package com.protip365.app.presentation.dashboard

import androidx.compose.foundation.background
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.protip365.app.R
import com.protip365.app.utils.localizedString
import java.text.NumberFormat
import java.util.Locale

/**
 * iOS-style Dashboard Stats Cards
 * Matches the exact layout from iOS DashboardStatsCards.swift
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
    // iOS-style linear list layout in a single card
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Sales section
            CompactStatRow(
                title = localizedString(R.string.sales_label),
                value = formatCurrency(currentStats.totalSales),
                icon = Icons.Default.ShoppingCart,
                iconColor = Color(0xFF9C27B0), // Purple
                subtitle = if (selectedPeriod == 0 && userTargets.dailySales > 0) {
                    String.format("%.0f%% of target", (currentStats.totalSales / userTargets.dailySales) * 100)
                } else null
            )

            HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))

            // Expected Net Salary section
            val netSalary = currentStats.totalWages * (1 - averageDeductionPercentage / 100)
            CompactStatRow(
                title = localizedString(R.string.expected_net_salary),
                value = formatCurrency(netSalary),
                icon = Icons.Default.AttachMoney,
                iconColor = Color(0xFF2196F3), // Blue
                subtitle = String.format(
                    "Gross Salary: %s",
                    formatCurrency(currentStats.totalWages)
                )
            )

            HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))

            // Hours Worked section
            CompactStatRow(
                title = localizedString(R.string.hours_worked_label),
                value = String.format("%.1f hours", currentStats.totalHours),
                icon = Icons.Default.Schedule,
                iconColor = Color(0xFF2196F3), // Blue
                subtitle = if (selectedPeriod == 0 && userTargets.dailyHours > 0) {
                    String.format("%.0f%% of target", (currentStats.totalHours / userTargets.dailyHours) * 100)
                } else null
            )

            HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))

            // Tips section
            CompactStatRow(
                title = localizedString(R.string.tips_label),
                value = formatCurrency(currentStats.totalTips),
                icon = Icons.Default.MonetizationOn,
                iconColor = Color(0xFF4CAF50), // Green
                subtitle = if (currentStats.averageTipPercentage > 0) {
                    if (selectedPeriod == 0 && userTargets.tipTargetPercentage > 0) {
                        String.format("%.1f%% of sales • Target: %.0f%%",
                            currentStats.averageTipPercentage,
                            userTargets.tipTargetPercentage)
                    } else {
                        String.format("%.1f%% of sales", currentStats.averageTipPercentage)
                    }
                } else null
            )

            // Other section (only if there's other income)
            if (currentStats.otherIncome > 0) {
                HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))
                CompactStatRow(
                    title = localizedString(R.string.other_label),
                    value = formatCurrency(currentStats.otherIncome),
                    icon = Icons.Default.Edit,
                    iconColor = Color(0xFF2196F3), // Blue
                    subtitle = null
                )
            }

            HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))

            // Subtotal
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 4.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = localizedString(R.string.subtotal_label).uppercase(),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = formatCurrency(
                        netSalary + currentStats.totalTips + currentStats.otherIncome
                    ),
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            // Tip Out section (only if there's tip out)
            if (currentStats.totalTipOut > 0) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 4.dp, vertical = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.RemoveCircle,
                            contentDescription = null,
                            tint = Color(0xFFF44336), // Red
                            modifier = Modifier.size(20.dp)
                        )
                        Text(
                            text = localizedString(R.string.tip_out_label),
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFFF44336),
                            fontWeight = FontWeight.Medium
                        )
                    }
                    Text(
                        text = "-${formatCurrency(currentStats.totalTipOut)}",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFFF44336)
                    )
                }
            }

            HorizontalDivider(
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.2f),
                thickness = 1.dp
            )

            // Total Income
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 4.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = localizedString(R.string.total_income_label).uppercase(),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = formatCurrency(currentStats.totalRevenue),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            // Show Details Button
            Button(
                onClick = { onDetailClick("total") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                ),
                shape = RoundedCornerShape(12.dp),
                enabled = currentStats.hasData
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.List,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = localizedString(R.string.show_details),
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

@Composable
private fun CompactStatRow(
    title: String,
    value: String,
    icon: ImageVector,
    iconColor: Color,
    subtitle: String? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Left side - Icon and title
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.weight(1f)
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(
                        iconColor.copy(alpha = 0.15f),
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = iconColor,
                    modifier = Modifier.size(22.dp)
                )
            }

            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                if (subtitle != null) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                }
            }
        }

        // Right side - Value
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

private fun formatCurrency(amount: Double): String {
    val format = NumberFormat.getCurrencyInstance(Locale.US)
    return format.format(amount)
}
