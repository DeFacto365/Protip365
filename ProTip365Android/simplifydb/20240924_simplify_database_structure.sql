-- ================================================================
-- ProTip365 Database Simplification Migration
-- Date: September 2024
-- Purpose: Simplify overly complex database structure
-- ================================================================
--
-- CURRENT ISSUES:
-- - Multiple overlapping tables: shifts, shift_income, entries, v_shift_income
-- - Data duplication: shift_date, employer_id, hourly_rate in multiple tables
-- - Redundant fields: lunch_break_hours + lunch_break_minutes (only minutes used)
-- - Unused fields: entry_notes
-- - Complex queries requiring multiple joins
--
-- NEW SIMPLIFIED STRUCTURE:
-- 1. expected_shifts: Planning/scheduling data only
-- 2. shift_entries: Actual work done + financial data
-- ================================================================

-- ================================================================
-- PHASE 1: CREATE NEW SIMPLIFIED TABLES
-- ================================================================

-- 1. Create expected_shifts table (replaces shifts table)
CREATE TABLE IF NOT EXISTS expected_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    employer_id UUID REFERENCES employers(id) ON DELETE SET NULL,

    -- Scheduling data
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    expected_hours DECIMAL(5,2) NOT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL,

    -- Break time (keep only minutes, remove hours)
    lunch_break_minutes INTEGER DEFAULT 0,

    -- Status and metadata
    status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'completed', 'missed')),
    alert_minutes INTEGER, -- For notifications
    notes TEXT, -- Shift-specific planning notes

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create shift_entries table (replaces shift_income table)
CREATE TABLE IF NOT EXISTS shift_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES expected_shifts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Actual work times (what really happened)
    actual_start_time TIME NOT NULL,
    actual_end_time TIME NOT NULL,
    actual_hours DECIMAL(5,2) NOT NULL,

    -- Financial data (entry-specific, not planning-specific)
    sales DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,
    cash_out DECIMAL(10,2) DEFAULT 0,
    other DECIMAL(10,2) DEFAULT 0,

    -- Entry-specific notes
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    -- Ensure one entry per shift
    UNIQUE(shift_id)
);

-- ================================================================
-- PHASE 2: ENABLE RLS ON NEW TABLES
-- ================================================================

ALTER TABLE expected_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_entries ENABLE ROW LEVEL SECURITY;

-- RLS policies for expected_shifts
CREATE POLICY "Users can view own expected shifts" ON expected_shifts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own expected shifts" ON expected_shifts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own expected shifts" ON expected_shifts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own expected shifts" ON expected_shifts
    FOR DELETE USING (auth.uid() = user_id);

-- RLS policies for shift_entries
CREATE POLICY "Users can view own shift entries" ON shift_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own shift entries" ON shift_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own shift entries" ON shift_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own shift entries" ON shift_entries
    FOR DELETE USING (auth.uid() = user_id);

-- ================================================================
-- PHASE 3: CREATE INDEXES FOR PERFORMANCE
-- ================================================================

CREATE INDEX IF NOT EXISTS idx_expected_shifts_user_id ON expected_shifts(user_id);
CREATE INDEX IF NOT EXISTS idx_expected_shifts_employer_id ON expected_shifts(employer_id);
CREATE INDEX IF NOT EXISTS idx_expected_shifts_date ON expected_shifts(shift_date);
CREATE INDEX IF NOT EXISTS idx_expected_shifts_status ON expected_shifts(status);

CREATE INDEX IF NOT EXISTS idx_shift_entries_user_id ON shift_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_shift_entries_shift_id ON shift_entries(shift_id);

-- ================================================================
-- PHASE 4: DATA MIGRATION (TO BE EXECUTED AFTER VERIFICATION)
-- ================================================================

-- NOTE: These INSERT statements should be executed after verification
-- that the new tables are working correctly with the application

/*
-- Migrate shifts table to expected_shifts
INSERT INTO expected_shifts (
    id, user_id, employer_id, shift_date, start_time, end_time,
    expected_hours, hourly_rate, lunch_break_minutes, status,
    alert_minutes, notes, created_at, updated_at
)
SELECT
    id, user_id, employer_id, shift_date, start_time, end_time,
    expected_hours, hourly_rate,
    COALESCE(lunch_break_minutes, 0) as lunch_break_minutes,
    CASE
        WHEN status = 'scheduled' THEN 'planned'
        WHEN status = 'in_progress' THEN 'planned'
        ELSE status
    END as status,
    alert_minutes, notes, created_at, updated_at
FROM shifts
WHERE id IS NOT NULL;

-- Migrate shift_income table to shift_entries
INSERT INTO shift_entries (
    shift_id, user_id, actual_start_time, actual_end_time, actual_hours,
    sales, tips, cash_out, other, notes, created_at, updated_at
)
SELECT
    shift_id, user_id,
    COALESCE(actual_start_time, '00:00:00') as actual_start_time,
    COALESCE(actual_end_time, '23:59:59') as actual_end_time,
    actual_hours,
    COALESCE(sales, 0) as sales,
    COALESCE(tips, 0) as tips,
    COALESCE(cash_out, 0) as cash_out,
    COALESCE(other, 0) as other,
    notes, created_at, updated_at
FROM shift_income
WHERE shift_id IS NOT NULL
AND shift_id IN (SELECT id FROM expected_shifts);
*/

-- ================================================================
-- PHASE 5: CLEANUP (TO BE EXECUTED AFTER FULL VERIFICATION)
-- ================================================================

/*
-- Drop old complex structure (execute only after full migration verification)
DROP VIEW IF EXISTS v_shift_income;
DROP TABLE IF EXISTS shift_income;
DROP TABLE IF EXISTS shifts;
DROP TABLE IF EXISTS entries; -- if it exists
*/

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Use these queries to verify data integrity after migration:

-- 1. Count records in old vs new tables
-- SELECT 'shifts' as table_name, COUNT(*) FROM shifts
-- UNION ALL
-- SELECT 'expected_shifts' as table_name, COUNT(*) FROM expected_shifts
-- UNION ALL
-- SELECT 'shift_income' as table_name, COUNT(*) FROM shift_income
-- UNION ALL
-- SELECT 'shift_entries' as table_name, COUNT(*) FROM shift_entries;

-- 2. Check for missing relationships
-- SELECT COUNT(*) as orphaned_entries
-- FROM shift_entries se
-- LEFT JOIN expected_shifts es ON se.shift_id = es.id
-- WHERE es.id IS NULL;

-- 3. Sample data comparison
-- SELECT 'OLD' as source, COUNT(*) as shifts_count, SUM(expected_hours) as total_hours
-- FROM shifts
-- UNION ALL
-- SELECT 'NEW' as source, COUNT(*) as shifts_count, SUM(expected_hours) as total_hours
-- FROM expected_shifts;