package com.protip365.app.presentation.dashboard

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.protip365.app.R
import com.protip365.app.presentation.components.BreathingGradient
import com.protip365.app.presentation.components.RollingCounter
import com.protip365.app.presentation.components.EarningsChart
import com.protip365.app.utils.localizedString
import android.view.HapticFeedbackConstants
import androidx.compose.ui.platform.LocalView
import java.text.NumberFormat
import java.time.format.TextStyle
import java.util.Locale

/**
 * iOS-style Dashboard Stats Cards
 * 1. Hero Card (Revenue)
 * 2. 2x2 Grid (Sales, Tips, Hours, Net)
 * 3. Collapsible Details (Other, Tip Out, Gross)
 */
@Composable
fun DashboardStatsCards(
    currentStats: DashboardState,
    userTargets: DashboardMetrics.UserTargets,
    selectedPeriod: Int,
    monthViewType: Int,
    averageDeductionPercentage: Double,
    defaultHourlyRate: Double,
    currentLanguage: String = "en",
    onDetailClick: (String) -> Unit = {}
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        
        // 1. HERO CARD: Total Earnings
        HeroStatCard(
            title = localizedString(R.string.total_income_label),
            value = formatCurrency(currentStats.totalRevenue),
            rawValue = currentStats.totalRevenue,
            subtitle = if (currentStats.totalRevenue > 0) "Great work!" else "No earnings yet",
            color = Color(0xFF4CAF50) // Green
        )

        // 2. CHART: Weekly Distribution
        // Only show if we have shifts and are in weekly view (selectedPeriod == 1)
        if (selectedPeriod == 1) {
            val weeklyData = remember(currentStats.shifts) {
                // Transform shifts to weekly data
                // This is a simplified transformation for the chart
                 val days = (0..6).map { dayOffset ->
                    // Simple approach:
                    // 1. Create map of DayOfWeek -> Total
                    val totals = currentStats.shifts.groupBy { 
                        // Assuming shiftDate is ISO string, parse carefully. 
                        // If it fails, fallback to empty. Ideally use safe parsing.
                        try {
                             java.time.LocalDate.parse(it.shiftDate).dayOfWeek 
                        } catch (e: Exception) {
                             java.time.DayOfWeek.MONDAY // Fallback
                        }
                    }.mapValues { entry ->
                        entry.value.sumOf { it.totalEarnings }
                    }
                    
                    // 2. Generate list for Mon-Sun
                    // Assuming Week starts on Monday for display
                    val day = java.time.DayOfWeek.MONDAY.plus(dayOffset.toLong())
                    val dayLabel = day.getDisplayName(TextStyle.SHORT, Locale.getDefault())
                    val amount = totals[day] ?: 0.0
                    
                    dayLabel to amount
                 }
                 days
            }
            
            EarningsChart(
                weeklyData = weeklyData,
                totalForWeek = formatCurrency(currentStats.totalRevenue)
            )
        }

        // 3. GRID: Secondary Stats
        val netSalary = currentStats.totalWages * (1 - averageDeductionPercentage / 100)
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Column 1
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                VerticalStatCard(
                    title = localizedString(R.string.sales_label),
                    value = formatCurrency(currentStats.totalSales),
                    icon = Icons.Default.ShoppingCart,
                    color = Color(0xFF9C27B0) // Purple
                )
                
                VerticalStatCard(
                    title = localizedString(R.string.hours_worked_label),
                    value = String.format("%.1f", currentStats.totalHours),
                    caption = "hours",
                    icon = Icons.Default.Schedule,
                    color = Color(0xFF2196F3) // Blue
                )
            }
            
            // Column 2
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                VerticalStatCard(
                    title = localizedString(R.string.tips_label),
                    value = formatCurrency(currentStats.totalTips),
                    icon = Icons.Default.MonetizationOn,
                    color = Color(0xFF4CAF50) // Green
                )
                
                VerticalStatCard(
                    title = localizedString(R.string.expected_net_salary),
                    value = formatCurrency(netSalary),
                    icon = Icons.Default.AttachMoney,
                    color = Color(0xFFFF9800) // Orange
                )
            }
        }

        // 4. COLLAPSIBLE DETAILS
        var isDetailsExpanded by remember { mutableStateOf(false) }
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.5f)
            )
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                val view = LocalView.current
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { 
                            isDetailsExpanded = !isDetailsExpanded 
                            view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                        }
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = localizedString(R.string.show_details),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Icon(
                        imageVector = if (isDetailsExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                        contentDescription = null
                    )
                }

                AnimatedVisibility(
                    visible = isDetailsExpanded,
                    enter = expandVertically() + fadeIn(),
                    exit = shrinkVertically() + fadeOut()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                            .padding(bottom = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Divider()
                        
                        // Other Income
                        if (currentStats.otherIncome > 0) {
                            DetailRow(
                                label = localizedString(R.string.other_label),
                                value = formatCurrency(currentStats.otherIncome),
                                icon = Icons.AutoMirrored.Filled.List
                            )
                        }

                        // Tip Out
                        if (currentStats.totalTipOut > 0) {
                            DetailRow(
                                label = localizedString(R.string.tip_out_label),
                                value = "-${formatCurrency(currentStats.totalTipOut)}",
                                icon = Icons.Default.RemoveCircle,
                                isNegative = true
                            )
                        }

                        // Gross Salary
                        DetailRow(
                            label = "Gross Salary",
                            value = formatCurrency(currentStats.totalWages),
                            icon = Icons.Default.AccountBalanceWallet
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Components

@Composable
fun HeroStatCard(
    title: String,
    value: String,
    rawValue: Double,
    subtitle: String?,
    color: Color
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        Box(modifier = Modifier.fillMaxWidth()) {
            // Background gradient effect
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .alpha(0.1f)
                    .background(
                        Brush.linearGradient(
                            colors = listOf(color, color.copy(alpha = 0.5f))
                        )
                    )
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 24.dp, horizontal = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = title.uppercase(),
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    letterSpacing = 1.sp
                )

                RollingCounter(
                    value = rawValue,
                    modifier = Modifier.padding(vertical = 4.dp),
                    style = MaterialTheme.typography.displayMedium.copy(
                        fontWeight = FontWeight.ExtraBold,
                        color = color
                    )
                )

                if (subtitle != null) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier
                            .background(
                                MaterialTheme.colorScheme.surfaceVariant,
                                RoundedCornerShape(50)
                            )
                            .padding(horizontal = 12.dp, vertical = 4.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun VerticalStatCard(
    title: String,
    value: String,
    icon: ImageVector,
    color: Color,
    caption: String? = null
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.Start,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Icon
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(color.copy(alpha = 0.1f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(24.dp)
                )
            }

            // Text
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1
                )
                
                Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(
                        text = value,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface,
                        maxLines = 1
                    )
                    
                    if (caption != null) {
                        Text(
                            text = caption,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(bottom = 2.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DetailRow(
    label: String,
    value: String,
    icon: ImageVector,
    isNegative: Boolean = false
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (isNegative) Color.Red else MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(16.dp)
            )
            Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold,
            color = if (isNegative) Color.Red else MaterialTheme.colorScheme.onSurface
        )
    }
}

// Add modifier extension for alpha if needed or use standard Modifier.alpha
// function removed

// Helper to avoid import issues if Modifier.alpha is tricky in some compose versions
private fun formatCurrency(amount: Double): String {
    val format = NumberFormat.getCurrencyInstance(Locale.US)
    return format.format(amount)
}
