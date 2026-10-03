package com.protip365.app.presentation.main

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.presentation.shifts.AddShiftViewModel
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.text.NumberFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddShiftScreen(
    navController: NavController,
    shiftId: String? = null,
    initialDate: String? = null,
    viewModel: AddShiftViewModel = hiltViewModel()
) {
    val isShiftType = true // This is Add Shift screen, always a shift
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
    var hours by remember { mutableStateOf("8.0") }
    var notes by remember { mutableStateOf("") }

    val state by viewModel.state.collectAsState()
    val employers by viewModel.employers.collectAsState()
    val selectedEmployerId by viewModel.selectedEmployerId.collectAsState()
    val hourlyRate by viewModel.hourlyRate.collectAsState()

    // Load shift if editing
    LaunchedEffect(shiftId) {
        shiftId?.let {
            viewModel.loadShift(it)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (shiftId != null) "Edit Shift" else "Add Shift") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            viewModel.saveShift(
                                date = startDate,
                                startTime = startTime,
                                endTime = endTime,
                                hours = hours.toDoubleOrNull() ?: 0.0,
                                sales = 0.0,  // No financial data in Add Shift
                                tips = 0.0,
                                hourlyRate = hourlyRate.toDoubleOrNull() ?: 0.0,
                                cashOut = 0.0,
                                other = 0.0,
                                notes = notes,
                                employerId = selectedEmployerId
                            )
                            navController.navigateUp()
                        },
                        enabled = !state.isLoading
                    ) {
                        Text("Save")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            // Start Date + Start Time
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                DateField(
                    date = startDate,
                    onDateChange = { startDate = it },
                    modifier = Modifier.weight(1f),
                    label = "Start Date"
                )
                OutlinedTextField(
                    value = startTime,
                    onValueChange = { startTime = it },
                    label = { Text("Start Time") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Default.Schedule, contentDescription = null) }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // End Date + End Time
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                DateField(
                    date = endDate,
                    onDateChange = { endDate = it },
                    modifier = Modifier.weight(1f),
                    label = "End Date"
                )
                OutlinedTextField(
                    value = endTime,
                    onValueChange = { endTime = it },
                    label = { Text("End Time") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Default.Schedule, contentDescription = null) }
                )
            }

            // Employer selector (if multiple employers enabled)
            if (employers.isNotEmpty()) {
                Spacer(modifier = Modifier.height(16.dp))
                EmployerDropdown(
                    employers = employers,
                    selectedEmployerId = selectedEmployerId,
                    onEmployerSelected = { viewModel.selectEmployer(it) }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
            OutlinedTextField(
                value = hours,
                onValueChange = { hours = it },
                label = { Text("Total Hours") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal,
                    imeAction = ImeAction.Next
                ),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                leadingIcon = { Icon(Icons.Default.Timer, contentDescription = null) }
            )

            Spacer(modifier = Modifier.height(16.dp))
            OutlinedTextField(
                value = hourlyRate,
                onValueChange = { }, // Read-only, controlled by employer selection
                label = { Text("Hourly Rate") },
                prefix = { Text("$") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                readOnly = true,
                colors = OutlinedTextFieldDefaults.colors(
                    disabledTextColor = MaterialTheme.colorScheme.onSurface,
                    disabledBorderColor = MaterialTheme.colorScheme.outline,
                    disabledLabelColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    disabledPrefixColor = MaterialTheme.colorScheme.onSurfaceVariant
                ),
                enabled = false
            )

            // Notes
            Spacer(modifier = Modifier.height(16.dp))
            OutlinedTextField(
                value = notes,
                onValueChange = { notes = it },
                label = { Text("Notes") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3,
                maxLines = 5
            )

            // Expected Income Summary Card
            Spacer(modifier = Modifier.height(24.dp))
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Expected Income",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    val expectedWages = (hourlyRate.toDoubleOrNull() ?: 0.0) * (hours.toDoubleOrNull() ?: 0.0)

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Expected Wages", style = MaterialTheme.typography.bodyMedium)
                        Text(
                            text = NumberFormat.getCurrencyInstance(Locale.US).format(expectedWages),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            // Error message
            state.error?.let { error ->
                Spacer(modifier = Modifier.height(16.dp))
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = error,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(16.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(80.dp)) // Space for FAB
        }
    }
}

@Composable
fun SegmentedButton(
    isShiftType: Boolean,
    onTypeChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth()
    ) {
        OutlinedButton(
            onClick = { onTypeChange(true) },
            modifier = Modifier.weight(1f),
            colors = if (isShiftType) ButtonDefaults.buttonColors() else ButtonDefaults.outlinedButtonColors()
        ) {
            Icon(Icons.Default.Schedule, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("Shift")
        }
        Spacer(modifier = Modifier.width(8.dp))
        OutlinedButton(
            onClick = { onTypeChange(false) },
            modifier = Modifier.weight(1f),
            colors = if (!isShiftType) ButtonDefaults.buttonColors() else ButtonDefaults.outlinedButtonColors()
        ) {
            Icon(Icons.Default.AttachMoney, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("Entry")
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DateField(
    date: LocalDate,
    onDateChange: (LocalDate) -> Unit,
    modifier: Modifier = Modifier,
    label: String = "Date"
) {
    var showDatePicker by remember { mutableStateOf(false) }

    OutlinedTextField(
        value = date.toString(),
        onValueChange = { },
        label = { Text(label) },
        modifier = modifier,
        readOnly = true,
        singleLine = true,
        trailingIcon = {
            IconButton(onClick = { showDatePicker = true }) {
                Icon(Icons.Default.CalendarToday, contentDescription = "Select date")
            }
        }
    )

    if (showDatePicker) {
        DatePickerDialog(
            initialDate = date,
            onDateSelected = { selectedDate ->
                onDateChange(selectedDate)
                showDatePicker = false
            },
            onDismiss = { showDatePicker = false }
        )
    }
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmployerDropdown(
    employers: List<com.protip365.app.data.models.Employer>,
    selectedEmployerId: String?,
    onEmployerSelected: (String) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedEmployer = employers.find { it.id == selectedEmployerId }

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it }
    ) {
        OutlinedTextField(
            value = selectedEmployer?.name ?: "",
            onValueChange = {},
            readOnly = true,
            label = { Text("Employer") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .fillMaxWidth()
                .menuAnchor()
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            employers.forEach { employer ->
                DropdownMenuItem(
                    text = { Text(employer.name) },
                    onClick = {
                        onEmployerSelected(employer.id)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
fun SummaryCard(
    sales: Double,
    tips: Double,
    wages: Double,
    cashOut: Double,
    other: Double
) {
    val totalEarnings = wages + tips + other - cashOut
    val tipPercentage = if (sales > 0) (tips / sales * 100) else 0.0

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Summary",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Medium
            )
            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Net Salary", style = MaterialTheme.typography.bodyMedium)
                Text(
                    text = NumberFormat.getCurrencyInstance(Locale.US).format(totalEarnings),
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            if (sales > 0) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Tip %", style = MaterialTheme.typography.bodyMedium)
                    Text(
                        text = String.format("%.1f%%", tipPercentage),
                        style = MaterialTheme.typography.bodyMedium,
                        color = when {
                            tipPercentage >= 20 -> MaterialTheme.colorScheme.tertiary
                            tipPercentage >= 15 -> MaterialTheme.colorScheme.primary
                            else -> MaterialTheme.colorScheme.error
                        }
                    )
                }
            }
        }
    }
}