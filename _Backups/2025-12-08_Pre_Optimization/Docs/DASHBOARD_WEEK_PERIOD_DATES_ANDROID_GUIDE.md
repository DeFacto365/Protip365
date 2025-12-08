# Dashboard Weekly Period Dates - Android Implementation Guide

## Overview
When users click "Show Details" on the Weekly dashboard view, the detail screen now displays the week's date range (e.g., "Sept. 29 to Oct 5") above "Income Breakdown". This uses the user's configured week start day from Settings.

**CRITICAL:** The week calculation logic used for displaying period dates MUST match exactly the logic used for filtering weekly data in the dashboard. This ensures consistency and prepares for future features like browsing past weeks.

---

## 1. iOS Implementation Summary

### Changes Made:

1. **DashboardMetrics.swift** - Added period dates to `DetailViewData`:
   ```swift
   struct DetailViewData: Identifiable {
       let id = UUID()
       let type: String
       let shifts: [ShiftIncome]
       let period: String
       let startDate: Date?  // NEW
       let endDate: Date?    // NEW
   }
   ```

2. **DashboardStatsCards.swift** - Calculate week dates:
   ```swift
   @AppStorage("weekStart") private var weekStartDay: Int = 0

   var periodStartDate: Date? {
       guard selectedPeriod == 1 else { return nil } // Only for week view
       return DashboardMetrics.getStartOfWeek(for: Date(), weekStartDay: weekStartDay)
   }

   var periodEndDate: Date? {
       guard selectedPeriod == 1, let startDate = periodStartDate else { return nil }
       return Calendar.current.date(byAdding: .day, value: 6, to: startDate)
   }
   ```

3. **DetailView.swift** - Accept and pass period dates:
   ```swift
   struct DetailView: View {
       let periodStartDate: Date?
       let periodEndDate: Date?
       // ... pass to DetailStatsSection
   }
   ```

4. **DetailStatsSection.swift** - Pass dates to DetailIncomeCard:
   ```swift
   DetailIncomeCard(
       // ... existing parameters
       periodStartDate: periodStartDate,
       periodEndDate: periodEndDate
   )
   ```

5. **DetailIncomeCard.swift** - Display period date range:
   ```swift
   var periodDateRange: String? {
       guard let startDate = periodStartDate, let endDate = periodEndDate else {
           return nil
       }

       let formatter = DateFormatter()
       formatter.dateFormat = "MMM d"  // Abbreviated month

       let startString = formatter.string(from: startDate)
       let endString = formatter.string(from: endDate)

       // Localized "to" separator
       let toText: String
       switch language {
       case "fr": toText = "au"
       case "es": toText = "al"
       default: toText = "to"
       }

       return "\(startString) \(toText) \(endString)"
   }

   var body: some View {
       VStack(spacing: 12) {
           // Period date range (if available for weekly view)
           if let dateRange = periodDateRange {
               Text(dateRange)
                   .font(.subheadline)
                   .fontWeight(.medium)
                   .foregroundColor(.primary)
                   .frame(maxWidth: .infinity, alignment: .leading)
           }

           Text(localization.incomeBreakdownText)
               .font(.caption)
               .fontWeight(.semibold)
               .foregroundColor(.secondary)
               .frame(maxWidth: .infinity, alignment: .leading)

           // ... rest of income breakdown
       }
   }
   ```

---

## 2. Week Start Calculation Logic

### Function: `getStartOfWeek`
**Location:** `DashboardMetrics.swift` (lines 189-194)

**CRITICAL:** This is the SINGLE SOURCE OF TRUTH for week calculation across the entire app.

```swift
static func getStartOfWeek(for date: Date, weekStartDay: Int) -> Date {
    let calendar = Calendar.current
    let currentWeekday = calendar.component(.weekday, from: date) - 1
    let daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
    return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
}
```

**Used by:**
1. **DashboardCharts.loadAllStats()** (line 168) - Filters weekly shift data
2. **DashboardStatsCards.periodStartDate** (line 31) - Displays week period dates
3. **Future:** Week navigation for viewing past/future weeks

