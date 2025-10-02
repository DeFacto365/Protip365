# ProTip365 - Product Requirements Document
**Version:** 4.0
**Date:** October 2025
**Platform:** iOS (v1.0.26 Deployed) | Android (Active Development)
**Purpose:** Unified technical specification for cross-platform development

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Core Data Architecture](#core-data-architecture)
3. [System Architecture](#system-architecture)
4. [Feature Specifications](#feature-specifications)
5. [iOS Implementation Status](#ios-implementation-status)
6. [Android Implementation Status](#android-implementation-status)
7. [Platform-Specific Notes](#platform-specific-notes)

---

## Executive Summary

### App Overview
ProTip365 is a comprehensive tip and income tracking application for service industry workers. It provides shift planning, financial tracking, performance analytics, and multi-employer support across iOS and Android platforms.

### Current Status
- **iOS:** v1.0.26 live in production
- **Android:** Active development with core features implemented
- **Backend:** Shared Supabase database with RLS security
- **Sync:** Real-time cross-platform data synchronization

### Key Features
- Shift planning with overlap detection and cross-day support
- Financial tracking (tips, sales, wages, deductions)
- Real-time performance analytics with targets
- Multi-employer management
- In-app alert system with navigation
- Multi-language support (EN/FR/ES)
- PIN and biometric security
- Subscription management (Part-Time vs Full Access)

---

## Core Data Architecture

### Database Schema (Shared iOS/Android)

**Simplified Two-Table Structure:**

#### 1. `expected_shifts` - Shift Planning
```sql
id                    UUID PRIMARY KEY
user_id               UUID NOT NULL
employer_id           UUID (references employers.id)
shift_date            DATE NOT NULL
start_time            TIME NOT NULL
end_time              TIME NOT NULL
expected_hours        DECIMAL(5,2) NOT NULL
hourly_rate           DECIMAL(10,2) NOT NULL
lunch_break_minutes   INTEGER DEFAULT 0
status                TEXT DEFAULT 'planned' -- 'planned', 'completed', 'missed'
alert_minutes         INTEGER -- notification timing
notes                 TEXT
created_at            TIMESTAMPTZ DEFAULT now()
updated_at            TIMESTAMPTZ DEFAULT now()
```

#### 2. `shift_entries` - Actual Work Data
```sql
id                  UUID PRIMARY KEY
shift_id            UUID NOT NULL (references expected_shifts.id)
user_id             UUID NOT NULL
actual_start_time   TIME NOT NULL
actual_end_time     TIME NOT NULL
actual_hours        DECIMAL(5,2) NOT NULL
sales               DECIMAL(10,2) DEFAULT 0
tips                DECIMAL(10,2) DEFAULT 0
cash_out            DECIMAL(10,2) DEFAULT 0
other               DECIMAL(10,2) DEFAULT 0
notes               TEXT
created_at          TIMESTAMPTZ DEFAULT now()
updated_at          TIMESTAMPTZ DEFAULT now()
UNIQUE(shift_id)    -- One entry per shift
```

#### 3. `employers` - Multi-Employer Support
```sql
id              UUID PRIMARY KEY
user_id         UUID NOT NULL
name            TEXT NOT NULL
hourly_rate     DECIMAL(10,2) NOT NULL
active          BOOLEAN DEFAULT true
created_at      TIMESTAMPTZ DEFAULT now()
```

#### 4. `users_profile` - User Settings
```sql
user_id                  UUID PRIMARY KEY
default_hourly_rate      DECIMAL(10,2) NOT NULL
week_start               INTEGER DEFAULT 0 -- 0=Sunday, 1=Monday
tip_target_percentage    DECIMAL(5,2)
target_sales_daily       DECIMAL(10,2)
target_sales_weekly      DECIMAL(10,2)
target_sales_monthly     DECIMAL(10,2)
target_hours_daily       DECIMAL(5,2)
target_hours_weekly      DECIMAL(5,2)
target_hours_monthly     DECIMAL(5,2)
name                     TEXT
default_employer_id      UUID
default_alert_minutes    INTEGER
preferred_language       TEXT DEFAULT 'en'
use_multiple_employers   BOOLEAN DEFAULT false
```

#### 5. `alerts` - In-App Notification System
```sql
id           UUID PRIMARY KEY
user_id      UUID NOT NULL
alert_type   TEXT NOT NULL -- 'shiftReminder', 'missingShift', etc.
title        TEXT NOT NULL
message      TEXT NOT NULL
is_read      BOOLEAN DEFAULT false
action       TEXT
data         JSONB -- Navigation metadata
created_at   TIMESTAMPTZ DEFAULT now()
read_at      TIMESTAMPTZ
```

#### 6. `user_subscriptions` - Subscription Management
```sql
user_id                UUID PRIMARY KEY
subscription_tier      TEXT -- 'part_time', 'full_access'
subscription_status    TEXT -- 'active', 'expired', 'trial'
trial_start_date       DATE
trial_end_date         DATE
subscription_start     TIMESTAMPTZ
subscription_end       TIMESTAMPTZ
```

### Data Benefits
- **50% reduction** in table complexity vs previous schema
- **Single source of truth** - no data duplication
- **Clear separation** - planning vs actual work
- **Maintained RLS** - all tables secured with Row Level Security
- **Cross-platform sync** - consistent data across iOS/Android

---

## System Architecture

### iOS Architecture (SwiftUI + MVVM)

**Entry Point:** `ProTip365App.swift`
- Language initialization from iOS system settings
- Notification delegate setup
- AlertManager environment injection
- App lifecycle management

**Main Coordinator:** `ContentView.swift`
- Authentication state management
- Security lock screen coordination
- Subscription verification
- Onboarding flow control
- Navigation management (iPad sidebar / iPhone tab bar)

**Core Managers (Singleton Pattern):**

1. **SupabaseManager** (`Managers/SupabaseManager.swift`)
   - Database CRUD operations
   - Authentication management
   - Real-time subscriptions
   - Optimized queries with concurrent fetching

2. **SecurityManager** (`Authentication/SecurityManager.swift`)
   - PIN authentication with CryptoKit hashing
   - Biometric (Face ID/Touch ID) integration
   - Auto-lock on background/inactive
   - Four security modes: none, biometric, PIN, both

3. **SubscriptionManager** (`Subscription/SubscriptionManager.swift`)
   - StoreKit 2 integration
   - Product loading and purchasing
   - Receipt validation
   - Part-time limit enforcement (3 shifts/entries per week)
   - Trial period management

4. **AlertManager** (`Managers/AlertManager.swift`)
   - Database-backed alerts synced across devices
   - Badge count management (iOS 17+ compatible)
   - Navigation coordination
   - Alert lifecycle management

5. **NotificationManager** (`Managers/NotificationManager.swift`)
   - iOS local notification scheduling
   - Shift reminder notifications
   - Permission management
   - Badge clearing

**UI Pattern:**
- SwiftUI with MVVM architecture
- Environment objects for dependency injection
- @AppStorage for persistent preferences
- @StateObject/@ObservedObject for reactive state

### Android Architecture (Jetpack Compose + MVVM + Hilt)

**Entry Point:** `ProTip365Application.kt`
- Hilt dependency injection setup
- Application-level initialization

**Main Activity:** `MainActivity.kt`
- Compose UI hosting
- Navigation graph setup
- Theme application

**Architecture Layers:**

1. **Data Layer** (`data/`)
   - `models/`: Data classes (ExpectedShift, ShiftEntry, CompletedShift, etc.)
   - `repository/`: Repository implementations with Supabase integration
   - `local/`: PreferencesManager for local settings
   - `remote/`: SupabaseClient wrapper

2. **Domain Layer** (`domain/`)
   - `repository/`: Repository interfaces
   - Business logic separation

3. **Presentation Layer** (`presentation/`)
   - `screens/`: Composable UI screens
   - `viewmodels/`: State management
   - `components/`: Reusable UI components
   - `navigation/`: Navigation graph and routing
   - `localization/`: Multi-language support system

**Key Components:**
- Hilt for dependency injection
- StateFlow for reactive state management
- Coroutines for async operations
- Material Design 3 components
- Custom localization system (TranslationManager)

---

## Feature Specifications

### 1. Authentication System

**iOS:** `Authentication/AuthView.swift`
**Android:** `presentation/auth/AuthScreen.kt`

**Features:**
- Email/password authentication via Supabase
- Language selector (globe icon, top-right)
- Real-time form validation
- Loading states with disabled UI
- Password reset flow
- Welcome sign-up with guided onboarding
- Session management with auto-refresh

**Onboarding Flow:**
1. Welcome screen with app introduction
2. Profile setup (name, preferred language)
3. Target setting (tip %, sales, hours)
4. Security configuration (PIN/biometric)
5. Subscription tier selection
6. Completion and main app entry

### 2. Dashboard

**iOS:** `Dashboard/DashboardView.swift`
**Android:** `presentation/dashboard/DashboardScreen.kt`

**Period Selector:**
- Today / Week / Month / Year
- 4-week pay period option
- Custom date range (Full Access only)
- Visual period indicators

**Stats Cards:**
1. **Total Revenue** (large, prominent)
2. **Income** (NET salary after deductions)
3. **Tips** (with percentage and target progress)
4. **Hours Worked** (with progress indicator)
5. **Sales** (with target comparison)
6. **Tip-out** (total deductions)
7. **Other Income** (additional earnings)

**Performance Indicators:**
- Target progress only shown for "Today" period
- Color-coded performance:
  - Green: ≥100% of target
  - Purple: ≥75% of target
  - Orange: ≥50% of target
  - Red: <50% of target
- Trend indicators (up/down arrows)

**Data Loading:**
- Optimized queries with concurrent fetching
- Loads from `expected_shifts` joined with `shift_entries`
- Real-time metrics calculation
- Pull-to-refresh support

### 3. Calendar & Shifts

**iOS:** `Calendar/CalendarShiftsView.swift`
**Android:** `presentation/calendar/CalendarScreen.kt`

**Month Calendar View:**
- Custom calendar with shift indicators
- Color-coded dots by status:
  - Purple: Planned shifts
  - Green: Completed shifts
  - Red: Missed shifts
- Today highlight
- Date selection
- Month/year navigation

**Shift List:**
- Chronological shift entries below calendar
- Date, time, employer display
- Total earnings per shift
- Financial breakdown on tap
- Swipe/tap actions for edit/delete

**Add/Edit Shift:**

**iOS:** `AddShift/AddShiftView.swift`
**Android:** `presentation/shifts/AddEditShiftScreen.kt`

**Features:**
- Employer selection dropdown
- Cross-day shift support (separate start/end dates)
- Lunch break options (None, 15, 30, 45, 60 min)
- Alert/reminder dropdown (15min, 30min, 1hr, 1 day, None)
- Real-time hours calculation
- Shift overlap detection and prevention
- Delete confirmation (edit mode)

**Validation:**
- Prevents overlapping shifts at same employer
- Automatic overnight shift detection
- Smart defaults (8-hour duration, user's default alert)
- Error messages in all languages

### 4. Employers Management

**iOS:** `Employers/EmployersView.swift`
**Android:** `presentation/employers/EmployersScreen.kt`

**Features:**
- Only visible when `useMultipleEmployers` is true
- Employer cards with details
- Active/inactive status toggle
- Custom hourly rate per employer
- Default tip-out percentage
- Color coding per employer
- Add/edit/delete operations
- Analytics by employer

### 5. Settings

**iOS:** `Settings/SettingsView.swift`
**Android:** `presentation/settings/SettingsScreen.kt`

**Sections:**

1. **Profile**
   - Name and email display
   - Language selection (EN/FR/ES)
   - Currency preference

2. **Targets**
   - Tip percentage target
   - Sales targets (daily/weekly/monthly)
   - Hours targets (daily/weekly/monthly)
   - Visual progress indicators

3. **Work Defaults**
   - Week start day (Sunday/Monday)
   - Default hourly rate
   - Multiple employers toggle
   - Default employer selection
   - Default shift alert timing

4. **Security**
   - PIN setup/change
   - Face ID/Touch ID toggle (iOS) / Biometric (Android)
   - Auto-lock settings
   - Security type selection (none/biometric/PIN/both)

5. **Subscription**
   - Current plan display
   - Usage statistics (Part-Time tier)
   - Upgrade button
   - Manage subscription (iOS: App Store, Android: Play Store)

6. **Support**
   - In-app support form
   - FAQ link
   - Privacy policy
   - Terms of service

7. **Account**
   - Export data (CSV)
   - Change password
   - Sign out
   - Delete account

### 6. Calculator

**iOS:** `Utilities/TipCalculatorView.swift`
**Android:** `presentation/calculator/TipCalculatorScreen.kt`

**Features:**
- Bill amount entry with decimal keyboard
- Tip percentage quick buttons (15%, 18%, 20%, 25%)
- Custom percentage input
- Slider for fine adjustment
- Split bill calculator (per-person amounts)
- Real-time calculations
- Haptic feedback

### 7. Alert System

**iOS:** `Managers/AlertManager.swift` + `Components/NotificationBell.swift`
**Android:** `presentation/alerts/AlertsScreen.kt` + `presentation/components/NotificationBell.kt`

**Alert Types:**
- `shiftReminder`: Upcoming shift with navigation to edit
- `missingShift`: Reminder to add yesterday's shift data
- `incompleteShift`: Alert for incomplete entries
- `targetAchieved`: Target achievement celebration
- `personalBest`: Personal record notifications
- `reminder`: General reminders

**Features:**
- Database-backed persistent alerts (synced across devices)
- Visual notification bell icon with badge count
- Interactive alert list with swipe-to-delete
- Direct navigation to relevant content (shift editing, calendar)
- Auto-deletion after user action
- Real-time badge updates
- Full localization support

**Navigation Flow:**
1. User taps alert in bell menu
2. Alert manager extracts navigation data (e.g., shiftId)
3. Coordinator switches tabs and presents relevant sheet
4. Alert auto-deletes after navigation

### 8. Subscription Tiers

**Part-Time Tier:**
- $2.99/month, $30/year (iOS pricing)
- 3 shifts per week limit
- 3 entries per week limit
- Single employer only
- Basic analytics

**Full Access Tier:**
- $4.99/month, $49.99/year (iOS pricing)
- Unlimited shifts/entries
- Multiple employers
- Advanced analytics
- Data export (CSV)
- Custom date ranges

**Trial Period:**
- 7-day free trial for new users
- Full access during trial
- Auto-converts to selected tier after trial

---

## iOS Implementation Status

### ✅ Completed Features (v1.0.26)

**Core Systems:**
- [x] Supabase integration with optimized queries
- [x] Security manager (PIN + biometric)
- [x] Subscription manager (StoreKit 2)
- [x] Alert manager with navigation
- [x] Notification manager (iOS local notifications)
- [x] Export manager (CSV export)

**Authentication:**
- [x] Email/password auth
- [x] Password reset
- [x] Welcome sign-up flow
- [x] Onboarding system
- [x] Session management

**Dashboard:**
- [x] Period selector (Today/Week/Month/Year/4-week)
- [x] Stats cards with all metrics
- [x] Performance indicators with color coding
- [x] Target progress tracking
- [x] Empty state UI

**Calendar:**
- [x] Month view with shift indicators
- [x] Shift list with financial details
- [x] Add/edit shift with validation
- [x] Cross-day shift support
- [x] Overlap detection
- [x] Delete functionality

**Other:**
- [x] Employers management
- [x] Settings (all sections)
- [x] Calculator
- [x] Multi-language (EN/FR/ES)
- [x] iPad layout (sidebar navigation)
- [x] iPhone layout (liquid glass tab bar)

**Database:**
- [x] Simplified 2-table structure
- [x] RLS policies on all tables
- [x] Optimized queries with concurrent fetching

### 🔄 Current Focus
- App Store review process
- User feedback integration
- Performance optimization

---

## Android Implementation Status

### ✅ Completed Features

**Core Systems:**
- [x] Supabase client integration
- [x] Hilt dependency injection
- [x] Repository pattern implementation
- [x] PreferencesManager for local storage
- [x] TranslationManager for localization

**Data Models:**
- [x] ExpectedShift model
- [x] ShiftEntry model
- [x] CompletedShift (combined view model)
- [x] Employer model
- [x] UserProfile model
- [x] Alert model

**Repositories:**
- [x] AuthRepository
- [x] UserRepository
- [x] ExpectedShiftRepository
- [x] ShiftEntryRepository
- [x] CompletedShiftRepository
- [x] EmployerRepository
- [x] AlertRepository
- [x] SubscriptionRepository

**UI Screens:**
- [x] AuthScreen with language selector
- [x] OnboardingScreen
- [x] DashboardScreen with period selector
- [x] CalendarScreen with custom calendar view
- [x] AddEditShiftScreen
- [x] EmployersScreen
- [x] SettingsScreen (all sections)
- [x] TipCalculatorScreen
- [x] AlertsScreen

**Navigation:**
- [x] Navigation graph with all routes
- [x] Bottom navigation bar
- [x] Deep links support
- [x] Conditional Employers tab

**Components:**
- [x] NotificationBell with badge
- [x] LanguageSelector
- [x] DashboardPeriodSelector
- [x] DashboardStatsCards
- [x] CustomCalendarView
- [x] iOS26LiquidGlassTabBar (Android adaptation)

**Localization:**
- [x] Multi-language support (EN/FR/ES)
- [x] BaseLocalization
- [x] DashboardLocalization
- [x] AuthLocalization
- [x] OnboardingLocalization
- [x] SettingsLocalization
- [x] NavigationLocalization

### 🚧 In Progress

**Testing:**
- [ ] Unit tests for repositories
- [ ] Unit tests for ViewModels
- [ ] Integration tests
- [ ] UI tests

**Subscription:**
- [ ] Google Play Billing integration
- [ ] Part-time limit enforcement
- [ ] Trial period management
- [ ] Subscription status syncing

**Security:**
- [ ] BiometricAuthManager implementation
- [ ] PIN setup and validation
- [ ] LockScreen implementation
- [ ] SecurityManager completion

**Notifications:**
- [ ] Android notification channels
- [ ] Shift reminder scheduling
- [ ] Notification handling

**Polish:**
- [ ] Loading states refinement
- [ ] Error handling improvements
- [ ] Accessibility compliance
- [ ] Performance optimization

### 📅 Upcoming

**Phase 1: Core Completion**
- Complete subscription integration
- Finalize security system
- Implement notification system
- Comprehensive error handling

**Phase 2: Testing & QA**
- Full test coverage
- Performance testing
- User acceptance testing
- Bug fixes

**Phase 3: Release Preparation**
- Play Store assets
- App description and screenshots
- Privacy policy update
- Beta testing

**Phase 4: Launch**
- Staged rollout
- Monitoring and analytics
- User feedback collection
- Iterative improvements

---

## Platform-Specific Notes

### iOS Specifics

**StoreKit 2:**
- Modern subscription management
- Automatic receipt validation
- Transaction history tracking
- Sandbox testing environment

**Security:**
- Keychain for PIN storage
- LocalAuthentication for biometrics
- CryptoKit for PIN hashing
- Secure enclave support

**Notifications:**
- UNUserNotificationCenter for local notifications
- NotificationDelegate for foreground handling
- Badge management with iOS 17+ APIs
- Rich notification support

**UI:**
- SwiftUI with native components
- Liquid glass design with blur effects
- iPad-specific sidebar layout
- SF Symbols icon system

### Android Specifics

**Google Play Billing:**
- BillingClient for subscriptions
- Purchase verification
- Subscription state management
- Testing with license tester accounts

**Security:**
- BiometricPrompt for fingerprint/face unlock
- EncryptedSharedPreferences for PIN
- Hashing with Android Crypto
- Hardware-backed keystore

**Notifications:**
- NotificationManager with channels
- WorkManager for scheduled notifications
- Badge support (Android 8.0+)
- Notification actions

**UI:**
- Jetpack Compose with Material 3
- Custom theming system
- Adaptive layouts for tablets
- Material icons

---

## Key Implementation Details

### Shift Overlap Detection Algorithm

**Logic (same for iOS/Android):**
```
Four overlap scenarios:
1. New shift starts during existing shift
2. New shift ends during existing shift
3. New shift completely contains existing shift
4. Existing shift completely contains new shift

Excludes:
- Self when editing
- Different employers (if multi-employer enabled)
```

**Implementation:**
- Time comparison using minutes since midnight
- Database query filtered by date
- Real-time validation before save
- Localized error messages

### Cross-Day Shift Support

**Features:**
- Separate start and end date tracking
- Automatic overnight detection (end time < start time)
- Proper hour calculation across date boundaries
- Visual indication of overnight shifts
- Backwards compatible with existing data

**Calculation:**
```
If endTime < startTime:
    endDate = startDate + 1 day

duration = (endDateTime - startDateTime) / 3600
```

### Alert Navigation Coordination

**Flow:**
1. Alert contains JSONB data field with navigation metadata
2. User taps alert in notification bell
3. AlertManager extracts shiftId or other data
4. Posts NotificationCenter event (iOS) or uses NavController (Android)
5. Coordinator switches tabs with 300ms delay
6. Sheet/screen presented with 100ms delay after tab switch
7. Alert marked as read and deleted

**Timing Critical:**
- Too fast: tab switch incomplete
- Too slow: jarring UX
- Current: 100ms dismiss + 300ms tab + 100ms present

---

## Version History

**v4.0 (October 2025):**
- Complete rewrite and consolidation
- Removed outdated/redundant information
- Accurate iOS v1.0.26 status
- Updated Android implementation progress
- Streamlined structure

**v3.2 (September 2024):**
- Database modernization
- Simplified schema
- Alert system implementation

**v3.1 (December 2024):**
- Cross-day shift support
- Enhanced validation

**v3.0 (November 2024):**
- Initial detailed specification

---

**Document Status:** Current and Accurate
**Next Review:** After Android launch or major feature additions
**Maintained By:** Development Team
