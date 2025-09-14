# ProTip365 - Product Requirements Document (PRD)
**Version:** 1.0
**Date:** September 2025
**Platform:** iOS (Current), Android (Future)
**Target:** Cross-platform identical experience

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Product Overview](#product-overview)
3. [User Personas & Use Cases](#user-personas--use-cases)
4. [Feature Requirements](#feature-requirements)
5. [Technical Architecture](#technical-architecture)
6. [User Interface Specifications](#user-interface-specifications)
7. [Data Models](#data-models)
8. [Security & Privacy](#security--privacy)
9. [Monetization](#monetization)
10. [Internationalization](#internationalization)
11. [Platform-Specific Requirements](#platform-specific-requirements)
12. [Success Metrics](#success-metrics)

---

## Executive Summary

ProTip365 is a comprehensive tip tracking and income management application designed specifically for service industry workers (waitstaff, bartenders, delivery drivers, etc.). The app enables users to track their daily earnings, set financial goals, analyze performance trends, and manage multiple employers while maintaining complete data privacy and security.

### Key Value Propositions
- **Accurate Income Tracking**: Detailed logging of tips, wages, hours, and sales data
- **Financial Goal Management**: Target setting and progress tracking for daily, weekly, and monthly goals
- **Multi-Employer Support**: Manage shifts across different restaurants or employers
- **Privacy-First Design**: All data encrypted and stored securely with user control
- **Cross-Platform Consistency**: Identical experience across iOS and Android platforms

---

## Product Overview

### Mission Statement
Empower service industry workers to take control of their financial success through intelligent tip tracking, goal setting, and performance analytics.

### Target Market
- **Primary**: Restaurant servers, bartenders, delivery drivers
- **Secondary**: Hair stylists, taxi drivers, hotel staff
- **Geographic**: North America (English, French, Spanish speakers)

### Core Problems Solved
1. **Income Uncertainty**: Service workers struggle to predict and track variable income
2. **Tax Preparation**: Difficulty maintaining accurate records for tax purposes
3. **Goal Setting**: Lack of tools to set and track financial performance goals
4. **Multi-Job Management**: Complexity of tracking earnings across multiple employers
5. **Performance Analysis**: No insights into peak earning periods and performance trends

---

## User Personas & Use Cases

### Primary Persona: Sarah (Restaurant Server)
- **Age**: 28
- **Experience**: 5 years in restaurant industry
- **Goals**: Save for apartment, track tip performance, improve earnings
- **Pain Points**: Inconsistent income, multiple shifts per week, tax record keeping

#### Sarah's User Journey:
1. **Onboarding**: Sets up profile with preferred language, security, and initial targets
2. **Daily Use**: Logs shift details (hours, sales, tips, tip-out) after each shift
3. **Weekly Review**: Checks dashboard for progress against targets
4. **Monthly Analysis**: Exports data for tax purposes, reviews trends
5. **Goal Achievement**: Celebrates hitting targets through achievement system

### Secondary Persona: Miguel (Multi-Employer Worker)
- **Age**: 22
- **Experience**: Works at 2 restaurants + delivery
- **Goals**: Maximize earnings, compare employer performance
- **Pain Points**: Managing multiple job schedules, comparing earning potential

---

## Feature Requirements

### 1. Authentication & User Management

#### 1.1 User Registration/Login
- **Email/Password Authentication** via Supabase Auth
- **Password Reset** functionality
- **Email Verification** for account security
- **Account Deletion** with complete data removal

#### 1.2 Profile Management
- **Personal Information**: Name, email, preferred language
- **Work Settings**: Default hourly rate, week start day
- **Employer Management**: Add/edit multiple employers
- **Preferences**: Notification settings, display preferences

### 2. Core Income Tracking

#### 2.1 Shift Entry
- **Basic Information**:
  - Date and time (start/end or total hours)
  - Employer selection (if multiple employers enabled)
  - Shift type/position (server, bartender, etc.)

- **Financial Data**:
  - Total sales served
  - Tips received (cash + credit card)
  - Hourly wage earned
  - Tip-out amounts (kitchen, bar, host, etc.)
  - Other income (bonuses, overtime, etc.)

- **Quick Entry Mode**: Fast input for basic tip/hour tracking
- **Detailed Entry Mode**: Complete shift breakdown with all fields
- **Bulk Entry**: Add multiple shifts at once

#### 2.2 Data Validation & Smart Defaults
- **Automatic Calculations**: Total income, tip percentage, hourly effective rate
- **Input Validation**: Reasonable ranges, required fields, format checking
- **Smart Suggestions**: Pre-fill common values, suggest based on historical data
- **Edit History**: Track changes to entries with timestamps

### 3. Dashboard & Analytics

#### 3.1 Time Period Views
- **Today**: Current day performance and targets
- **Week**: Weekly summary with daily breakdown
- **Month**: Monthly performance (calendar month vs. 4-week periods)
- **Year**: Annual tracking and trends

#### 3.2 Key Metrics Display
- **Total Revenue**: Wages + Tips + Other - Tip-out
- **Breakdown by Category**:
  - Base salary/wages (hours × hourly rate)
  - Tips (with percentage of sales)
  - Other income
  - Tip-out amounts (negative)
- **Performance Metrics**:
  - Average tip percentage
  - Effective hourly rate (total revenue / hours)
  - Hours worked
  - Total sales served

#### 3.3 Visual Data Representation
- **Liquid Glass Card Design**: Modern, translucent card-based layout
- **Progressive Disclosure**: Tap cards to view detailed breakdowns
- **Interactive Charts**: Trend lines, bar charts for period comparisons
- **Color-Coded Performance**: Visual indicators for target achievement

### 4. Goal Setting & Target Management

#### 4.1 Target Types
- **Tip Percentage Targets**: Daily/weekly/monthly tip percentage goals
- **Income Targets**: Total revenue goals by period
- **Sales Targets**: Total sales served goals
- **Hours Targets**: Worked hours goals for work-life balance

#### 4.2 Target Tracking
- **Progress Indicators**: Visual progress bars and percentages
- **Target vs. Actual**: Side-by-side comparison displays
- **Achievement Celebrations**: Notifications and badges when targets are met
- **Target Adjustments**: Easy modification of goals based on performance

### 5. Multi-Employer Support

#### 5.1 Employer Management
- **Employer Profiles**: Name, address, hourly rate, tip-out policies
- **Default Selection**: Set primary employer for quick entry
- **Per-Employer Analytics**: Compare performance across employers
- **Employer-Specific Settings**: Different hourly rates, tip-out percentages

#### 5.2 Employer Comparison
- **Side-by-Side Metrics**: Compare tip percentages, hourly rates, total income
- **Time Period Analysis**: Performance trends by employer
- **ROI Analysis**: Best earning opportunities and shifts

### 6. Calendar & Scheduling

#### 6.1 Calendar View
- **Monthly Calendar**: Visual overview of worked shifts
- **Shift Indicators**: Color-coded by employer or earnings level
- **Quick Add**: Tap date to add shift entry
- **Shift Density**: Visual representation of work intensity

#### 6.2 Schedule Integration
- **Week View**: Detailed weekly schedule with earnings
- **Custom Week Start**: Sunday or Monday week start options
- **Shift Patterns**: Identify most profitable days/times
- **Time Off Tracking**: Mark vacation days and breaks

### 7. Achievement & Gamification System

#### 7.1 Achievement Types
- **Tip Master**: Achieve 20%+ tip average
- **Consistency King**: Enter data for 7 consecutive days
- **Target Crusher**: Exceed tip target by 50%
- **High Earner**: Earn $30+/hour average
- **Streak Achievements**: Various consecutive goal achievements

#### 7.2 Achievement Features
- **Visual Celebrations**: Full-screen achievement unlocks with confetti
- **Progress Tracking**: Progress bars for locked achievements
- **Badge Collection**: Visual badge display in profile
- **Social Sharing**: Optional sharing of achievements
- **Localized Achievements**: Titles and descriptions in user's language

### 8. Alert & Notification System

#### 8.1 Alert Types
- **Missing Shift Data**: Reminder when yesterday's shift isn't logged
- **Target Achievement**: Celebration when goals are met
- **Personal Bests**: New record notifications
- **Data Reminders**: Gentle prompts to maintain tracking habits

#### 8.2 Alert Management
- **Notification Bell**: In-app notification center
- **Alert History**: List of all past alerts with timestamps
- **Customizable Settings**: Enable/disable specific alert types
- **Smart Timing**: Appropriate timing for different alert types

### 9. Data Export & Reporting

#### 9.1 Export Formats
- **CSV Export**: Spreadsheet-compatible format for accounting
- **PDF Reports**: Professional formatted reports
- **Email Integration**: Direct email of reports
- **Tax-Ready Formats**: Organized for tax preparation

#### 9.2 Report Types
- **Income Summary**: Total earnings by period
- **Detailed Transaction Log**: Every shift with full breakdown
- **Tax Summary**: Annual totals with tax-relevant categorization
- **Employer Comparison**: Performance analysis across employers

### 10. Calculator & Tools

#### 10.1 Tip Calculator
- **Bill Amount Input**: Enter total bill or individual bills
- **Tip Percentage Calculator**: Calculate tips at various percentages
- **Split Calculator**: Divide bills among multiple people
- **Tip-out Calculator**: Calculate tip sharing amounts
- **Custom Percentage**: Non-standard tip percentages

#### 10.2 Financial Tools
- **Effective Hourly Rate**: Calculate true hourly earnings including tips
- **Tax Estimator**: Estimate tax obligations based on income
- **Goal Calculator**: Determine required performance to meet targets
- **Savings Projector**: Project savings based on current earning trends

### 11. Security & Privacy

#### 11.1 App Security
- **App Lock Options**:
  - PIN Code (4-digit)
  - Face ID / Touch ID (iOS) / Fingerprint (Android)
  - None (user choice)
- **Auto-lock**: Lock app when backgrounded
- **Security Settings**: Easy enable/disable/change security methods

#### 11.2 Data Privacy
- **Local Encryption**: All sensitive data encrypted at rest
- **Secure Transmission**: All API calls over HTTPS
- **User Data Control**: Complete data export and deletion
- **No Data Selling**: Clear privacy policy with no third-party data sharing

### 12. Settings & Customization

#### 12.1 App Settings
- **Language Selection**: English, French, Spanish
- **Currency Display**: Local currency formatting
- **Date/Time Format**: Regional preferences
- **Theme Options**: System, Light, Dark (future)

#### 12.2 Notification Settings
- **Alert Preferences**: Granular control over alert types
- **Timing Settings**: When to receive different notifications
- **Sound Settings**: Custom sounds for different alert types
- **Do Not Disturb**: Quiet hours setting

#### 12.3 Data Settings
- **Backup Options**: Automatic cloud backup settings
- **Export Settings**: Default export formats and recipients
- **Data Retention**: Control over historical data storage
- **Account Management**: Change password, delete account

---

## Technical Architecture

### Backend Infrastructure
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth with email/password
- **API**: RESTful API through Supabase
- **File Storage**: Supabase Storage for exports
- **Real-time**: Supabase Real-time for live updates

### Frontend Architecture
- **iOS**: Swift/SwiftUI with MVVM architecture
- **Android**: Kotlin/Jetpack Compose with MVVM architecture (future)
- **State Management**: ObservableObject pattern (iOS), ViewModel pattern (Android)
- **Local Storage**: UserDefaults (iOS), SharedPreferences (Android)
- **Networking**: URLSession (iOS), Retrofit (Android)

### Data Flow
1. **User Input** → Local validation → API call
2. **Server Processing** → Database update → Response
3. **Local Update** → UI refresh → State synchronization
4. **Offline Support** → Local storage → Sync when online

---

## User Interface Specifications

### Design System
- **Visual Style**: Liquid Glass design with translucent cards
- **Color Palette**: Adaptive colors supporting dark/light mode
- **Typography**: System fonts with consistent hierarchy
- **Iconography**: SF Symbols (iOS), Material Icons (Android)
- **Spacing**: 4pt grid system for consistent spacing
- **Components**: Reusable UI components across all screens

### Screen Specifications

#### 1. Authentication Flow
- **Welcome Screen**: App introduction with language selection
- **Sign In Screen**: Email/password with "Forgot Password" link
- **Sign Up Screen**: Registration form with email verification
- **Onboarding**: Multi-step setup for preferences and initial settings

#### 2. Main Dashboard
- **Layout**: Segmented period selector at top, stats cards below
- **Interaction**: Tap cards to view detailed breakdowns
- **Navigation**: Tab bar at bottom (Dashboard, Calendar, Calculator, Settings)
- **Responsive**: Adapt layout for iPad with sidebar navigation

#### 3. Shift Entry Screens
- **Quick Entry**: Simplified form for basic tip/hour logging
- **Detailed Entry**: Complete shift breakdown with all fields
- **Edit Mode**: Modify existing shift entries
- **Bulk Entry**: Add multiple shifts efficiently

#### 4. Settings Screens
- **Modular Design**: Organized sections (Profile, Targets, Security, Support, Account)
- **Progressive Disclosure**: Expandable sections to reduce cognitive load
- **Form Design**: Clear labels, proper input types, validation feedback
- **Responsive Layout**: Adapt to different screen sizes

### Responsive Design
- **iPhone**: Single column layout with tab navigation
- **iPad**: Two-column layout with sidebar navigation
- **Landscape**: Optimize layout for horizontal orientation
- **Accessibility**: VoiceOver support, Dynamic Type, high contrast

---

## Data Models

### User Profile
```json
{
  "id": "uuid",
  "email": "string",
  "created_at": "timestamp",
  "default_hourly_rate": "decimal",
  "tip_target_percentage": "decimal",
  "week_start": "integer", // 0=Sunday, 1=Monday
  "use_multiple_employers": "boolean",
  "default_employer_id": "uuid",
  "language": "string", // en, fr, es
  "target_sales_daily": "decimal",
  "target_sales_weekly": "decimal",
  "target_sales_monthly": "decimal",
  "target_hours_daily": "decimal",
  "target_hours_weekly": "decimal",
  "target_hours_monthly": "decimal"
}
```

### Employer
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "name": "string",
  "address": "string",
  "hourly_rate": "decimal",
  "default_tip_out_percentage": "decimal",
  "color": "string", // hex color for calendar
  "active": "boolean",
  "created_at": "timestamp"
}
```

### Shift Entry
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "employer_id": "uuid",
  "shift_date": "date",
  "start_time": "time",
  "end_time": "time",
  "hours": "decimal",
  "sales": "decimal",
  "tips": "decimal",
  "hourly_rate": "decimal",
  "cash_out": "decimal", // tip-out amount
  "other": "decimal", // other income
  "notes": "string",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Achievement
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "type": "string", // tip_master, consistency_king, etc.
  "unlocked_at": "timestamp",
  "data": "json" // additional achievement-specific data
}
```

### Alert
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "type": "string", // missing_shift, target_achieved, etc.
  "title": "string",
  "message": "string",
  "data": "json", // alert-specific data
  "read": "boolean",
  "created_at": "timestamp"
}
```

---

## Security & Privacy

### Data Protection
- **Encryption at Rest**: All sensitive data encrypted using AES-256
- **Encryption in Transit**: TLS 1.3 for all API communications
- **Database Security**: Row-level security policies in Supabase
- **Authentication**: JWT tokens with secure refresh mechanism

### Privacy Compliance
- **GDPR Compliance**: Right to access, rectify, and delete personal data
- **CCPA Compliance**: California consumer privacy rights
- **Data Minimization**: Collect only necessary data for functionality
- **Transparent Policy**: Clear privacy policy in multiple languages

### App Security Features
- **Biometric Authentication**: Face ID, Touch ID, Fingerprint support
- **PIN Protection**: 4-digit PIN with lockout after failed attempts
- **Auto-lock**: Configurable app locking when backgrounded
- **Screenshot Protection**: Optional screenshot blocking for sensitive screens

---

## Monetization

### Subscription Model
- **Freemium**: Basic tip tracking free with limited features
- **Premium**: $4.99/month or $49.99/year
  - Unlimited shift entries
  - Advanced analytics and reporting
  - Data export capabilities
  - Achievement system
  - Multi-employer support
  - Priority customer support

### Premium Features
- **Advanced Analytics**: Trend analysis, performance insights
- **Export Capabilities**: PDF reports, CSV exports
- **Multi-Employer**: Support for multiple employers
- **Achievement System**: Gamification and progress tracking
- **Priority Support**: Email support with faster response times

### Trial Period
- **7-Day Free Trial**: Full access to premium features
- **No Credit Card**: Required for trial signup
- **Easy Cancellation**: Cancel anytime through device settings

---

## Internationalization

### Supported Languages
1. **English**: Primary language, US/Canada markets
2. **French**: Canada (Quebec) and France markets
3. **Spanish**: US Hispanic market and Latin America

### Localization Features
- **UI Text**: All interface text translated
- **Currency**: Local currency symbols and formatting
- **Date/Time**: Regional date and time formats
- **Number Formats**: Decimal separators and thousands separators
- **Achievement Names**: Localized achievement titles and descriptions

### Cultural Adaptations
- **Tipping Culture**: Adjust default percentages by region
- **Work Week**: Flexible week start day (Sunday vs Monday)
- **Holiday Recognition**: Regional holidays in calendar views
- **Support Channels**: Local support contact methods

---

## Platform-Specific Requirements

### iOS Implementation
- **SwiftUI Framework**: Modern declarative UI framework
- **iOS 16+ Support**: Leverage latest iOS features
- **Liquid Glass Design**: Native iOS visual effects
- **SF Symbols**: Consistent iconography
- **Shortcuts Integration**: Siri shortcuts for quick entry
- **Widget Support**: Home screen widgets for quick stats

### Android Implementation (Future)
- **Jetpack Compose**: Modern Android UI framework
- **Android 8+ Support**: Broad device compatibility
- **Material Design 3**: Google's latest design system
- **Adaptive Icons**: Support various launcher icon shapes
- **Shortcuts**: Android app shortcuts for quick actions
- **Widgets**: Home screen widgets matching iOS functionality

### Cross-Platform Consistency
- **Identical Features**: Same functionality on both platforms
- **Visual Parity**: Consistent layout and information hierarchy
- **Interaction Patterns**: Platform-native interaction patterns
- **Performance**: Equivalent performance and responsiveness
- **Data Sync**: Seamless data synchronization between platforms

---

## Success Metrics

### User Engagement
- **Daily Active Users (DAU)**: Target 70% of monthly users
- **Monthly Active Users (MAU)**: Target 10,000 users in Year 1
- **Session Length**: Average 5-7 minutes per session
- **Retention Rate**:
  - Day 1: 80%
  - Day 7: 50%
  - Day 30: 25%

### Feature Adoption
- **Shift Entry Rate**: 80% of users log shifts within first week
- **Goal Setting**: 60% of users set financial targets
- **Multi-Employer**: 30% of users add multiple employers
- **Export Usage**: 40% of premium users export data monthly

### Business Metrics
- **Conversion Rate**: 15% free-to-premium conversion
- **Churn Rate**: <5% monthly churn for premium users
- **Customer Lifetime Value**: $60 average per premium user
- **App Store Rating**: Maintain 4.5+ stars

### Quality Metrics
- **Crash Rate**: <0.1% of sessions
- **Load Times**: <2 seconds for main screens
- **Support Tickets**: <2% of users contact support monthly
- **Bug Reports**: Address critical bugs within 24 hours

---

## Development Roadmap

### Phase 1: Core MVP (Completed)
- ✅ User authentication and profile management
- ✅ Basic shift entry and income tracking
- ✅ Dashboard with key metrics
- ✅ Goal setting and target management
- ✅ iOS app with Liquid Glass design

### Phase 2: Enhanced Features (Current)
- ✅ Achievement system with gamification
- ✅ Alert and notification system
- ✅ Multi-employer support
- ✅ Calendar integration
- ✅ Data export capabilities

### Phase 3: Platform Expansion (Future)
- 🔄 Android app development
- 🔄 Cross-platform data synchronization
- 🔄 Advanced analytics and reporting
- 🔄 Widget support (iOS/Android)
- 🔄 Siri Shortcuts integration

### Phase 4: Advanced Features (Future)
- 🔄 Team features (restaurant managers)
- 🔄 Integration with POS systems
- 🔄 Tax preparation assistance
- 🔄 Financial planning tools
- 🔄 Social features and community

---

## Conclusion

ProTip365 represents a comprehensive solution for service industry workers to manage their variable income effectively. By providing detailed tracking, goal setting, and analytics in a beautiful, user-friendly interface, the app addresses real pain points in the market while building a sustainable subscription business.

The focus on cross-platform consistency ensures that the Android version will provide an identical experience to iOS users, maximizing user satisfaction and market penetration. The robust technical architecture, comprehensive feature set, and clear monetization strategy position ProTip365 for long-term success in the fintech space.

---

**Document Version**: 1.0
**Last Updated**: September 14, 2025
**Next Review**: December 2025