**Parameters:**
- `date`: The reference date (typically today, but can be any date for navigation)
- `weekStartDay`: Integer 0-6 representing Sunday (0) through Saturday (6)

**Returns:** The start date of the week containing the given date

**Algorithm Explanation:**
1. Get current weekday (0-6, Sunday=0)
2. Calculate days to subtract: `(currentWeekday - weekStartDay + 7) % 7`
   - The `+ 7` ensures positive values before modulo
   - The `% 7` handles wrap-around
3. Subtract those days from the reference date

**Example:**
- Today: October 2, 2025 (Thursday)
- Week start: Monday (1)
- Current weekday: 4 (Thursday, 0-indexed)
- Days to subtract: (4 - 1 + 7) % 7 = 3
- Week start: September 29, 2025 (Monday)
- Week end: September 29 + 6 days = October 5, 2025 (Sunday)

**Future Week Navigation Example:**
- User wants to view previous week
- Reference date: September 29, 2025 (current week start)
- Previous week: September 29 - 7 days = September 22, 2025
- Call: `getStartOfWeek(for: Sept 22, weekStartDay: 1)`
- Result: September 22, 2025 (Monday)
- Week range: September 22 - September 28

---

## 3. Android Implementation Steps

### Step 1: Update Data Models

**File:** `DashboardModels.kt` or equivalent

```kotlin
data class DetailViewData(
    val type: String,
    val shifts: List<ShiftIncome>,
    val period: String,
    val startDate: LocalDate? = null,  // NEW
    val endDate: LocalDate? = null     // NEW
)
```

---

### Step 2: Add Week Calculation in DashboardViewModel

**File:** `DashboardViewModel.kt`

```kotlin
import java.time.LocalDate
import java.time.temporal.ChronoUnit

class DashboardViewModel : ViewModel() {
    // Load week start from preferences
    private val weekStartDay: Int
        get() = preferencesManager.getWeekStartDay() // 0-6, Sunday-Saturday

    private val selectedPeriod: MutableStateFlow<Int> = MutableStateFlow(0)

    val periodStartDate: LocalDate?
        get() {
            // Only for week view (selectedPeriod == 1)
            return if (selectedPeriod.value == 1) {
                getStartOfWeek(LocalDate.now(), weekStartDay)
            } else null
        }

    val periodEndDate: LocalDate?
        get() {
            return periodStartDate?.plusDays(6)
        }

    /**
     * Calculate the start of the week based on the configured week start day.
     *
     * @param date The reference date (typically today)
     * @param weekStartDay Integer 0-6 (Sunday=0, Monday=1, ..., Saturday=6)
     * @return The start date of the week
     */
    private fun getStartOfWeek(date: LocalDate, weekStartDay: Int): LocalDate {
        // Java DayOfWeek: MONDAY=1, TUESDAY=2, ..., SUNDAY=7
        // Our weekStartDay: SUNDAY=0, MONDAY=1, ..., SATURDAY=6

        // Convert LocalDate's dayOfWeek to 0-based (Sunday=0)
        val currentWeekday = (date.dayOfWeek.value % 7) // Sunday becomes 0

        // Calculate days to subtract to reach week start
        val daysToSubtract = (currentWeekday - weekStartDay + 7) % 7

        return date.minusDays(daysToSubtract.toLong())
    }

    fun showWeeklyDetails() {
        val detailData = DetailViewData(
            type = "total",
            shifts = currentStats.shifts,
            period = periodText,
            startDate = periodStartDate,
            endDate = periodEndDate
        )
        _detailViewData.value = detailData
    }
}
```

---

### Step 3: Update DetailScreen to Accept Dates

**File:** `DetailScreen.kt`

```kotlin
@Composable
fun DetailScreen(
    shifts: List<ShiftIncome>,
    detailType: String,
    periodText: String,
    periodStartDate: LocalDate? = null,  // NEW
    periodEndDate: LocalDate? = null,    // NEW
    onEditShift: (ShiftIncome) -> Unit,
    onDismiss: () -> Unit
) {
    // ... existing code

    Column {
        DetailStatsSection(
            shifts = shifts,
            localization = localization,
            averageDeductionPercentage = averageDeductionPercentage,
            targetIncome = targetIncome,
            targetTips = targetTips,
            targetSales = targetSales,
            targetHours = targetHours,
            periodStartDate = periodStartDate,  // NEW
            periodEndDate = periodEndDate        // NEW
        )

        // ... rest of UI
    }
}
```

