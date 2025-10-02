# Android Implementation Guide - October 2, 2025 Updates

**iOS Version:** v1.1.31
**Date:** October 2, 2025
**Priority:** High - Contains critical bug fixes

---

## Overview

This document outlines all changes made to the iOS app on October 2, 2025, that need to be implemented in the Android app. Most changes are bug fixes and UI improvements.

## Table of Contents
1. [Subscription Flow Fix](#1-subscription-flow-fix)
2. [Shift Status Preservation](#2-shift-status-preservation)
3. [Today's Shift Status Logic](#3-todays-shift-status-logic)
4. [Sales Target Default Loading](#4-sales-target-default-loading)
5. [Sales Target UI Layout](#5-sales-target-ui-layout)
6. [Tip Calculator UI Update](#6-tip-calculator-ui-update)
7. [Settings Targets Layout](#7-settings-targets-layout)
8. [Subscription Page Redesign](#8-subscription-page-redesign)
9. [Splash Screen](#9-splash-screen)
10. [Subscription Section Visibility](#10-subscription-section-visibility)

---

## 1. Subscription Flow Fix

### Issue
Subscription page appeared twice on app launch (flash → disappear → reappear).

### Root Cause
- Duplicate subscription checks triggered during authentication flow
- Auth state listener triggering multiple concurrent subscription validations

### iOS Solution
**Files:** `ProTip365/ContentView.swift`

1. Removed duplicate `.onAppear` block that was calling `checkAuth()` after `.task` already called it
2. Added guard in auth state listener to prevent concurrent subscription checks:

```swift
// Only check subscription if not already checking
let shouldCheck = await MainActor.run {
    return !isCheckingSubscription
}

if shouldCheck {
    await MainActor.run {
        isCheckingSubscription = true
    }

    await subscriptionManager.checkAndSyncExistingSubscription()

    try? await Task.sleep(nanoseconds: 500_000_000)

    await MainActor.run {
        isCheckingSubscription = false
    }
}
```

### Android Implementation

**Status:** ✅ **NOT NEEDED** - Android app doesn't have this issue

The Android app structure is different and doesn't have duplicate subscription checks. The `AuthViewModel` and `SubscriptionViewModel` are properly separated and don't trigger multiple flows.

**Verification:** Test app launch to ensure subscription screen only appears once.

---

## 2. Shift Status Preservation

### Issue
When editing an existing shift, the status was being automatically changed to "completed" even when the user didn't change it.

### Root Cause
Save logic was recalculating status for ALL shifts (both new and existing), overwriting the original status when editing.

### iOS Solution
**File:** `ProTip365/AddShift/AddShiftDataManager.swift:512-530`

```swift
if let existingShift = editingShift {
    // Update existing expected shift - PRESERVE EXISTING STATUS
    // Don't auto-change status when editing, only user can change it
    let updatedShift = ExpectedShift(
        ...
        status: existingShift.expected_shift.status, // ✅ Preserve existing status
        ...
    )
}
```

### Android Implementation

**Files to Check:**
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/shifts/AddEditShiftViewModel.kt`
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/shifts/AddShiftViewModel.kt`

**Implementation:**

```kotlin
// When updating existing shift
if (editingShiftId != null) {
    val updatedShift = ExpectedShift(
        id = editingShiftId,
        userId = userId,
        // ... other fields ...
        status = existingShift.status, // ✅ Preserve original status
        // ... rest of fields ...
    )
    expectedShiftRepository.updateExpectedShift(updatedShift)
} else {
    // For new shifts, calculate status based on date
    val status = calculateShiftStatus(shiftDate)
    val newShift = ExpectedShift(
        // ... fields ...
        status = status, // ✅ Auto-set for new shifts only
        // ... rest of fields ...
    )
    expectedShiftRepository.createExpectedShift(newShift)
}
```

**Key Points:**
- **Editing existing shift:** Always preserve `shift.status` from database
- **Creating new shift:** Auto-calculate status based on date (see next section)
- **Never auto-change status** when user is editing an existing shift

---

## 3. Today's Shift Status Logic

### Issue
Creating a new shift for "today" would mark it as "completed" if the shift's start time had already passed (e.g., creating a 9am shift when it's currently 2pm).

### Root Cause
Status calculation compared full date-time (including hours/minutes) instead of just the date.

### iOS Solution
**File:** `ProTip365/AddShift/AddShiftDataManager.swift:550-556`

**Before (Wrong):**
```swift
let shiftStartDateTime = calendar.date(from: shiftDateComponents) ?? selectedDate
let now = Date()
let shiftStatus = shiftStartDateTime > now ? "planned" : "completed"
```

**After (Correct):**
```swift
// Compare dates only: today or future = "planned", past = "completed"
let calendar = Calendar.current
let today = calendar.startOfDay(for: Date())
let shiftDate = calendar.startOfDay(for: selectedDate)

let shiftStatus = shiftDate >= today ? "planned" : "completed"
```

### Android Implementation

**Function:** `calculateShiftStatus()` or wherever status is determined for new shifts

```kotlin
fun calculateShiftStatus(shiftDate: LocalDate): String {
    val today = Clock.System.now()
        .toLocalDateTime(TimeZone.currentSystemDefault())
        .date

    return if (shiftDate >= today) {
        "planned"
    } else {
        "completed"
    }
}
```

**Alternative using Calendar:**
```kotlin
fun calculateShiftStatus(shiftDate: Date): String {
    val calendar = Calendar.getInstance()

    // Get today at midnight
    val today = calendar.apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.time

    // Get shift date at midnight
    val shiftDateMidnight = Calendar.getInstance().apply {
        time = shiftDate
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.time

    return if (shiftDateMidnight >= today) {
        "planned"
    } else {
        "completed"
    }
}
```

**Expected Behavior:**
- **Today or future dates** → `"planned"`
- **Yesterday or earlier** → `"completed"`
- **Time of day is ignored** when determining status

**Why Compare Dates Only?**
When creating a shift for today, users expect it to be "planned" regardless of whether they set the start time to 9am while it's currently 2pm. The status should only become "completed" when:
1. The user explicitly marks it as completed (via UI)
2. The shift date is in the past (yesterday or earlier)

---

## 4. Sales Target Default Loading

### Issue
When creating a new shift, the sales target field didn't display the user's default daily sales target value from `users_profile.target_sales_daily`.

### Root Cause
The `loadUserDefaults()` function wasn't fetching the `target_sales_daily` field from the database.

### iOS Solution
**File:** `ProTip365/AddShift/AddShiftDataManager.swift:173-213`

**Before:**
```swift
struct ProfileDefaults: Decodable {
    let default_alert_minutes: Int?
}

let profiles: [ProfileDefaults] = try await SupabaseManager.shared.client
    .from("users_profile")
    .select("default_alert_minutes")  // ❌ Missing target_sales_daily
    .eq("user_id", value: userId)
    .execute()
    .value
```

**After:**
```swift
struct ProfileDefaults: Decodable {
    let default_alert_minutes: Int?
    let target_sales_daily: Double?  // ✅ Added
}

let profiles: [ProfileDefaults] = try await SupabaseManager.shared.client
    .from("users_profile")
    .select("default_alert_minutes, target_sales_daily")  // ✅ Fetch both
    .eq("user_id", value: userId)
    .execute()
    .value

if let profile = profiles.first {
    // Load alert default
    if let defaultMinutes = profile.default_alert_minutes {
        defaultAlertMinutes = defaultMinutes
        // ... set selected alert ...
    }

    // Load sales target default
    if let dailySalesTarget = profile.target_sales_daily {
        defaultDailySalesTarget = dailySalesTarget  // ✅ Store in variable
    }
}
```

### Android Implementation

**Status:** ✅ **ALREADY IMPLEMENTED CORRECTLY**

**File:** `ProTip365Android/app/src/main/java/com/protip365/app/presentation/shifts/AddEditShiftViewModel.kt:63-92`

The Android code already loads `targetSalesDaily` correctly:

```kotlin
private fun loadUserDefaults() {
    viewModelScope.launch {
        try {
            val currentUser = userRepository.getCurrentUser().first()
            val userId = currentUser?.userId ?: return@launch

            userRepository.getUserProfile(userId)?.let { profile ->
                _uiState.update { state ->
                    state.copy(
                        alertMinutes = profile.defaultAlertMinutes,
                        averageDeductionPercentage = profile.averageDeductionPercentage,
                        defaultSalesTarget = profile.targetSalesDaily ?: 0.0  // ✅ Already correct
                    )
                }
            }
        } catch (e: Exception) {
            // Silently fail - defaults are optional
        }
    }
}
```

**Verification:**
- Ensure `UserProfile` model has `targetSalesDaily` field
- Verify field is displayed as placeholder in UI
- Test creating new shift shows default value

---

## 5. Sales Target UI Layout

### Issue
Sales target field was displayed vertically (stacked) with label above and field below, taking up too much space. Caption "Use Default Target" was redundant.

### iOS Solution
**File:** `ProTip365/AddShift/ShiftDetailsSection.swift:78-100`

**Before (Vertical Layout):**
```swift
VStack(alignment: .leading, spacing: 8) {
    Text(localization.salesTargetText)
        .font(.body)
        .foregroundColor(.primary)

    TextField(...)
        .padding(...)
        .background(...)

    // Caption below
    if salesTarget.isEmpty && defaultSalesTarget > 0 {
        Text("Use Default Target: $\(defaultSalesTarget)")
            .font(.caption)
    }
}
```

**After (Horizontal Layout):**
```swift
HStack {
    Text(localization.salesTargetText)
        .font(.body)
        .foregroundColor(.primary)

    Spacer()

    TextField(
        defaultSalesTarget > 0 ? String(format: "%.0f", defaultSalesTarget) : "0",
        text: $salesTarget
    )
    .font(.body)
    .keyboardType(.decimalPad)
    .multilineTextAlignment(.trailing)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color(.systemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(maxWidth: 150)
}
.padding(.horizontal, 16)
.padding(.vertical, 12)
```

### Android Implementation

**File:** `ProTip365Android/app/src/main/java/com/protip365/app/presentation/shifts/AddEditShiftScreen.kt`

**Current Code (around line 424-435):**
Already implemented correctly! No changes needed.

```kotlin
OutlinedTextField(
    value = salesTarget,
    onValueChange = onSalesTargetChange,
    placeholder = {
        Text(
            text = if (defaultSalesTarget > 0) {
                String.format("%.0f", defaultSalesTarget)
            } else {
                "0"
            }
        )
    },
    // ... rest of config ...
)
```

**Verify:**
- Layout is horizontal (Row): Label on left, field on right
- Field width is approximately 150dp
- Placeholder shows default value from `users_profile.target_sales_daily`
- No caption below field
- Text aligned to the right in the field

**Reference Implementation (if needed):**
```kotlin
Row(
    modifier = Modifier
        .fillMaxWidth()
        .padding(horizontal = 16.dp, vertical = 12.dp),
    horizontalArrangement = Arrangement.SpaceBetween,
    verticalAlignment = Alignment.CenterVertically
) {
    Text(
        text = stringResource(R.string.sales_target),
        style = MaterialTheme.typography.bodyLarge
    )

    OutlinedTextField(
        value = salesTarget,
        onValueChange = { salesTarget = it },
        placeholder = {
            Text(
                text = if (defaultSalesTarget > 0)
                    defaultSalesTarget.toInt().toString()
                else "0"
            )
        },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
        textStyle = LocalTextStyle.current.copy(textAlign = TextAlign.End),
        modifier = Modifier
            .width(150.dp)
            .height(48.dp),
        shape = RoundedCornerShape(8.dp),
        singleLine = true
    )
}
```

---

## 6. Tip Calculator UI Update

### Issue
In the Tip-out tab, the "%" symbol was inside the input field, making it unclear that users should enter percentage values.

### iOS Solution
**File:** `ProTip365/Utilities/TipCalculatorView.swift:690-739`

**Before:**
```swift
HStack(spacing: 4) {
    TextField("0", text: $percentage)
        .frame(width: 35)

    Text("%")  // Inside the grey background box
}
.padding(...)
.background(Color(.systemGray6))
.clipShape(RoundedRectangle(cornerRadius: 8))
```

**After:**
```swift
TextField("0", text: $percentage)
    .frame(width: 50)
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 8))

Text("%")  // Outside the grey box, as a caption
    .font(.body)
    .foregroundStyle(.secondary)
```

### Android Implementation

**File:** Look for Tip Calculator screen, specifically the Tip-out tab

**Location:** Likely in:
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/calculator/CalculatorScreen.kt`
- Or a dedicated Tip-out screen/component

**Current Layout (to find and update):**
```kotlin
// Find the Bar, Busser, Runner input fields in Tip-out tab
```

**New Layout:**
```kotlin
Row(
    modifier = Modifier
        .fillMaxWidth()
        .padding(horizontal = 16.dp, vertical = 8.dp),
    horizontalArrangement = Arrangement.SpaceBetween,
    verticalAlignment = Alignment.CenterVertically
) {
    Text(
        text = stringResource(R.string.bar), // or busser, runner
        style = MaterialTheme.typography.bodyLarge,
        modifier = Modifier.width(80.dp)
    )

    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        OutlinedTextField(
            value = barPercentage,
            onValueChange = { /* ... */ },
            placeholder = { Text("0") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            textStyle = LocalTextStyle.current.copy(textAlign = TextAlign.End),
            modifier = Modifier
                .width(70.dp)
                .height(48.dp),
            shape = RoundedCornerShape(8.dp),
            singleLine = true
        )

        // % symbol OUTSIDE the field
        Text(
            text = "%",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }

    Spacer(modifier = Modifier.weight(1f))

    // Amount display
    Text(
        text = formatCurrency(barAmount),
        style = MaterialTheme.typography.bodyLarge,
        fontWeight = FontWeight.Medium
    )
}
```

**Key Changes:**
1. Move "%" symbol **outside** the TextField border
2. "%" appears to the right of the input field
3. Use secondary/tertiary color for "%" to indicate it's a label
4. Increase field width slightly (70dp) since "%" is now outside

**Visual Layout:**
```
[Label]     [Input] %           $Amount
Bar         [5    ] %           $2.50
Busser      [3    ] %           $1.50
Runner      [2    ] %           $1.00
```

---

## 7. Settings Targets Layout

### Issue
The "Set Your Goals" section appeared as a separate card above the "Your Targets" card, creating visual separation and taking up extra space.

### iOS Solution
**File:** `ProTip365/Settings/TargetsSettingsSection.swift:51-95`

**Before:**
```swift
var body: some View {
    VStack(spacing: 20) {
        // Separate "Set Your Goals" card
        targetsExplanationSection

        // "Your Targets" card with title
        allTargetsSection
    }
}

private var allTargetsSection: some View {
    VStack(alignment: .leading, spacing: 20) {
        // Section Title "Your Targets"
        HStack(spacing: 12) {
            Image(systemName: "target")
            Text(localization.yourTargetsTitle)  // ❌ Remove this
            Spacer()
        }

        // Tip Targets...
    }
}
```

**After:**
```swift
var body: some View {
    VStack(spacing: 20) {
        // Single combined card
        allTargetsSection
    }
}

private var allTargetsSection: some View {
    VStack(alignment: .leading, spacing: 20) {
        // Set Your Goals explanation at top (moved from separate card)
        VStack(spacing: 8) {
            Text(localization.setYourGoalsTitle)  // ✅ "Set Your Goals"
                .font(.headline)
                .foregroundStyle(.primary)

            Text(localization.setYourGoalsDescription)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }

        Divider()

        // Tip Targets (no more "Your Targets" title)
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.tipTargetsSection)
            // ... rest of tip targets
        }
    }
}
```

### Android Implementation

**File:** Look for Settings screen, specifically the Targets section

**Location:** Likely in:
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/TargetsScreen.kt`
- Or within `SettingsScreen.kt` as a section

**Changes Needed:**

1. **Remove separate "Set Your Goals" card** if it exists
2. **Remove "Your Targets" title** from the targets card
3. **Add "Set Your Goals" content at the top** of the targets card

**Expected Structure:**
```kotlin
Card(
    modifier = Modifier
        .fillMaxWidth()
        .padding(16.dp),
    shape = RoundedCornerShape(12.dp)
) {
    Column(
        modifier = Modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // 1. Set Your Goals section at top
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = stringResource(R.string.set_your_goals_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Text(
                text = stringResource(R.string.set_your_goals_description),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Divider()

        // 2. Tip Targets section
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                text = stringResource(R.string.tip_targets),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Medium
            )

            // Tip percentage field
            // ...
        }

        Divider()

        // 3. Sales Targets section
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                text = stringResource(R.string.sales_targets),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Medium
            )

            // Daily/Weekly/Monthly sales fields
            // ...
        }

        Divider()

        // 4. Hours Targets section
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                text = stringResource(R.string.hours_targets),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Medium
            )

            // Daily/Weekly/Monthly hours fields
            // ...
        }
    }
}
```

**Visual Result:**
```
┌─────────────────────────────────┐
│ Set Your Goals                  │  ← Title at top
│ Set daily, weekly, and monthly  │  ← Caption
│ targets to track your progress  │
├─────────────────────────────────┤  ← Divider
│ Tip Targets                     │  ← Section title
│ Tip %: [____] %                 │
│ ℹ️ Note about tip percentage    │
├─────────────────────────────────┤
│ Sales Targets                   │
│ Daily:   [____]                 │
│ Weekly:  [____]                 │
│ Monthly: [____]                 │
│ ℹ️ Note about variable schedule │
├─────────────────────────────────┤
│ Hours Targets                   │
│ Daily:   [____]                 │
│ Weekly:  [____]                 │
│ Monthly: [____]                 │
│ ℹ️ Note about variable schedule │
└─────────────────────────────────┘
```

**Key Points:**
- **Single card** containing all targets
- **"Set Your Goals"** title and caption at the very top
- **No "Your Targets"** title/header
- Targets organized by section: Tip → Sales → Hours
- Dividers between each major section

---

## 8. Subscription Page Redesign

### Issue
The subscription marketing page had weak copy that didn't effectively communicate the value proposition. Title was generic and features were listed without context.

### iOS Solution
**File:** `ProTip365/Subscription/SubscriptionTiersView.swift:166-190, 351-449`

**Before:**
```swift
Text("ProTip365 Premium")
    .font(.largeTitle)
    .fontWeight(.bold)

Text("Start your 7-day free trial")
    .font(.subheadline)

// Features
"Unlimited shift tracking"
"Unlimited entries"
"Advanced analytics"
```

**After:**
```swift
Text("Track Every Tip.\nManage Every Shift.\nAccess Your Data Anywhere.")
    .font(.system(size: 28, weight: .bold))
    .multilineTextAlignment(.center)

Text("The smart tip tracking app designed for service industry professionals who want to replace paper slips and Excel files with real-time data management across all their devices.")
    .font(.subheadline)
    .multilineTextAlignment(.center)

// Updated Features
"Unlimited shifts per day"
"Multiple employer management"
"Advanced analytics and detailed reports"
"Data export (CSV/PDF)"
"Automatic cloud synchronization"
"Priority support"
```

### Android Implementation

**File:** Subscription/Paywall screen

**Location:** Likely in:
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/SubscriptionScreen.kt`
- Or dedicated subscription paywall screen

**New Marketing Copy:**

```kotlin
// Header Title (multi-line)
Text(
    text = when (language) {
        "fr" -> "Suivez Chaque Pourboire.\nGérez Chaque Quart.\nAccédez à Vos Données Partout."
        "es" -> "Rastrea Cada Propina.\nGestiona Cada Turno.\nAccede a Tus Datos en Todas Partes."
        else -> "Track Every Tip.\nManage Every Shift.\nAccess Your Data Anywhere."
    },
    style = MaterialTheme.typography.headlineMedium,
    fontWeight = FontWeight.Bold,
    textAlign = TextAlign.Center,
    modifier = Modifier.padding(horizontal = 16.dp)
)

// Subtitle
Text(
    text = when (language) {
        "fr" -> "L'application intelligente de suivi des pourboires conçue pour les professionnels de l'industrie des services qui veulent remplacer les reçus papier et les fichiers Excel par une gestion des données en temps réel sur tous leurs appareils."
        "es" -> "La aplicación inteligente de seguimiento de propinas diseñada para profesionales de la industria de servicios que desean reemplazar recibos de papel y archivos de Excel con gestión de datos en tiempo real en todos sus dispositivos."
        else -> "The smart tip tracking app designed for service industry professionals who want to replace paper slips and Excel files with real-time data management across all their devices."
    },
    style = MaterialTheme.typography.bodyMedium,
    textAlign = TextAlign.Center,
    color = MaterialTheme.colorScheme.onSurfaceVariant,
    modifier = Modifier.padding(horizontal = 32.dp)
)

// Premium Section Title
Text(
    text = stringResource(R.string.premium_features),
    style = MaterialTheme.typography.titleLarge,
    fontWeight = FontWeight.Bold
)

// Updated Feature List
val premiumFeatures = when (language) {
    "fr" -> listOf(
        "Suivi illimité des quarts de travail par jour",
        "Gestion de plusieurs employeurs",
        "Analyses avancées et rapports détaillés",
        "Export de données (CSV/PDF)",
        "Synchronisation automatique dans le cloud",
        "Support prioritaire"
    )
    "es" -> listOf(
        "Turnos ilimitados por día",
        "Gestión de múltiples empleadores",
        "Análisis avanzados e informes detallados",
        "Exportación de datos (CSV/PDF)",
        "Sincronización automática en la nube",
        "Soporte prioritario"
    )
    else -> listOf(
        "Unlimited shifts per day",
        "Multiple employer management",
        "Advanced analytics and detailed reports",
        "Data export (CSV/PDF)",
        "Automatic cloud synchronization",
        "Priority support"
    )
}
```

**String Resources (res/values/strings.xml):**
```xml
<string name="subscription_header_title">Track Every Tip.\nManage Every Shift.\nAccess Your Data Anywhere.</string>
<string name="subscription_header_subtitle">The smart tip tracking app designed for service industry professionals who want to replace paper slips and Excel files with real-time data management across all their devices.</string>

<string name="premium_description">Everything you need to manage your tip income</string>

<string name="feature_unlimited_shifts">Unlimited shifts per day</string>
<string name="feature_multiple_employers">Multiple employer management</string>
<string name="feature_advanced_analytics">Advanced analytics and detailed reports</string>
<string name="feature_data_export">Data export (CSV/PDF)</string>
<string name="feature_cloud_sync">Automatic cloud synchronization</string>
<string name="feature_priority_support">Priority support</string>
```

**French (res/values-fr/strings.xml):**
```xml
<string name="subscription_header_title">Suivez Chaque Pourboire.\nGérez Chaque Quart.\nAccédez à Vos Données Partout.</string>
<string name="subscription_header_subtitle">L\'application intelligente de suivi des pourboires conçue pour les professionnels de l\'industrie des services qui veulent remplacer les reçus papier et les fichiers Excel par une gestion des données en temps réel sur tous leurs appareils.</string>

<string name="premium_description">Tout ce dont vous avez besoin pour gérer vos revenus de pourboires</string>

<string name="feature_unlimited_shifts">Suivi illimité des quarts de travail par jour</string>
<string name="feature_multiple_employers">Gestion de plusieurs employeurs</string>
<string name="feature_advanced_analytics">Analyses avancées et rapports détaillés</string>
<string name="feature_data_export">Export de données (CSV/PDF)</string>
<string name="feature_cloud_sync">Synchronisation automatique dans le cloud</string>
<string name="feature_priority_support">Support prioritaire</string>
```

**Spanish (res/values-es/strings.xml):**
```xml
<string name="subscription_header_title">Rastrea Cada Propina.\nGestiona Cada Turno.\nAccede a Tus Datos en Todas Partes.</string>
<string name="subscription_header_subtitle">La aplicación inteligente de seguimiento de propinas diseñada para profesionales de la industria de servicios que desean reemplazar recibos de papel y archivos de Excel con gestión de datos en tiempo real en todos sus dispositivos.</string>

<string name="premium_description">Todo lo que necesitas para gestionar tus ingresos por propinas</string>

<string name="feature_unlimited_shifts">Turnos ilimitados por día</string>
<string name="feature_multiple_employers">Gestión de múltiples empleadores</string>
<string name="feature_advanced_analytics">Análisis avanzados e informes detallados</string>
<string name="feature_data_export">Exportación de datos (CSV/PDF)</string>
<string name="feature_cloud_sync">Sincronización automática en la nube</string>
<string name="feature_priority_support">Soporte prioritario</string>
```

**Visual Layout:**
```
┌─────────────────────────────────┐
│        [App Logo]               │
│                                 │
│   Track Every Tip.              │
│   Manage Every Shift.           │
│   Access Your Data Anywhere.    │
│                                 │
│   The smart tip tracking app    │
│   designed for service industry │
│   professionals...              │
├─────────────────────────────────┤
│   Premium Features              │
│                                 │
│   ✅ Unlimited shifts per day   │
│   ✅ Multiple employer mgmt     │
│   ✅ Advanced analytics         │
│   ✅ Data export (CSV/PDF)      │
│   ✅ Cloud synchronization      │
│   ✅ Priority support           │
├─────────────────────────────────┤
│   ⭐⭐⭐⭐⭐                      │
├─────────────────────────────────┤
│   7 days free                   │
│   Then $3.99/month              │
├─────────────────────────────────┤
│   [Start Free Trial Button]    │
│                                 │
│   [Restore Purchases]           │
└─────────────────────────────────┘
```

**Key Changes:**
1. **Header:** Multi-line, benefit-focused title
2. **Subtitle:** Clear value proposition for target audience
3. **Features:** More specific and benefit-oriented
4. **Removed:** Generic "Maximize Your Earnings" title
5. **Added:** Context about replacing paper/Excel

---

## 9. Splash Screen

### Issue
The app only showed a static icon on launch without the app name or branding catchphrase.

### iOS Solution
**Files Created:**
- `ProTip365/SplashScreenView.swift` (new)
- `ProTip365/ProTip365App.swift` (updated)

**Implementation:**
```swift
struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var size = 0.8
    @State private var opacity = 0.5
    @AppStorage("language") private var language = "en"

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // App Icon
                Image("Logo2")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(radius: 10)

                // App Name
                HStack(spacing: 0) {
                    Text("ProTip")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("365")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                }

                // Catchphrase
                Text(catchphrase)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isActive = true
                    }
                }
            }
        }
    }

    private var catchphrase: String {
        switch language {
        case "fr":
            return "Maximisez vos revenus, un pourboire à la fois"
        case "es":
            return "Maximiza tus ingresos, una propina a la vez"
        default:
            return "Maximize Your Tips, One Shift at a Time"
        }
    }
}
```

### Android Implementation

**File:** Create `SplashActivity.kt` or `SplashScreen.kt`

**Location:**
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/splash/SplashScreen.kt`

**Implementation:**

```kotlin
@Composable
fun SplashScreen(
    onTimeout: () -> Unit,
    language: String
) {
    var startAnimation by remember { mutableStateOf(false) }
    val alphaAnim = animateFloatAsState(
        targetValue = if (startAnimation) 1f else 0f,
        animationSpec = tween(durationMillis = 800)
    )
    val scaleAnim = animateFloatAsState(
        targetValue = if (startAnimation) 1f else 0.8f,
        animationSpec = tween(durationMillis = 800)
    )

    LaunchedEffect(key1 = true) {
        startAnimation = true
        delay(2000)
        onTimeout()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        Color(0xFF2196F3).copy(alpha = 0.3f),
                        Color(0xFF9C27B0).copy(alpha = 0.3f)
                    ),
                    start = Offset(0f, 0f),
                    end = Offset(1000f, 1000f)
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier
                .scale(scaleAnim.value)
                .alpha(alphaAnim.value)
        ) {
            // App Icon
            Image(
                painter = painterResource(id = R.drawable.app_icon_full),
                contentDescription = "ProTip365 Logo",
                modifier = Modifier
                    .size(120.dp)
                    .clip(RoundedCornerShape(28.dp))
                    .shadow(10.dp, RoundedCornerShape(28.dp))
            )

            Spacer(modifier = Modifier.height(20.dp))

            // App Name
            Row {
                Text(
                    text = "ProTip",
                    fontSize = 36.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = "365",
                    fontSize = 36.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF2196F3)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Catchphrase
            Text(
                text = when (language) {
                    "fr" -> "Maximisez vos revenus, un pourboire à la fois"
                    "es" -> "Maximiza tus ingresos, una propina a la vez"
                    else -> "Maximize Your Tips, One Shift at a Time"
                },
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 40.dp)
            )
        }
    }
}
```

**Add to MainActivity or Navigation:**
```kotlin
// In your main composable
var showSplash by remember { mutableStateOf(true) }

if (showSplash) {
    SplashScreen(
        onTimeout = { showSplash = false },
        language = currentLanguage
    )
} else {
    // Main app content
    MainScreen()
}
```

**Catchphrase Translations:**
- **English:** "Maximize Your Tips, One Shift at a Time"
- **French:** "Maximisez vos revenus, un pourboire à la fois"
- **Spanish:** "Maximiza tus ingresos, una propina a la vez"

**String Resources:**
```xml
<!-- res/values/strings.xml -->
<string name="splash_catchphrase">Maximize Your Tips, One Shift at a Time</string>

<!-- res/values-fr/strings.xml -->
<string name="splash_catchphrase">Maximisez vos revenus, un pourboire à la fois</string>

<!-- res/values-es/strings.xml -->
<string name="splash_catchphrase">Maximiza tus ingresos, una propina a la vez</string>
```

**Visual Elements:**
- **Icon:** 120dp × 120dp, rounded corners (28dp)
- **Gradient:** Blue to purple, 30% opacity
- **Animation:** Fade in + scale up (800ms)
- **Duration:** 2 seconds total display time
- **Transition:** Fade out (300ms)

---

## 10. Subscription Section Visibility

### Issue
The subscription management card was always showing in Settings, even when user had no active subscription, displaying potentially stale "Premium Active" data.

### iOS Solution
**File:** `ProTip365/Settings/SubscriptionManagementSection.swift:11-13`

**Before:**
```swift
var body: some View {
    VStack(alignment: .leading, spacing: 16) {
        // Always shows subscription card
        // Could display incorrect status
    }
}
```

**After:**
```swift
var body: some View {
    // Only show this section if user has an active subscription or is in trial
    if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
        VStack(alignment: .leading, spacing: 16) {
            // Subscription card content
        }
    }
}
```

### Android Implementation

**File:** Settings screen subscription section

**Location:**
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/SettingsScreen.kt`

**Changes Needed:**

```kotlin
// Only show subscription management card if user has active subscription
if (subscriptionState.isSubscribed || subscriptionState.isInTrialPeriod) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Section Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = null,
                    tint = Color(0xFFFFD700),
                    modifier = Modifier.size(28.dp)
                )
                Text(
                    text = stringResource(R.string.subscription_title),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            // Status Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = stringResource(R.string.status_label),
                    style = MaterialTheme.typography.bodyMedium
                )

                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(
                        imageVector = if (subscriptionState.isInTrialPeriod) {
                            Icons.Default.Schedule
                        } else {
                            Icons.Default.CheckCircle
                        },
                        contentDescription = null,
                        tint = if (subscriptionState.isInTrialPeriod) {
                            Color.Blue
                        } else {
                            Color.Green
                        },
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = if (subscriptionState.isInTrialPeriod) {
                            stringResource(R.string.trial_period)
                        } else {
                            stringResource(R.string.premium_active)
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (subscriptionState.isInTrialPeriod) {
                            Color.Blue
                        } else {
                            Color.Green
                        }
                    )
                }
            }

            // Trial days remaining (if in trial)
            if (subscriptionState.isInTrialPeriod) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = stringResource(R.string.trial_remaining),
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Text(
                        text = "${subscriptionState.trialDaysRemaining} ${stringResource(R.string.days)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Manage Subscription Button
            OutlinedButton(
                onClick = {
                    // Open Play Store subscription management
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        data = Uri.parse("https://play.google.com/store/account/subscriptions")
                    }
                    context.startActivity(intent)
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(stringResource(R.string.manage_subscription))
                Spacer(modifier = Modifier.width(8.dp))
                Icon(
                    imageVector = Icons.Default.OpenInNew,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}
```

**Key Points:**
- **Conditional rendering:** Only show card if `isSubscribed` OR `isInTrialPeriod`
- **Clean UI:** No subscription card when there's no subscription
- **Prevents confusion:** Users won't see stale "Premium Active" status
- **State-driven:** Card appearance is tied to actual subscription state

---

## Testing Checklist

### Shift Status Tests
- [ ] Create a new shift for tomorrow → verify status is "planned"
- [ ] Create a new shift for today at any time → verify status is "planned"
- [ ] Create a new shift for today at 9am when it's 2pm → verify status is "planned"
- [ ] Create a new shift for yesterday → verify status is "completed"
- [ ] Edit an existing "planned" shift → verify status stays "planned"
- [ ] Edit an existing "completed" shift → verify status stays "completed"
- [ ] Edit shift date but not status → verify status doesn't auto-change

### Sales Target Tests
- [ ] Set default daily sales target to 500 in Settings
- [ ] Create new shift → verify field placeholder shows "500"
- [ ] Leave field empty and save → verify uses default (500)
- [ ] Enter custom value (700) → verify saves 700 to `expected_shifts.sales_target`
- [ ] Edit existing shift with custom target → verify shows custom value
- [ ] Edit existing shift with no custom target → verify shows default as placeholder

### Tip Calculator Tests
- [ ] Open Calculator tab → switch to Tip-out
- [ ] Verify "%" symbol appears OUTSIDE the input field for Bar/Busser/Runner
- [ ] Enter percentage values → verify calculations work correctly
- [ ] Verify layout matches iOS (label - field - % - amount)

### Settings Targets Tests
- [ ] Open Settings → scroll to Targets section
- [ ] Verify "Set Your Goals" title appears at top of card
- [ ] Verify "Set Your Goals" caption appears below title
- [ ] Verify NO separate "Set Your Goals" card above targets
- [ ] Verify NO "Your Targets" title/header in the card
- [ ] Verify all targets (Tip/Sales/Hours) are within single card
- [ ] Verify dividers separate each section

### Subscription Page Tests
- [ ] Open subscription page → verify new marketing copy displays
- [ ] Verify title: "Track Every Tip. Manage Every Shift..."
- [ ] Verify subtitle about replacing paper/Excel
- [ ] Verify updated feature list (6 features)
- [ ] Test all three languages (EN/FR/ES)

### Splash Screen Tests
- [ ] Launch app → verify splash screen shows
- [ ] Verify app icon appears (120dp)
- [ ] Verify "ProTip365" name shows (ProTip + 365 in different colors)
- [ ] Verify catchphrase shows in correct language
- [ ] Verify fade-in animation works
- [ ] Verify 2-second duration then auto-dismiss
- [ ] Test all three language catchphrases

### Subscription Section Visibility Tests
- [ ] No subscription → verify NO subscription card in Settings
- [ ] Active subscription → verify card appears in Settings
- [ ] Trial period → verify card appears with trial info
- [ ] Cancel subscription → verify card disappears after expiry

### Subscription Flow Tests
- [ ] Fresh app install → verify subscription screen appears once
- [ ] Kill and relaunch app → verify no duplicate subscription screens
- [ ] Sign out and sign in → verify subscription flow is smooth

---

## Database Schema Updates

No schema changes are required. All changes are code-level only.

**Existing schema** already supports:
- `expected_shifts.sales_target` (nullable DECIMAL)
- `expected_shifts.status` (TEXT)
- `users_profile.target_sales_daily` (DECIMAL)

---

## Priority & Impact

### Critical (Must Fix)
1. ✅ **Shift Status Preservation** - Prevents data corruption
2. ✅ **Today's Shift Status Logic** - Fixes incorrect status assignment

### High (Should Fix)
3. ✅ **Sales Target Default Loading** - Improves UX
4. ✅ **Sales Target UI Layout** - Consistency with iOS

### Medium (Nice to Have)
5. ⚠️ **Subscription Flow** - Not applicable to Android
6. ✅ **Tip Calculator UI** - Polish/UX improvement
7. ✅ **Settings Targets Layout** - UI consolidation/cleanup
8. ✅ **Subscription Page Redesign** - Marketing/UX improvement
9. ✅ **Splash Screen** - Branding/polish
10. ✅ **Subscription Section Visibility** - Clean UI

---

## Summary

**Total Changes:** 10
**Critical Fixes:** 2
**Already Implemented in Android:** 2
**UI Improvements:** 6
**Not Applicable:** 1

**Estimated Implementation Time:** 4-6 hours

**Files to Modify:**
1. `AddEditShiftViewModel.kt` or `AddShiftViewModel.kt` (shift status logic)
2. Calculator screen (tip-out tab "%" placement)
3. Settings/Targets screen (layout consolidation)
4. Subscription screen (marketing copy update)
5. Create `SplashScreen.kt` (new file)
6. Settings screen (subscription card visibility)

**No Changes Needed:**
- Sales target loading (already correct)
- Sales target UI layout (already correct)
- Subscription flow (different architecture)

**New Features Added:**
- Splash screen with branding
- Improved subscription marketing
- Conditional subscription card display

**Translation Coverage:**
All new text has been translated into:
- ✅ English
- ✅ French (Français)
- ✅ Spanish (Español)

---

## Related Documentation

- **Detailed Guide:** `/Docs/ANDROID_SHIFT_STATUS_PRESERVATION_FIX.md`
- **PRD Update:** `/Docs/ProTip365_PRD_v3.0_Detailed_Specs.md` (v4.1)
- **iOS Changes:** Git commit history for October 2, 2025

---

## Questions or Issues?

If you encounter any issues during implementation:
1. Check the iOS code for exact implementation details
2. Refer to the detailed guides in `/Docs/`
3. Test thoroughly against the checklist above
4. Verify database queries return expected data

**End of Android Implementation Guide**
