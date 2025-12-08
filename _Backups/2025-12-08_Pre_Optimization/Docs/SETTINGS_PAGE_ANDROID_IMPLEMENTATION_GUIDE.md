# iOS Settings Page - Complete Implementation Guide for Android

## Overview
The Settings screen is the central configuration hub for ProTip365, allowing users to manage their profile, work defaults, security, targets, subscription, and account settings. iOS is the source of truth for all layouts, logic, and validation.

---

## 1. Page Structure & Layout

### Header Layout
**File:** `SettingsView.swift` (lines 159-204)

**Layout:**
```
[Cancel (X)] -------- [Settings] -------- [Save (✓)]
```

**Components:**
- **Cancel Button (Left):**
  - X icon
  - Action: Check for unsaved changes → Show alert if changes exist, otherwise navigate back

- **Title (Center):**
  - "Settings" (localized)

- **Save Button (Right):**
  - Shows checkmark icon (when changes detected)
  - Shows spinner when saving
  - Color: Accent blue when changes exist, gray when no changes
  - Disabled when: No changes OR currently saving

**Header Styling:**
- Padding: 20px horizontal, 16px vertical
- Background: systemGroupedBackground

---

## 2. Unsaved Changes Detection

**File:** `SettingsView.swift` (lines 301-347)

### Change Detection Logic

**State Management:**
- Store original values when page loads (`OriginalSettings` struct)
- Compare current values with original on every change
- Enable/disable save button based on comparison

**Tracked Fields:**
```kotlin
data class OriginalSettings(
    val userName: String,
    val defaultHourlyRate: String,
    val averageDeductionPercentage: String,
    val tipTargetPercentage: String,
    val targetTipDaily: String,
    val targetTipWeekly: String,
    val targetTipMonthly: String,
    val targetSalesDaily: String,
    val targetSalesWeekly: String,
    val targetSalesMonthly: String,
    val targetHoursDaily: String,
    val targetHoursWeekly: String,
    val targetHoursMonthly: String,
    val weekStartDay: Int,
    val useMultipleEmployers: Boolean,
    val hasVariableSchedule: Boolean,
    val defaultEmployerId: UUID?,
    val defaultAlertString: String,
    val language: String
)
```

**Unsaved Changes Alert:**
- **Triggered:** When user taps Cancel/Back with unsaved changes
- **Title:** "Unsaved Changes"
- **Message:** "You have unsaved changes. Would you like to save them?"
- **Actions:**
  - "Save" → Save settings, then navigate back
  - "Discard" (destructive/red) → Navigate back without saving
  - "Cancel" → Stay on settings page

---

## 3. Section Order & Content

**File:** `SettingsView.swift` (lines 206-297)

### Section 1: App Info & Language
**File:** `AppInfoSection.swift`

**Layout:**
1. **Section Header:**
   - Icon: `person.circle` (20pt, monochrome)
   - Title: "Language"

2. **App Logo & Version:**
   - Logo: 60x60 with 12px rounded corners
   - App Name: "ProTip" + "365" (title2, bold)
   - Version: "v{version} ({build})" (subheadline, secondary color)

3. **How to Use Button:**
   - Icon: Help/question mark (20pt, secondary)
   - Text: "How to Use"
   - Action: Opens onboarding flow
   - Right arrow indicator

4. **Language Picker:**
   - Style: Segmented control
   - Options: "English" | "Français" | "Español"
   - Tags: "en" | "fr" | "es"
   - Full width
   - **Instant save to database** when changed

**Styling:**
- White background
- Rounded corners (12px)
- Shadow: black 5% opacity, radius 3, offset (0, 1)
- Padding: 16px all sides

---

### Section 2: Profile
**File:** `ProfileSettingsSection.swift`

**Layout:**
1. **Section Header:**
   - Icon: `person.fill` (20pt, monochrome)
   - Title: "Profile"

2. **Name Field:**
   - Label: "Name" (left, primary color)
   - Input: Text field (right-aligned, 200px width)
   - Placeholder: "Enter your name"
   - Background: Liquid glass form style
   - Padding: 8px
   - Validation: Can be empty (stored as NULL in database)

3. **Email Field (Read-only):**
   - Label: "Email" (left, primary color)
   - Value: User email (right, secondary color)
   - No input field (display only)

