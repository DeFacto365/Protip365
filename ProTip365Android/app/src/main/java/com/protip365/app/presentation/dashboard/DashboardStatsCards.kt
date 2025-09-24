package com.protip365.app.presentation.dashboard

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.NumberFormat
import java.util.Locale

data class DashboardStats(
    val totalRevenue: Double = 0.0,
    val totalWages: Double = 0.0,
    val totalTips: Double = 0.0,
    val totalHours: Double = 0.0,
    val totalSales: Double = 0.0,
    val totalTipOut: Double = 0.0,
    val otherIncome: Double = 0.0,
    val averageTipPercentage: Double = 0.0,
    val hourlyRate: Double = 0.0,
    val revenueChange: Double = 0.0,
    val wagesChange: Double = 0.0,
    val tipsChange: Double = 0.0,
    val hoursChange: Double = 0.0,
    val salesChange: Double = 0.0,
    val tipOutChange: Double = 0.0,
    val otherChange: Double = 0.0
)

data class UserTargets(
    val tipTargetPercentage: Double = 20.0,
    val targetSalesDaily: Double? = null,
    val targetSalesWeekly: Double? = null,
    val targetSalesMonthly: Double? = null,
    val targetHoursDaily: Double? = null,
    val targetHoursWeekly: Double? = null,
    val targetHoursMonthly: Double? = null
)

@Composable
fun DashboardStatsCards(
    currentStats: DashboardStats,
    userTargets: UserTargets,
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
        // Main revenue card
        MainRevenueCard(
            totalRevenue = currentStats.totalRevenue,
            revenueChange = currentStats.revenueChange,
            selectedPeriod = selectedPeriod,
            currentLanguage = currentLanguage,
            onClick = { onDetailClick("revenue") }
        )

        // Stats grid
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            modifier = Modifier
                .fillMaxWidth()
                .height(400.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                StatCard(
                    title = when (currentLanguage) {
                        "fr" -> "Salaire/Gages"
                        "es" -> "Salario/Sueldos"
                        else -> "Salary/Wages"
                    },
                    value = formatCurrency(currentStats.totalWages),
                    change = currentStats.wagesChange,
                    icon = Icons.Default.AttachMoney,
                    onClick = { onDetailClick("wages") }
                )
            }
            item {
                StatCard(
                    title = when (currentLanguage) {
                        "fr" -> "Pourboires"
                        "es" -> "Propinas"
                        else -> "Tips"
                    },
                    value = formatCurrency(currentStats.totalTips),
                    subtitle = "${String.format("%.1f", currentStats.averageTipPercentage)}%",
                    change = currentStats.tipsChange,
                    icon = Icons.Default.MonetizationOn,
                    targetPercentage = if (currentStats.totalSales > 0)
                        (currentStats.totalTips / currentStats.totalSales * 100) / userTargets.tipTargetPercentage * 100
                    else null,
                    onClick = { onDetailClick("tips") }
                )
            }
            item {
                StatCard(
                    title = when (currentLanguage) {
                        "fr" -> "Heures"
                        "es" -> "Horas"
                        else -> "Hours"
                    },
                    value = String.format("%.1f", currentStats.totalHours),
                    subtitle = "${formatCurrency(currentStats.hourlyRate)}/hr",
                    change = currentStats.hoursChange,
                    icon = Icons.Default.Schedule,
                    targetPercentage = getTargetProgress(
                        currentStats.totalHours,
                        userTargets,
                        selectedPeriod,
                        "hours"
                    ),
                    onClick = { onDetailClick("hours") }
                )
            }
            item {
                StatCard(
                    title = when (currentLanguage) {
                        "fr" -> "Ventes"
                        "es" -> "Ventas"
                        else -> "Sales"
                    },
                    value = formatCurrency(currentStats.totalSales),
                    change = currentStats.salesChange,
                    icon = Icons.Default.ShoppingCart,
                    targetPercentage = getTargetProgress(
                        currentStats.totalSales,
                        userTargets,
                        selectedPeriod,
                        "sales"
                    ),
                    onClick = { onDetailClick("sales") }
                )
            }
            item {
                StatCard(
                    title = when (currentLanguage) {
                        "fr" -> "Partage"
                        "es" -> "Compartir"
                        else -> "Tip-out"
                    },
                    value = formatCurrency(currentStats.totalTipOut),
                    change = currentStats.tipOutChange,
                    icon = Icons.Default.Share,
                    onClick = { onDetailClick("tipout") }
                )
            }
            item {
                StatCard(
                    title = when (currentLanguage) {
                        "fr" -> "Autre"
                        "es" -> "Otro"
                        else -> "Other"
                    },
                    value = formatCurrency(currentStats.otherIncome),
                    change = currentStats.otherChange,
                    icon = Icons.Default.MoreHoriz,
                    onClick = { onDetailClick("other") }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MainRevenueCard(
    totalRevenue: Double,
    revenueChange: Double,
    selectedPeriod: Int,
    currentLanguage: String,
    onClick: () -> Unit
) {
    // Removed background - just text on transparent background
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp)
            .clickable { onClick() },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = when (currentLanguage) {
                "fr" -> "Revenu Total"
                "es" -> "Ingresos Totales"
                else -> "Total Revenue"
            },
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = formatCurrency(totalRevenue),
            style = MaterialTheme.typography.displayMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
        if (revenueChange != 0.0) {
            Spacer(modifier = Modifier.height(8.dp))
            ChangeIndicator(change = revenueChange)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun StatCard(
    title: String,
    value: String,
    subtitle: String? = null,
    change: Double,
    icon: ImageVector,
    targetPercentage: Double? = null,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left side - Text content
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Text(
                    text = value,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                if (subtitle != null) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                }
                targetPercentage?.let { percentage ->
                    Spacer(modifier = Modifier.height(8.dp))
                    LinearProgressIndicator(
                        progress = { (percentage / 100.0).coerceIn(0.0, 1.0).toFloat() },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(4.dp)
                            .clip(RoundedCornerShape(2.dp)),
                        color = when {
                            percentage >= 100 -> Color(0xFF4CAF50)
                            percentage >= 75 -> Color(0xFFFFC107)
                            else -> MaterialTheme.colorScheme.primary
                        }
                    )
                }
            }
            
            // Right side - Icon and change indicator
            Column(
                horizontalAlignment = Alignment.End,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    modifier = Modifier.size(32.dp), // Made bigger
                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.7f)
                )
                if (change != 0.0) {
                    ChangeIndicator(change = change, small = true)
                }
            }
        }
    }
}

