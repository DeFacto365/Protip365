package com.protip365.app.presentation.detail

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.protip365.app.data.model.ShiftIncome
import java.text.NumberFormat
import java.util.Locale

@Composable
fun DetailStatsSection(
    shifts: List<ShiftIncome>,
    localization: DetailLocalization,
    averageDeductionPercentage: Double,
    targetAmount: Double,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        IncomeBreakdownCard(
            shifts = shifts,
            localization = localization,
            averageDeductionPercentage = averageDeductionPercentage,
            targetIncome = targetAmount,
            targetTips = targetAmount
        )
        
        PerformanceMetricsCard(
            shifts = shifts,
            localization = localization,
            targetSales = targetAmount,
            targetHours = 0.0
        )
    }
}

@Composable
private fun IncomeBreakdownCard(
    shifts: List<ShiftIncome>,
    localization: DetailLocalization,
    averageDeductionPercentage: Double,
    targetIncome: Double,
    targetTips: Double
) {
    val grossSalary = shifts.sumOf { it.base_income ?: ((it.hours ?: 0.0) * it.hourly_rate) }
    val netSalary = grossSalary * (1 - averageDeductionPercentage / 100)
    val totalTips = shifts.sumOf { it.tips ?: 0.0 }
    val totalIncome = netSalary + totalTips
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = localization.incomeBreakdownText,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            StatRow(
                label = localization.grossSalaryText,
                value = formatCurrency(grossSalary)
            )
            
            StatRow(
                label = localization.netSalaryText,
                value = formatCurrency(netSalary)
            )
            
            StatRow(
                label = localization.tipsText,
                value = formatCurrency(totalTips),
                target = if (targetTips > 0) formatCurrency(targetTips) else null,
                progress = if (targetTips > 0) (totalTips / targetTips).toFloat().coerceIn(0f, 1f) else null
            )
            
            HorizontalDivider()
            
            StatRow(
                label = localization.totalIncomeText,
                value = formatCurrency(totalIncome),
                isBold = true,
                target = if (targetIncome > 0) formatCurrency(targetIncome) else null,
                progress = if (targetIncome > 0) (totalIncome / targetIncome).toFloat().coerceIn(0f, 1f) else null
            )
        }
    }
}

@Composable
private fun PerformanceMetricsCard(
    shifts: List<ShiftIncome>,
    localization: DetailLocalization,
    targetSales: Double,
    targetHours: Double
) {
    val totalSales = shifts.sumOf { it.sales ?: 0.0 }
    val totalHours = shifts.sumOf { it.hours ?: 0.0 }
    val totalTips = shifts.sumOf { it.tips ?: 0.0 }
    val totalIncome = shifts.sumOf { it.total_income ?: 0.0 }
    
    val avgHourlyRate = if (totalHours > 0) totalIncome / totalHours else 0.0
    val tipPercent = if (totalSales > 0) (totalTips / totalSales) * 100 else 0.0
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = localization.performanceMetricsText,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            StatRow(
                label = localization.totalSalesText,
                value = formatCurrency(totalSales),
                target = if (targetSales > 0) formatCurrency(targetSales) else null,
                progress = if (targetSales > 0) (totalSales / targetSales).toFloat().coerceIn(0f, 1f) else null
            )
            
            StatRow(
                label = localization.totalHoursText,
                value = String.format(Locale.getDefault(), "%.1f", totalHours),
                target = if (targetHours > 0) String.format(Locale.getDefault(), "%.1f", targetHours) else null,
                progress = if (targetHours > 0) (totalHours / targetHours).toFloat().coerceIn(0f, 1f) else null
            )
            
            StatRow(
                label = localization.avgHourlyRateText,
                value = formatCurrency(avgHourlyRate)
            )
            
            if (totalSales > 0) {
                StatRow(
                    label = localization.tipPercentText,
                    value = String.format(Locale.getDefault(), "%.1f%%", tipPercent)
                )
            }
        }
    }
}

@Composable
private fun StatRow(
    label: String,
    value: String,
    isBold: Boolean = false,
    target: String? = null,
    progress: Float? = null
) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isBold) FontWeight.Bold else FontWeight.Normal,
                color = if (isBold) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
            )
        }
        
        if (target != null && progress != null) {
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                LinearProgressIndicator(
                    progress = progress,
                    modifier = Modifier.weight(1f),
                    color = MaterialTheme.colorScheme.primary,
                    trackColor = MaterialTheme.colorScheme.surfaceVariant
                )
                Text(
                    text = target,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

private fun formatCurrency(amount: Double): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale.getDefault())
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.format(amount)
}

