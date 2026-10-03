-- Check what delete functions exist in the database
SELECT
    proname as function_name,
    pronargs as num_arguments
FROM pg_proc
WHERE proname LIKE '%delete%account%'
    OR proname LIKE 'delete_account'
    OR proname LIKE 'delete-account';

-- If you need to create the function with underscores instead:
-- First drop the old one if it exists
DROP FUNCTION IF EXISTS public."delete-account"();

-- Create with underscores (more standard for PostgreSQL)
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

    -- Delete all user data in the correct order (to respect foreign key constraints)
    DELETE FROM achievements WHERE user_id = current_user_id;
    DELETE FROM alerts WHERE user_id = current_user_id;
    DELETE FROM entries WHERE user_id = current_user_id;
    DELETE FROM shifts WHERE user_id = current_user_id;
    DELETE FROM employers WHERE user_id = current_user_id;
    DELETE FROM user_subscriptions WHERE user_id = current_user_id;
    DELETE FROM users_profile WHERE user_id = current_user_id;

    -- Note: We cannot delete from auth.users directly in most Supabase setups
    -- The user needs to be deleted through Supabase Auth Admin API
    -- For now, all user data is deleted and they can't log in to see anything
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;

-- Add a comment to document the function
COMMENT ON FUNCTION public.delete_account() IS 'Deletes the current user data (except auth record)';