-- Complete Database Schema for ProTip365
-- This creates ALL tables that the app expects, even if not currently used
-- This ensures a clean, professional, and future-proof database structure

-- ============================================
-- 1. ACHIEVEMENTS TABLE
-- ============================================
-- Stores user achievements/badges earned in the app
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_achievement UNIQUE(user_id, achievement_type)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON public.achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_type ON public.achievements(achievement_type);

-- Enable RLS
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own achievements" ON public.achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON public.achievements
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements" ON public.achievements
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own achievements" ON public.achievements
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 2. ALERTS TABLE
-- ============================================
-- Stores in-app notifications and alerts for users
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    action TEXT,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_alerts_user_id ON public.alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_alerts_is_read ON public.alerts(is_read);
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON public.alerts(created_at DESC);

-- Enable RLS
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own alerts" ON public.alerts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own alerts" ON public.alerts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own alerts" ON public.alerts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own alerts" ON public.alerts
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. USER_SUBSCRIPTIONS TABLE (if not exists)
-- ============================================
-- Stores subscription information for cross-device sync
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    transaction_id TEXT,
    is_trial BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_subscription UNIQUE(user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_expires_at ON public.user_subscriptions(expires_at);

-- Enable RLS
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own subscription" ON public.user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription" ON public.user_subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription" ON public.user_subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own subscription" ON public.user_subscriptions
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 4. UPDATE DELETE_ACCOUNT FUNCTION
-- ============================================
-- Now that all tables exist, create a proper delete function
DROP FUNCTION IF EXISTS public.delete_account();

CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_user_id uuid;
BEGIN
    -- Get the current user's ID from the auth context
    current_user_id := auth.uid();

    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Delete all user data in the correct order (respecting foreign key constraints)

    -- Delete achievements
    DELETE FROM public.achievements WHERE user_id = current_user_id;

    -- Delete alerts
    DELETE FROM public.alerts WHERE user_id = current_user_id;

    -- Delete entries
    DELETE FROM public.entries WHERE user_id = current_user_id;

    -- Delete shifts
    DELETE FROM public.shifts WHERE user_id = current_user_id;

    -- Delete employers
    DELETE FROM public.employers WHERE user_id = current_user_id;

    -- Delete user subscriptions
    DELETE FROM public.user_subscriptions WHERE user_id = current_user_id;

    -- Delete user profile (this should be last as it's the main user record)
    DELETE FROM public.users_profile WHERE user_id = current_user_id;

    -- Note: We cannot delete from auth.users directly in Supabase
    -- The user will be signed out and their session invalidated

    RAISE NOTICE 'Successfully deleted all data for user %', current_user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;

-- Add documentation
COMMENT ON FUNCTION public.delete_account() IS 'Completely deletes all user data from all tables in the correct order';
COMMENT ON TABLE public.achievements IS 'Stores user achievements and badges earned in the app';
COMMENT ON TABLE public.alerts IS 'Stores in-app notifications and alerts for users';
COMMENT ON TABLE public.user_subscriptions IS 'Stores subscription information for cross-device synchronization';

-- ============================================
-- 5. VERIFY ALL TABLES EXIST
-- ============================================
-- This query will show all tables that should exist
SELECT table_name,
       obj_description(pgc.oid, 'pg_class') as description
FROM information_schema.tables t
JOIN pg_class pgc ON pgc.relname = t.table_name
WHERE table_schema = 'public'
AND table_name IN (
    'users_profile',
    'employers',
    'shifts',
    'entries',
    'achievements',
    'alerts',
    'user_subscriptions'
)
ORDER BY table_name;

-- You should see all 7 tables listed!