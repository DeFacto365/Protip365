-- Create a function that allows users to delete their own account
CREATE OR REPLACE FUNCTION delete_user_account()
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

    -- Delete shift_income records
    DELETE FROM shift_income WHERE user_id = current_user_id;

    -- Delete shifts
    DELETE FROM shifts WHERE user_id = current_user_id;

    -- Delete employers
    DELETE FROM employers WHERE user_id = current_user_id;

    -- Delete user profile
    DELETE FROM users_profile WHERE user_id = current_user_id;

    -- Finally, delete the auth user
    -- This uses Supabase's auth.users table
    DELETE FROM auth.users WHERE id = current_user_id;

END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;

-- Add a comment for documentation
COMMENT ON FUNCTION delete_user_account() IS 'Allows authenticated users to delete their own account and all associated data';