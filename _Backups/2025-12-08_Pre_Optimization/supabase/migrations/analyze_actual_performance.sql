-- ProTip365 ACTUAL Performance Analysis
-- Run these queries IN YOUR SUPABASE SQL EDITOR to get real metrics
-- ================================================================

-- ================================================================
-- STEP 1: GET ACTUAL TABLE SIZES AND ROW COUNTS
-- ================================================================

-- This shows your ACTUAL data volume
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_indexes_size(relid)) AS indexes_size,
    n_live_tup AS estimated_rows,
    n_dead_tup AS dead_rows,
    last_vacuum,
    last_autovacuum,
    CASE
        WHEN n_live_tup > 0 THEN
            ROUND((n_dead_tup::numeric / n_live_tup) * 100, 2)
        ELSE 0
    END AS bloat_percentage
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(relid) DESC;

-- ================================================================
-- STEP 2: ANALYZE YOUR ACTUAL QUERY PATTERNS
-- ================================================================

-- Check which tables are being hit the most
SELECT
    schemaname,
    tablename,
    n_tup_ins AS rows_inserted,
    n_tup_upd AS rows_updated,
    n_tup_del AS rows_deleted,
    seq_scan AS sequential_scans,
    idx_scan AS index_scans,
    CASE
        WHEN (seq_scan + idx_scan) > 0 THEN
            ROUND((seq_scan::numeric / (seq_scan + idx_scan)) * 100, 2)
        ELSE 0
    END AS seq_scan_ratio
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY (n_tup_ins + n_tup_upd + n_tup_del) DESC;

-- ================================================================
-- STEP 3: FIND YOUR ACTUAL SLOW QUERIES
-- ================================================================

-- Currently running queries
SELECT
    pid,
    NOW() - pg_stat_activity.query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE (NOW() - pg_stat_activity.query_start) > interval '2 seconds'
AND state != 'idle'
AND query NOT LIKE '%pg_stat%';

-- ================================================================
-- STEP 4: CHECK YOUR ACTUAL INDEX USAGE
-- ================================================================

-- Which indexes are actually being used?
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan / GREATEST(1, (SELECT SUM(idx_scan) FROM pg_stat_user_indexes WHERE schemaname = 'public')) * 100 AS usage_percentage
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Unused indexes (wasting space)
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
    AND idx_scan = 0
    AND indexrelname NOT LIKE 'pg_toast%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- ================================================================
-- STEP 5: ANALYZE YOUR v_shift_income VIEW PERFORMANCE
-- ================================================================

-- Test the actual performance of your view
EXPLAIN ANALYZE
SELECT * FROM v_shift_income
WHERE user_id = (SELECT user_id FROM shifts LIMIT 1)
LIMIT 100;

-- ================================================================
-- STEP 6: CHECK YOUR ACTUAL USER LOAD
-- ================================================================

-- How many ACTUAL active users do you have?
SELECT
    COUNT(DISTINCT user_id) as total_users,
    COUNT(DISTINCT CASE WHEN shift_date >= CURRENT_DATE - INTERVAL '7 days' THEN user_id END) as active_week,
    COUNT(DISTINCT CASE WHEN shift_date >= CURRENT_DATE - INTERVAL '30 days' THEN user_id END) as active_month,
    COUNT(*) as total_shifts,
    ROUND(COUNT(*)::numeric / COUNT(DISTINCT user_id), 2) as avg_shifts_per_user
FROM shifts;

-- User activity distribution
SELECT
    CASE
        WHEN last_activity < CURRENT_DATE - INTERVAL '90 days' THEN 'Inactive (>90 days)'
        WHEN last_activity < CURRENT_DATE - INTERVAL '30 days' THEN 'Dormant (30-90 days)'
        WHEN last_activity < CURRENT_DATE - INTERVAL '7 days' THEN 'Active (7-30 days)'
        ELSE 'Very Active (<7 days)'
    END as user_status,
    COUNT(*) as user_count,
    ROUND(COUNT(*)::numeric / (SELECT COUNT(DISTINCT user_id) FROM shifts) * 100, 2) as percentage
FROM (
    SELECT user_id, MAX(shift_date) as last_activity
    FROM shifts
    GROUP BY user_id
) user_activity
GROUP BY user_status
ORDER BY
    CASE user_status
        WHEN 'Very Active (<7 days)' THEN 1
        WHEN 'Active (7-30 days)' THEN 2
        WHEN 'Dormant (30-90 days)' THEN 3
        ELSE 4
    END;

-- ================================================================
-- STEP 7: CONNECTION POOL ANALYSIS
-- ================================================================

-- Current connections
SELECT
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active,
    COUNT(*) FILTER (WHERE state = 'idle') as idle,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
    MAX(EXTRACT(EPOCH FROM (NOW() - state_change))) as longest_idle_seconds
FROM pg_stat_activity
WHERE datname = current_database();

-- ================================================================
-- STEP 8: DATA GROWTH PROJECTION
-- ================================================================

