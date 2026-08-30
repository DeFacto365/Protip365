-- ProTip365 Security Warnings Fix
-- Addresses all security warnings from Supabase dashboard
-- ================================================================

-- ================================================================
-- 1. FIX FUNCTION SEARCH_PATH WARNINGS
-- ================================================================

-- Fix get_recent_shifts function
CREATE OR REPLACE FUNCTION get_recent_shifts(
    p_user_id UUID,
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE(
    id UUID,
    shift_date DATE,
    hours NUMERIC,
    hourly_rate NUMERIC,
    sales NUMERIC,
    tips NUMERIC,
    employer_id UUID,
    status TEXT
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
SET search_path = public, pg_catalog
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.shift_date,
        s.hours,
        s.hourly_rate,
        s.sales,
        s.tips,
        s.employer_id,
        s.status
    FROM public.shifts s
    WHERE s.user_id = p_user_id
        AND s.shift_date >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    ORDER BY s.shift_date DESC;
END;
$$;

-- Fix get_calendar_shifts function
CREATE OR REPLACE FUNCTION get_calendar_shifts(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    shift_date DATE,
    shift_count BIGINT,
    total_hours NUMERIC,
    total_tips NUMERIC,
    total_sales NUMERIC,
    has_completed BOOLEAN
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
SET search_path = public, pg_catalog
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.shift_date,
        COUNT(*) as shift_count,
        SUM(s.hours) as total_hours,
        SUM(s.tips) as total_tips,
        SUM(s.sales) as total_sales,
        BOOL_OR(s.status = 'completed') as has_completed
    FROM public.shifts s
    WHERE s.user_id = p_user_id
        AND s.shift_date BETWEEN p_start_date AND p_end_date
    GROUP BY s.shift_date
    ORDER BY s.shift_date;
END;
$$;

-- Fix set_default_hourly_rate function
CREATE OR REPLACE FUNCTION set_default_hourly_rate()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF NEW.hourly_rate IS NULL THEN
        SELECT default_hourly_rate INTO NEW.hourly_rate
        FROM public.users_profile
        WHERE user_id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$;

-- Fix handle_new_user function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
BEGIN
    INSERT INTO public.users_profile (
        user_id,
        email,
        created_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        NOW()
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- ================================================================
-- 2. AUTH SECURITY CONFIGURATION
-- ================================================================

-- Update auth.config for security best practices
-- Note: These require admin access and should be run in Supabase dashboard

/*
-- Reduce OTP expiry time to recommended 3600 seconds (1 hour)
UPDATE auth.config 
SET config = jsonb_set(config, '{OTP_EXPIRY}', '3600')
WHERE id = 1;

-- Enable leaked password protection
UPDATE auth.config 
SET config = jsonb_set(config, '{PASSWORD_MIN_LENGTH}', '8')
WHERE id = 1;

UPDATE auth.config 
SET config = jsonb_set(config, '{SECURITY_CHECK_HIBP}', 'true')
WHERE id = 1;
*/

-- ================================================================
-- 3. ADDITIONAL SECURITY ENHANCEMENTS
-- ================================================================

-- Add password complexity requirements function
CREATE OR REPLACE FUNCTION check_password_strength(password TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public, pg_catalog
AS $$
BEGIN
    -- Check minimum length
    IF LENGTH(password) < 8 THEN
        RETURN FALSE;
    END IF;
    
    -- Check for at least one uppercase letter
    IF NOT (password ~ '[A-Z]') THEN
        RETURN FALSE;
    END IF;
    
    -- Check for at least one lowercase letter
    IF NOT (password ~ '[a-z]') THEN
        RETURN FALSE;
    END IF;
    
    -- Check for at least one number
    IF NOT (password ~ '[0-9]') THEN
        RETURN FALSE;
    END IF;
    
    -- Check for at least one special character
    IF NOT (password ~ '[!@#$%^&*(),.?":{}|<>]') THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- Create function to check for commonly leaked passwords
CREATE OR REPLACE FUNCTION is_common_password(password TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public, pg_catalog
AS $$
DECLARE
    common_passwords TEXT[] := ARRAY[
        'password', '12345678', 'qwerty', 'abc123', 'password1',
        'password123', '123456789', 'welcome', 'monkey', '1234567890',
        'letmein', 'dragon', 'baseball', 'iloveyou', 'trustno1',
        'sunshine', 'master', '123123', 'welcome123', 'shadow',
        'ashley', 'football', 'jesus', 'michael', 'ninja',
        'mustang', 'password1', 'admin', 'hello', 'freedom'
    ];
BEGIN
    RETURN LOWER(password) = ANY(common_passwords);
END;
$$;

-- ================================================================
-- 4. AUDIT AND MONITORING
-- ================================================================

-- Create security audit log table
CREATE TABLE IF NOT EXISTS security_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    event_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for security audit queries
CREATE INDEX IF NOT EXISTS idx_security_audit_user_date 
ON security_audit_log(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_security_audit_event_date 
ON security_audit_log(event_type, created_at DESC);

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    p_event_type TEXT,
    p_user_id UUID DEFAULT NULL,
    p_event_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO public.security_audit_log (
        event_type,
        user_id,
        event_data,
        ip_address,
        user_agent
    ) VALUES (
        p_event_type,
        p_user_id,
        p_event_data,
        inet_client_addr(),
        current_setting('request.headers', true)::json->>'user-agent'
    )
    RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$;

-- ================================================================
-- 5. ROW LEVEL SECURITY ENHANCEMENT
-- ================================================================

-- Ensure RLS is enabled on all tables
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE employers ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

-- Add RLS policy for security audit log
CREATE POLICY "Users can view own security events" ON security_audit_log
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "System can insert security events" ON security_audit_log
    FOR INSERT WITH CHECK (true);

-- ================================================================
-- 6. VERIFY FIXES
-- ================================================================

-- Check function search paths are fixed
SELECT 
    proname as function_name,
    CASE 
        WHEN prosecdef THEN 'SECURITY DEFINER'
        ELSE 'SECURITY INVOKER'
    END as security_type,
    CASE
        WHEN proconfig::text LIKE '%search_path%' THEN '✅ Search path set'
        ELSE '⚠️ No search path'
    END as search_path_status
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
    AND prokind = 'f'
    AND proname IN (
        'get_recent_shifts',
        'get_calendar_shifts',
        'set_default_hourly_rate',
        'handle_new_user'
    )
ORDER BY proname;

-- ================================================================
-- 7. RECOMMENDATIONS OUTPUT
-- ================================================================

SELECT 'Security fixes applied' as status, 
       'Functions updated with explicit search_path' as description
UNION ALL
SELECT 'Manual action required', 
       'Update Postgres to latest version for security patches'
UNION ALL
SELECT 'Manual action required', 
       'Configure auth.config in Supabase dashboard for OTP and password settings'
UNION ALL
SELECT 'Security enhanced', 
       'Added password strength validation and audit logging';
