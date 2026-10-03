# Dashboard Quick Reference - Android Implementation

Quick reference for Android dashboard logic matching iOS behavior.

---

## 📅 Period Calculations

### Today
```kotlin
today to today
```

### Week
```kotlin
val weekStart = getStartOfWeek(today, weekStartDay)
val weekEnd = weekStart.plus(6, DateTimeUnit.DAY)
weekStart to weekEnd
```
**Note**: Week start day is user-configurable (0=Sunday, 1=Monday, etc.)

### Month (Calendar)
```kotlin
val startOfMonth = LocalDate(today.year, today.month, 1)
val endOfMonth = startOfMonth.plus(1, DateTimeUnit.MONTH).minus(1, DateTimeUnit.DAY)
startOfMonth to endOfMonth
```

### 4 Weeks (Pay Period)
```kotlin
val weekStart = getStartOfWeek(today, weekStartDay)
val fourWeeksStart = weekStart.minus(21, DateTimeUnit.DAY) // 3 weeks back
val weekEnd = weekStart.plus(6, DateTimeUnit.DAY)
fourWeeksStart to weekEnd
```
**Critical**: Goes BACK 3 weeks, not forward!

### Year
```kotlin
val startOfYear = LocalDate(today.year, 1, 1)
startOfYear to today  // Use TODAY, not Dec 31!
```

---

## 🔍 Shift Filtering

### Only Count Shifts with Earnings
```kotlin
val workedShifts = shifts.filter { it.hasEarnings }
```

### hasEarnings Definition
```kotlin
// ShiftEntry
val hasEarnings: Boolean
    get() = sales > 0 || tips > 0 || cashOut > 0 || other > 0

// CompletedShift
val hasEarnings: Boolean
    get() = shiftEntry?.hasEarnings ?: false
```

**Rule**: Shift only counts if it has ANY financial data.

---

## 💰 Total Revenue Formula

```kotlin
// Step 1: Calculate net income for each shift
val netIncome = grossIncome * (1 - deductionPercentage / 100)
totalNetIncome += netIncome

// Step 2: Calculate total revenue
totalRevenue = totalNetIncome + tips + other - tipOut
```

**Key**: Uses NET salary (after deductions), not gross.

---

## 🎯 Target Calculations

### Hours Target
```kotlin
when (period) {
    TODAY -> userTargets.dailyHours
    WEEK -> userTargets.weeklyHours
    MONTH -> {
        if (monthViewType == FOUR_WEEKS) 
            userTargets.weeklyHours * 4
        else 
            userTargets.monthlyHours
    }
    YEAR -> {
        val currentMonth = Clock.System.now().monthNumber
        userTargets.monthlyHours * currentMonth
    }
}
```

### Sales Target (with Per-Shift Overrides)
```kotlin
fun calculateEffectiveSalesTarget(
    shifts: List<CompletedShift>,
    defaultTarget: Double
): Double {
    return shifts.sumOf { shift ->
        shift.expectedShift.salesTarget ?: defaultTarget
    }
}
```

**Key**: Each shift can have custom sales target, otherwise use default.

---

## 📊 Performance Card

### Overall Performance
```kotlin
val performances = listOf(
    (actualHours / targetHours) * 100,
    (actualSales / targetSales) * 100,
    (actualTipPct / targetTipPct) * 100
)
val overall = performances.average()
```

### Color Coding
```kotlin
when {
    percentage >= 95 -> GREEN  // 🟢 On track
    percentage >= 80 -> ORANGE // 🟡 Warning
    else -> RED                // 🔴 Needs attention
}
```

---

## 💾 Caching

### Cache Duration
```kotlin
private val CACHE_VALIDITY_MS = 5 * 60 * 1000L // 5 minutes
```

### Invalidate Cache When
- User edits/creates shift
- User edits/creates entry
- User manually refreshes (pull to refresh)

### Cache Strategy
1. Load ENTIRE YEAR once
2. Filter in memory for each period
3. Cache for 5 minutes
4. Invalidate on data changes

---

## 🔄 Week Start Algorithm

```kotlin
fun getStartOfWeek(date: LocalDate, weekStartDay: Int): LocalDate {
    val currentWeekday = (date.dayOfWeek.value % 7) // Sunday=0
    val daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
    return date.minus(daysToSubtract, DateTimeUnit.DAY)
}
```

**Example**: If today is Thursday (4) and week starts Monday (1):
- `daysToSubtract = (4 - 1 + 7) % 7 = 3`
- Result: Go back 3 days to Monday

---

## 🎨 Display Rules

### Target Display
- **Today tab**: Show targets inline (e.g., "$500/$800")
- **Other tabs**: Don't show targets inline
- **Performance Card**: Always show targets (all tabs)

### Stats Cards Order
1. Sales
2. Expected Net Salary (with Gross subtitle)
3. Hours Worked
4. Tips (with % of sales)
5. Other (if > 0)
6. **Subtotal**
7. Tip Out (if > 0, shown as negative)
8. **Total Income** (NET revenue)

---

## ⚠️ Common Pitfalls

### ❌ DON'T
```kotlin
// Wrong: 4 weeks forward
val endOf4Weeks = weekStart.plus(27, DateTimeUnit.DAY)

// Wrong: Count all shifts with entries
shifts.filter { it.isWorked }

// Wrong: Use Dec 31 for year end
val endOfYear = LocalDate(today.year, 12, 31)

// Wrong: Use gross salary in total revenue
totalRevenue = grossSalary + tips + other - tipOut
```

### ✅ DO
```kotlin
// Right: 4 weeks back + current
val fourWeeksStart = weekStart.minus(21, DateTimeUnit.DAY)
val weekEnd = weekStart.plus(6, DateTimeUnit.DAY)

// Right: Only count shifts with earnings
shifts.filter { it.hasEarnings }

// Right: Use today for year end
startOfYear to today

// Right: Use net salary in total revenue
totalRevenue = netSalary + tips + other - tipOut
```

---

## 🧪 Test Cases

### 4 Weeks Calculation
```
Given: Today is Oct 11, 2025 (Friday), Week starts Monday
When: Calculate 4 weeks period
Then: 
  Start = Sep 16, 2025 (Monday, 3 weeks back)
  End = Oct 13, 2025 (Sunday, current week end)
  Total = 28 days
```

### hasEarnings Filter
```
Given: Shift with ShiftEntry but $0 sales, $0 tips, $0 other, $0 cash_out
When: Filter shifts by hasEarnings
Then: Shift should NOT be included
```

### Year Target Scaling
```
Given: Monthly target = 160 hours, Current month = October (10)
When: Calculate year target
Then: Target = 160 × 10 = 1600 hours
```

---

## 📖 References

- **Full Documentation**: `IOS_DASHBOARD_LOGIC_EXPLAINED.md`
- **Verification Report**: `DASHBOARD_VERIFICATION_REPORT.md`
- **Fix Summary**: `DASHBOARD_FIX_SUMMARY.md`

---

**Last Updated**: October 12, 2025

