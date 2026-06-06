# Week Calculation Consistency - Implementation Summary

## Objective
Ensure that the weekly dashboard tab and weekly detail view use the exact same week calculation logic based on the user's configured week start day from Settings.

---

## Current Implementation (iOS)

### Single Source of Truth: `DashboardMetrics.getStartOfWeek()`

**Location:** `DashboardMetrics.swift` (lines 189-194)

```swift
static func getStartOfWeek(for date: Date, weekStartDay: Int) -> Date {
    let calendar = Calendar.current
    let currentWeekday = calendar.component(.weekday, from: date) - 1
    let daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
    return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
}
```

### Where It's Used

#### 1. Data Loading - `DashboardCharts.loadAllStats()`
**File:** `DashboardCharts.swift` (lines 161-209)

**Process:**
1. Load `week_start` from database (`users_profile` table)
2. Calculate `weekStart = getStartOfWeek(for: today, weekStartDay: weekStartDay)`
3. Calculate `weekEnd = weekStart + 6 days`
4. Filter shifts: `shift_date >= weekStartString && shift_date <= weekEndString`
5. Calculate stats for filtered shifts

**Result:** Weekly tab displays data for the calculated week range

#### 2. Period Date Display - `DashboardStatsCards`
**File:** `DashboardStatsCards.swift` (lines 16, 28-38)

**Process:**
1. Load `weekStart` from `@AppStorage("weekStart")`
2. Calculate `periodStartDate = getStartOfWeek(for: today, weekStartDay: weekStartDay)`
3. Calculate `periodEndDate = periodStartDate + 6 days`
4. Pass dates to `DetailView` → `DetailStatsSection` → `DetailIncomeCard`
5. Format and display: "Sept. 29 to Oct 5"

**Result:** Detail view shows the exact same week range as the data

---

## Verification of Consistency

### Example Calculation
**Given:**
- Today: October 2, 2025 (Thursday)
- Week start setting: Monday (1)

**Data Loading (DashboardCharts):**
1. weekStartDay = 1 (from database)
2. weekStart = getStartOfWeek(Oct 2, 1) = Sept 29 (Monday)
3. weekEnd = Sept 29 + 6 = Oct 5 (Sunday)
4. Shifts filtered: Sept 29 to Oct 5
5. Stats calculated for these 7 days

**Period Display (DashboardStatsCards):**
1. weekStartDay = 1 (from AppStorage)
2. periodStartDate = getStartOfWeek(Oct 2, 1) = Sept 29 (Monday)
3. periodEndDate = Sept 29 + 6 = Oct 5 (Sunday)
4. Display: "Sept. 29 to Oct 5"

**Result:** ✅ Data and display match perfectly

---

## Configuration Source

### Database (Source of Truth)
- **Table:** `users_profile`
- **Column:** `week_start`
- **Type:** INTEGER (0-6)
- **Values:** 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday

### AppStorage (Local Cache)
- **Key:** `"weekStart"`
- **Type:** Int
- **Synced:** When user changes setting in Settings page

**Note:** DashboardCharts loads directly from database to ensure accuracy. DashboardStatsCards uses AppStorage for performance but should be synced.

---

## Future Enhancement: Week Navigation

### Planned Feature
Allow users to navigate to previous/future weeks in the dashboard.

### Implementation Approach

**1. Add Reference Date State**
```swift
@State private var referenceDate: Date = Date() // Default to today
```

**2. Update Data Loading**
```swift
// Instead of: let weekStart = getStartOfWeek(for: Date(), ...)
let weekStart = getStartOfWeek(for: referenceDate, weekStartDay: weekStartDay)
```

**3. Update Period Dates**
```swift
var periodStartDate: Date? {
    guard selectedPeriod == 1 else { return nil }
    return DashboardMetrics.getStartOfWeek(for: referenceDate, weekStartDay: weekStartDay)
}
```

**4. Add Navigation Functions**
```swift
func navigateToPreviousWeek() {
    let currentWeekStart = DashboardMetrics.getStartOfWeek(for: referenceDate, weekStartDay: weekStartDay)
    referenceDate = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart)!
    Task { await preloadAllStats() }
}

func navigateToNextWeek() {
    let currentWeekStart = DashboardMetrics.getStartOfWeek(for: referenceDate, weekStartDay: weekStartDay)
    referenceDate = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart)!
    Task { await preloadAllStats() }
}

func navigateToCurrentWeek() {
    referenceDate = Date()
    Task { await preloadAllStats() }
}
```

**5. Add UI Controls**
```swift
HStack {
    Button(action: navigateToPreviousWeek) {
        Image(systemName: "chevron.left")
    }

    Text(periodDateRange ?? "Current Week")

    Button(action: navigateToNextWeek) {
        Image(systemName: "chevron.right")
    }
}
```

### Key Benefit
By using the same `getStartOfWeek()` function with a variable reference date:
- Data loading and display remain perfectly synchronized
- Navigation is simple (just change reference date)
- All edge cases are handled consistently (month/year boundaries, different week starts, etc.)

---

## Testing Checklist

### Current Implementation
- [x] Weekly tab calculates week using user's week start setting
- [x] Period dates calculate week using same logic
- [x] Both use `DashboardMetrics.getStartOfWeek()` function
- [x] Week is always 7 days (start + 6 days)
- [x] Works with all week start days (0-6)
- [x] Handles month boundaries correctly
- [x] Handles year boundaries correctly
- [x] Localized date display (EN/FR/ES)

### Future Navigation Feature
- [ ] Previous week button loads correct data range
- [ ] Next week button loads correct data range
- [ ] Period dates update to match navigation
- [ ] "Current week" button returns to today
- [ ] Navigation works across month boundaries
- [ ] Navigation works across year boundaries
- [ ] Reference date persists during session
- [ ] Navigation disabled when not on weekly tab

---

## Android Implementation Status

**Guide Created:** ✅ `/Docs/DASHBOARD_WEEK_PERIOD_DATES_ANDROID_GUIDE.md`

**Key Sections:**
1. Week calculation algorithm (matching iOS)
2. Consistency verification tests
3. Future week navigation preparation
4. Complete code examples for all affected files

**Next Steps for Android Team:**
1. Implement `getStartOfWeek()` function in `DashboardViewModel`
2. Use it for BOTH data loading AND period display
3. Add verification test to ensure consistency
4. Implement period date display in `DetailIncomeCard`
5. Add localization for "to" separator (EN: "to", FR: "au", ES: "al")

---

## Summary

✅ **iOS Implementation Complete:**
- Single source of truth for week calculation
- Consistent data loading and display
- Ready for future week navigation feature
- Fully tested and verified

✅ **Android Guide Complete:**
- Detailed implementation instructions
- Consistency verification approach
- Future navigation preparation
- Complete code examples

**Critical Success Factor:** Both platforms use the exact same algorithm with the same parameters, ensuring identical behavior across iOS and Android.
