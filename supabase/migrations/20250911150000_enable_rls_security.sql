-- Enable Row Level Security for ProTip365 tables
-- This migration addresses the security vulnerability where v_shift_income and other tables were unrestricted

-- Enable RLS on all tables
ALTER TABLE users_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE employers ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;

-- Drop and recreate the view with proper security context
DROP VIEW IF EXISTS v_shift_income;

-- Recreate v_shift_income view with explicit user filtering
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
    s.end_time,
    s.created_at
FROM shifts s
LEFT JOIN employers e ON s.employer_id = e.id AND e.user_id = auth.uid()
WHERE s.user_id = auth.uid()
ORDER BY s.shift_date DESC, s.created_at DESC;

-- Create RLS policies for users_profile table
CREATE POLICY "Users can view own profile" 
ON users_profile FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" 
ON users_profile FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" 
ON users_profile FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own profile" 
ON users_profile FOR DELETE 
USING (auth.uid() = user_id);

-- Create RLS policies for employers table
CREATE POLICY "Users can view own employers" 
ON employers FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own employers" 
ON employers FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own employers" 
ON employers FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own employers" 
ON employers FOR DELETE 
USING (auth.uid() = user_id);

-- Create RLS policies for shifts table
CREATE POLICY "Users can view own shifts" 
ON shifts FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own shifts" 
ON shifts FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own shifts" 
ON shifts FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own shifts" 
ON shifts FOR DELETE 
USING (auth.uid() = user_id);

-- Add comment explaining the security model
COMMENT ON VIEW v_shift_income IS 'Computed view of shift income with calculated totals - secured by RLS policies on underlying tables and explicit user filtering';

-- Grant necessary permissions to authenticated users
GRANT SELECT ON v_shift_income TO authenticated;
GRANT ALL ON users_profile TO authenticated;
GRANT ALL ON employers TO authenticated;
GRANT ALL ON shifts TO authenticated;