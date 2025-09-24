-- ProTip365 Performance Analysis - SUPABASE COMPATIBLE
-- Each section can be run independently to avoid errors
-- ================================================================

-- ================================================================
-- SECTION 1: BASIC TABLE INFO (TEST THIS FIRST)
-- ================================================================

-- Get table sizes
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(relid) DESC;

-- ================================================================
-- SECTION 2: CHECK YOUR ACTUAL DATA VOLUME
-- ================================================================

-- Simple count of your data
SELECT 'shifts' as table_name, COUNT(*) as row_count FROM shifts
UNION ALL
SELECT 'entries', COUNT(*) FROM entries
UNION ALL
SELECT 'alerts', COUNT(*) FROM alerts
UNION ALL
SELECT 'employers', COUNT(*) FROM employers
UNION ALL
SELECT 'achievements', COUNT(*) FROM achievements
UNION ALL
SELECT 'user_subscriptions', COUNT(*) FROM user_subscriptions
ORDER BY row_count DESC;

-- ================================================================
-- SECTION 3: USER ACTIVITY ANALYSIS
-- ================================================================

-- How many active users do you actually have?
SELECT
    COUNT(DISTINCT user_id) as total_users,
    COUNT(*) as total_shifts,
    ROUND(AVG(shift_count), 2) as avg_shifts_per_user,
    MAX(shift_count) as max_shifts_single_user
FROM (
    SELECT user_id, COUNT(*) as shift_count
    FROM shifts
    GROUP BY user_id
) user_stats;

-- User activity in last 30 days
SELECT
    COUNT(DISTINCT user_id) as active_users_30d,
    COUNT(*) as shifts_30d
FROM shifts
WHERE shift_date >= CURRENT_DATE - INTERVAL '30 days';

-- ================================================================
-- SECTION 4: CHECK EXISTING INDEXES
-- ================================================================

-- List all your indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ================================================================
-- SECTION 5: FIND SLOW PATTERNS (SIMPLE VERSION)
-- ================================================================

-- Check which operations are most common
SELECT
    relname AS table_name,
    n_tup_ins AS inserts,
    n_tup_upd AS updates,
    n_tup_del AS deletes,
    seq_scan AS table_scans,
    idx_scan AS index_scans
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY (n_tup_ins + n_tup_upd + n_tup_del) DESC;

-- ================================================================
-- SECTION 6: DATA GROWTH ANALYSIS
-- ================================================================

-- Monthly growth trend
SELECT
    TO_CHAR(shift_date, 'YYYY-MM') as month,
    COUNT(*) as shifts,
    COUNT(DISTINCT user_id) as unique_users
FROM shifts
WHERE shift_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY TO_CHAR(shift_date, 'YYYY-MM')
ORDER BY month DESC;

-- ================================================================
-- SECTION 7: CHECK FOR MISSING CRITICAL INDEXES
-- ================================================================

-- Check if these critical indexes exist
SELECT
    'shifts_user_date' as needed_index,
    EXISTS(
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'shifts'
        AND indexdef LIKE '%user_id%'
        AND indexdef LIKE '%shift_date%'
    ) as exists
UNION ALL
SELECT
    'alerts_user_unread',
    EXISTS(
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'alerts'
        AND indexdef LIKE '%user_id%'
        AND indexdef LIKE '%is_read%'
    )
UNION ALL
SELECT
    'entries_user_date',
    EXISTS(
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'entries'
        AND indexdef LIKE '%user_id%'
        AND indexdef LIKE '%entry_date%'
    )
UNION ALL
SELECT
    'employers_user',
    EXISTS(
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'employers'
        AND indexdef LIKE '%user_id%'
    );

-- ================================================================
-- SECTION 8: TEST SPECIFIC QUERY PERFORMANCE
-- ================================================================

-- Test query 1: Dashboard data (most common query)
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), SUM(tips), SUM(sales)
FROM shifts
WHERE user_id = (SELECT user_id FROM shifts LIMIT 1)
  AND shift_date >= CURRENT_DATE - INTERVAL '30 days';

