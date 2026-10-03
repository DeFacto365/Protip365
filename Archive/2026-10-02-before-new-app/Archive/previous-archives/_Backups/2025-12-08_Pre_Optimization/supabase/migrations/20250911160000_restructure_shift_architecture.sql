-- Restructure ProTip365 architecture: separate expected shifts from actual earnings
-- This migration implements the new two-table system:
-- 1. shifts table = expected/planned shifts (created in advance or retroactively)
-- 2. shift_income table = actual earnings data (linked to planned shifts)

-- First drop the existing view that depends on columns we'll be changing
DROP VIEW IF EXISTS v_shift_income;

-- Backup existing data by creating a temporary table
CREATE TABLE shifts_backup AS SELECT * FROM shifts;

-- Create the new shift_income table for actual earnings data
CREATE TABLE IF NOT EXISTS shift_income (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    actual_hours DECIMAL(10,2) DEFAULT 0,
    sales DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,
    cash_out DECIMAL(10,2) DEFAULT 0,
    other DECIMAL(10,2) DEFAULT 0,
    actual_start_time TEXT,
    actual_end_time TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on shift_income table
ALTER TABLE shift_income ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for shift_income table
CREATE POLICY "Users can view own shift income" 
ON shift_income FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own shift income" 
ON shift_income FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own shift income" 
ON shift_income FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own shift income" 
ON shift_income FOR DELETE 
USING (auth.uid() = user_id);

-- Modify the shifts table to focus on expected/planned shifts only
-- Remove earnings-related columns and keep planning-related ones
ALTER TABLE shifts DROP COLUMN IF EXISTS sales;
ALTER TABLE shifts DROP COLUMN IF EXISTS tips;
ALTER TABLE shifts DROP COLUMN IF EXISTS cash_out;
ALTER TABLE shifts DROP COLUMN IF EXISTS other;
ALTER TABLE shifts DROP COLUMN IF EXISTS cash_out_note;

-- Add expected hours if not exists (keeping the hours column as expected_hours concept)
-- The hours column will now represent expected/planned hours
ALTER TABLE shifts RENAME COLUMN hours TO expected_hours;

-- Add status column to track shift state
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'completed', 'missed'));

-- Migrate existing data: 
-- For each shift in backup that has earnings data, create both a planned shift and earnings record
DO $$
DECLARE
    backup_row RECORD;
    new_shift_id UUID;
BEGIN
    FOR backup_row IN SELECT * FROM shifts_backup LOOP
        -- Check if this shift has any earnings data
        IF backup_row.sales > 0 OR backup_row.tips > 0 OR backup_row.cash_out > 0 OR backup_row.other > 0 THEN
            -- This was a completed shift, so create both planned shift and earnings
            
            -- Update the existing shift record to be the planned version
            UPDATE shifts 
            SET 
                expected_hours = backup_row.hours,
                status = 'completed',
                notes = COALESCE(backup_row.notes, ''),
                updated_at = NOW()
            WHERE id = backup_row.id;
            
            -- Create the earnings record
            INSERT INTO shift_income (
                shift_id, user_id, actual_hours, sales, tips, cash_out, other,
                actual_start_time, actual_end_time, notes, created_at
            ) VALUES (
                backup_row.id, backup_row.user_id, backup_row.hours, 
                backup_row.sales, backup_row.tips, backup_row.cash_out, backup_row.other,
                backup_row.start_time, backup_row.end_time, backup_row.cash_out_note,
                backup_row.created_at
            );
        ELSE
            -- This was a planned-only shift
            UPDATE shifts 
            SET 
                expected_hours = backup_row.hours,
                status = 'planned',
                notes = COALESCE(backup_row.notes, ''),
                updated_at = NOW()
            WHERE id = backup_row.id;
        END IF;
    END LOOP;
END $$;

-- Update the v_shift_income view to use the new architecture
DROP VIEW IF EXISTS v_shift_income;

CREATE OR REPLACE VIEW v_shift_income AS
SELECT 
    si.id as income_id,
    s.id as shift_id,
    s.user_id,
    s.employer_id,
    e.name as employer_name,
    s.shift_date,
    s.expected_hours,
    COALESCE(si.actual_hours, 0) as hours,
    s.hourly_rate,
    COALESCE(si.sales, 0) as sales,
    COALESCE(si.tips, 0) as tips,
    COALESCE(si.cash_out, 0) as cash_out,
    COALESCE(si.other, 0) as other,
    (COALESCE(si.actual_hours, 0) * COALESCE(s.hourly_rate, 0)) as base_income,
    (COALESCE(si.tips, 0) - COALESCE(si.cash_out, 0)) as net_tips,
    (COALESCE(si.actual_hours, 0) * COALESCE(s.hourly_rate, 0)) + COALESCE(si.tips, 0) + COALESCE(si.other, 0) - COALESCE(si.cash_out, 0) as total_income,
    CASE 
        WHEN COALESCE(si.sales, 0) > 0 THEN (COALESCE(si.tips, 0) / si.sales) * 100
        ELSE 0 
    END as tip_percentage,
    COALESCE(si.actual_start_time, s.start_time) as start_time,
    COALESCE(si.actual_end_time, s.end_time) as end_time,
    s.status as shift_status,
    CASE WHEN si.id IS NOT NULL THEN true ELSE false END as has_earnings,
    s.created_at as shift_created_at,
    si.created_at as earnings_created_at
FROM shifts s
LEFT JOIN shift_income si ON s.id = si.shift_id
LEFT JOIN employers e ON s.employer_id = e.id AND e.user_id = auth.uid()
WHERE s.user_id = auth.uid()
ORDER BY s.shift_date DESC, s.created_at DESC;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_shift_income_shift_id ON shift_income(shift_id);
CREATE INDEX IF NOT EXISTS idx_shift_income_user_id ON shift_income(user_id);

-- Grant permissions
GRANT SELECT ON v_shift_income TO authenticated;
GRANT ALL ON shift_income TO authenticated;

-- Clean up backup table
DROP TABLE shifts_backup;

-- Add comments
COMMENT ON TABLE shift_income IS 'Actual earnings data for completed shifts';
COMMENT ON COLUMN shifts.expected_hours IS 'Expected/planned hours for this shift';
COMMENT ON COLUMN shifts.status IS 'Shift status: planned, completed, or missed';
COMMENT ON VIEW v_shift_income IS 'Combined view of planned shifts and actual earnings with calculated totals';