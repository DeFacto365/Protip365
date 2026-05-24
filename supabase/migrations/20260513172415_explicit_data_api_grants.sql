-- Explicit Data API grants for Supabase public-schema hardening.
--
-- Supabase is removing implicit Data API exposure for newly-created public
-- tables/functions. Keep grants next to schema setup so replaying migrations
-- into a new project exposes only the intended authenticated API surface.

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

DO $$
DECLARE
    table_name text;
    view_name text;
BEGIN
    -- User-owned app tables accessed through supabase-js from the mobile app.
    FOREACH table_name IN ARRAY ARRAY[
        'users_profile',
        'employers',
        'shifts',
        'shift_income',
        'expected_shifts',
        'shift_entries',
        'entries',
        'alerts',
        'achievements',
        'user_subscriptions'
    ] LOOP
        IF to_regclass(format('public.%I', table_name)) IS NOT NULL THEN
            EXECUTE format(
                'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.%I TO authenticated',
                table_name
            );
            EXECUTE format(
                'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.%I TO service_role',
                table_name
            );
        END IF;
    END LOOP;

    -- Internal tables should stay unavailable to anon/authenticated clients but
    -- remain reachable to service-role jobs and Edge Functions.
    FOREACH table_name IN ARRAY ARRAY[
        'password_reset_tokens',
        'security_audit_log',
        'performance_logs',
        'performance_baseline'
    ] LOOP
        IF to_regclass(format('public.%I', table_name)) IS NOT NULL THEN
            EXECUTE format(
                'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.%I TO service_role',
                table_name
            );
        END IF;
    END LOOP;

    -- Read-only views exposed to authenticated app users.
    FOREACH view_name IN ARRAY ARRAY[
        'v_shift_income',
        'v_upcoming_shift_alerts'
    ] LOOP
        IF to_regclass(format('public.%I', view_name)) IS NOT NULL THEN
            EXECUTE format('GRANT SELECT ON TABLE public.%I TO authenticated', view_name);
            EXECUTE format('GRANT SELECT ON TABLE public.%I TO service_role', view_name);
        END IF;
    END LOOP;
END $$;

DO $$
BEGIN
    IF to_regprocedure('public.check_email_exists(text)') IS NOT NULL THEN
        GRANT EXECUTE ON FUNCTION public.check_email_exists(text) TO anon, authenticated, service_role;
    END IF;

    IF to_regprocedure('public.delete_account()') IS NOT NULL THEN
        GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated, service_role;
    END IF;

    IF to_regprocedure('public.get_recent_shifts(uuid, integer)') IS NOT NULL THEN
        GRANT EXECUTE ON FUNCTION public.get_recent_shifts(uuid, integer) TO authenticated, service_role;
    END IF;

    IF to_regprocedure('public.get_calendar_shifts(uuid, date, date)') IS NOT NULL THEN
        GRANT EXECUTE ON FUNCTION public.get_calendar_shifts(uuid, date, date) TO authenticated, service_role;
    END IF;

    IF to_regprocedure('public.get_dashboard_data_cached(uuid, integer)') IS NOT NULL THEN
        GRANT EXECUTE ON FUNCTION public.get_dashboard_data_cached(uuid, integer) TO authenticated, service_role;
    END IF;

    IF to_regprocedure('public.bulk_insert_shifts(jsonb)') IS NOT NULL THEN
        GRANT EXECUTE ON FUNCTION public.bulk_insert_shifts(jsonb) TO authenticated, service_role;
    END IF;
END $$;
