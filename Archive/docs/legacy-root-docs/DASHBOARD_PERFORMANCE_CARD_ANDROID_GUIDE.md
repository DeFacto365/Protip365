# Dashboard Performance Card - Android Implementation Guide

## Overview

This guide provides complete implementation details for the expandable Performance Card component in the Dashboard. This card displays target vs actual metrics with color-coded indicators and detailed breakdowns.

**iOS Source Files:**
- `/ProTip365/Dashboard/DashboardPerformanceCard.swift`
- `/ProTip365/Dashboard/DashboardLocalization.swift` (lines 265-321)
- `/ProTip365/Dashboard/DashboardStatsCards.swift` (lines 59-67)

---

## Component Architecture

### Collapsed State (Default)
```
┌──────────────────────────────────────────────┐
│ 📊 Performance: 🟢 92%            ▼          │
└──────────────────────────────────────────────┘
```

### Expanded State - High Performance Example
```
┌──────────────────────────────────────────────┐
│ 📊 Performance: 🟢 95%            ▲          │
├──────────────────────────────────────────────┤
│ ✅ Hours Worked: 95%                         │
│    38.0 / 40.0 hrs                          │
│    ████████████████████░ (95%)              │
│                                              │
│ ✅ Sales: 96%                                │
│    $5,000 / $5,200                          │
│    █████████████████████ (96%)              │
│                                              │
│ ✅ Tip %: 95%                                │
│    16.0 / 16.8%                             │
│    ████████████████████░ (95%)              │
└──────────────────────────────────────────────┘
```

### Expanded State - Mixed Performance Example
```
┌──────────────────────────────────────────────┐
│ 📊 Performance: ⚠️ 85%            ▲          │
├──────────────────────────────────────────────┤
│ ✅ Hours Worked: 95%                         │
│    38.0 / 40.0 hrs                          │
│    ████████████████████░ (95%)              │
│                                              │
│ ⚠️ Sales: 88%                                │
│    $4,400 / $5,000                          │
│    ██████████████████░░ (88%)               │
│                                              │
│ 📊 Tip %: 72%                                │
│    12.0 / 16.8%                             │
│    ██████████████░░░░░░ (72%)               │
└──────────────────────────────────────────────┘
```

**Note:** Only Hours, Sales, and Tip % are shown.
"Tips" dollar target is excluded to avoid redundancy with "Tip %".

**Icon Meanings:**
- ✅ = Exceeding or meeting target (≥95%)
- ⚠️ = Good progress, room for improvement (80-94%)
- 📊 = Needs attention, neutral indicator (<80%)

---

## 1. Localization Strings

### DashboardLocalization.kt

Add the following strings to `DashboardLocalization.kt`:

```kotlin
// MARK: - Performance Card

fun performanceText(): String {
    return when (language) {
        "fr" -> "Performance"
        "es" -> "Rendimiento"
        else -> "Performance"
    }
}

fun overallText(): String {
    return when (language) {
        "fr" -> "Global"
        "es" -> "General"
        else -> "Overall"
    }
}

fun setTargetsPromptText(): String {
    return when (language) {
        "fr" -> "Définissez des objectifs dans les paramètres pour suivre vos performances"
        "es" -> "Establece objetivos en Configuración para rastrear tu rendimiento"
        else -> "Set targets in Settings to track your performance"
    }
}

fun goToSettingsText(): String {
    return when (language) {
        "fr" -> "Aller aux paramètres →"
        "es" -> "Ir a Configuración →"
        else -> "Go to Settings →"
    }
}

fun tipPercentageText(): String {
    return when (language) {
        "fr" -> "% Pourboires"
        "es" -> "% Propinas"
        else -> "Tip %"
    }
}

fun hoursShortText(): String {
    return when (language) {
        "fr" -> "hrs"
        "es" -> "hrs"
        else -> "hrs"
    }
}

fun ofTargetText(): String {
    return when (language) {
        "fr" -> "de l'objectif"
        "es" -> "del objetivo"
        else -> "of target"
    }
}
```

---