**Styling:**
- White background
- Rounded corners (12px)
- Shadow: black 5% opacity, radius 3, offset (0, 1)
- Padding: 16px all sides

---

### Section 3: Work Defaults
**File:** `WorkDefaultsSection.swift`

**Layout:**
1. **Section Header:**
   - Icon: Briefcase/employers icon (20pt, monochrome)
   - Title: "Work Defaults"

2. **Hourly Rate:**
   - Label: "Hourly Rate" (left)
   - Input: "$" prefix + text field
   - Keyboard: Decimal pad
   - Placeholder: "15.00"
   - Width: 100px
   - Format: 2 decimal places
   - **Clear field behavior:** When user taps and value is "15.00" or "0.00", clear to empty string
   - Validation: Must be positive number

3. **Average Deduction Percentage:**
   - Label: "Average Deduction %" (left)
   - Input: Text field + "%" suffix (implied)
   - Keyboard: Decimal pad
   - Placeholder: "30"
   - Width: 100px
   - Format: Whole number (0-100)
   - **Validation:** Clamp between 0-100 on input
   - **Clear field behavior:** When user taps and value is "30" or "0", clear to empty string

4. **Info Box - Deduction Explanation:**
   - Background: Blue 10% opacity
   - Rounded corners: 8px
   - Icon: Info circle (caption size)
   - Title: "Average Deduction Note" (bold, caption)
   - Message: Explanation text (caption, secondary color)
   - Padding: 12px
   - Multi-line text support

5. **Use Multiple Employers Toggle:**
   - Style: Liquid glass toggle
   - Label: "Use Multiple Employers"
   - Description: "Track shifts across different employers"
   - Action: Stores to `@AppStorage` AND database
   - **Effect:** Shows/hides default employer picker

6. **Variable Schedule Toggle:**
   - Style: Liquid glass toggle
   - Label: "Variable Schedule"
   - Description: "Enable if your schedule changes week to week"
   - Action: Stores to database
   - **Effect:** Hides weekly/monthly target fields when enabled

7. **Info Box - Variable Schedule (when enabled):**
   - Background: Blue 10% opacity
   - Rounded corners: 8px
   - Icon: Info circle
   - Title: "Variable Schedule Enabled"
   - Message: "Weekly and monthly targets are hidden because your schedule varies"
   - Only visible when `hasVariableSchedule = true`

8. **Default Employer Picker (conditional):**
   - **Visible only if:** `useMultipleEmployers = true` AND employers list is not empty
   - Label: "Default Employer" (left)
   - Button: Shows selected employer name or "None"
   - Expands to wheel picker below when tapped
   - Picker height: 120px
   - Options: "None" + all employers
   - **Auto-close:** 0.5s after selection
   - Animation: Fade + scale (0.95)

9. **Week Start Day Picker:**
   - Label: "Week Start Day" (left)
   - Button: Shows selected day (localized)
   - Expands to wheel picker below when tapped
   - Picker height: 120px
   - Options: Sunday through Saturday (0-6)
   - Localized day names:
     - EN: Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
     - FR: Dimanche, Lundi, Mardi, Mercredi, Jeudi, Vendredi, Samedi
     - ES: Domingo, Lunes, Martes, Miércoles, Jueves, Viernes, Sábado
   - **Auto-close:** 0.5s after selection

10. **Default Alert Picker:**
    - Label: "Default Alert" (left)
    - Button: Shows selected alert (localized)
    - Expands to wheel picker below when tapped
    - Picker height: 120px
    - Options:
      - "None" / "Aucune" / "Ninguna"
      - "15 minutes before" / "15 minutes avant" / "15 minutos antes"
      - "30 minutes before" / "30 minutes avant" / "30 minutos antes"
      - "1 hour before" / "1 heure avant" / "1 hora antes"
      - "1 day before" / "1 jour avant" / "1 día antes"
    - **Auto-close:** 0.5s after selection
    - **Stored as:** Integer minutes (0, 15, 30, 60, 1440) in database

**Picker Behavior:**
- Only ONE picker can be open at a time
- Opening a picker closes all others with animation
- Animation: Fade + scale (duration 0.3s, easeInOut)

**Styling:**
- White background (systemBackground)
- Rounded corners (12px)
- Shadow: black 5% opacity, radius 3, offset (0, 1)
- Padding: 16px all sides

---

