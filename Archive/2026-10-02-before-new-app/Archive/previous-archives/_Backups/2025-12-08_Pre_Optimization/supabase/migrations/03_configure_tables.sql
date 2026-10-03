-- ProTip365 Scaling Strategy - Part 3: TABLE CONFIGURATION
-- This configures autovacuum and table settings for high performance
-- ================================================================

-- ================================================================
-- 1. OPTIMIZE AUTOVACUUM FOR HIGH-TRAFFIC TABLES
-- ================================================================

-- Configure aggressive autovacuum for shifts table (most active)
ALTER TABLE shifts SET (
    autovacuum_vacuum_scale_factor = 0.1,  -- Vacuum when 10% dead tuples
    autovacuum_analyze_scale_factor = 0.05, -- Analyze when 5% changed
    autovacuum_vacuum_cost_delay = 10      -- Reduce vacuum delay
);

-- Configure for entries table
ALTER TABLE entries SET (
    autovacuum_vacuum_scale_factor = 0.15,
    autovacuum_analyze_scale_factor = 0.1
);

-- Configure for alerts table (high insert/delete)
ALTER TABLE alerts SET (
    autovacuum_vacuum_scale_factor = 0.2,
    autovacuum_analyze_scale_factor = 0.1
);

-- ================================================================
-- 2. UPDATE TABLE STATISTICS
-- ================================================================

-- Update statistics for query planner optimization
ANALYZE shifts;
ANALYZE entries;
ANALYZE alerts;
ANALYZE employers;
ANALYZE achievements;
ANALYZE user_subscriptions;
ANALYZE users_profile;

-- ================================================================
-- 3. OPTIMIZE RLS POLICIES
-- ================================================================

-- Drop and recreate RLS policies with better performance

-- Shifts table optimization
DROP POLICY IF EXISTS "Users can view own shifts" ON shifts;
CREATE POLICY "shifts_select_optimized" ON shifts
FOR SELECT USING (
    user_id = auth.uid()
    AND (
        shift_date >= CURRENT_DATE - INTERVAL '1 year'
        OR shift_date IS NULL
    )
);

DROP POLICY IF EXISTS "Users can insert own shifts" ON shifts;
CREATE POLICY "shifts_insert_optimized" ON shifts
FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own shifts" ON shifts;
CREATE POLICY "shifts_update_optimized" ON shifts
FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own shifts" ON shifts;
CREATE POLICY "shifts_delete_optimized" ON shifts
FOR DELETE USING (user_id = auth.uid());

-- Alerts table optimization
DROP POLICY IF EXISTS "Users can view own alerts" ON alerts;
CREATE POLICY "alerts_select_optimized" ON alerts
FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own alerts" ON alerts;
CREATE POLICY "alerts_update_optimized" ON alerts
FOR UPDATE USING (user_id = auth.uid());

-- ================================================================
-- 4. CREATE HELPER FUNCTIONS FOR COMMON QUERIES
-- ================================================================

-- Optimized function to get recent shifts
CREATE OR REPLACE FUNCTION get_recent_shifts(
    p_user_id UUID,
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE(
    id UUID,
    shift_date DATE,
    hours NUMERIC,
    hourly_rate NUMERIC,
    sales NUMERIC,
    tips NUMERIC,
    employer_id UUID,
    status TEXT
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.shift_date,
        s.hours,
        s.hourly_rate,
        s.sales,
        s.tips,
        s.employer_id,
        s.status
    FROM shifts s
    WHERE s.user_id = p_user_id
        AND s.shift_date >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    ORDER BY s.shift_date DESC;
END;
$$;

-- Optimized function for calendar view
CREATE OR REPLACE FUNCTION get_calendar_shifts(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    shift_date DATE,
    shift_count BIGINT,
    total_hours NUMERIC,
    total_tips NUMERIC,
    total_sales NUMERIC,
    has_completed BOOLEAN
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.shift_date,
        COUNT(*) as shift_count,
        SUM(s.hours) as total_hours,
        SUM(s.tips) as total_tips,
        SUM(s.sales) as total_sales,
        BOOL_OR(s.status = 'completed') as has_completed
    FROM shifts s
    WHERE s.user_id = p_user_id
        AND s.shift_date BETWEEN p_start_date AND p_end_date
    GROUP BY s.shift_date
    ORDER BY s.shift_date;
END;
$$;

-- ================================================================
-- 5. CREATE MONITORING VIEWS
-- ================================================================

-- View to monitor table health
CREATE OR REPLACE VIEW table_health AS
SELECT
    schemaname,
    relname as tablename,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    CASE
        WHEN n_live_tup > 0 THEN
            ROUND((n_dead_tup::numeric / n_live_tup) * 100, 2)
        ELSE 0
    END as bloat_percent,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

-- View to monitor index usage
CREATE OR REPLACE VIEW index_usage AS
SELECT
    schemaname,
    relname as tablename,
    indexrelname as indexname,
    idx_scan as scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- ================================================================
-- 6. PERFORMANCE BASELINE
-- ================================================================

-- Create baseline metrics table
CREATE TABLE IF NOT EXISTS performance_baseline (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    metric_date DATE DEFAULT CURRENT_DATE,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(metric_date, metric_name)
);

-- Capture current baseline
INSERT INTO performance_baseline (metric_name, metric_value)
VALUES
    ('total_users', (SELECT COUNT(DISTINCT user_id) FROM shifts)),
    ('total_shifts', (SELECT COUNT(*) FROM shifts)),
    ('avg_shifts_per_user', (SELECT AVG(c) FROM (SELECT COUNT(*) as c FROM shifts GROUP BY user_id) t)),
    ('db_size_mb', (SELECT pg_database_size(current_database()) / 1048576))
ON CONFLICT (metric_date, metric_name)
DO UPDATE SET metric_value = EXCLUDED.metric_value;

-- ================================================================
-- 7. FINAL STATUS CHECK
-- ================================================================

SELECT
    'Optimization Complete' as status,
    COUNT(*) FILTER (WHERE indexname LIKE 'idx_%') as custom_indexes,
    pg_size_pretty(pg_database_size(current_database())) as database_size,
    (SELECT COUNT(DISTINCT user_id) FROM shifts) as total_users,
    (SELECT COUNT(*) FROM shifts) as total_shifts
FROM pg_indexes
WHERE schemaname = 'public'
GROUP BY database_size;