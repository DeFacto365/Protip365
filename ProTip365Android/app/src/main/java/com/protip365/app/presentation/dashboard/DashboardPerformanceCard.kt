package com.protip365.app.presentation.dashboard

import androidx.compose.animation.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.protip365.app.presentation.localization.DashboardLocalization
import java.text.NumberFormat
import java.util.*

@Composable
fun DashboardPerformanceCard(
    currentStats: DashboardState,
    userTargets: DashboardMetrics.UserTargets,
    selectedPeriod: DashboardPeriod,
    monthViewType: MonthViewType,
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
                text = "${localization.performanceText}:",
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
    currentStats: DashboardState,
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
                name = localization.hoursLabel,
                actual = currentStats.totalHours,
                target = targets.hours,
                suffix = " ${localization.hoursShortText}",
                isCurrency = false,
                localization = localization
            )
        }

        // Sales
        if (targets.sales > 0) {
            MetricRow(
                name = localization.salesLabel,
                actual = currentStats.totalSales,
                target = targets.sales,
                suffix = "",
                isCurrency = true,
                localization = localization
            )
        }

        // Tip Percentage (combines both tip amount and percentage tracking)
        // Note: We only show Tip % to avoid redundancy with Tips dollar amount
        if (targets.tipPercentage > 0 && currentStats.averageTipPercentage > 0) {
            MetricRow(
                name = localization.tipPercentageText,
                actual = currentStats.averageTipPercentage,
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
            progress = { minOf(actual / target, 1.0).toFloat() },
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
            text = localization.setTargetsPromptText,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

// Helper Functions

private fun getTargetsForPeriod(
    selectedPeriod: DashboardPeriod,
    monthViewType: MonthViewType,
    userTargets: DashboardMetrics.UserTargets,
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
        DashboardPeriod.TODAY -> {
            PerformanceTargets(
                hours = userTargets.dailyHours,
                tips = userTargets.dailyIncome,
                sales = userTargets.dailySales,
                tipPercentage = userTargets.tipTargetPercentage
            )
        }
        DashboardPeriod.WEEK -> {
            PerformanceTargets(
                hours = userTargets.weeklyHours,
                tips = userTargets.weeklyIncome,
                sales = userTargets.weeklySales,
                tipPercentage = userTargets.tipTargetPercentage
            )
        }
        DashboardPeriod.MONTH -> {
            if (monthViewType == MonthViewType.FOUR_WEEKS && userTargets.weeklyHours > 0) {
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
        DashboardPeriod.YEAR -> {
            val calendar = Calendar.getInstance()
            val currentMonth = calendar.get(Calendar.MONTH) + 1 // 1-12
            PerformanceTargets(
                hours = userTargets.monthlyHours * currentMonth,
                tips = userTargets.monthlyIncome * currentMonth,
                sales = userTargets.monthlySales * currentMonth,
                tipPercentage = userTargets.tipTargetPercentage
            )
        }
        DashboardPeriod.FOUR_WEEKS -> {
            PerformanceTargets(
                hours = userTargets.weeklyHours * 4,
                tips = userTargets.weeklyIncome * 4,
                sales = userTargets.weeklySales * 4,
                tipPercentage = userTargets.tipTargetPercentage
            )
        }
        DashboardPeriod.CUSTOM -> PerformanceTargets()
    }
}

private fun calculateOverallPerformance(
    stats: DashboardState,
    targets: PerformanceTargets
): Double {
    val performances = mutableListOf<Double>()

    if (targets.hours > 0 && stats.totalHours > 0) {
        performances.add((stats.totalHours / targets.hours) * 100)
    }
    if (targets.sales > 0 && stats.totalSales > 0) {
        performances.add((stats.totalSales / targets.sales) * 100)
    }
    if (targets.tipPercentage > 0 && stats.averageTipPercentage > 0) {
        performances.add((stats.averageTipPercentage / targets.tipPercentage) * 100)
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
        val formatter = NumberFormat.getCurrencyInstance(Locale.US)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.format(value)
    } else {
        String.format("%.1f", value)
    }
}
