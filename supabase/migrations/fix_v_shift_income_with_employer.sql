-- Fix v_shift_income view - attempt to include employer info
-- First, let's check if employer_id column actually exists

-- Check if employer_id column exists in shift_income
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'shift_income' 
AND table_schema = 'public'
AND column_name = 'employer_id';

-- Drop the existing view
DROP VIEW IF EXISTS public.v_shift_income;

-- Create the view - try with employer_id first
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
    -- Try to include employer info if column exists
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'shift_income' 
            AND column_name = 'employer_id'
            AND table_schema = 'public'
        ) THEN si.employer_id
        ELSE NULL
    END as employer_id,
    -- Try to get employer name
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'shift_income' 
            AND column_name = 'employer_id'
            AND table_schema = 'public'
        ) THEN e.name
        ELSE NULL
    END as employer_name,
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
FROM shift_income si
LEFT JOIN employers e ON (
    EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'shift_income' 
        AND column_name = 'employer_id'
        AND table_schema = 'public'
    ) AND si.employer_id = e.id
);

-- If the above doesn't work, try this simpler version without employer join:
/*
DROP VIEW IF EXISTS public.v_shift_income;

CREATE VIEW public.v_shift_income AS
SELECT 
    si.*,
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
*/

-- Verify the view was created correctly
SELECT 
    schemaname,
    viewname
FROM pg_views 
WHERE viewname = 'v_shift_income' 
AND schemaname = 'public';
