# Android Implementation Guide - Multiple Shift Selection Dialog

**Date:** October 2, 2025
**Feature:** Select Shift Dialog for Multiple Shifts on Same Date
**iOS Version:** v1.1.30+

---

## Overview

When a user clicks "Add Entry" or "Edit Existing Entry" on a date with **multiple shifts**, they need a way to choose which shift to work with. This document provides complete implementation details for Android.

---

## Problem Statement

**Scenario:**
- User has 2+ shifts on the same date (e.g., morning shift at Restaurant A, evening shift at Restaurant B)
- User clicks "Add Entry" button in calendar
- Current implementation: Shows dialog with "Edit Existing Entry" or "Create New Shift & Entry"
- **BUG:** Clicking "Edit Existing Entry" just picks the first shift from the database
- **Expected:** User should see a list of all shifts and choose which one to edit/add entry to

---

## Solution: Multi-Step Dialog Flow

### Flow Diagram

```
User clicks "Add Entry" on date with 2+ shifts
           ↓
    [Dialog 1: Add Entry Options]
    - Edit Existing Entry (or Add Entry to Existing Shift)
    - Create New Shift & Entry
    - Cancel
           ↓ (User clicks "Edit Existing Entry")
           ↓
    Check shift count:
    - If 1 shift → Open edit directly
    - If 2+ shifts → Show Dialog 2
           ↓
    [Dialog 2: Select Shift]
    - Restaurant A (9:00 AM - 2:00 PM)
    - Restaurant B (5:00 PM - 11:00 PM)
    - Cancel
           ↓ (User selects shift)
           ↓
    Open Add/Edit Entry sheet for selected shift
```

---

## iOS Implementation (Reference)

### Files Modified
- `ProTip365/Calendar/CalendarShiftsView.swift`

### Key Changes

**1. Added state variable:**
```swift
@State private var showingSelectShiftDialog = false
```

**2. Modified "Edit Existing Entry" button logic:**
```swift
Button(editExistingEntryText) {
    let shiftsOnDate = shiftsForDate(selectedDate)
    if shiftsOnDate.count > 1 {
        // Multiple shifts - show selection dialog
        showingSelectShiftDialog = true
        showingAddEntryDialog = false
    } else {
        // Single shift - edit directly
        selectedShiftIncomeForEdit = existingShift
    }
}
```

**3. Added shift selection dialog:**
```swift
.confirmationDialog(
    selectShiftDialogTitle,
    isPresented: $showingSelectShiftDialog
) {
    ForEach(shiftsForDate(selectedDate), id: \.id) { shift in
        Button(shiftDisplayName(for: shift)) {
            if shift.has_entry {
                selectedShiftIncomeForEdit = shift
            } else {
                selectedDateForEntry = selectedDate
                selectedShiftForEntry = shift
                showingAddEntry = true
            }
        }
    }
    Button(cancelText, role: .cancel) { }
} message: {
    Text(selectShiftDialogMessage)
}
```

**4. Helper function to format shift display:**
```swift
private func shiftDisplayName(for shift: ShiftWithEntry) -> String {
    let employer = shift.employer_name ?? noEmployerText
    let startTime = formatTimeWithoutSeconds(shift.expected_shift.start_time)
    let endTime = formatTimeWithoutSeconds(shift.expected_shift.end_time)
    return "\(employer) (\(startTime) - \(endTime))"
}
```

---

## Android Implementation

### File to Modify
**`app/src/main/java/com/protip365/app/presentation/calendar/CalendarScreen.kt`**

### Step 1: Add State Variables

```kotlin
@Composable
fun CalendarScreen(
    viewModel: CalendarViewModel,
    selectedDate: LocalDate,
    shiftsForDate: List<ShiftWithEntry>
) {
    // ... existing state variables ...

    var showAddEntryDialog by remember { mutableStateOf(false) }
    var showAddEntrySheet by remember { mutableStateOf(false) }
    var showSelectShiftDialog by remember { mutableStateOf(false) } // ✅ ADD THIS
    var entryToEdit by remember { mutableStateOf<ShiftWithEntry?>(null) }
    var preselectedShift by remember { mutableStateOf<ShiftWithEntry?>(null) }

    // ...
}
```

