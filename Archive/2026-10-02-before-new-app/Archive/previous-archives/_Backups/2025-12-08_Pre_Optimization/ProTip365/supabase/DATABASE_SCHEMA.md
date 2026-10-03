# ProTip365 Database Schema Documentation

## Overview
This document describes the complete database schema for ProTip365. All tables listed here MUST exist in the database for the application to function properly. The database is shared between iOS and Android apps.

**Last Updated**: September 15, 2025
**Database**: PostgreSQL (via Supabase)
**Important**: This schema is used by both iOS and Android apps. DO NOT modify without coordinating changes in both platforms.

## Tables

### 1. users_profile
**Purpose**: Stores user profile information and preferences
**Relationships**: References auth.users(id)

| Column | Type | Description | Default | Constraints |
|--------|------|-------------|---------|-------------|
| user_id | UUID | Primary key, references auth.users | - | NOT NULL, REFERENCES auth.users(id) ON DELETE CASCADE |
| email | TEXT | User's email address | - | - |
| name | TEXT | User's display name | - | - |
| preferred_language | TEXT | Language preference (en, fr, es) | 'en' | - |
| subscription_tier | TEXT | Current subscription tier (none, parttime, full) | 'none' | - |
| subscription_status | TEXT | Subscription status (active, cancelled, expired) | - | - |
| default_hourly_rate | DECIMAL | Default hourly wage | - | - |
| tip_target_percentage | DECIMAL | Target tip percentage | - | - |
| average_deduction_percentage | DECIMAL(5,2) | Average tax/deduction percentage | 30.00 | CHECK (0-100) |
| week_start | INTEGER | 0=Sunday, 1=Monday | 0 | - |
| use_multiple_employers | BOOLEAN | Whether user has multiple employers | false | - |
| default_employer_id | UUID | Default employer reference | - | REFERENCES employers(id) |
| target_sales_daily | DECIMAL | Daily sales target | - | - |
| target_sales_weekly | DECIMAL | Weekly sales target | - | - |
| target_sales_monthly | DECIMAL | Monthly sales target | - | - |
| target_hours_daily | DECIMAL | Daily hours target | - | - |
| target_hours_weekly | DECIMAL | Weekly hours target | - | - |
| target_hours_monthly | DECIMAL | Monthly hours target | - | - |
| created_at | TIMESTAMP WITH TIME ZONE | Record creation time | CURRENT_TIMESTAMP | - |
| updated_at | TIMESTAMP WITH TIME ZONE | Last update time | CURRENT_TIMESTAMP | - |

### 2. employers
**Purpose**: Stores employer/workplace information
**Relationships**: References users_profile(user_id)

| Column | Type | Description | Default | Constraints |
|--------|------|-------------|---------|-------------|
| id | UUID | Primary key | gen_random_uuid() | NOT NULL |
| user_id | UUID | References users_profile | - | NOT NULL, REFERENCES auth.users(id) ON DELETE CASCADE |
| name | TEXT | Employer name | - | NOT NULL |
| address | TEXT | Employer address | - | - |
| hourly_rate | DECIMAL | Hourly wage at this employer | - | - |
| is_active | BOOLEAN | Whether employer is active | true | - |
| created_at | TIMESTAMP WITH TIME ZONE | Record creation time | CURRENT_TIMESTAMP | - |

### 3. shifts
**Purpose**: Stores work shift records with hours
**Relationships**: References users_profile(user_id), employers(id)

| Column | Type | Description | Default | Constraints |
|--------|------|-------------|---------|-------------|
| id | UUID | Primary key | gen_random_uuid() | NOT NULL |
| user_id | UUID | References users_profile | - | NOT NULL, REFERENCES auth.users(id) ON DELETE CASCADE |
| employer_id | UUID | References employers | - | REFERENCES employers(id) |
| shift_date | DATE | Date of the shift | - | NOT NULL |
| start_time | TIME | Shift start time | - | - |
| end_time | TIME | Shift end time | - | - |
| hours | DECIMAL | Total hours worked | - | - |
| sales | DECIMAL | Total sales served | - | - |
| tips | DECIMAL | Tips received | - | - |
| hourly_rate | DECIMAL | Hourly wage for this shift | - | - |
| cash_out | DECIMAL | Tip-out amount | - | - |
| other | DECIMAL | Other income | - | - |
| notes | TEXT | Additional notes | - | - |
| created_at | TIMESTAMP WITH TIME ZONE | Record creation time | CURRENT_TIMESTAMP | - |
| updated_at | TIMESTAMP WITH TIME ZONE | Last update time | CURRENT_TIMESTAMP | - |

