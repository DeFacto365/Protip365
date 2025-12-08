-- ================================================================
-- ProTip365 Migration Rollback Script
-- Date: September 2024
-- Purpose: Complete rollback to pre-migration state
-- ================================================================
--
-- ⚠️ EMERGENCY ROLLBACK PROCEDURE ⚠️
--
-- Use this script if the migration fails or causes issues.
-- This will restore the database to exactly the state before migration.
--
-- IMPORTANT: This script should only be run if something goes wrong!
-- ================================================================

-- ================================================================
-- STEP 1: VERIFY BACKUP EXISTS
-- ================================================================

-- Check that backup schema exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.schemata WHERE schema_name = 'backup_20240924') THEN
        RAISE EXCEPTION 'BACKUP SCHEMA NOT FOUND! Cannot proceed with rollback.';
    END IF;
END
$$;

-- Verify backup has data
SELECT
    'BACKUP VERIFICATION' as status,
    table_name,
    record_count
FROM backup_20240924.backup_metadata
WHERE backup_status LIKE '%COMPLETED%'
ORDER BY table_name;

-- ================================================================
-- STEP 2: DROP NEW TABLES (if they exist)
-- ================================================================

-- Drop new tables created during migration
DROP TABLE IF EXISTS public.shift_entries CASCADE;
DROP TABLE IF EXISTS public.expected_shifts CASCADE;

-- Drop any new views
DROP VIEW IF EXISTS public.v_expected_shifts CASCADE;
DROP VIEW IF EXISTS public.v_shift_entries CASCADE;

-- ================================================================
-- STEP 3: RESTORE ORIGINAL TABLES
-- ================================================================

-- Restore shifts table
DROP TABLE IF EXISTS public.shifts CASCADE;
CREATE TABLE public.shifts AS
SELECT * FROM backup_20240924.shifts;

-- Restore shift_income table
DROP TABLE IF EXISTS public.shift_income CASCADE;
CREATE TABLE public.shift_income AS
SELECT * FROM backup_20240924.shift_income;

-- Restore entries table (if it existed)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'backup_20240924' AND table_name = 'entries') THEN
        EXECUTE 'DROP TABLE IF EXISTS public.entries CASCADE';
        EXECUTE 'CREATE TABLE public.entries AS SELECT * FROM backup_20240924.entries';
    END IF;
END
$$;

-- Restore employers table
DROP TABLE IF EXISTS public.employers CASCADE;
CREATE TABLE public.employers AS
SELECT * FROM backup_20240924.employers;

-- ================================================================
-- STEP 4: RESTORE CONSTRAINTS AND PRIMARY KEYS
-- ================================================================

-- Add primary keys back
ALTER TABLE public.shifts ADD PRIMARY KEY (id);
ALTER TABLE public.shift_income ADD PRIMARY KEY (id);
ALTER TABLE public.employers ADD PRIMARY KEY (id);

-- Add foreign key constraints
ALTER TABLE public.shifts
ADD CONSTRAINT shifts_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.shifts
ADD CONSTRAINT shifts_employer_id_fkey
FOREIGN KEY (employer_id) REFERENCES public.employers(id) ON DELETE SET NULL;

ALTER TABLE public.shift_income
ADD CONSTRAINT shift_income_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.shift_income
ADD CONSTRAINT shift_income_shift_id_fkey
FOREIGN KEY (shift_id) REFERENCES public.shifts(id) ON DELETE CASCADE;

ALTER TABLE public.shift_income
ADD CONSTRAINT shift_income_employer_id_fkey
FOREIGN KEY (employer_id) REFERENCES public.employers(id) ON DELETE SET NULL;

ALTER TABLE public.employers
ADD CONSTRAINT employers_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- ================================================================
-- STEP 5: RESTORE INDEXES
-- ================================================================

-- Restore indexes from backup
DO $$
DECLARE
    index_record RECORD;
BEGIN
    FOR index_record IN
        SELECT indexdef
        FROM backup_20240924.table_indexes
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE index_record.indexdef;
        EXCEPTION WHEN others THEN
            -- Log error but continue
            RAISE NOTICE 'Could not restore index: %', index_record.indexdef;
        END;
    END LOOP;
END
$$;

-- ================================================================
-- STEP 6: RESTORE RLS POLICIES
-- ================================================================

-- Enable RLS on restored tables
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_income ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employers ENABLE ROW LEVEL SECURITY;

