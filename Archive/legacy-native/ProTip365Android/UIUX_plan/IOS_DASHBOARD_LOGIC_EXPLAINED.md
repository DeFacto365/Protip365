# iOS Dashboard Logic and Calculations - Complete Explanation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Data Loading and Caching](#data-loading-and-caching)
3. [Period Calculations](#period-calculations)
4. [Metrics Calculations](#metrics-calculations)
5. [Target System](#target-system)
6. [Performance Card Logic](#performance-card-logic)
7. [Week Start Day](#week-start-day)
8. [Stats Aggregation](#stats-aggregation)
9. [Display Components](#display-components)
10. [Common Patterns](#common-patterns)

---

## Architecture Overview

### Component Structure

The Dashboard follows a **layered architecture**:

```
DashboardView (Coordinator)
    ↓
DashboardCharts (Data Layer)
    ↓
DashboardMetrics (Calculation Layer)
    ↓
DashboardStatsCards + DashboardPerformanceCard (Display Layer)
```

### Key Files

| File | Purpose |
|------|---------|
| `DashboardView.swift` | Main view coordinator, state management |
| `DashboardCharts.swift` | Data loading, caching, conversion |
| `DashboardMetrics.swift` | Calculations, formatting, utilities |
| `DashboardStatsCards.swift` | Stats display component |
| `DashboardPerformanceCard.swift` | Target progress tracking |
| `DashboardPeriodSelector.swift` | Period selection UI |

### Data Flow

```
1. User opens Dashboard
   ↓
2. DashboardView.task { performInitialLoad() }
   ↓
3. preloadAllStats() → DashboardCharts.loadAllStats()
   ↓
4. Fetch year of data (single query)
   ↓
5. Filter into periods (Today, Week, Month, Year, 4 Weeks)
   ↓
6. DashboardMetrics.calculateStats() for each period
   ↓
7. Display in DashboardStatsCards
```

---

## Data Loading and Caching

### Single Query Optimization

**File**: `DashboardCharts.swift` lines 135-260

**Key Concept**: Load entire year of data once, then filter in memory.

```swift
static func loadAllStats(
    forceRefresh: Bool = false, 
    defaultHourlyRate: Double, 
    averageDeductionPercentage: Double
) async -> (
    todayStats: Stats,
    weekStats: Stats,
    monthStats: Stats,
    yearStats: Stats,
    fourWeeksStats: Stats
)
```

#### Step-by-Step Process

**1. Check Cache First**:
```swift
// Lines 9-14
private static var cachedData: (data: [ShiftIncome], cacheTime: Date)? = nil
private static let cacheValiditySeconds: TimeInterval = 300 // 5 minutes

private static func isCacheValid() -> Bool {
    guard let cache = cachedData else { return false }
    return Date().timeIntervalSince(cache.cacheTime) < cacheValiditySeconds
}
```

**Cache Strategy**:
- Cache is valid for **5 minutes**
- Invalidated on: shift creation, entry edit, force refresh
- Check: `if !forceRefresh && isCacheValid()`

**2. Load Year of Data** (if cache invalid):
```swift
// Lines 168-185
let yearStart = calendar.dateInterval(of: .year, for: today)?.start ?? today

let allShiftsWithEntries = try await SupabaseManager.shared.fetchShiftsWithEntries(
    from: yearStart, 
    to: today
)

// Convert from ShiftWithEntry to ShiftIncome
let convertedShifts = convertShiftWithEntriesToShiftIncome(allShiftsWithEntries)

// Cache it
cachedData = (data: convertedShifts, cacheTime: Date())
```

**Why Single Query?**:
- **Before**: 5 separate queries (Today, Week, Month, Year, 4 Weeks)
- **After**: 1 query for year, filter in memory
- **Result**: ~5x faster load time

**3. Filter Data for Each Period**:
```swift
// Today (line 192)
let todayString = dateFormatter.string(from: today)
let todayShifts = allShifts.filter { $0.shift_date == todayString }

// Week (lines 200-205)
let weekStartString = dateFormatter.string(from: weekStart)
let weekEndString = dateFormatter.string(from: weekEnd)
let weekShifts = allShifts.filter {
    $0.shift_date >= weekStartString && $0.shift_date <= weekEndString
}

// Month (lines 213-219)
let monthShifts = allShifts.filter {
    $0.shift_date >= monthStartString && $0.shift_date < monthEndString
}

// Year (line 227)
// No filtering needed - use all shifts

// 4 Weeks (lines 234-238)
let fourWeeksShifts = allShifts.filter {
    $0.shift_date >= fourWeeksStartString && $0.shift_date <= fourWeeksEndString
}
```

**4. Calculate Stats for Each Period**:
```swift
todayStats = DashboardMetrics.calculateStats(
    for: todayShifts,
    averageDeductionPercentage: averageDeductionPercentage,
    defaultHourlyRate: defaultHourlyRate
)
// Repeat for week, month, year, fourWeeks
```

### Cache Invalidation

**When Cache is Cleared**:
```swift
// Called from:
// - AddEntryView after saving/editing/deleting entry
// - AddShiftView after saving/editing shift
// - Manual refresh (pull to refresh)

DashboardCharts.invalidateCache()
```

### Data Conversion

**ShiftWithEntry → ShiftIncome** (Lines 25-79):

```swift
private static func convertShiftWithEntriesToShiftIncome(_ shiftsWithEntries: [ShiftWithEntry]) -> [ShiftIncome] {
    return shiftsWithEntries.map { shiftWithEntry in
        let shift = shiftWithEntry.expected_shift
        let entry = shiftWithEntry.entry
        
        // Use actual hours if entry exists, otherwise expected
        let hours = entry?.actual_hours ?? shift.expected_hours
        
        // Financial data (from entry or zero)
        let sales = entry?.sales ?? 0
        let tips = entry?.tips ?? 0
        let cashOut = entry?.cash_out ?? 0
        let other = entry?.other ?? 0
        
        // Calculate derived values
        let baseIncome = hours * shift.hourly_rate
        let netTips = tips - cashOut
        let totalIncome = baseIncome + netTips + other
        let tipPercentage = sales > 0 ? (tips / sales) * 100 : 0
        
        return ShiftIncome(
            // ... all fields mapped
        )
    }
}
```

**Why Convert?**:
- Legacy compatibility with existing `DashboardMetrics.Stats`
- Easier filtering and aggregation
- Flat structure for calculations

---

## Period Calculations

### Today

**Simple**: Current date only

```swift
let today = Date()
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
let todayString = dateFormatter.string(from: today)

let todayShifts = allShifts.filter { $0.shift_date == todayString }
```

**Example**:
- Today: October 12, 2024
- Filter: `shift_date == "2024-10-12"`

### Week

**Complex**: Based on user's week start preference

**File**: `DashboardMetrics.swift` lines 214-218

```swift
static func getStartOfWeek(for date: Date, weekStartDay: Int) -> Date {
    let calendar = Calendar.current
    let currentWeekday = calendar.component(.weekday, from: date) - 1  // 0 = Sunday
    let daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
    return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
}
```

**weekStartDay Values**:
- `0` = Sunday
- `1` = Monday
- `2` = Tuesday
- ... and so on

**Calculation Steps**:

1. **Get user's week start preference**:
```swift
// From users_profile table
let weekStartDay = profiles.first?.week_start ?? 0
```

2. **Calculate week start**:
```swift
let weekStart = DashboardMetrics.getStartOfWeek(for: today, weekStartDay: weekStartDay)
```

3. **Calculate week end** (always 6 days after start):
```swift
let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
```

4. **Filter shifts**:
```swift
let weekShifts = allShifts.filter {
    $0.shift_date >= weekStartString && $0.shift_date <= weekEndString
}
```

**Example** (Week starts Monday):
```
Today: Friday, October 11, 2024
weekStartDay: 1 (Monday)

currentWeekday: 5 (Friday = weekday 6, minus 1 = 5)
daysToSubtract: (5 - 1 + 7) % 7 = 4

weekStart: October 7, 2024 (Monday)
weekEnd: October 13, 2024 (Sunday)

Range: "2024-10-07" to "2024-10-13"
```

**Example** (Week starts Sunday):
```
Today: Friday, October 11, 2024
weekStartDay: 0 (Sunday)

currentWeekday: 5
daysToSubtract: (5 - 0 + 7) % 7 = 5

weekStart: October 6, 2024 (Sunday)
weekEnd: October 12, 2024 (Saturday)

Range: "2024-10-06" to "2024-10-12"
```

### Month (Calendar Month)

**Simple**: First to last day of current month

```swift
// Lines 213-219
let monthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
let monthEnd = calendar.dateInterval(of: .month, for: today)?.end ?? today

let monthShifts = allShifts.filter {
    $0.shift_date >= monthStartString && $0.shift_date < monthEndString  // Note: < not <=
}
```

**Example**:
```
Today: October 12, 2024
monthStart: October 1, 2024 00:00:00
monthEnd: November 1, 2024 00:00:00  (exclusive)

Range: "2024-10-01" to "2024-10-31"
```

### 4 Weeks (Pay Period)

**Purpose**: For users paid every 4 weeks

**Calculation**:
```swift
// Lines 170
let weekStart = getStartOfWeek(for: today, weekStartDay: weekStartDay)
let fourWeeksStart = calendar.date(byAdding: .weekOfYear, value: -3, to: weekStart) ?? weekStart

// Lines 234-238
let fourWeeksShifts = allShifts.filter {
    $0.shift_date >= fourWeeksStartString && $0.shift_date <= fourWeeksEndString
}
```

**Logic**:
1. Find current week start
2. Go back 3 weeks (= 4 weeks total including current)
3. End at current week end

**Example** (Week starts Monday):
```
Today: October 11, 2024 (Friday)
weekStart: October 7, 2024 (Monday)
fourWeeksStart: September 16, 2024 (Monday, 3 weeks back)
weekEnd: October 13, 2024 (Sunday)

Range: "2024-09-16" to "2024-10-13"
Total: 28 days (4 complete weeks)
```

### Year

**Simple**: January 1 to today

```swift
// Line 168
let yearStart = calendar.dateInterval(of: .year, for: today)?.start ?? today

// Line 227-231
yearStats = DashboardMetrics.calculateStats(
    for: allShifts,  // No filtering - use entire dataset
    averageDeductionPercentage: averageDeductionPercentage,
    defaultHourlyRate: defaultHourlyRate
)
```

**Example**:
```
Today: October 12, 2024
yearStart: January 1, 2024
Range: "2024-01-01" to "2024-10-12"
```

---

## Metrics Calculations

### Stats Structure

**File**: `DashboardMetrics.swift` lines 9-24

```swift
struct Stats {
    var hours: Double = 0           // Total hours worked
    var sales: Double = 0            // Total sales
    var tips: Double = 0             // Total tips received
    var tipOut: Double = 0           // Total tip out
    var other: Double = 0            // Other income
    var income: Double = 0           // GROSS salary (hours × rate)
    var tipPercentage: Double = 0    // Tips as % of sales
    var totalRevenue: Double = 0     // NET salary + tips + other - tipout
    var shifts: [ShiftIncome] = []   // All shifts in period
    
    func netIncome(deductionPercentage: Double) -> Double {
        return income * (1 - deductionPercentage / 100)
    }
}
```

### Calculate Stats

**File**: `DashboardMetrics.swift` lines 50-82

```swift
static func calculateStats(
    for shifts: [ShiftIncome], 
    averageDeductionPercentage: Double, 
    defaultHourlyRate: Double
) -> Stats
```

#### Step-by-Step Calculation

**1. Filter to Worked Shifts Only**:
```swift
// Line 53
stats.shifts = shifts.filter { $0.has_earnings }
```

**What is `has_earnings`?**
```swift
// From Models.swift line 266-268
var has_earnings: Bool {
    return (sales ?? 0) > 0 || (tips ?? 0) > 0 || (cash_out ?? 0) > 0 || (other ?? 0) > 0
}
```

**Why Filter?**:
- Exclude "planned" shifts (not yet worked)
- Exclude "missed" shifts (didn't work)
- Only count actual work performed

**2. Aggregate All Fields**:
```swift
// Lines 55-69
for shift in stats.shifts {
    // Hours
    stats.hours += (shift.hours ?? 0)
    
    // Sales
    stats.sales += (shift.sales ?? 0)
    
    // Tips
    stats.tips += (shift.tips ?? 0)
    
    // Base Income (Gross Salary)
    if let baseIncome = shift.base_income {
        stats.income += baseIncome  // Use pre-calculated if available
    } else {
        let hours = shift.hours ?? 0
        stats.income += (hours * shift.hourly_rate)
    }
    
    // Tip Out
    stats.tipOut += (shift.cash_out ?? 0)
    
    // Other Income
    stats.other += (shift.other ?? 0)
}
```

**3. Calculate Total Revenue**:
```swift
// Lines 71-73
let netSalary = stats.income * (1 - averageDeductionPercentage / 100)
stats.totalRevenue = netSalary + stats.tips + stats.other - stats.tipOut
```

**Formula Breakdown**:
```
Gross Salary = Σ(hours × hourlyRate) for all shifts
Net Salary = Gross Salary × (1 - deductionPercentage / 100)
Total Revenue = Net Salary + Tips + Other - Tip Out
```

**Example**:
```
Shift 1: 8 hours @ $15/hr, $200 sales, $40 tips, $5 tip out, $10 other
Shift 2: 6 hours @ $15/hr, $150 sales, $30 tips, $3 tip out, $0 other

Hours: 8 + 6 = 14
Sales: 200 + 150 = 350
Tips: 40 + 30 = 70
Tip Out: 5 + 3 = 8
Other: 10 + 0 = 10
Gross Salary: (8 × 15) + (6 × 15) = 120 + 90 = 210

Assuming 30% deduction:
Net Salary: 210 × (1 - 0.30) = 210 × 0.70 = 147
Total Revenue: 147 + 70 + 10 - 8 = 219
```

**4. Calculate Tip Percentage**:
```swift
// Lines 75-79
if stats.sales > 0 && !stats.sales.isNaN && !stats.tips.isNaN {
    stats.tipPercentage = (stats.tips / stats.sales) * 100
} else {
    stats.tipPercentage = 0
}
```

**Formula**:
```
Tip Percentage = (Total Tips / Total Sales) × 100
```

**Example**:
```
Tips: $70
Sales: $350
Tip %: (70 / 350) × 100 = 20%
```

---

## Target System

### User Targets Structure

**File**: `DashboardMetrics.swift` lines 26-37

```swift
struct UserTargets {
    var tipTargetPercentage: Double = 0  // Target tip % (e.g., 20%)
    var dailySales: Double = 0            // Daily sales target
    var weeklySales: Double = 0           // Weekly sales target
    var monthlySales: Double = 0          // Monthly sales target
    var dailyHours: Double = 0            // Daily hours target
    var weeklyHours: Double = 0           // Weekly hours target
    var monthlyHours: Double = 0          // Monthly hours target
    var dailyIncome: Double = 0           // Daily income target (calculated)
    var weeklyIncome: Double = 0          // Weekly income target (calculated)
    var monthlyIncome: Double = 0         // Monthly income target (calculated)
}
```

### Loading Targets

**File**: `DashboardCharts.swift` lines 84-132

```swift
static func loadTargets() async -> (
    targets: UserTargets, 
    hourlyRate: Double, 
    deductionPercentage: Double
)
```

**Process**:
```swift
// Query users_profile table
let profiles: [Profile] = try await client
    .from("users_profile")
    .select()
    .eq("user_id", value: userId)
    .execute()
    .value

if let profile = profiles.first {
    // Load direct targets
    hourlyRate = profile.default_hourly_rate
    deductionPercentage = profile.average_deduction_percentage ?? 30.0
    targets.tipTargetPercentage = profile.tip_target_percentage ?? 0
    targets.dailySales = profile.target_sales_daily ?? 0
    targets.weeklySales = profile.target_sales_weekly ?? 0
    targets.monthlySales = profile.target_sales_monthly ?? 0
    targets.dailyHours = profile.target_hours_daily ?? 0
    targets.weeklyHours = profile.target_hours_weekly ?? 0
    targets.monthlyHours = profile.target_hours_monthly ?? 0
    
    // Calculate income targets
    targets.dailyIncome = hourlyRate × dailyHours
    targets.weeklyIncome = hourlyRate × weeklyHours
    targets.monthlyIncome = hourlyRate × monthlyHours
}
```

### Target Calculations by Period

#### Hours Target

**File**: `DashboardMetrics.swift` lines 86-103

```swift
static func getHoursTarget(
    selectedPeriod: Int, 
    monthViewType: Int, 
    userTargets: UserTargets
) -> Double {
    switch selectedPeriod {
    case 0: // Today
        return userTargets.dailyHours
        
    case 1: // Week
        return userTargets.weeklyHours
        
    case 2: // Month or 4 Weeks
        if monthViewType == 1 && userTargets.weeklyHours > 0 {
            // 4 weeks mode
            return userTargets.weeklyHours * 4
        }
        return userTargets.monthlyHours
        
    case 3: // Year
        let currentMonth = Calendar.current.component(.month, from: Date())
        return userTargets.monthlyHours * Double(currentMonth)
        
    default: 
        return 0
    }
}
```

**Year Target Logic**:
```
If current month is October (month 10):
Yearly Target = Monthly Target × 10

Example:
Monthly Target: 160 hours
Current Month: 10 (October)
Yearly Target: 160 × 10 = 1600 hours
```

**Rationale**: You've only had 10 months to accumulate hours, so target should reflect that.

#### Sales Target

**File**: `DashboardMetrics.swift` lines 105-122

**Same logic as hours**, but with sales targets:
```swift
case 0: return userTargets.dailySales
case 1: return userTargets.weeklySales
case 2: return monthViewType == 1 ? userTargets.weeklySales * 4 : userTargets.monthlySales
case 3: return userTargets.monthlySales * Double(currentMonth)
```

#### Effective Sales Target (Per-Shift Override)

**File**: `DashboardMetrics.swift` lines 196-210

**Purpose**: Handle shifts with custom sales targets

```swift
static func calculateEffectiveSalesTarget(
    shifts: [ShiftIncome], 
    defaultTarget: Double
) -> Double {
    var totalTarget: Double = 0
    
    for shift in shifts {
        if let customTarget = shift.sales_target {
            // Shift has custom target
            totalTarget += customTarget
        } else {
            // Use default target
            totalTarget += defaultTarget
        }
    }
    
    return totalTarget
}
```

**Example**:
```
User's default daily sales target: $500

Week has 3 shifts:
- Shift 1 (Monday): No custom target → $500
- Shift 2 (Wednesday): Custom target $750
- Shift 3 (Friday): No custom target → $500

Effective Weekly Target: 500 + 750 + 500 = $1,750
(NOT: default weekly target of $3,500)
```

### Target Display Logic

**Only Today Tab Shows Targets** (for sales/income/tips):

**File**: `DashboardMetrics.swift` lines 135-165

```swift
static func formatIncomeWithTarget(...) -> String {
    let income = formatCurrency(currentStats.income)
    
    // ONLY show target for Today tab
    if selectedPeriod == 0 {
        let target = userTargets.dailyIncome
        return target > 0 ? "\(income)/\(target)" : income
    } else {
        // Week, Month, Year - just show income
        return income
    }
}
```

**Reason**: 
- Daily targets are most actionable (user can adjust today)
- Weekly/monthly targets displayed in Performance Card instead
- Avoids cluttering the main stats

---

## Performance Card Logic

**File**: `DashboardPerformanceCard.swift`

### Purpose

Expandable card showing progress toward targets with color-coded indicators.

### Overall Performance Calculation

**Lines 22-38**:

```swift
private var overallPerformance: Double {
    var performances: [Double] = []
    let targets = getTargetsForPeriod()
    
    // Hours performance
    if targets.hours > 0 && currentStats.hours > 0 {
        performances.append((currentStats.hours / targets.hours) * 100)
    }
    
    // Sales performance
    if targets.sales > 0 && currentStats.sales > 0 {
        performances.append((currentStats.sales / targets.sales) * 100)
    }
    
    // Tip % performance
    if targets.tipPercentage > 0 && currentStats.tipPercentage > 0 {
        performances.append((currentStats.tipPercentage / targets.tipPercentage) * 100)
    }
    
    guard !performances.isEmpty else { return 0 }
    
    // Average of all performance metrics
    return performances.reduce(0, +) / Double(performances.count)
}
```

**Example**:
```
Targets: 40 hours, $2,000 sales, 18% tip
Actual: 35 hours, $2,200 sales, 16% tip

Hours: (35 / 40) × 100 = 87.5%
Sales: (2,200 / 2,000) × 100 = 110%
Tip %: (16 / 18) × 100 = 88.9%

Overall: (87.5 + 110 + 88.9) / 3 = 95.5%
```

### Performance Color Coding

**Lines 40-49**:

```swift
private var performanceColor: Color {
    let percentage = overallPerformance
    if percentage >= 95 {
        return .green      // Excellent
    } else if percentage >= 80 {
        return .orange     // Good
    } else {
        return .red        // Needs improvement
    }
}
```

### Performance Icon

**Lines 51-60**:

```swift
private var performanceIcon: String {
    let percentage = overallPerformance
    if percentage >= 95 {
        return "🟢"
    } else if percentage >= 80 {
        return "🟡"
    } else {
        return "🔴"
    }
}
```

### Individual Target Rows

**Lines 186-228**:

```swift
private func targetRow(
    name: String,
    actual: Double,
    target: Double,
    suffix: String,
    isCurrency: Bool
) -> some View {
    let percentage = target > 0 ? (actual / target) * 100 : 0
    let statusIcon = getStatusIcon(percentage: percentage)
    let progressColor = getProgressColor(percentage: percentage)
    
    return VStack(alignment: .leading, spacing: 6) {
        // Status icon + Name + Percentage
        HStack {
            Text(statusIcon)  // ✅ ⚠️ or 📊
            Text(name + ":")
            Text("\(Int(percentage))%")
                .foregroundStyle(progressColor)
            Spacer()
        }
        
        // Actual / Target values
        Text("\(actual) / \(target)" + suffix)
            .font(.caption)
        
        // Progress bar
        ProgressView(value: min(actual / target, 1.0))
            .tint(progressColor)
    }
}
```

**Status Icons** (Lines 295-303):
```swift
if percentage >= 95 { return "✅" }      // On track
else if percentage >= 80 { return "⚠️" } // Warning
else { return "📊" }                     // Needs attention
```

### Variable Schedule Mode

**Lines 239-247**:

```swift
// For variable schedule users, only use daily targets
if hasVariableSchedule {
    return (
        hours: userTargets.dailyHours,
        tips: userTargets.dailyIncome,
        sales: effectiveSalesTarget,
        tipPercentage: userTargets.tipTargetPercentage
    )
}
```

**Purpose**: Users with irregular schedules only see daily targets regardless of selected period.

---

## Week Start Day

### User Preference

**Stored in**: `users_profile.week_start`

**Values**:
- `0` = Sunday (default)
- `1` = Monday
- `2` = Tuesday
- etc.

### Why It Matters

Different users/industries have different "start of week":
- **Retail/Service**: Often Monday
- **Traditional**: Often Sunday
- **European**: Usually Monday

### Calculation Algorithm

**File**: `DashboardMetrics.swift` lines 214-218

```swift
static func getStartOfWeek(for date: Date, weekStartDay: Int) -> Date {
    let calendar = Calendar.current
    let currentWeekday = calendar.component(.weekday, from: date) - 1
    let daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
    return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
}
```

### Worked Examples

#### Example 1: Monday Start
```
Today: Thursday, October 10, 2024
weekStartDay: 1 (Monday)

Step 1: Get current weekday
calendar.component(.weekday, from: today) = 5 (Thursday)
currentWeekday = 5 - 1 = 4

Step 2: Calculate days to subtract
daysToSubtract = (4 - 1 + 7) % 7 = 10 % 7 = 3

Step 3: Subtract days
weekStart = Oct 10 - 3 days = October 7, 2024 (Monday) ✓
```

#### Example 2: Sunday Start
```
Today: Thursday, October 10, 2024
weekStartDay: 0 (Sunday)

Step 1: currentWeekday = 4

Step 2: daysToSubtract = (4 - 0 + 7) % 7 = 11 % 7 = 4

Step 3: weekStart = Oct 10 - 4 days = October 6, 2024 (Sunday) ✓
```

#### Example 3: Edge Case - Today IS Week Start
```
Today: Monday, October 7, 2024
weekStartDay: 1 (Monday)

Step 1: currentWeekday = 1 (Monday) - 1 = 0

Step 2: daysToSubtract = (0 - 1 + 7) % 7 = 6 % 7 = 6

Wait, that's wrong! Let's trace:
(0 - 1 + 7) = 6
6 % 7 = 6
Oct 7 - 6 = October 1 (previous Monday)

Actually, this IS correct behavior in the original code!
But let's check the actual iOS behavior...

Actually, looking closer, when today IS the week start:
daysToSubtract = 0 (we want to keep today)

The formula should give 0 when currentWeekday == weekStartDay
(x - x + 7) % 7 = 7 % 7 = 0 ✓

So if today is Monday and week starts Monday:
currentWeekday = 1 - 1 = 0
daysToSubtract = (0 - 1 + 7) % 7 = 6 % 7 = 6
This would go back 6 days... that's a bug!

Wait, let me re-read the formula...

Actually in iOS Swift:
calendar.component(.weekday, from: date) 
Returns: 1 = Sunday, 2 = Monday, ..., 7 = Saturday

So:
Monday: .weekday = 2
Thursday: .weekday = 5

Let's redo:
Today: Monday, October 7, 2024
weekStartDay: 1 (Monday)

currentWeekday = 2 - 1 = 1  (Monday in our 0-indexed system)
daysToSubtract = (1 - 1 + 7) % 7 = 7 % 7 = 0 ✓

weekStart = Oct 7 - 0 = October 7 (today) ✓
```

### Consistency Across App

**Critical**: Same calculation used in:
1. `DashboardCharts.loadAllStats()` - for data filtering
2. `DashboardStatsCards.periodStartDate` - for display
3. `DashboardPerformanceCard.getTargetsForPeriod()` - for targets

**File**: `DashboardStatsCards.swift` lines 29-38

```swift
var periodStartDate: Date? {
    guard selectedPeriod == 1 else { return nil }
    // Uses SAME function as data loading
    return DashboardMetrics.getStartOfWeek(for: Date(), weekStartDay: weekStartDay)
}

var periodEndDate: Date? {
    guard selectedPeriod == 1, let startDate = periodStartDate else { return nil }
    // Week is ALWAYS 7 days
    return Calendar.current.date(byAdding: .day, value: 6, to: startDate)
}
```

---

## Stats Aggregation

### Period State Management

**File**: `DashboardView.swift` lines 7-15

```swift
@State private var todayStats = DashboardMetrics.Stats()
@State private var weekStats = DashboardMetrics.Stats()
@State private var monthStats = DashboardMetrics.Stats()
@State private var yearStats = DashboardMetrics.Stats()
@State private var fourWeeksStats = DashboardMetrics.Stats()
@State private var selectedPeriod = 0  // 0=Today, 1=Week, 2=Month, 3=Year
@State private var monthViewType = 0   // 0=Calendar Month, 1=4 Weeks
```

### Current Stats Selector

**Lines 306-315**:

```swift
var currentStats: DashboardMetrics.Stats {
    switch selectedPeriod {
    case 1: return weekStats
    case 2:
        // Month tab - check view type
        return monthViewType == 0 ? monthStats : fourWeeksStats
    case 3: return yearStats
    default: return todayStats
    }
}
```

**Display Logic**:
- User selects period via `DashboardPeriodSelector`
- `selectedPeriod` binding updates
- `currentStats` computed property returns appropriate stats
- UI re-renders with new stats

### Preload All Stats

**Lines 340-377**:

```swift
func preloadAllStats(forceRefresh: Bool = false) async {
    isLoading = true
    defer {
        isLoading = false
        statsPreloaded = true
    }
    
    // Single call loads all periods
    let result = await DashboardCharts.loadAllStats(
        forceRefresh: forceRefresh,
        defaultHourlyRate: defaultHourlyRate,
        averageDeductionPercentage: averageDeductionPercentage
    )
    
    await MainActor.run {
        // Clear if force refresh
        if forceRefresh {
            todayStats = Stats()
            weekStats = Stats()
            monthStats = Stats()
            yearStats = Stats()
            fourWeeksStats = Stats()
        }
        
        // Update with fresh data
        todayStats = result.todayStats
        weekStats = result.weekStats
        monthStats = result.monthStats
        yearStats = result.yearStats
        fourWeeksStats = result.fourWeeksStats
    }
}
```

**When Called**:
1. **Initial Load**: `.task { await performInitialLoad() }` (line 277-278)
2. **Refresh**: Pull-to-refresh gesture (line 54-56)
3. **Return from Edit**: After editing shift/entry (line 265)
4. **Manual Refresh**: On appear after being backgrounded (line 212)

---

## Display Components

### Stats Cards

**File**: `DashboardStatsCards.swift`

#### Structure

```
GlassEffectContainer
    ↓
VStack
    ↓
    - DashboardPerformanceCard (expandable)
    - Sales Section
    - Income Section (Net Salary with Gross subtitle)
    - Hours Section
    - Tips Section (with % of sales)
    - Other Section (if > 0)
    - Subtotal
    - Tip Out Section (if > 0)
    - Divider
    - Total Income (NET revenue)
    - Show Details Button
```

#### Sales Section

**Lines 104-122**:

```swift
CompactGlassStatCard(
    title: "Sales",
    value: formatCurrency(currentStats.sales),
    icon: "cart.fill",
    color: .purple,
    subtitle: selectedPeriod == 0 && getSalesTarget() > 0
        ? "% of target: \(percentage)%"
        : nil
)
```

**Subtitle shown ONLY for Today tab with target set**

#### Income Section

**Lines 124-132**:

```swift
CompactGlassStatCard(
    title: "Expected Net Salary",
    value: formatCurrency(netIncome(deductionPercentage: ...)),
    icon: "dollarsign.circle.fill",
    color: .blue,
    subtitle: "Total Gross Salary: \(grossIncome)"
)
```

**Key Point**: 
- Main display: **Net** salary (after deductions)
- Subtitle: **Gross** salary (before deductions)

#### Total Income Calculation

**Lines 200-214**:

```swift
Text(formatCurrency(currentStats.totalRevenue))
```

Where `totalRevenue` is:
```swift
// From DashboardMetrics.calculateStats()
let netSalary = stats.income * (1 - averageDeductionPercentage / 100)
stats.totalRevenue = netSalary + stats.tips + stats.other - stats.tipOut
```

### Period Selector

**File**: `DashboardPeriodSelector.swift`

Tabs:
- **Today** (0)
- **Week** (1)
- **Month** (2) - with sub-toggle for Calendar Month / 4 Weeks
- **Year** (3)

---

## Common Patterns

### 1. Force Refresh Pattern

```swift
// Pull to refresh
.refreshable {
    await performRefresh()
}

async func performRefresh() {
    statsPreloaded = false  // Reset flag
    await preloadAllStats(forceRefresh: true)  // Force fresh data
    await loadTargets()
    // Check achievements/alerts
}
```

### 2. Cache Invalidation After Edit

```swift
// In AddEntryView after saving
DashboardCharts.invalidateCache()

// In AddShiftView after saving
DashboardCharts.invalidateCache()

// Next dashboard load will fetch fresh data
```

### 3. Deduction Percentage Usage

**Two Purposes**:
1. **Display**: Show Net Salary on cards
2. **Snapshot**: Store in shift_entry for historical accuracy

**Calculation**:
```swift
@AppStorage("averageDeductionPercentage") var deductionPct: Double = 30.0

// Display Net
let netSalary = grossSalary * (1 - deductionPct / 100)

// Store in entry
shiftEntry.deduction_percentage = deductionPct
shiftEntry.net_income = totalIncome * (1 - deductionPct / 100)
```

### 4. Filtering Worked Shifts

**Always use**:
```swift
shifts.filter { $0.has_earnings }
```

**Why**: Exclude planned/missed shifts from stats

### 5. Date Formatting Consistency

**Always use**:
```swift
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
```

**For comparisons**: Use string format (`"2024-10-12"`)
**For display**: Convert back to Date, then format with locale

### 6. Target Progress Colors

**Standard across app**:
```swift
func getProgressColor(percentage: Double) -> Color {
    if percentage >= 100 { return .green }       // Target met
    else if percentage >= 75 { return .purple }  // Close
    else if percentage >= 50 { return .orange }  // Half way
    else { return .red }                         // Far from target
}
```

### 7. Performance Optimization

**Key Techniques**:
1. **Single Query**: Load year data once
2. **In-Memory Filtering**: Filter cached data by period
3. **5-Minute Cache**: Avoid repeated queries
4. **Concurrent Loading**: Load targets and stats in parallel
5. **Lazy Calculation**: Compute stats only when period changes

### 8. Error Handling

```swift
do {
    let stats = try await loadStats()
} catch {
    print("Error loading stats: \(error)")
    // Return empty stats (graceful degradation)
    return Stats()
}
```

**Pattern**: Never crash, always return empty/default data

---

## Summary: Key Takeaways

1. **Single Query Architecture**: Load year data once, filter in memory (5x faster)
2. **5-Minute Cache**: Reduces database load, invalidated on edits
3. **Week Start Flexibility**: User-configurable week start day affects all calculations
4. **Two-Level Targets**: Default + per-shift overrides for sales targets
5. **Net vs Gross**: Display NET salary prominently, show gross in subtitle
6. **Filter Worked Shifts**: Always use `has_earnings` filter for stats
7. **Consistent Date Format**: "yyyy-MM-dd" strings for all comparisons
8. **Performance Card**: Expandable card shows progress toward all targets
9. **Year Target Scaling**: Year targets scale by current month (e.g., 10 months = 10× monthly target)
10. **4 Weeks Mode**: Alternative to calendar month for pay period tracking

---

## Formulas Quick Reference

### Total Revenue (Final Number)
```
Gross Salary = Σ(hours × hourlyRate) for all shifts
Net Salary = Gross Salary × (1 - deductionPercentage / 100)
Total Revenue = Net Salary + Tips + Other - Tip Out
```

### Tip Percentage
```
Tip % = (Total Tips / Total Sales) × 100
```

### Target Progress
```
Progress % = (Actual / Target) × 100
```

### Week Start Calculation
```
currentWeekday = calendar.weekday(today) - 1
daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
weekStart = today - daysToSubtract days
```

### Overall Performance
```
Performance = Average of all metric progress percentages
(hoursProgress + salesProgress + tipProgress) / count
```

---

## File Reference

| File | Purpose |
|------|---------|
| `DashboardView.swift` | Main coordinator, state management |
| `DashboardCharts.swift` | Data loading, caching, conversion |
| `DashboardMetrics.swift` | Calculations, utilities, formatting |
| `DashboardStatsCards.swift` | Stats display component |
| `DashboardPerformanceCard.swift` | Target progress tracking |
| `DashboardPeriodSelector.swift` | Period selection UI |

---

**Generated**: October 12, 2025  
**For**: Android agent reference  
**Author**: Claude (iOS codebase analysis)

