-- Supabase security QA fixes:
-- 1. Prevent anon/public email enumeration through check_email_exists.
-- 2. Provide transactional account cleanup for the delete-account Edge Function.

CREATE OR REPLACE FUNCTION public.check_email_exists(check_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
  RETURN TRUE;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.check_email_exists(TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.check_email_exists(TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO service_role;

CREATE OR REPLACE FUNCTION public.delete_user_owned_data(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  cleanup_table TEXT;
  cleanup_tables TEXT[] := ARRAY[
    'password_reset_tokens',
    'security_audit_log',
    'performance_logs',
    'shift_entries',
    'shift_income',
    'entries',
    'alerts',
    'achievements',
    'expected_shifts',
    'shifts',
    'user_subscriptions'
  ];
BEGIN
  IF target_user_id IS NULL THEN
    RAISE EXCEPTION 'target_user_id is required';
  END IF;

  FOREACH cleanup_table IN ARRAY cleanup_tables LOOP
    IF to_regclass(format('public.%I', cleanup_table)) IS NOT NULL AND EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = cleanup_table
        AND column_name = 'user_id'
    ) THEN
      EXECUTE format('DELETE FROM public.%I WHERE user_id = $1', cleanup_table)
      USING target_user_id;
    END IF;
  END LOOP;

  IF to_regclass('public.users_profile') IS NOT NULL THEN
    IF EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'users_profile'
        AND column_name = 'default_employer_id'
    ) THEN
      UPDATE public.users_profile
      SET default_employer_id = NULL
      WHERE user_id = target_user_id;
    END IF;
  END IF;

  IF to_regclass('public.employers') IS NOT NULL THEN
    DELETE FROM public.employers WHERE user_id = target_user_id;
  END IF;

  IF to_regclass('public.users_profile') IS NOT NULL THEN
    DELETE FROM public.users_profile WHERE user_id = target_user_id;
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_user_owned_data(UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_user_owned_data(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.delete_user_owned_data(UUID) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_owned_data(UUID) TO service_role;
