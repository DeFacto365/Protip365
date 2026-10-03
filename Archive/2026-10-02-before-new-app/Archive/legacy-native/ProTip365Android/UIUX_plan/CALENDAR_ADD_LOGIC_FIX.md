# Calendar "Add Entry" and "Add Shift" Logic - iOS vs Android Comparison

## Date: October 12, 2025

## iOS Logic (Reference Implementation)

### Button Enabling Rules:
- **Add Entry Button**: Enabled for **today OR past dates** (`selected <= today`)
- **Add Shift Button**: Enabled for **today OR future dates** (`selected >= today`)

### Button Click Behavior:

#### Add Shift Button:
1. Check if shifts exist on selected date
2. **If shifts exist**: Show dialog with options:
   - "Modify Existing Shift" → Opens edit screen for existing shift
   - "Add New Shift" → Opens add shift screen for new shift
   - "Cancel"
3. **If no shifts**: Directly open add shift screen

#### Add Entry Button:
1. Check if shifts exist on selected date
2. **If shifts exist**: Show dialog with different options based on entry status:
   
   **Scenario A: Shift WITH entry** (has_entry = true):
   - "Edit Existing Entry" → If multiple shifts, show selection dialog; else edit directly
   - "Create New Shift & Entry" → Opens add entry screen (creates both)
   - "Cancel"
   
   **Scenario B: Shift WITHOUT entry** (has_entry = false):
   - "Add Entry to Existing Shift" → If multiple shifts, show selection dialog; else add entry to shift
   - "Create New Shift & Entry" → Opens add entry screen (creates both)
   - "Cancel"

3. **If no shifts**: Directly open add entry screen (will create both shift and entry)

#### Multiple Shifts Selection:
When multiple shifts exist on the same date, show a selection dialog:
- List each shift with employer name and time range
- User selects which shift to edit/add entry to
- Then proceeds to appropriate screen

---

## Android Current Implementation Issues

### CRITICAL PROBLEMS FOUND:

1. **WRONG Button Enabling Logic**:
   ```kotlin
   val entryEnabled = !isFuture  // ❌ WRONG - Should be: selectedDate <= today
   val shiftEnabled = !isPast    // ❌ WRONG - Should be: selectedDate >= today
   ```
   - Current: `!isFuture` enables for **past and today only**
   - Should be: **today OR past** (same as iOS)
   - Current: `!isPast` enables for **future and today only**  
   - Should be: **today OR future** (same as iOS)

2. **Missing Multiple Shifts Handling**:
   - iOS shows selection dialog when multiple shifts exist on same date
   - Android only checks `firstOrNull()` and doesn't handle multiple shifts

3. **Incomplete Entry Dialog Logic**:
   - Android doesn't differentiate between "Edit Existing Entry" vs "Add Entry to Existing Shift"
   - Missing logic to handle multiple shifts scenario

4. **Navigation Issues**:
   - When editing existing entry, should pass shift ID to edit screen
   - When adding entry to existing shift, should preselect that shift

---

## Required Fixes for Android

### Fix 1: Correct Button Enabling Logic
```kotlin
// Replace in QuickActionsSection:
val today = Clock.System.now().toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date

// Add Entry: Available for today OR past
val entryEnabled = selectedDate <= today

// Add Shift: Available for today OR future  
val shiftEnabled = selectedDate >= today
```

### Fix 2: Handle Multiple Shifts in Add Entry Dialog
```kotlin
// In Add Entry Dialog:
confirmButton = {
    TextButton(
        onClick = {
            val selectedDateShifts = shifts.filter { it.shiftDate == selectedDate.toString() }
            
            if (hasEntry) {
                // Edit existing entry
                if (selectedDateShifts.size > 1) {
                    // Show selection dialog for multiple shifts
                    showShiftSelectionDialog = true
                    showAddEntryDialog = false
                } else {
                    // Single shift - edit directly
                    existingShift?.let { onNavigateToEditShift(it.expectedShift.id) }
                    showAddEntryDialog = false
                }
            } else {
                // Add entry to existing shift
                if (selectedDateShifts.size > 1) {
                    // Show selection dialog for multiple shifts
                    showShiftSelectionDialog = true
                    showAddEntryDialog = false
                } else {
                    // Single shift - preselect and navigate
                    onNavigateToAddEntry(uiState.selectedDate) // TODO: Pass shift ID
                    showAddEntryDialog = false
                }
            }
        }
    )
}
```

