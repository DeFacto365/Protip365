-- Check RLS status for all tables and views
SELECT
    schemaname,
    tablename,
    rowsecurity,
    CASE
        WHEN rowsecurity THEN 'RLS Enabled'
        ELSE 'RLS Disabled'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Check policies on shifts table
SELECT
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('shifts', 'shift_income')
ORDER BY tablename, policyname;

-- Check if v_shift_income view exists and what it's based on
SELECT
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public'
AND viewname = 'v_shift_income';