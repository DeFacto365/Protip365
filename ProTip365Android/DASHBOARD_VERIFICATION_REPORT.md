# Dashboard Android vs iOS Verification Report
Generated: October 12, 2025

## Executive Summary

This document compares the Android dashboard implementation against the iOS reference implementation as documented in `IOS_DASHBOARD_LOGIC_EXPLAINED.md`.

---

## ✅ VERIFIED CORRECT

### 1. Cache Implementation (5-minute validity)
**Status**: ✅ MATCHES

**iOS** (DashboardCharts.swift lines 9-14):
```swift
private static var cachedData: (data: [ShiftIncome], cacheTime: Date)? = nil
private static let cacheValiditySeconds: TimeInterval = 300 // 5 minutes
```

**Android** (DashboardViewModel.kt lines 55-63):
```kotlin
private var cachedData: Pair<List<CompletedShift>, Long>? = null
private val CACHE_VALIDITY_MS = 5 * 60 * 1000L // 5 minutes
```

✅ **CORRECT**: Both use 5-minute cache with same invalidation logic.

---

### 2. Single Query Optimization
**Status**: ✅ MATCHES

**iOS** (DashboardCharts.swift lines 168-185):
- Loads entire year of data in one query
- Filters in memory for each period

**Android** (DashboardViewModel.kt lines 176-201):
```kotlin
// Single query for entire year like iOS
val shifts = completedShiftRepository.getCompletedShifts(
    userId = userId,
    startDate = yearStart,
    endDate = today,
    includeUnworked = true
)
```

✅ **CORRECT**: Both use single year query with in-memory filtering.

---

### 3. Week Start Calculation Algorithm
**Status**: ✅ MATCHES

**iOS** (DashboardMetrics.swift lines 214-218):
```swift
let currentWeekday = calendar.component(.weekday, from: date) - 1
let daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
```

**Android** (DashboardMetrics.kt lines 311-320):
```kotlin
val currentWeekday = (date.dayOfWeek.value % 7) // Sunday becomes 0
val daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
return date.minus(daysToSubtract, DateTimeUnit.DAY)
```

✅ **CORRECT**: Identical algorithm, same modulo logic.

---

### 4. Period Date Ranges - Today
**Status**: ✅ MATCHES

Both: `today to today`

---

### 5. Period Date Ranges - Week
**Status**: ✅ MATCHES

**iOS & Android**:
- Start: `getStartOfWeek(today, weekStartDay)`
- End: `weekStart + 6 days`

---

### 6. Period Date Ranges - Month
**Status**: ✅ MATCHES

**iOS & Android**:
- Calendar Month: First to last day of current month
- Both handle month end correctly

---

### 7. Period Date Ranges - Year
**Status**: ✅ MATCHES

**iOS & Android**:
- Start: January 1 of current year
- End: December 31 (or today for data loading)

---

### 8. Target Calculations - Hours & Sales
**Status**: ✅ MATCHES

**iOS** (DashboardMetrics.swift lines 86-122):
**Android** (DashboardMetrics.kt lines 125-176):

Both correctly handle:
- Today: Daily target
- Week: Weekly target
- Month: Monthly or 4×Weekly (if in 4-week mode)
- Year: Monthly × currentMonth

---

### 9. Effective Sales Target Calculation
**Status**: ✅ MATCHES

**iOS** (DashboardMetrics.swift lines 196-210):
**Android** (DashboardMetrics.kt lines 186-204):

Both iterate through shifts and sum:
- Custom target if `shift.sales_target` exists
- Default target otherwise

✅ **CORRECT**: Identical per-shift override logic.

---

### 10. Performance Card - Overall Performance
**Status**: ✅ MATCHES

**iOS** (DashboardPerformanceCard.swift lines 22-38):
**Android** (DashboardPerformanceCard.kt lines 380-398):

Both calculate:
```
performances = [hours%, sales%, tip%]
overall = average(performances)
```

✅ **CORRECT**: Same averaging algorithm.

---

### 11. Performance Card - Color Coding
**Status**: ✅ MATCHES

**iOS** (DashboardPerformanceCard.swift lines 40-60):
**Android** (DashboardPerformanceCard.kt lines 400-422):

Both use:
- ≥95%: Green (🟢 / ✅)
- ≥80%: Orange (🟡 / ⚠️)
- <80%: Red (🔴 / 📊)

✅ **CORRECT**: Identical thresholds and colors.

---

### 12. Target Display Logic - Today Only
**Status**: ✅ MATCHES

**iOS** (DashboardMetrics.swift lines 135-165):
**Android** (DashboardStatsCards.kt lines 61-64, 89-91, 103-106):

Both show targets in stats cards ONLY for Today period:
```kotlin
if (selectedPeriod == 0 && userTargets.dailySales > 0) {
    // Show target
}
```

✅ **CORRECT**: Targets shown only on Today tab.