### Section 4: Security Settings
**File:** `SecuritySettingsSection.swift`

**Layout:**
1. **Section Header:**
   - Icon: `lock.shield` (20pt, monochrome)
   - Title: "Security"

2. **App Lock Security Options:**
   - Title: "App Lock Security" (headline)
   - **Option 1: None**
     - Icon: `lock.open`
     - Text: "None"
     - Selection indicator: Blue checkmark circle when selected
     - Action when selected FROM another type: Requires authentication to disable

   - **Option 2: PIN Code**
     - Icon: `lock.fill`
     - Text: "PIN Code"
     - Selection indicator: Blue checkmark circle when selected
     - Action when selected from None: Shows PIN setup sheet

   - **Option 3: Biometric (Face ID / Touch ID)**
     - **Only show if device supports biometrics**
     - Icon: `faceid` or `touchid` (based on device capability)
     - Text: "Face ID" or "Touch ID" (dynamic based on device)
     - Color: Blue when selected, secondary when not
     - Selection indicator: Blue checkmark circle when selected
     - Action when selected from None: Shows PIN setup sheet first (PIN is fallback)

3. **Change PIN Button (conditional):**
   - **Visible only if:** Current security type is PIN
   - Icon: `key` (secondary color)
   - Text: "Change PIN"
   - Right arrow indicator
   - Action: Opens PIN setup sheet
   - Style: Secondary button with liquid glass form

**Security Logic:**

**Disabling Security (None selected):**
1. Check if security is currently enabled
2. Require authentication (biometric or PIN)
3. If authentication succeeds: Disable all security
4. If authentication fails: Revert selection to current type

**Enabling PIN:**
1. If coming from None: Show PIN setup sheet
2. If coming from Biometric: Just switch to PIN (no sheet)

**Enabling Biometric:**
1. Check device capability
2. If coming from None: Show PIN setup sheet first (PIN as fallback)
3. If coming from PIN: Just enable biometric
4. Store security type preference

**PIN Setup Sheet:**
- Modal sheet presentation
- Navigation bar with "Cancel" button
- Title: "Security Setup"
- Step 1: "Enter PIN"
  - 4-digit PIN
  - Visual: 4 circles (filled = entered, empty = remaining)
  - Number pad: 1-9, 0, delete, checkmark
  - Auto-advance when 4 digits entered
- Step 2: "Confirm PIN"
  - Same UI
  - Validation: Must match first PIN
  - Error if mismatch: "PINs don't match. Please try again." → Reset to step 1
  - Success: Save PIN, enable selected security type, dismiss sheet

**Number Pad Layout:**
```
[1] [2] [3]
[4] [5] [6]
[7] [8] [9]
[⌫] [0] [✓]
```
- Each button: 80x80 circle
- Background: Ultra thin material
- Delete button: Red icon
- Checkmark button: Green icon, disabled until 4 digits entered

**Styling:**
- White background (systemBackground)
- Rounded corners (12px)
- Shadow: black 5% opacity, radius 3, offset (0, 1)
- Padding: 16px all sides

---

### Section 5: Targets
**File:** `TargetsSettingsSection.swift`

**Layout:**

**Explanation Card (separate):**
- Title: "Set Your Goals" (headline)
- Description: Explanation text (caption)
- White background
- Rounded corners (12px)
- Shadow
- Padding: 16px

**Main Targets Card:**
1. **Section Header:**
   - Icon: `target` (20pt, monochrome)
   - Title: "Your Targets"

2. **Tip Targets Subsection:**
   - Subtitle: "Tip Targets" (subheadline, medium weight)

   - **Tip Percentage Target:**
     - Label: "Tip %" (left)
     - Input: Text field + "%" suffix
     - Keyboard: Decimal pad
     - Placeholder: "15"
     - Width: 100px
     - Format: Whole number
     - Liquid glass form style

   - **Info Box:**
     - Background: Blue 10% opacity
     - Icon: Info circle
     - Title: "Tip Percentage Note"
     - Message: Explanation about tip percentage
     - Rounded corners: 8px
     - Padding: 12px

3. **Divider**