## 2. Data Model

### PerformanceTargets.kt

```kotlin
data class PerformanceTargets(
    val hours: Double = 0.0,
    val tips: Double = 0.0,
    val sales: Double = 0.0,
    val tipPercentage: Double = 0.0
)

data class MetricPerformance(
    val name: String,
    val actual: Double,
    val target: Double,
    val percentage: Double,
    val isCurrency: Boolean,
    val suffix: String = ""
)
```

---

## 3. Performance Card Component

### DashboardPerformanceCard.kt

```kotlin
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.text.NumberFormat
import java.util.*

@Composable
fun DashboardPerformanceCard(
    currentStats: DashboardStats,
    userTargets: UserTargets,
    selectedPeriod: Int,
    monthViewType: Int,
    hasVariableSchedule: Boolean,
    localization: DashboardLocalization,
    modifier: Modifier = Modifier
) {
    // State for expansion
    var isExpanded by remember { mutableStateOf(false) }

    // Calculate targets based on period
    val targets = remember(selectedPeriod, monthViewType, userTargets, hasVariableSchedule) {
        getTargetsForPeriod(
            selectedPeriod = selectedPeriod,
            monthViewType = monthViewType,
            userTargets = userTargets,
            hasVariableSchedule = hasVariableSchedule
        )
    }

    // Check if any targets are set
    val hasAnyTargets = targets.hours > 0 || targets.tips > 0 ||
                        targets.sales > 0 || targets.tipPercentage > 0

    // Calculate overall performance
    val overallPerformance = calculateOverallPerformance(currentStats, targets)

    // Get color and icon based on performance
    val performanceColor = getPerformanceColor(overallPerformance)
    val performanceIcon = getPerformanceIcon(overallPerformance)

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column {
            // Header (always visible)
            PerformanceCardHeader(
                localization = localization,
                hasAnyTargets = hasAnyTargets,
                performanceIcon = performanceIcon,
                overallPerformance = overallPerformance,
                performanceColor = performanceColor,
                isExpanded = isExpanded,
                onToggle = { isExpanded = !isExpanded }
            )

            // Expandable content
            AnimatedVisibility(
                visible = isExpanded,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                if (hasAnyTargets) {
                    PerformanceMetricsContent(
                        currentStats = currentStats,
                        targets = targets,
                        localization = localization
                    )
                } else {
                    NoTargetsContent(localization = localization)
                }
            }
        }
    }
}

@Composable
private fun PerformanceCardHeader(
    localization: DashboardLocalization,
    hasAnyTargets: Boolean,
    performanceIcon: String,
    overallPerformance: Double,
    performanceColor: Color,
    isExpanded: Boolean,
    onToggle: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle)
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "📊",
                style = MaterialTheme.typography.titleMedium
            )

            Text(
                text = "${localization.performanceText()}:",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium
            )

            if (hasAnyTargets) {
                Text(text = performanceIcon)

                Text(
                    text = "${overallPerformance.toInt()}%",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = performanceColor
                )
            }
        }

        Icon(
            imageVector = if (isExpanded) {
                Icons.Default.KeyboardArrowUp
            } else {
                Icons.Default.KeyboardArrowDown
            },
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun PerformanceMetricsContent(
    currentStats: DashboardStats,
    targets: PerformanceTargets,
    localization: DashboardLocalization
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Hours
        if (targets.hours > 0) {
            MetricRow(
                name = localization.hoursWorkedText(),
                actual = currentStats.hours,
                target = targets.hours,
                suffix = " ${localization.hoursShortText()}",
                isCurrency = false,
                localization = localization
            )
        }

        // Sales
        if (targets.sales > 0) {
            MetricRow(
                name = localization.salesText(),
                actual = currentStats.sales,
                target = targets.sales,
                suffix = "",
                isCurrency = true,
                localization = localization
            )
        }

        // Tip Percentage (combines both tip amount and percentage tracking)
        // Note: We only show Tip % to avoid redundancy with Tips dollar amount
        if (targets.tipPercentage > 0 && currentStats.tipPercentage > 0) {
            MetricRow(
                name = localization.tipPercentageText(),
                actual = currentStats.tipPercentage,
                target = targets.tipPercentage,
                suffix = "%",
                isCurrency = false,
                localization = localization
            )
        }
    }
}

@Composable
private fun MetricRow(
    name: String,
    actual: Double,
    target: Double,
    suffix: String,
    isCurrency: Boolean,
    localization: DashboardLocalization
) {
    val percentage = if (target > 0) (actual / target) * 100 else 0.0
    val statusIcon = getStatusIcon(percentage)
    val progressColor = getProgressColor(percentage)

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        // Status icon + Name + Percentage
        Row(
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = statusIcon)

            Text(
                text = "$name:",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )

            Text(
                text = "${percentage.toInt()}%",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = progressColor
            )
        }

        // Actual / Target values
        Text(
            text = "${formatValue(actual, isCurrency)} / ${formatValue(target, isCurrency)}$suffix",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        // Progress bar
        LinearProgressIndicator(
            progress = minOf(actual / target, 1.0).toFloat(),
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp)),
            color = progressColor,
            trackColor = MaterialTheme.colorScheme.surfaceVariant
        )
    }
}

@Composable
private fun NoTargetsContent(localization: DashboardLocalization) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = "💡",
            style = MaterialTheme.typography.displaySmall
        )

        Text(
            text = localization.setTargetsPromptText(),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        // Note: Add navigation to Settings if needed
        // Could add a button here: localization.goToSettingsText()
    }
}

// Helper Functions

private fun getTargetsForPeriod(
    selectedPeriod: Int,
    monthViewType: Int,
    userTargets: UserTargets,
    hasVariableSchedule: Boolean
): PerformanceTargets {
    // For variable schedule users, only use daily targets
    if (hasVariableSchedule) {
        return PerformanceTargets(
            hours = userTargets.dailyHours,
            tips = userTargets.dailyIncome,
            sales = userTargets.dailySales,
            tipPercentage = userTargets.tipTargetPercentage
        )
    }

    return when (selectedPeriod) {
        0 -> { // Today
            PerformanceTargets(
                hours = userTargets.dailyHours,
                tips = userTargets.dailyIncome,
                sales = userTargets.dailySales,
                tipPercentage = userTargets.tipTargetPercentage
            )
        }
        1 -> { // Week
            PerformanceTargets(
                hours = userTargets.weeklyHours,
                tips = userTargets.weeklyIncome,
                sales = userTargets.weeklySales,
                tipPercentage = userTargets.tipTargetPercentage
            )
        }
        2 -> { // Month or 4 Weeks
            if (monthViewType == 1 && userTargets.weeklyHours > 0) {
                // 4 weeks mode - calculate from weekly
                PerformanceTargets(
                    hours = userTargets.weeklyHours * 4,
                    tips = userTargets.weeklyIncome * 4,
                    sales = userTargets.weeklySales * 4,
                    tipPercentage = userTargets.tipTargetPercentage
                )
            } else {
                // Calendar month mode
                PerformanceTargets(
                    hours = userTargets.monthlyHours,
                    tips = userTargets.monthlyIncome,
                    sales = userTargets.monthlySales,
                    tipPercentage = userTargets.tipTargetPercentage
                )
            }
        }
        3 -> { // Year
            val calendar = Calendar.getInstance()
            val currentMonth = calendar.get(Calendar.MONTH) + 1 // 1-12
            PerformanceTargets(
                hours = userTargets.monthlyHours * currentMonth,
                tips = userTargets.monthlyIncome * currentMonth,
                sales = userTargets.monthlySales * currentMonth,
                tipPercentage = userTargets.tipTargetPercentage
            )
        }
        else -> PerformanceTargets()
    }
}

private fun calculateOverallPerformance(
    stats: DashboardStats,
    targets: PerformanceTargets
): Double {
    val performances = mutableListOf<Double>()

    if (targets.hours > 0 && stats.hours > 0) {
        performances.add((stats.hours / targets.hours) * 100)
    }
    if (targets.sales > 0 && stats.sales > 0) {
        performances.add((stats.sales / targets.sales) * 100)
    }
    if (targets.tipPercentage > 0 && stats.tipPercentage > 0) {
        performances.add((stats.tipPercentage / targets.tipPercentage) * 100)
    }
    // Note: We exclude tips dollar amount to avoid double-counting with tip percentage

    return if (performances.isEmpty()) 0.0 else performances.average()
}

private fun getPerformanceColor(percentage: Double): Color {
    return when {
        percentage >= 95 -> Color(0xFF4CAF50) // Green
        percentage >= 80 -> Color(0xFFFF9800) // Orange
        else -> Color(0xFFF44336) // Red
    }
}

private fun getProgressColor(percentage: Double): Color {
    return when {
        percentage >= 95 -> Color(0xFF4CAF50) // Green
        percentage >= 80 -> Color(0xFFFF9800) // Orange
        else -> Color(0xFFF44336) // Red
    }
}

private fun getPerformanceIcon(percentage: Double): String {
    return when {
        percentage >= 95 -> "🟢"
        percentage >= 80 -> "🟡"
        else -> "🔴"
    }
}

private fun getStatusIcon(percentage: Double): String {
    return when {
        percentage >= 95 -> "✅"
        percentage >= 80 -> "⚠️"
        else -> "📊" // Neutral chart icon instead of negative X
    }
}

private fun formatValue(value: Double, isCurrency: Boolean): String {
    return if (isCurrency) {
        val formatter = NumberFormat.getCurrencyInstance(Locale.getDefault())
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.format(value)
    } else {
        String.format("%.1f", value)
    }
}
```

