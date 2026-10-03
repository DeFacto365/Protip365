package com.protip365.app.presentation.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.datetime.*
import java.time.format.TextStyle
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatePickerDialog(
    selectedDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit,
    onDismiss: () -> Unit,
    allowPastDates: Boolean = true,
    allowFutureDates: Boolean = true
) {
    // Get today's date in milliseconds for date validation
    val today = Clock.System.now().toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date
    val todayMillis = today.toEpochDays() * 24 * 60 * 60 * 1000L

    val datePickerState = when {
        !allowPastDates && !allowFutureDates -> {
            // Only allow today
            rememberDatePickerState(
                initialSelectedDateMillis = todayMillis,
                selectableDates = object : SelectableDates {
                    override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                        return utcTimeMillis == todayMillis
                    }
                }
            )
        }
        !allowPastDates -> {
            // Allow today and future dates only
            rememberDatePickerState(
                initialSelectedDateMillis = selectedDate.toEpochDays() * 24 * 60 * 60 * 1000L,
                selectableDates = object : SelectableDates {
                    override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                        return utcTimeMillis >= todayMillis
                    }
                }
            )
        }
        !allowFutureDates -> {
            // Allow past dates and today only
            rememberDatePickerState(
                initialSelectedDateMillis = selectedDate.toEpochDays() * 24 * 60 * 60 * 1000L,
                selectableDates = object : SelectableDates {
                    override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                        return utcTimeMillis <= todayMillis
                    }
                }
            )
        }
        else -> {
            // Allow all dates
            rememberDatePickerState(
                initialSelectedDateMillis = selectedDate.toEpochDays() * 24 * 60 * 60 * 1000L
            )
        }
    }

    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(
                onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        val instant = Instant.fromEpochMilliseconds(millis)
                        val date = instant.toLocalDateTime(kotlinx.datetime.TimeZone.UTC).date
                        onDateSelected(date)
                    }
                }
            ) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    ) {
        DatePicker(
            state = datePickerState,
            showModeToggle = true
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimePickerDialog(
    selectedTime: LocalTime,
    onTimeSelected: (LocalTime) -> Unit,
    onDismiss: () -> Unit
) {
    val timePickerState = rememberTimePickerState(
        initialHour = selectedTime.hour,
        initialMinute = selectedTime.minute,
        is24Hour = false
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Time") },
        text = {
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                TimePicker(
                    state = timePickerState,
                    modifier = Modifier.padding(16.dp)
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val time = LocalTime(timePickerState.hour, timePickerState.minute)
                    onTimeSelected(time)
                }
            ) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun MonthYearPickerDialog(
    selectedMonth: Int,
    selectedYear: Int,
    onMonthYearSelected: (Int, Int) -> Unit,
    onDismiss: () -> Unit
) {
    var month by remember { mutableStateOf(selectedMonth) }
    var year by remember { mutableStateOf(selectedYear) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Month & Year") },
        text = {
            Column {
                // Month selector
                Text("Month", style = MaterialTheme.typography.labelMedium)
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    for (m in 1..12) {
                        val monthName = java.time.Month.of(m)
                            .getDisplayName(TextStyle.SHORT, Locale.getDefault())
                        FilterChip(
                            selected = m == month,
                            onClick = { month = m },
                            label = { Text(monthName) },
                            modifier = Modifier.padding(2.dp)
                        )
                        if (m % 4 == 0) {
                            Spacer(modifier = Modifier.height(4.dp))
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Year selector
                Text("Year", style = MaterialTheme.typography.labelMedium)
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    val currentYear = Clock.System.now()
                        .toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).year
                    for (y in (currentYear - 2)..(currentYear + 2)) {
                        FilterChip(
                            selected = y == year,
                            onClick = { year = y },
                            label = { Text(y.toString()) }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onMonthYearSelected(month, year) }
            ) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}