### Step 2: Modify Add Entry Dialog Logic

```kotlin
// ✅ ADD ENTRY CONFIRMATION DIALOG (MODIFIED)
if (showAddEntryDialog) {
    val existingShift = shiftsForDate.firstOrNull {
        it.shift_date == selectedDate.toString()
    }
    val shiftsOnDate = shiftsForDate.filter {
        it.shift_date == selectedDate.toString()
    }

    AlertDialog(
        onDismissRequest = { showAddEntryDialog = false },
        title = { Text(stringResource(R.string.existing_shift_found)) },
        text = {
            Text(
                if (existingShift?.has_entry == true) {
                    stringResource(R.string.existing_shift_with_entry_message)
                } else {
                    stringResource(R.string.existing_shift_no_entry_message)
                }
            )
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (shiftsOnDate.size > 1) {
                        // ✅ MULTIPLE SHIFTS: Show selection dialog
                        showSelectShiftDialog = true
                        showAddEntryDialog = false
                    } else {
                        // ✅ SINGLE SHIFT: Proceed directly
                        if (existingShift?.has_entry == true) {
                            // Edit existing entry
                            entryToEdit = existingShift
                        } else {
                            // Add entry to existing shift
                            preselectedShift = existingShift
                            showAddEntrySheet = true
                        }
                        showAddEntryDialog = false
                    }
                }
            ) {
                Text(
                    if (existingShift?.has_entry == true) {
                        stringResource(R.string.edit_existing_entry)
                    } else {
                        stringResource(R.string.add_entry_to_existing_shift)
                    }
                )
            }
        },
        dismissButton = {
            Column {
                TextButton(
                    onClick = {
                        // Create new shift and entry
                        preselectedShift = null
                        showAddEntrySheet = true
                        showAddEntryDialog = false
                    }
                ) {
                    Text(stringResource(R.string.create_new_shift_and_entry))
                }
                TextButton(
                    onClick = { showAddEntryDialog = false }
                ) {
                    Text(stringResource(R.string.cancel))
                }
            }
        }
    )
}
```

### Step 3: Add Shift Selection Dialog

```kotlin
// ✅ NEW: SHIFT SELECTION DIALOG
if (showSelectShiftDialog) {
    val shiftsOnDate = shiftsForDate.filter {
        it.shift_date == selectedDate.toString()
    }

    AlertDialog(
        onDismissRequest = { showSelectShiftDialog = false },
        title = { Text(stringResource(R.string.select_shift)) },
        text = { Text(stringResource(R.string.select_shift_message)) },
        confirmButton = {
            // No primary confirm button - each shift is a button
        },
        dismissButton = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // ✅ SHOW BUTTON FOR EACH SHIFT
                shiftsOnDate.forEach { shift ->
                    TextButton(
                        onClick = {
                            if (shift.has_entry) {
                                // Edit existing entry
                                entryToEdit = shift
                            } else {
                                // Add entry to this shift
                                preselectedShift = shift
                                showAddEntrySheet = true
                            }
                            showSelectShiftDialog = false
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = formatShiftDisplayName(shift),
                            style = MaterialTheme.typography.bodyLarge,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                // Cancel button
                TextButton(
                    onClick = { showSelectShiftDialog = false },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(stringResource(R.string.cancel))
                }
            }
        }
    )
}
```

### Step 4: Add Helper Function

```kotlin
// ✅ HELPER FUNCTION: Format shift display name
private fun formatShiftDisplayName(shift: ShiftWithEntry): String {
    val employerName = shift.employer_name ?: "No Employer"
    val startTime = formatTime(shift.expected_shift.start_time)
    val endTime = formatTime(shift.expected_shift.end_time)
    return "$employerName ($startTime - $endTime)"
}

private fun formatTime(timeString: String): String {
    // Input format: "HH:mm:ss"
    // Output format: "h:mm a" (e.g., "9:00 AM")
    return try {
        val inputFormatter = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
        val outputFormatter = SimpleDateFormat("h:mm a", Locale.getDefault())
        val date = inputFormatter.parse(timeString)
        outputFormatter.format(date ?: return timeString)
    } catch (e: Exception) {
        timeString.substring(0, 5) // Fallback to "HH:mm"
    }
}
```

