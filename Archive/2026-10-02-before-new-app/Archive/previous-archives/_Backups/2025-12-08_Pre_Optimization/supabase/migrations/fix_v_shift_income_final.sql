-- Final fix for v_shift_income view - using only existing columns
-- This version gets all date and employer info from the shifts table

-- Drop the existing view
DROP VIEW IF EXISTS public.v_shift_income;

-- Create the view using only columns that actually exist
CREATE VIEW public.v_shift_income AS
SELECT 
    si.id,
    si.shift_id,
    si.user_id,
    si.actual_hours,
    si.sales,
    si.tips,
    si.cash_out,
    si.other,
    si.actual_start_time,
    si.actual_end_time,
    si.hourly_rate,
    si.lunch_break_minutes,
    si.status,
    si.created_at,
    si.updated_at,
    -- Get date and employer info from shifts table
    s.shift_date,
    s.employer_id,
    e.name as employer_name,
    -- Calculate total income
    (si.sales + si.tips + si.other - si.cash_out) as total_income,
    -- Calculate hourly wage
    CASE 
        WHEN si.actual_hours > 0 THEN 
            (si.sales + si.tips + si.other - si.cash_out) / si.actual_hours
        ELSE 0
    END as hourly_wage,
    -- Calculate base pay
    (si.hourly_rate * si.actual_hours) as base_pay,
    -- Calculate tip percentage
    CASE 
        WHEN si.sales > 0 THEN 
            (si.tips / si.sales) * 100
        ELSE 0
    END as tip_percentage
FROM shift_income si
LEFT JOIN shifts s ON si.shift_id = s.id
LEFT JOIN employers e ON s.employer_id = e.id;

-- Verify the view was created correctly
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE viewname = 'v_shift_income' 
AND schemaname = 'public';

-- Test that the view works correctly
SELECT COUNT(*) as total_records FROM v_shift_income;

-- Show a sample of the data to verify it's working
SELECT 
    id,
    shift_date,
    employer_name,
    actual_hours,
    sales,
    tips,
    total_income,
    hourly_wage
FROM v_shift_income 
LIMIT 5;
