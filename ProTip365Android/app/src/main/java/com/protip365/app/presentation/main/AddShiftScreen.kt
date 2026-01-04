package com.protip365.app.presentation.main

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.presentation.shifts.AddShiftViewModel
import kotlinx.datetime.Clock
import kotlinx.datetime.DatePeriod
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.datetime.plus
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddShiftScreen(
    navController: NavController,
    shiftId: String? = null,
    initialDate: String? = null,
    viewModel: AddShiftViewModel = hiltViewModel()
) {
    val todayDate = remember { Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date }
    var startDate by remember {
        mutableStateOf(
            if (initialDate != null && initialDate.isNotEmpty()) {
                try { LocalDate.parse(initialDate) } catch (e: Exception) { todayDate }
            } else {
                todayDate
            }
        )
    }
    var endDate by remember { mutableStateOf(startDate) }
    var startTime by remember { mutableStateOf("09:00") }
    var endTime by remember { mutableStateOf("17:00") }
    var salesTarget by remember { mutableStateOf("777") }
    var comments by remember { mutableStateOf("") }
    var lunchBreak by remember { mutableStateOf("None") }
    var selectedAlert by remember { mutableStateOf("1 hour before") }

    // Picker states
    var showEmployerPicker by remember { mutableStateOf(false) }
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    var showStartTimePicker by remember { mutableStateOf(false) }
    var showEndTimePicker by remember { mutableStateOf(false) }
    var showLunchBreakPicker by remember { mutableStateOf(false) }
    var showAlertPicker by remember { mutableStateOf(false) }

    val state by viewModel.state.collectAsState()
    val employers by viewModel.employers.collectAsState()
    val selectedEmployerId by viewModel.selectedEmployerId.collectAsState()
    val selectedEmployer = employers.find { it.id == selectedEmployerId }

    // Load shift if editing
    LaunchedEffect(shiftId) {
        shiftId?.let {
            viewModel.loadShift(it)
        }
    }

    // Time validation logic (iOS-conformant)
    LaunchedEffect(startDate, endDate, startTime, endTime) {
        val calendar = java.util.Calendar.getInstance()
        
        // Create full date-time objects
        val startDateCal = calendar.clone() as java.util.Calendar
        startDateCal.set(startDate.year, startDate.monthNumber - 1, startDate.dayOfMonth)
        val startTimeParts = startTime.split(":")
        startDateCal.set(java.util.Calendar.HOUR_OF_DAY, startTimeParts[0].toInt())
        startDateCal.set(java.util.Calendar.MINUTE, startTimeParts[1].toInt())
        
        val endDateCal = calendar.clone() as java.util.Calendar
        endDateCal.set(endDate.year, endDate.monthNumber - 1, endDate.dayOfMonth)
        val endTimeParts = endTime.split(":")
        endDateCal.set(java.util.Calendar.HOUR_OF_DAY, endTimeParts[0].toInt())
        endDateCal.set(java.util.Calendar.MINUTE, endTimeParts[1].toInt())
        
        val timeDifference = endDateCal.timeInMillis - startDateCal.timeInMillis
        
        // If end time is more than 1 hour before start time, adjust it
        if (timeDifference < -3600000) { // Less than -1 hour in milliseconds
            // For overnight shifts, set end date to next day
            val nextDay = startDate.plus(DatePeriod(days = 1))
            endDate = nextDay
            println("🔄 Adjusted end date to next day for overnight shift")
        } else if (timeDifference <= 0 && startDate == endDate) {
            // Same day but end time is before or equal to start time
            // Set end time to start time + 8 hours (typical shift duration)
            val adjustedCal = startDateCal.clone() as java.util.Calendar
            adjustedCal.add(java.util.Calendar.HOUR_OF_DAY, 8)
            endTime = String.format("%02d:%02d", 
                adjustedCal.get(java.util.Calendar.HOUR_OF_DAY),
                adjustedCal.get(java.util.Calendar.MINUTE)
            )
            println("🔄 Adjusted end time to: $endTime")
        }
    }

    // No additional validation needed - the time validation above handles everything

    // Calculate expected hours (iOS-conformant with cross-day shift support)
    val expectedHours = remember(startDate, endDate, startTime, endTime, lunchBreak) {
        val calendar = java.util.Calendar.getInstance()
        
        // Parse start date and time
        val startDateComponents = calendar.clone() as java.util.Calendar
        startDateComponents.set(startDate.year, startDate.monthNumber - 1, startDate.dayOfMonth)
        val startTimeParts = startTime.split(":")
        startDateComponents.set(java.util.Calendar.HOUR_OF_DAY, startTimeParts[0].toInt())
        startDateComponents.set(java.util.Calendar.MINUTE, startTimeParts[1].toInt())
        startDateComponents.set(java.util.Calendar.SECOND, 0)
        
        // Parse end date and time
        val endDateComponents = calendar.clone() as java.util.Calendar
        endDateComponents.set(endDate.year, endDate.monthNumber - 1, endDate.dayOfMonth)
        val endTimeParts = endTime.split(":")
        endDateComponents.set(java.util.Calendar.HOUR_OF_DAY, endTimeParts[0].toInt())
        endDateComponents.set(java.util.Calendar.MINUTE, endTimeParts[1].toInt())
        endDateComponents.set(java.util.Calendar.SECOND, 0)
        
        // Calculate time difference in minutes
        val timeIntervalMillis = endDateComponents.timeInMillis - startDateComponents.timeInMillis
        var totalMinutes = (timeIntervalMillis / (1000 * 60)).toInt()
        
        // Ensure positive duration
        if (totalMinutes < 0) {
            totalMinutes += 24 * 60
        }
        
        // Subtract lunch break
        val lunchMinutes = when (lunchBreak) {
            "15 min" -> 15
            "30 min" -> 30
            "45 min" -> 45
            "60 min" -> 60
            else -> 0
        }
        
        totalMinutes -= lunchMinutes
        
        maxOf(0.0, totalMinutes / 60.0) // Return as Double (hours), ensure non-negative
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF2F2F7)) // iOS systemGroupedBackground
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // iOS-style header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Close button
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color(0xFFE5E5EA)) // iOS systemGray5
                        .clickable { navController.navigateUp() },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = "Close",
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurface
                    )
                }

                // Title
                Text(
                    text = if (shiftId != null) "Edit Shift" else "Add Shift",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.SemiBold
                )

                // Save button (checkmark)
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color(0xFFE5E5EA)) // iOS systemGray5
                        .clickable {
                            if (!state.isLoading) {
                                viewModel.saveShift(
                                    startDate = startDate,
                                    endDate = endDate,
                                    startTime = startTime,
                                    endTime = endTime,
                                    hours = expectedHours, // Already in hours (Double)
                                    sales = salesTarget.toDoubleOrNull() ?: 0.0,
                                    tips = 0.0,
                                    hourlyRate = selectedEmployer?.hourlyRate ?: 15.0,
                                    cashOut = 0.0,
                                    other = 0.0,
                                    notes = comments,
                                    employerId = selectedEmployerId
                                )
                                navController.navigateUp()
                            }
                        },
                    contentAlignment = Alignment.Center
                ) {
                    if (state.isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(
                            Icons.Default.Check,
                            contentDescription = "Save",
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }

            // Main content
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp)
            ) {
                Spacer(modifier = Modifier.height(20.dp))

                // Main form card - iOS style
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    ),
                    shape = RoundedCornerShape(12.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                ) {
                    Column {
                        // Employer row
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Employer",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFF2F2F7))
                                    .clickable { showEmployerPicker = !showEmployerPicker }
                                    .padding(horizontal = 12.dp, vertical = 8.dp)
                            ) {
                                Text(
                                    text = selectedEmployer?.name ?: "Select Employer",
                                    style = MaterialTheme.typography.bodyLarge
                                )
                            }
                        }

                        // Employer picker
                        AnimatedVisibility(visible = showEmployerPicker) {
                            Column {
                                employers.forEach { employer ->
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clickable {
                                                viewModel.selectEmployer(employer.id)
                                                showEmployerPicker = false
                                            }
                                            .padding(horizontal = 16.dp, vertical = 12.dp)
                                    ) {
                                        Text(
                                            text = employer.name,
                                            style = MaterialTheme.typography.bodyLarge
                                        )
                                    }
                                }
                            }
                        }

                        Divider(modifier = Modifier.padding(horizontal = 16.dp))

                        // Sales Target row
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Sales Target",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFF2F2F7))
                                    .padding(horizontal = 12.dp, vertical = 8.dp)
                                    .width(150.dp)
                            ) {
                                TextField(
                                    value = salesTarget,
                                    onValueChange = { salesTarget = it },
                                    textStyle = MaterialTheme.typography.bodyLarge,
                                    keyboardOptions = KeyboardOptions(
                                        keyboardType = KeyboardType.Number,
                                        imeAction = ImeAction.Done
                                    ),
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true
                                )
                            }
                        }

                        Divider(modifier = Modifier.padding(horizontal = 16.dp))

                        // Comments row
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp)
                        ) {
                            Text(
                                text = "Comments",
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )
                            
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFF2F2F7))
                                    .padding(12.dp)
                            ) {
                                TextField(
                                    value = comments,
                                    onValueChange = { comments = it },
                                    placeholder = { Text("Add notes...") },
                                    textStyle = MaterialTheme.typography.bodyLarge,
                                    modifier = Modifier.fillMaxWidth(),
                                    minLines = 2,
                                    maxLines = 2
                                )
                            }
                        }

                        Divider(modifier = Modifier.padding(horizontal = 16.dp))

                        // Starts row
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Starts",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                // Date button
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFF2F2F7))
                                        .clickable { showStartDatePicker = !showStartDatePicker }
                                        .padding(horizontal = 12.dp, vertical = 8.dp)
                                ) {
                                    Text(
                                        text = formatDate(startDate),
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                }

                                // Time button
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFF2F2F7))
                                        .clickable { showStartTimePicker = !showStartTimePicker }
                                        .padding(horizontal = 12.dp, vertical = 8.dp)
                                ) {
                                    Text(
                                        text = startTime,
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                }
                            }
                        }

                        // Start date picker
                        AnimatedVisibility(visible = showStartDatePicker) {
                            DatePickerDialog(
                                initialDate = startDate,
                                onDateSelected = { date ->
                                    startDate = date
                                    showStartDatePicker = false
                                },
                                onDismiss = { showStartDatePicker = false }
                            )
                        }

                        // Start time picker
                        AnimatedVisibility(visible = showStartTimePicker) {
                            TimePickerDialog(
                                initialTime = startTime,
                                onTimeSelected = { time ->
                                    startTime = time
                                    showStartTimePicker = false
                                },
                                onDismiss = { showStartTimePicker = false }
                            )
                        }

                        Divider(modifier = Modifier.padding(horizontal = 16.dp))

                        // Ends row
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Ends",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                // Date button
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFF2F2F7))
                                        .clickable { showEndDatePicker = !showEndDatePicker }
                                        .padding(horizontal = 12.dp, vertical = 8.dp)
                                ) {
                                    Text(
                                        text = formatDate(endDate),
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                }

                                // Time button
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFF2F2F7))
                                        .clickable { showEndTimePicker = !showEndTimePicker }
                                        .padding(horizontal = 12.dp, vertical = 8.dp)
                                ) {
                                    Text(
                                        text = endTime,
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                }
                            }
                        }

                        // End date picker
                        AnimatedVisibility(visible = showEndDatePicker) {
                            DatePickerDialog(
                                initialDate = endDate,
                                onDateSelected = { date ->
                                    endDate = date
                                    showEndDatePicker = false
                                },
                                onDismiss = { showEndDatePicker = false }
                            )
                        }

                        // End time picker
                        AnimatedVisibility(visible = showEndTimePicker) {
                            TimePickerDialog(
                                initialTime = endTime,
                                onTimeSelected = { time ->
                                    endTime = time
                                    showEndTimePicker = false
                                },
                                onDismiss = { showEndTimePicker = false }
                            )
                        }

                        Divider(modifier = Modifier.padding(horizontal = 16.dp))

                        // Lunch Break row
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Lunch Break",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFF2F2F7))
                                    .clickable { showLunchBreakPicker = !showLunchBreakPicker }
                                    .padding(horizontal = 12.dp, vertical = 8.dp)
                            ) {
                                Text(
                                    text = lunchBreak,
                                    style = MaterialTheme.typography.bodyLarge
                                )
                            }
                        }

                        // Lunch break picker
                        AnimatedVisibility(visible = showLunchBreakPicker) {
                            Column {
                                listOf("None", "15 min", "30 min", "45 min", "60 min").forEach { option ->
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clickable {
                                                lunchBreak = option
                                                showLunchBreakPicker = false
                                            }
                                            .padding(horizontal = 16.dp, vertical = 12.dp)
                                    ) {
                                        Text(
                                            text = option,
                                            style = MaterialTheme.typography.bodyLarge
                                        )
                                    }
                                }
                            }
                        }

                        Divider(modifier = Modifier.padding(horizontal = 16.dp))

                        // Alert row
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(
                                    Icons.Default.Notifications,
                                    contentDescription = null,
                                    modifier = Modifier.size(20.dp)
                                )
                                Text(
                                    text = "Alert",
                                    style = MaterialTheme.typography.bodyLarge
                                )
                            }
                            
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Text(
                                    text = selectedAlert,
                                    style = MaterialTheme.typography.bodyLarge
                                )
                                Icon(
                                    Icons.Default.ChevronRight,
                                    contentDescription = null,
                                    modifier = Modifier.size(16.dp),
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                                )
                            }
                        }

                        // Alert picker
                        AnimatedVisibility(visible = showAlertPicker) {
                            Column {
                                listOf("None", "15 minutes before", "30 minutes before", "1 hour before", "1 day before").forEach { option ->
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clickable {
                                                selectedAlert = option
                                                showAlertPicker = false
                                            }
                                            .padding(horizontal = 16.dp, vertical = 12.dp)
                                    ) {
                                        Text(
                                            text = option,
                                            style = MaterialTheme.typography.bodyLarge
                                        )
                                    }
                                }
                            }
                        }

                        Divider(modifier = Modifier.padding(horizontal = 16.dp))

                        // Shift Expected Hours row - BOLD
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Shift Expected Hours",
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.Bold
                            )
                            
                            Text(
                                text = "${String.format("%.1f", expectedHours)} hours",
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(80.dp))
            }
        }
    }
}