### 4. entries
**Purpose**: Stores quick income entries without hours
**Relationships**: References users_profile(user_id), employers(id)

| Column | Type | Description | Default | Constraints |
|--------|------|-------------|---------|-------------|
| id | UUID | Primary key | gen_random_uuid() | NOT NULL |
| user_id | UUID | References users_profile | - | NOT NULL, REFERENCES auth.users(id) ON DELETE CASCADE |
| employer_id | UUID | References employers | - | REFERENCES employers(id) |
| entry_date | DATE | Date of the entry | - | NOT NULL |
| sales | DECIMAL | Total sales | - | - |
| tips | DECIMAL | Tips received | - | - |
| hourly_rate | DECIMAL | Hourly rate (if applicable) | - | - |
| cash_out | DECIMAL | Tip-out amount | - | - |
| other | DECIMAL | Other income | - | - |
| notes | TEXT | Additional notes | - | - |
| created_at | TIMESTAMP WITH TIME ZONE | Record creation time | CURRENT_TIMESTAMP | - |
| updated_at | TIMESTAMP WITH TIME ZONE | Last update time | CURRENT_TIMESTAMP | - |

### 5. achievements
**Purpose**: Stores user achievements and badges
**Relationships**: References auth.users(id)

| Column | Type | Description | Default | Constraints |
|--------|------|-------------|---------|-------------|
| id | UUID | Primary key | gen_random_uuid() | NOT NULL |
| user_id | UUID | References auth.users | - | NOT NULL, REFERENCES auth.users(id) ON DELETE CASCADE |
| achievement_type | TEXT | Type of achievement | - | NOT NULL, UNIQUE with user_id |
| unlocked_at | TIMESTAMP WITH TIME ZONE | When achievement was unlocked | CURRENT_TIMESTAMP | - |
| data | JSONB | Additional achievement data | - | - |
| created_at | TIMESTAMP WITH TIME ZONE | Record creation time | CURRENT_TIMESTAMP | - |

**Unique Constraint**: (user_id, achievement_type) - Each user can only have each achievement once

### 6. alerts
**Purpose**: Stores in-app notifications and alerts
**Relationships**: References auth.users(id)

| Column | Type | Description | Default | Constraints |
|--------|------|-------------|---------|-------------|
| id | UUID | Primary key | gen_random_uuid() | NOT NULL |
| user_id | UUID | References auth.users | - | NOT NULL, REFERENCES auth.users(id) ON DELETE CASCADE |
| alert_type | TEXT | Type of alert | - | NOT NULL |
| title | TEXT | Alert title | - | NOT NULL |
| message | TEXT | Alert message | - | NOT NULL |
| is_read | BOOLEAN | Whether alert has been read | false | - |
| action | TEXT | Associated action | - | - |
| data | JSONB | Additional alert data | - | - |
| created_at | TIMESTAMP WITH TIME ZONE | Record creation time | CURRENT_TIMESTAMP | - |
| read_at | TIMESTAMP WITH TIME ZONE | When alert was read | - | - |

### 7. user_subscriptions
**Purpose**: Stores subscription information for cross-platform sync
**Relationships**: References auth.users(id)