### Fix 3: Add Shift Selection Dialog
```kotlin
// New dialog state
var showShiftSelectionDialog by remember { mutableStateOf(false) }
var shiftSelectionMode by remember { mutableStateOf(ShiftSelectionMode.EDIT) }

enum class ShiftSelectionMode {
    EDIT,   // Edit existing entry
    ADD     // Add entry to shift
}

// Shift Selection Dialog
if (showShiftSelectionDialog) {
    val selectedDateShifts = shifts.filter { it.shiftDate == uiState.selectedDate.toString() }
    
    AlertDialog(
        onDismissRequest = { showShiftSelectionDialog = false },
        title = { Text(stringResource(R.string.select_shift)) },
        text = {
            Text(stringResource(R.string.multiple_shifts_message))
        },
        confirmButton = {},
        dismissButton = {
            Column {
                selectedDateShifts.forEach { shift ->
                    TextButton(
                        onClick = {
                            when (shiftSelectionMode) {
                                ShiftSelectionMode.EDIT -> {
                                    onNavigateToEditShift(shift.expectedShift.id)
                                }
                                ShiftSelectionMode.ADD -> {
                                    onNavigateToAddEntry(uiState.selectedDate) // TODO: Pass shift ID
                                }
                            }
                            showShiftSelectionDialog = false
                        }
                    ) {
                        Column {
                            Text("${shift.employerName} (${shift.startTime} - ${shift.endTime})")
                        }
                    }
                }
                TextButton(onClick = { showShiftSelectionDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        }
    )
}
```

### Fix 4: Update String Resources
Add missing strings to `strings.xml`:
```xml
<string name="select_shift">Select Shift</string>
<string name="multiple_shifts_message">Multiple shifts exist for this date. Which one would you like to use?</string>
```

---

## Implementation Priority

1. **CRITICAL - Fix Button Enabling Logic** ✅
   - This breaks basic functionality
   - Must match iOS exactly

2. **HIGH - Handle Multiple Shifts** ✅
   - Current implementation fails when user has multiple shifts same day
   - Common use case for users with multiple employers

3. **MEDIUM - Add Shift Selection Dialog** ✅
   - Improves UX for multiple shifts scenario
   - Matches iOS behavior exactly

4. **LOW - Add debug logging** 
   - Help diagnose future issues
   - Match iOS debug output

---

## Testing Checklist

After implementing fixes, test:

- [ ] Add Entry button enabled for today
- [ ] Add Entry button enabled for past dates
- [ ] Add Entry button disabled for future dates
- [ ] Add Shift button enabled for today
- [ ] Add Shift button enabled for future dates
- [ ] Add Shift button disabled for past dates
- [ ] Add Entry on date with no shifts → Creates both
- [ ] Add Entry on date with 1 shift (no entry) → Adds entry to shift
- [ ] Add Entry on date with 1 shift (has entry) → Edits existing entry
- [ ] Add Entry on date with multiple shifts (no entries) → Shows selection
- [ ] Add Entry on date with multiple shifts (has entries) → Shows selection
- [ ] Add Shift on date with no shifts → Creates shift
- [ ] Add Shift on date with existing shifts → Shows modify/add new dialog
- [ ] Calendar refreshes and shows indicators after adding shift
- [ ] Calendar shows shift details when date is selected

---

## Summary

The Android app has THREE critical bugs in the calendar Add Entry/Add Shift logic:

1. **Wrong date comparison logic** for enabling buttons (uses `isPast`/`isFuture` instead of date comparison)
2. **Missing multiple shifts handling** (only handles first shift, ignores others)
3. **Incomplete dialog flows** (missing shift selection dialog)

These must be fixed to match iOS functionality exactly.

