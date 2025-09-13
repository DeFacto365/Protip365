# ProTip365 Project Summary

## Overview
**ProTip365** is an iOS app for waitstaff to track work hours, tips, sales, and calculate income. Built with SwiftUI and Supabase backend.

## Tech Stack
- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Language**: Swift 5.9
- **Min iOS Version**: 17.0
- **Package Dependencies**: Supabase Swift SDK

## Project Location
```
~/Github/ProTip365/
```

## Core Features Implemented

### 1. **Authentication**
- Email/password sign up and sign in
- User profile creation with name
- Secure session management
- Password reset capability

### 2. **Dashboard**
- Today/Week/Month views with statistics
- Clickable income cards showing detailed breakdowns
- Tips, Sales, Hours, Total Income tracking
- Tip percentage calculation
- Visual stats with colored cards
- Empty state handling
- Detail view with delay fix for proper data loading

### 3. **Shift Management** 
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

### 4. **Employers**
- Add multiple employers with hourly rates
- Toggle in Settings to enable/disable
- Employer tab only shows when enabled
- Currency formatting based on device locale
- Delete employers with swipe
- Single-line display with hourly rate

### 5. **Tip Calculator**
- Bill amount input
- Adjustable tip percentage slider (0-30%)
- Split between people feature (1-20)
- Real-time calculation display
- Per-person amount calculation
- Clean UI without unnecessary buttons

### 6. **Settings**
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

## Recent Updates & Fixes

### **v1.0.18 - Calendar & Entry Improvements (September 2025)**
1. **Calendar View Redesign**:
   - Reduced top padding for better space utilization
   - Moved edit/delete buttons to bottom of entry cards
   - Financial data organized in 3 aligned columns (Caption, Actual, Budget)
   - Replaced time display with hours format (actual/expected)
   - Employer name now smaller to fit on one line

2. **Budget Comparison Feature**:
   - Added daily budget targets display in calendar entries
   - Sales shows actual/target (e.g., $350/500)
   - Tips shows actual/target (e.g., $125/100)
   - Salary shows actual/expected based on hours × rate
   - Fixed database table reference (users_profile not profiles)

3. **Didn't Work Feature**:
   - Toggle for marking shifts as missed
   - Reason codes (Sick, Shift Cancelled, etc.) with translations
   - Proper display in calendar with red status badge
   - Zero hours calculation when didn't work is selected

4. **Date/Time Handling Fixes**:
   - Fixed overnight shift support (crossing midnight)
   - End date calendar now closes on selection
   - Fixed end date preservation when editing times
   - Smart validation ensures start time before end time
   - Automatic date adjustment for overnight shifts

5. **UI Polish**:
   - Blue placeholder text in input fields for better visibility
   - Total amount spans two columns for larger numbers
   - Financial section shifted left for more space
   - Settings cancel button now properly dismisses view
   - Other field restored to revenue calculations

### **v1.0.16 - Analytics & Engagement System**
1. **CSV Export System**: Complete data export with detailed and summary formats
2. **Smart Alert System**: Missing data reminders and achievement celebrations
3. **Achievement Gamification**: Badges, streaks, and progress tracking
4. **Enhanced Sharing**: Social media integration with formatted summaries
5. **Performance Analytics**: Advanced trend analysis and insights
6. **Export Options View**: Professional export interface with date ranges
7. **Achievement Celebrations**: Confetti animations and progress tracking
8. **Alert Management**: Contextual notifications and reminders
9. **Dashboard Enhancements**: Export and share buttons in toolbar
10. **Data Persistence**: Achievement and settings storage

### **v1.0.15 - UI & UX Improvements**
1. **Split DashboardView into multiple files for better maintainability**
2. **Fixed detail view "No data" issue with async delay**
3. Fixed calendar positioning at top of screen
4. Added clickable detail views for all dashboard stats
5. Implemented iOS 18-style form design
6. Removed success alerts for smoother UX
7. Added currency formatting based on device locale
8. Fixed landscape orientation support
9. Implemented save button animation feedback
10. Simplified tip calculator (removed Done button)
11. Fixed empty state for weekly/monthly views
12. Added proper error handling for Supabase queries
13. Fixed AnyJSON handling for user metadata
14. Resolved string interpolation formatting issues
15. Added sales and hours targets to settings
16. Fixed month view to show last 30 days instead of current month