4. **Sales Targets Subsection:**
   - Subtitle: "Sales Targets" (subheadline, medium weight)

   - **Daily Sales Target:**
     - Label: "Daily" (left)
     - Input: Text field (no prefix)
     - Keyboard: Decimal pad
     - Placeholder: "500.00"
     - Width: 100px
     - Format: 2 decimal places

   - **Weekly Sales Target:**
     - **Only visible if `hasVariableSchedule = false`**
     - Label: "Weekly" (left)
     - Placeholder: "3500.00"

   - **Monthly Sales Target:**
     - **Only visible if `hasVariableSchedule = false`**
     - Label: "Monthly" (left)
     - Placeholder: "14000.00"

   - **Info Box:**
     - Background: Blue 10% opacity
     - Title: "Variable Schedule Note"
     - Message: Explanation about sales targets
     - Always visible (explains why weekly/monthly may be hidden)

5. **Divider**

6. **Hours Targets Subsection:**
   - Subtitle: "Hours Targets" (subheadline, medium weight)

   - **Daily Hours Target:**
     - Label: "Daily" (left)
     - Input: Text field
     - Keyboard: Decimal pad
     - Placeholder: "8"
     - Width: 100px
     - Format: Whole number (hours)

   - **Weekly Hours Target:**
     - **Only visible if `hasVariableSchedule = false`**
     - Label: "Weekly" (left)
     - Placeholder: "40"

   - **Monthly Hours Target:**
     - **Only visible if `hasVariableSchedule = false`**
     - Label: "Monthly" (left)
     - Placeholder: "160"

   - **Info Box:**
     - Background: Blue 10% opacity
     - Title: "Variable Schedule Note"
     - Message: Explanation about hours targets (different from sales)

**Input Field Behavior:**
- **On focus:** If value equals placeholder or "0" or "0.00", clear to empty string
- **Validation:** None (allow any positive number or empty)
- **Keyboard dismiss:** Tap outside text fields

**Conditional Visibility Logic:**
```kotlin
// Show weekly/monthly fields only when NOT variable schedule
if (!hasVariableSchedule) {
    // Show weekly and monthly target rows
} else {
    // Hide weekly and monthly target rows
}
```

**Styling:**
- White background (systemBackground)
- Rounded corners (12px)
- Shadow: black 5% opacity, radius 3, offset (0, 1)
- Padding: 16px all sides
- Spacing between cards: 20px

---

### Section 6: Support
**File:** `SupportSettingsSection.swift`

**Layout:**
1. **Section Header:**
   - Icon: `questionmark.circle` (20pt, monochrome)
   - Title: "Support"

2. **Export Data (Coming Soon):**
   - Left:
     - Text: "Export Data" (secondary color)
     - Subtext: "Coming soon" (caption, tertiary color)
   - Right:
     - Icon: Clock (caption, tertiary)
   - Disabled/non-interactive
   - Padding: 16px

3. **Divider** (white 20% opacity, height 1px)

4. **Onboarding Guide:**
   - Left:
     - Text: "Onboarding Guide"
     - Subtext: "Review the app tutorial" (caption, secondary)
   - Right:
     - Next arrow icon (caption, tertiary)
   - Action: Opens onboarding flow
   - Padding: 16px

5. **Divider**

6. **Support/Contact:**
   - Left:
     - Icon: Email (16pt, secondary, 20x20 frame)
     - Text: "Support"
     - Subtext: "support@protip365.com" (caption, secondary)
   - Right:
     - Next arrow icon (caption, secondary)
   - Action: Opens support contact sheet
   - Padding: 16px

7. **Divider** (white 20% opacity, height 0.5px)

8. **Suggest Ideas:**
   - Left:
     - Text: "Suggest Ideas"
   - Right:
     - Next arrow icon (caption, secondary)
   - Action: Opens suggestion sheet
   - Padding: 16px

**Support & Suggestion Sheets:**
- Modal sheet presentation
- Gray background (systemGroupedBackground)
- **Two states:**
  1. **Form state:**
     - Title input field
     - Message text area (multi-line)
     - Email field (pre-filled with user email)
     - Submit button
  2. **Thank you state:**
     - Success checkmark icon (large, tint color)
     - Title: "Thank You!"
     - Message: "We appreciate your feedback"
     - Auto-dismiss after showing

**Styling:**
- White background (systemBackground)
- Rounded corners (12px)
- Shadow: black 5% opacity, radius 3, offset (0, 1)
- Padding: 16px all sides

---

### Section 7: Subscription Management
**File:** `SubscriptionManagementSection.swift`

