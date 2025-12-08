# iOS "Add Shift" Screen - Complete Implementation Guide for Android

## Overview
The Add/Edit Shift screen allows users to create and manage scheduled shifts with comprehensive validation, overlap detection, and cross-day support.

---

## 1. UI Layout & Structure

### Header Layout (iOS 26 Style)
**File:** `AddShiftView.swift` (lines 115-181)

**Layout:**
```
[Cancel (X)] -------- [Title] -------- [Delete (🗑️)] [Save (✓)]
```

**Components:**
- **Cancel Button:** Circle background with X icon (left)
- **Title:** "Add Shift" (new) or "Edit Shift" (editing mode)
- **Delete Button:** Circle background with trash icon, RED color (only visible when editing)
- **Save Button:** Circle background with checkmark icon (right), shows spinner when loading

**Styling:**
- All buttons: 32x32 circular buttons with systemGray5 background
- Header padding: 20px horizontal, 16px vertical
- Background: systemGroupedBackground

---

## 2. Main Form Card Structure

**File:** `AddShiftView.swift` (lines 184-233)

The form is a single card with rounded corners (12px) containing 4 sections:

### Section 1: Shift Details (`ShiftDetailsSection.swift`)
**Components:**
1. **Employer Selection Row**
   - Label: "Employer" (left)
   - Button: Selected employer name or "Select Employer" (right)
   - Background: systemGroupedBackground with rounded corners
   - Inline Wheel Picker (expands below when clicked)
   - Auto-closes 0.5s after selection

2. **Comments/Notes Field**
   - Label: "Comments"
   - Multi-line text field (2 lines max)
   - Placeholder: "Add notes..."
   - Background: systemGroupedBackground with rounded corners

**Divider between each row**

---

### Section 2: Time Selection (`ShiftTimeSection.swift`)
**Components:**

1. **Starts Row**
   - Label: "Starts" (left)
   - Two buttons side-by-side:
     - Date button (e.g., "Jan 15, 2025")
     - Time button (e.g., "8:00 AM")
   - Inline date/time pickers expand below when clicked

2. **Ends Row**
   - Label: "Ends" (left)
   - Two buttons side-by-side:
     - **Separate** End Date button (supports cross-day shifts)
     - Time button
   - Inline date/time pickers expand below when clicked

3. **Lunch Break Row**
   - Label: "Lunch Break" (left)
   - Button: Selected option (right)
   - Options: None, 15 min, 30 min, 45 min, 60 min
   - Inline picker expands below

**Important:** Only ONE picker can be open at a time. Opening a new picker closes all others with animation.

**Dividers between each row**

---

### Section 3: Alert Section (`ShiftAlertSection.swift`)
**Components:**
1. **Alert Row**
   - Label with icon: "Alert" + bell icon (left)
   - **Text color: PRIMARY (black)** ← UPDATED (was secondary/grey)
   - Selected value (right): e.g., "1 hour before"
   - Chevron indicator (right)

2. **Inline Alert Picker**
   - Options:
     - "None"
     - "15 minutes before"
     - "30 minutes before"
     - "1 hour before"
     - "1 day before"
   - Selected item: checkmark + accent color background
   - Auto-closes after selection

**Divider above**

---

### Section 4: Summary Section (`ShiftSummarySection.swift`)
**Components:**
1. **Expected Hours Row**
   - Label: "Shift Expected Hours" (**BOLD**)
   - Value: "X.X hours" (**BOLD**)
   - Real-time calculation: (end - start - lunch break)
   - Handles cross-day shifts automatically

**Divider above**

---

## 3. Core Logic & Data Management

### Data Manager (`AddShiftDataManager.swift`)

#### State Variables
```swift
@Published var selectedDate: Date
@Published var endDate: Date  // Separate for cross-day support
@Published var startTime: Date
@Published var endTime: Date
@Published var selectedLunchBreak: String = "None"
@Published var selectedAlert: String = "60 minutes"  // Default from user preferences
@Published var comments: String
@Published var selectedEmployer: Employer?
@Published var employers: [Employer]
@Published var isLoading: Bool
@Published var isInitializing: Bool
@Published var showErrorAlert: Bool
@Published var errorMessage: String
```

---

### 3.1 Initialization Logic

**File:** `AddShiftDataManager.swift` (lines 157-363)

**Initialization Sequence:**
1. **Load Employers** (async)
   - Fetch from database
   - Set default/selected employer

2. **Load User Defaults** (async)
   - Fetch `default_alert_minutes` from `users_profile`
   - Convert to alert string (15/30/60/1440 minutes)
   - Default: 60 minutes if not set