| Column | Type | Description | Default | Constraints |
|--------|------|-------------|---------|-------------|
| id | UUID | Primary key | gen_random_uuid() | NOT NULL |
| user_id | UUID | References auth.users | - | NOT NULL, REFERENCES auth.users(id) ON DELETE CASCADE, UNIQUE |
| product_id | TEXT | Store product ID | - | NOT NULL |
| status | TEXT | Subscription status | 'active' | NOT NULL |
| purchase_date | TIMESTAMP WITH TIME ZONE | When subscription was purchased | CURRENT_TIMESTAMP | - |
| expires_at | TIMESTAMP WITH TIME ZONE | When subscription expires | - | - |
| transaction_id | TEXT | Store transaction ID | - | - |
| is_trial | BOOLEAN | Whether in trial period | false | - |
| created_at | TIMESTAMP WITH TIME ZONE | Record creation time | CURRENT_TIMESTAMP | - |
| updated_at | TIMESTAMP WITH TIME ZONE | Last update time | CURRENT_TIMESTAMP | - |

**Unique Constraint**: user_id - Each user can only have one active subscription

## Indexes

### Performance Indexes
- `idx_achievements_user_id` on achievements(user_id)
- `idx_achievements_type` on achievements(achievement_type)
- `idx_alerts_user_id` on alerts(user_id)
- `idx_alerts_is_read` on alerts(is_read)
- `idx_alerts_created_at` on alerts(created_at DESC)
- `idx_user_subscriptions_user_id` on user_subscriptions(user_id)
- `idx_user_subscriptions_status` on user_subscriptions(status)
- `idx_user_subscriptions_expires_at` on user_subscriptions(expires_at)

## Row Level Security (RLS)

All tables have RLS enabled with the following policies:
- **SELECT**: Users can only view their own records
- **INSERT**: Users can only insert records for themselves
- **UPDATE**: Users can only update their own records
- **DELETE**: Users can only delete their own records

Policy naming convention:
- "Users can view own {table_name}"
- "Users can insert own {table_name}"
- "Users can update own {table_name}"
- "Users can delete own {table_name}"

## Database Functions

### delete_account()
**Purpose**: Deletes all user data from all tables
**Security**: SECURITY DEFINER (runs with elevated privileges)
**Access**: Granted to authenticated users
**Returns**: void

This function:
1. Gets the current user ID from auth.uid()
2. Deletes records from all tables in the correct order:
   - achievements
   - alerts
   - entries
   - shifts
   - employers
   - user_subscriptions
   - users_profile
3. Respects foreign key constraints
4. Cannot delete the auth.users record (handled by Supabase Auth)

## Supabase Configuration

### Connection Details
- **Project URL**: https://ztzpjsbfzcccvbacgskc.supabase.co
- **Anon Key**: Stored in app configuration
- **Database**: PostgreSQL 15+
- **Region**: US East 1

### Authentication
- **Provider**: Supabase Auth
- **Methods**: Email/Password
- **Session Management**: JWT tokens
- **Password Reset**: Email-based

## Important Notes for Android Development

1. **Database Compatibility**:
   - All table names and column names must match exactly (case-sensitive)
   - Use the same UUID format for IDs
   - Timestamps should use ISO 8601 format

2. **Subscription Sync**:
   - iOS uses StoreKit, Android uses Google Play Billing
   - Both must write to user_subscriptions table for cross-platform sync
   - product_id should include platform prefix (ios_ or android_)

3. **Data Types Mapping**:
   - UUID → String (in Kotlin)
   - DECIMAL → BigDecimal or Double
   - TIMESTAMP WITH TIME ZONE → Instant or OffsetDateTime
   - JSONB → Map<String, Any> or custom serialization

4. **Required Libraries**:
   - Supabase Kotlin Client
   - Kotlinx Serialization for JSON
   - Kotlinx DateTime for timestamps

5. **Migration Order** (if setting up new database):
   1. users_profile (depends on auth.users)
   2. employers (depends on users_profile)
   3. shifts (depends on users_profile and employers)
   4. entries (depends on users_profile and employers)
   5. achievements (depends on auth.users)
   6. alerts (depends on auth.users)
   7. user_subscriptions (depends on auth.users)

## Maintenance Notes

- **Vacuum**: Run regular VACUUM for performance
- **Monitoring**: Track table sizes and query performance
- **Backups**: Automated daily backups via Supabase
- **Updates**: Coordinate schema changes between iOS and Android teams

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Sep 2024 | Initial schema |
| 1.1 | Sep 2024 | Added average_deduction_percentage to users_profile |
| 2.0 | Sep 15, 2025 | Documentation update for Android development |