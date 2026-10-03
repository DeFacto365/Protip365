-- Fix Multiple Permissive Policies - ProTip365 Database
-- This script removes duplicate RLS policies that cause performance issues

-- ========================================
-- PART 2: Remove Duplicate Policies
-- ========================================

-- Remove duplicate policies from shifts table
DROP POLICY IF EXISTS "shifts_policy" ON public.shifts;

-- Remove duplicate policies from employers table  
DROP POLICY IF EXISTS "employers_policy" ON public.employers;

-- Remove duplicate policies from shift_income table
DROP POLICY IF EXISTS "shift_income_policy" ON public.shift_income;

-- ========================================
-- PART 3: Clean up any remaining duplicate policies
-- ========================================

-- Check for and remove any remaining duplicate policies
-- (These might exist with slightly different names)

-- Remove any policy that might be duplicating the main ones
DROP POLICY IF EXISTS "Users can insert own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can create own employers" ON public.employers;
DROP POLICY IF EXISTS "Users can insert own employers" ON public.employers;

-- ========================================
-- PART 4: Verify the fixes
-- ========================================

-- Check remaining policies on key tables
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('shifts', 'employers', 'shift_income', 'users_profile', 'user_subscriptions', 'achievements', 'alerts', 'entries')
ORDER BY tablename, policyname;