---

## ❌ CRITICAL ISSUES FOUND

### ISSUE #1: 4 Weeks Period Calculation
**Status**: ❌ INCORRECT - COMPLETELY WRONG

**iOS** (IOS_DASHBOARD_LOGIC_EXPLAINED.md lines 331-361):
```swift
let weekStart = getStartOfWeek(for: today, weekStartDay: weekStartDay)
let fourWeeksStart = calendar.date(byAdding: .weekOfYear, value: -3, to: weekStart) ?? weekStart
// End: weekEnd (6 days after weekStart)
```

**Logic**: 
1. Find current week start (e.g., Monday Oct 7)
2. Go **BACK 3 weeks** (e.g., Monday Sep 16)
3. End at current week end (Sunday Oct 13)
4. **Total: 4 complete weeks (28 days)**

**Android** (DashboardMetrics.kt lines 349-354):
```kotlin
DashboardPeriod.FOUR_WEEKS -> {
    val startOfWeek = getStartOfWeek(today, weekStartDay)
    val endOf4Weeks = startOfWeek.plus(27, DateTimeUnit.DAY)
    startOfWeek to endOf4Weeks
}
```

**Logic**:
1. Find current week start (e.g., Monday Oct 7)
2. Go **FORWARD 27 days** (e.g., Sunday Nov 3)
3. **Total: Looking at FUTURE 4 weeks, not PAST!**

**Example**:
```
Today: October 11, 2025 (Friday)
Week starts Monday

iOS:
  Start: Sept 16, 2025 (Monday, 3 weeks back)
  End: Oct 13, 2025 (Sunday, current week end)
  Range: 28 days of PAST data ✅

Android:
  Start: Oct 7, 2025 (Monday, current week start)
  End: Nov 3, 2025 (Sunday, 3 weeks + 6 days forward)
  Range: 28 days but including FUTURE dates ❌
```

**Impact**: 🔴 HIGH
- Users expect "4 weeks" to show **past 4 weeks of data**
- Android shows **current week + next 3 weeks**
- This breaks pay period tracking entirely
- Most shifts will be "planned" not "worked"

**Fix Required**: Change to:
```kotlin
DashboardPeriod.FOUR_WEEKS -> {
    val weekStart = getStartOfWeek(today, weekStartDay)
    val fourWeeksStart = weekStart.minus(21, DateTimeUnit.DAY) // Go back 3 weeks
    val weekEnd = weekStart.plus(6, DateTimeUnit.DAY)
    fourWeeksStart to weekEnd
}
```

---

### ISSUE #2: Worked Shift Filtering Logic
**Status**: ❌ INCORRECT - TOO PERMISSIVE

**iOS** (IOS_DASHBOARD_LOGIC_EXPLAINED.md lines 435-438):
```swift
var has_earnings: Bool {
    return (sales ?? 0) > 0 || (tips ?? 0) > 0 || 
           (cash_out ?? 0) > 0 || (other ?? 0) > 0
}
```

**Logic**: Shift counts as "worked" if **ANY financial data exists**

**Android** (CompletedShift.kt lines 25-26):
```kotlin
val isWorked: Boolean
    get() = shiftEntry != null
```

**Logic**: Shift counts as "worked" if **ShiftEntry exists**

**Problem**:
- A user could create a ShiftEntry with all zeros (0 sales, 0 tips, 0 other, 0 cash_out)
- iOS would exclude it from stats (no earnings)
- Android would include it in stats (entry exists)
- This inflates shift counts and hours without actual income

**Example**:
```
Shift with ShiftEntry:
- Sales: $0
- Tips: $0
- Cash Out: $0
- Other: $0
- Hours: 4

iOS: NOT counted in stats (has_earnings = false)
Android: COUNTED in stats (isWorked = true)

Result: Android shows 4 hours worked but $0 revenue
```

**Impact**: 🟡 MEDIUM
- Rare edge case (users unlikely to enter all-zero entries)
- But violates iOS parity
- Could confuse users if they test with dummy data

**Fix Required**: Update CompletedShift:
```kotlin
val isWorked: Boolean
    get() = shiftEntry != null && shiftEntry.hasEarnings

val hasEarnings: Boolean
    get() = shiftEntry?.let { entry ->
        entry.sales > 0 || entry.tips > 0 || 
        entry.cashOut > 0 || entry.other > 0
    } ?: false
```

Then in DashboardMetrics.calculateStatsFromCompletedShifts:
```kotlin
// Line 67: Change from
stats.completedShifts = shifts.filter { it.isWorked }

// To:
stats.completedShifts = shifts.filter { it.hasEarnings }
```

---

### ISSUE #3: Total Revenue Calculation
**Status**: ⚠️ NEEDS VERIFICATION