3. **Setup Times**
   - **New Shift Mode:**
     - Use `initialDate` if provided, otherwise today
     - Start time: 8:00 AM
     - End time: Start + 8 hours (4:00 PM)
     - End date: Same as start date

   - **Edit Mode:**
     - Parse shift_date (yyyy-MM-dd format)
     - Parse start_time (HH:mm:ss or HH:mm format)
     - Parse end_time (HH:mm:ss or HH:mm format)
     - **Cross-day detection:** If endTime minutes < startTime minutes, set endDate = startDate + 1 day
     - Load lunch break, employer, notes, alert preference

4. Mark `isInitializing = false`

---

### 3.2 Time Validation Logic

**File:** `AddShiftDataManager.swift` (lines 113-154)

**Auto-validation triggers:**
- When `selectedDate` changes
- When `endDate` changes
- When `startTime` changes

**Validation Rules:**
1. **Create full DateTime objects** using selectedDate/endDate + time components
2. Calculate time difference
3. **If end is > 1 hour before start:** Set endDate to nextDay automatically
4. **If same day and end ≤ start:** Set endTime = startTime + 8 hours
5. **Cross-day shifts are allowed** (overnight shifts)

---

### 3.3 Expected Hours Calculation

**File:** `AddShiftDataManager.swift` (lines 76-111)

**Algorithm:**
```kotlin
// Pseudo-code for Android
1. Combine selectedDate + startTime → fullStartDateTime
2. Combine endDate + endTime → fullEndDateTime
3. Calculate: timeInterval = fullEndDateTime - fullStartDateTime
4. Convert to minutes
5. If negative, add 24 hours (edge case handling)
6. Subtract lunchBreakMinutes
7. Return max(0, totalMinutes / 60.0)
```

**Real-time:** Updates automatically as user changes times/dates/lunch break

---

### 3.4 Overlap Detection

**File:** `AddShiftDataManager.swift` (lines 366-463)

**Called:** Before saving shift

**Algorithm:**
1. Format shift_date as "yyyy-MM-dd"
2. Format times as "HH:mm"
3. Query database for all shifts on same date for current user
4. **Skip current shift if editing**
5. For each existing shift:
   - Convert times to minutes since midnight
   - Check 4 overlap conditions:
     ```
     a. newStart >= existingStart && newStart < existingEnd
     b. newEnd > existingStart && newEnd <= existingEnd
     c. newStart <= existingStart && newEnd >= existingEnd
     d. existingStart <= newStart && existingEnd >= newEnd
     ```
6. If overlap found:
   - Fetch employer name
   - Show localized error with employer name and time range
   - Return `true` (has overlap)
7. If no overlap: Return `false`

**Error Message Format:**
- EN: "This shift overlaps with an existing shift at [Employer] from [time] to [time]"
- FR: "Ce quart de travail chevauche avec un quart existant chez [Employer] de [time] à [time]"
- ES: "Este turno se superpone con un turno existente en [Employer] de [time] a [time]"

---

### 3.5 Save Logic

**File:** `AddShiftDataManager.swift` (lines 465-500+)

**Validation Order:**
1. Check employer selected → Error if not
2. **Check for overlapping shifts** → Block save if overlap
3. Check subscription status (if creating new shift) → Block if no premium access
4. Set `isLoading = true`
5. Save to database (create or update ExpectedShift)
6. Dismiss view on success

---

## 4. Localization Updates

### Updated Strings
**File:** `AddShiftLocalization.swift` (lines 78-84)

**Changed:**
- **English:** "New Shift" → "Add Shift"
- **French:** "Nouveau quart" → "Ajouter un quart"
- **Spanish:** "Nuevo turno" → "Agregar turno"

### All Localized Strings Needed:
```
- "Add Shift" / "Edit Shift"
- "Employer" / "Select Employer"
- "Comments" / "Add notes..."
- "Starts" / "Ends"
- "Lunch Break" / "Select Lunch Break"
- "Alert" / "Select Alert"
- "Shift Expected Hours" / "hours"
- "Delete Shift" / "Are you sure you want to delete this shift?"
- "Delete" / "Cancel"
- "Error Saving Shift" / "OK"
- "Please select an employer"
- "Schedule Conflict"
- Overlap error message (with employer name and times)
```

**Lunch Break Options:**
- "None" / "Aucune" / "Ninguna"
- "15 min" / "15 minutes" / "15 minutos"
- "30 min" / "30 minutes" / "30 minutos"
- "45 min" / "45 minutes" / "45 minutos"
- "60 min" / "60 minutes" / "60 minutos"

