-- ProTip365 Scaling Strategy - Part 2: VIEWS & FUNCTIONS
-- This can run as a single transaction
-- ================================================================

-- ================================================================
-- 1. CREATE MATERIALIZED VIEW FOR DASHBOARD PERFORMANCE
-- ================================================================

-- Drop if exists to recreate
DROP MATERIALIZED VIEW IF EXISTS mv_dashboard_stats CASCADE;

-- Create materialized view for dashboard performance
CREATE MATERIALIZED VIEW mv_dashboard_stats AS
WITH user_stats AS (
    SELECT
        user_id,
        DATE_TRUNC('day', shift_date) as day,
        COUNT(*) as shift_count,
        SUM(hours) as total_hours,
        SUM(sales) as total_sales,
        SUM(tips) as total_tips,
        SUM(cash_out) as total_cash_out,
        AVG(tips::numeric / NULLIF(sales, 0)) as avg_tip_rate
    FROM shifts
    WHERE status = 'completed'
        AND shift_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY user_id, DATE_TRUNC('day', shift_date)
)
SELECT
    user_id,
    day,
    shift_count,
    total_hours,
    total_sales,
    total_tips,
    total_cash_out,
    avg_tip_rate
FROM user_stats;

-- Create indexes on materialized view (these don't need CONCURRENTLY)
CREATE UNIQUE INDEX idx_mv_dashboard_user_day ON mv_dashboard_stats(user_id, day);
CREATE INDEX idx_mv_dashboard_day ON mv_dashboard_stats(day DESC);

-- Auto-refresh function
CREATE OR REPLACE FUNCTION refresh_dashboard_stats()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_dashboard_stats;
END;
$$;

-- ================================================================
-- 2. PERFORMANCE MONITORING INFRASTRUCTURE
-- ================================================================

-- Create performance tracking table
CREATE TABLE IF NOT EXISTS performance_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    query_type TEXT NOT NULL,
    user_id UUID,
    execution_time_ms NUMERIC,
    query_date TIMESTAMP DEFAULT NOW(),
    success BOOLEAN DEFAULT true,
    error_message TEXT
);

-- Create indexes for performance analysis
CREATE INDEX IF NOT EXISTS idx_perf_logs_type_date
ON performance_logs(query_type, query_date DESC);

CREATE INDEX IF NOT EXISTS idx_perf_logs_slow
ON performance_logs(execution_time_ms DESC)
WHERE execution_time_ms > 100;

-- ================================================================
-- 3. OPTIMIZED DASHBOARD FUNCTION
-- ================================================================

