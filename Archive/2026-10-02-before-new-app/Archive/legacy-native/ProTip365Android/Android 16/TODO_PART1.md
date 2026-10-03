# Android 16 UI/UX Implementation To-Do List

**Last Updated:** [Update this date when modifying this file]

This comprehensive TODO list includes all tasks for upgrading ProTip365 to Android 16 compliance, including detailed implementation guidance for critical features.

**Note:** This file contains Phases 0-6 (Implementation phases). See `TODO_PART2.md` for Phases 7-11 (Polish and testing phases).

**📋 File Structure:**
- `TODO.md` (this file) - Phases 0-6: Implementation phases
- `TODO_PART2.md` - Phases 7-11: Polish and testing phases

---

## Phase 0: Critical Missing Features (DO FIRST!)

### 0.1 Predictive Back Gesture (CRITICAL)

**Issue:** The app currently uses default back navigation without predictive back gesture support. **Android 16 requires predictive back navigation** for apps targeting API 36+.

**Current State:**
- ❌ No predictive back gesture implementation found
- ❌ Navigation uses default `popBackStack()` without predictive back support
- ❌ No `OnBackPressedDispatcher` integration for Compose

**Android 16 Requirements:**
- **Mandatory:** All apps targeting Android 16 must support predictive back gesture
- **3-Button Navigation:** Predictive back now works with 3-button navigation in Android 16
- **User Experience:** Users see a preview of where they'll navigate before confirming

**Implementation Steps:**

- [ ] **Update Navigation Dependencies**
  - File: `app/build.gradle.kts`
  - Action: Ensure `androidx.activity:activity-compose` is latest version (1.9.3+)
  - Code: `implementation("androidx.activity:activity-compose:1.9.3")`

- [ ] **Add Predictive Back Support to MainActivity**
  - File: `app/src/main/java/com/protip365/app/MainActivity.kt`
  - Action: Predictive back is automatically handled by Compose Navigation
  - Note: Ensure all screens use proper back handling
  - Priority: 🔴 CRITICAL - Must fix before Android 16 release
  - Estimated: 1 day

- [ ] **Update all screens for predictive back**
  - Files: All screen composables
  - Action: Ensure proper back handling with `BackHandler` where needed
  - Example for custom back behavior:
    ```kotlin
    @Composable
    fun AddEditEntryScreen(navController: NavController, viewModel: AddEditEntryViewModel) {
        val hasUnsavedChanges by viewModel.hasUnsavedChanges.collectAsState()
        
        BackHandler(enabled = hasUnsavedChanges) {
            // Show confirmation dialog before navigating back
            viewModel.showDiscardDialog()
        }
        // Screen content
    }
    ```
  - Test: Verify preview animations work correctly
  - Estimated: 2-3 days

**Files to Update:**
- `app/src/main/java/com/protip365/app/MainActivity.kt`
- `app/src/main/java/com/protip365/app/presentation/navigation/AppNavigation.kt`
- All screen composables (Dashboard, Calendar, Settings, etc.)
- `app/src/main/java/com/protip365/app/presentation/entries/AddEditEntryScreen.kt`
- `app/src/main/java/com/protip365/app/presentation/main/MainScreen.kt`

**Testing:**
- [ ] Test predictive back gesture on Android 16 devices
- [ ] Test with 3-button navigation enabled
- [ ] Test with gesture navigation enabled
- [ ] Verify custom back handlers work correctly

---

### 0.2 Window Insets Handling (CRITICAL)

**Issue:** The app enables edge-to-edge display (`enableEdgeToEdge()`) but **does not handle WindowInsets** properly. This causes content to be hidden behind system bars.

**Current State:**
- ✅ `enableEdgeToEdge()` called in MainActivity
- ❌ No WindowInsets handling found in composables
- ❌ Content likely hidden behind status bar/navigation bar
- ❌ No proper padding for system bars

**Android 16 Requirements:**
- **Mandatory:** Proper WindowInsets handling for edge-to-edge display
- **Best Practice:** Use `Modifier.windowInsetsPadding()` for system bars
- **User Experience:** Content should not be hidden behind system UI

**Implementation Steps:**

