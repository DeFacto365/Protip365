# PostgreSQL Upgrade Guide for ProTip365

## Current Issue
Your PostgreSQL version requires security patches. Upgrading ensures you have the latest security fixes and performance improvements.

## Upgrade Process in Supabase

### Method 1: In-Place Upgrade (Recommended)

1. **Check current version**:
   ```sql
   SELECT version();
   ```

2. **Schedule maintenance window**:
   - Choose a time with minimal user activity
   - Notify users in advance
   - Plan for 15-30 minutes of downtime

3. **Backup your database**:
   - Go to Supabase Dashboard → Settings → Database
   - Click "Create Backup"
   - Wait for backup completion
   - Download the backup file

4. **Perform the upgrade**:
   - Go to Supabase Dashboard → Settings → Infrastructure
   - Click "Upgrade Database"
   - Select the latest stable PostgreSQL version (15.x recommended)
   - Review the upgrade notes
   - Click "Start Upgrade"

5. **Monitor the upgrade**:
   - The upgrade typically takes 10-20 minutes
   - Supabase will show progress indicators
   - Your database will be read-only during this time

### Method 2: Migration to New Project

If in-place upgrade is not available:

1. **Create new Supabase project** with latest PostgreSQL version

2. **Export data from old project**:
   ```bash
   pg_dump -h old-db-host -U postgres -d postgres > backup.sql
   ```

3. **Import to new project**:
   ```bash
   psql -h new-db-host -U postgres -d postgres < backup.sql
   ```

4. **Update application connections**:
   - Update DATABASE_URL in your apps
   - Update API keys and endpoints

5. **Verify data integrity**:
   ```sql
   -- Check row counts
   SELECT 'shifts' as table_name, COUNT(*) as row_count FROM shifts
   UNION ALL
   SELECT 'users_profile', COUNT(*) FROM users_profile
   UNION ALL
   SELECT 'employers', COUNT(*) FROM employers;
   ```

## Pre-Upgrade Checklist

- [ ] Create full database backup
- [ ] Document current PostgreSQL version
- [ ] Review breaking changes in target version
- [ ] Test upgrade process in development environment
- [ ] Notify users of maintenance window
- [ ] Prepare rollback plan

## Post-Upgrade Tasks

1. **Verify version**:
   ```sql
   SELECT version();
   ```

2. **Run ANALYZE on all tables**:
   ```sql
   ANALYZE shifts;
   ANALYZE users_profile;
   ANALYZE employers;
   ANALYZE entries;
   ANALYZE alerts;
   ANALYZE achievements;
   ANALYZE user_subscriptions;
   ```

3. **Check query performance**:
   ```sql
   SELECT * FROM scaling_readiness_check();
   ```

4. **Verify indexes**:
   ```sql
   SELECT indexname, tablename
   FROM pg_indexes
   WHERE schemaname = 'public'
   ORDER BY tablename, indexname;
   ```

5. **Test critical functions**:
   ```sql
   -- Test dashboard function
   SELECT * FROM get_dashboard_data_cached(
       (SELECT user_id FROM users_profile LIMIT 1),
       30
   );
   
   -- Test recent shifts function
   SELECT * FROM get_recent_shifts(
       (SELECT user_id FROM users_profile LIMIT 1),
       30
   );
   ```

## Version-Specific Benefits

### PostgreSQL 15 improvements:
- **Performance**: Up to 2x improvement in sorting performance
- **Security**: Enhanced encryption and authentication methods
- **Compression**: Improved compression algorithms for faster queries
- **Monitoring**: Better statistics and monitoring capabilities
- **Partitioning**: Enhanced partitioning features for large tables

### Security patches included:
- CVE-2023-5868: Memory disclosure vulnerability
- CVE-2023-5869: Buffer overrun vulnerability
- CVE-2023-5870: Permission bypass vulnerability
- CVE-2024-0985: Privilege escalation vulnerability

## Rollback Plan

If issues occur after upgrade:

1. **Immediate rollback** (if using Method 2):
   - Switch application back to old database URL
   - Investigate issues
   - Plan corrective action

2. **Restore from backup**:
   ```bash
   pg_restore -h db-host -U postgres -d postgres backup.dump
   ```

3. **Contact Supabase support**:
   - Available through dashboard
   - Provide error messages and logs
   - Request assistance with rollback

## Monitoring After Upgrade

Monitor these metrics for 24-48 hours:

1. **Connection pool usage**:
   ```sql
   SELECT * FROM connection_monitor;
   ```

2. **Query performance**:
   ```sql
   SELECT 
       query_type,
       AVG(execution_time_ms) as avg_ms,
       MAX(execution_time_ms) as max_ms,
       COUNT(*) as query_count
   FROM performance_logs
   WHERE query_date >= NOW() - INTERVAL '1 hour'
   GROUP BY query_type
   ORDER BY avg_ms DESC;
   ```

3. **Error rates**:
   ```sql
   SELECT 
       error_message,
       COUNT(*) as error_count
   FROM performance_logs
   WHERE success = false
       AND query_date >= NOW() - INTERVAL '1 hour'
   GROUP BY error_message;
   ```

## Support Resources

- **Supabase Documentation**: https://supabase.com/docs/guides/platform/migrating-and-upgrading-projects
- **PostgreSQL Release Notes**: https://www.postgresql.org/docs/release/
- **Supabase Support**: Available through dashboard
- **Community Discord**: https://discord.supabase.com

## Timeline Recommendation

Given your proactive scaling strategy for 1,000+ users:

1. **Immediate** (This week):
   - Schedule upgrade for low-traffic period
   - Perform upgrade to PostgreSQL 15
   - Apply security patches

2. **Short-term** (Next 2 weeks):
   - Monitor performance metrics
   - Fine-tune configuration if needed
   - Document any issues and resolutions

3. **Long-term** (Monthly):
   - Review PostgreSQL release notes
   - Plan regular security updates
   - Keep within 1 major version of latest stable release