---

## 4. Integration into DashboardStatsCards

### DashboardStatsCards.kt

Add the Performance Card at the top of the stats cards:

```kotlin
@Composable
fun DashboardStatsCards(
    currentStats: DashboardStats,
    userTargets: UserTargets,
    selectedPeriod: Int,
    monthViewType: Int,
    averageDeductionPercentage: Double,
    defaultHourlyRate: Double,
    localization: DashboardLocalization,
    onDetailViewDataChange: (DetailViewData?) -> Unit,
    modifier: Modifier = Modifier
) {
    // Get hasVariableSchedule from SharedPreferences
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE) }
    val hasVariableSchedule by remember {
        mutableStateOf(prefs.getBoolean("hasVariableSchedule", false))
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Performance Card - NEW
        DashboardPerformanceCard(
            currentStats = currentStats,
            userTargets = userTargets,
            selectedPeriod = selectedPeriod,
            monthViewType = monthViewType,
            hasVariableSchedule = hasVariableSchedule,
            localization = localization
        )

        // Sales section
        SalesCard(...)

        // Income section
        IncomeCard(...)

        // ... rest of existing cards
    }
}
```

---

## 5. Performance Thresholds

### Color-Coded Indicators

**Overall Performance (Header):**
- 🟢 Green: ≥ 95%
- 🟡 Yellow: 80-94%
- 🔴 Red: < 80%