- [ ] **Add WindowInsets imports**
  - Files: All screen composables
  - Action: Add imports:
    ```kotlin
    import androidx.compose.foundation.layout.WindowInsets
    import androidx.compose.foundation.layout.WindowInsetsSides
    import androidx.compose.foundation.layout.only
    import androidx.compose.foundation.layout.systemBars
    import androidx.compose.foundation.layout.windowInsetsPadding
    ```
  - Note: WindowInsets support is already included in Compose BOM
  - Estimated: 0.5 days

- [ ] **Update Scaffold components**
  - Files: All screen composables with Scaffold
  - Action: Add `Modifier.windowInsetsPadding()` for system bars
  - Example:
    ```kotlin
    Scaffold(
        modifier = Modifier.windowInsetsPadding(
            WindowInsets.systemBars.only(WindowInsetsSides.Horizontal)
        )
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical))
        ) {
            // Content
        }
    }
    ```
  - Files to update:
    - `DashboardScreen.kt`
    - `CalendarScreen.kt`
    - `SettingsScreen.kt`
    - `MainScreen.kt`
    - `AddEditEntryScreen.kt`
    - All other screens
  - Priority: 🔴 CRITICAL - Content visibility issue
  - Estimated: 2-3 days

- [ ] **Update TopAppBar for status bar**
  - Files: All screens with TopAppBar
  - Action: Add status bar insets padding
  - Example:
    ```kotlin
    TopAppBar(
        modifier = Modifier.windowInsetsPadding(
            WindowInsets.statusBars.only(WindowInsetsSides.Top)
        )
    )
    ```
  - Estimated: 1 day

- [ ] **Update BottomNavigation for navigation bar**
  - File: `app/src/main/java/com/protip365/app/presentation/navigation/BottomNavigation.kt`
  - Action: Add navigation bar insets padding
  - Example:
    ```kotlin
    NavigationBar(
        modifier = modifier.windowInsetsPadding(
            WindowInsets.navigationBars.only(WindowInsetsSides.Bottom)
        )
    )
    ```
  - Estimated: 1 day

- [ ] **Test window insets on various devices**
  - Action: Test on devices with notches, different navigation bar styles
  - Verify: No content hidden behind system UI
  - Estimated: 1 day

**Files to Update:**
- `app/src/main/java/com/protip365/app/MainActivity.kt`
- `app/src/main/java/com/protip365/app/presentation/dashboard/DashboardScreen.kt`
- `app/src/main/java/com/protip365/app/presentation/calendar/CalendarScreen.kt`
- `app/src/main/java/com/protip365/app/presentation/settings/SettingsScreen.kt`
- `app/src/main/java/com/protip365/app/presentation/main/MainScreen.kt`
- `app/src/main/java/com/protip365/app/presentation/navigation/BottomNavigation.kt`
- All other screen composables

**Testing:**
- [ ] Verify content is not hidden behind status bar
- [ ] Verify content is not hidden behind navigation bar
- [ ] Test on devices with different notch configurations
- [ ] Test on devices with different navigation bar styles

---

### 0.3 Adaptive Refresh Rate Support (IMPORTANT)

**Issue:** App does not optimize for Adaptive Refresh Rate (ARR), which can improve battery life and performance on Android 16 devices.

**Android 16 Feature:**
- **Adaptive Refresh Rate:** Display refresh rate adapts to content frame rate
- **Battery Savings:** Lower refresh rates when content is static
- **Performance:** Higher refresh rates for animations

**Implementation Steps:**

- [ ] **Add ARR detection utility**
  - File: Create new utility file or add to existing
  - Action: Implement ARR support check:
    ```kotlin
    fun isAdaptiveRefreshRateSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S // Android 12+
    }
    ```
  - Estimated: 0.5 days

- [ ] **Optimize animations for ARR**
  - Files: Animation components, screen transitions
  - Action: Use appropriate animation durations:
    ```kotlin
    val animationDuration = if (isAdaptiveRefreshRateSupported()) {
        300.milliseconds // Can be shorter with ARR
    } else {
        400.milliseconds
    }
    ```
  - Priority: 🟡 Important - Better battery life
  - Estimated: 1-2 days

- [ ] **Reduce unnecessary animations**
  - Files: All animation code
  - Action: Only animate when necessary, use `snapTo()` for instant changes
  - Estimated: 1 day

