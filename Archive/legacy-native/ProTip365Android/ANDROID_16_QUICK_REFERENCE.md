# Android 16 UI/UX Quick Reference Guide

This guide provides code examples and quick implementation snippets for common Android 16 UI/UX features.

## Table of Contents
1. [Dynamic Color Enhancement](#dynamic-color-enhancement)
2. [Live Updates Notifications](#live-updates-notifications)
3. [Notification Grouping](#notification-grouping)
4. [Adaptive Layouts](#adaptive-layouts)
5. [Accessibility](#accessibility)
6. [Haptic Feedback](#haptic-feedback)
7. [Animations](#animations)

---

## Dynamic Color Enhancement

### Enhanced Theme with Android 16 Color System

```kotlin
// Theme.kt
@Composable
fun ProTip365Theme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Android 16+ enhanced color extraction
                if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
            } else {
                // Fallback for Android 12-15
                if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
            }
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
```

### Supporting Dynamic Type Scaling

```kotlin
// In composables, ensure text scales properly
@Composable
fun ScalableText(
    text: String,
    modifier: Modifier = Modifier
) {
    Text(
        text = text,
        modifier = modifier,
        style = MaterialTheme.typography.bodyLarge,
        // Text will automatically scale with system font size
        fontSize = MaterialTheme.typography.bodyLarge.fontSize
    )
}
```

---

## Live Updates Notifications

### Android 16 Live Updates Implementation

```kotlin
// NotificationManager.kt
fun showLiveUpdateNotification(
    alertType: AlertType,
    title: String,
    message: String,
    liveUpdateContent: String? = null
) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        // Android 16+ Live Updates
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setGroup(GROUP_KEY_SHIFT_REMINDERS)
            .setGroupSummary(false)
            .apply {
                // Live Update content for lock screen
                liveUpdateContent?.let {
                    setStyle(NotificationCompat.BigTextStyle()
                        .bigText(it)
                        .setSummaryText(message))
                }
            }
            .build()

        NotificationManagerCompat.from(context).notify(
            getNotificationId(alertType),
            notification
        )
    } else {
        // Fallback for older versions
        showNotification(alertType, title, message)
    }
}
```

### Notification Channel Setup for Live Updates

```kotlin
private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val importance = NotificationManager.IMPORTANCE_HIGH // High for Live Updates
        val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
            description = CHANNEL_DESCRIPTION
            enableLights(true)
            enableVibration(true)
            setShowBadge(true)
            
            // Android 16+ specific settings
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Allow Live Updates
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
        }

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) 
            as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }
}
```

---

## Notification Grouping

### Implementing Notification Groups

```kotlin
companion object {
    const val GROUP_KEY_SHIFT_REMINDERS = "shift_reminders"
    const val GROUP_KEY_ACHIEVEMENTS = "achievements"
    const val GROUP_KEY_TARGETS = "targets"
}

fun showGroupedNotification(
    alertType: AlertType,
    title: String,
    message: String,
    groupKey: String
) {
    val notification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle(title)
        .setContentText(message)
        .setGroup(groupKey) // Group key
        .setGroupSummary(false) // Individual notification
        .setAutoCancel(true)
        .build()

    NotificationManagerCompat.from(context).notify(
        getNotificationId(alertType),
        notification
    )
    
    // Show summary notification
    showSummaryNotification(groupKey)
}

private fun showSummaryNotification(groupKey: String) {
    val summaryText = when (groupKey) {
        GROUP_KEY_SHIFT_REMINDERS -> "Multiple shift reminders"
        GROUP_KEY_ACHIEVEMENTS -> "New achievements unlocked"
        GROUP_KEY_TARGETS -> "Target updates"
        else -> "Updates available"
    }

    val summaryNotification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle(summaryText)
        .setGroup(groupKey)
        .setGroupSummary(true) // This is the summary
        .setStyle(NotificationCompat.InboxStyle()
            .setSummaryText(summaryText))
        .build()

    NotificationManagerCompat.from(context).notify(
        getGroupSummaryId(groupKey),
        summaryNotification
    )
}
```

---

## Adaptive Layouts

### Window Size Class Detection

```kotlin
// Add dependency: androidx.compose.material3.adaptive

@Composable
fun AdaptiveDashboardScreen() {
    val windowSizeClass = calculateWindowSizeClass()
    
    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact -> {
            // Phone layout
            SingleColumnDashboard()
        }
        WindowWidthSizeClass.Medium -> {
            // Tablet portrait
            TwoColumnDashboard()
        }
        WindowWidthSizeClass.Expanded -> {
            // Tablet landscape or foldable unfolded
            ThreeColumnDashboard()
        }
    }
}

@Composable
fun calculateWindowSizeClass(): WindowSizeClass {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    
    return when {
        screenWidth < 600.dp -> WindowSizeClass.Compact
        screenWidth < 840.dp -> WindowSizeClass.Medium
        else -> WindowSizeClass.Expanded
    }
}
```

### Foldable Device Support

```kotlin
@Composable
fun FoldableAwareScreen() {
    val windowInfo = rememberWindowInfo()
    
    when {
        windowInfo.isTablet && windowInfo.isFolded -> {
            // Folded state - single pane
            SinglePaneLayout()
        }
        windowInfo.isTablet && !windowInfo.isFolded -> {
            // Unfolded state - dual pane
            DualPaneLayout()
        }
        else -> {
            // Phone
            SinglePaneLayout()
        }
    }
}

@Composable
fun rememberWindowInfo(): WindowInfo {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp
    
    return remember(configuration) {
        WindowInfo(
            isTablet = screenWidth >= 600,
            isFolded = false // Detect fold state using Jetpack WindowManager
        )
    }
}
```

### Adaptive Navigation

```kotlin
@Composable
fun AdaptiveNavigation(
    currentRoute: String,
    onNavigate: (String) -> Unit
) {
    val windowSizeClass = calculateWindowSizeClass()
    
    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact -> {
            // Bottom navigation for phones
            BottomNavigationBar(
                currentRoute = currentRoute,
                onNavigate = onNavigate
            )
        }
        WindowWidthSizeClass.Medium,
        WindowWidthSizeClass.Expanded -> {
            // Navigation rail for tablets
            NavigationRail(
                currentRoute = currentRoute,
                onNavigate = onNavigate
            )
        }
    }
}
```

---

## Accessibility

### Content Descriptions

```kotlin
// ✅ Good: Decorative icon
Icon(
    imageVector = Icons.Default.Close,
    contentDescription = null, // Decorative, no action
    modifier = Modifier.clickable { onClose() }
)

// ✅ Good: Interactive icon with description
IconButton(onClick = { onClose() }) {
    Icon(
        imageVector = Icons.Default.Close,
        contentDescription = "Close" // Descriptive for TalkBack
    )
}

// ✅ Good: Image with description
Image(
    painter = painterResource(id = R.drawable.protip365_logo),
    contentDescription = "ProTip365 Logo" // Descriptive
)
```

### Semantic Headings

```kotlin
@Composable
fun DashboardScreen() {
    Column {
        // Screen title - heading level 1
        Text(
            text = "Dashboard",
            style = MaterialTheme.typography.headlineLarge,
            modifier = Modifier.semantics { heading() }
        )
        
        // Section - heading level 2
        Text(
            text = "Statistics",
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier.semantics { heading() }
        )
        
        // Subsection - heading level 3
        Text(
            text = "This Week",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.semantics { heading() }
        )
    }
}
```

### Touch Target Sizes

```kotlin
// ✅ Good: Minimum 48dp touch target
IconButton(
    onClick = { onAction() },
    modifier = Modifier.size(48.dp) // Minimum size
) {
    Icon(
        imageVector = Icons.Default.Add,
        contentDescription = "Add"
    )
}

// ✅ Good: Padding to increase touch target
Box(
    modifier = Modifier
        .clickable { onAction() }
        .padding(12.dp) // Ensures minimum touch target
) {
    Icon(
        imageVector = Icons.Default.Add,
        contentDescription = "Add",
        modifier = Modifier.size(24.dp)
    )
}
```

### Dynamic Type Support

```kotlin
// Text automatically scales with system font size
Text(
    text = "This text scales automatically",
    style = MaterialTheme.typography.bodyLarge
)

// For custom scaling, use LocalDensity
@Composable
fun ScalableText(text: String) {
    val density = LocalDensity.current
    val fontSize = with(density) {
        // Base size that scales with system settings
        MaterialTheme.typography.bodyLarge.fontSize
    }
    
    Text(
        text = text,
        fontSize = fontSize
    )
}
```

---

## Haptic Feedback

### Basic Haptic Feedback

```kotlin
@Composable
fun ButtonWithHaptic(
    onClick: () -> Unit,
    text: String
) {
    val haptics = LocalHapticFeedback.current
    
    Button(
        onClick = {
            haptics.performHapticFeedback(HapticFeedbackType.LongPress)
            onClick()
        }
    ) {
        Text(text)
    }
}
```

### Context-Aware Haptics

```kotlin
@Composable
fun ContextualHapticButton(
    onClick: () -> Unit,
    text: String,
    hapticType: HapticFeedbackType = HapticFeedbackType.LongPress
) {
    val haptics = LocalHapticFeedback.current
    
    Button(
        onClick = {
            haptics.performHapticFeedback(hapticType)
            onClick()
        }
    ) {
        Text(text)
    }
}

// Usage
ContextualHapticButton(
    onClick = { /* confirm action */ },
    text = "Confirm",
    hapticType = HapticFeedbackType.LongPress // Strong for confirmation
)

ContextualHapticButton(
    onClick = { /* navigate */ },
    text = "Next",
    hapticType = HapticFeedbackType.TextHandleMove // Light for navigation
)
```

---

## Animations

### Shared Element Transitions

```kotlin
// Note: Requires experimental SharedTransitionLayout
@OptIn(ExperimentalSharedTransitionApi::class)
@Composable
fun SharedElementTransitionExample() {
    SharedTransitionLayout {
        // Source screen
        Card(
            modifier = Modifier
                .sharedElement(
                    rememberSharedContentState(key = "card")
                )
        ) {
            // Content
        }
    }
}
```

### AnimatedVisibility

```kotlin
@Composable
fun AnimatedErrorBanner(
    error: String?,
    onDismiss: () -> Unit
) {
    AnimatedVisibility(
        visible = error != null,
        enter = slideInVertically() + fadeIn(),
        exit = slideOutVertically() + fadeOut()
    ) {
        error?.let {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Text(
                    text = it,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
        }
    }
}
```

### Respecting Reduced Motion

```kotlin
@Composable
fun RespectMotionPreferences() {
    val isReducedMotionEnabled = LocalAccessibilityManager.current?.isEnabled == true
    
    AnimatedVisibility(
        visible = true,
        enter = if (isReducedMotionEnabled) {
            fadeIn() // Simpler animation
        } else {
            slideInVertically() + fadeIn() // Full animation
        },
        exit = if (isReducedMotionEnabled) {
            fadeOut()
        } else {
            slideOutVertically() + fadeOut()
        }
    ) {
        // Content
    }
}
```

---

## Helper Functions

### Window Size Class Helper

```kotlin
// Add to a utils file
@Composable
fun rememberWindowSizeClass(): WindowSizeClass {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    val screenHeight = configuration.screenHeightDp.dp
    
    return remember(configuration) {
        val widthSizeClass = when {
            screenWidth < 600.dp -> WindowWidthSizeClass.Compact
            screenWidth < 840.dp -> WindowWidthSizeClass.Medium
            else -> WindowWidthSizeClass.Expanded
        }
        
        val heightSizeClass = when {
            screenHeight < 480.dp -> WindowHeightSizeClass.Compact
            screenHeight < 900.dp -> WindowHeightSizeClass.Medium
            else -> WindowHeightSizeClass.Expanded
        }
        
        WindowSizeClass(widthSizeClass, heightSizeClass)
    }
}

// Usage
val windowSizeClass = rememberWindowSizeClass()
```

### Accessibility Helper

```kotlin
// Helper to combine semantics
fun Modifier.semanticHeading(level: Int): Modifier {
    return this.semantics {
        when (level) {
            1 -> heading()
            2 -> heading()
            3 -> heading()
            else -> {}
        }
    }
}

// Usage
Text(
    text = "Section Title",
    modifier = Modifier.semanticHeading(2)
)
```

---

## Testing Helpers

### Test Notification Grouping

```kotlin
// Test helper function
fun testNotificationGrouping() {
    val notificationManager = NotificationManagerCompat.from(context)
    
    // Trigger multiple notifications
    showGroupedNotification(
        AlertType.MISSING_SHIFT,
        "Shift Reminder 1",
        "Don't forget your shift",
        GROUP_KEY_SHIFT_REMINDERS
    )
    
    showGroupedNotification(
        AlertType.MISSING_SHIFT,
        "Shift Reminder 2",
        "Another shift reminder",
        GROUP_KEY_SHIFT_REMINDERS
    )
    
    // Verify they are grouped
    // Check notification shade manually or use instrumentation tests
}
```

---

## Notes

- Always check `Build.VERSION.SDK_INT` before using Android 16+ APIs
- Provide fallbacks for older Android versions
- Test thoroughly on actual devices when possible
- Use Android Studio's Layout Inspector to verify touch target sizes
- Use Accessibility Scanner to identify accessibility issues


