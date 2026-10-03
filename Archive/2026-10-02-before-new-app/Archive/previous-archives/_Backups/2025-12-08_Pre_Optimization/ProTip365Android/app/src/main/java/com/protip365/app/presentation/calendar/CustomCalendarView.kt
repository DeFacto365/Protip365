package com.protip365.app.presentation.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.*

@Composable
fun CustomCalendarView(
    selectedDate: LocalDate,
    shiftsForDate: (LocalDate) -> List<com.protip365.app.data.models.CompletedShift>,
    onDateTapped: (LocalDate) -> Unit,
    language: String = "en"
) {
    val today = LocalDate.now()
    val currentMonth = selectedDate.withDayOfMonth(1)
    val firstDayOfMonth = currentMonth.withDayOfMonth(1)
    val lastDayOfMonth = currentMonth.withDayOfMonth(currentMonth.lengthOfMonth())
    
    // Calculate the first day to show (might be from previous month)
    val firstDayToShow = firstDayOfMonth.with(DayOfWeek.SUNDAY)
    val lastDayToShow = lastDayOfMonth.with(DayOfWeek.SATURDAY)
    
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        // Month header
        MonthHeader(
            month = currentMonth,
            language = language
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Day of week headers
        DayOfWeekHeaders(language = language)
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Calendar grid
        CalendarGrid(
            firstDayToShow = firstDayToShow,
            lastDayToShow = lastDayToShow,
            currentMonth = currentMonth,
            selectedDate = selectedDate,
            today = today,
            shiftsForDate = shiftsForDate,
            onDateTapped = onDateTapped
        )
    }
}