@Composable
private fun ChangeIndicator(change: Double, small: Boolean = false) {
    val isPositive = change > 0
    val color by animateColorAsState(
        targetValue = if (isPositive) Color(0xFF4CAF50) else Color(0xFFF44336),
        label = "changeColor"
    )

    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(color.copy(alpha = 0.1f))
            .padding(horizontal = if (small) 6.dp else 8.dp, vertical = if (small) 2.dp else 4.dp)
    ) {
        Icon(
            imageVector = if (isPositive) Icons.Default.TrendingUp else Icons.Default.TrendingDown,
            contentDescription = null,
            modifier = Modifier.size(if (small) 12.dp else 16.dp),
            tint = color
        )
        Spacer(modifier = Modifier.width(2.dp))
        Text(
            text = "${if (isPositive) "+" else ""}${String.format("%.1f", change)}%",
            style = if (small) MaterialTheme.typography.labelSmall else MaterialTheme.typography.labelMedium,
            color = color,
            fontWeight = FontWeight.Medium
        )
    }
}

private fun formatCurrency(amount: Double): String {
    val format = NumberFormat.getCurrencyInstance(Locale.US)
    return format.format(amount)
}

private fun getTargetProgress(
    value: Double,
    targets: UserTargets,
    selectedPeriod: Int,
    type: String
): Double? {
    return when (type) {
        "sales" -> when (selectedPeriod) {
            0 -> targets.targetSalesDaily?.let { (value / it) * 100 }
            1 -> targets.targetSalesWeekly?.let { (value / it) * 100 }
            2 -> targets.targetSalesMonthly?.let { (value / it) * 100 }
            else -> null
        }
        "hours" -> when (selectedPeriod) {
            0 -> targets.targetHoursDaily?.let { (value / it) * 100 }
            1 -> targets.targetHoursWeekly?.let { (value / it) * 100 }
            2 -> targets.targetHoursMonthly?.let { (value / it) * 100 }
            else -> null
        }
        else -> null
    }
}