**Visibility:** **ONLY visible if user has active subscription OR is in trial period**

**Layout:**
1. **Section Header:**
   - Icon: `crown.fill` (20pt, yellow, hierarchical rendering)
   - Title: "Subscription" / "Abonnement" / "Suscripción"

2. **Subscription Status:**
   - Label: "Status" (left)
   - Right side:
     - Status icon + text
     - **If in trial:**
       - Icon: `clock.fill` (blue)
       - Text: "Trial Period" / "Période d'essai" / "Período de prueba" (blue)
     - **If subscribed:**
       - Icon: `checkmark.circle.fill` (green)
       - Text: "Premium Active" / "Premium Actif" / "Premium Activo" (green)
     - **If inactive:**
       - Icon: `xmark.circle.fill` (red)
       - Text: "Inactive" / "Inactif" / "Inactivo" (red)

3. **Trial Days Remaining (conditional):**
   - **Only visible if:** `isInTrialPeriod = true`
   - Label: "Trial Remaining" (left)
   - Value: "{N} day(s)" / "{N} jour(s)" / "{N} día(s)" (right, secondary)

4. **Manage Subscription Button:**
   - Text: "Manage Subscription" (left)
   - Icon: `arrow.up.forward.square` (right, caption, secondary)
   - Action: Opens iOS Subscription settings
   - URL: `https://apps.apple.com/account/subscriptions`

**Styling:**
- White background
- Rounded corners (12px)
- Shadow: black 5% opacity, radius 3, offset (0, 1)
- Padding: 16px all sides

**Localization:**
```kotlin
// Subscription title
EN: "Subscription"
FR: "Abonnement"
ES: "Suscripción"

// Status label
EN: "Status"
FR: "Statut"
ES: "Estado"

// Trial remaining
EN: "Trial Remaining"
FR: "Essai restant"
ES: "Prueba restante"

// Manage button
EN: "Manage Subscription"
FR: "Gérer l'abonnement"
ES: "Administrar suscripción"

// Status values
EN: "Trial Period" / "Premium Active" / "Inactive"
FR: "Période d'essai" / "Premium Actif" / "Inactif"
ES: "Período de prueba" / "Premium Activo" / "Inactivo"

// Days format
EN: "{n} day" / "{n} days"
FR: "{n} jour" / "{n} jours"
ES: "{n} día" / "{n} días"
```

---

### Section 8: Account Settings
**File:** `AccountSettingsSection.swift`

**Layout:**

**Cancel Subscription Card (conditional):**
- **Visible only if:** User has active subscription OR is in trial
- **Section Header:**
  - Icon: `creditcard.circle` (20pt, tint color, monochrome)
  - Title: "Cancel Subscription"
- **Instructions:**
  - Text 1: "To cancel your subscription, go to your Apple Account settings" (subheadline, secondary)
  - Text 2: "Your access will continue until the end of your billing period" (caption, tint color, medium weight)
- **Button:**
  - Icon: Settings gear
  - Text: "Go to Apple Account"
  - Right arrow
  - Action: Opens iOS Settings app
  - URL: `UIApplication.openSettingsURLString`
  - Tint color for all elements
- White background, rounded corners, shadow
- Padding: 16px

**Account Actions Card:**
1. **Sign Out:**
   - Text: "Sign Out" (RED color)
   - Left-aligned
   - Action: Shows confirmation alert
   - Padding: 16px

2. **Divider** (white 20% opacity, height 0.5px)

3. **Delete Account:**
   - Text: "Delete Account" (RED color)
   - Left-aligned
   - Action: Shows confirmation alert
   - Padding: 16px

**Sign Out Alert:**
- Title: "Sign Out?"
- Message: "Are you sure you want to sign out?"
- Actions:
  - "Cancel" (cancel role)
  - "Sign Out" (destructive/red role)
    - Action: Call `SupabaseManager.signOut()`
    - Post notification: `userDidSignOut`
    - Navigate to auth screen

**Delete Account Alert:**
- Title: "Delete Account?"
- Message: "This action cannot be undone. All your data will be permanently deleted."
- Actions:
  - "Cancel" (cancel role)
  - "Delete Account" (destructive/red role)
    - Action: Start deletion process