**Files to Update:**
- Animation components
- Screen transition code
- All `AnimatedVisibility` usages

**Testing:**
- [ ] Test on ARR-capable devices
- [ ] Verify smooth animations
- [ ] Check battery usage improvements

---

### 0.4 Automatic Themed App Icons (IMPORTANT)

**Issue:** App icons do not support automatic theming based on system wallpaper. Android 16 enhances this feature.

**Current State:**
- ✅ Icons exist: `ic_launcher.xml`, `ic_launcher_foreground.xml`
- ❌ No themed icon support
- ❌ Icons don't adapt to system theme

**Implementation Steps:**

- [ ] **Create monochrome icon**
  - File: `app/src/main/res/drawable/ic_launcher_monochrome.xml` (create new)
  - Action: Design monochrome version of app icon
  - Example:
    ```xml
    <vector xmlns:android="http://schemas.android.com/apk/res/android"
        android:width="108dp"
        android:height="108dp"
        android:viewportWidth="108"
        android:viewportHeight="108">
        <!-- Monochrome version of icon -->
    </vector>
    ```
  - Priority: 🟡 Important - Better user experience
  - Estimated: 1 day

- [ ] **Update adaptive icon configuration**
  - File: `app/src/main/res/mipmap-anydpi-v31/ic_launcher.xml` (update if exists)
  - Action: Add monochrome drawable reference:
    ```xml
    <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
        <background android:drawable="@drawable/ic_launcher_background"/>
        <foreground android:drawable="@drawable/ic_launcher_foreground"/>
        <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
    </adaptive-icon>
    ```
  - Estimated: 0.5 days

**Files to Update:**
- `app/src/main/res/drawable/ic_launcher_monochrome.xml` (create new)
- `app/src/main/res/mipmap-anydpi-v31/ic_launcher.xml` (update if exists)
- Icon design files

**Testing:**
- [ ] Test icon appearance with different wallpapers
- [ ] Verify monochrome icons work correctly
- [ ] Test on Android 12+ devices

---

### 0.5 System-Triggered Profiling (IMPORTANT)

**Issue:** App does not leverage Android 16's system-triggered profiling for performance optimization.

**Android 16 Feature:**
- **System-Triggered Profiling:** Automatic profiling during critical events
- **Performance Insights:** Profiling data during cold starts, ANRs, etc.
- **Optimization:** Use insights to improve app performance

**Implementation Steps:**

- [ ] **Create PerformanceProfiler utility**
  - File: `app/src/main/java/com/protip365/app/utils/PerformanceProfiler.kt` (create new)
  - Action: Implement system-triggered profiling integration:
    ```kotlin
    import android.app.ProfilingManager
    import android.content.Context
    
    class AppProfiler(private val context: Context) {
        private val profilingManager: ProfilingManager? = if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
        ) {
            context.getSystemService(Context.PROFILING_SERVICE) as? ProfilingManager
        } else {
            null
        }
        
        fun registerProfilingInterest() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                profilingManager?.registerProfilingInterest(
                    ProfilingManager.PROFILE_APP_STARTUP or
                    ProfilingManager.PROFILE_ANR
                )
            }
        }
    }
    ```
  - Priority: 🟡 Important - Performance optimization
  - Estimated: 1 day

- [ ] **Initialize profiling in Application class**
  - File: `app/src/main/java/com/protip365/app/ProTip365Application.kt`
  - Action: Register profiling interest for app startup and ANRs:
    ```kotlin
    class ProTip365Application : Application() {
        private lateinit var appProfiler: AppProfiler
        
        override fun onCreate() {
            super.onCreate()
            appProfiler = AppProfiler(this)
            appProfiler.registerProfilingInterest()
        }
    }
    ```
  - Estimated: 0.5 days

**Files to Create/Update:**
- `app/src/main/java/com/protip365/app/utils/PerformanceProfiler.kt` (create new)
- `app/src/main/java/com/protip365/app/ProTip365Application.kt` (update)

---

### 0.6 App Shortcuts (NICE TO HAVE)

**Issue:** App shortcuts are mentioned in documentation but not implemented.

**Current State:**
- ❌ No app shortcuts implementation
- 📝 Mentioned in `docs_archive/IMPLEMENTATION_TODO.md`

