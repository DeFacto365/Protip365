-- ProTip365 Database Performance Analysis for Supabase
-- Optimized queries that work with Supabase's PostgreSQL configuration
-- ================================================================

-- ================================================================
-- 1. DATABASE SIZE AND TABLE ANALYSIS (SUPABASE COMPATIBLE)
-- ================================================================

-- Check table sizes and row counts
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Get approximate row counts
SELECT
    relname AS table_name,
    n_live_tup AS row_count,
    n_dead_tup AS dead_rows,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

-- ================================================================
-- 2. CHECK EXISTING INDEXES
-- ================================================================

-- List all indexes and their sizes
SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    pg_size_pretty(pg_relation_size(i.oid)) AS index_size,
    idx.indisunique AS is_unique,
    idx.indisprimary AS is_primary
FROM pg_class t
JOIN pg_index idx ON t.oid = idx.indrelid
JOIN pg_class i ON i.oid = idx.indexrelid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE n.nspname = 'public'
    AND t.relkind = 'r'
ORDER BY pg_relation_size(i.oid) DESC;

-- ================================================================
-- 3. FIND MISSING INDEXES (SIMPLIFIED FOR SUPABASE)
-- ================================================================

-- Tables with high sequential scan ratio (may need indexes)
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    CASE
        WHEN seq_scan = 0 THEN 0
        ELSE ROUND((seq_scan::NUMERIC / NULLIF(seq_scan + idx_scan, 0)) * 100, 2)
    END AS seq_scan_percentage
FROM pg_stat_user_tables
WHERE schemaname = 'public'
    AND seq_scan > 0
ORDER BY seq_scan_percentage DESC;

-- ================================================================
-- 4. MOST ACCESSED TABLES (HOTSPOTS)
-- ================================================================

SELECT
    schemaname,
    tablename,
    n_tup_ins AS inserts,
    n_tup_upd AS updates,
    n_tup_del AS deletes,
    n_tup_hot_upd AS hot_updates,
    seq_scan + idx_scan AS total_scans
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY (n_tup_ins + n_tup_upd + n_tup_del) DESC
LIMIT 10;

-- ================================================================
-- 5. SLOW QUERY IDENTIFICATION (BASIC VERSION)
-- ================================================================

-- Current running queries and their duration
SELECT
    pid,
    usename,
    application_name,
    state,
    NOW() - query_start AS duration,
    LEFT(query, 100) AS query_preview
FROM pg_stat_activity
WHERE state != 'idle'
    AND query NOT ILIKE '%pg_stat%'
ORDER BY duration DESC NULLS LAST
LIMIT 20;

-- ================================================================
-- 6. CONNECTION USAGE
-- ================================================================

-- Current connection stats
SELECT
    COUNT(*) AS total_connections,
    COUNT(*) FILTER (WHERE state = 'active') AS active_connections,
    COUNT(*) FILTER (WHERE state = 'idle') AS idle_connections,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') AS idle_in_transaction
FROM pg_stat_activity;

-- Connections by database
SELECT
    datname,
    COUNT(*) AS connections
FROM pg_stat_activity
GROUP BY datname
ORDER BY connections DESC;

-- ================================================================
-- 7. TABLE BLOAT CHECK
-- ================================================================

SELECT
    tablename,
    n_dead_tup AS dead_rows,
    n_live_tup AS live_rows,
    ROUND((n_dead_tup::NUMERIC / NULLIF(n_live_tup + n_dead_tup, 0)) * 100, 2) AS dead_percentage,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'public'
    AND n_dead_tup > 100
ORDER BY dead_percentage DESC;

-- ================================================================
-- 8. CHECK RLS POLICIES
-- ================================================================

SELECT
    schemaname,
    tablename,
    policyname,
    cmd,
    permissive,
    roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ================================================================
-- 9. CRITICAL INDEXES TO ADD FOR 1000+ USERS
-- ================================================================

-- Check if recommended indexes exist, create if not
DO $$
BEGIN
    -- Index for shifts by user and date
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_shifts_user_date_optimized'
    ) THEN
        CREATE INDEX CONCURRENTLY idx_shifts_user_date_optimized
        ON public.shifts(user_id, shift_date DESC)
        WHERE status = 'completed';
        RAISE NOTICE 'Created index: idx_shifts_user_date_optimized';
    END IF;

    -- Index for active alerts
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_alerts_active_unread'
    ) THEN
        CREATE INDEX CONCURRENTLY idx_alerts_active_unread
        ON public.alerts(user_id, created_at DESC)
        WHERE is_read = FALSE;
        RAISE NOTICE 'Created index: idx_alerts_active_unread';
    END IF;

    -- Index for employer shifts
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_shifts_employer_optimized'
    ) THEN
        CREATE INDEX CONCURRENTLY idx_shifts_employer_optimized
        ON public.shifts(employer_id, shift_date DESC)
        WHERE employer_id IS NOT NULL;
        RAISE NOTICE 'Created index: idx_shifts_employer_optimized';
    END IF;

    -- Index for entries by date
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_entries_user_date'
    ) THEN
        CREATE INDEX CONCURRENTLY idx_entries_user_date
        ON public.entries(user_id, entry_date DESC);
        RAISE NOTICE 'Created index: idx_entries_user_date';
    END IF;

    -- Index for active subscriptions
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_subscriptions_active_users'
    ) THEN
        CREATE INDEX CONCURRENTLY idx_subscriptions_active_users
        ON public.user_subscriptions(user_id)
        WHERE status = 'active' AND expires_at > NOW();
        RAISE NOTICE 'Created index: idx_subscriptions_active_users';
    END IF;
