# ProTip365 Baseline v1.0.8

## Project Overview
**ProTip365** is an iOS app for waitstaff to track work hours, tips, sales, and calculate income. Built with SwiftUI and Supabase backend.

## Current Version: 1.0.8
**Date**: December 30, 2024  
**Status**: Production Ready

## Tech Stack
- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Language**: Swift 5.9
- **Min iOS Version**: 17.0
- **Package Dependencies**: Supabase Swift SDK

## Core Features Implemented

### ✅ **Authentication & User Management**
- Email/password sign up and sign in
- User profile creation with name
- Secure session management
- Password reset capability
- Biometric authentication support

### ✅ **Dashboard (v1.0.8)**
- Today/Week/Month views with statistics
- **Clickable dashboard cards** (restored in v1.0.1)
- Tips, Sales, Hours, Total Income tracking
- Tip percentage calculation
- Visual stats with colored cards
- Empty state handling
- Detail view with proper data loading
- **Salary field added** (v1.0.4)
- **Future vs actual shifts differentiation** (v1.0.2)

### ✅ **Shift Management (v1.0.8)**
- Weekly calendar view with iOS 18-style UI
- Add/edit shifts with:
  - Start/end times
  - Sales amount
  - Tips amount
  - Tip out (cash out)
  - Employer selection (optional)
- Today's shift summary display
- Bold dates for days with shifts
- Auto-selection of today's date
- Schedule future shifts (without earnings)
- **Time picker auto-dismissal** (v1.0.3)
- **Expected vs actual shifts** (v1.0.2)

### ✅ **Employers (v1.0.8)**
- Add multiple employers with hourly rates
- Toggle in Settings to enable/disable
- Employer tab only shows when enabled
- Currency formatting based on device locale
- Delete employers with swipe
- Single-line display with hourly rate
- **Salary calculation uses employer rates** (v1.0.6)

### ✅ **Tip Calculator**
- Bill amount input
- Adjustable tip percentage slider (0-30%)
- Split between people feature (1-20)
- Real-time calculation display
- Per-person amount calculation
- Clean UI without unnecessary buttons

### ✅ **Settings (v1.0.8)**
- User name management
- Language selection (English, French, Spanish)
- Default hourly rate (when not using employers)
- Tip targets (daily/weekly/monthly)
- Sales targets (daily/weekly/monthly)
- Hours targets (daily/weekly/monthly)
- Week start day selection
- Use multiple employers toggle
- Sign out functionality
- Delete account functionality
- Save confirmation animation
- Currency symbol based on locale
- **ProTip365 logo branding** (v1.0.7)
- **Localized form labels** (v1.0.5)

### ✅ **Feedback System (v1.0.1)**
- In-app feedback form
- Email integration via Supabase Edge Functions
- Proper error handling and validation

## Database Structure

### Tables:

#### users_profile
```sql
- user_id: UUID (Primary Key)
- default_hourly_rate: Double
- target_tip_daily: Double
- target_tip_weekly: Double
- target_tip_monthly: Double
- target_sales_daily: Double
- target_sales_weekly: Double
- target_sales_monthly: Double
- target_hours_daily: Double
- target_hours_weekly: Double
- target_hours_monthly: Double
- week_start: Int
- language: String
- name: String
- use_multiple_employers: Bool
- created_at: Timestamp
```

#### employers
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key)
- name: String
- hourly_rate: Double
- created_at: Timestamp
```

#### shifts
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key)
- shift_date: String (yyyy-MM-dd)
- hours: Double
- sales: Double
- tips: Double
- cash_out: Double
- notes: String
- hourly_rate: Double
- employer_id: UUID (Optional)
- start_time: String
- end_time: String
- created_at: Timestamp
```

#### v_shift_income (View)
```sql
- All shift fields plus:
- total_income: Calculated as (hours × hourly_rate) + tips - cash_out
- employer_name: Joined from employers table
- base_income: Double
- net_tips: Double
- tip_percentage: Double
```

## Recent Updates & Fixes (v1.0.8)

### **v1.0.8 - Build Issues Resolution**
- Fixed `useMultipleEmployers` scope errors in DashboardView
- Updated deprecated `glassCard()` to `liquidGlassCard()` in all components
- Resolved all build errors and warnings

