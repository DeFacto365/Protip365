-- ================================================================
-- ProTip365 - Complete RLS Security Fix
-- ================================================================
-- This script ensures ALL tables have proper Row Level Security (RLS)
-- policies to prevent unauthorized data access
-- Date: December 2024
-- ================================================================

-- ================================================================
-- 1. ENABLE RLS ON ALL TABLES
-- ================================================================

-- Core tables
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE employers ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_profile ENABLE ROW LEVEL SECURITY;

-- Feature tables
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Support tables
ALTER TABLE shift_income ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_reset_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

-- ================================================================
-- 2. ENTRIES TABLE POLICIES (Currently Unprotected!)
-- ================================================================

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own entries" ON public.entries;
DROP POLICY IF EXISTS "Users can create own entries" ON public.entries;
DROP POLICY IF EXISTS "Users can update own entries" ON public.entries;
DROP POLICY IF EXISTS "Users can delete own entries" ON public.entries;

-- Create new policies for entries table
CREATE POLICY "Users can view own entries" ON public.entries
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own entries" ON public.entries
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own entries" ON public.entries
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own entries" ON public.entries
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ================================================================
-- 3. ALERTS TABLE POLICIES
-- ================================================================

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own alerts" ON public.alerts;
DROP POLICY IF EXISTS "Users can create own alerts" ON public.alerts;
DROP POLICY IF EXISTS "Users can update own alerts" ON public.alerts;
DROP POLICY IF EXISTS "Users can delete own alerts" ON public.alerts;

-- Create new policies for alerts table
CREATE POLICY "Users can view own alerts" ON public.alerts
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own alerts" ON public.alerts
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own alerts" ON public.alerts
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own alerts" ON public.alerts
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ================================================================
-- 4. ACHIEVEMENTS TABLE POLICIES
-- ================================================================

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can create own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can update own achievements" ON public.achievements;
DROP POLICY IF EXISTS "Users can delete own achievements" ON public.achievements;

-- Create new policies for achievements table
CREATE POLICY "Users can view own achievements" ON public.achievements
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own achievements" ON public.achievements
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own achievements" ON public.achievements
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own achievements" ON public.achievements
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ================================================================
-- 5. VERIFY EXISTING TABLE POLICIES
-- ================================================================

-- Shifts table (ensure optimized policies exist)
DROP POLICY IF EXISTS "Users can view own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can create own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can update own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Users can delete own shifts" ON public.shifts;

CREATE POLICY "Users can view own shifts" ON public.shifts
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own shifts" ON public.shifts
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own shifts" ON public.shifts
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own shifts" ON public.shifts
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Employers table
DROP POLICY IF EXISTS "Users can view own employers" ON public.employers;
DROP POLICY IF EXISTS "Users can create own employers" ON public.employers;
DROP POLICY IF EXISTS "Users can update own employers" ON public.employers;
DROP POLICY IF EXISTS "Users can delete own employers" ON public.employers;

CREATE POLICY "Users can view own employers" ON public.employers
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own employers" ON public.employers
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own employers" ON public.employers
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own employers" ON public.employers
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Users profile table
DROP POLICY IF EXISTS "Users can view own profile" ON public.users_profile;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users_profile;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users_profile;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users_profile;

CREATE POLICY "Users can view own profile" ON public.users_profile
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own profile" ON public.users_profile
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own profile" ON public.users_profile
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own profile" ON public.users_profile
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- User subscriptions table
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can create own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can delete own subscriptions" ON public.user_subscriptions;

CREATE POLICY "Users can view own subscriptions" ON public.user_subscriptions
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own subscriptions" ON public.user_subscriptions
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own subscriptions" ON public.user_subscriptions
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own subscriptions" ON public.user_subscriptions
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ================================================================
-- 6. FIX V_SHIFT_INCOME VIEW SECURITY
-- ================================================================

-- Drop and recreate the view with proper security filtering
DROP VIEW IF EXISTS v_shift_income CASCADE;

CREATE OR REPLACE VIEW v_shift_income AS
SELECT
    s.id AS shift_id,
    s.user_id,
    s.employer_id,
    e.name AS employer_name,
    s.shift_date,
    s.hours,
    s.expected_hours,
    s.hourly_rate,
    s.sales,
    s.tips,
    s.cash_out,
    s.other,
    s.status AS shift_status,
    s.start_time,
    s.end_time,
    s.lunch_break_minutes,
    s.notes,
    -- Calculated fields
    (s.hours * COALESCE(s.hourly_rate, 0)) AS base_income,
    (s.tips - COALESCE(s.cash_out, 0)) AS net_tips,
    (s.hours * COALESCE(s.hourly_rate, 0)) + s.tips + COALESCE(s.other, 0) - COALESCE(s.cash_out, 0) AS total_income,
    CASE
        WHEN s.sales > 0 THEN (s.tips / s.sales) * 100
        ELSE 0
    END AS tip_percentage,
    s.created_at
