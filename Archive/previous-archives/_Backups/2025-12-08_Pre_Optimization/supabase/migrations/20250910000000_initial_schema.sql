-- Initial schema for ProTip365
-- Create users_profile table
CREATE TABLE IF NOT EXISTS users_profile (
    user_id UUID PRIMARY KEY,
    default_hourly_rate DECIMAL(10,2) DEFAULT 0,
    week_start INTEGER DEFAULT 0,
    target_tip_daily DECIMAL(10,2) DEFAULT 0,
    target_tip_weekly DECIMAL(10,2) DEFAULT 0,
    target_tip_monthly DECIMAL(10,2) DEFAULT 0,
    name TEXT,
    default_employer_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create employers table
CREATE TABLE IF NOT EXISTS employers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name TEXT NOT NULL,
    hourly_rate DECIMAL(10,2) DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create shifts table
CREATE TABLE IF NOT EXISTS shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    employer_id UUID REFERENCES employers(id),
    shift_date TEXT NOT NULL,
    hours DECIMAL(10,2) DEFAULT 0,
    hourly_rate DECIMAL(10,2),
    sales DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,
    cash_out DECIMAL(10,2) DEFAULT 0,
    other DECIMAL(10,2) DEFAULT 0,
    cash_out_note TEXT,
    notes TEXT,
    start_time TEXT,
    end_time TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key constraint to users_profile for default_employer_id
ALTER TABLE users_profile 
ADD CONSTRAINT fk_users_profile_default_employer 
FOREIGN KEY (default_employer_id) REFERENCES employers(id);

-- Create shifts_income view
CREATE OR REPLACE VIEW v_shift_income AS
SELECT 
    s.id,
    s.user_id,
    s.employer_id,
    e.name as employer_name,
    s.shift_date,
    s.hours,
    s.hourly_rate,
    s.sales,
    s.tips,
    s.cash_out,
    s.other,
    (s.hours * COALESCE(s.hourly_rate, 0)) as base_income,
    (s.tips - COALESCE(s.cash_out, 0)) as net_tips,
    (s.hours * COALESCE(s.hourly_rate, 0)) + s.tips + COALESCE(s.other, 0) - COALESCE(s.cash_out, 0) as total_income,
    CASE 
        WHEN s.sales > 0 THEN (s.tips / s.sales) * 100
        ELSE 0 
    END as tip_percentage,
    s.start_time,
    s.end_time
FROM shifts s
LEFT JOIN employers e ON s.employer_id = e.id
ORDER BY s.shift_date DESC, s.created_at DESC;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_shifts_user_id ON shifts(user_id);
CREATE INDEX IF NOT EXISTS idx_shifts_date ON shifts(shift_date);
CREATE INDEX IF NOT EXISTS idx_employers_user_id ON employers(user_id);

-- Comments
COMMENT ON TABLE users_profile IS 'User profile and preferences';
COMMENT ON TABLE employers IS 'Employer information for each user';
COMMENT ON TABLE shifts IS 'Shift data with earnings information';
COMMENT ON COLUMN users_profile.default_employer_id IS 'Default employer selected by user for quick entry forms';
COMMENT ON COLUMN shifts.other IS 'Other earnings category for miscellaneous income';
COMMENT ON VIEW v_shift_income IS 'Computed view of shift income with calculated totals';