-- Restore RLS policies for shifts
CREATE POLICY "Users can view their own shifts" ON public.shifts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own shifts" ON public.shifts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own shifts" ON public.shifts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own shifts" ON public.shifts
    FOR DELETE USING (auth.uid() = user_id);

-- Restore RLS policies for shift_income
CREATE POLICY "Users can view their own shift income" ON public.shift_income
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own shift income" ON public.shift_income
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own shift income" ON public.shift_income
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own shift income" ON public.shift_income
    FOR DELETE USING (auth.uid() = user_id);

-- Restore RLS policies for employers
CREATE POLICY "Users can view their own employers" ON public.employers
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own employers" ON public.employers
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own employers" ON public.employers
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own employers" ON public.employers
    FOR DELETE USING (auth.uid() = user_id);

-- ================================================================
-- STEP 7: RESTORE VIEWS
-- ================================================================

-- Restore v_shift_income view
CREATE OR REPLACE VIEW public.v_shift_income AS
SELECT
    si.id as income_id,
    s.id as shift_id,
    si.user_id,
    s.employer_id,
    e.name as employer_name,
    s.shift_date,
    s.expected_hours,
    s.lunch_break_minutes,
    CASE
        WHEN s.expected_hours IS NOT NULL AND s.lunch_break_minutes IS NOT NULL THEN
            s.expected_hours - (s.lunch_break_minutes::decimal / 60)
        ELSE s.expected_hours
    END as net_expected_hours,
    si.actual_hours as hours,
    s.hourly_rate,
    si.sales,
    si.tips,
    si.cash_out,
    si.other,
    (si.actual_hours * s.hourly_rate) as base_income,
    (si.tips - COALESCE(si.cash_out, 0)) as net_tips,
    ((si.actual_hours * s.hourly_rate) + si.tips + COALESCE(si.other, 0) - COALESCE(si.cash_out, 0)) as total_income,
    CASE
        WHEN si.sales > 0 THEN (si.tips / si.sales * 100)
        ELSE 0
    END as tip_percentage,
    s.start_time,
    s.end_time,
    si.actual_start_time,
    si.actual_end_time,
    s.status as shift_status,
    s.created_at as shift_created_at,
    si.created_at as earnings_created_at,
    COALESCE(si.notes, s.notes) as notes
FROM public.shifts s
LEFT JOIN public.shift_income si ON s.id = si.shift_id
LEFT JOIN public.employers e ON s.employer_id = e.id;

-- ================================================================
-- STEP 8: VERIFY ROLLBACK SUCCESS
-- ================================================================

-- Verify data integrity
SELECT
    'ROLLBACK VERIFICATION' as status,
    'Original count: ' || (SELECT COUNT(*) FROM backup_20240924.shifts) as shifts_backup,
    'Restored count: ' || (SELECT COUNT(*) FROM public.shifts) as shifts_restored,
    CASE
        WHEN (SELECT COUNT(*) FROM backup_20240924.shifts) = (SELECT COUNT(*) FROM public.shifts)
        THEN '✅ SUCCESS'
        ELSE '❌ MISMATCH'
    END as shifts_status;

SELECT
    'shift_income verification' as table_name,
    'Original: ' || (SELECT COUNT(*) FROM backup_20240924.shift_income) as backup_count,
    'Restored: ' || (SELECT COUNT(*) FROM public.shift_income) as restored_count,
    CASE
        WHEN (SELECT COUNT(*) FROM backup_20240924.shift_income) = (SELECT COUNT(*) FROM public.shift_income)
        THEN '✅ SUCCESS'
        ELSE '❌ MISMATCH'
    END as status;

-- Test basic functionality
SELECT
    'FUNCTIONALITY TEST' as test_name,
    COUNT(*) as total_shifts,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_shifts,
    'Basic queries working' as result
FROM public.shifts;

-- ================================================================
-- STEP 9: CLEANUP (Optional)
-- ================================================================

-- Uncomment these lines if you want to remove the backup schema after successful rollback
-- WARNING: Only do this if you're absolutely sure the rollback worked!

/*
DROP SCHEMA IF EXISTS backup_20240924 CASCADE;
*/

-- ================================================================
-- ROLLBACK COMPLETION LOG
-- ================================================================

SELECT
    '🔄 ROLLBACK COMPLETED!' as message,
    'Database restored to pre-migration state' as status,
    'Verify application functionality' as next_steps,
    now() as completed_at;