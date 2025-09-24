-- Fix v_shift_income view with correct column structure
-- This version works with the actual table structure

-- Drop the existing view
DROP VIEW IF EXISTS public.v_shift_income;

-- Recreate the view with the correct column references
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
    si.shift_date,
    si.hourly_rate,
    si.lunch_break_minutes,
    si.status,
    si.created_at,
    si.updated_at,
    -- Get employer info from the shifts table instead
    e.name as employer_name,
    s.employer_id,
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