**Alert Options:**
- "None" / "Aucune" / "Ninguna"
- "15 minutes before" / "15 minutes avant" / "15 minutos antes"
- "30 minutes before" / "30 minutes avant" / "30 minutos antes"
- "1 hour before" / "1 heure avant" / "1 hora antes"
- "1 day before" / "1 jour avant" / "1 día antes"

---

## 5. UI Styling Updates

### Alert Text Color Change
**File:** `ShiftAlertSection.swift` (line 29)

**Before:** `.foregroundColor(.secondary)` (grey)
**After:** `.foregroundColor(.primary)` (black/white based on theme)

**Android Equivalent:**
- Before: `color = MaterialTheme.colorScheme.onSurfaceVariant`
- After: `color = MaterialTheme.colorScheme.onSurface`

**Rationale:** Improved readability and consistency with other form values

---

## 6. Delete Functionality

**File:** `AddShiftView.swift` (lines 38-57, 139-151)

**Behavior:**
- Only visible when editing (not creating new)
- Shows confirmation dialog
- Deletes both:
  1. Shift entry (if exists)
  2. Expected shift
- Invalidates dashboard cache
- Dismisses view on success

**Confirmation Dialog:**
- Title: "Delete Shift"
- Message: "Are you sure you want to delete this shift?"
- Buttons: "Delete" (destructive/red) and "Cancel"

---

## 7. Android Implementation Checklist

### UI Components Needed:
- [ ] Circular button with icon (32dp) using FloatingActionButton or custom composable
- [ ] Inline expandable pickers (animated) with AnimatedVisibility
- [ ] Card with rounded corners (12dp) using Card composable
- [ ] Divider lines between rows using Divider()
- [ ] Multi-line text field (2 lines max) using TextField with maxLines = 2
- [ ] Date/time formatters (medium date, short time) using SimpleDateFormat
- [ ] Loading spinner in button using CircularProgressIndicator

### Logic Components Needed:
- [ ] Overlap detection algorithm (same 4 conditions as iOS)
- [ ] Cross-day shift support (separate start/end dates)
- [ ] Real-time hours calculation (using derivedStateOf)
- [ ] Auto-validation of end time (using LaunchedEffect)
- [ ] User defaults loading (alert preference from database)
- [ ] Employer management (fetch and selection)
- [ ] Subscription status check (before allowing save)
- [ ] Error alert dialogs (using AlertDialog)

### State Management:
```kotlin
// ViewModel state
var selectedDate by mutableStateOf(LocalDate.now())
var endDate by mutableStateOf(LocalDate.now())
var startTime by mutableStateOf(LocalTime.of(8, 0))
var endTime by mutableStateOf(LocalTime.of(16, 0))
var selectedLunchBreak by mutableStateOf("None")
var selectedAlert by mutableStateOf("60 minutes")
var comments by mutableStateOf("")
var selectedEmployer by mutableStateOf<Employer?>(null)
var employers by mutableStateOf<List<Employer>>(emptyList())
var isLoading by mutableStateOf(false)
var isInitializing by mutableStateOf(true)
var showErrorAlert by mutableStateOf(false)
var errorMessage by mutableStateOf("")

// Picker expansion states
var showEmployerPicker by mutableStateOf(false)
var showStartDatePicker by mutableStateOf(false)
var showEndDatePicker by mutableStateOf(false)
var showStartTimePicker by mutableStateOf(false)
var showEndTimePicker by mutableStateOf(false)
var showLunchBreakPicker by mutableStateOf(false)
var showAlertPicker by mutableStateOf(false)
```

### String Resources:
- [ ] Update "New Shift" → "Add Shift" in strings.xml (EN/FR/ES)
- [ ] Overlap error messages (localized with placeholders)
- [ ] All form labels (Employer, Comments, Starts, Ends, Lunch Break, Alert)
- [ ] Lunch break options (None, 15 min, 30 min, 45 min, 60 min)
- [ ] Alert options (None, 15/30/60 minutes before, 1 day before)
- [ ] Delete confirmation messages

