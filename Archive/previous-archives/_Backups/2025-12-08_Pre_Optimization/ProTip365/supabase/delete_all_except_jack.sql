-- Delete all users except jack_77_77@hotmail.com
-- This script will delete users and all their associated data

-- First, let's see what users we have
DO $$
DECLARE
    user_count INTEGER;
    jack_id UUID;
BEGIN
    -- Get count of users to be deleted
    SELECT COUNT(*) INTO user_count
    FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com';

    RAISE NOTICE 'Found % users to delete', user_count;

    -- Get jack's user ID for verification
    SELECT id INTO jack_id
    FROM auth.users
    WHERE email = 'jack_77_77@hotmail.com';

    IF jack_id IS NOT NULL THEN
        RAISE NOTICE 'Preserving user jack_77_77@hotmail.com with ID: %', jack_id;
    ELSE
        RAISE WARNING 'User jack_77_77@hotmail.com not found!';
    END IF;
END $$;

-- Delete all achievements except for jack
DELETE FROM achievements
WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com'
);

-- Delete all alerts except for jack
DELETE FROM alerts
WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com'
);

-- Delete all entries except for jack
DELETE FROM entries
WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com'
);

-- Delete all shifts except for jack
DELETE FROM shifts
WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com'
);

-- Delete all shift_income except for jack
DELETE FROM shift_income
WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com'
);

-- Delete all employers except for jack
DELETE FROM employers
WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com'
);

-- Delete all user_subscriptions except for jack
DELETE FROM user_subscriptions
WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com'
);

-- Delete all user profiles except for jack
DELETE FROM users_profile
WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email != 'jack_77_77@hotmail.com'
);

-- Finally, delete the auth users themselves except for jack
-- Note: This uses the Supabase function to properly delete auth users
DO $$
DECLARE
    r RECORD;
    deleted_count INTEGER := 0;
BEGIN
    -- Loop through all users except jack
    FOR r IN
        SELECT id, email
        FROM auth.users
        WHERE email != 'jack_77_77@hotmail.com'
    LOOP
        BEGIN
            -- Use the Supabase auth.admin_delete_user function if available
            -- Otherwise, delete directly from auth.users
            DELETE FROM auth.users WHERE id = r.id;

            deleted_count := deleted_count + 1;
            RAISE NOTICE 'Deleted user: % (%)', r.email, r.id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Failed to delete user %: %', r.email, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE 'Successfully deleted % users', deleted_count;
END $$;

-- Verify remaining user
DO $$
DECLARE
    remaining_count INTEGER;
    jack_exists BOOLEAN;
BEGIN
    -- Count remaining users
    SELECT COUNT(*) INTO remaining_count FROM auth.users;

    -- Check if jack still exists
    SELECT EXISTS(
        SELECT 1 FROM auth.users
        WHERE email = 'jack_77_77@hotmail.com'
    ) INTO jack_exists;

    RAISE NOTICE 'Remaining users: %', remaining_count;

    IF jack_exists THEN
        RAISE NOTICE '✅ User jack_77_77@hotmail.com preserved successfully';
    ELSE
        RAISE WARNING '❌ User jack_77_77@hotmail.com was not found after deletion';
    END IF;

    -- Show remaining users
    FOR r IN SELECT email FROM auth.users LOOP
        RAISE NOTICE 'Remaining user: %', r.email;
    END LOOP;
END $$;