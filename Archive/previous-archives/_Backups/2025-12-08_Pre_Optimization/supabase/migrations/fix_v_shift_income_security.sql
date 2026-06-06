-- CRITICAL SECURITY FIX: Add Row Level Security to v_shift_income view
-- This script adds proper RLS policies to prevent unauthorized data access

-- Since v_shift_income is a VIEW, we need to:
-- 1. Ensure the underlying tables (shifts and shift_income) have RLS enabled
-- 2. Create a security definer function or recreate the view with proper security

-- First, ensure RLS is enabled on base tables
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_income ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can only see their own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can only insert their own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can only update their own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can only delete their own shifts" ON public.shifts;

DROP POLICY IF EXISTS "Users can only see their own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can only insert their own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can only update their own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can only delete their own shift income" ON public.shift_income;

-- Create RLS policies for shifts table
CREATE POLICY "Users can only see their own shifts"
    ON public.shifts
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can only insert their own shifts"
    ON public.shifts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only update their own shifts"
    ON public.shifts
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only delete their own shifts"
    ON public.shifts
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create RLS policies for shift_income table
CREATE POLICY "Users can only see their own shift income"
    ON public.shift_income
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can only insert their own shift income"
    ON public.shift_income
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only update their own shift income"
    ON public.shift_income
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only delete their own shift income"
    ON public.shift_income
    FOR DELETE
    USING (auth.uid() = user_id);

-- Now recreate the v_shift_income view with SECURITY INVOKER
-- This ensures the view respects the RLS policies of the underlying tables

-- First, get the current view definition (you may need to adjust this based on actual view)
-- Drop the existing view
DROP VIEW IF EXISTS public.v_shift_income CASCADE;

-- Recreate the view with proper security context
CREATE OR REPLACE VIEW public.v_shift_income
WITH (security_invoker = true) AS
SELECT
    si.id as income_id,
    s.id as shift_id,
    s.user_id,
    s.employer_id,
    e.name as employer_name,
    s.shift_date,
    s.expected_hours,
    s.lunch_break_minutes,
    COALESCE(s.expected_hours - (s.lunch_break_minutes::numeric / 60), s.expected_hours) as net_expected_hours,
    COALESCE(si.actual_hours, s.hours, 0) as hours,
    s.hourly_rate,
    COALESCE(si.sales, s.sales, 0) as sales,
    COALESCE(si.tips, s.tips, 0) as tips,
    COALESCE(si.cash_out, s.cash_out, 0) as cash_out,
    COALESCE(si.other, s.other, 0) as other,
    -- Calculate base income
    COALESCE(si.actual_hours * s.hourly_rate, s.hours * s.hourly_rate, 0) as base_income,
    -- Calculate net tips (tips - cash_out)
    COALESCE(si.tips - si.cash_out, s.tips - s.cash_out, 0) as net_tips,
    -- Calculate total income
    COALESCE(
        (si.actual_hours * s.hourly_rate) + (si.tips - si.cash_out) + si.other,
        (s.hours * s.hourly_rate) + (s.tips - s.cash_out) + s.other,
        0
    ) as total_income,
    -- Calculate tip percentage
    CASE
        WHEN COALESCE(si.sales, s.sales, 0) > 0
        THEN (COALESCE(si.tips, s.tips, 0) / COALESCE(si.sales, s.sales, 1)) * 100
        ELSE 0
    END as tip_percentage,
    s.start_time,
    s.end_time,
    s.status as shift_status,
    CASE WHEN si.id IS NOT NULL THEN true ELSE false END as has_earnings,
    s.created_at as shift_created_at,
    si.created_at as earnings_created_at,
    COALESCE(si.notes, s.notes) as notes
FROM
    public.shifts s
    LEFT JOIN public.shift_income si ON s.id = si.shift_id
    LEFT JOIN public.employers e ON s.employer_id = e.id
WHERE
    -- This WHERE clause ensures users only see their own data
    s.user_id = auth.uid();

-- Grant appropriate permissions
GRANT SELECT ON public.v_shift_income TO authenticated;

-- Verify the fix
-- This should return only the current user's data
-- SELECT COUNT(*) FROM public.v_shift_income;

-- IMPORTANT: After running this script, test thoroughly:
-- 1. Log in as a test user and verify they can only see their own data
-- 2. Try to query another user's data (should return empty)
-- 3. Verify the app still works correctly with these restrictions

-- Additional security recommendations:
-- 1. Audit all other tables and views for similar issues
-- 2. Enable RLS on ALL tables by default
-- 3. Create explicit policies for each table
-- 4. Use security_invoker for all views that access user data