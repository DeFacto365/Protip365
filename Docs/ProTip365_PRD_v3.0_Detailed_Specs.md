# ProTip365 - Detailed iOS Implementation Specifications
**Version:** 3.1
**Date:** December 2024
**Platform:** iOS (Fully Implemented v1.0.23), Android (Implementation Guide)
**Purpose:** Complete technical specification with latest updates for Android development

---

## Table of Contents
1. [App Architecture Overview](#app-architecture-overview)
2. [Core Systems & Managers](#core-systems--managers)
3. [Authentication System](#authentication-system)
4. [Localization System](#localization-system)
5. [Security System](#security-system)
6. [Subscription System](#subscription-system)
7. [Navigation System](#navigation-system)
8. [Page-by-Page Specifications](#page-by-page-specifications)
9. [Data Models & Database](#data-models--database)
10. [UI Components & Design System](#ui-components--design-system)
11. [Android Implementation Roadmap](#android-implementation-roadmap)

---

## App Architecture Overview

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
- Receipt validation
- Part-time limit enforcement (3 shifts/3 entries per week)
- Trial period management

### 4. AlertManager (ObservableObject)
**File:** `Managers/AlertManager.swift`
**Purpose:** In-app notification system

**Alert Types:**
- Missing shift reminders
- Target achievement celebrations
- Personal best notifications
- Subscription limit warnings
- Weekly summaries

---

## Authentication System

### AuthView Structure
**File:** `Authentication/AuthView.swift`
**Components:**
1. Language selector (top right)
2. Logo and welcome text
3. Email/password fields
4. Sign up/Sign in toggle
5. Forgot password link
6. Welcome sign-up flow

**AddEntryView Updates:**
**File:** `AddEntry/AddEntryView.swift`
- "Didn't work" option only shown for new entries (not in edit mode)
- Delete button added to header when editing
- Delete confirmation dialog with localization
- Proper date selection from calendar
- Financial data (sales, tips, etc.) saved to shifts table
- Presentation detent set to .large for full-screen view

### Authentication Flow
```
1. Language Selection (EN/FR/ES)
2. Email/Password Entry
3. Form Validation
4. Supabase Authentication
5. User Profile Creation
6. Security Setup (PIN/Biometric)
7. Subscription Selection
8. Main App Entry
```

### Key Features:
- **Real-time Validation**: Email format, password strength
- **Loading States**: Disabled UI during authentication
- **Error Handling**: User-friendly error messages
- **Password Reset**: Email-based reset flow
- **Welcome Flow**: Guided setup for new users

### Localization Support:
- All text dynamically changes based on selected language
- Language preference persisted to database
- System language auto-detection on first launch

---

## Localization System

### Implementation Structure
```
Localization/
├── en.lproj/Localizable.strings
├── fr.lproj/Localizable.strings
└── es.lproj/Localizable.strings
```

### Language Management
**File:** `ProTip365App.swift`
- Auto-detects iOS system language on first launch
- Supports EN, FR, ES with fallback to English
- Syncs with system language changes
- Persists user preference to Supabase database

### Dynamic Localization Pattern
```swift
@AppStorage("language") private var language = "en"

var welcomeText: String {
    switch language {
    case "fr": return "Bienvenue dans ProTip365"
    case "es": return "Bienvenido a ProTip365"
    default: return "Welcome to ProTip365"
    }
}
```

### Localization Files Structure
Each `.lproj` folder contains:
- `Localizable.strings`: UI text translations
- `InfoPlist.strings`: System-level translations
- Face ID usage descriptions
- Local network usage descriptions

---

## Security System

### EnhancedLockScreenView
**File:** `Authentication/EnhancedLockScreenView.swift`
**Features:**
- Blurred background with app content
- Biometric authentication prompt
- PIN entry fallback
- Haptic feedback
- Auto-retry on failure

### PIN Entry System
**File:** `Authentication/PINEntryView.swift`
**Features:**
- 4-digit PIN input
- Secure keypad
- Visual feedback
- Haptic responses
- Error handling

### Security Integration
- Auto-lock on app background/inactive
- Biometric re-authentication on app resume
- Secure PIN storage using CryptoKit
- Keychain integration for persistence

---

## Subscription System

### SubscriptionManager Features
**File:** `Subscription/SubscriptionManager.swift`
- StoreKit 2 integration
- Product loading and purchasing
- Subscription status validation
- Receipt verification
- Part-time limit enforcement
- Trial period management

### Subscription Tiers
**Part-Time Tier:**
- $2.99/month, $30/year
- 3 shifts per week limit
- 3 entries per week limit
- Single employer
- Basic features

**Full Access Tier:**
- $4.99/month, $49.99/year
- Unlimited shifts/entries
- Multiple employers
- Advanced analytics
- Data export

### SubscriptionTiersView
**File:** `Subscription/SubscriptionTiersView.swift`
- Product cards with feature comparison
- Pricing display
- Trial period information
- Purchase flow integration
- Upgrade/downgrade handling

---

## Navigation System

### iOS26LiquidGlassTabBar
**File:** `Components/iOS26LiquidGlassTabBar.swift`
**Features:**
- Liquid glass design with blur effects
- Smooth animations and transitions
- Scroll-aware behavior
- Dynamic tab visibility (Employers conditional)
- Haptic feedback

### Tab Structure
```
Dashboard → DashboardView
Calendar → CalendarShiftsView
Employers → EmployersView (conditional)
Calculator → TipCalculatorView
Settings → SettingsView
```

### iPad Navigation
- Uses `NavigationSplitView` for sidebar navigation
- Persistent sidebar with list-style navigation
- Detail view for main content

---

## Page-by-Page Specifications

### 1. Authentication Page (AuthView)

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

### 2. Dashboard Page (DashboardView)

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
- Loads from v_shift_income view
- Handles optional fields with fallback values
- Calculated metrics include deduction percentages
- Target comparisons for daily metrics
- Historical trends

**DashboardMetrics Helper:**
- Calculates stats with optional field handling
- Formats currency and percentages
- Manages target calculations by period
- Handles NET vs GROSS income display

### 3. Calendar Page (CalendarShiftsView)

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
- Loads directly from shifts table for calendar display
- Color-coded by shift status (not employer)
- Selected date passes to AddEntryView
- Delete from edit view with confirmation
- Proper padding to avoid tab bar overlap

### 4. Settings Page (SettingsView)

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
   - Current plan display
   - Usage statistics (Part-Time)
   - Upgrade button
   - Manage subscription link

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

### 5. Employers Page (EmployersView)

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

### 6. Calculator Page (TipCalculatorView)

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

### Core Models
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

struct Shift: Codable, Identifiable, Hashable {
    let id: UUID?
    let user_id: UUID
    let employer_id: UUID?
    let shift_date: String
    let expected_hours: Double?
    let hours: Double? // Actual hours worked
    let lunch_break_minutes: Int?
    let hourly_rate: Double?
    let sales: Double?
    let tips: Double?
    let cash_out: Double?
    let other: Double?
    let notes: String?
    let start_time: String?
    let end_time: String?
    let status: String? // planned, completed, missed
    let created_at: Date?
}

struct ShiftIncome: Codable, Identifiable, Equatable {
    let income_id: UUID? // ID from shift_income table
    let shift_id: UUID?  // ID from shifts table
    var id: UUID { shift_id ?? income_id ?? UUID() }
    let user_id: UUID
    let employer_id: UUID?
    let employer_name: String?
    let shift_date: String
    let expected_hours: Double?
    let lunch_break_minutes: Int?
    let net_expected_hours: Double?
    let hours: Double? // Optional to handle missing data
    let hourly_rate: Double?
    let sales: Double? // Optional to handle missing data
    let tips: Double? // Optional to handle missing data
    let cash_out: Double?
    let other: Double?
    let base_income: Double?
    let net_tips: Double?
    let total_income: Double?
    let tip_percentage: Double?
    let start_time: String?
    let end_time: String?
    let shift_status: String?
    let has_earnings: Bool
    let shift_created_at: String?
    let earnings_created_at: String?
    let notes: String?
}

struct ShiftIncomeData: Codable, Identifiable {
    let id: UUID?
    let shift_id: UUID
    let user_id: UUID
    let actual_hours: Double
    let sales: Double
    let tips: Double
    let cash_out: Double?
    let other: Double?
    let actual_start_time: String?
    let actual_end_time: String?
    let notes: String?
    let created_at: Date?
}
```

### Database Schema
**Tables:**
- `users_profile`: User settings and preferences
- `employers`: Multi-employer support
- `shifts`: Planned/scheduled shifts with expected hours
- `shift_income`: Actual earnings data for completed shifts
- `v_shift_income`: View combining shifts and shift_income data
- `achievements`: User achievement tracking
- `alerts`: In-app notification system
- `user_subscriptions`: Subscription management

**Important Views:**
- `v_shift_income`: Combined view with RLS (Row Level Security) enabled
  - Joins shifts and shift_income tables
  - Calculates base_income, net_tips, total_income
  - Provides has_earnings flag
  - Security: Users can only see their own data

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
**Files:**
- `Components/FlexibleHeader.swift`
- `Components/iOS26LiquidGlassTabBar.swift`
- `Components/LiquidGlassToggle.swift`
- `Components/NotificationBell.swift`

---

## Android Implementation Roadmap

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
   - Part-time limits
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

## Critical Implementation Notes

### 1. Feature Parity Requirements
- **100% feature match** with iOS version
- **Identical data models** and validation
- **Same subscription tiers** and pricing
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

**Document Version**: 3.1
**Last Updated**: December 2024
**Status**: Complete iOS Specification (v1.0.23), Android Roadmap Ready
**Next Review**: Post Android Implementation

## Recent Updates (v1.0.25 - Shift Overlap Validation)

### Shift Overlap Prevention System
1. **Overlap Detection Logic**
   - Prevents creating shifts that overlap with existing shifts on the same date
   - Comprehensive validation checks four overlap scenarios:
     - New shift starting during an existing shift
     - New shift ending during an existing shift
     - New shift completely containing an existing shift
     - Existing shift completely containing a new shift
   - Shows specific conflict details including employer name and time range

2. **Smart Time Validation**
   - Automatic end time adjustment when start time changes
   - Ensures end time is always after start time
   - Defaults to 8-hour shift duration for new shifts
   - Handles cross-midnight shifts appropriately

3. **Error Messaging**
   - Clear, localized error messages in English, French, and Spanish
   - Shows exact conflict details (employer and time range)
   - User-friendly guidance for resolution

4. **Implementation Details**
   - `checkForOverlappingShifts()` function in AddShiftDataManager
   - Time comparison using minutes for accuracy
   - Skips self-comparison when editing existing shifts
   - Integrated validation before database operations

## Recent Updates (v1.0.24 - Alert System)

### New Alert Notification System
1. **Shift Alert Notifications**
   - Added customizable alert notifications for upcoming shifts
   - Alert options: 15 minutes, 30 minutes, 60 minutes, 1 day before
   - Notifications display employer name and shift start time
   - Full localization support (EN/FR/ES)

2. **Add/Edit Shift Updates**
   - New "Alert" dropdown in shift creation/editing
   - Automatically uses default alert from settings
   - Can override default alert per shift
   - Persists alert preferences in database

3. **Settings Enhancement**
   - Added "Default Alert" setting in Work Defaults section
   - User-defined default for all new shifts
   - Syncs across devices via Supabase

4. **NotificationManager Implementation**
   - Schedules iOS local notifications
   - Handles notification permissions
   - Updates/cancels notifications when shifts change
   - Supports all iOS notification features

5. **Database Schema Updates**
   - Added `alert_minutes` column to shifts table
   - Added `default_alert_minutes` to users_profile table
   - Created indexes for efficient alert queries
   - Added constraints for valid alert values

## Recent Updates (v1.0.23)

### Major Fixes and Improvements
1. **Calendar Display Issues Fixed**
   - Shifts now properly display with color-coded status
   - Fixed data loading from shifts table
   - Added proper refresh handlers
   - Resolved date selection issues

2. **Dashboard Data Loading**
   - Fixed v_shift_income view data retrieval
   - Made ShiftIncome fields optional to handle missing data
   - Proper handling of sales, tips, and financial data
   - NET salary calculation with deduction percentages

3. **Security Enhancement**
   - Added Row Level Security (RLS) to v_shift_income view
   - Ensures users only see their own data
   - Created SQL migration script for RLS policies

4. **UI/UX Improvements**
   - Removed "Didn't work" option from edit mode
   - Added delete functionality to edit entry page
   - Fixed button positioning under tab bar
   - Changed calendar legend colors (Purple for Planned)
   - Removed grey background from entry cards

5. **Localization Updates**
   - Complete calendar localization (EN/FR/ES)
   - Added delete confirmation translations
   - Fixed date format localization
   - Updated status text translations

6. **Model Updates**
   - Made hours, sales, tips fields optional in ShiftIncome
   - Added proper null handling throughout the app
   - Fixed compilation errors in multiple views
   - Updated ExportManager for optional fields