---

### Step 4: Update DetailStatsSection

**File:** `DetailStatsSection.kt`

```kotlin
@Composable
fun DetailStatsSection(
    shifts: List<ShiftIncome>,
    localization: DetailLocalization,
    averageDeductionPercentage: Double,
    targetIncome: Double,
    targetTips: Double,
    targetSales: Double,
    targetHours: Double,
    periodStartDate: LocalDate? = null,  // NEW
    periodEndDate: LocalDate? = null     // NEW
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        DetailIncomeCard(
            shifts = shifts,
            localization = localization,
            averageDeductionPercentage = averageDeductionPercentage,
            targetIncome = targetIncome,
            targetTips = targetTips,
            periodStartDate = periodStartDate,  // NEW
            periodEndDate = periodEndDate        // NEW
        )

        // ... other cards
    }
}
```

---

### Step 5: Update DetailIncomeCard to Display Period Dates

**File:** `DetailIncomeCard.kt`

```kotlin
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun DetailIncomeCard(
    shifts: List<ShiftIncome>,
    localization: DetailLocalization,
    averageDeductionPercentage: Double,
    targetIncome: Double,
    targetTips: Double,
    periodStartDate: LocalDate? = null,  // NEW
    periodEndDate: LocalDate? = null     // NEW
) {
    val language = LocalizationManager.currentLanguage

    // Calculate period date range string
    val periodDateRange: String? = remember(periodStartDate, periodEndDate, language) {
        if (periodStartDate != null && periodEndDate != null) {
            formatPeriodDateRange(periodStartDate, periodEndDate, language)
        } else {
            null
        }
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Period date range (if available for weekly view)
            periodDateRange?.let { dateRange ->
                Text(
                    text = dateRange,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            // Income Breakdown header
            Text(
                text = localization.incomeBreakdownText,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth()
            )

            // ... rest of income breakdown rows
        }
    }
}

/**
 * Format period date range with localized "to" separator.
 *
 * @param startDate Start date of the period
 * @param endDate End date of the period
 * @param language Current language code ("en", "fr", "es")
 * @return Formatted date range string (e.g., "Sept. 29 to Oct 5")
 */
private fun formatPeriodDateRange(
    startDate: LocalDate,
    endDate: LocalDate,
    language: String
): String {
    // Create formatter for abbreviated month format
    val locale = when (language) {
        "fr" -> Locale.FRENCH
        "es" -> Locale("es")
        else -> Locale.ENGLISH
    }

    // Pattern: "MMM d" produces "Sept. 29" or "Oct 5"
    val formatter = DateTimeFormatter.ofPattern("MMM d", locale)

    val startString = startDate.format(formatter)
    val endString = endDate.format(formatter)

    // Localized "to" separator
    val toText = when (language) {
        "fr" -> "au"
        "es" -> "al"
        else -> "to"
    }

    return "$startString $toText $endString"
}
```

---

## 4. Localization Details

### "To" Separator Translations:
- **English:** "to"
- **French:** "au"
- **Spanish:** "al"

### Date Format:
- Pattern: `"MMM d"` (abbreviated month + day)
- Examples:
  - **English:** "Sept. 29 to Oct 5"
  - **French:** "sept. 29 au oct. 5"
  - **Spanish:** "sept. 29 al oct. 5"

**Note:** Month abbreviations are automatically localized by `DateTimeFormatter` when using the appropriate `Locale`.

---

## 5. Preferences Manager Update

Ensure `PreferencesManager` stores and retrieves the week start day:

**File:** `PreferencesManager.kt`