**Implementation Steps:**

- [ ] **Create shortcuts.xml**
  - File: `app/src/main/res/xml/shortcuts.xml` (create new)
  - Action: Define app shortcuts (Add Entry, View Dashboard, etc.)
  - Example:
    ```xml
    <shortcuts xmlns:android="http://schemas.android.com/apk/res/android">
        <shortcut
            android:shortcutId="add_entry"
            android:shortcutShortLabel="@string/shortcut_add_entry"
            android:shortcutLongLabel="@string/shortcut_add_entry_long"
            android:icon="@drawable/ic_add">
            <intent
                android:action="android.intent.action.VIEW"
                android:targetPackage="com.protip365.monthly"
                android:targetClass="com.protip365.app.presentation.MainActivity"
                android:data="protip365://add_entry" />
        </shortcut>
    </shortcuts>
    ```
  - Priority: 🟢 Nice to Have
  - Estimated: 1 day

- [ ] **Update AndroidManifest for shortcuts**
  - File: `app/src/main/AndroidManifest.xml`
  - Action: Add shortcuts meta-data to MainActivity:
    ```xml
    <activity android:name=".presentation.MainActivity">
        <meta-data
            android:name="android.app.shortcuts"
            android:resource="@xml/shortcuts" />
    </activity>
    ```
  - Estimated: 0.5 days

- [ ] **Handle shortcut intents in MainActivity**
  - File: `app/src/main/java/com/protip365/app/MainActivity.kt`
  - Action: Add intent handling for shortcuts
  - Estimated: 1 day

**Files to Create/Update:**
- `app/src/main/res/xml/shortcuts.xml` (create new)
- `app/src/main/AndroidManifest.xml` (update)
- `app/src/main/java/com/protip365/app/MainActivity.kt` (update)

---

### 0.7 Home Screen Widgets (NICE TO HAVE)

**Issue:** Widgets are mentioned in documentation but not implemented.

**Current State:**
- ❌ No widget implementation
- 📝 Mentioned in `ANDROID_COMPLETE_GUIDE.md`

**Implementation Steps:**

- [ ] **Create widget provider**
  - File: `app/src/main/java/com/protip365/app/presentation/widgets/DashboardWidgetProvider.kt` (create new)
  - Action: Implement AppWidgetProvider for dashboard stats
  - Priority: 🟢 Nice to Have
  - Estimated: 2 days

- [ ] **Create widget layout**
  - File: `app/src/main/res/layout/widget_dashboard.xml` (create new)
  - Action: Design widget layout
  - Estimated: 1 day

- [ ] **Create widget info XML**
  - File: `app/src/main/res/xml/widget_info.xml` (create new)
  - Action: Configure widget properties
  - Estimated: 0.5 days

- [ ] **Register widget in AndroidManifest**
  - File: `app/src/main/AndroidManifest.xml`
  - Action: Add widget receiver
  - Estimated: 0.5 days

**Files to Create:**
- `app/src/main/java/com/protip365/app/presentation/widgets/DashboardWidgetProvider.kt`
- `app/src/main/res/layout/widget_dashboard.xml`
- `app/src/main/res/xml/widget_info.xml`

---

## Phase 1: Foundation & Setup

### 1.1 SDK and Dependencies Update

- [ ] **Update targetSdk to 36** (Android 16)
  - File: `app/build.gradle.kts`
  - Action: Change `targetSdk = 35` to `targetSdk = 36`
  - Note: May need to wait for Android 16 SDK release

- [ ] **Update compileSdk to 36**
  - File: `app/build.gradle.kts`
  - Action: Change `compileSdk = 35` to `compileSdk = 36`

- [ ] **Update Compose BOM version**
  - File: `gradle/libs.versions.toml`
  - Action: Update `composeBom = "2024.12.01"` to latest Android 16 compatible version
  - Check: Latest Material 3 version compatibility

- [ ] **Update Material 3 library**
  - File: `app/build.gradle.kts`
  - Action: Ensure latest Material 3 version (check for Android 16 specific features)
  - Verify: `androidx.compose.material3:material3` is latest version

- [ ] **Update core Android libraries**
  - File: `gradle/libs.versions.toml`
  - Action: Update `coreKtx`, `activity`, `lifecycle` to latest versions
  - Check: Compatibility with Android 16 APIs