## File Structure
```
ProTip365/
├── Core App Files/
│   ├── ProTip365App.swift          # App entry point
│   ├── ContentView.swift           # Tab navigation
│   ├── AuthView.swift              # Sign in/up screens
│   ├── BiometricAuthManager.swift # Biometric authentication
│   └── LockScreenView.swift        # Lock screen UI
│
├── Main Views/
│   ├── DashboardView.swift         # Main dashboard logic
│   ├── DashboardComponents.swift  # Dashboard UI components
│   ├── AddEntryView.swift          # Add/Edit shift entry (1300+ lines)
│   ├── CalendarShiftsView.swift    # Calendar with shift entries (800+ lines)
│   ├── CalendarView.swift          # Calendar component
│   ├── DetailedEntriesView.swift   # Detailed shift list
│   ├── EmployersView.swift        # Employer management
│   ├── TipCalculatorView.swift     # Tip calculator
│   ├── SettingsView.swift          # User settings (800+ lines)
│   ├── SubscriptionView.swift      # Subscription UI
│   └── iOS26LiquidGlassTabBar.swift # Custom tab bar
│
├── Analytics Features (v1.0.16)/
│   ├── ExportManager.swift         # CSV export functionality
│   ├── AlertManager.swift          # Smart alerts and reminders
│   ├── AchievementManager.swift    # Gamification system
│   ├── ExportOptionsView.swift     # Export interface
│   └── AchievementView.swift       # Achievement celebrations
│
├── Supporting Files/
│   ├── Models.swift                # Data models (Codable structs)
│   ├── SupabaseManager.swift       # Supabase client singleton
│   ├── SubscriptionManager.swift   # In-app purchases
│   ├── ThemeExtension.swift        # UI styling and components
│   └── Assets.xcassets/           # App icons and images
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

## Fixed Issues
1. ✅ Dashboard detail view "No data" issue (fixed with async delay)
2. ✅ Large file maintainability (split into multiple files)
3. ✅ String encoding issues with French/Spanish characters
4. ✅ Empty state for weekly/monthly views
5. ✅ Calendar view shift deletion

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
4. Bundle ID: com.yourcompany.ProTip365

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

## Implemented Features ✅

### **v1.0.16 - Analytics & Engagement**
- ✅ **Data export (CSV reports)** - Complete export system with multiple formats
- ✅ **Income goals with progress tracking** - Target achievement system
- ✅ **Detailed analytics and charts** - Performance tracking and insights
- ✅ **Smart notifications** - Missing data alerts and achievement celebrations
- ✅ **Social sharing** - Formatted summaries for social media
- ✅ **Gamification system** - Badges, streaks, and progress tracking

### **Previous Versions**
- ✅ **Biometric authentication** - Face ID/Touch ID integration
- ✅ **Subscription features** - In-app purchase system
- ✅ **Multi-language support** - English, French, Spanish
- ✅ **Multi-employer support** - Multiple jobs with different rates
- ✅ **Future shift planning** - Expected vs actual shifts
- ✅ **Missed shift tracking** - Absence recording with reasons

## Future Potential Features
- Shift templates for recurring schedules
- Push notifications for shift reminders
- Shift notes with rich text
- Photo receipts attachment
- Backup and restore
- Multi-device sync
- Apple Watch companion app
- Widget for today's earnings
- Siri shortcuts integration
- Advanced data visualization (charts/graphs)
- Team features and collaboration
- API integrations with payroll systems

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
- **Extensions**: UI helpers and styling

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
- v1.1.0 - Added sales/hours targets, fixed detail view issues
- v1.2.0 - Split dashboard into multiple files for maintainability
- v1.0.15 - UI & UX improvements, Liquid Glass design, multi-language support
- v1.0.16 - Analytics & engagement system, CSV export, achievements, smart alerts
- Current - All features listed above implemented

## Contact & Resources
- Project Location: `~/Github/ProTip365/`
- Min iOS Version: 17.0
- Swift Version: 5.9
- Last Updated: December 2024

---

This document provides a complete overview of the ProTip365 project for handoff to the next developer or team member.