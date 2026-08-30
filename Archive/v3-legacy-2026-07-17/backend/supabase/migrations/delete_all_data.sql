-- ⚠️ DANGER: Delete ALL data including users from ProTip365 database
-- This script will delete EVERYTHING - use only for testing/development

-- IMPORTANT: This must be run as a Supabase admin or service role
-- Regular users cannot delete auth.users

BEGIN;

-- Step 1: Disable RLS temporarily for deletion (only for tables that exist)
DO $$
BEGIN
    -- Disable RLS on tables that exist
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'shift_entries') THEN
        ALTER TABLE shift_entries DISABLE ROW LEVEL SECURITY;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'expected_shifts') THEN
        ALTER TABLE expected_shifts DISABLE ROW LEVEL SECURITY;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'employers') THEN
        ALTER TABLE employers DISABLE ROW LEVEL SECURITY;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_subscriptions') THEN
        ALTER TABLE user_subscriptions DISABLE ROW LEVEL SECURITY;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'users_profile') THEN
        ALTER TABLE users_profile DISABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Step 2: Delete all data from application tables (in correct order due to foreign keys)

-- First, clear default_employer_id references in users_profile to avoid FK constraint
UPDATE users_profile SET default_employer_id = NULL WHERE default_employer_id IS NOT NULL;

-- Delete shift entries first (references expected_shifts)
DELETE FROM shift_entries WHERE TRUE;

-- Delete expected shifts (references employers)
DELETE FROM expected_shifts WHERE TRUE;

-- Delete employers (now safe after clearing FK references)
DELETE FROM employers WHERE TRUE;

-- Delete user subscriptions
DELETE FROM user_subscriptions WHERE TRUE;

-- Delete users profile
DELETE FROM users_profile WHERE TRUE;

-- Step 3: Delete all users from auth.users (requires admin/service role)
-- This will cascade delete to auth.identities and related auth tables
DELETE FROM auth.users WHERE TRUE;

-- Step 4: Re-enable RLS
DO $$
BEGIN
    -- Re-enable RLS on tables that exist
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'shift_entries') THEN
        ALTER TABLE shift_entries ENABLE ROW LEVEL SECURITY;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'expected_shifts') THEN
        ALTER TABLE expected_shifts ENABLE ROW LEVEL SECURITY;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'employers') THEN
        ALTER TABLE employers ENABLE ROW LEVEL SECURITY;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_subscriptions') THEN
        ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'users_profile') THEN
        ALTER TABLE users_profile ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Step 5: Verify deletion
DO $$
DECLARE
    auth_user_count INTEGER;
    profile_count INTEGER;
    employer_count INTEGER;
    expected_shift_count INTEGER;
    entry_count INTEGER;
    subscription_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO auth_user_count FROM auth.users;
    SELECT COUNT(*) INTO profile_count FROM users_profile;
    SELECT COUNT(*) INTO employer_count FROM employers;
    SELECT COUNT(*) INTO expected_shift_count FROM expected_shifts;
    SELECT COUNT(*) INTO entry_count FROM shift_entries;
    SELECT COUNT(*) INTO subscription_count FROM user_subscriptions;

    RAISE NOTICE '=== DELETION COMPLETE ===';
    RAISE NOTICE 'Auth users remaining: %', auth_user_count;
    RAISE NOTICE 'User profiles remaining: %', profile_count;
    RAISE NOTICE 'Employers remaining: %', employer_count;
    RAISE NOTICE 'Expected shifts remaining: %', expected_shift_count;
    RAISE NOTICE 'Shift entries remaining: %', entry_count;
    RAISE NOTICE 'User subscriptions remaining: %', subscription_count;
    RAISE NOTICE '========================';
END $$;

COMMIT;

-- Alternative: If you want to keep RLS disabled for fresh start, comment out Step 4
-- Alternative: If you want to delete specific users, replace DELETE FROM auth.users with:
-- DELETE FROM auth.users WHERE email = 'specific@email.com';