### 1.2 Theme System Enhancement

- [ ] **Enhance dynamic color implementation**
  - File: `app/src/main/java/com/protip365/app/presentation/theme/Theme.kt`
  - Action: Update `dynamicColorScheme()` to use latest Android 16 color extraction
  - Add: Support for tonal palettes
  - Add: Better color contrast ratios
  - Test: Verify colors adapt to system wallpaper changes

- [ ] **Update color scheme definitions**
  - File: `app/src/main/java/com/protip365/app/presentation/theme/Theme.kt`
  - Action: Review `DarkColorScheme` and `LightColorScheme`
  - Ensure: All color tokens follow Material 3 guidelines
  - Verify: Color contrast meets WCAG 2.1 AA standards

- [ ] **Add custom color spaces support**
  - File: `app/src/main/java/com/protip365/app/presentation/theme/Theme.kt`
  - Action: Implement tone mapping for better color accuracy
  - Note: Android 16 may introduce new color space features

### 1.3 Typography System

- [ ] **Review and update typography scale**
  - File: `app/src/main/java/com/protip365/app/presentation/theme/Type.kt`
  - Action: Ensure Material 3 Typography scale is used
  - Verify: All text styles follow Material 3 guidelines
  - Add: Support for dynamic type scaling (up to 200%)

- [ ] **Implement dynamic type support**
  - Files: All screen composables
  - Action: Test all Text components with large text sizes
  - Fix: Any UI breaking issues with large text
  - Verify: Text scales properly without clipping

---

## Phase 2: Notifications Enhancement

### 2.1 Live Updates Implementation

- [ ] **Research Android 16 Live Updates API**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Review Android 16 documentation for Live Updates
  - Identify: Required APIs and permissions

- [ ] **Implement Live Updates for shift reminders**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Add Live Update support for shift reminders
  - Feature: Show countdown timer on lock screen
  - Requirement: Android 16+ API check

- [ ] **Implement Live Updates for achievements**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Add Live Update for achievement unlocks
  - Feature: Immediate notification on lock screen

- [ ] **Add Live Update actions**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Add quick actions to Live Updates
  - Feature: Quick actions from lock screen (e.g., "Mark as Complete")

### 2.2 Notification Grouping

- [ ] **Implement notification grouping keys**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Add `setGroup()` calls to notification builders
  - Group: Shift reminders together
  - Group: Achievements together
  - Group: Target notifications together

- [ ] **Create notification summary notifications**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Implement summary notifications for grouped notifications
  - Feature: Show summary when multiple notifications are grouped

- [ ] **Update notification channels**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Review and update notification channel importance levels
  - Ensure: Proper categorization for Android 16 grouping

- [ ] **Test notification grouping**
  - Action: Test on Android 16 device/emulator
  - Verify: Notifications group correctly
  - Verify: Summary notifications appear as expected

### 2.3 Rich Notification Content

- [ ] **Enhance notification content**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Add more detailed notification content
  - Add: Images/icons where appropriate
  - Add: Expandable notification content

- [ ] **Add notification actions**
  - File: `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`
  - Action: Add action buttons to notifications
  - Examples: "View Details", "Dismiss", "Mark Complete"

---

## Phase 3: Adaptive Layouts

### 3.1 Window Size Classes

- [ ] **Implement WindowSizeClass detection**
  - Files: All main screen composables
  - Action: Add `calculateWindowSizeClass()` usage
  - Breakpoints: Compact, Medium, Expanded
  - Use: `androidx.compose.material3.adaptive` library

- [ ] **Update DashboardScreen for adaptive layouts**
  - File: `app/src/main/java/com/protip365/app/presentation/dashboard/DashboardScreen.kt`
  - Action: Implement different layouts for different screen sizes
  - Tablet: Use two-column layout
  - Phone: Keep single-column layout

- [ ] **Update CalendarScreen for adaptive layouts**
  - File: `app/src/main/java/com/protip365/app/presentation/calendar/CalendarScreen.kt`
  - Action: Optimize calendar for tablet screens
  - Feature: Show more days visible on tablets

- [ ] **Update SettingsScreen for adaptive layouts**
  - File: `app/src/main/java/com/protip365/app/presentation/settings/SettingsScreen.kt`
  - Action: Use navigation rail for tablets
  - Feature: Two-pane layout for tablets