**Delete Account Process:**
1. Show loading overlay:
   - Black 70% opacity background
   - Spinner (1.5x scale, white)
   - Title: "Deleting Account..." (headline, white)
   - Message: "Please wait while we process your request." (subheadline, white 80%)
   - Background: Ultra thin material
   - Rounded corners: 20px
   - Padding: 40px

2. **Deletion Steps:**
   ```kotlin
   // Step 1: Get auth token
   val session = supabase.auth.session
   val authToken = session.accessToken

   // Step 2: Call Edge Function
   POST {SUPABASE_URL}/functions/v1/delete-user
   Headers: Authorization: Bearer {authToken}

   // Step 3: If Edge Function fails (fallback):
   // Delete from tables in order:
   - shift_entries (where user_id = userId)
   - expected_shifts (where user_id = userId)
   - employers (where user_id = userId)
   - users_profile (where user_id = userId)

   // Try RPC as last resort:
   supabase.rpc("delete_account").execute()

   // Step 4: Clear StoreKit transactions (iOS specific)
   // For Android: Clear Google Play billing cache

   // Step 5: Sign out
   supabase.auth.signOut()

   // Step 6: Post notification
   NotificationCenter.post("userDidDeleteAccount")

   // Step 7: Navigate to auth screen
   ```

3. **Error Handling:**
   - Always attempt sign out even if deletion fails
   - Always post notification to reset app
   - Log all errors for debugging

**Styling:**
- White background (systemBackground)
- Rounded corners (12px)
- Shadow: black 5% opacity, radius 3, offset (0, 1)
- Spacing between cards: 20px

---

## 4. Data Loading & Saving

### Load Sequence
**File:** `SettingsView.swift` (lines 126-147, 349-521)

**On page load (async tasks in order):**
1. **Load User Info:**
   - Fetch user email from Supabase auth session
   - Store in `userEmail` state

2. **Load Settings from Database:**
   - Query `users_profile` table
   - Fields loaded:
     ```sql
     SELECT
       default_hourly_rate,
       average_deduction_percentage,
       tip_target_percentage,
       target_tip_daily,
       target_tip_weekly,
       target_tip_monthly,
       target_sales_daily,
       target_sales_weekly,
       target_sales_monthly,
       target_hours_daily,
       target_hours_weekly,
       target_hours_monthly,
       week_start,
       name,
       use_multiple_employers,
       has_variable_schedule,
       default_employer_id,
       default_alert_minutes
     FROM users_profile
     WHERE user_id = $userId
     ```

   - **Format conversions:**
     - Numbers → Strings for display
     - 0 values → Empty strings
     - Alert minutes → Alert string ("15 minutes", "60 minutes", etc.)
     - UUID string → UUID object

3. **Load Employers:**
   - Query `employers` table
   - Filter: `user_id = currentUserId`
   - Order: By name
   - Store in `employers` list

4. **Load Shifts (for export):**
   - Fetch last 2 years of shifts with entries
   - Use `fetchShiftsWithEntries()` method
   - Store in `shifts` list

5. **Store Original Values:**
   - Create snapshot of all loaded values
   - Used for change detection

### Save Logic
**File:** `SettingsView.swift` (lines 523-613)

**Triggered:** User taps Save button

**Process:**
1. Set `isSaving = true` (shows spinner)

2. **Build update object:**
   ```kotlin
   data class ProfileUpdate(
       val default_hourly_rate: Double,
       val average_deduction_percentage: Double, // Clamped 0-100
       val tip_target_percentage: Double,
       val target_sales_daily: Double,
       val target_sales_weekly: Double, // 0 if variable schedule
       val target_sales_monthly: Double, // 0 if variable schedule
       val target_hours_daily: Double,
       val target_hours_weekly: Double, // 0 if variable schedule
       val target_hours_monthly: Double, // 0 if variable schedule
       val language: String,
       val preferred_language: String, // Same as language
       val week_start: Int,
       val name: String?, // NULL if empty
       val use_multiple_employers: Boolean,
       val has_variable_schedule: Boolean,
       val default_employer_id: String?, // UUID as string or NULL
       val default_alert_minutes: Int // Converted from string
   )
   ```

3. **String to value conversions:**
   - Empty strings → 0 (for numeric fields)
   - Alert string → Minutes integer:
     - "15 minutes" → 15
     - "30 minutes" → 30
     - "60 minutes" → 60
     - "1 day before" → 1440
     - "None" → 0
   - Average deduction: Clamp to 0-100
   - Variable schedule: Force weekly/monthly to 0

