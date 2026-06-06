package com.protip365.app.presentation.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.protip365.app.data.model.ShiftIncome
import java.text.NumberFormat
import java.util.Locale

@Composable
fun DetailShiftCard(
    shift: ShiftIncome,
    localization: DetailLocalization,
    averageDeductionPercentage: Double,
    onEditShift: (ShiftIncome) -> Unit,
    modifier: Modifier = Modifier
) {
    val haptics = LocalHapticFeedback.current
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable {
                haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                onEditShift(shift)
            },
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            if (shift.employer_name != null) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = shift.employer_name,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(16.dp)
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                ShiftDetailItem(
                    label = localization.hoursText,
                    value = String.format(Locale.getDefault(), "%.1f", shift.hours ?: 0.0),
                    modifier = Modifier.weight(1f)
                )
                
                val grossSalary = shift.base_income ?: ((shift.hours ?: 0.0) * shift.hourly_rate)
                val netSalary = grossSalary * (1 - averageDeductionPercentage / 100)
                ShiftDetailItem(
                    label = localization.netSalaryText,
                    value = formatCurrency(netSalary),
                    modifier = Modifier.weight(1f)
                )
                
                ShiftDetailItem(
                    label = localization.tipsText,
                    value = formatCurrency(shift.tips ?: 0.0),
                    modifier = Modifier.weight(1f)
                )
                
                ShiftDetailItem(
                    label = localization.totalText,
                    value = formatCurrency(shift.total_income ?: 0.0),
                    isBold = true,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun ShiftDetailItem(
    label: String,
    value: String,
    isBold: Boolean = false,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.Start
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = if (isBold) FontWeight.Bold else FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

private fun formatCurrency(amount: Double): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale.getDefault())
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.format(amount)
}