---

## String Resources

### `app/src/main/res/values/strings.xml`

```xml
<!-- Select Shift Dialog -->
<string name="select_shift">Select Shift</string>
<string name="select_shift_message">Multiple shifts exist for this date. Which one would you like to use?</string>
```

### `app/src/main/res/values-fr/strings.xml`

```xml
<!-- Select Shift Dialog -->
<string name="select_shift">Sélectionner un quart</string>
<string name="select_shift_message">Plusieurs quarts existent pour cette date. Lequel souhaitez-vous utiliser?</string>
```

### `app/src/main/res/values-es/strings.xml`

```xml
<!-- Select Shift Dialog -->
<string name="select_shift">Seleccionar turno</string>
<string name="select_shift_message">Existen varios turnos para esta fecha. ¿Cuál desea usar?</string>
```

---

## Complete Flow Examples

### Example 1: Edit Entry (2 Shifts with Entries)

**Setup:**
- Date: Oct 1, 2025
- Shift 1: Restaurant A, 9:00 AM - 2:00 PM, has entry
- Shift 2: Restaurant B, 5:00 PM - 11:00 PM, has entry

**User Flow:**
1. User selects Oct 1 in calendar
2. User clicks "Add Entry" button
3. **Dialog 1** appears:
   - Title: "Existing Shift Found"
   - Message: "A shift with an entry exists for this date..."
   - Buttons: "Edit Existing Entry", "Create New Shift & Entry", "Cancel"
4. User clicks "Edit Existing Entry"
5. **Dialog 2** appears:
   - Title: "Select Shift"
   - Message: "Multiple shifts exist for this date..."
   - Buttons:
     - "Restaurant A (9:00 AM - 2:00 PM)"
     - "Restaurant B (5:00 PM - 11:00 PM)"
     - "Cancel"
6. User clicks "Restaurant A (9:00 AM - 2:00 PM)"
7. Add Entry sheet opens in **edit mode** for Restaurant A's entry

### Example 2: Add Entry (2 Shifts, Neither Has Entry)

**Setup:**
- Date: Oct 3, 2025
- Shift 1: Restaurant A, 9:00 AM - 2:00 PM, NO entry
- Shift 2: Restaurant B, 5:00 PM - 11:00 PM, NO entry

**User Flow:**
1. User selects Oct 3 in calendar
2. User clicks "Add Entry" button
3. **Dialog 1** appears:
   - Title: "Existing Shift Found"
   - Message: "A shift without an entry exists for this date..."
   - Buttons: "Add Entry to Existing Shift", "Create New Shift & Entry", "Cancel"
4. User clicks "Add Entry to Existing Shift"
5. **Dialog 2** appears:
   - Title: "Select Shift"
   - Message: "Multiple shifts exist for this date..."
   - Buttons:
     - "Restaurant A (9:00 AM - 2:00 PM)"
     - "Restaurant B (5:00 PM - 11:00 PM)"
     - "Cancel"
6. User clicks "Restaurant B (5:00 PM - 11:00 PM)"
7. Add Entry sheet opens with Restaurant B's shift **preselected**

### Example 3: Single Shift (No Selection Dialog)

**Setup:**
- Date: Oct 2, 2025
- Shift 1: Restaurant A, 9:00 AM - 2:00 PM, has entry

**User Flow:**
1. User selects Oct 2 in calendar
2. User clicks "Add Entry" button
3. **Dialog 1** appears:
   - Title: "Existing Shift Found"
   - Message: "A shift with an entry exists for this date..."
   - Buttons: "Edit Existing Entry", "Create New Shift & Entry", "Cancel"
4. User clicks "Edit Existing Entry"
5. **No Dialog 2** - opens directly to edit mode for Restaurant A
   (because only 1 shift exists)

---

## Testing Checklist

### Single Shift Tests
- [ ] Date with 1 shift (no entry)
  - [ ] Click "Add Entry" → Dialog appears
  - [ ] Click "Add Entry to Existing Shift"
  - [ ] **Verify:** Opens Add Entry sheet directly (no selection dialog)
  - [ ] **Verify:** Shift is preselected

