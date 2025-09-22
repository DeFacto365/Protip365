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
    shiftsForDate: (LocalDate) -> List<com.protip365.app.data.models.Shift>,
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
    shiftsForDate: (LocalDate) -> List<com.protip365.app.data.models.Shift>,
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
    shifts: List<com.protip365.app.data.models.Shift>,
    onDateTapped: (LocalDate) -> Unit
) {
    val hasShifts = shifts.isNotEmpty()
    val hasCompletedShifts = shifts.any { it.hours > 0 }
    val hasIncompleteShifts = shifts.any { it.hours <= 0 }
    
    Box(
        modifier = Modifier
            .size(40.dp)
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
            verticalArrangement = Arrangement.Center
        ) {
            // Date number
            Text(
                text = date.dayOfMonth.toString(),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isSelected || isToday) FontWeight.Bold else FontWeight.Normal,
                color = when {
                    isSelected -> MaterialTheme.colorScheme.onPrimary
                    isToday -> MaterialTheme.colorScheme.onPrimaryContainer
                    !isCurrentMonth -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                    else -> MaterialTheme.colorScheme.onSurface
                },
                fontSize = if (isSelected || isToday) 16.sp else 14.sp
            )
            
            // Shift indicators
            if (hasShifts) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    if (hasCompletedShifts) {
                        Box(
                            modifier = Modifier
                                .size(4.dp)
                                .clip(CircleShape)
                                .background(Color.Green)
                        )
                    }
                    if (hasIncompleteShifts) {
                        Box(
                            modifier = Modifier
                                .size(4.dp)
                                .clip(CircleShape)
                                .background(Color(0xFFFF9800)) // Orange color
                        )
                    }
                }
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
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = when (language) {
                    "fr" -> "Légende"
                    "es" -> "Leyenda"
                    else -> "Legend"
                },
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                CustomLegendItem(
                    color = Color.Green,
                    label = when (language) {
                        "fr" -> "Complété"
                        "es" -> "Completado"
                        else -> "Completed"
                    }
                )
                
                CustomLegendItem(
                    color = Color(0xFFFF9800), // Orange color
                    label = when (language) {
                        "fr" -> "Incomplet"
                        "es" -> "Incompleto"
                        else -> "Incomplete"
                    }
                )
                
                CustomLegendItem(
                    color = MaterialTheme.colorScheme.primary,
                    label = when (language) {
                        "fr" -> "Aujourd'hui"
                        "es" -> "Hoy"
                        else -> "Today"
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