-- Drop the old function
DROP FUNCTION IF EXISTS public.delete_account();

-- Create updated function that only deletes from existing tables
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

    -- Delete all user data from existing tables
    -- Note: achievements table doesn't exist, so removed

    -- Delete alerts if table exists
    DELETE FROM alerts WHERE user_id = current_user_id;

    -- Delete entries
    DELETE FROM entries WHERE user_id = current_user_id;

    -- Delete shifts
    DELETE FROM shifts WHERE user_id = current_user_id;

    -- Delete employers
    DELETE FROM employers WHERE user_id = current_user_id;

    -- Delete user_subscriptions if exists
    BEGIN
        DELETE FROM user_subscriptions WHERE user_id = current_user_id;
    EXCEPTION
        WHEN undefined_table THEN
            -- Table doesn't exist, continue
            NULL;
    END;

    -- Delete user profile
    DELETE FROM users_profile WHERE user_id = current_user_id;

    -- Note: Cannot delete from auth.users directly in Supabase
    -- The user session will be invalidated when they sign out
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;

-- Add a comment to document the function
COMMENT ON FUNCTION public.delete_account() IS 'Deletes all user data from the database';