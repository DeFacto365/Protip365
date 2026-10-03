# Android Implementation Guide: Preserve Shift Status on Edit

## Issues Fixed

### Issue 1: Status Overwritten on Edit
When editing an existing shift in the calendar, the status was being changed to "completed" automatically based on the shift's date/time, even when the user didn't intend to change the status.

### Issue 2: Today's Shifts Marked as "Completed"
When creating a new shift for today, if the shift's start time was before the current time (e.g., creating a 9am shift at 2pm), the status was being set to "completed" instead of "planned".

## Root Causes

1. **Edit Mode**: The save logic was calculating status for ALL shifts (new and existing), overwriting the existing status on edits
2. **Date Comparison**: The logic was comparing full date-time (including hours/minutes) instead of just the date, causing shifts for "today" to be marked as "completed" if the start time had already passed

## iOS Fix Applied
**File**: `ProTip365/AddShift/AddShiftDataManager.swift`

### Before (Lines 512-535)
```swift
// ❌ WRONG: Compares date-time (not just date) and overwrites status on edit
let calendar = Calendar.current
let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
var shiftDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
shiftDateComponents.hour = startComponents.hour
shiftDateComponents.minute = startComponents.minute

let shiftStartDateTime = calendar.date(from: shiftDateComponents) ?? selectedDate
let now = Date()
let shiftStatus = shiftStartDateTime > now ? "planned" : "completed"

if let existingShift = editingShift {
    let updatedShift = ExpectedShift(
        ...
        status: shiftStatus,  // ❌ WRONG: Overwrites existing status
        ...
    )
}
```

### After (Lines 512-556)
```swift
if let existingShift = editingShift {
    // Update existing expected shift - PRESERVE EXISTING STATUS
    // Don't auto-change status when editing, only user can change it
    let updatedShift = ExpectedShift(
        ...
        status: existingShift.expected_shift.status, // ✅ CORRECT: Preserve existing status
        ...
    )
} else {
    // Create new expected shift - determine status based on shift DATE only (not time)
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let shiftDate = calendar.startOfDay(for: selectedDate)

    // ✅ CORRECT: Compare dates only: today or future = "planned", past = "completed"
    let shiftStatus = shiftDate >= today ? "planned" : "completed"

    let newExpectedShift = ExpectedShift(
        ...
        status: shiftStatus, // ✅ CORRECT: Auto-set status for new shifts
        ...
    )
}
```

## Android Implementation Instructions

### Files to Modify
Look for the shift editing/saving logic in these files:
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/shifts/AddEditShiftViewModel.kt`
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/shifts/AddEditShiftScreen.kt`
- Or similar repository implementation files

### Key Changes Needed

1. **When updating an existing shift**: Preserve the existing status from the database
   ```kotlin
   // ❌ WRONG: Overwrites existing status
   val shiftStartDateTime = // combine shift date + start time
   val now = Date()
   val status = if (shiftStartDateTime > now) "planned" else "completed"

   // ✅ CORRECT: Preserve existing status
   val status = existingShift?.status ?: "planned"
   ```

2. **When creating a new shift**: Calculate status based on DATE ONLY (not time)
   ```kotlin
   if (editingShiftId == null) {
       // ❌ WRONG: Compares date-time, so today's shifts become "completed" if time passed
       val shiftStartDateTime = // combine shift date + start time
       val now = Calendar.getInstance().time
       val status = if (shiftStartDateTime.after(now)) "planned" else "completed"

       // ✅ CORRECT: Compare dates only, ignore time
       val calendar = Calendar.getInstance()
       val today = calendar.apply {
           set(Calendar.HOUR_OF_DAY, 0)
           set(Calendar.MINUTE, 0)
           set(Calendar.SECOND, 0)
           set(Calendar.MILLISECOND, 0)
       }.time

       val shiftDate = Calendar.getInstance().apply {
           time = selectedDate
           set(Calendar.HOUR_OF_DAY, 0)
           set(Calendar.MINUTE, 0)
           set(Calendar.SECOND, 0)
           set(Calendar.MILLISECOND, 0)
       }.time

       val status = if (shiftDate >= today) "planned" else "completed"
   } else {
       // Use existing status when editing
       val status = existingShift.status
   }
   ```

### Expected Behavior After Fix

**Creating a new shift:**
- If shift date is today or future → status = "planned"
- If shift date is in the past (yesterday or earlier) → status = "completed"
- **Note**: Time of day is ignored when determining status for new shifts

**Editing an existing shift:**
- Status remains unchanged from the original shift
- User must explicitly change status if desired (through UI controls, not automatic)

### Why Compare Dates Only (Not Times)?

When creating a new shift for today, users expect it to be "planned" regardless of whether they set the start time to 9am while it's currently 2pm. The status should only become "completed" when:
1. The user explicitly marks it as completed (via UI)
2. The shift date is in the past (yesterday or earlier)

Comparing date-time would incorrectly mark today's shifts as "completed" if the start time has passed.

### Testing Checklist

- [ ] Create a new shift for tomorrow → verify status is "planned"
- [ ] Create a new shift for today → verify status is "planned" (regardless of time)
- [ ] Create a new shift for today at 9am (when it's currently 2pm) → verify status is "planned"
- [ ] Create a new shift for yesterday → verify status is "completed"
- [ ] Edit an existing "planned" shift → verify status stays "planned"
- [ ] Edit an existing "completed" shift → verify status stays "completed"
- [ ] Edit shift date from tomorrow to yesterday → verify status stays the same (doesn't auto-change)
- [ ] Edit shift time (but not date) → verify status doesn't change

## Database Schema Note
The `expected_shifts` table has a `status` column that can be:
- `"planned"` - Shift is scheduled for the future
- `"completed"` - Shift has occurred
- `"cancelled"` - Shift was cancelled (if implemented)

Only preserve status on edit; never auto-change it based on date calculations.

## Sales Target Field UI (Added October 2, 2025)

### iOS Implementation
**File:** `ProTip365/AddShift/ShiftDetailsSection.swift:78-100`

The sales target field is displayed on the same line as its label, matching the employer field layout:

```swift
HStack {
    Text("Sales Target")
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
```

### Android Implementation
**Location:** Add Shift / Edit Shift screen, Shift Details section

**UI Requirements:**
- **Layout:** Horizontal row (label on left, field on right)
- **Label:** "Sales Target" (localized)
- **Field Width:** Max 150dp (same as other input fields)
- **Keyboard Type:** Decimal/Number pad
- **Placeholder:** Show default value from `users_profile.target_sales_daily`
  - Example: "500" if user's daily target is 500
  - "0" if no default target set
- **Text Alignment:** Right-aligned in field
- **Background:** System grouped background color
- **Corner Radius:** 8dp
- **No caption below field** (removed for cleaner UI)

**Example Compose Implementation:**
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

**Data Binding:**
- Empty field → uses default from `users_profile.target_sales_daily`
- Non-empty field → overrides default for this specific shift
- Stored in `expected_shifts.sales_target` (nullable)