- [ ] **Update AddEditEntryScreen for adaptive layouts**
  - File: `app/src/main/java/com/protip365/app/presentation/entries/AddEditEntryScreen.kt`
  - Action: Optimize form layout for larger screens
  - Feature: Side-by-side fields on tablets

### 3.2 Foldable Device Support

- [ ] **Detect foldable device states**
  - Files: Main screen composables
  - Action: Implement `WindowInfoRepository` for fold detection
  - Feature: Detect when device is folded/unfolded

- [ ] **Implement dual-pane layouts for foldables**
  - Files: Dashboard, Calendar, Settings screens
  - Action: Create dual-pane layouts when unfolded
  - Feature: Show different content on each pane

- [ ] **Handle configuration changes**
  - Files: All screen composables
  - Action: Ensure state preservation during fold/unfold
  - Test: Verify no data loss during transitions

### 3.3 Orientation Support

- [ ] **Optimize layouts for landscape mode**
  - Files: All screen composables
  - Action: Review and optimize landscape layouts
  - Feature: Better use of horizontal space

- [ ] **Test orientation changes**
  - Action: Test all screens in both orientations
  - Verify: No UI breaking issues
  - Verify: State preservation during rotation

### 3.4 Navigation Updates

- [ ] **Implement adaptive navigation**
  - File: `app/src/main/java/com/protip365/app/presentation/navigation/AppNavigation.kt`
  - Action: Use navigation rail for tablets
  - Feature: Bottom navigation for phones, rail for tablets

- [ ] **Update BottomNavigation component**
  - File: `app/src/main/java/com/protip365/app/presentation/navigation/BottomNavigation.kt`
  - Action: Make adaptive based on screen size
  - Feature: Switch to NavigationRail on larger screens

---

## Phase 4: Accessibility Enhancements

### 4.1 Content Descriptions

- [ ] **Add content descriptions to all images**
  - Files: All composables with Image components
  - Priority: High
  - Action: Add `contentDescription` parameter to all `Image()` calls
  - Files to check:
    - `DashboardScreen.kt` (logo)
    - `CalendarScreen.kt` (icons)
    - `SettingsScreen.kt` (icons)
    - All other screens

- [ ] **Add content descriptions to all icons**
  - Files: All composables with Icon components
  - Priority: High
  - Action: Add `contentDescription` or use `null` for decorative icons
  - Verify: All interactive icons have descriptions

- [ ] **Add labels to all buttons**
  - Files: All composables with Button components
  - Priority: High
  - Action: Ensure buttons have clear text labels or content descriptions
  - Verify: Icon-only buttons have content descriptions

### 4.2 Semantic Headings

- [ ] **Add semantic headings to DashboardScreen**
  - File: `app/src/main/java/com/protip365/app/presentation/dashboard/DashboardScreen.kt`
  - Action: Use `semantics { heading() }` modifier
  - Add: Headings for major sections

- [ ] **Add semantic headings to all screens**
  - Files: All screen composables
  - Action: Implement proper heading hierarchy
  - Structure: h1 for screen title, h2 for sections, h3 for subsections

- [ ] **Test with TalkBack**
  - Action: Enable TalkBack and navigate through app
  - Verify: Proper heading navigation
  - Fix: Any navigation issues

### 4.3 Dynamic Type Support

- [ ] **Test DashboardScreen with large text**
  - File: `app/src/main/java/com/protip365/app/presentation/dashboard/DashboardScreen.kt`
  - Action: Test with system text size set to largest
  - Fix: Any UI breaking issues
  - Verify: Text scales properly without clipping

- [ ] **Test CalendarScreen with large text**
  - File: `app/src/main/java/com/protip365/app/presentation/calendar/CalendarScreen.kt`
  - Action: Test with system text size set to largest
  - Fix: Any UI breaking issues

- [ ] **Test AddEditEntryScreen with large text**
  - File: `app/src/main/java/com/protip365/app/presentation/entries/AddEditEntryScreen.kt`
  - Action: Test with system text size set to largest
  - Fix: Any form field layout issues

- [ ] **Test all other screens with large text**
  - Files: All remaining screen composables
  - Action: Systematically test each screen
  - Fix: Any UI breaking issues