- [ ] Date with 1 shift (has entry)
  - [ ] Click "Add Entry" → Dialog appears
  - [ ] Click "Edit Existing Entry"
  - [ ] **Verify:** Opens edit sheet directly (no selection dialog)

### Multiple Shifts Tests
- [ ] Date with 2 shifts (neither has entry)
  - [ ] Click "Add Entry" → Dialog 1 appears
  - [ ] Click "Add Entry to Existing Shift"
  - [ ] **Verify:** Dialog 2 appears with 2 shift options
  - [ ] **Verify:** Each shows employer name and time range
  - [ ] Click first shift
  - [ ] **Verify:** Opens Add Entry sheet with first shift preselected
  - [ ] Repeat for second shift

- [ ] Date with 2 shifts (both have entries)
  - [ ] Click "Add Entry" → Dialog 1 appears
  - [ ] Click "Edit Existing Entry"
  - [ ] **Verify:** Dialog 2 appears with 2 shift options
  - [ ] Click first shift
  - [ ] **Verify:** Opens edit sheet for first shift's entry
  - [ ] Repeat for second shift

- [ ] Date with 3+ shifts (mixed: some with entries, some without)
  - [ ] Click "Add Entry" → Dialog 1 appears
  - [ ] Click action button
  - [ ] **Verify:** Dialog 2 shows all 3+ shifts
  - [ ] **Verify:** Each shift displays correctly
  - [ ] Select each shift and verify correct behavior

### Translation Tests
- [ ] Switch to French
  - [ ] Verify "Sélectionner un quart" as dialog title
  - [ ] Verify "Plusieurs quarts existent pour cette date..." message
  - [ ] Verify employer names and times display correctly

- [ ] Switch to Spanish
  - [ ] Verify "Seleccionar turno" as dialog title
  - [ ] Verify "Existen varios turnos para esta fecha..." message
  - [ ] Verify employer names and times display correctly

### Edge Cases
- [ ] No employer assigned to shift
  - [ ] **Verify:** Shows "No Employer" in shift display name

- [ ] Very long employer name
  - [ ] **Verify:** Text wraps or truncates properly in dialog

- [ ] Shift times crossing midnight
  - [ ] **Verify:** Time range displays correctly (e.g., "11:00 PM - 3:00 AM")

---

## UI/UX Considerations

### Dialog Presentation
- Use `AlertDialog` with scrollable content for 3+ shifts
- Each shift button should be full-width with left-aligned text
- Use consistent typography (MaterialTheme.typography.bodyLarge)
- Include proper spacing between buttons (8.dp)

### Accessibility
- Ensure shift buttons have proper content descriptions
- Support TalkBack/screen readers
- Maintain minimum touch target size (48dp)

### Performance
- Only show dialog when shiftsOnDate.count > 1
- Avoid unnecessary re-compositions
- Cache formatted time strings if needed

---

## Summary of Changes

### Modified Files
1. `app/src/main/java/com/protip365/app/presentation/calendar/CalendarScreen.kt`
   - Added `showSelectShiftDialog` state variable
   - Modified "Edit Existing Entry" and "Add Entry to Existing Shift" button logic
   - Added shift selection dialog component
   - Added `formatShiftDisplayName()` helper function
   - Added `formatTime()` helper function

### New String Resources
2. `app/src/main/res/values/strings.xml`
   - Added `select_shift` and `select_shift_message`

3. `app/src/main/res/values-fr/strings.xml`
   - Added French translations

4. `app/src/main/res/values-es/strings.xml`
   - Added Spanish translations

---

## Priority

**HIGH** - This is a user-facing bug that prevents users from editing/adding entries to specific shifts when multiple shifts exist on the same date.

---

## Questions?

If you have questions while implementing:
1. **Shift Display Format:** See `shiftDisplayName(for:)` in iOS CalendarShiftsView.swift:913
2. **Dialog Flow:** See iOS implementation in CalendarShiftsView.swift:203-267
3. **Time Formatting:** See `formatTimeWithoutSeconds()` in CalendarShiftsView.swift:766-796

Good luck! 🚀