@Composable
fun MonthHeader(
    month: LocalDate,
    language: String
) {
    val monthNames = when (language) {
        "fr" -> listOf(
            "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
            "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
        )
        "es" -> listOf(
            "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
        )
        else -> listOf(
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        )
    }
    
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "${monthNames[month.monthValue - 1]} ${month.year}",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
fun DayOfWeekHeaders(language: String) {
    val dayNames = when (language) {
        "fr" -> listOf("D", "L", "M", "M", "J", "V", "S")
        "es" -> listOf("D", "L", "M", "M", "J", "V", "S")
        else -> listOf("S", "M", "T", "W", "T", "F", "S")
    }
    
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        dayNames.forEach { dayName ->
            Box(
                modifier = Modifier
                    .size(40.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = dayName,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun CalendarGrid(
    firstDayToShow: LocalDate,
    lastDayToShow: LocalDate,
    currentMonth: LocalDate,
    selectedDate: LocalDate,
    today: LocalDate,
    shiftsForDate: (LocalDate) -> List<com.protip365.app.data.models.CompletedShift>,
    onDateTapped: (LocalDate) -> Unit
) {
    val weeks = generateWeeks(firstDayToShow, lastDayToShow)
    
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        weeks.forEach { week ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                week.forEach { date ->
                    CalendarDayCell(
                        date = date,
                        isCurrentMonth = date.month == currentMonth.month,
                        isSelected = date == selectedDate,
                        isToday = date == today,
                        shifts = shiftsForDate(date),
                        onDateTapped = onDateTapped
                    )
                }
            }
        }
    }
}

@Composable
fun CalendarDayCell(
    date: LocalDate,
    isCurrentMonth: Boolean,
    isSelected: Boolean,
    isToday: Boolean,
    shifts: List<com.protip365.app.data.models.CompletedShift>,
    onDateTapped: (LocalDate) -> Unit
) {
    Box(
        modifier = Modifier
            .size(44.dp) // Increased size to match iOS
            .clip(CircleShape)
            .background(
                when {
                    isSelected -> MaterialTheme.colorScheme.primary
                    isToday -> MaterialTheme.colorScheme.primaryContainer
                    else -> Color.Transparent
                }
            )
            .border(
                width = if (isToday && !isSelected) 2.dp else 0.dp,
                color = MaterialTheme.colorScheme.primary,
                shape = CircleShape
            )
            .clickable { onDateTapped(date) },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            // Date number
            Text(
                text = date.dayOfMonth.toString(),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isSelected || isToday) FontWeight.Bold else FontWeight.Medium,
                color = when {
                    isSelected -> MaterialTheme.colorScheme.onPrimary
                    isToday -> MaterialTheme.colorScheme.onPrimaryContainer
                    !isCurrentMonth -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                    else -> MaterialTheme.colorScheme.onSurface
                },
                fontSize = 17.sp // Match iOS size
            )
            
            // iOS-style shift indicators
            ShiftIndicators(shifts = shifts)
        }
    }
}

@Composable
fun ShiftIndicators(shifts: List<com.protip365.app.data.models.CompletedShift>) {
    if (shifts.isEmpty()) {
        // Empty space to maintain consistent height
        Spacer(modifier = Modifier.height(6.dp))
    } else {
        Row(
            horizontalArrangement = Arrangement.spacedBy(2.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Show up to 3 dots, then "+N" for more
            val maxDots = 3
            val shiftsToShow = shifts.take(maxDots)
            
            shiftsToShow.forEachIndexed { index, shift ->
                Box(
                    modifier = Modifier
                        .size(6.dp) // Match iOS size
                        .clip(CircleShape)
                        .background(colorForShift(shift, index))
                )
            }
            
            // Show "+N" if more than 3 shifts
            if (shifts.size > maxDots) {
                Text(
                    text = "+${shifts.size - maxDots}",
                    style = MaterialTheme.typography.labelSmall,
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

private fun colorForShift(shift: com.protip365.app.data.models.CompletedShift, index: Int): Color {
    // Use different colors based on shift status and earnings (matching iOS logic)
    val hasEarnings = shift.totalEarnings > 0
    
    return if (hasEarnings) {
        // Completed shifts with earnings
        when (index % 3) {
            0 -> Color(0xFF4CAF50) // Green
            1 -> Color(0xFF2196F3) // Blue  
            2 -> Color(0xFF9C27B0) // Purple
            else -> Color(0xFF4CAF50)
        }
    } else {
        // Planned shifts or completed but no earnings
        when (shift.status) {
            "planned" -> when (index % 3) {
                0 -> Color(0xFF00BCD4) // Cyan
                1 -> Color(0xFF4DD0E1) // Light Blue
                2 -> Color(0xFF3F51B5) // Indigo
                else -> Color(0xFF00BCD4)
            }
            "missed" -> Color(0xFFF44336) // Red
            else -> when (index % 3) {
                0 -> Color(0xFF9E9E9E) // Gray
                1 -> Color(0xFF757575) // Dark Gray
                2 -> Color(0xFF424242) // Darker Gray
                else -> Color(0xFF9E9E9E)
            }
        }
    }
}

private fun generateWeeks(firstDay: LocalDate, lastDay: LocalDate): List<List<LocalDate>> {
    val weeks = mutableListOf<List<LocalDate>>()
    var currentDate = firstDay
    
    while (currentDate <= lastDay) {
        val week = mutableListOf<LocalDate>()
        for (i in 0..6) {
            week.add(currentDate.plusDays(i.toLong()))
        }
        weeks.add(week)
        currentDate = currentDate.plusWeeks(1)
    }
    
    return weeks
}

@Composable
fun CustomCalendarLegend(
    language: String = "en"
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Text(
                text = when (language) {
                    "fr" -> "Légende du calendrier"
                    "es" -> "Leyenda del calendario"
                    else -> "Calendar Legend"
                },
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                // Completed with earnings
                CustomLegendItem(
                    color = Color(0xFF4CAF50), // Green
                    label = when (language) {
                        "fr" -> "Complété"
                        "es" -> "Completado"
                        else -> "Completed"
                    }
                )
                
                // Planned/Scheduled
                CustomLegendItem(
                    color = Color(0xFF00BCD4), // Cyan
                    label = when (language) {
                        "fr" -> "Planifié"
                        "es" -> "Programado"
                        else -> "Scheduled"
                    }
                )
                
                // Missed
                CustomLegendItem(
                    color = Color(0xFFF44336), // Red
                    label = when (language) {
                        "fr" -> "Manqué"
                        "es" -> "Perdido"
                        else -> "Missed"
                    }
                )
            }
        }
    }
}

@Composable
fun CustomLegendItem(
    color: Color,
    label: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(color)
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}