END $$;

-- ================================================================
-- 10. DATA DISTRIBUTION ANALYSIS
-- ================================================================

-- User activity distribution (to identify power users)
WITH user_stats AS (
    SELECT
        user_id,
        COUNT(*) AS shift_count,
        MAX(shift_date) AS last_shift,
        MIN(shift_date) AS first_shift
    FROM shifts
    GROUP BY user_id
)
SELECT
    CASE
        WHEN shift_count >= 100 THEN 'Power Users (100+ shifts)'
        WHEN shift_count >= 50 THEN 'Active Users (50-99 shifts)'
        WHEN shift_count >= 20 THEN 'Regular Users (20-49 shifts)'
        WHEN shift_count >= 5 THEN 'Casual Users (5-19 shifts)'
        ELSE 'New Users (<5 shifts)'
    END AS user_category,
    COUNT(*) AS user_count,
    SUM(shift_count) AS total_shifts,
    AVG(shift_count) AS avg_shifts_per_user
FROM user_stats
GROUP BY user_category
ORDER BY MIN(shift_count) DESC;

-- Shifts per day distribution
SELECT
    shift_date,
    COUNT(*) AS shifts_count,
    COUNT(DISTINCT user_id) AS unique_users
FROM shifts
WHERE shift_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY shift_date
ORDER BY shift_date DESC;

-- ================================================================
-- 11. PERFORMANCE BASELINE METRICS
-- ================================================================

-- Save current metrics as baseline
CREATE TABLE IF NOT EXISTS performance_baseline (
    metric_date DATE DEFAULT CURRENT_DATE,
    metric_name TEXT,
    metric_value NUMERIC,
    PRIMARY KEY (metric_date, metric_name)
);

-- Insert baseline metrics
INSERT INTO performance_baseline (metric_name, metric_value)
SELECT 'total_shifts', COUNT(*) FROM shifts
ON CONFLICT (metric_date, metric_name) DO UPDATE SET metric_value = EXCLUDED.metric_value;

INSERT INTO performance_baseline (metric_name, metric_value)
SELECT 'total_users', COUNT(DISTINCT user_id) FROM shifts
ON CONFLICT (metric_date, metric_name) DO UPDATE SET metric_value = EXCLUDED.metric_value;

INSERT INTO performance_baseline (metric_name, metric_value)
SELECT 'avg_shifts_per_user', AVG(shift_count)
FROM (SELECT user_id, COUNT(*) AS shift_count FROM shifts GROUP BY user_id) t
ON CONFLICT (metric_date, metric_name) DO UPDATE SET metric_value = EXCLUDED.metric_value;

INSERT INTO performance_baseline (metric_name, metric_value)
SELECT 'total_connections', COUNT(*) FROM pg_stat_activity
ON CONFLICT (metric_date, metric_name) DO UPDATE SET metric_value = EXCLUDED.metric_value;

-- View baseline metrics
SELECT * FROM performance_baseline WHERE metric_date = CURRENT_DATE;

-- ================================================================
-- 12. QUICK HEALTH CHECK SUMMARY
-- ================================================================

SELECT 'Database Health Check Report' AS report;

-- Summary stats
WITH stats AS (
    SELECT
        (SELECT COUNT(DISTINCT user_id) FROM shifts) AS total_users,
        (SELECT COUNT(*) FROM shifts) AS total_shifts,
        (SELECT COUNT(*) FROM shifts WHERE shift_date >= CURRENT_DATE - INTERVAL '7 days') AS recent_shifts,
        (SELECT pg_database_size(current_database())) AS db_size,
        (SELECT COUNT(*) FROM pg_stat_activity) AS connections,
        (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public') AS index_count
)
SELECT
    'Total Users' AS metric,
    total_users::TEXT AS value
FROM stats
UNION ALL
SELECT
    'Total Shifts',
    total_shifts::TEXT
FROM stats
UNION ALL
SELECT
    'Shifts (Last 7 Days)',
    recent_shifts::TEXT
FROM stats
UNION ALL
SELECT
    'Database Size',
    pg_size_pretty(db_size)
FROM stats
UNION ALL
SELECT
    'Active Connections',
    connections::TEXT
FROM stats
UNION ALL
SELECT
    'Total Indexes',
    index_count::TEXT
FROM stats
ORDER BY metric;