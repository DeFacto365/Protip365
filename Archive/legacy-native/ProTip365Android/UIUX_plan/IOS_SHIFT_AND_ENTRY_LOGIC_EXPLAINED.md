# iOS Shift and Entry Logic - Complete Explanation

## Table of Contents
1. [Data Model Overview](#data-model-overview)
2. [Creating a New Shift](#creating-a-new-shift)
3. [Editing an Existing Shift](#editing-an-existing-shift)
4. [Adding Multiple Shifts on Same Date](#adding-multiple-shifts-on-same-date)
5. [Adding an Entry to a Shift](#adding-an-entry-to-a-shift)
6. [Status Management](#status-management)
7. [Time Handling](#time-handling)
8. [Database Operations](#database-operations)
9. [Common Patterns and Edge Cases](#common-patterns-and-edge-cases)

---

## Data Model Overview

The iOS app uses a **TWO-TABLE** architecture:

### 1. ExpectedShift (expected_shifts table)
**Purpose**: Stores SCHEDULING information - what was planned/expected.

**Key Fields**:
```swift
struct ExpectedShift {
    let id: UUID
    let user_id: UUID
    let employer_id: UUID?
    let shift_date: String              // "yyyy-MM-dd" format
    let start_time: String              // "HH:mm:ss" format (expected)
    let end_time: String                // "HH:mm:ss" format (expected)
    let expected_hours: Double          // Calculated expected hours
    let hourly_rate: Double             // Snapshot of rate at creation
    let lunch_break_minutes: Int        // Break duration
    let sales_target: Double?           // Custom target (nil = use default)
    let status: String                  // "planned", "completed", "missed"
    let alert_minutes: Int?             // Notification timing
    let notes: String?                  // Planning notes
    let created_at: Date
    let updated_at: Date
}
```

### 2. ShiftEntry (shift_entries table)
**Purpose**: Stores ACTUAL work performed and all financial data.

**Key Fields**:
```swift
struct ShiftEntry {
    let id: UUID
    let shift_id: UUID                  // Foreign key to ExpectedShift
    let user_id: UUID
    let actual_start_time: String       // "HH:mm:ss" format (what actually happened)
    let actual_end_time: String         // "HH:mm:ss" format (what actually happened)
    let actual_hours: Double            // Calculated actual hours
    
    // Financial data (ONLY stored here)
    let sales: Double
    let tips: Double
    let cash_out: Double
    let other: Double
    
    // Snapshot fields (preserve calculations at time of entry)
    let hourly_rate: Double?
    let gross_income: Double?
    let total_income: Double?
    let net_income: Double?
    let deduction_percentage: Double?
    
    let notes: String?                  // Entry-specific notes
    let created_at: Date
    let updated_at: Date
}
```

### 3. ShiftWithEntry (Display Model)
**Purpose**: Combines ExpectedShift + ShiftEntry for UI display.

```swift
struct ShiftWithEntry {
    let expected_shift: ExpectedShift
    let entry: ShiftEntry?              // nil if no entry yet
    let employer_name: String?
    
    var has_entry: Bool { entry != nil }
}
```

**Key Concept**: 
- Every shift starts as an `ExpectedShift`
- When actual work is recorded, a `ShiftEntry` is created and linked via `shift_id`
- The app displays both together using `ShiftWithEntry`

---

## Creating a New Shift

### Entry Point: `AddShiftView`
**File**: `ProTip365/AddShift/AddShiftView.swift`

### Workflow

#### 1. View Initialization
```swift
init(editingShift: ShiftWithEntry? = nil, initialDate: Date? = nil) {
    self.editingShift = editingShift
    self.initialDate = initialDate
    self._dataManager = StateObject(wrappedValue: AddShiftDataManager(
        editingShift: editingShift, 
        initialDate: initialDate
    ))
}
```

#### 2. Data Manager Initialization (`AddShiftDataManager.initializeView()`)
**File**: `ProTip365/AddShift/AddShiftDataManager.swift`

**Sequence**:
```swift
func initializeView() async {
    await loadEmployers()           // Load all active employers
    await loadUserDefaults()        // Load default alert preferences
    await setupDefaultTimes()       // Set default times OR populate from editing shift
    isInitializing = false
}
```

#### 3. Default Time Setup (New Shift)
**Lines 356-381 in AddShiftDataManager.swift**

```swift
// For NEW shifts (editingShift == nil):
let baseDate = initialDate ?? Date()
selectedDate = baseDate
endDate = baseDate  // Default to same day

// Start time: 8:00 AM
var startComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
startComponents.hour = 8
startComponents.minute = 0
startTime = calendar.date(from: startComponents)

// End time: 8 hours after start (4:00 PM by default)
endTime = calendar.date(byAdding: .hour, value: 8, to: startTime)
```

#### 4. Save Logic (`AddShiftDataManager.saveShift()`)
**Lines 484-631 in AddShiftDataManager.swift**

**Step-by-step**:

**A. Validation**:
```swift
guard let employer = selectedEmployer else {
    errorMessage = "Select an employer"
    return false
}
```

**B. Overlap Detection**:
```swift
let hasOverlap = await checkForOverlappingShifts()
if hasOverlap {
    return false  // Error already shown to user
}
```

**C. Status Determination** (CRITICAL):
```swift
// Lines 573-579
let calendar = Calendar.current
let today = calendar.startOfDay(for: Date())
let shiftDate = calendar.startOfDay(for: selectedDate)

// Compare DATE only (not time)
let shiftStatus = shiftDate >= today ? "planned" : "completed"
```

**Status Rules**:
- `shiftDate >= today` → Status = **"planned"**
- `shiftDate < today` → Status = **"completed"**
- This is based ONLY on the DATE, not the time

**D. Create ExpectedShift**:
```swift
let newExpectedShift = ExpectedShift(
    id: UUID(),
    user_id: userId,
    employer_id: employer.id,
    shift_date: dateFormatter.string(from: selectedDate),  // "yyyy-MM-dd"
    start_time: timeFormatter.string(from: startTime),      // "HH:mm:ss"
    end_time: timeFormatter.string(from: endTime),          // "HH:mm:ss"
    expected_hours: expectedHours,                          // Calculated
    hourly_rate: employer.hourly_rate,                      // From employer
    lunch_break_minutes: lunchBreakMinutes,                 // From UI
    sales_target: customSalesTarget,                        // nil or custom
    status: shiftStatus,                                    // "planned" or "completed"
    alert_minutes: alertMinutes,
    notes: comments.isEmpty ? nil : comments,
    created_at: Date(),
    updated_at: Date()
)
```

**E. Insert to Database**:
```swift
_ = try await SupabaseManager.shared.createExpectedShift(newExpectedShift)
```

**F. Schedule Notification** (if alert set):
```swift
if let alertMins = alertMinutes {
    try await NotificationManager.shared.scheduleShiftAlert(
        shiftId: newExpectedShift.id,
        shiftDate: selectedDate,
        startTime: startTime,
        employerName: employer.name,
        alertMinutes: alertMins
    )
}
```

---

## Editing an Existing Shift

### Entry Point: Same `AddShiftView` but with `editingShift` parameter

### Workflow

#### 1. Load Existing Data (`AddShiftDataManager.setupDefaultTimes()`)
**Lines 243-355 in AddShiftDataManager.swift**

```swift
if let shift = editingShift {
    // Parse shift date
    let shiftDate = dateFormatter.date(from: shift.expected_shift.shift_date) ?? Date()
    selectedDate = shiftDate
    endDate = shiftDate
    
    // Parse times from expected_shift
    let startTimeString = shift.expected_shift.start_time  // "HH:mm:ss"
    let endTimeString = shift.expected_shift.end_time
    
    // Create Date objects with combined date + time
    // (Complex date parsing logic here - lines 260-318)
    
    // Check for cross-day shifts
    if endTimeInMinutes < startTimeInMinutes {
        // This is a cross-day shift - set end date to next day
        endDate = calendar.date(byAdding: .day, value: 1, to: shiftDate) ?? shiftDate
    }
    
    // Set lunch break
    selectedLunchBreak = // Based on lunch_break_minutes
    
    // Set employer
    selectedEmployer = employers.first { $0.id == employerId }
    
    // Set notes and alert
    comments = shift.expected_shift.notes ?? ""
    selectedAlert = // Based on alert_minutes
    
    // Set sales target
    salesTarget = shift.expected_shift.sales_target ? String(...) : ""
}
```

#### 2. Save Logic (Edit Mode)
**Lines 530-571 in AddShiftDataManager.swift**

**CRITICAL**: Status is **PRESERVED** when editing!

```swift
if let existingShift = editingShift {
    let updatedShift = ExpectedShift(
        id: existingShift.id,                                    // Same ID
        user_id: userId,
        employer_id: employer.id,
        shift_date: dateFormatter.string(from: selectedDate),
        start_time: timeFormatter.string(from: startTime),
        end_time: timeFormatter.string(from: endTime),
        expected_hours: expectedHours,
        hourly_rate: employer.hourly_rate,
        lunch_break_minutes: lunchBreakMinutes,
        sales_target: customSalesTarget,
        status: existingShift.expected_shift.status,             // PRESERVE existing status!
        alert_minutes: alertMinutes,
        notes: comments.isEmpty ? nil : comments,
        created_at: existingShift.expected_shift.created_at,     // Preserve
        updated_at: Date()                                       // Update timestamp
    )
    
    _ = try await SupabaseManager.shared.updateExpectedShift(updatedShift)
    
    // Update notification
    if let alertMins = alertMinutes {
        try await NotificationManager.shared.updateShiftAlert(...)
    } else {
        NotificationManager.shared.cancelShiftAlert(shiftId: existingShift.id)
    }
}
```

**Key Point**: When editing, the status does NOT automatically change. Only the user (or adding an entry) can change the status.

---

## Adding Multiple Shifts on Same Date

### The Problem
Multiple shifts can exist on the same date (e.g., two part-time jobs). The app must prevent TIME OVERLAP.

### Overlap Detection Algorithm
**Function**: `AddShiftDataManager.checkForOverlappingShifts()`
**Lines 385-471 in AddShiftDataManager.swift**

#### Step-by-Step Process

**1. Query All Shifts for Same Date**:
```swift
let dateString = dateFormatter.string(from: selectedDate)  // "yyyy-MM-dd"

let existingShifts: [ExpectedShift] = try await client
    .from("expected_shifts")
    .select()
    .eq("user_id", value: userId)
    .eq("shift_date", value: dateString)  // Same date only
    .execute()
    .value
```

**2. Skip Self When Editing**:
```swift
for shift in existingShifts {
    if let editingShift = editingShift, shift.id == editingShift.id {
        continue  // Don't compare with itself
    }
    // ... check overlap
}
```

**3. Convert Times to Minutes**:
```swift
private func timeToMinutes(_ timeString: String) -> Int {
    let components = timeString.split(separator: ":")
    let hours = Int(components[0])
    let minutes = Int(components[1])
    return hours * 60 + minutes
}

let newStart = timeToMinutes(newStartTime)        // e.g., 540 (9:00 AM)
let newEnd = timeToMinutes(newEndTime)            // e.g., 1020 (5:00 PM)
let existingStart = timeToMinutes(existingStartTime)
let existingEnd = timeToMinutes(existingEndTime)
```

**4. Overlap Logic**:
```swift
// Shifts overlap if ANY of these conditions are true:
let hasOverlap = 
    (newStart >= existingStart && newStart < existingEnd) ||      // New starts during existing
    (newEnd > existingStart && newEnd <= existingEnd) ||          // New ends during existing
    (newStart <= existingStart && newEnd >= existingEnd) ||       // New contains existing
    (existingStart <= newStart && existingEnd >= newEnd)          // Existing contains new
```

**Examples**:
```
Existing: 9:00 - 17:00 (540 - 1020 minutes)

New: 10:00 - 12:00 (600 - 720)
→ OVERLAP (new starts during existing)

New: 18:00 - 20:00 (1080 - 1200)
→ NO OVERLAP (completely after)

New: 8:00 - 18:00 (480 - 1080)
→ OVERLAP (new contains existing)

New: 16:00 - 19:00 (960 - 1140)
→ OVERLAP (new ends during existing)
```

**5. Show Error**:
```swift
if hasOverlap {
    errorMessage = "A shift already exists from \(existingStartTime) to \(existingEndTime) for \(employerName)"
    showErrorAlert = true
    return true
}
```

---

## Adding an Entry to a Shift

### Entry Point: `AddEntryView`
**File**: `ProTip365/AddEntry/AddEntryView.swift`

### Three Scenarios

#### Scenario 1: New Entry (Ad-Hoc)
**When**: User creates entry without existing shift
**Parameters**: `editingShift = nil`, `preselectedShift = nil`

**Process**:
```swift
// Lines 542-562 in AddEntryView.swift
else {
    // Create NEW expected shift for this entry
    let newExpectedShift = ExpectedShift(
        id: UUID(),
        user_id: userId,
        employer_id: state.selectedEmployer?.id,
        shift_date: shiftDate,
        start_time: startTimeStr,           // Use ACTUAL times as expected
        end_time: endTimeStr,
        expected_hours: state.calculatedHours,
        hourly_rate: state.selectedEmployer?.hourly_rate ?? defaultHourlyRate,
        lunch_break_minutes: lunchBreakMinutes,
        sales_target: nil,                  // No custom target for ad-hoc
        status: state.didntWork ? "missed" : "completed",
        alert_minutes: nil,
        notes: state.didntWork ? state.missedReason : nil,
        created_at: Date(),
        updated_at: Date()
    )
    
    let createdShift = try await SupabaseManager.shared.createExpectedShift(newExpectedShift)
    shiftId = createdShift.id
}
```

#### Scenario 2: Preselected Shift
**When**: User selects existing "planned" shift to add entry to
**Parameters**: `editingShift = nil`, `preselectedShift = ShiftWithEntry`

**Process**:
```swift
// Lines 510-539 in AddEntryView.swift
else if let preselectedId = preselectedShiftId {
    shiftId = preselectedId
    
    // Update the expected shift status to "completed"
    if let preselectedShift = try await SupabaseManager.shared.fetchExpectedShifts(
        from: state.selectedDate,
        to: state.selectedDate
    ).first(where: { $0.id == preselectedId }) {
        
        let updatedShift = ExpectedShift(
            id: preselectedShift.id,
            user_id: preselectedShift.user_id,
            employer_id: preselectedShift.employer_id,
            shift_date: preselectedShift.shift_date,
            start_time: preselectedShift.start_time,      // Keep expected times
            end_time: preselectedShift.end_time,
            expected_hours: preselectedShift.expected_hours,
            hourly_rate: preselectedShift.hourly_rate,
            lunch_break_minutes: preselectedShift.lunch_break_minutes,
            sales_target: preselectedShift.sales_target,  // Preserve target
            status: "completed",                          // Update status
            alert_minutes: preselectedShift.alert_minutes,
            notes: preselectedShift.notes,
            created_at: preselectedShift.created_at,
            updated_at: Date()
        )
        
        _ = try await SupabaseManager.shared.updateExpectedShift(updatedShift)
    }
}
```

#### Scenario 3: Editing Existing Entry
**When**: User edits entry with existing shift data
**Parameters**: `editingShift = ShiftWithEntry` (with entry)

**Process**:
```swift
// Lines 486-508 in AddEntryView.swift
if let editingShift = editingShift {
    shiftId = editingShift.id
    
    let updatedExpectedShift = ExpectedShift(
        id: editingShift.id,
        user_id: userId,
        employer_id: state.selectedEmployer?.id,
        shift_date: shiftDate,
        start_time: editingShift.expected_shift.start_time,  // Keep expected times
        end_time: editingShift.expected_shift.end_time,
        expected_hours: editingShift.expected_hours,
        hourly_rate: state.selectedEmployer?.hourly_rate ?? defaultHourlyRate,
        lunch_break_minutes: lunchBreakMinutes,
        sales_target: editingShift.expected_shift.sales_target,  // Preserve
        status: state.didntWork ? "missed" : "completed",
        alert_minutes: editingShift.expected_shift.alert_minutes,
        notes: state.didntWork ? state.missedReason : editingShift.expected_shift.notes,
        created_at: editingShift.expected_shift.created_at,
        updated_at: Date()
    )
    
    _ = try await SupabaseManager.shared.updateExpectedShift(updatedExpectedShift)
}
```

### Creating/Updating ShiftEntry

**Common Pattern** (applies to all scenarios):

```swift
// Lines 566-635 in AddEntryView.swift
if !state.didntWork {
    // Calculate snapshot values
    let hourlyRate = state.selectedEmployer?.hourly_rate ?? defaultHourlyRate
    let grossIncome = state.calculatedHours * hourlyRate
    let tipsAmount = state.tips.toLocaleDouble() ?? 0
    let tipOutAmount = state.tipOut.toLocaleDouble() ?? 0
    let otherAmount = state.other.toLocaleDouble() ?? 0
    let totalIncome = grossIncome + tipsAmount + otherAmount - tipOutAmount
    
    let deductionPct = UserDefaults.standard.double(forKey: "averageDeductionPercentage")
    let finalDeductionPct = deductionPct > 0 ? deductionPct : 30.0
    let netIncome = totalIncome * (1.0 - finalDeductionPct / 100.0)
    
    if let existingEntry = editingShift?.entry {
        // UPDATE existing entry
        let updatedEntry = ShiftEntry(
            id: existingEntry.id,                    // Same ID
            shift_id: shiftId,
            user_id: userId,
            actual_start_time: startTimeStr,
            actual_end_time: endTimeStr,
            actual_hours: state.calculatedHours,
            sales: state.sales.toLocaleDouble() ?? 0,
            tips: tipsAmount,
            cash_out: tipOutAmount,
            other: otherAmount,
            hourly_rate: hourlyRate,                 // Snapshot
            gross_income: grossIncome,               // Snapshot
            total_income: totalIncome,               // Snapshot
            net_income: netIncome,                   // Snapshot
            deduction_percentage: finalDeductionPct, // Snapshot
            notes: state.comments.isEmpty ? nil : state.comments,
            created_at: existingEntry.created_at,
            updated_at: Date()
        )
        
        _ = try await SupabaseManager.shared.updateShiftEntry(updatedEntry)
        DashboardCharts.invalidateCache()
        
    } else {
        // CREATE new entry
        let newEntry = ShiftEntry(
            id: UUID(),
            shift_id: shiftId,                       // Links to ExpectedShift
            user_id: userId,
            actual_start_time: startTimeStr,
            actual_end_time: endTimeStr,
            actual_hours: state.calculatedHours,
            sales: state.sales.toLocaleDouble() ?? 0,
            tips: tipsAmount,
            cash_out: tipOutAmount,
            other: otherAmount,
            hourly_rate: hourlyRate,                 // Snapshot
            gross_income: grossIncome,               // Snapshot
            total_income: totalIncome,               // Snapshot
            net_income: netIncome,                   // Snapshot
            deduction_percentage: finalDeductionPct, // Snapshot
            notes: state.comments.isEmpty ? nil : state.comments,
            created_at: Date(),
            updated_at: Date()
        )
        
        _ = try await SupabaseManager.shared.createShiftEntry(newEntry)
        DashboardCharts.invalidateCache()
    }
}
```

**Key Points**:
1. ShiftEntry is ONLY created if `!state.didntWork`
2. All financial calculations are snapshotted at time of entry
3. `shift_id` links the entry to the ExpectedShift
4. Dashboard cache is invalidated after changes

---

## Status Management

### Three Possible Statuses

```
"planned"    → Shift is scheduled for future
"completed"  → Shift was worked (may or may not have entry data)
"missed"     → Shift was scheduled but user didn't work
```

### Status Transitions

#### 1. On Shift Creation
**File**: `AddShiftDataManager.swift` lines 573-579

```swift
let today = calendar.startOfDay(for: Date())
let shiftDate = calendar.startOfDay(for: selectedDate)

if shiftDate >= today {
    status = "planned"
} else {
    status = "completed"  // Past date = automatically completed
}
```

#### 2. On Entry Creation (Scenario 1 - Ad-hoc)
**File**: `AddEntryView.swift` lines 554

```swift
status: state.didntWork ? "missed" : "completed"
```

#### 3. On Entry Addition to Planned Shift (Scenario 2)
**File**: `AddEntryView.swift` line 531

```swift
status: "completed"  // Always set to completed when adding entry
```

#### 4. On Entry Edit (Scenario 3)
**File**: `AddEntryView.swift` line 501

```swift
status: state.didntWork ? "missed" : "completed"
```

#### 5. On Shift Edit
**File**: `AddShiftDataManager.swift` line 548

```swift
status: existingShift.expected_shift.status  // PRESERVE existing status
```

### Status Flow Diagram

```
NEW SHIFT
    ↓
shiftDate >= today? 
    ↓ YES          ↓ NO
"planned"      "completed"
    ↓                ↓
User adds entry    (Already completed)
    ↓                ↓
"completed"    "completed"
    ↓
didntWork = true?
    ↓ YES
"missed"
```

### Important Rules

1. **Creating a shift**: Status determined by date only
2. **Editing a shift**: Status is PRESERVED
3. **Adding an entry**: Status changes to "completed" (or "missed" if didntWork)
4. **Status never auto-changes**: Only user actions change status

---

## Time Handling

### Time Storage Format

```
shift_date: "yyyy-MM-dd"        (e.g., "2024-10-12")
start_time: "HH:mm:ss"          (e.g., "09:00:00")
end_time: "HH:mm:ss"            (e.g., "17:00:00")
```

### Cross-Day (Overnight) Shifts

**Problem**: Shift starts one day and ends the next (e.g., 22:00 - 02:00)

**Solution**: Use separate date pickers for start and end dates

#### Detection During Edit
**File**: `AddShiftDataManager.swift` lines 301-309

```swift
// Parse times
let endTimeHour = 2      // From "02:00:00"
let startTimeHour = 22   // From "22:00:00"

let endTimeInMinutes = endTimeHour * 60 + endTimeMinute       // 120
let startTimeInMinutes = startTimeHour * 60 + startTimeMinute // 1320

if endTimeInMinutes < startTimeInMinutes {
    // End time is "earlier" than start time → cross-day shift
    endDate = calendar.date(byAdding: .day, value: 1, to: shiftDate)
    print("🌙 Detected cross-day shift")
}
```

#### Calculation
**File**: `AddShiftDataManager.swift` lines 78-113

```swift
var expectedHours: Double {
    let calendar = Calendar.current
    
    // Create full date-time objects using SEPARATE start and end dates
    let startDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
    let endDateComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
    let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
    let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
    
    var fullStartComponents = startDateComponents
    fullStartComponents.hour = startTimeComponents.hour
    fullStartComponents.minute = startTimeComponents.minute
    
    var fullEndComponents = endDateComponents
    fullEndComponents.hour = endTimeComponents.hour
    fullEndComponents.minute = endTimeComponents.minute
    
    let startDateTime = calendar.date(from: fullStartComponents)  // Oct 12, 22:00
    let endDateTime = calendar.date(from: fullEndComponents)      // Oct 13, 02:00
    
    let timeInterval = endDateTime.timeIntervalSince(startDateTime)
    var totalMinutes = Int(timeInterval / 60)  // 240 minutes = 4 hours
    
    totalMinutes -= lunchBreakMinutes
    
    return max(0, Double(totalMinutes) / 60.0)
}
```

**Example**:
```
Start: Oct 12, 2024 at 22:00 (selectedDate + startTime)
End:   Oct 13, 2024 at 02:00 (endDate + endTime)
Lunch: 0 minutes

Calculation:
timeInterval = 4 hours = 14400 seconds
totalMinutes = 240 minutes
expected_hours = 4.0
```

### Validation
**File**: `AddShiftDataManager.swift` lines 116-156

```swift
private func validateEndTime() {
    // Create full date-times
    let startDateTime = // ... combined date + time
    let endDateTime = // ... combined date + time
    
    let timeDifference = endDateTime.timeIntervalSince(startDateTime)
    
    if timeDifference < -3600 {  // End more than 1 hour before start
        // Assume overnight shift - set end date to next day
        endDate = calendar.date(byAdding: .day, value: 1, to: selectedDate)
    } else if timeDifference <= 0 && sameDay {
        // Same day but end before start - adjust end time forward
        endTime = calendar.date(byAdding: .hour, value: 8, to: startTime)
    }
}
```

---

## Database Operations

### Pattern: Insert

```swift
// 1. Create model with all fields
let newExpectedShift = ExpectedShift(
    id: UUID(),                    // Generate new UUID
    user_id: userId,
    // ... all other fields
    created_at: Date(),
    updated_at: Date()
)

// 2. Insert and get back result
let response: [ExpectedShift] = try await client
    .from("expected_shifts")
    .insert(newExpectedShift)
    .select()                      // Return inserted row
    .execute()
    .value

// 3. Extract created object
guard let createdShift = response.first else {
    throw Error("Failed to create")
}
```

### Pattern: Update

```swift
// 1. Create model with SAME id, updated fields, new updated_at
let updatedShift = ExpectedShift(
    id: existingShift.id,          // SAME ID
    user_id: existingShift.user_id,
    // ... updated fields
    created_at: existingShift.created_at,  // Preserve original
    updated_at: Date()                     // New timestamp
)

// 2. Update by ID
let response: [ExpectedShift] = try await client
    .from("expected_shifts")
    .update(updatedShift)
    .eq("id", value: updatedShift.id)     // WHERE clause
    .select()                              // Return updated row
    .execute()
    .value

// 3. Extract updated object
guard let updated = response.first else {
    throw Error("Failed to update")
}
```

### Pattern: Delete

```swift
// Delete entry first (if exists)
if let entry = shift.entry {
    try await client
        .from("shift_entries")
        .delete()
        .eq("id", value: entry.id)
        .execute()
}

// Then delete expected shift
try await client
    .from("expected_shifts")
    .delete()
    .eq("id", value: shift.id)
    .execute()
```

### Pattern: Query with Join

```swift
// File: Models.swift lines 399-452
func fetchShiftsWithEntries(from: Date, to: Date) async throws -> [ShiftWithEntry] {
    // Load all three tables in parallel
    async let expectedShiftsTask: [ExpectedShift] = client
        .from("expected_shifts")
        .select()
        .eq("user_id", value: userId)
        .gte("shift_date", value: startDateString)
        .lte("shift_date", value: endDateString)
        .order("shift_date", ascending: false)
        .execute()
        .value
    
    async let entriesTask: [ShiftEntry] = client
        .from("shift_entries")
        .select()
        .eq("user_id", value: userId)
        .execute()
        .value
    
    async let employersTask: [Employer] = fetchEmployers()
    
    // Await all
    let (expectedShifts, allEntries, employers) = try await (
        expectedShiftsTask, 
        entriesTask, 
        employersTask
    )
    
    // Create lookup dictionaries for O(1) performance
    let entriesDict = Dictionary(uniqueKeysWithValues: allEntries.map { 
        ($0.shift_id, $0) 
    })
    let employerDict = Dictionary(uniqueKeysWithValues: employers.map { 
        ($0.id, $0.name) 
    })
    
    // Combine data
    return expectedShifts.map { shift in
        let entry = entriesDict[shift.id]
        let employerName = shift.employer_id.flatMap { employerDict[$0] }
        
        return ShiftWithEntry(
            expected_shift: shift,
            entry: entry,
            employer_name: employerName
        )
    }
}
```

**Performance**: Single concurrent request instead of N+1 queries

---

## Common Patterns and Edge Cases

### 1. Multiple Shifts on Same Date

**UI Flow** (`CalendarShiftsView.swift` lines 495-518):

```swift
func handleAddShiftTapped() {
    let existingShifts = shiftsForDate(selectedDate)
    
    if !existingShifts.isEmpty {
        // Show dialog: "Modify existing" or "Add new shift"
        showingAddShiftDialog = true
    } else {
        // No shifts exist - open AddShiftView directly
        showingAddShift = true
    }
}
```

**Validation**: Time overlap check (covered in section 4)

### 2. Editing Entry vs Editing Shift

**Two Different Flows**:

```swift
// Edit SHIFT (scheduling info)
selectedShiftForEdit = shift
// Opens: AddShiftView(editingShift: shift)

// Edit ENTRY (financial data)
selectedShiftIncomeForEdit = shift
// Opens: AddEntryView(editingShift: shift)
```

### 3. "Didn't Work" Handling

**AddEntryView** has `didntWork` toggle:

```swift
if state.didntWork {
    // No financial fields shown
    // User selects reason (sick, vacation, etc.)
    
    // On save:
    // - Create ExpectedShift with status "missed"
    // - Do NOT create ShiftEntry
    // - Store reason in notes field
}
```

### 4. Sales Target Logic

**Two Levels**:
```swift
// 1. Default (in user_profile)
let defaultDailySalesTarget: Double = 500

// 2. Per-shift override (in expected_shifts)
let sales_target: Double? = 750  // Overrides default for this shift

// Usage in UI:
let target = shift.sales_target ?? defaultDailySalesTarget
```

### 5. Expected vs Actual Hours

**Displayed Together**:
```swift
// In ShiftRowView when completed
Text("\(actual_hours) / \(expected_hours) hrs")

// Color coding:
if actual > expected + 0.5 { green }      // Worked more
else if actual < expected - 0.5 { orange } // Worked less
else { primary }                           // About right
```

### 6. Snapshot Values

**Why**: Preserve calculations at time of entry

```swift
// At entry creation:
let hourlyRate = employer.hourly_rate           // Current rate
let grossIncome = actualHours * hourlyRate      // Calculate now
let deductionPct = userSettings.deductionPct    // Current setting

// Store ALL in ShiftEntry
// Later, if employer changes rate, this entry is unchanged
```

### 7. Cache Invalidation

**After ANY change to shift or entry**:
```swift
DashboardCharts.invalidateCache()
```

This forces dashboard to reload data on next view.

---

## Summary: Key Takeaways

1. **Two-Table Design**: `expected_shifts` (scheduling) + `shift_entries` (actuals)
2. **Status Rules**: 
   - New shift: Date comparison determines planned/completed
   - Edit shift: Status preserved
   - Add entry: Status becomes completed
3. **Overlap Detection**: Time-based comparison for same date
4. **Cross-Day Shifts**: Use separate date pickers, calculate with full datetime
5. **Entry Scenarios**: Three paths (ad-hoc, preselected, editing)
6. **Snapshot Pattern**: Store calculations at time of entry
7. **Performance**: Parallel queries with dictionary lookups
8. **Delete Order**: Entry first, then shift

---

## File Reference

| File | Purpose |
|------|---------|
| `Models.swift` | Data structures + SupabaseManager extensions |
| `AddShiftView.swift` | Shift creation/edit UI |
| `AddShiftDataManager.swift` | Shift creation/edit logic |
| `AddEntryView.swift` | Entry creation/edit UI |
| `AddEntryModels.swift` | Entry data structures + helpers |
| `CalendarShiftsView.swift` | Display and navigation logic |

---

**Generated**: October 12, 2025  
**For**: Android agent reference  
**Author**: Claude (iOS codebase analysis)