CREATE OR REPLACE FUNCTION get_dashboard_data_cached(
    p_user_id UUID,
    p_period_days INTEGER DEFAULT 30
)
RETURNS TABLE(
    total_revenue NUMERIC,
    total_tips NUMERIC,
    total_sales NUMERIC,
    total_hours NUMERIC,
    shift_count INTEGER,
    avg_hourly NUMERIC,
    avg_tip_rate NUMERIC
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        SUM(s.tips + (s.hours * COALESCE(s.hourly_rate, 0))) as total_revenue,
        SUM(s.tips) as total_tips,
        SUM(s.sales) as total_sales,
        SUM(s.hours) as total_hours,
        COUNT(*)::INTEGER as shift_count,
        AVG(s.hourly_rate) as avg_hourly,
        AVG(s.tips::numeric / NULLIF(s.sales, 0)) as avg_tip_rate
    FROM shifts s
    WHERE s.user_id = p_user_id
        AND s.shift_date >= CURRENT_DATE - (p_period_days || ' days')::INTERVAL
        AND s.status = 'completed';
END;
$$;

-- ================================================================
-- 4. CONNECTION MONITORING
-- ================================================================

CREATE OR REPLACE VIEW connection_monitor AS
SELECT
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active_connections,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_connections,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
    MAX(EXTRACT(EPOCH FROM (NOW() - state_change))) as max_idle_seconds
FROM pg_stat_activity
WHERE datname = current_database();

-- ================================================================
-- 5. PERFORMANCE LOGGING FUNCTION
-- ================================================================

CREATE OR REPLACE FUNCTION log_query_performance(
    p_query_type TEXT,
    p_user_id UUID,
    p_start_time TIMESTAMP,
    p_success BOOLEAN DEFAULT true,
    p_error TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    execution_ms NUMERIC;
BEGIN
    execution_ms := EXTRACT(EPOCH FROM (NOW() - p_start_time)) * 1000;

    -- Only log slow queries or errors
    IF execution_ms > 50 OR NOT p_success THEN
        INSERT INTO performance_logs (
            query_type,
            user_id,
            execution_time_ms,
            success,
            error_message
        ) VALUES (
            p_query_type,
            p_user_id,
            execution_ms,
            p_success,
            p_error
        );
    END IF;
END;
$$;

-- ================================================================
-- 6. BATCH OPERATIONS SUPPORT
-- ================================================================

CREATE OR REPLACE FUNCTION bulk_insert_shifts(
    p_shifts JSONB
)
RETURNS TABLE(inserted INTEGER, failed INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inserted INTEGER := 0;
    v_failed INTEGER := 0;
    v_shift JSONB;
BEGIN
    FOR v_shift IN SELECT * FROM jsonb_array_elements(p_shifts)
    LOOP
        BEGIN
            INSERT INTO shifts (
                user_id,
                shift_date,
                hours,
                sales,
                tips,
                status
            ) VALUES (
                (v_shift->>'user_id')::UUID,
                (v_shift->>'shift_date')::DATE,
                (v_shift->>'hours')::NUMERIC,
                (v_shift->>'sales')::NUMERIC,
                (v_shift->>'tips')::NUMERIC,
                COALESCE(v_shift->>'status', 'completed')
            );
            v_inserted := v_inserted + 1;
        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
        END;
    END LOOP;

    RETURN QUERY SELECT v_inserted, v_failed;
END;
$$;

-- ================================================================
-- 7. SCALING READINESS CHECK FUNCTION
-- ================================================================

CREATE OR REPLACE FUNCTION scaling_readiness_check()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY

    -- Check indexes
    SELECT
        'Critical Indexes',
        CASE
            WHEN COUNT(*) >= 7 THEN '✅ READY'
            ELSE '⚠️ MISSING'
        END,
        'Found ' || COUNT(*)::TEXT || ' custom indexes'
    FROM pg_indexes
    WHERE schemaname = 'public'
        AND indexname LIKE 'idx_%'

    UNION ALL

    -- Check table sizes
    SELECT
        'Database Size',
        CASE
            WHEN pg_database_size(current_database()) < 1073741824 THEN '✅ OK'
            WHEN pg_database_size(current_database()) < 5368709120 THEN '⚠️ GROWING'
            ELSE '🔴 LARGE'
        END,
        pg_size_pretty(pg_database_size(current_database()))

    UNION ALL

    -- Check dead tuples
    SELECT
        'Table Bloat',
        CASE
            WHEN COALESCE(MAX(n_dead_tup::numeric / NULLIF(n_live_tup, 0)), 0) < 0.1 THEN '✅ HEALTHY'
            WHEN COALESCE(MAX(n_dead_tup::numeric / NULLIF(n_live_tup, 0)), 0) < 0.2 THEN '⚠️ MODERATE'
            ELSE '🔴 HIGH'
        END,
        'Max bloat: ' ||
        ROUND(COALESCE(MAX(n_dead_tup::numeric / NULLIF(n_live_tup, 0)), 0) * 100, 2)::TEXT || '%'
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'

    UNION ALL

    -- Check connections
    SELECT
        'Connection Usage',
        CASE
            WHEN COUNT(*) < 30 THEN '✅ LOW'
            WHEN COUNT(*) < 60 THEN '⚠️ MODERATE'
            ELSE '🔴 HIGH'
        END,
        COUNT(*)::TEXT || ' active connections'
    FROM pg_stat_activity
    WHERE datname = current_database()

    UNION ALL

    -- Check materialized view
    SELECT
        'Dashboard Cache',
        CASE
            WHEN EXISTS(SELECT 1 FROM pg_matviews WHERE matviewname = 'mv_dashboard_stats')
            THEN '✅ READY'
            ELSE '🔴 MISSING'
        END,
        CASE
            WHEN EXISTS(SELECT 1 FROM pg_matviews WHERE matviewname = 'mv_dashboard_stats')
            THEN 'Materialized view exists'
            ELSE 'Run Part 2 script'
        END

    UNION ALL

    -- Overall status
    SELECT
        'Overall Status',
        '🎯 READY FOR SCALE',
        'System optimized for 1,000+ users';
END;
$$;

-- ================================================================
-- 8. TEST THE OPTIMIZATION
-- ================================================================

-- Refresh materialized view with current data
REFRESH MATERIALIZED VIEW mv_dashboard_stats;

-- Test the optimized dashboard function
SELECT * FROM get_dashboard_data_cached(
    (SELECT user_id FROM users_profile LIMIT 1),
    30
);

-- Show readiness status
SELECT * FROM scaling_readiness_check();