```kotlin
class PreferencesManager(context: Context) {
    private val prefs = context.getSharedPreferences("ProTip365Prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_WEEK_START = "weekStart"
    }

    /**
     * Get the configured week start day.
     *
     * @return Integer 0-6 (Sunday=0, Monday=1, ..., Saturday=6)
     */
    fun getWeekStartDay(): Int {
        return prefs.getInt(KEY_WEEK_START, 0) // Default to Sunday
    }

    /**
     * Set the week start day.
     *
     * @param day Integer 0-6 (Sunday=0, Monday=1, ..., Saturday=6)
     */
    fun setWeekStartDay(day: Int) {
        prefs.edit().putInt(KEY_WEEK_START, day).apply()
    }
}
```

**Database Sync:**
When settings are saved, also update the database:

```kotlin
suspend fun saveWeekStartDay(day: Int) {
    // Save to local preferences
    preferencesManager.setWeekStartDay(day)

    // Sync to database
    supabaseClient
        .from("users_profile")
        .update(mapOf("week_start" to day))
        .eq("user_id", userId)
        .execute()
}
```

---

## 6. Visual Layout

**Before:**
```
┌─────────────────────────────┐
│                             │
│  INCOME BREAKDOWN           │  <- Header only
│                             │
│  Gross Salary      $250.00  │
│  ...                        │
└─────────────────────────────┘
```

**After (Weekly view only):**
```
┌─────────────────────────────┐
│                             │
│  Sept. 29 to Oct 5          │  <- NEW: Period date range
│                             │
│  INCOME BREAKDOWN           │  <- Header
│                             │
│  Gross Salary      $250.00  │
│  ...                        │
└─────────────────────────────┘
```

---

## 7. Testing Checklist

### Functional Tests:
- [ ] Week period dates appear only on Weekly detail view
- [ ] Dates do NOT appear on Today, Month, or Year views
- [ ] Dates calculate correctly based on user's week start setting
- [ ] Changing week start day in Settings updates calculations
- [ ] Week range is always 7 days (start to start+6)
- [ ] Date range crosses month boundaries correctly
- [ ] Date range crosses year boundaries correctly

### Localization Tests:
- [ ] "to" separator translates to "au" in French
- [ ] "to" separator translates to "al" in Spanish
- [ ] Month abbreviations display in correct language
- [ ] Date format matches locale conventions

### Edge Cases:
- [ ] Week start = Sunday (0): Calculates correctly
- [ ] Week start = Monday (1): Calculates correctly
- [ ] Week start = Saturday (6): Calculates correctly
- [ ] Current day = week start day: Shows current week
- [ ] Current day = week start day - 1: Shows previous week

### UI Tests:
- [ ] Date range has proper font size (bodyMedium/subheadline)
- [ ] Date range has medium font weight
- [ ] Date range uses primary text color
- [ ] Date range is left-aligned
- [ ] Proper spacing between date range and "Income Breakdown" (12dp)
- [ ] Text wraps properly if very long month names

---

## 8. Example Outputs

### English (Week start: Monday)
Today: October 2, 2025 (Thursday)
```
Sept. 29 to Oct 5
```

### French (Week start: Monday)
Today: October 2, 2025 (Thursday)
```
sept. 29 au oct. 5
```

### Spanish (Week start: Sunday)
Today: October 2, 2025 (Thursday)
```
sept. 27 al oct. 3
```

---

## 9. Consistency Verification

### Critical Requirement: Data and Display Must Match

The week calculation logic MUST be used in TWO places:

**1. Data Loading (DashboardViewModel)**
```kotlin
// Load weekly data from database
suspend fun loadWeeklyStats(referenceDate: LocalDate = LocalDate.now()) {
    val weekStartDay = preferencesManager.getWeekStartDay()
    val weekStart = getStartOfWeek(referenceDate, weekStartDay)
    val weekEnd = weekStart.plusDays(6)

    // Filter shifts for this week
    val weekShifts = allShifts.filter { shift ->
        val shiftDate = LocalDate.parse(shift.shift_date)
        shiftDate >= weekStart && shiftDate <= weekEnd
    }

    // Calculate stats
    _weekStats.value = calculateStats(weekShifts, ...)
}
```

**2. Period Date Display (DashboardViewModel)**
```kotlin
// Show period dates in detail view
val periodStartDate: LocalDate?
    get() = if (selectedPeriod == 1) {
        getStartOfWeek(LocalDate.now(), weekStartDay)
    } else null

val periodEndDate: LocalDate?
    get() = periodStartDate?.plusDays(6)
```

