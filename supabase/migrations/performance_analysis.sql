-- ProTip365 Database Performance Analysis & Optimization Queries
-- Run these queries in Supabase SQL Editor to analyze performance for 1,000+ users
-- ================================================================

-- ================================================================
-- 1. DATABASE SIZE AND GROWTH ANALYSIS
-- ================================================================

-- Check table sizes and row counts
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS indexes_size,
    n_live_tup as row_count,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ================================================================
-- 2. INDEX USAGE AND EFFECTIVENESS
-- ================================================================

-- Find missing indexes (queries without index scans)
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    CASE
        WHEN seq_scan + idx_scan = 0 THEN 0
        ELSE round((seq_scan::numeric / (seq_scan + idx_scan)) * 100, 2)
    END as seq_scan_percentage
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY seq_scan_percentage DESC;

-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Find duplicate indexes
SELECT
    pg_size_pretty(sum(pg_relation_size(idx))::bigint) as size,
    (array_agg(idx))[1] as idx1,
    (array_agg(idx))[2] as idx2,
    (array_agg(idx))[3] as idx3,
    (array_agg(idx))[4] as idx4
FROM (
    SELECT
        indexrelid::regclass AS idx,
        (indrelid::text ||E'\n'|| indclass::text ||E'\n'|| indkey::text ||E'\n'|| coalesce(indexprs::text,'')||E'\n' || coalesce(indpred::text,'')) AS KEY
    FROM pg_index
) sub
GROUP BY KEY
HAVING COUNT(*)>1
ORDER BY sum(pg_relation_size(idx)) DESC;

-- ================================================================
-- 3. QUERY PERFORMANCE MONITORING
-- ================================================================

-- Most expensive queries (requires pg_stat_statements extension)
-- Note: Might need to enable in Supabase dashboard
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_%'
ORDER BY mean_exec_time DESC
LIMIT 20;

-- ================================================================
-- 4. CONNECTION AND CONCURRENCY ANALYSIS
-- ================================================================

-- Current connection count and limits
SELECT
    max_conn,
    used,
    res_for_super,
    max_conn - used - res_for_super AS available,
    (used::float / max_conn::float) * 100 AS percentage_used
FROM
    (SELECT count(*) AS used FROM pg_stat_activity) t1,
    (SELECT setting::int AS max_conn FROM pg_settings WHERE name = 'max_connections') t2,
    (SELECT setting::int AS res_for_super FROM pg_settings WHERE name = 'superuser_reserved_connections') t3;

-- Active queries and their duration
SELECT
    pid,
    usename,
    application_name,
    client_addr,
    backend_start,
    state,
    state_change,
    NOW() - query_start AS query_duration,
    query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_duration DESC;

-- ================================================================
-- 5. CRITICAL PERFORMANCE BOTTLENECKS FOR 1000+ USERS
-- ================================================================

-- Check for lock contention
SELECT
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- ================================================================
-- 6. RECOMMENDED INDEXES FOR OPTIMIZATION
-- ================================================================

-- Add these indexes for better performance at scale:

-- Composite index for shift queries by date range
CREATE INDEX IF NOT EXISTS idx_shifts_user_date
ON shifts(user_id, shift_date DESC)
WHERE status = 'completed';

-- Composite index for employer-specific queries
CREATE INDEX IF NOT EXISTS idx_shifts_employer_date
ON shifts(employer_id, shift_date DESC)
WHERE employer_id IS NOT NULL;

-- Partial index for active alerts
CREATE INDEX IF NOT EXISTS idx_alerts_user_unread
ON alerts(user_id, created_at DESC)
WHERE is_read = FALSE;

-- Index for subscription checks
CREATE INDEX IF NOT EXISTS idx_subscriptions_active
ON user_subscriptions(user_id)
WHERE status = 'active' AND expires_at > NOW();

-- Composite index for v_shift_income performance
CREATE INDEX IF NOT EXISTS idx_shift_income_composite
ON shift_income(shift_id, user_id);

-- ================================================================
-- 7. DATA ARCHIVING STRATEGY
-- ================================================================

-- Count old shifts that could be archived
SELECT
    COUNT(*) as total_old_shifts,
    COUNT(DISTINCT user_id) as affected_users,
    MIN(shift_date) as oldest_shift,
    pg_size_pretty(
        AVG(pg_column_size(shifts.*))::bigint * COUNT(*)
    ) as estimated_size
FROM shifts
WHERE shift_date < NOW() - INTERVAL '1 year';

-- ================================================================
-- 8. VACUUM AND MAINTENANCE
-- ================================================================

-- Tables needing vacuum
SELECT
    schemaname,
    tablename,
    n_dead_tup,
    n_live_tup,
    round(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) as dead_tuple_percent,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'public'
    AND n_dead_tup > 1000
ORDER BY dead_tuple_percent DESC;

-- ================================================================
-- 9. RLS POLICY PERFORMANCE CHECK
-- ================================================================

-- Check RLS policy complexity
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
ORDER BY tablename;

-- ================================================================
-- 10. MONITORING DASHBOARD QUERIES
-- ================================================================

-- User activity patterns (for capacity planning)
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(DISTINCT user_id) as active_users,
    COUNT(*) as total_operations
FROM shifts
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY hour
ORDER BY hour DESC;

-- Peak usage times
SELECT
    EXTRACT(DOW FROM created_at) as day_of_week,
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as operations_count,
    COUNT(DISTINCT user_id) as unique_users
FROM shifts
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY day_of_week, hour_of_day
ORDER BY operations_count DESC
LIMIT 20;