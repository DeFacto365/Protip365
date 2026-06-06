-- ProTip365 Scaling Strategy - Part 1: INDEXES
-- Run each CREATE INDEX command separately (they can't be in a transaction)
-- Copy and paste each command one by one into Supabase SQL Editor
-- ================================================================

-- ================================================================
-- RUN EACH OF THESE COMMANDS SEPARATELY
-- ================================================================

-- Index 1: Main shifts composite index
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shifts_user_date_composite
ON shifts(user_id, shift_date DESC, status)
WHERE status = 'completed';

-- Index 2: Monthly aggregation index
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shifts_user_month
ON shifts(user_id, DATE_TRUNC('month', shift_date));

-- Index 3: Unread alerts optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_unread_priority
ON alerts(user_id, created_at DESC)
WHERE is_read = false;

-- Index 4: Entries by date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_entries_user_date
ON entries(user_id, entry_date DESC);

-- Index 5: Active employers
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_employers_active
ON employers(user_id, active)
WHERE active = true;

-- Index 6: Achievements lookup
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_achievements_user_type
ON achievements(user_id, achievement_type, unlocked_at DESC);

-- Index 7: Active subscriptions
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscriptions_active
ON user_subscriptions(user_id, expires_at DESC)
WHERE status = 'active';

-- Index 8: Recent shifts (most queries are for recent data)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shifts_recent
ON shifts(user_id, shift_date DESC)
WHERE shift_date >= CURRENT_DATE - INTERVAL '90 days';

-- ================================================================
-- VERIFY INDEXES WERE CREATED
-- ================================================================

-- Run this after creating all indexes to verify
SELECT
    indexname,
    tablename,
    CASE
        WHEN indexname LIKE 'idx_%' THEN '✅ Custom Index'
        ELSE '📦 System Index'
    END as index_type
FROM pg_indexes
WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;