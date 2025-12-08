-- ================================================================
-- ProTip365 - Complete Old Table Cleanup
-- Date: September 2024
-- Purpose: Remove all old complex tables and start fresh
-- ================================================================

-- ⚠️ WARNING: This will DELETE ALL old data permanently!
-- Only run this if you're sure you want to start fresh.
-- ================================================================

-- ================================================================
-- STEP 1: DROP ALL OLD VIEWS FIRST
-- ================================================================

-- Drop the complex view
DROP VIEW IF EXISTS public.v_shift_income CASCADE;
DROP VIEW IF EXISTS public.v_upcoming_shift_alerts CASCADE;

-- ================================================================
-- STEP 2: DROP ALL OLD TABLES
-- ================================================================

-- Drop old complex tables (this deletes all old data)
DROP TABLE IF EXISTS public.shift_income CASCADE;
DROP TABLE IF EXISTS public.shifts CASCADE;
DROP TABLE IF EXISTS public.entries CASCADE;

-- ================================================================
-- STEP 3: CLEAN UP BACKUP (Optional)
-- ================================================================

-- Uncomment these lines if you want to remove backup schema too
-- (Only do this if you're absolutely sure you don't need the old data)

/*
DROP SCHEMA IF EXISTS backup_20240924 CASCADE;
*/

-- ================================================================
-- STEP 4: VERIFY CLEAN STATE
-- ================================================================

-- Show remaining tables (should only show new clean structure)
SELECT
    table_name,
    'REMAINING' as status
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'shifts', 'shift_income', 'entries', 'v_shift_income',
    'expected_shifts', 'shift_entries'
)
ORDER BY table_name;

-- ================================================================
-- FINAL RESULT
-- ================================================================

SELECT
    '🧹 OLD TABLES CLEANED UP!' as message,
    'Only expected_shifts and shift_entries remain' as new_structure,
    'Ready for fresh data!' as status;