# ProTip365 - Product Requirements Document & Technical Specifications
**Version:** 4.1
**Date:** October 2, 2025
**Platform:** iOS (v1.1.31 - Production Ready), Android (In Development)
**Purpose:** Complete product specification and technical implementation guide

---

## Table of Contents
1. [Product Overview](#product-overview)
2. [App Architecture](#app-architecture)
3. [Core Systems & Managers](#core-systems--managers)
4. [Feature Specifications](#feature-specifications)
5. [Data Models & Database](#data-models--database)
6. [UI Components & Design System](#ui-components--design-system)
7. [Technical Implementation Details](#technical-implementation-details)
8. [Android Development Guide](#android-development-guide)

---

## Product Overview

### What is ProTip365?
ProTip365 is a comprehensive tip and shift tracking application designed for service industry professionals. It enables users to:
- Track shifts, hours, and earnings across multiple employers
- Monitor tips, sales, and performance metrics
- Set and achieve income targets
- Analyze performance trends over time
- Export data for tax purposes and record keeping

### Target Audience
- Restaurant servers and bartenders
- Delivery drivers (food delivery, rideshare)
- Hotel and hospitality staff
- Any tipped service industry professional

### Key Value Propositions
1. **Simplified Income Tracking**: Quick shift entry with comprehensive financial data
2. **Multi-Employer Support**: Track work across multiple jobs seamlessly
3. **Performance Analytics**: Understand earnings patterns and optimize performance
4. **Tax Preparation**: Export capabilities for accurate tax reporting
5. **Privacy & Security**: PIN and biometric protection for sensitive financial data

### Current Status
- **iOS**: v1.1.31 (Production, App Store)
- **Android**: In active development
- **Subscription Model**: $3.99/month with 7-day free trial
- **Platform**: Supabase (PostgreSQL + Auth + Realtime)

### Recent Updates (v1.1.31)
- Fixed subscription page appearing twice on app launch
- Fixed shift status being overwritten when editing existing shifts
- Fixed today's shifts incorrectly marked as "completed"
- Added per-shift sales target customization

---

## App Architecture

### Main App Structure
```
ProTip365App.swift (Entry Point)
├── ContentView.swift (Main Coordinator)
├── Authentication/ (Auth Flow)
├── Managers/ (Core Services)
├── Components/ (Reusable UI)
├── Dashboard/ (Main Dashboard)
├── Calendar/ (Calendar & Shifts)
├── Settings/ (App Settings)
├── Employers/ (Multi-Employer)
├── Subscription/ (Billing)
├── Utilities/ (Helpers)
└── Localization/ (en.lproj, fr.lproj, es.lproj)
```

### Key Architecture Patterns
- **MVVM**: Model-View-ViewModel pattern throughout
- **Manager Pattern**: Singleton managers for core services
- **Environment Objects**: Dependency injection via SwiftUI
- **@AppStorage**: Persistent user preferences
- **@StateObject/@ObservedObject**: Reactive state management

---

## Core Systems & Managers

### 1. SupabaseManager (Singleton)
**File:** `Managers/SupabaseManager.swift`
**Purpose:** Central database and authentication hub

**Key Features:**
- Supabase client initialization with configuration validation
- Authentication state management
- Real-time subscriptions
- CRUD operations for all data models
- Error handling and retry logic

**Methods:**
```swift
// Authentication
func signUp(email: String, password: String) async throws -> AuthResponse
func signIn(email: String, password: String) async throws -> AuthResponse
func signOut() async throws
func resetPassword(email: String) async throws

// Data Operations
func fetchEmployers() async throws -> [Employer]
func createShift(_ shift: Shift) async throws -> Shift
func updateShift(_ shift: Shift) async throws -> Shift
func deleteShift(id: UUID) async throws
// ... similar for entries, achievements, alerts
```

### 2. SecurityManager (ObservableObject)
**File:** `Authentication/SecurityManager.swift`
**Purpose:** PIN and biometric authentication

**Security Types:**
- `none`: No security
- `biometric`: Face ID/Touch ID only
- `pinCode`: 4-digit PIN only
- `both`: Biometric with PIN fallback

**Key Features:**
- PIN hashing with CryptoKit
- Biometric authentication with LocalAuthentication
- Auto-lock on app background/inactive
- Secure PIN storage in Keychain

### 3. SubscriptionManager (ObservableObject)
**File:** `Subscription/SubscriptionManager.swift`
**Purpose:** StoreKit 2 integration and subscription management

**Features:**
- Product loading and purchasing
- Subscription status tracking
- Receipt validation with Apple servers
- 7-day free trial management
- Trial period validation
- Optimized subscription checking to prevent duplicate flows

**Critical Implementation:**
- Subscription checking happens ONCE per app launch
- Auth state listener prevents duplicate subscription checks
- Guards against concurrent subscription validation
- Ensures subscription screen doesn't appear twice on launch

### 4. AlertManager (ObservableObject)
**File:** `Managers/AlertManager.swift`
**Purpose:** Comprehensive in-app notification and alert system

**Alert Types:**
- `shiftReminder`: Upcoming shift notifications with navigation
- `missingShift`: Reminders for missing shift data
- `incompleteShift`: Alerts for incomplete shift entries
- `targetAchieved`: Target achievement celebrations
- `personalBest`: Personal record notifications
- `reminder`: General reminders
- Subscription limit warnings

**Key Features:**
- Database-backed persistent alerts (synced across devices)
- Visual notification bell with badge count
- Interactive alert list with swipe-to-delete
- Direct navigation to relevant content
- Auto-deletion after user action
- Real-time badge updates (iOS 17+ compatible)
- Full localization support (EN/FR/ES)

**Alert Data Structure:**
```swift
struct DatabaseAlert {
    let id: UUID
    let user_id: UUID
    let alert_type: String
    let title: String
    let message: String
    let action: String?
    let data: Data? // JSON encoded additional data
    let created_at: Date
    let read: Bool
}
```

**Navigation System:**
- Alerts can contain navigation data (e.g., shiftId)
- Tapping alerts navigates directly to relevant content
- Automatic tab switching and view presentation
- Timing-coordinated navigation for smooth UX
---

## Feature Specifications

### Authentication & Onboarding

#### 1. Authentication Page (AuthView)

**File:** `Authentication/AuthView.swift`
**Components:**
1. **Language Selector** (Top Right)
   - Globe icon with current language
   - Dropdown menu (EN/FR/ES)
   - Rounded background with tint color

2. **Logo Section**
   - App icon (100x100, rounded corners, shadow)
   - "ProTip365" title (large, bold)
   - Welcome text (subtitle, secondary color)

3. **Form Fields**
   - Email field with validation
   - Password field with show/hide toggle
   - Real-time validation feedback
   - Keyboard navigation support

4. **Action Buttons**
   - Primary action (Sign In/Sign Up)
   - Secondary action (Toggle mode)
   - Forgot password link
   - Loading states with disabled UI

5. **Welcome Sign-Up Flow**
   - Multi-step onboarding
   - Profile setup
   - Security configuration
   - Subscription selection

**States:**
- Loading: Disabled form with spinner
- Error: Error message display
- Success: Navigation to main app
- Validation: Real-time field validation

**Localization:**
- Auto-detects iOS system language on first launch
- Supports EN, FR, ES with fallback to English
- Syncs with system language changes
- Persists user preference to Supabase

**Security:**
- Biometric authentication (Face ID / Touch ID)
- 4-digit PIN protection
- Auto-lock on background/inactive
- CryptoKit for PIN hashing
- Keychain integration

### Core Features

#### 2. Dashboard Page (DashboardView)

**File:** `Dashboard/DashboardView.swift`
**Components:**
1. **Period Selector**
   - Today/Week/Month/Year tabs
   - 4-week pay period option
   - Custom date range (Full Access)
   - Visual period indicators

2. **Stats Grid**
   - Total Revenue (large, prominent)
   - Income card (shows NET salary after deductions)
   - Tips card with percentage and target
   - Hours worked card with progress
   - Sales card with target
   - Tip-out card
   - Other income card

3. **Performance Indicators**
   - Target progress only shown for "Today" tab
   - Color-coded performance:
     - Green: ≥100% of target
     - Purple: ≥75% of target
     - Orange: ≥50% of target
     - Red: <50% of target
   - Trend indicators (up/down arrows)
   - Percentage changes

4. **Empty State**
   - Illustration/image
   - "No data yet" message
   - "Add First Shift" button

**Data Sources:**
- Loads from `expected_shifts` joined with `shift_entries`
- Handles optional fields with fallback values
- Calculated metrics include deduction percentages
- Target comparisons for daily metrics
- Historical trends
- Simplified queries with better performance

**DashboardMetrics Helper:**
- Calculates stats with optional field handling
- Formats currency and percentages
- Manages target calculations by period
- Handles NET vs GROSS income display

**Navigation:**
- iOS26LiquidGlassTabBar for iPhone
- NavigationSplitView for iPad
- Conditional Employers tab (when multi-employer enabled)

#### 3. Calendar Page (CalendarShiftsView)

**File:** `Calendar/CalendarShiftsView.swift`
**Components:**
1. **Month View**
   - Month/Year header with navigation
   - Week day labels
   - Date grid with indicators
   - Today highlight
   - Color-coded shift status dots:
     - Purple: Planned shifts
     - Green: Completed shifts
     - Red: Missed shifts
   - Selection state

2. **Shift List**
   - Chronological shift entries below calendar
   - Date, time, employer info
   - Total earnings display
   - Financial breakdown (sales, tips, salary)
   - Delete functionality from edit view
   - Empty state for no shifts

3. **Action Buttons**
   - "Add Entry" button (always visible)
   - "Add Shift" button (disabled for past dates)
   - Buttons properly positioned with ScrollView

4. **Legend**
   - Purple square: Planned
   - Green square: Completed
   - Red square: Missed
   - Fully localized (EN/FR/ES)

**Features:**
- Loads directly from `expected_shifts` table for calendar display
- Color-coded by shift status (not employer)
- Selected date passes to AddEntryView
- Delete from edit view with confirmation
- Proper padding to avoid tab bar overlap

#### 3.1 Add/Edit Shift (AddShiftView)

**File:** `AddShift/AddShiftView.swift`
**Data Manager:** `AddShift/AddShiftDataManager.swift`

**Components:**
1. **Header**
   - Cancel button (X icon)
   - Title (New Shift / Edit Shift)
   - Delete button (when editing)
   - Save button (checkmark icon)

2. **Shift Details Section**
   - Employer selection (dropdown)
   - Notes/comments (text field)
   - Sales target (optional per-shift override, defaults to user's daily target)

3. **Time Section**
   - Start date picker
   - Start time picker
   - End date picker (separate for cross-day shifts)
   - End time picker
   - Lunch break dropdown (None, 15, 30, 45, 60 min)

4. **Alert Section**
   - Reminder dropdown (15 min, 30 min, 60 min, 1 day, None)
   - Uses default from settings
   - Can override per shift

5. **Summary Section**
   - Expected hours calculation
   - Real-time updates
   - Cross-day shift support

**Validation Features:**
1. **Overlap Prevention**
   ```swift
   checkForOverlappingShifts() -> Bool
   - Queries existing shifts for the same date
   - Compares time ranges in minutes
   - Excludes current shift when editing
   - Shows error with conflict details
   ```

2. **Cross-Day Support**
   - Separate date tracking for start/end
   - Automatic overnight detection
   - Proper hour calculation across dates
   - Visual indication of overnight shifts

3. **Smart Defaults**
   - 8-hour default duration
   - Auto-adjustment of end time
   - Default alert from user settings
   - Current employer pre-selected

4. **Error Messages**
   - "Shift Conflict" alert
   - Shows conflicting employer and times
   - Localized in EN/FR/ES
   - Clear resolution guidance

5. **Status Management**
   - **New Shifts**: Status auto-set based on shift date (not time)
     - Today or future → "planned"
     - Yesterday or earlier → "completed"
   - **Editing Shifts**: Status is PRESERVED from original shift
     - Never auto-changed when editing
     - User must explicitly change status if desired
   - **Critical**: Comparing dates only (ignoring time) prevents today's shifts from being marked "completed"

#### 4. Settings Page (SettingsView)

**File:** `Settings/SettingsView.swift`
**Sections:**
1. **Profile Section**
   - Name and email display
   - Language selection
   - Currency preference

2. **Targets Section**
   - Tip percentage target
   - Sales targets (daily/weekly/monthly)
   - Hours targets (daily/weekly/monthly)
   - Visual progress indicators

3. **Preferences Section**
   - Week start day (Sunday/Monday)
   - Default hourly rate
   - Multiple employers toggle
   - Default employer selection

4. **Security Section**
   - PIN setup/change
   - Face ID/Touch ID toggle
   - Auto-lock settings
   - Security type selection

5. **Subscription Section**
   - Current subscription status
   - Trial days remaining (if applicable)
   - Manage subscription link
   - Subscription renewal date

6. **Support Section**
   - In-app support form
   - FAQ link
   - Privacy policy
   - Terms of service

7. **Account Section**
   - Export data (CSV)
   - Change password
   - Sign out
   - Delete account

**Form Behavior:**
- Save/Cancel buttons in header
- Disabled save when no changes
- Real-time validation
- Loading states for async operations

**Subscription Management:**
- StoreKit 2 integration
- $3.99/month with 7-day free trial
- Subscription status display
- Trial days remaining
- Manage subscription link

#### 5. Employers Page (EmployersView)

**File:** `Employers/EmployersView.swift`
**Components:**
1. **Employer List**
   - Employer cards with details
   - Active/inactive status
   - Color coding
   - Quick actions

2. **Add Employer**
   - Name (required)
   - Address (optional)
   - Custom hourly rate
   - Default tip-out percentage
   - Active/inactive toggle

3. **Edit Employer**
   - Pre-filled form
   - Update capabilities
   - Delete option

**Features:**
- Only visible when `useMultipleEmployers` is true
- Employer selection in shift entry
- Analytics by employer
- Performance comparison

#### 6. Calculator Page (TipCalculatorView)

**File:** `Utilities/TipCalculatorView.swift`
**Components:**
1. **Bill Entry**
   - Amount input with decimal keyboard
   - Currency formatting
   - Clear button

2. **Tip Percentage**
   - Quick buttons (15%, 18%, 20%, 25%)
   - Custom percentage input
   - Slider for fine adjustment

3. **Results Display**
   - Tip amount
   - Total with tip
   - Per person (if splitting)

4. **Split Bill Feature**
   - Number of people selector
   - Equal split calculation
   - Individual amounts

**Features:**
- Real-time calculations
- Haptic feedback
- Currency formatting
- Quick calculations (tip-out, hourly rate)

---

## Data Models & Database

### Core Models (Simplified Structure)
**File:** `Managers/Models.swift`

```swift
struct UserProfile: Codable {
    let user_id: UUID
    let default_hourly_rate: Double
    let week_start: Int // 0=Sunday, 1=Monday
    let tip_target_percentage: Double?
    let name: String?
    let default_employer_id: UUID?
}

struct Employer: Codable, Identifiable, Hashable {
    let id: UUID
    let user_id: UUID
    let name: String
    let hourly_rate: Double
    let active: Bool
    let created_at: Date
}

struct ExpectedShift: Codable, Identifiable, Hashable {
    let id: UUID?
    let user_id: UUID
    let employer_id: UUID?

    // Scheduling data
    let shift_date: String
    let start_time: String
    let end_time: String
    let expected_hours: Double
    let hourly_rate: Double

    // Break time
    let lunch_break_minutes: Int?

    // Sales target (optional per-shift override)
    let sales_target: Double?

    // Status and metadata
    let status: String // planned, completed, missed
    let alert_minutes: Int?
    let notes: String?

    let created_at: Date?
    let updated_at: Date?
}

struct ShiftEntry: Codable, Identifiable, Hashable {
    let id: UUID?
    let shift_id: UUID
    let user_id: UUID

    // Actual work times
    let actual_start_time: String
    let actual_end_time: String
    let actual_hours: Double

    // Financial data
    let sales: Double?
    let tips: Double?
    let cash_out: Double?
    let other: Double?

    // Entry-specific notes
    let notes: String?

    let created_at: Date?
    let updated_at: Date?
}

// Combined view for dashboard display
struct CompletedShift: Codable, Identifiable, Equatable {
    let id: UUID
    let user_id: UUID
    let employer_id: UUID?
    let employer_name: String?

    // Shift planning data
    let shift_date: String
    let expected_hours: Double
    let hourly_rate: Double
    let lunch_break_minutes: Int?

    // Actual work data (from shift_entry)
    let actual_hours: Double?
    let sales: Double?
    let tips: Double?
    let cash_out: Double?
    let other: Double?

    // Calculated fields
    let base_income: Double?
    let net_tips: Double?
    let total_income: Double?
    let tip_percentage: Double?

    let status: String
    let notes: String?
    let created_at: Date?
}
```

### Simplified Database Schema
**Core Tables:**
- `users_profile`: User settings and preferences
- `employers`: Multi-employer support
- `expected_shifts`: Planned/scheduled shifts with expected hours and timing
- `shift_entries`: Actual work data and financial earnings (one-to-one with expected_shifts)
- `achievements`: User achievement tracking
- `alerts`: In-app notification system
- `user_subscriptions`: Subscription management

**Key Improvements:**
- **Simplified Structure**: Reduced from 4+ overlapping tables to 2 core tables
- **Clear Separation**: `expected_shifts` for planning, `shift_entries` for actual work
- **No Data Duplication**: Each piece of data has a single source of truth
- **Better Performance**: Simpler queries, fewer joins required
- **Maintained RLS**: All tables have Row Level Security enabled

**Table Relationships:**
- `expected_shifts` ↔ `shift_entries` (one-to-one via shift_id)
- `expected_shifts` → `employers` (many-to-one)
- All tables → `users_profile` (many-to-one via user_id)

---

## UI Components & Design System

### Design System
**File:** `Utilities/DesignSystem.swift`

**Colors:**
- Primary: System blue
- Success: System green
- Warning: System yellow
- Danger: System red
- Background: Adaptive (light/dark mode)

**Typography:**
- Headers: SF Pro Display
- Body: SF Pro Text
- Numbers: SF Pro Rounded

**Components:**
- **LiquidGlassCard**: Translucent with blur effects
- **StatCard**: Main metric display
- **DetailCard**: Expandable information
- **ShiftCard**: Shift list item
- **AchievementCard**: Achievement display

### Liquid Glass Design
**Features:**
- Semi-transparent backgrounds
- Blur effects (ultraThinMaterial)
- Rounded corners (12pt radius)
- Subtle shadows
- Smooth animations

### Component Library
**Key Components:**

**1. NotificationBell** (`Components/NotificationBell.swift`)
- Interactive notification icon with badge
- Sheet presentation for alert list
- Swipe-to-delete functionality
- Color-coded alert types
- Time-ago formatting
- Direct navigation support
- Auto-deletion after action

**2. iOS26LiquidGlassTabBar** (`Components/iOS26LiquidGlassTabBar.swift`)
- Custom tab bar with glass morphism
- Navigation state management
- Alert navigation coordination
- Adaptive sizing for device types

**3. FlexibleHeader** (`Components/FlexibleHeader.swift`)
- Collapsible header with animations
- Contextual actions
- Adaptive layout

**4. LiquidGlassToggle** (`Components/LiquidGlassToggle.swift`)
- Custom toggle with glass effects
- Smooth state transitions
- Haptic feedback

---

## Technical Implementation Details

### Navigation System
**iOS26LiquidGlassTabBar** (`Components/iOS26LiquidGlassTabBar.swift`)
- Liquid glass design with blur effects
- Smooth animations and transitions
- Scroll-aware behavior
- Dynamic tab visibility (Employers conditional)
- Haptic feedback

**Tab Structure:**
- Dashboard → DashboardView
- Calendar → CalendarShiftsView
- Employers → EmployersView (conditional on useMultipleEmployers)
- Calculator → TipCalculatorView
- Settings → SettingsView

**iPad Navigation:**
- NavigationSplitView for sidebar navigation
- Persistent sidebar with list-style navigation
- Detail view for main content

### Localization System
**Implementation:** `ProTip365App.swift`, `en.lproj/`, `fr.lproj/`, `es.lproj/`

**Features:**
- Auto-detects iOS system language on first launch
- Dynamic language switching without restart
- Persists preference to Supabase database
- Syncs across devices
- Falls back to English for unsupported languages

**Pattern:**
```swift
@AppStorage("language") private var language = "en"

var localizedText: String {
    switch language {
    case "fr": return "Texte en français"
    case "es": return "Texto en español"
    default: return "Text in English"
    }
}
```

---

## Android Development Guide

### Phase 1: Core Infrastructure
1. **Project Setup**
   - Android Studio project structure
   - Gradle configuration
   - Dependencies (Supabase, Compose, etc.)

2. **Core Managers**
   - SupabaseManager (Kotlin equivalent)
   - SecurityManager (PIN/Biometric)
   - SubscriptionManager (Google Play Billing)
   - AlertManager (In-app notifications)

3. **Authentication System**
   - AuthView equivalent
   - Language selector
   - Form validation
   - Supabase integration

### Phase 2: Main Features
1. **Navigation System**
   - Bottom navigation bar
   - Conditional tab visibility
   - Navigation graph

2. **Dashboard Implementation**
   - Stats cards
   - Period selector
   - Real-time data updates

3. **Calendar Implementation**
   - Month view
   - Shift list
   - Date selection

### Phase 3: Advanced Features
1. **Settings Implementation**
   - All settings sections
   - Form validation
   - Preference persistence

2. **Multi-Employer Support**
   - Employer management
   - Conditional UI
   - Analytics by employer

3. **Calculator Implementation**
   - Tip calculator
   - Split bill feature
   - Quick calculations

### Phase 4: Polish & Testing
1. **Localization**
   - String resources
   - Dynamic language switching
   - Cultural adaptations

2. **Security Features**
   - PIN entry
   - Biometric authentication
   - Auto-lock functionality

3. **Subscription Integration**
   - Google Play Billing
   - 7-day free trial
   - $3.99/month subscription
   - Subscription management

### Phase 5: Testing & Launch
1. **Comprehensive Testing**
   - Feature parity verification
   - Performance testing
   - User acceptance testing

2. **App Store Preparation**
   - Screenshots
   - Store listing
   - Privacy policy

---

## Database Migration & Simplification

### Migration Overview
**Date:** September 2024
**Purpose:** Simplify overly complex database structure

**Previous Issues Addressed:**
- Multiple overlapping tables: `shifts`, `shift_income`, `entries`, `v_shift_income`
- Data duplication across tables (shift_date, employer_id, hourly_rate)
- Redundant fields: `lunch_break_hours` + `lunch_break_minutes` (only minutes used)
- Complex queries requiring multiple joins

**New Simplified Architecture:**

**1. `expected_shifts` Table:**
```sql
CREATE TABLE expected_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    employer_id UUID REFERENCES employers(id),

    -- Scheduling data
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    expected_hours DECIMAL(5,2) NOT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL,

    -- Break time
    lunch_break_minutes INTEGER DEFAULT 0,

    -- Sales target (optional per-shift override)
    sales_target DECIMAL(10,2),

    -- Status and metadata
    status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'completed', 'missed')),
    alert_minutes INTEGER,
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

**Status Field Behavior:**
- **New shifts**: Auto-set based on shift DATE only (not time)
  - `shift_date >= today` → "planned"
  - `shift_date < today` → "completed"
- **Editing shifts**: Status is preserved, never auto-changed
- **User control**: Status can be manually changed through UI

**2. `shift_entries` Table:**
```sql
CREATE TABLE shift_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES expected_shifts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,

    -- Actual work times
    actual_start_time TIME NOT NULL,
    actual_end_time TIME NOT NULL,
    actual_hours DECIMAL(5,2) NOT NULL,

    -- Financial data
    sales DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,
    cash_out DECIMAL(10,2) DEFAULT 0,
    other DECIMAL(10,2) DEFAULT 0,

    -- Entry-specific notes
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    -- Ensure one entry per shift
    UNIQUE(shift_id)
);
```

**Benefits:**
- **50% Reduction** in table complexity
- **Eliminated Data Duplication** - single source of truth for each data point
- **Improved Query Performance** - fewer joins required
- **Clearer Data Model** - planning vs actual work clearly separated
- **Maintained Security** - RLS enabled on all new tables
- **Preserved Functionality** - all existing features supported

---

## Critical Implementation Notes

### 1. Feature Parity Requirements
- **100% feature match** with iOS version
- **Identical data models** and validation
- **Same subscription model** ($3.99/month with 7-day trial)
- **Equivalent UI/UX** experience
- **Cross-platform data sync** via Supabase

### 2. Technical Considerations
- Use **Jetpack Compose** for UI
- Implement **MVVM architecture**
- Use **Hilt** for dependency injection
- Follow **Material Design 3** guidelines
- Ensure **accessibility** compliance

### 3. Data Consistency
- Same **Supabase database** as iOS
- Identical **API contracts**
- Real-time **synchronization**
- Consistent **validation rules**

### 4. User Experience
- **Platform-appropriate** navigation
- **Native feel** with Material Design
- **Performance optimization**
- **Offline capability** where appropriate

---

## Summary

### Current State (October 2025)
**iOS Application (v1.1.30):**
- ✅ Production ready and available on App Store
- ✅ Complete feature set with all core functionality
- ✅ Subscription system with 7-day free trial
- ✅ Multi-language support (EN, FR, ES)
- ✅ Security features (PIN, biometric)
- ✅ Comprehensive alert and notification system
- ✅ Simplified database architecture with optimal performance

**Android Application:**
- 🔄 In active development
- 🔄 Core infrastructure completed
- 🔄 Working toward feature parity with iOS

### Key Achievements
1. **Simplified Database:** Reduced from 4+ overlapping tables to 2 core tables
2. **Modern Alert System:** Database-backed alerts with smart navigation
3. **Cross-Platform Ready:** Shared Supabase backend for iOS and Android
4. **Production Stability:** Multiple iterations of bug fixes and improvements
5. **Localization:** Full support for English, French, and Spanish

### Next Priorities
1. Complete Android feature parity
2. Android app store launch
3. User feedback integration
4. Performance optimizations
5. Feature enhancements based on analytics

---

---

## Document Change Log

### Version 4.0 (October 2025)
**Major Restructuring:**
- Consolidated duplicate and outdated sections
- Updated to reflect iOS v1.1.30 production status
- Clarified product overview and value propositions
- Streamlined architecture documentation
- Removed redundant technical details
- Updated subscription pricing and trial information
- Consolidated alert system documentation
- Updated current implementation status

### Version 3.2 (September 2024)
**Changes:**
- Database simplification (removed redundant tables)
- Shift validation and cross-day support
- Enhanced alert system with navigation

### Version 3.1 (August 2024)
**Changes:**
- Initial comprehensive iOS specification
- Android implementation roadmap
- Core systems documentation

---

## Recent Feature Additions (v1.0.24 - v1.1.30)

### v1.1.30 (Current Production)
- Language auto-detection from iOS system settings
- Improved notification handling and badge management
- Enhanced subscription state management
- Bug fixes and performance improvements

### v1.1.31 - Critical Bug Fixes (October 2, 2025)

#### 1. Subscription Flow Fix
**Issue:** Subscription page appeared twice on app launch (flash → disappear → reappear)

**Root Cause:**
- Duplicate `.onAppear` block in ContentView calling `checkAuth()` after `.task` already called it
- Auth state changes listener triggering multiple subscription checks during initial setup

**Solution:**
- Removed duplicate `.onAppear` block in `ContentView.swift`
- Added guard in auth state listener to prevent concurrent subscription checks
- Subscription now checks ONCE per app launch

**Files Changed:**
- `ProTip365/ContentView.swift:66-71` (removed duplicate onAppear)
- `ProTip365/ContentView.swift:344-361` (added concurrent check guard)

#### 2. Shift Status Preservation Fix
**Issue:** Editing existing shifts incorrectly changed status to "completed"

**Root Cause:**
- Save logic calculated status for ALL shifts (new and existing)
- Status was being recalculated based on date/time, overwriting the existing status

**Solution:**
- When **editing** existing shifts: Preserve original status, never auto-change
- When **creating** new shifts: Auto-set status based on DATE only (not time)

**Files Changed:**
- `ProTip365/AddShift/AddShiftDataManager.swift:512-530` (preserve status on edit)

#### 3. Today's Shifts Status Fix
**Issue:** Creating new shifts for "today" marked them as "completed" if the start time had passed

**Root Cause:**
- Status logic compared full date-time instead of just the date
- If creating a shift for today at 9am when it's currently 2pm, it would mark as "completed"

**Solution:**
- Changed comparison from date-time to DATE only
- Today or future dates → "planned"
- Yesterday or earlier → "completed"

**Files Changed:**
- `ProTip365/AddShift/AddShiftDataManager.swift:550-556` (date-only comparison)

**Implementation Guide:**
- See `/Docs/ANDROID_SHIFT_STATUS_PRESERVATION_FIX.md` for Android implementation details

#### 4. Per-Shift Sales Target
**Enhancement:** Added ability to set custom sales targets per shift

**Features:**
- Optional `sales_target` field in `expected_shifts` table
- Empty value defaults to user's daily sales target
- Custom value overrides default for that specific shift

**Files Changed:**
- `ProTip365/AddShift/AddShiftDataManager.swift:35,339-344,516-517,558-559` (sales_target field)
- `ProTip365/AddShift/AddShiftView.swift:190,199` (sales_target UI binding)
- Database schema updated with `sales_target` column

---

### v1.0.26 - Shift Validation & Cross-Day Support

### Comprehensive Shift Validation System

#### 1. Shift Overlap Prevention
**File:** `AddShift/AddShiftDataManager.swift`

**Overlap Detection Algorithm:**
```swift
// Four overlap scenarios checked:
1. New shift starts during existing shift:
   newStart >= existingStart && newStart < existingEnd
2. New shift ends during existing shift:
   newEnd > existingStart && newEnd <= existingEnd
3. New shift completely contains existing:
   newStart <= existingStart && newEnd >= existingEnd
4. Existing shift completely contains new:
   existingStart <= newStart && existingEnd >= newEnd
```

**Features:**
- Real-time validation before saving
- Excludes self when editing existing shifts
- Multi-employer support (can have overlapping shifts at different employers)
- Time-based comparison using minutes since midnight
- Database query optimization with date filtering

**Error Handling:**
- Localized error messages (EN/FR/ES)
- Shows conflicting employer name and time range
- Alert dialog with clear explanation
- Prevents database save on conflict

#### 2. Cross-Day Shift Support
**Implementation:**
- Separate `selectedDate` and `endDate` variables
- Automatic overnight shift detection
- Smart validation for end time vs start time
- Proper hour calculation across date boundaries

**UI Updates:**
- Independent date pickers for start and end
- Visual indication of overnight shifts
- Automatic date advancement for late-night shifts
- Preserves existing single-date shifts

**Validation Logic:**
```swift
// Detect cross-day shifts automatically
if endTimeMinutes < startTimeMinutes {
    endDate = nextDay
}

// Calculate hours across dates
let timeInterval = endDateTime - startDateTime
let hours = timeInterval / 3600
```

#### 3. Smart Time Management
- Auto-adjustment of end time when start time changes
- Default 8-hour shift duration for new shifts
- Lunch break deduction from total hours
- Prevention of negative duration shifts
- Handling of 24+ hour shifts for cross-day scenarios

### v1.0.25 - Enhanced Alert System
- Visual notification bell with badge count
- Alert list management with swipe-to-delete
- Smart navigation from alerts to relevant content
- Alert types: shift reminders, missing shifts, incomplete shifts, achievements
- Database-backed alerts with RLS security
- iOS 17+ badge management API

### v1.0.24 - Alert Foundation System
- Shift alert notifications (15min, 30min, 1hr, 1 day before)
- Default alert settings in user preferences
- NotificationManager for iOS local notifications
- Alert permissions handling
- Database schema updates for alerts

### v1.0.23 - Major Fixes
- Calendar display improvements with color-coded status
- Dashboard data loading from simplified database
- Row Level Security (RLS) implementation
- UI/UX polish (delete functionality, positioning fixes)
- Complete localization (EN/FR/ES)
- Optional field handling throughout app


