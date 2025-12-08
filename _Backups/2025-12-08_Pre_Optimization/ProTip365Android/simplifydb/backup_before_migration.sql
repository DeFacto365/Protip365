-- ================================================================
-- ProTip365 Complete Database Backup Before Migration
-- Date: September 2024
-- Purpose: Create comprehensive backup before database simplification
-- ================================================================
--
-- IMPORTANT: Execute these commands BEFORE running any migration!
-- This creates a complete snapshot that can be used for rollback.
-- ================================================================

-- ================================================================
-- STEP 1: CREATE BACKUP SCHEMA
-- ================================================================

-- Create a dedicated backup schema with timestamp
CREATE SCHEMA IF NOT EXISTS backup_20240924;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA backup_20240924 TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA backup_20240924 TO postgres;

-- ================================================================
-- STEP 2: BACKUP ALL EXISTING TABLES
-- ================================================================

-- Backup shifts table
CREATE TABLE backup_20240924.shifts AS
SELECT * FROM public.shifts;

-- Backup shift_income table
CREATE TABLE backup_20240924.shift_income AS
SELECT * FROM public.shift_income;

-- Backup entries table (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'entries') THEN
        EXECUTE 'CREATE TABLE backup_20240924.entries AS SELECT * FROM public.entries';
    END IF;
END
$$;

-- Backup employers table (dependency)
CREATE TABLE backup_20240924.employers AS
SELECT * FROM public.employers;

-- Backup users_profile table (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users_profile') THEN
        EXECUTE 'CREATE TABLE backup_20240924.users_profile AS SELECT * FROM public.users_profile';
    END IF;
END
$$;

-- Backup alerts table (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'alerts') THEN
        EXECUTE 'CREATE TABLE backup_20240924.alerts AS SELECT * FROM public.alerts';
    END IF;
END
$$;

-- ================================================================
-- STEP 3: BACKUP TABLE SCHEMAS AND CONSTRAINTS
-- ================================================================

-- Create a log table for metadata
CREATE TABLE backup_20240924.backup_metadata (
    backup_date TIMESTAMPTZ DEFAULT now(),
    table_name TEXT,
    record_count BIGINT,
    backup_status TEXT
);

-- Log backup information
INSERT INTO backup_20240924.backup_metadata (table_name, record_count, backup_status)
SELECT 'shifts', COUNT(*), 'COMPLETED' FROM backup_20240924.shifts
UNION ALL
SELECT 'shift_income', COUNT(*), 'COMPLETED' FROM backup_20240924.shift_income
UNION ALL
SELECT 'employers', COUNT(*), 'COMPLETED' FROM backup_20240924.employers;

-- Log entries table if it exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'backup_20240924' AND table_name = 'entries') THEN
        INSERT INTO backup_20240924.backup_metadata (table_name, record_count, backup_status)
        SELECT 'entries', COUNT(*), 'COMPLETED' FROM backup_20240924.entries;
    END IF;
END
$$;

-- ================================================================
-- STEP 4: BACKUP RLS POLICIES AND PERMISSIONS
-- ================================================================

-- Create backup of RLS policies
CREATE TABLE backup_20240924.rls_policies AS
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('shifts', 'shift_income', 'entries', 'employers');

-- Create backup of table constraints
CREATE TABLE backup_20240924.table_constraints AS
SELECT
    table_schema,
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public'
AND table_name IN ('shifts', 'shift_income', 'entries', 'employers');

-- ================================================================
-- STEP 5: BACKUP INDEXES
-- ================================================================

-- Create backup of indexes
CREATE TABLE backup_20240924.table_indexes AS
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('shifts', 'shift_income', 'entries', 'employers');

-- ================================================================
-- STEP 6: BACKUP VIEWS AND FUNCTIONS
-- ================================================================

-- Backup view definitions
CREATE TABLE backup_20240924.view_definitions AS
SELECT
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public';

-- ================================================================
-- STEP 7: VERIFY BACKUP INTEGRITY
-- ================================================================

-- Verification query - run this to confirm backup
SELECT
    'BACKUP VERIFICATION' as status,
    backup_date,
    table_name,
    record_count,
    backup_status
FROM backup_20240924.backup_metadata
ORDER BY table_name;

-- Additional verification - compare counts
SELECT
    'ORIGINAL' as source,
    'shifts' as table_name,
    COUNT(*) as record_count
FROM public.shifts
UNION ALL
SELECT
    'BACKUP' as source,
    'shifts' as table_name,
    COUNT(*) as record_count
FROM backup_20240924.shifts
UNION ALL
SELECT
    'ORIGINAL' as source,
    'shift_income' as table_name,
    COUNT(*) as record_count
FROM public.shift_income
UNION ALL
SELECT
    'BACKUP' as source,
    'shift_income' as table_name,
    COUNT(*) as record_count
FROM backup_20240924.shift_income
ORDER BY table_name, source;

-- ================================================================
-- BACKUP COMPLETION LOG
-- ================================================================

-- Final log entry
INSERT INTO backup_20240924.backup_metadata (table_name, record_count, backup_status)
VALUES ('BACKUP_PROCESS', 0, 'COMPLETED - ' || now()::TEXT);

-- Show final status
SELECT
    '🎯 BACKUP COMPLETED SUCCESSFULLY!' as message,
    'Schema: backup_20240924' as backup_location,
    'Execute rollback.sql if needed' as next_steps;