FROM shifts s
LEFT JOIN employers e ON s.employer_id = e.id
WHERE s.user_id = (SELECT auth.uid())  -- Critical: Filter by current user
    AND (e.user_id IS NULL OR e.user_id = (SELECT auth.uid()))  -- Ensure employer also belongs to user
ORDER BY s.shift_date DESC, s.created_at DESC;

-- Grant access to authenticated users
GRANT SELECT ON v_shift_income TO authenticated;

-- Add comment explaining security
COMMENT ON VIEW v_shift_income IS 'Secured view of shift income - filters data by authenticated user ID';

-- ================================================================
-- 7. SECURITY AUDIT LOG POLICIES
-- ================================================================

DROP POLICY IF EXISTS "Users can view own security events" ON public.security_audit_log;
DROP POLICY IF EXISTS "System can insert security events" ON public.security_audit_log;

CREATE POLICY "Users can view own security events" ON public.security_audit_log
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "System can insert security events" ON public.security_audit_log
    FOR INSERT WITH CHECK (true);  -- Allow system to log events

-- ================================================================
-- 8. PASSWORD RESET TOKENS (SPECIAL HANDLING)
-- ================================================================

DROP POLICY IF EXISTS "password_reset_tokens_policy" ON public.password_reset_tokens;

-- Only allow users to interact with their own tokens
CREATE POLICY "Users can manage own reset tokens" ON public.password_reset_tokens
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- ================================================================
-- 9. SHIFT INCOME TABLE (IF USED)
-- ================================================================

DROP POLICY IF EXISTS "Users can view own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can insert own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can update own shift income" ON public.shift_income;
DROP POLICY IF EXISTS "Users can delete own shift income" ON public.shift_income;

CREATE POLICY "Users can view own shift income" ON public.shift_income
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own shift income" ON public.shift_income
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own shift income" ON public.shift_income
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own shift income" ON public.shift_income
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- ================================================================
-- 10. GRANT NECESSARY PERMISSIONS
-- ================================================================

-- Grant permissions to authenticated role
GRANT ALL ON shifts TO authenticated;
GRANT ALL ON entries TO authenticated;
GRANT ALL ON employers TO authenticated;
GRANT ALL ON users_profile TO authenticated;
GRANT ALL ON alerts TO authenticated;
GRANT ALL ON achievements TO authenticated;
GRANT ALL ON user_subscriptions TO authenticated;
GRANT SELECT ON v_shift_income TO authenticated;

-- ================================================================
-- 11. VERIFY RLS IS ENABLED
-- ================================================================

DO $$
DECLARE
    r RECORD;
    missing_rls TEXT := '';
BEGIN
    -- Check for tables without RLS
    FOR r IN
        SELECT schemaname, tablename
        FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename NOT IN (
            SELECT tablename
            FROM pg_tables t
            JOIN pg_class c ON c.relname = t.tablename
            WHERE t.schemaname = 'public'
            AND c.relrowsecurity = true
        )
    LOOP
        missing_rls := missing_rls || r.schemaname || '.' || r.tablename || ', ';
    END LOOP;

    IF LENGTH(missing_rls) > 0 THEN
        RAISE WARNING 'Tables without RLS: %', missing_rls;
    ELSE
        RAISE NOTICE 'All tables have RLS enabled ✓';
    END IF;
END $$;

-- ================================================================
-- 12. VERIFY POLICIES EXIST
-- ================================================================

SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd;

-- ================================================================
-- 13. FINAL SECURITY CHECK
-- ================================================================

SELECT
    'Table Security Status' as check_type,
    t.tablename,
    CASE
        WHEN c.relrowsecurity THEN '✅ RLS Enabled'
        ELSE '❌ RLS DISABLED - SECURITY RISK!'
    END as status,
    COUNT(p.policyname) as policy_count
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename AND c.relnamespace = 'public'::regnamespace
LEFT JOIN pg_policies p ON p.tablename = t.tablename AND p.schemaname = 'public'
WHERE t.schemaname = 'public'
GROUP BY t.tablename, c.relrowsecurity
ORDER BY c.relrowsecurity DESC, t.tablename;

-- Output message
SELECT 'RLS Security Fix Complete! All tables should now be protected.' as message;