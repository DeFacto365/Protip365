-- Fix RLS for v_shift_income view by securing underlying tables
-- Views inherit RLS from their underlying tables

-- Enable RLS on shifts table (if not already enabled)
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;

-- Create/update RLS policy for shifts table
DROP POLICY IF EXISTS "Users can manage their own shifts" ON shifts;
CREATE POLICY "Users can manage their own shifts"
ON shifts
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Enable RLS on shift_income table (if not already enabled)
ALTER TABLE shift_income ENABLE ROW LEVEL SECURITY;

-- Create/update RLS policy for shift_income table
DROP POLICY IF EXISTS "Users can manage their own shift income" ON shift_income;
CREATE POLICY "Users can manage their own shift income"
ON shift_income
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON shifts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON shift_income TO authenticated;
GRANT SELECT ON v_shift_income TO authenticated;