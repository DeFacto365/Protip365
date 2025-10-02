# ProTip365 Version Synchronization Guide

## 🔄 Version Management Policy

**IMPORTANT**: The Android app version must ALWAYS match the iOS/Xcode version to maintain consistency across platforms.

## 📍 Version Locations

### iOS (Primary/Master)
**File**: `ProTip365/Info.plist`
```xml
<key>CFBundleShortVersionString</key>
<string>1.1.21</string>  <!-- Version Name -->
<key>CFBundleVersion</key>
<string>21</string>       <!-- Build Number -->
```

### Android (Must Match iOS)
**File**: `ProTip365Android/app/build.gradle.kts`
```kotlin
defaultConfig {
    versionCode = 21        // Must match iOS CFBundleVersion
    versionName = "1.1.21"  // Must match iOS CFBundleShortVersionString
}
```

## 📋 Version Update Checklist

When releasing a new version:

1. **Update iOS FIRST** (Master version)
   - Open Xcode
   - Update version in project settings or Info.plist
   - Note both version string and build number

2. **Update Android to Match**
   - Open `app/build.gradle.kts`
   - Set `versionCode` = iOS build number
   - Set `versionName` = iOS version string

3. **Verify Version Display**
   - Run Android app
   - Go to Settings → About
   - Confirm version shows correctly: "1.1.21 (Build 21)"

## 🎯 Current Version Status

| Platform | Version | Build | Last Updated |
|----------|---------|-------|--------------|
| iOS      | 1.1.21  | 21    | Master       |
| Android  | 1.1.21  | 21    | Jan 2025     |

## 🔧 Automated Version Display

The Android app automatically displays the version from BuildConfig:
- Location: Settings → About → Version
- Format: `${BuildConfig.VERSION_NAME} (Build ${BuildConfig.VERSION_CODE})`
- Example: "1.1.21 (Build 21)"

## ⚠️ Important Notes

1. **Never update Android version independently** - Always follow iOS
2. **iOS is the source of truth** for all version numbers
3. **Build numbers must increment** with each release
4. **Version format**: Major.Minor.Patch (e.g., 1.1.21)

## 🚀 Release Process

1. iOS team updates version in Xcode
2. iOS team communicates new version via:
   - Slack/Teams message
   - Git commit message
   - Pull request description
3. Android team updates to match
4. Both apps release with same version

## 💡 Tips

- Use semantic versioning (Major.Minor.Patch)
- Build numbers should always increment (never reuse)
- Consider using a shared version file or CI/CD automation
- Test version display after each update

---

*Last synchronized: January 2025 - Version 1.1.21 (Build 21)*