-- Calculate growth rate
WITH monthly_growth AS (
    SELECT
        DATE_TRUNC('month', shift_date) as month,
        COUNT(*) as shifts_count,
        COUNT(DISTINCT user_id) as users_count
    FROM shifts
    WHERE shift_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY month
    ORDER BY month
)
SELECT
    month,
    shifts_count,
    users_count,
    shifts_count - LAG(shifts_count) OVER (ORDER BY month) as shift_growth,
    users_count - LAG(users_count) OVER (ORDER BY month) as user_growth,
    ROUND(
        (shifts_count - LAG(shifts_count) OVER (ORDER BY month))::numeric /
        NULLIF(LAG(shifts_count) OVER (ORDER BY month), 0) * 100,
        2
    ) as growth_percentage
FROM monthly_growth;

-- ================================================================
-- STEP 9: BOTTLENECK IDENTIFICATION
-- ================================================================

-- Tables with high sequential scan ratio (need indexes)
SELECT
    tablename,
    seq_scan,
    idx_scan,
    ROUND((seq_scan::numeric / NULLIF(seq_scan + idx_scan, 0)) * 100, 2) as seq_scan_percentage,
    'Needs Index' as recommendation
FROM pg_stat_user_tables
WHERE schemaname = 'public'
    AND seq_scan > 1000
    AND (seq_scan::numeric / NULLIF(seq_scan + idx_scan, 0)) > 0.5
ORDER BY seq_scan DESC;

-- ================================================================
-- STEP 10: GENERATE OPTIMIZATION SCRIPT BASED ON YOUR DATA
-- ================================================================

-- This generates the EXACT indexes you need based on YOUR usage
SELECT DISTINCT
    'CREATE INDEX CONCURRENTLY idx_' ||
    tablename || '_' ||
    REPLACE(column_name, '_', '') ||
    ' ON ' || tablename || '(' || column_name || ');' as create_index_sql
FROM (
    SELECT
        tablename,
        'user_id' as column_name
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
        AND tablename IN ('shifts', 'entries', 'alerts', 'achievements')
        AND seq_scan > idx_scan

    UNION ALL

    SELECT
        'shifts' as tablename,
        'shift_date' as column_name
    WHERE EXISTS (
        SELECT 1 FROM pg_stat_user_tables
        WHERE tablename = 'shifts'
        AND seq_scan > 100
    )

    UNION ALL

    SELECT
        'alerts' as tablename,
        'is_read' as column_name
    WHERE EXISTS (
        SELECT 1 FROM pg_stat_user_tables
        WHERE tablename = 'alerts'
        AND seq_scan > 100
    )
) needed_indexes
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND pg_indexes.tablename = needed_indexes.tablename
    AND indexdef LIKE '%' || column_name || '%'
);

-- ================================================================
-- PERFORMANCE SCORE CALCULATION
-- ================================================================

WITH metrics AS (
    SELECT
        -- Data volume score (lower is better for current optimization)
        (SELECT COUNT(*) FROM shifts) as total_shifts,

        -- User load score
        (SELECT COUNT(DISTINCT user_id) FROM shifts) as total_users,

        -- Index efficiency
        (SELECT AVG(seq_scan::numeric / NULLIF(seq_scan + idx_scan, 0))
         FROM pg_stat_user_tables
         WHERE schemaname = 'public') as avg_seq_scan_ratio,

        -- Dead tuple ratio (bloat)
        (SELECT AVG(n_dead_tup::numeric / NULLIF(n_live_tup, 0))
         FROM pg_stat_user_tables
         WHERE schemaname = 'public') as avg_bloat_ratio,

        -- Connection usage
        (SELECT COUNT(*) FROM pg_stat_activity) as connection_count
)
SELECT
    'Performance Score Report' as metric,
    '========================' as value
UNION ALL
SELECT 'Total Shifts', total_shifts::text FROM metrics
UNION ALL
SELECT 'Total Users', total_users::text FROM metrics
UNION ALL
SELECT 'Avg Shifts/User', ROUND(total_shifts::numeric / NULLIF(total_users, 1), 2)::text FROM metrics
UNION ALL
SELECT 'Sequential Scan %', ROUND(avg_seq_scan_ratio * 100, 2)::text || '%' FROM metrics
UNION ALL
SELECT 'Table Bloat %', ROUND(avg_bloat_ratio * 100, 2)::text || '%' FROM metrics
UNION ALL
SELECT 'Active Connections', connection_count::text FROM metrics
UNION ALL
SELECT 'Performance Grade',
    CASE
        WHEN avg_seq_scan_ratio < 0.2 AND avg_bloat_ratio < 0.1 THEN 'A - Excellent'
        WHEN avg_seq_scan_ratio < 0.4 AND avg_bloat_ratio < 0.2 THEN 'B - Good'
        WHEN avg_seq_scan_ratio < 0.6 AND avg_bloat_ratio < 0.3 THEN 'C - Needs Optimization'
        ELSE 'D - Critical - Immediate Action Required'
    END
FROM metrics;