4. **Database update:**
   ```sql
   UPDATE users_profile
   SET {all_fields}
   WHERE user_id = $userId
   ```

5. **On success:**
   - Set `isSaving = false`
   - Change save button text to "Saved!" for 2 seconds
   - Update original values (reset change detection)
   - Trigger haptic feedback (light impact)
   - Stay on settings page

6. **On error:**
   - Set `isSaving = false`
   - Show error alert
   - Log error
   - Keep changes (allow user to retry)

### Validation Rules

**Hourly Rate:**
- Type: Decimal (2 decimal places)
- Min: > 0
- Format: Currency

**Average Deduction:**
- Type: Integer
- Min: 0
- Max: 100
- Enforcement: Real-time clamping on input

**Tip Percentage:**
- Type: Decimal
- Min: 0
- Max: 100
- No enforcement (just target)

**Sales Targets:**
- Type: Decimal (2 decimal places)
- Min: 0
- No max

**Hours Targets:**
- Type: Integer
- Min: 0
- No max

**Week Start:**
- Type: Integer (0-6)
- Represents: Sunday (0) through Saturday (6)

**Name:**
- Type: String
- Can be empty (stored as NULL)
- No max length enforced in UI

---

## 5. Liquid Glass Form Styling

**Custom modifier used throughout:**
```swift
.liquidGlassForm()
```

**Appearance:**
- Background: Light glass effect
- Rounded corners: 8px
- Subtle shadow or border
- Used for: Text fields, picker buttons, toggle backgrounds

**Android Equivalent:**
```kotlin
// Use Material 3 outlined text field or similar
OutlinedTextField(
    modifier = Modifier
        .background(
            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
            shape = RoundedCornerShape(8.dp)
        )
)
```

---

## 6. Android Implementation Checklist

### UI Components Needed:
- [ ] Header with cancel/save buttons
- [ ] Unsaved changes detection system
- [ ] Unsaved changes alert dialog
- [ ] Scrollable content with sections
- [ ] Segmented control for language picker
- [ ] Text fields with custom formatting (currency, percentage)
- [ ] Toggles with descriptions (Switch + text)
- [ ] Expandable wheel pickers (animated)
- [ ] Info boxes (colored background with icon and text)
- [ ] Radio button group for security options
- [ ] PIN setup bottom sheet with number pad
- [ ] Biometric authentication prompt
- [ ] Loading overlay (for account deletion)
- [ ] Section cards with headers
- [ ] Navigation to external URLs (Apple subscriptions, settings)

### State Management Needed:
- [ ] All form field values (strings, booleans, integers)
- [ ] Original values snapshot for change detection
- [ ] Picker expansion states (one at a time)
- [ ] Loading states (saving, deleting)
- [ ] Error states and messages
- [ ] Security type selection
- [ ] Subscription status from manager

### Logic Components Needed:
- [ ] Load user profile from database
- [ ] Load employers list
- [ ] Save profile updates to database
- [ ] Change detection (compare with original)
- [ ] Input validation (hourly rate, deduction %, etc.)
- [ ] Format conversions (string ↔ number, alert string ↔ minutes)
- [ ] Conditional visibility (variable schedule, multiple employers, subscription)
- [ ] Picker auto-close after selection
- [ ] Security type change handling
- [ ] PIN setup and validation
- [ ] Biometric capability check
- [ ] Account deletion flow
- [ ] Sign out flow
- [ ] Navigation to external URLs

### Database Operations:
```kotlin
// Load profile
suspend fun loadUserProfile(userId: UUID): UserProfile {
    return supabase
        .from("users_profile")
        .select()
        .eq("user_id", userId)
        .single()
        .decodeAs<UserProfile>()
}

// Save profile
suspend fun saveUserProfile(userId: UUID, updates: ProfileUpdate) {
    supabase
        .from("users_profile")
        .update(updates)
        .eq("user_id", userId)
        .execute()
}

// Load employers
suspend fun loadEmployers(userId: UUID): List<Employer> {
    return supabase
        .from("employers")
        .select()
        .eq("user_id", userId)
        .order("name")
        .decodeList<Employer>()
}
```

