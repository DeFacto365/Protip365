-- Script to empty v_shift_income table
-- Note: v_shift_income is a view, so we need to delete from the underlying tables

-- First, delete all data from shift_income table (which feeds the view)
DELETE FROM shift_income;

-- Also delete from shifts table if you want to clear everything
DELETE FROM shifts;

-- Reset any auto-increment sequences if they exist
-- (This is not needed for UUID primary keys, but included for completeness)

-- Verify the tables are empty
SELECT COUNT(*) as shift_income_count FROM shift_income;
SELECT COUNT(*) as shifts_count FROM shifts;
SELECT COUNT(*) as v_shift_income_count FROM v_shift_income;

-- Optional: If you want to keep employers but clear everything else
-- DELETE FROM shift_income WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%test%');
-- DELETE FROM shifts WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%test%');