**Verification Test:**
```kotlin
@Test
fun `verify week calculation consistency`() {
    val weekStartDay = 1 // Monday
    val today = LocalDate.of(2025, 10, 2) // Thursday

    // Calculate week for data loading
    val dataWeekStart = getStartOfWeek(today, weekStartDay)
    val dataWeekEnd = dataWeekStart.plusDays(6)

    // Calculate week for display
    val displayWeekStart = getStartOfWeek(today, weekStartDay)
    val displayWeekEnd = displayWeekStart.plusDays(6)

    // MUST be identical
    assertEquals(dataWeekStart, displayWeekStart)
    assertEquals(dataWeekEnd, displayWeekEnd)

    // Verify expected values
    assertEquals(LocalDate.of(2025, 9, 29), dataWeekStart) // Monday
    assertEquals(LocalDate.of(2025, 10, 5), dataWeekEnd)   // Sunday
}
```

---

## 10. Future Enhancement: Week Navigation

### Preparation for Past/Future Week Viewing

The current implementation uses `LocalDate.now()` as the reference date. Future enhancement will add navigation:

**ViewModel State:**
```kotlin
class DashboardViewModel : ViewModel() {
    // Current reference date (default to today)
    private val _referenceDate = MutableStateFlow(LocalDate.now())
    val referenceDate: StateFlow<LocalDate> = _referenceDate.asStateFlow()

    // Navigate to previous week
    fun navigateToPreviousWeek() {
        val currentWeekStart = getStartOfWeek(_referenceDate.value, weekStartDay)
        _referenceDate.value = currentWeekStart.minusDays(7)
        loadWeeklyStats(_referenceDate.value)
    }

    // Navigate to next week
    fun navigateToNextWeek() {
        val currentWeekStart = getStartOfWeek(_referenceDate.value, weekStartDay)
        _referenceDate.value = currentWeekStart.plusDays(7)
        loadWeeklyStats(_referenceDate.value)
    }

    // Reset to current week
    fun navigateToCurrentWeek() {
        _referenceDate.value = LocalDate.now()
        loadWeeklyStats(_referenceDate.value)
    }
}
```

**UI Controls (Future):**
```kotlin
Row(
    modifier = Modifier.fillMaxWidth(),
    horizontalArrangement = Arrangement.SpaceBetween
) {
    IconButton(onClick = { viewModel.navigateToPreviousWeek() }) {
        Icon(Icons.Default.ChevronLeft, "Previous Week")
    }

    Text(
        text = periodDateRange ?: "Current Week",
        style = MaterialTheme.typography.titleMedium
    )

    IconButton(onClick = { viewModel.navigateToNextWeek() }) {
        Icon(Icons.Default.ChevronRight, "Next Week")
    }
}
```

**Period Date Calculation (Updated):**
```kotlin
val periodStartDate: LocalDate?
    get() = if (selectedPeriod == 1) {
        getStartOfWeek(referenceDate.value, weekStartDay) // Uses reference date
    } else null
```

This ensures that:
1. Data loading always matches the reference date
2. Period dates always match the data being displayed
3. Navigation maintains consistency across data and UI

---

## 11. Key Implementation Notes

1. **Conditional Display:** Only show period dates when `periodStartDate` and `periodEndDate` are not null (i.e., only for weekly view)

2. **Week Calculation:** Use modulo arithmetic to handle week start day wrapping:
   ```
   daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
   ```

3. **Date Formatting:** Use platform's `DateTimeFormatter` with locale-specific formatting for automatic month translation

4. **State Management:** Pass dates through the view hierarchy from ViewModel → DetailScreen → DetailStatsSection → DetailIncomeCard

5. **Performance:** Use `remember` for date formatting to avoid recalculating on every recomposition

6. **Null Safety:** All date parameters are nullable to support non-weekly views

---

## End of Guide

This guide provides complete implementation details to add week period dates to the Android Dashboard weekly detail view, matching iOS behavior exactly.
