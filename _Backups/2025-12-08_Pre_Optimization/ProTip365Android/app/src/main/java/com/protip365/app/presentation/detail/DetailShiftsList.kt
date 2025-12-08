package com.protip365.app.presentation.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.protip365.app.data.model.ShiftIncome
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.Locale

@Composable
fun DetailShiftsList(
    shifts: List<ShiftIncome>,
    localization: DetailLocalization,
    averageDeductionPercentage: Double,
    onEditShift: (ShiftIncome) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = localization.shiftDetailsText,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "${shifts.size} ${if (shifts.size == 1) localization.shiftText else localization.shiftsText}",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        val shiftsByDate = shifts
            .groupBy { it.shift_date }
            .toList()
            .sortedByDescending { it.first }
        
        shiftsByDate.forEach { (date, shiftsForDate) ->
            DayCard(
                date = date,
                shifts = shiftsForDate,
                localization = localization,
                averageDeductionPercentage = averageDeductionPercentage,
                onEditShift = onEditShift
            )
        }
    }
}

@Composable
private fun DayCard(
    date: String,
    shifts: List<ShiftIncome>,
    localization: DetailLocalization,
    averageDeductionPercentage: Double,
    onEditShift: (ShiftIncome) -> Unit
) {
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
                .padding(vertical = 8.dp)
        ) {
            Text(
                text = formatDate(date),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
            )
            
            val sortedShifts = shifts.sortedWith(
                compareBy<ShiftIncome> { it.employer_name ?: "" }
                    .thenByDescending { it.hours ?: 0.0 }
            )
            
            sortedShifts.forEach { shift ->
                DetailShiftCard(
                    shift = shift,
                    localization = localization,
                    averageDeductionPercentage = averageDeductionPercentage,
                    onEditShift = onEditShift,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

private fun formatDate(dateString: String): String {
    return try {
        val inputFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val date = inputFormatter.parse(dateString)
        val outputFormatter = DateFormat.getDateInstance(DateFormat.MEDIUM, Locale.getDefault())
        date?.let { outputFormatter.format(it) } ?: dateString
    } catch (e: Exception) {
        dateString
    }
}