### Data Models:
```kotlin
data class ExpectedShift(
    val id: UUID?,
    val user_id: UUID,
    val employer_id: UUID?,
    val shift_date: String,  // yyyy-MM-dd
    val start_time: String,  // HH:mm:ss
    val end_time: String,    // HH:mm:ss
    val expected_hours: Double,
    val hourly_rate: Double,
    val lunch_break_minutes: Int?,
    val status: String,  // planned, completed, missed
    val alert_minutes: Int?,
    val notes: String?,
    val created_at: Instant?,
    val updated_at: Instant?
)

data class ShiftEntry(
    val id: UUID?,
    val shift_id: UUID,
    val user_id: UUID,
    val actual_start_time: String,
    val actual_end_time: String,
    val actual_hours: Double,
    val sales: Double?,
    val tips: Double?,
    val cash_out: Double?,
    val other: Double?,
    val notes: String?,
    val created_at: Instant?,
    val updated_at: Instant?
)

data class ShiftWithEntry(
    val expected_shift: ExpectedShift,
    val entry: ShiftEntry?
)
```

---

## 8. Key Differences from Previous Implementation

1. **Title changed** from "New Shift" to "Add Shift"
2. **Alert text color** is now primary/black (not secondary/grey)
3. **Separate end date** field for cross-day shift support
4. **Only one picker open** at a time with proper animations
5. **Real-time validation** of end time
6. **Overlap detection** before save
7. **User default alert** preference loaded from database
8. **Auto-close pickers** after selection (0.5s delay for employer, immediate for others)

---

## 9. Animation & UX Details

### Picker Animations
- Use `AnimatedVisibility` with `fadeIn()` + `slideInVertically()` for expansion
- Use `fadeOut()` + `slideOutVertically()` for collapse
- Duration: 300ms with easeInOut easing

### Picker Behavior
- Tapping any picker closes all others first (animated)
- Employer picker: Auto-closes 0.5s after selection
- Other pickers: Remain open until user taps elsewhere or selects another picker

### Loading States
- Show loading spinner during initialization
- Replace save button checkmark with spinner during save
- Disable all inputs during loading

---

## 10. Error Handling

### Validation Errors
1. **No employer selected:** "Please select an employer"
2. **Shift overlap:** Custom message with employer and time details
3. **No subscription:** "Please subscribe to ProTip365 Premium to add shifts."

### Display Method
- Use AlertDialog with:
  - Title: Error type (e.g., "Schedule Conflict")
  - Message: Detailed error message
  - Single "OK" button to dismiss

---

## 11. Navigation Flow

### Entry Points
1. **Calendar View:** "Add Shift" button
   - Passes selected date as `initialDate`
2. **Shift List:** Tap existing shift
   - Passes `ShiftWithEntry` for editing

### Exit Points
1. **Cancel button:** Dismiss without saving
2. **Save success:** Dismiss and refresh parent view
3. **Delete success:** Dismiss and refresh parent view

---

## 12. Testing Checklist

### Functional Tests
- [ ] Create new shift with all fields
- [ ] Edit existing shift
- [ ] Delete shift with confirmation
- [ ] Overlap detection (same employer, different employers)
- [ ] Cross-day shift creation (e.g., 11 PM - 3 AM)
- [ ] Lunch break calculation
- [ ] Alert preference loading
- [ ] Real-time hours calculation
- [ ] Form validation (employer required)
- [ ] Subscription check for new shifts

### UI Tests
- [ ] All pickers open/close correctly
- [ ] Only one picker open at a time
- [ ] Animations smooth (300ms)
- [ ] Loading states display properly
- [ ] Error dialogs show correct messages
- [ ] Multi-line comments field (2 lines max)
- [ ] Date/time formatting matches locale

### Localization Tests
- [ ] All strings in EN/FR/ES
- [ ] Error messages localized
- [ ] Date/time formats locale-aware
- [ ] Lunch break options localized
- [ ] Alert options localized

---

## 13. Files Reference

### iOS Implementation Files
- `AddShiftView.swift` - Main view with header and form card
- `AddShiftDataManager.swift` - Business logic and state management
- `AddShiftLocalization.swift` - All localized strings
- `ShiftDetailsSection.swift` - Employer and comments section
- `ShiftTimeSection.swift` - Date/time selection section
- `ShiftAlertSection.swift` - Alert preference section
- `ShiftSummarySection.swift` - Expected hours display

### Android Target Files (to create/update)
- `AddEditShiftScreen.kt` - Main composable screen
- `AddEditShiftViewModel.kt` - ViewModel with business logic
- `ShiftRepository.kt` - Database operations
- `strings.xml` (en/fr/es) - Localized strings
- `ShiftModels.kt` - Data models

---

## End of Guide

This guide provides complete implementation details for the Add/Edit Shift screen on Android, matching the iOS implementation exactly. Follow the checklist to ensure feature parity.
