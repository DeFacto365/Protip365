-- Add lunch break field to shifts table
-- This allows tracking unpaid break time that should be deducted from expected hours

-- Add lunch_break_minutes column to shifts table
ALTER TABLE shifts 
ADD COLUMN lunch_break_minutes INTEGER DEFAULT 0 NOT NULL;

-- Update the v_shift_income view to include lunch break and adjust calculations
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
    s.lunch_break_minutes,
    -- Calculate net expected hours (subtracting lunch break)
    GREATEST(0, s.expected_hours - (s.lunch_break_minutes::DECIMAL / 60)) as net_expected_hours,
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

-- Grant permissions
GRANT SELECT ON v_shift_income TO authenticated;

-- Add comment explaining the lunch break functionality
COMMENT ON COLUMN shifts.lunch_break_minutes IS 'Unpaid break time in minutes, deducted from expected hours for net working time calculation';
COMMENT ON VIEW v_shift_income IS 'Combined view of planned shifts and actual earnings with lunch break calculations and totals';