### **v1.0.7 - Branding Enhancement**
- Replaced user icon with ProTip365 logo in Settings page
- Added proper brand colors (purple and orange)
- Improved visual consistency throughout app

### **v1.0.6 - Salary Calculation Fix**
- Fixed salary calculation to use employer-specific hourly rates
- Added `employerHourlyRate` parameter to QuickEntryView
- Proper fallback to default rate when multiple employers disabled

### **v1.0.5 - Edit Shift Enhancement**
- Added employer name display in Edit Shift view
- Added proper localization for employer-related text
- Conditional display based on `useEmployers` setting

### **v1.0.4 - Detail View Enhancement**
- Added missing salary field to shift details
- Salary now shows as first line in totals summary
- Proper localization for salary-related text

### **v1.0.3 - Liquid Glass Implementation**
- Complete Liquid Glass design system overhaul
- Standardized on `.ultraThinMaterial` for all surfaces
- Added `liquidGlassCard()`, `liquidGlassButton()`, `liquidGlassForm()` modifiers
- Consistent depth system and corner radius values
- Backward compatibility with deprecated modifiers

### **v1.0.2 - Future vs Actual Shifts**
- Differentiated between expected (future) and actual (past) shifts
- Future shifts show "Expected" badge instead of earnings
- Past shifts show actual earnings and breakdown
- Proper localization for expected vs actual text

### **v1.0.1 - Feedback Form Fix**
- Fixed Supabase URL in feedback form
- Resolved "server not found" error
- Added comprehensive debugging for troubleshooting

## File Structure
```
ProTip365/
├── ProTip365App.swift          # App entry point
├── ContentView.swift           # Tab navigation
├── AuthView.swift              # Sign in/up screens
├── DashboardView.swift         # Main dashboard logic
├── DashboardComponents.swift   # Dashboard UI components
├── QuickEntryView.swift        # Quick entry form
├── DetailView.swift            # Shift detail view
├── ShiftsCalendarView.swift    # Shift management
├── EmployersView.swift         # Employer management
├── TipCalculatorView.swift     # Tip calculator
├── SettingsView.swift          # User settings
├── SupabaseManager.swift       # Supabase client singleton
├── Models.swift                # Data models (Codable structs)
├── ThemeExtension.swift        # Liquid Glass styling and components
├── BiometricAuthManager.swift  # Biometric authentication
├── LockScreenView.swift        # Lock screen UI
├── SubscriptionManager.swift   # In-app purchases
├── SubscriptionView.swift      # Subscription UI
└── Info.plist                  # App configuration
```

## Data Models

### ShiftIncome
```swift
- id: UUID
- user_id: UUID
- shift_date: String
- hours: Double
- sales: Double
- tips: Double
- cash_out: Double?
- notes: String?
- hourly_rate: Double
- employer_id: UUID?
- employer_name: String?
- total_income: Double?
- base_income: Double?
- net_tips: Double?
- tip_percentage: Double?
- start_time: String?
- end_time: String?
- created_at: String
```

### Employer
```swift
- id: UUID
- user_id: UUID
- name: String
- hourly_rate: Double
- created_at: Date
```

### UserProfile
```swift
- user_id: UUID
- default_hourly_rate: Double
- week_start: Int
- target_tip_daily: Double
- target_tip_weekly: Double
- target_tip_monthly: Double
- name: String?
```

### Shift
```swift
- id: UUID?
- user_id: UUID
- employer_id: UUID?
- shift_date: String
- hours: Double
- hourly_rate: Double?
- sales: Double
- tips: Double
- cash_out: Double?
- cash_out_note: String?
- notes: String?
- start_time: String?
- end_time: String?
- created_at: Date?
```

## Localization
- **Languages**: English, French, Spanish
- **Storage**: @AppStorage("language")
- **Implementation**: In-view computed properties
- **Coverage**: All UI text and labels

## UI/UX Features
- iOS 18-style form designs
- **Liquid Glass design system** (v1.0.3)
- Adaptive color scheme support
- Landscape orientation support
- Tab bar with icons (iPad uses sidebar navigation)
- Pull-to-refresh capability
- Loading states
- Empty state messages
- Validation feedback
- Currency formatting per locale
- Glass morphism effects
- Haptic feedback
- Success toast notifications

## Known Issues/Considerations
1. Keyboard may not show in simulator for tip calculator (works on real device)
2. No data export functionality yet
3. No dark mode specific styling (uses system defaults)
4. localStorage not supported in artifacts