-- Test query 2: Calendar view (second most common)
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM shifts
WHERE user_id = (SELECT user_id FROM shifts LIMIT 1)
  AND shift_date BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE
ORDER BY shift_date DESC;

-- ================================================================
-- SECTION 9: CONNECTION ANALYSIS
-- ================================================================

-- Current connections
SELECT
    COUNT(*) as total_connections,
    COUNT(DISTINCT usename) as unique_users,
    COUNT(*) FILTER (WHERE state = 'active') as active_queries,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_connections
FROM pg_stat_activity
WHERE datname = current_database();

-- ================================================================
-- SECTION 10: QUICK PERFORMANCE SCORE
-- ================================================================

-- Performance summary
WITH stats AS (
    SELECT
        (SELECT COUNT(DISTINCT user_id) FROM shifts) as users,
        (SELECT COUNT(*) FROM shifts) as shifts,
        (SELECT COUNT(*) FROM shifts WHERE shift_date >= CURRENT_DATE - INTERVAL '30 days') as recent_shifts,
        (SELECT relname FROM pg_stat_user_tables WHERE schemaname = 'public' ORDER BY seq_scan DESC LIMIT 1) as most_scanned_table,
        (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public') as index_count
)
SELECT
    users as total_users,
    shifts as total_shifts,
    recent_shifts as shifts_last_30d,
    ROUND(shifts::numeric / NULLIF(users, 0), 2) as avg_shifts_per_user,
    most_scanned_table,
    index_count,
    CASE
        WHEN users < 100 THEN 'Development'
        WHEN users < 500 THEN 'Growing - Optimize Now'
        WHEN users < 1000 THEN 'Scale Ready - Critical'
        ELSE 'High Scale - Needs Architecture Review'
    END as stage
FROM stats;

-- ================================================================
-- SECTION 11: GENERATE OPTIMIZATION COMMANDS
-- ================================================================

-- Create the indexes you actually need
SELECT
    '-- Run these commands to optimize for 1000+ users:' as optimization_commands
UNION ALL
SELECT
    'CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shifts_user_date ON shifts(user_id, shift_date DESC);'
UNION ALL
SELECT
    'CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_unread ON alerts(user_id, created_at DESC) WHERE is_read = false;'
UNION ALL
SELECT
    'CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_entries_user_date ON entries(user_id, entry_date DESC);'
UNION ALL
SELECT
    'CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shifts_status ON shifts(status) WHERE status = ''completed'';'
UNION ALL
SELECT
    'CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_employers_active ON employers(user_id) WHERE active = true;'
UNION ALL
SELECT
    'ANALYZE shifts; ANALYZE entries; ANALYZE alerts; -- Update statistics';

-- ================================================================
-- SECTION 12: CAPACITY PLANNING
-- ================================================================

-- Project when you'll hit 1000 users
WITH growth AS (
    SELECT
        DATE_TRUNC('month', created_at) as month,
        COUNT(DISTINCT user_id) as new_users
    FROM users_profile
    WHERE created_at >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('month', created_at)
),
trend AS (
    SELECT
        AVG(new_users) as avg_monthly_growth,
        (SELECT COUNT(DISTINCT user_id) FROM users_profile) as current_users
    FROM growth
)
SELECT
    current_users as current_user_count,
    ROUND(avg_monthly_growth, 2) as avg_new_users_per_month,
    CASE
        WHEN avg_monthly_growth > 0 THEN
            ROUND((1000 - current_users) / avg_monthly_growth, 1)
        ELSE NULL
    END as months_to_1000_users,
    CASE
        WHEN avg_monthly_growth > 0 THEN
            (CURRENT_DATE + INTERVAL '1 month' * ROUND((1000 - current_users) / avg_monthly_growth))::date
        ELSE NULL
    END as projected_1000_users_date
FROM trend;