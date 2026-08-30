-- Complete RLS Performance Fix - ProTip365 Database
-- This script fixes ALL performance warnings in one go

-- ========================================
-- COMPLETE RLS PERFORMANCE FIX
-- ========================================

-- Fix shifts table - remove duplicates and optimize auth calls
DROP POLICY IF EXISTS "Users can view own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can create own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can insert own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can update own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can delete own shifts" ON public.shifts;
DROP POLICY IF EXISTS "shifts_policy" ON public.shifts;

CREATE POLICY "Users can view own shifts" ON public.shifts
    FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can create own shifts" ON public.shifts
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own shifts" ON public.shifts
    FOR UPDATE USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own shifts" ON public.shifts
    FOR DELETE USING ((select auth.uid()) = user_id);

-- Fix employers table - remove duplicates and optimize auth calls
DROP POLICY IF EXISTS "Users can view own employers" ON public.employers;
DROP POLICY IF EXISTS "Users can create own employers" ON public.employers;
DROP POLICY IF EXISTS "Users can insert own employers" ON public.employers;
DROP POLICY IF EXISTS "Users can update own employers" ON public.employers;
DROP POLICY IF EXISTS "Users can delete own employers" ON public.employers;
DROP POLICY IF EXISTS "employers_policy" ON public.employers;

CREATE POLICY "Users can view own employers" ON public.employers
    FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can create own employers" ON public.employers
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own employers" ON public.employers
    FOR UPDATE USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own employers" ON public.employers
    FOR DELETE USING ((select auth.uid()) = user_id);

-- Fix shift_income table - remove duplicates and optimize auth calls
DROP POLICY IF EXISTS "Users can view own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can insert own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can update own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can delete own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "shift_income_policy" ON public.shift_income;

CREATE POLICY "Users can view own shift income" ON public.shift_income
    FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own shift income" ON public.shift_income
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own shift income" ON public.shift_income
    FOR UPDATE USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own shift income" ON public.shift_income
    FOR DELETE USING ((select auth.uid()) = user_id);

-- Fix users_profile table - optimize auth calls
DROP POLICY IF EXISTS "Users can view own profile" ON public.users_profile;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users_profile;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users_profile;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users_profile;

CREATE POLICY "Users can view own profile" ON public.users_profile
    FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own profile" ON public.users_profile
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own profile" ON public.users_profile
    FOR UPDATE USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own profile" ON public.users_profile
    FOR DELETE USING ((select auth.uid()) = user_id);

-- Fix password_reset_tokens table - optimize auth calls
DROP POLICY IF EXISTS "password_reset_tokens_policy" ON public.password_reset_tokens;

CREATE POLICY "password_reset_tokens_policy" ON public.password_reset_tokens
    FOR ALL USING ((select auth.uid()) = user_id);

-- Fix user_subscriptions table - remove duplicates and optimize auth calls
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can view own subscription" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscription" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can update own subscription" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can delete own subscription" ON public.user_subscriptions;

CREATE POLICY "Users can view own subscriptions" ON public.user_subscriptions
    FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own subscriptions" ON public.user_subscriptions
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own subscriptions" ON public.user_subscriptions
    FOR UPDATE USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own subscriptions" ON public.user_subscriptions
    FOR DELETE USING ((select auth.uid()) = user_id);

-- Fix achievements table - optimize auth calls
DROP POLICY IF EXISTS "Users can view own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can insert own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can update own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can delete own achievements" ON public.achievements;

CREATE POLICY "Users can view own achievements" ON public.achievements
    FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own achievements" ON public.achievements
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own achievements" ON public.achievements
    FOR UPDATE USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own achievements" ON public.achievements
    FOR DELETE USING ((select auth.uid()) = user_id);

-- Fix alerts table - optimize auth calls
DROP POLICY IF EXISTS "Users can view own alerts" ON public.alerts;
DROP POLICY IF EXISTS "Users can insert own alerts" ON public.alerts;
DROP POLICY IF EXISTS "Users can update own alerts" ON public.alerts;
DROP POLICY IF EXISTS "Users can delete own alerts" ON public.alerts;

CREATE POLICY "Users can view own alerts" ON public.alerts
    FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own alerts" ON public.alerts
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own alerts" ON public.alerts
    FOR UPDATE USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own alerts" ON public.alerts
    FOR DELETE USING ((select auth.uid()) = user_id);

-- Fix entries table - optimize auth calls
DROP POLICY IF EXISTS "Users can view own entries" ON public.entries;
DROP POLICY IF EXISTS "Users can insert own entries" ON public.entries;
DROP POLICY IF EXISTS "Users can update own entries" ON public.entries;
DROP POLICY IF EXISTS "Users can delete own entries" ON public.entries;

CREATE POLICY "Users can view own entries" ON public.entries
    FOR SELECT USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own entries" ON public.entries
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own entries" ON public.entries
    FOR UPDATE USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own entries" ON public.entries
    FOR DELETE USING ((select auth.uid()) = user_id);

-- ========================================
-- VERIFICATION
-- ========================================

-- Check the results
SELECT 
    'Performance fixes completed successfully!' as status,
    COUNT(*) as total_policies_remaining
FROM pg_policies 
WHERE tablename IN ('shifts', 'employers', 'shift_income', 'users_profile', 'user_subscriptions', 'achievements', 'alerts', 'entries');

-- Show remaining policies for verification
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename IN ('shifts', 'employers', 'shift_income', 'users_profile', 'user_subscriptions', 'achievements', 'alerts', 'entries')
ORDER BY tablename, policyname;