### String Resources (EN/FR/ES):
- [ ] All section titles
- [ ] All field labels
- [ ] All button texts
- [ ] All alert titles and messages
- [ ] All info box texts
- [ ] All placeholder texts
- [ ] Week day names
- [ ] Alert option labels
- [ ] Security option labels
- [ ] Subscription status texts

---

## 7. Key Differences from Current Android

### Missing Features to Add:
1. **Unsaved changes detection** - Track original values and compare
2. **Conditional subscription section** - Only show for active subscribers
3. **Variable schedule logic** - Hide weekly/monthly targets when enabled
4. **Multiple employers toggle** - Show/hide default employer picker
5. **Security options** - Full PIN/biometric implementation
6. **Week start day picker** - With localized day names
7. **Default alert picker** - With localized options
8. **Liquid glass form styling** - Custom form field appearance
9. **Auto-close pickers** - 0.5s delay after selection
10. **Info boxes** - Colored explanatory boxes throughout
11. **Cancel subscription card** - Instructions for iOS subscription management
12. **Account deletion** - Full flow with Edge Function + fallback
13. **Input field clearing** - Clear on focus if default/zero value
14. **Percentage clamping** - Real-time validation for deduction %
15. **Format preservation** - Proper decimal places for currency fields

### Layout Improvements Needed:
1. **Section order** - Match exact iOS order
2. **Card spacing** - 20px between major sections
3. **Padding consistency** - 16px inside cards
4. **Icon sizing** - 20pt for section headers, 28x28 frame
5. **Shadow styling** - Black 5% opacity, radius 3, offset (0,1)
6. **Divider styling** - White 20% opacity for in-card dividers
7. **Button alignment** - Proper left/right alignment in rows
8. **Multi-line support** - Info boxes and descriptions

---

## 8. Testing Checklist

### Functional Tests:
- [ ] Load settings from database on page open
- [ ] Detect unsaved changes correctly
- [ ] Show unsaved changes alert on back navigation
- [ ] Save all fields to database correctly
- [ ] Format conversions work (string ↔ number)
- [ ] Alert string ↔ minutes conversion
- [ ] Variable schedule hides weekly/monthly targets
- [ ] Multiple employers toggle shows/hides employer picker
- [ ] Only one picker open at a time
- [ ] Pickers auto-close after selection
- [ ] Default employer picker includes "None" option
- [ ] Week start day picker has all 7 days
- [ ] Security type changes work (None, PIN, Biometric)
- [ ] PIN setup validates matching PINs
- [ ] PIN setup rejects mismatched PINs
- [ ] Biometric capability check works
- [ ] Account deletion completes successfully
- [ ] Sign out clears session
- [ ] Subscription section only shows when active
- [ ] Trial days calculate correctly
- [ ] External URLs open correctly (subscriptions, settings)

### UI Tests:
- [ ] All sections render in correct order
- [ ] Card styling matches iOS (shadows, corners, padding)
- [ ] Icons are correct size and color
- [ ] Text colors match (primary, secondary, tertiary)
- [ ] Liquid glass form styling applied
- [ ] Info boxes have blue background (10% opacity)
- [ ] Dividers are subtle (white 20%)
- [ ] Save button changes color when changes detected
- [ ] Save button shows spinner when saving
- [ ] Loading overlay shows during account deletion
- [ ] PIN number pad layout matches iOS
- [ ] Security options show checkmarks when selected
- [ ] Toggles have proper labels and descriptions
- [ ] Red text for destructive actions (sign out, delete)

### Localization Tests:
- [ ] All text in EN/FR/ES
- [ ] Week day names localized
- [ ] Alert options localized
- [ ] Subscription status texts localized
- [ ] Trial days format handles plurals correctly
- [ ] Language picker changes UI immediately
- [ ] Info box texts localized

### Edge Cases:
- [ ] Empty name field (saves as NULL)
- [ ] Zero values in numeric fields
- [ ] Deduction percentage >100 (clamped to 100)
- [ ] No employers available (hide employer picker)
- [ ] Biometrics not available (hide biometric option)
- [ ] No active subscription (hide subscription section)
- [ ] Network errors during save (show error, keep changes)
- [ ] Network errors during delete (still sign out and reset)

---

## End of Guide

This comprehensive guide provides 100% implementation details for the Settings page on Android to match iOS exactly. Follow each section carefully to ensure complete feature parity.