**iOS** (IOS_DASHBOARD_LOGIC_EXPLAINED.md lines 471-479):
```swift
let netSalary = stats.income * (1 - averageDeductionPercentage / 100)
stats.totalRevenue = netSalary + stats.tips + stats.other - stats.tipOut
```

**Formula**: `NET salary + tips + other - tip out`

**Android** (DashboardMetrics.kt lines 69-110):
```kotlin
// Uses snapshot values if available
if (entry.grossIncome != null && entry.netIncome != null) {
    stats.income += entry.grossIncome
    totalNetIncome += entry.netIncome
} else {
    // Calculate from hourly rate
    val grossIncome = actualHours * hourlyRate
    stats.income += grossIncome
    val deductionPct = entry.deductionPercentage ?: averageDeductionPercentage
    val netIncome = grossIncome * (1 - deductionPct / 100)
    totalNetIncome += netIncome
}

// Line 110
stats.totalRevenue = totalNetIncome + stats.tips + stats.other - stats.tipOut
```

**Analysis**:
- Android has TWO code paths: snapshot vs calculated
- Both paths accumulate netIncome correctly
- Final formula matches iOS: `netIncome + tips + other - tipOut`

**BUT**: Snapshot path uses **per-shift** deduction percentages stored at entry time
**iOS**: Always uses **current** deduction percentage for display

**Question**: Should historical deduction percentages be honored?

**iOS Behavior**: 
- Uses current deduction % for ALL calculations
- Ignores historical deduction rates
- Simpler but less historically accurate

**Android Behavior**:
- Uses snapshot deduction % if available
- More historically accurate
- But diverges from iOS

**Impact**: 🟡 MEDIUM
- Different results if user changes deduction % over time
- Android shows "true" historical net income
- iOS shows "what if all past shifts used current deduction %"

**Recommendation**: 
Option A) Match iOS - Always use current deduction %
Option B) Keep Android behavior - More accurate but document difference

**Fix for Option A**:
```kotlin
// Always calculate, don't use snapshots for net income
val hourlyRate = entry.hourlyRate ?: shift.expectedShift.hourlyRate
val grossIncome = actualHours * hourlyRate
stats.income += grossIncome
val netIncome = grossIncome * (1 - averageDeductionPercentage / 100)
totalNetIncome += netIncome
```

---

### ISSUE #4: Year Target Calculation - NEED TO VERIFY
**Status**: ⚠️ VERIFY END DATE HANDLING

**iOS** (IOS_DASHBOARD_LOGIC_EXPLAINED.md lines 168-227):
```swift
let yearStart = calendar.dateInterval(of: .year, for: today)?.start ?? today
// End: today (NOT Dec 31)
```

**Android** (DashboardViewModel.kt lines 183-187):
```kotlin
val yearStart = LocalDate(it.year, 1, 1)
val today = Clock.System.now()
    .toLocalDateTime(TimeZone.currentSystemDefault()).date

// Query from yearStart to today ✅
```

**BUT** in getDateRangeForPeriod (DashboardMetrics.kt lines 343-347):
```kotlin
DashboardPeriod.YEAR -> {
    val startOfYear = LocalDate(today.year, 1, 1)
    val endOfYear = LocalDate(today.year, 12, 31)  // ❌ December 31!
    startOfYear to endOfYear
}
```

**Problem**: 
- Data loading uses `today` as end date ✅
- Period calculation uses `December 31` ❌
- This means period filter might include dates beyond "today"
- Could cause discrepancy if any future shifts exist

**Impact**: 🟢 LOW
- Unlikely to have shifts in the future
- But technically wrong
- Should match iOS: year end = today

**Fix Required**:
```kotlin
DashboardPeriod.YEAR -> {
    val startOfYear = LocalDate(today.year, 1, 1)
    startOfYear to today  // Use today, not Dec 31
}
```

---

## 📊 Summary

### Critical Fixes Required
1. ✅ **4 Weeks Period** - Go BACK 3 weeks, not forward
2. ✅ **Worked Shift Filter** - Add has_earnings check

### Medium Priority
3. ⚠️ **Total Revenue** - Decide on snapshot vs current deduction %
4. ⚠️ **Year End Date** - Use today instead of Dec 31

### Verification Complete
- Cache: ✅
- Single Query: ✅
- Week Start: ✅
- All Period Dates (except 4 weeks): ✅
- Target Calculations: ✅
- Effective Sales Target: ✅
- Performance Card: ✅
- Color Coding: ✅

---

## Next Steps

1. Fix ISSUE #1 (4 Weeks) - CRITICAL
2. Fix ISSUE #2 (isWorked/hasEarnings) - IMPORTANT
3. Discuss ISSUE #3 (deduction %) with stakeholder
4. Fix ISSUE #4 (year end date) - MINOR

---

**Report Generated**: October 12, 2025
**Verified By**: Claude (Automated Analysis)
**Reference**: IOS_DASHBOARD_LOGIC_EXPLAINED.md