// Helper function to format date like iOS
@Composable
fun formatDate(date: LocalDate): String {
    val formatter = SimpleDateFormat("MMM dd, yyyy", Locale.US)
    val javaDate = java.time.LocalDate.of(date.year, date.monthNumber, date.dayOfMonth)
        .atStartOfDay(java.time.ZoneId.systemDefault())
        .toInstant()
        .toEpochMilli()
    return formatter.format(javaDate)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimePickerDialog(
    initialTime: String,
    onTimeSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val timeParts = initialTime.split(":")
    val initialHour = timeParts[0].toInt()
    val initialMinute = timeParts[1].toInt()
    
    val timePickerState = rememberTimePickerState(
        initialHour = initialHour,
        initialMinute = initialMinute,
        is24Hour = false
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Time") },
        text = {
            TimePicker(state = timePickerState)
        },
        confirmButton = {
            TextButton(onClick = {
                val selectedTime = String.format(
                    "%02d:%02d",
                    timePickerState.hour,
                    timePickerState.minute
                )
                onTimeSelected(selectedTime)
            }) {
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatePickerDialog(
    initialDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit,
    onDismiss: () -> Unit
) {
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = initialDate.toEpochDays().toLong() * 24 * 60 * 60 * 1000
    )

    androidx.compose.material3.DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = {
                datePickerState.selectedDateMillis?.let { millis ->
                    val days = (millis / (24 * 60 * 60 * 1000)).toInt()
                    val selectedDate = LocalDate.fromEpochDays(days)
                    onDateSelected(selectedDate)
                }
            }) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    ) {
        DatePicker(state = datePickerState)
    }
}