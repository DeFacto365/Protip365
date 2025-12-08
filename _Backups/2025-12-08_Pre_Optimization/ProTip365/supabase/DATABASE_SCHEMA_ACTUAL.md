# ProTip365 ACTUAL Production Database Schema
**Source**: Direct export from Supabase production database
**Last Updated**: September 15, 2025
**Important**: This is the ACTUAL schema currently in production. Android app MUST use these exact table structures.

## Tables Overview

The production database contains 9 tables and 1 view:
1. `achievements` - User achievements/badges
2. `alerts` - In-app notifications
3. `employers` - Employer/workplace information
4. `entries` - Quick income entries without hours
5. `password_reset_tokens` - Password reset functionality
6. `shift_income` - Detailed shift income tracking
7. `shifts` - Work shift records
8. `user_subscriptions` - Subscription information
9. `users_profile` - User profile and settings
10. `v_shift_income` - View for shift income data

## Detailed Schema

### achievements
```sql
CREATE TABLE public.achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_achievement UNIQUE(user_id, achievement_type)
);
```
**Indexes**: `idx_achievements_user_id`, `idx_achievements_type`

### alerts
```sql
CREATE TABLE public.alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    action TEXT,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE
);
```
**Indexes**: `idx_alerts_user_id`, `idx_alerts_is_read`, `idx_alerts_created_at DESC`

### employers
```sql
CREATE TABLE public.employers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    hourly_rate NUMERIC(10,2) DEFAULT 15.00 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    active BOOLEAN DEFAULT TRUE  -- Note: field is 'active' not 'is_active'
);
```