## Environment Setup

### Supabase Configuration
1. Create new Supabase project
2. Run SQL migrations for tables
3. Set up RLS policies
4. Configure auth settings
5. Add Supabase URL and Anon Key to SupabaseManager.swift

### Xcode Setup
1. Xcode 15.0 or later required
2. iOS 17.0+ deployment target
3. Swift Package Manager for dependencies
4. Bundle ID: com.protip365.ProTip365

## Testing Checklist
- [x] Authentication flow (sign up, sign in, sign out)
- [x] Dashboard stats calculation
- [x] Dashboard detail views
- [x] Shift creation and editing
- [x] Employer management
- [x] Language switching
- [x] Landscape orientation
- [x] Empty states
- [x] Data persistence
- [x] Tip calculator accuracy
- [x] Settings save confirmation
- [x] Target goals display
- [x] Week start day functionality
- [x] Future vs actual shifts
- [x] Liquid Glass implementation
- [x] Employer salary calculations
- [x] Feedback form functionality

## Next Potential Features
- Data export (CSV/PDF reports)
- Shift templates for recurring schedules
- Income goals with progress tracking
- Push notifications for shift reminders
- Detailed analytics and charts
- Shift notes with rich text
- Photo receipts attachment
- Backup and restore
- Multi-device sync
- Apple Watch companion app
- Widget for today's earnings
- Siri shortcuts integration
- Biometric authentication (partially implemented)
- Subscription features (partially implemented)

## API Endpoints Used
All through Supabase client:
- `/auth/signup` - User registration
- `/auth/signin` - User login
- `/auth/signout` - User logout
- `/auth/resetPasswordForEmail` - Password reset
- `/rest/v1/users_profile` - Profile CRUD
- `/rest/v1/employers` - Employers CRUD
- `/rest/v1/shifts` - Shifts CRUD
- `/rest/v1/v_shift_income` - Income calculations view
- `/functions/v1/send-suggestion` - Feedback form

## Build & Deploy Instructions

### Development Build
```bash
1. cd ~/Github/ProTip365
2. open ProTip365.xcodeproj
3. Select target device/simulator
4. Press Cmd+R to build and run
```

### Production Build
```bash
1. Select "Any iOS Device" as target
2. Product > Archive
3. Distribute App > App Store Connect
4. Upload to TestFlight/App Store
```

### Required Certificates
- Apple Developer Account
- iOS Distribution Certificate
- App Store Provisioning Profile

## Code Architecture

### File Organization
- **Main Views**: Core app screens (Dashboard, Settings, etc.)
- **Components**: Reusable UI components (split from main views)
- **Models**: Data structures and Codable implementations
- **Managers**: Singleton services (Supabase, Biometric, Subscription)
- **Extensions**: UI helpers and Liquid Glass styling

### State Management
- `@State` for local view state
- `@AppStorage` for user preferences
- `@StateObject` for view models
- `@Environment` for system settings

## Performance Optimizations
- Lazy loading of shift data
- Efficient date calculations
- Minimal re-renders with @State
- Async/await for all API calls
- Proper error handling
- Split large files for faster compilation

## Security Considerations
- Row Level Security (RLS) in Supabase
- User data isolation
- Secure authentication tokens
- No sensitive data in UserDefaults
- HTTPS only communication
- Biometric authentication support

## Support & Maintenance
- Regular Supabase SDK updates
- iOS version compatibility checks
- Localization updates
- Bug fixes based on user feedback
- Performance monitoring

## Version History
- v1.0.0 - Initial release with core features
- v1.0.1 - Added sales/hours targets, fixed detail view issues
- v1.0.2 - Split dashboard into multiple files for maintainability
- v1.0.3 - Complete Liquid Glass implementation overhaul
- v1.0.4 - Added salary field to detail view
- v1.0.5 - Added employer name to edit shift view
- v1.0.6 - Fixed salary calculation for multiple employers
- v1.0.7 - Added ProTip365 branding to settings
- v1.0.8 - Resolved all build issues and warnings

## Contact & Resources
- Project Location: `~/Github/ProTip365/`
- Min iOS Version: 17.0
- Swift Version: 5.9
- Last Updated: December 30, 2024

---

This document provides a complete baseline of the ProTip365 project at version 1.0.8 for handoff to the next developer or team member.
