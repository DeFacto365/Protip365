-- Minimal fix for v_shift_income view - without employer join
-- This version works with just the shift_income table columns

-- Drop the existing view
DROP VIEW IF EXISTS public.v_shift_income;

-- Create the view using only columns that definitely exist
CREATE VIEW public.v_shift_income AS
SELECT 
    si.id,
    si.user_id,
    si.shift_date,
    si.hours as actual_hours,
    si.hourly_rate,
    si.sales,
    si.tips,
    si.cash_out,
    si.cash_out_note,
    si.start_time as actual_start_time,
    si.end_time as actual_end_time,
    si.other,
    si.notes,
    si.created_at,
    si.expected_hours,
    si.lunch_break_hours,
    si.status,
    si.lunch_break_minutes,
    -- Calculate total income
    (si.sales + si.tips + si.other - si.cash_out) as total_income,
    -- Calculate hourly wage
    CASE 
        WHEN si.hours > 0 THEN 
            (si.sales + si.tips + si.other - si.cash_out) / si.hours
        ELSE 0
    END as hourly_wage,
    -- Calculate base pay
    CASE 
        WHEN si.hourly_rate IS NOT NULL AND si.hours > 0 THEN 
            si.hourly_rate * si.hours
        ELSE 0
    END as base_pay,
    -- Calculate tip percentage
    CASE 
        WHEN si.sales > 0 THEN 
            (si.tips / si.sales) * 100
        ELSE 0
    END as tip_percentage,
    -- Calculate net earnings (after cash out)
    (si.sales + si.tips + si.other - si.cash_out) as net_earnings
FROM shift_income si;

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
    hours as actual_hours,
    sales,
    tips,
    total_income,
    hourly_wage,
    net_earnings
FROM v_shift_income 
LIMIT 5;