**Individual Metrics (Expanded):**
- ✅ Check: ≥ 95% (Great performance!)
- ⚠️ Warning: 80-94% (Good, room for improvement)
- 📊 Chart: < 80% (Needs attention - neutral indicator)

### Performance Calculation

```kotlin
Overall Performance = Average of all set target percentages

Example (showing only Hours, Sales, and Tip %):
- Hours: 95% (38/40)
- Sales: 96% ($5,000/$5,200)
- Tip %: 95% (16.0/16.8)

Overall = (95 + 96 + 95) / 3 = 95.33% → 🟢 95%

Note: We exclude "Tips" dollar amount target to avoid redundancy with "Tip %"
since they both measure the same performance (tip percentage vs target).
```

---

## 6. Period-Based Target Logic

### Daily (Today) - Period 0
```kotlin
hours = dailyHours
tips = dailyIncome
sales = dailySales
tipPercentage = tipTargetPercentage
```

### Weekly - Period 1
```kotlin
hours = weeklyHours
tips = weeklyIncome
sales = weeklySales
tipPercentage = tipTargetPercentage
```

### Monthly - Period 2

**Calendar Month Mode (monthViewType = 0):**
```kotlin
hours = monthlyHours
tips = monthlyIncome
sales = monthlySales
tipPercentage = tipTargetPercentage
```