### entries
```sql
CREATE TABLE public.entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    employer_id UUID REFERENCES employers(id) ON DELETE SET NULL,
    entry_date DATE NOT NULL,
    sales NUMERIC(10,2) DEFAULT 0,
    tips NUMERIC(10,2) DEFAULT 0,
    hourly_rate NUMERIC(10,2) DEFAULT 0,
    cash_out NUMERIC(10,2) DEFAULT 0,
    other NUMERIC(10,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
**Indexes**: `idx_entries_user_id`, `idx_entries_entry_date DESC`, `idx_entries_employer_id`

### password_reset_tokens (NOT IN iOS APP)
```sql
CREATE TABLE public.password_reset_tokens (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### shift_income (NOT IN iOS APP)
```sql
CREATE TABLE public.shift_income (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    shift_id UUID NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    actual_hours NUMERIC(5,2) NOT NULL,
    sales NUMERIC(10,2) DEFAULT 0 NOT NULL,
    tips NUMERIC(10,2) DEFAULT 0 NOT NULL,
    cash_out NUMERIC(10,2) DEFAULT 0 NOT NULL,
    other NUMERIC(10,2) DEFAULT 0 NOT NULL,
    actual_start_time TIME,
    actual_end_time TIME,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    entry_notes TEXT
);
```

### shifts
```sql
CREATE TABLE public.shifts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    shift_date DATE NOT NULL,
    hours NUMERIC(4,2) NOT NULL,
    hourly_rate NUMERIC(10,2),
    sales NUMERIC(10,2) DEFAULT 0,
    tips NUMERIC(10,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    employer_id UUID REFERENCES employers(id) ON DELETE CASCADE,
    cash_out NUMERIC(10,2) DEFAULT 0,
    cash_out_note TEXT,
    start_time TIME,
    end_time TIME,
    other DOUBLE PRECISION DEFAULT 0,  -- Note: DOUBLE not NUMERIC
    expected_hours NUMERIC(5,2),
    lunch_break_hours NUMERIC(3,2) DEFAULT 0.0 NOT NULL,
    status TEXT DEFAULT 'completed',
    lunch_break_minutes INTEGER DEFAULT 0
);
```
**Special Features**:
- Full-text search index on notes: `idx_shifts_notes`
- Trigger: `auto_hourly_rate` BEFORE INSERT

### user_subscriptions
```sql
CREATE TABLE public.user_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT,
    status TEXT CHECK (status IN ('active', 'expired', 'cancelled')),
    expires_at TIMESTAMP WITH TIME ZONE,
    transaction_id TEXT,
    purchase_date TIMESTAMP WITH TIME ZONE,
    environment TEXT CHECK (environment IN ('sandbox', 'production')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```
**Indexes**: `idx_user_subscriptions_user_id`, `idx_user_subscriptions_status`, `idx_user_subscriptions_expires_at`

### users_profile
```sql
CREATE TABLE public.users_profile (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    default_hourly_rate NUMERIC(10,2) DEFAULT 15.00,
    week_start INTEGER DEFAULT 0 CHECK (week_start >= 0 AND week_start <= 6),
    -- Legacy tip target fields (deprecated but still in DB)
    target_tip_daily NUMERIC(10,2) DEFAULT 100,
    target_tip_weekly NUMERIC(10,2) DEFAULT 500,
    target_tip_monthly NUMERIC(10,2) DEFAULT 2000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    language VARCHAR(5) DEFAULT 'en',  -- Legacy field
    name VARCHAR(255),
    -- Current target fields
    target_sales_daily NUMERIC(10,2) DEFAULT 0,
    target_sales_weekly NUMERIC(10,2) DEFAULT 0,
    target_sales_monthly NUMERIC(10,2) DEFAULT 0,
    target_hours_daily NUMERIC(6,1) DEFAULT 0,
    target_hours_weekly NUMERIC(6,1) DEFAULT 0,
    target_hours_monthly NUMERIC(6,1) DEFAULT 0,
    use_multiple_employers BOOLEAN DEFAULT FALSE,
    default_employer_id UUID REFERENCES employers(id),
    tip_target_percentage NUMERIC(10,2) DEFAULT 0,
    has_variable_schedule BOOLEAN DEFAULT FALSE,
    average_deduction_percentage NUMERIC(5,2) DEFAULT 30.00
        CHECK (average_deduction_percentage >= 0 AND average_deduction_percentage <= 100),
    preferred_language TEXT DEFAULT 'en'
        CHECK (preferred_language IN ('en', 'fr', 'es'))
);
```

## Critical Differences for Android Development

### 1. Field Name Differences
- `employers.active` (NOT `is_active`)
- `shifts.other` is DOUBLE PRECISION (not NUMERIC)

### 2. Additional Fields in Production
**shifts table extras**:
- `expected_hours`
- `lunch_break_hours`
- `lunch_break_minutes`
- `status`
- `cash_out_note`

**users_profile extras**:
- `has_variable_schedule`
- Legacy fields: `target_tip_daily`, `target_tip_weekly`, `target_tip_monthly`
- Duplicate language fields: `language` AND `preferred_language`

### 3. Tables NOT Used by iOS App
- `password_reset_tokens` - Handled by Supabase Auth
- `shift_income` - Not implemented in iOS

### 4. Check Constraints
- `user_subscriptions.status`: Must be 'active', 'expired', or 'cancelled'
- `user_subscriptions.environment`: Must be 'sandbox' or 'production'
- `users_profile.preferred_language`: Must be 'en', 'fr', or 'es'
- `users_profile.week_start`: Must be 0-6

## Android Implementation Notes

### Required Data Models
Create Kotlin data classes matching these EXACT structures:

```kotlin
// Example for shifts table
data class Shift(
    val id: String = UUID.randomUUID().toString(),
    val userId: String,
    val shiftDate: LocalDate,
    val hours: BigDecimal,
    val hourlyRate: BigDecimal?,
    val sales: BigDecimal = BigDecimal.ZERO,
    val tips: BigDecimal = BigDecimal.ZERO,
    val notes: String?,
    val createdAt: Instant = Clock.System.now(),
    val employerId: String?,
    val cashOut: BigDecimal = BigDecimal.ZERO,
    val cashOutNote: String?,
    val startTime: LocalTime?,
    val endTime: LocalTime?,
    val other: Double = 0.0,  // Note: Double not BigDecimal
    val expectedHours: BigDecimal?,
    val lunchBreakHours: BigDecimal = BigDecimal.ZERO,
    val status: String = "completed",
    val lunchBreakMinutes: Int = 0
)
```

### Critical Implementation Rules
1. **Use exact field names** - Supabase is case-sensitive
2. **Match data types precisely** - Especially `shifts.other` as Double
3. **Include all fields** - Even if not used, to avoid deserialization errors
4. **Handle nullable fields** - Many fields are optional
5. **Respect check constraints** - Validate before sending to DB

### Ignored Tables
The Android app can safely ignore:
- `password_reset_tokens` (Supabase Auth handles this)
- `shift_income` (Not implemented in iOS, skip for parity)

## RLS Policies
All tables have Row Level Security enabled with standard policies:
- Users can only SELECT/INSERT/UPDATE/DELETE their own records
- Exception: `password_reset_tokens` may have special policies

## Database Functions
- `delete_account()` - Deletes all user data
- `set_default_hourly_rate()` - Trigger function for shifts table

## View: v_shift_income
A database view exists but details weren't provided. Likely joins shifts with shift_income data.