-- Delete test users and all their associated data
-- This script removes all data for the specified test users

-- User IDs to delete
-- e7728de7-8359-4575-a739-d94ba4346786 - bolduc67@outlook.com
-- 5bcb4654-964b-4036-b6ee-1b4e929db4aa - lauriebolduc@hotmail.com

BEGIN;

-- Delete from all tables in reverse dependency order
-- These users' IDs
DO $$
DECLARE
    user1_id UUID := 'e7728de7-8359-4575-a739-d94ba4346786';
    user2_id UUID := '5bcb4654-964b-4036-b6ee-1b4e929db4aa';
BEGIN
    -- Delete achievements
    DELETE FROM public.achievements WHERE user_id IN (user1_id, user2_id);

    -- Delete alerts
    DELETE FROM public.alerts WHERE user_id IN (user1_id, user2_id);

    -- Delete entries
    DELETE FROM public.entries WHERE user_id IN (user1_id, user2_id);

    -- Delete shifts
    DELETE FROM public.shifts WHERE user_id IN (user1_id, user2_id);

    -- Delete employers
    DELETE FROM public.employers WHERE user_id IN (user1_id, user2_id);

    -- Delete user subscriptions
    DELETE FROM public.user_subscriptions WHERE user_id IN (user1_id, user2_id);

    -- Delete user profiles
    DELETE FROM public.users_profile WHERE user_id IN (user1_id, user2_id);

    -- Finally, delete from auth.users (this requires admin privileges)
    DELETE FROM auth.users WHERE id IN (user1_id, user2_id);

    RAISE NOTICE 'Successfully deleted users and all associated data';
END $$;

COMMIT;

-- Verify deletion
SELECT 'Remaining users in auth.users:' as check_type, COUNT(*) as count
FROM auth.users
WHERE id IN ('e7728de7-8359-4575-a739-d94ba4346786', '5bcb4654-964b-4036-b6ee-1b4e929db4aa')
UNION ALL
SELECT 'Remaining profiles:', COUNT(*)
FROM public.users_profile
WHERE user_id IN ('e7728de7-8359-4575-a739-d94ba4346786', '5bcb4654-964b-4036-b6ee-1b4e929db4aa');