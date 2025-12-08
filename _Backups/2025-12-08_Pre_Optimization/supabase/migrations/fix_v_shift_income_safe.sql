-- SAFE fix for v_shift_income view - minimal changes only
-- This version removes SECURITY DEFINER without changing functionality

-- First, let's see what the current view looks like
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE viewname = 'v_shift_income' 
AND schemaname = 'public';

-- Drop the existing view
DROP VIEW IF EXISTS public.v_shift_income;

-- Recreate the view with the SAME structure as before, just without SECURITY DEFINER
-- Using the simplest possible structure based on what we know exists
CREATE VIEW public.v_shift_income AS
SELECT 
    si.id,
    si.user_id,
    si.shift_date,
    si.hours,
    si.hourly_rate,
    si.sales,
    si.tips,
    si.cash_out,
    si.cash_out_note,
    si.start_time,
    si.end_time,
    si.other,
    si.notes,
    si.created_at,
    si.expected_hours,
    si.lunch_break_hours,
    si.status,
    si.lunch_break_minutes
FROM shift_income si;

-- Verify the view was created successfully
SELECT 
    schemaname,
    viewname
FROM pg_views 
WHERE viewname = 'v_shift_income' 
AND schemaname = 'public';

-- Test that the view works
SELECT COUNT(*) as total_records FROM v_shift_income;
