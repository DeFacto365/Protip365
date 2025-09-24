-- Drop the old function
DROP FUNCTION IF EXISTS public.delete_account();

-- Create a minimal function that only deletes from tables we know exist
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

    -- Only delete from tables that definitely exist
    -- These are the core tables that the app uses

    -- Delete entries
    DELETE FROM entries WHERE user_id = current_user_id;

    -- Delete shifts
    DELETE FROM shifts WHERE user_id = current_user_id;

    -- Delete employers
    DELETE FROM employers WHERE user_id = current_user_id;

    -- Delete user profile (this should be last as it's the main user record)
    DELETE FROM users_profile WHERE user_id = current_user_id;

    -- Note: The auth.users record remains but all app data is gone
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;

-- Add a comment to document the function
COMMENT ON FUNCTION public.delete_account() IS 'Deletes core user data from the database';