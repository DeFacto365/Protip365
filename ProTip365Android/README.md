# ProTip365 Android App

A comprehensive tip tracking and shift management application for service industry professionals, built with Jetpack Compose and modern Android development practices.

## 🚀 Features

### Core Functionality
- **Shift & Entry Management**: Track work shifts and quick tip entries
- **Multi-Employer Support**: Manage multiple employers with conditional navigation
- **Real-time Analytics**: Live dashboard with earnings statistics and trends
- **Calendar Integration**: Visual calendar view with shift scheduling
- **Tip Calculator**: Built-in calculator for tip calculations
- **Data Export**: Export data to CSV format

### Security & Authentication
- **Biometric Authentication**: Fingerprint and face unlock support
- **PIN Protection**: Customizable PIN-based security
- **Auto-lock**: Configurable auto-lock timers
- **Secure Data Storage**: Encrypted local storage with Android Keystore

### Subscription Management
- **Free Trial**: Limited features for new users
- **Part-Time Pro**: $2.99/month for 3 shifts/entries per week
- **Full Access**: $4.99/month for unlimited usage
- **Google Play Billing**: Integrated subscription management

### Localization
- **Multi-language Support**: English, French, and Spanish
- **Dynamic Language Switching**: Change language without app restart
- **Localized Content**: All UI text and content translated

## 🏗️ Architecture

### Tech Stack
- **UI Framework**: Jetpack Compose with Material 3
- **Architecture**: MVVM with Clean Architecture
- **Dependency Injection**: Hilt
- **Database**: Supabase (PostgreSQL) with real-time subscriptions
- **Authentication**: Supabase Auth with biometric support
- **State Management**: StateFlow and Compose State
- **Navigation**: Navigation Compose
- **Testing**: JUnit 4, MockK, Coroutines Test

### Project Structure
```
app/src/main/java/com/protip365/app/
├── data/
│   ├── models/           # Data models and DTOs
│   ├── remote/           # Supabase client and API interfaces
│   └── repository/       # Repository implementations
├── domain/
│   ├── repository/       # Repository interfaces
│   └── usecase/          # Business logic use cases
├── presentation/
│   ├── auth/            # Authentication screens and ViewModels
│   ├── calendar/        # Calendar functionality
│   ├── dashboard/       # Main dashboard
│   ├── settings/        # Settings and configuration
│   ├── shifts/          # Shift and entry management
│   ├── employers/       # Multi-employer support
│   ├── calculator/      # Tip calculator
│   ├── components/      # Reusable UI components
│   └── navigation/      # Navigation setup
└── di/                  # Dependency injection modules
```

## 🛠️ Development Setup

### Prerequisites
- Android Studio Hedgehog or later
- JDK 17 or later
- Android SDK 34
- Kotlin 1.9.0 or later

### Environment Configuration
1. Clone the repository
2. Create `local.properties` with your Android SDK path:
   ```
   sdk.dir=/path/to/android/sdk
   ```
3. Create `app/src/main/res/values/secrets.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <string name="supabase_url">YOUR_SUPABASE_URL</string>
       <string name="supabase_anon_key">YOUR_SUPABASE_ANON_KEY</string>
   </resources>
   ```

### Build Configuration
The app supports multiple build variants:
- **Debug**: Development builds with logging
- **Release**: Production builds with ProGuard optimization

### Dependencies
Key dependencies include:
- Jetpack Compose BOM
- Supabase Android SDK
- Hilt for dependency injection
- Navigation Compose
- Biometric authentication
- Google Play Billing Library

## 🧪 Testing

### Running Tests
```bash
# Unit tests
./gradlew test

# Instrumented tests
./gradlew connectedAndroidTest

# All tests
./gradlew check
```

### Test Coverage
- ViewModel unit tests with MockK
- Repository integration tests
- UI component tests with Compose Testing
- End-to-end user flow tests

## 🚀 Building for Production

### Release Build
```bash
./gradlew assembleRelease
```

### App Bundle (Recommended for Play Store)
```bash
./gradlew bundleRelease
```

### Signing Configuration
Configure signing in `app/build.gradle.kts`:
```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("release-key.jks")
            storePassword = "your-store-password"
            keyAlias = "your-key-alias"
            keyPassword = "your-key-password"
        }
    }
    
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## 📱 App Store Preparation

### Required Assets
- App icon (multiple densities)
- Feature graphics
- Screenshots (phone and tablet)
- Privacy policy
- Terms of service

### Metadata
- App title: "ProTip365 - Tip Tracker"
- Short description: "Track tips, manage shifts, and analyze earnings for service industry professionals"
- Full description: See `Docs/APP_STORE_DESCRIPTION.md`

### Permissions
The app requests minimal permissions:
- Internet access (for Supabase)
- Biometric authentication
- Notification permissions (for alerts)

## 🔧 Configuration

### Supabase Setup
1. Create a Supabase project
2. Configure authentication providers
3. Set up database tables (see `create_protip365_tables.sql`)
4. Configure RLS policies
5. Set up real-time subscriptions

### Google Play Console
1. Create app listing
2. Upload app bundle
3. Configure subscription products
4. Set up release tracks
5. Configure app signing

## 🐛 Troubleshooting

### Common Issues
- **Build failures**: Ensure all dependencies are properly configured
- **Authentication issues**: Verify Supabase configuration
- **Biometric not working**: Check device compatibility and permissions
- **Real-time sync issues**: Verify network connectivity and Supabase setup

### Debug Mode
Enable debug logging by setting `BuildConfig.DEBUG` to true in debug builds.

## 📄 License

This project is proprietary software. All rights reserved.

## 🤝 Contributing

This is a private project. For issues or feature requests, please contact the development team.

## 📞 Support

For technical support or questions:
- Email: support@protip365.app
- Documentation: [ProTip365 Docs](https://docs.protip365.app)