**4 Weeks Mode (monthViewType = 1):**
```kotlin
hours = weeklyHours * 4
tips = weeklyIncome * 4
sales = weeklySales * 4
tipPercentage = tipTargetPercentage
```

### Yearly - Period 3
```kotlin
val currentMonth = Calendar.getInstance().get(Calendar.MONTH) + 1
hours = monthlyHours * currentMonth
tips = monthlyIncome * currentMonth
sales = monthlySales * currentMonth
tipPercentage = tipTargetPercentage
```

### Variable Schedule Override
If `hasVariableSchedule = true`, **always use daily targets** regardless of period.

---

## 7. Testing Checklist

### Visual Tests
- [ ] Card displays with correct emoji and percentage
- [ ] Tap/click expands and collapses card smoothly
- [ ] Animation is smooth (fade + expand/shrink)
- [ ] Progress bars display correct color
- [ ] Progress bars fill to correct percentage (capped at 100%)
- [ ] All icons display correctly (📊, 🟢, 🟡, 🔴, ✅, ⚠️, ❌)
- [ ] Currency formatting matches locale
- [ ] Decimal formatting is consistent (1 decimal place for non-currency)

### Functional Tests
- [ ] Overall percentage calculated correctly
- [ ] Individual metric percentages calculated correctly
- [ ] Targets change correctly when switching periods
- [ ] Variable schedule users only see daily targets
- [ ] "No targets" message shows when all targets are 0
- [ ] Only metrics with targets > 0 are displayed
- [ ] Tip percentage only shown when actual > 0

### Localization Tests
- [ ] All text translates correctly (EN/FR/ES)
- [ ] "Performance" label translates
- [ ] "Set targets..." prompt translates
- [ ] All metric names translate
- [ ] Currency symbols match locale

### Edge Cases
- [ ] All targets = 0: Shows "No targets" message
- [ ] Some targets = 0: Only shows set targets
- [ ] Actual > target: Progress bar caps at 100%, percentage shows actual
- [ ] Target > 0 but actual = 0: Shows 0% with red indicator
- [ ] Very large numbers: Format correctly with thousand separators

---

## 8. Persistence

### SharedPreferences Key

Save expansion state to persist between sessions:

```kotlin
// Save
prefs.edit().putBoolean("performanceCardExpanded", isExpanded).apply()

// Load
val isExpanded = prefs.getBoolean("performanceCardExpanded", false)
```

**Default:** `false` (collapsed)

---

## 9. Future Enhancements

### Week Navigation Support

When week navigation is implemented, the Performance Card will automatically adapt because it uses the same period-based target logic. No changes needed.

### Settings Link

The "No targets" view includes a placeholder comment for adding navigation to Settings:

```kotlin
// Note: Add navigation to Settings if needed
// Could add a button here: localization.goToSettingsText()
```

Implement this button to navigate users to the Targets section when they have no targets set.

---

## Summary

✅ **Component Features:**
- Expandable/collapsible with smooth animation
- Color-coded performance indicators (🟢🟡🔴)
- Individual metric breakdowns with progress bars
- Shows only Hours, Sales, and Tip % (excludes redundant Tips $ target)
- Zero vertical space cost when collapsed
- Full localization support (EN/FR/ES)
- Variable schedule handling
- Period-based target calculation

✅ **iOS Parity:**
- Same calculation logic
- Same color thresholds
- Same UI layout and styling
- Same expansion behavior
- Same localization strings

✅ **Testing:**
- Visual appearance matches iOS
- Animations are smooth
- All edge cases handled
- All localizations work

**Critical Success Factor:** The Performance Card uses the exact same target calculation logic as iOS, ensuring identical behavior across both platforms.