### 4.4 Color Contrast

- [ ] **Audit color contrast ratios**
  - Files: Theme files and all composables
  - Action: Use Android Accessibility Scanner or manual testing
  - Verify: All text meets WCAG 2.1 AA standards (4.5:1 for normal text, 3:1 for large text)
  - Fix: Any contrast issues

- [ ] **Test in high contrast mode**
  - Action: Enable high contrast mode in system settings
  - Verify: App remains usable
  - Fix: Any visibility issues

- [ ] **Ensure color is not the only indicator**
  - Files: All composables
  - Action: Review all UI elements
  - Verify: Information is not conveyed by color alone
  - Add: Icons or text labels where needed

### 4.5 Touch Target Sizes

- [ ] **Audit touch target sizes**
  - Files: All composables with interactive elements
  - Action: Measure all buttons, icons, and interactive elements
  - Requirement: Minimum 48dp x 48dp touch targets
  - Fix: Any elements smaller than 48dp

- [ ] **Add proper spacing between interactive elements**
  - Files: All composables
  - Action: Ensure 8dp minimum spacing between touch targets
  - Verify: No overlapping touch areas

### 4.6 Focus Management

- [ ] **Add visible focus indicators**
  - Files: All composables with focusable elements
  - Action: Ensure focus indicators are visible
  - Verify: Focus is clearly visible in both light and dark modes

- [ ] **Test keyboard navigation**
  - Action: Connect external keyboard (if applicable)
  - Test: Navigate through app using keyboard
  - Verify: Logical focus order
  - Fix: Any navigation issues

---

## Phase 5: Enhanced Haptic Feedback

### 5.1 Review Current Implementation

- [ ] **Audit existing haptic feedback usage**
  - Files: All screen composables
  - Action: Document all current haptic feedback usage
  - Identify: Areas missing haptic feedback

### 5.2 Add Haptic Feedback

- [ ] **Add haptic feedback to button presses**
  - Files: All composables with Button components
  - Action: Add haptic feedback to primary actions
  - Type: `HapticFeedbackType.LongPress` or appropriate type

- [ ] **Add haptic feedback to successful actions**
  - Files: All success callbacks
  - Action: Add haptic feedback on successful saves, updates, etc.
  - Type: `HapticFeedbackType.LongPress`

- [ ] **Add haptic feedback to error states**
  - Files: Error handling code
  - Action: Add haptic feedback for errors
  - Type: `HapticFeedbackType.TextHandleMove` or custom pattern

- [ ] **Add haptic feedback to navigation**
  - Files: Navigation components
  - Action: Add subtle haptic feedback on tab changes
  - Type: Light haptic feedback

- [ ] **Add haptic feedback to form interactions**
  - Files: Form screens (AddEditEntryScreen, etc.)
  - Action: Add haptic feedback to important form interactions
  - Example: When switching between date/time pickers

### 5.3 Context-Aware Haptics

- [ ] **Implement context-aware haptic patterns**
  - Files: All interactive screens
  - Action: Use different haptic patterns for different contexts
  - Examples:
    - Light tap for navigation
    - Medium tap for selections
    - Strong tap for confirmations

---

## Phase 6: Animation and Transitions

### 6.1 Review Existing Animations

- [ ] **Review Animations.kt.bak file**
  - File: `app/src/main/java/com/protip365/app/presentation/components/Animations.kt.bak`
  - Action: Review and restore useful animations
  - Update: To Material 3 motion guidelines

### 6.2 Shared Element Transitions

- [ ] **Add shared element transitions**
  - Files: Navigation between screens
  - Action: Implement shared element transitions where appropriate
  - Examples: Calendar day to detail view, entry card to edit screen

### 6.3 State-Based Animations

- [ ] **Add AnimatedVisibility where appropriate**
  - Files: All screens with conditional content
  - Action: Replace instant show/hide with animated transitions
  - Examples: Error banners, loading states, expanded sections

### 6.4 Reduced Motion Support

- [ ] **Respect accessibility motion settings**
  - Files: All animations
  - Action: Check `isAnimationEnabled()` or similar
  - Feature: Disable animations when user prefers reduced motion
  - Verify: App remains functional without animations

---
