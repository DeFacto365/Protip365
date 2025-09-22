package com.protip365.app.presentation.shifts

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.data.models.Employer
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.Duration
import java.time.format.FormatStyle
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditShiftScreen(
    navController: NavController,
    shiftId: String? = null,
    initialDate: LocalDate? = null,
    viewModel: AddShiftViewModel = hiltViewModel()
) {
    var isShiftType by remember { mutableStateOf(true) }
    var date by remember { mutableStateOf(initialDate ?: LocalDate.now()) }
    var startTime by remember { mutableStateOf(LocalTime.of(9, 0)) }
    var endTime by remember { mutableStateOf(LocalTime.of(17, 0)) }
    var lunchBreak by remember { mutableStateOf(0f) } // in minutes
    var sales by remember { mutableStateOf("") }
    var tips by remember { mutableStateOf("") }
    var hourlyRate by remember { mutableStateOf("") }
    var tipOut by remember { mutableStateOf("") }
    var other by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var selectedEmployer by remember { mutableStateOf<Employer?>(null) }

    var showDatePicker by remember { mutableStateOf(false) }
    var showStartTimePicker by remember { mutableStateOf(false) }
    var showEndTimePicker by remember { mutableStateOf(false) }
    var showLunchBreakPicker by remember { mutableStateOf(false) }
    var showEmployerSelector by remember { mutableStateOf(false) }
    var showValidationError by remember { mutableStateOf(false) }

    val state by viewModel.state.collectAsState()
    val employers by viewModel.employers.collectAsState()

    val scope = rememberCoroutineScope()
    val focusManager = LocalFocusManager.current

    // Calculate derived values
    val hoursWorked = remember(startTime, endTime, lunchBreak) {
        val minutes = java.time.Duration.between(startTime, endTime).toMinutes() - lunchBreak
        (minutes / 60f).coerceAtLeast(0f)
    }

    val wages = remember(hourlyRate, hoursWorked) {
        (hourlyRate.toFloatOrNull() ?: 0f) * hoursWorked
    }

    val totalEarnings = remember(wages, tips, tipOut, other) {
        wages + (tips.toFloatOrNull() ?: 0f) - (tipOut.toFloatOrNull() ?: 0f) + (other.toFloatOrNull() ?: 0f)
    }

    val tipPercentage = remember(tips, sales) {
        val salesAmount = sales.toFloatOrNull() ?: 0f
        val tipsAmount = tips.toFloatOrNull() ?: 0f
        if (salesAmount > 0) (tipsAmount / salesAmount * 100) else 0f
    }

    // Load shift data if editing
    LaunchedEffect(shiftId) {
        shiftId?.let {
            viewModel.loadShift(it) // TODO: Fix loadShift to return shift data through state
        }
    }

    // Date validation helper
    val isPastDateOrToday = date <= LocalDate.now()
    val isFutureDate = date > LocalDate.now()

    // Load default values from settings
    LaunchedEffect(employers) {
        if (shiftId == null && employers.isNotEmpty()) {
            selectedEmployer = employers.firstOrNull() // Select first employer as default
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when {
                            shiftId != null -> getLocalizedText("Edit ${if (isShiftType) "Shift" else "Entry"}", "en")
                            else -> getLocalizedText("Add ${if (isShiftType) "Shift" else "Entry"}", "en")
                        },
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                },
                navigationIcon = {
                    IconButton(
                        onClick = { navController.navigateUp() },
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.surfaceVariant)
                    ) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = getLocalizedText("Close", "en")
                        )
                    }
                },
                actions = {
                    Button(
                        onClick = {
                            if (validateForm()) {
                                scope.launch {
                                    // Convert java.time.LocalDate to kotlinx.datetime.LocalDate
                                    val kotlinDate = kotlinx.datetime.LocalDate(date.year, date.monthValue, date.dayOfMonth)

                                    // Calculate hours
                                    val hours = if (isShiftType) {
                                        val duration = java.time.Duration.between(startTime, endTime)
                                        val totalMinutes = duration.toMinutes() - lunchBreak.toInt()
                                        totalMinutes / 60.0
                                    } else {
                                        0.0
                                    }

                                    viewModel.saveShift(
                                        date = kotlinDate,
                                        startTime = if (isShiftType) startTime.toString() else "",
                                        endTime = if (isShiftType) endTime.toString() else "",
                                        hours = hours,
                                        sales = sales.toDoubleOrNull() ?: 0.0,
                                        tips = tips.toDoubleOrNull() ?: 0.0,
                                        hourlyRate = if (isShiftType) hourlyRate.toDoubleOrNull() ?: 0.0 else 0.0,
                                        cashOut = tipOut.toDoubleOrNull() ?: 0.0,
                                        other = other.toDoubleOrNull() ?: 0.0,
                                        notes = notes.ifBlank { "" },
                                        employerId = selectedEmployer?.id
                                    )
                                    navController.navigateUp()
                                }
                            } else {
                                showValidationError = true
                            }
                        },
                        enabled = !state.isLoading,
                        modifier = Modifier.padding(horizontal = 8.dp)
                    ) {
                        if (state.isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text(getLocalizedText("Save", "en"))
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.background)
        ) {
            // Main content with scroll
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp)
            ) {
                Spacer(modifier = Modifier.height(16.dp))

                // Date validation info
                DateValidationInfo(
                    date = date,
                    isShiftType = isShiftType,
                    language = "en"
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Type Selector (Shift/Entry)
                TypeSelector(
                    isShiftType = isShiftType,
                    onTypeChange = { isShiftType = it },
                    language = "en"
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Date & Time Section
                DateTimeSection(
                    isShiftType = isShiftType,
                    date = date,
                    startTime = startTime,
                    endTime = endTime,
                    lunchBreak = lunchBreak,
                    onDateClick = { showDatePicker = true },
                    onStartTimeClick = { showStartTimePicker = true },
                    onEndTimeClick = { showEndTimePicker = true },
                    onLunchBreakClick = { showLunchBreakPicker = true },
                    hoursWorked = hoursWorked,
                    language = "en"
                )

                // Employer Selection (if enabled)
                if (employers.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(16.dp))
                    EmployerSelectionCard(
                        selectedEmployer = selectedEmployer,
                        onClick = { showEmployerSelector = true },
                        language = "en"
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Financial Information Section
                FinancialSection(
                    isShiftType = isShiftType,
                    sales = sales,
                    tips = tips,
                    hourlyRate = hourlyRate,
                    tipOut = tipOut,
                    other = other,
                    onSalesChange = { sales = it },
                    onTipsChange = { tips = it },
                    onHourlyRateChange = { hourlyRate = it },
                    onTipOutChange = { tipOut = it },
                    onOtherChange = { other = it },
                    focusManager = focusManager,
                    language = "en"
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Notes Section
                NotesSection(
                    notes = notes,
                    onNotesChange = { notes = it },
                    language = "en"
                )

                Spacer(modifier = Modifier.height(100.dp)) // Space for summary card
            }

            // Fixed Summary Card at bottom
            SummarySection(
                isShiftType = isShiftType,
                totalEarnings = totalEarnings,
                hoursWorked = hoursWorked,
                tipPercentage = tipPercentage,
                wages = wages,
                tips = tips.toFloatOrNull() ?: 0f,
                tipOut = tipOut.toFloatOrNull() ?: 0f,
                other = other.toFloatOrNull() ?: 0f,
                language = "en"
            )
        }
    }

    // Dialogs
    if (showDatePicker) {
        DatePickerDialog(
            selectedDate = date,
            onDateSelected = {
                date = it
                showDatePicker = false
            },
            onDismiss = { showDatePicker = false },
            language = "en"
        )
    }

    if (showStartTimePicker) {
        TimePickerDialog(
            selectedTime = startTime,
            title = getLocalizedText("Start Time", "en"),
            onTimeSelected = {
                startTime = it
                showStartTimePicker = false
            },
            onDismiss = { showStartTimePicker = false }
        )
    }

    if (showEndTimePicker) {
        TimePickerDialog(
            selectedTime = endTime,
            title = getLocalizedText("End Time", "en"),
            onTimeSelected = {
                endTime = it
                showEndTimePicker = false
            },
            onDismiss = { showEndTimePicker = false }
        )
    }

    if (showLunchBreakPicker) {
        LunchBreakDialog(
            currentBreak = lunchBreak.toInt(),
            onBreakSelected = {
                lunchBreak = it.toFloat()
                showLunchBreakPicker = false
            },
            onDismiss = { showLunchBreakPicker = false },
            language = "en"
        )
    }

    if (showEmployerSelector) {
        EmployerSelectorDialog(
            employers = employers,
            selectedEmployer = selectedEmployer,
            onEmployerSelected = {
                selectedEmployer = it
                showEmployerSelector = false
            },
            onDismiss = { showEmployerSelector = false },
            language = "en"
        )
    }

    if (showValidationError) {
        AlertDialog(
            onDismissRequest = { showValidationError = false },
            title = {
                Text(getLocalizedText("Validation Error", "en"))
            },
            text = {
                Text(getLocalizedText("Please fill in all required fields", "en"))
            },
            confirmButton = {
                TextButton(onClick = { showValidationError = false }) {
                    Text(getLocalizedText("OK", "en"))
                }
            }
        )
    }
}

@Composable
private fun TypeSelector(
    isShiftType: Boolean,
    onTypeChange: (Boolean) -> Unit,
    language: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            TypeButton(
                isSelected = isShiftType,
                text = getLocalizedText("Shift", "en"),
                icon = Icons.Default.Schedule,
                onClick = { onTypeChange(true) },
                modifier = Modifier.weight(1f)
            )
            TypeButton(
                isSelected = !isShiftType,
                text = getLocalizedText("Entry", "en"),
                icon = Icons.Default.Receipt,
                onClick = { onTypeChange(false) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun TypeButton(
    isSelected: Boolean,
    text: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val animatedColor by animateColorAsState(
        targetValue = if (isSelected)
            MaterialTheme.colorScheme.primaryContainer
        else
            Color.Transparent,
        animationSpec = tween(300)
    )

    Card(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .clickable { onClick() },
        colors = CardDefaults.cardColors(
            containerColor = animatedColor
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = if (isSelected)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                color = if (isSelected)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun DateTimeSection(
    isShiftType: Boolean,
    date: LocalDate,
    startTime: LocalTime,
    endTime: LocalTime,
    lunchBreak: Float,
    onDateClick: () -> Unit,
    onStartTimeClick: () -> Unit,
    onEndTimeClick: () -> Unit,
    onLunchBreakClick: () -> Unit,
    hoursWorked: Float,
    language: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Date selector
            DateTimeItem(
                icon = Icons.Default.CalendarToday,
                label = getLocalizedText("Date", "en"),
                value = date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)),
                onClick = onDateClick
            )

            if (isShiftType) {
                Divider()

                // Time selectors
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    DateTimeItem(
                        icon = Icons.Default.Schedule,
                        label = getLocalizedText("Start", "en"),
                        value = startTime.format(DateTimeFormatter.ofPattern("h:mm a")),
                        onClick = onStartTimeClick,
                        modifier = Modifier.weight(1f)
                    )
                    DateTimeItem(
                        icon = Icons.Default.Schedule,
                        label = getLocalizedText("End", "en"),
                        value = endTime.format(DateTimeFormatter.ofPattern("h:mm a")),
                        onClick = onEndTimeClick,
                        modifier = Modifier.weight(1f)
                    )
                }

                // Lunch break
                DateTimeItem(
                    icon = Icons.Default.Restaurant,
                    label = getLocalizedText("Break", "en"),
                    value = if (lunchBreak > 0) "${lunchBreak.toInt()} min" else getLocalizedText("None", "en"),
                    onClick = onLunchBreakClick
                )

                // Total hours display
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.5f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Timer,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(20.dp)
                            )
                            Text(
                                text = getLocalizedText("Total Hours", "en"),
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        Text(
                            text = String.format("%.1f", hoursWorked),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun DateTimeItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onClick() },
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = label,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Text(
                text = value,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
private fun EmployerSelectionCard(
    selectedEmployer: Employer?,
    onClick: () -> Unit,
    language: String
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Business,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
                Column {
                    Text(
                        text = getLocalizedText("Employer", "en"),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = selectedEmployer?.name ?: getLocalizedText("Select Employer", "en"),
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = if (selectedEmployer != null) FontWeight.Medium else FontWeight.Normal,
                        color = if (selectedEmployer != null)
                            MaterialTheme.colorScheme.onSurface
                        else
                            MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FinancialSection(
    isShiftType: Boolean,
    sales: String,
    tips: String,
    hourlyRate: String,
    tipOut: String,
    other: String,
    onSalesChange: (String) -> Unit,
    onTipsChange: (String) -> Unit,
    onHourlyRateChange: (String) -> Unit,
    onTipOutChange: (String) -> Unit,
    onOtherChange: (String) -> Unit,
    focusManager: androidx.compose.ui.focus.FocusManager,
    language: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = getLocalizedText("Financial Information", "en"),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            if (isShiftType) {
                OutlinedTextField(
                    value = hourlyRate,
                    onValueChange = onHourlyRateChange,
                    label = { Text(getLocalizedText("Hourly Rate", "en")) },
                    leadingIcon = { Text("$") },
                    trailingIcon = { Text("/hr") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Down) }
                    ),
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = sales,
                    onValueChange = onSalesChange,
                    label = { Text(getLocalizedText("Sales", "en")) },
                    leadingIcon = { Text("$") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Right) }
                    ),
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
                OutlinedTextField(
                    value = tips,
                    onValueChange = onTipsChange,
                    label = { Text(getLocalizedText("Tips", "en")) },
                    leadingIcon = { Text("$") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Down) }
                    ),
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = tipOut,
                    onValueChange = onTipOutChange,
                    label = { Text(getLocalizedText("Tip-out", "en")) },
                    leadingIcon = { Text("$") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Right) }
                    ),
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
                OutlinedTextField(
                    value = other,
                    onValueChange = onOtherChange,
                    label = { Text(getLocalizedText("Other", "en")) },
                    leadingIcon = { Text("$") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = { focusManager.clearFocus() }
                    ),
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
            }
        }
    }
}

@Composable
private fun NotesSection(
    notes: String,
    onNotesChange: (String) -> Unit,
    language: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            OutlinedTextField(
                value = notes,
                onValueChange = onNotesChange,
                label = { Text(getLocalizedText("Notes (Optional)", "en")) },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3,
                maxLines = 5,
                keyboardOptions = KeyboardOptions(
                    imeAction = ImeAction.Default
                ),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.surfaceVariant
                )
            )
        }
    }
}

@Composable
private fun SummarySection(
    isShiftType: Boolean,
    totalEarnings: Float,
    hoursWorked: Float,
    tipPercentage: Float,
    wages: Float,
    tips: Float,
    tipOut: Float,
    other: Float,
    language: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Total Earnings
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = getLocalizedText("Total Earnings", "en"),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = NumberFormat.getCurrencyInstance(Locale.US).format(totalEarnings),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            }

            Divider()

            // Breakdown
            Column(
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                if (isShiftType && wages > 0) {
                    SummaryRow(
                        label = getLocalizedText("Wages", "en"),
                        value = NumberFormat.getCurrencyInstance(Locale.US).format(wages),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                if (tips > 0) {
                    SummaryRow(
                        label = getLocalizedText("Tips", "en"),
                        value = NumberFormat.getCurrencyInstance(Locale.US).format(tips),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                if (tipOut > 0) {
                    SummaryRow(
                        label = getLocalizedText("Tip-out", "en"),
                        value = "-${NumberFormat.getCurrencyInstance(Locale.US).format(tipOut)}",
                        color = MaterialTheme.colorScheme.error
                    )
                }
                if (other > 0) {
                    SummaryRow(
                        label = getLocalizedText("Other", "en"),
                        value = NumberFormat.getCurrencyInstance(Locale.US).format(other),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Tip Percentage Badge
            if (tipPercentage > 0) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = when {
                            tipPercentage >= 20 -> Color(0xFF4CAF50).copy(alpha = 0.2f)
                            tipPercentage >= 15 -> MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                            else -> MaterialTheme.colorScheme.error.copy(alpha = 0.2f)
                        }
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Percent,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp),
                            tint = when {
                                tipPercentage >= 20 -> Color(0xFF4CAF50)
                                tipPercentage >= 15 -> MaterialTheme.colorScheme.primary
                                else -> MaterialTheme.colorScheme.error
                            }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "${getLocalizedText("Tip Percentage", "en")}: ${String.format("%.1f%%", tipPercentage)}",
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Medium,
                            color = when {
                                tipPercentage >= 20 -> Color(0xFF4CAF50)
                                tipPercentage >= 15 -> MaterialTheme.colorScheme.primary
                                else -> MaterialTheme.colorScheme.error
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryRow(
    label: String,
    value: String,
    color: Color
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = color
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = color
        )
    }
}

// Dialog implementations would go here...
@Composable
private fun DatePickerDialog(
    selectedDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit,
    onDismiss: () -> Unit,
    language: String
) {
    // Implementation of date picker dialog
}

@Composable
private fun TimePickerDialog(
    selectedTime: LocalTime,
    title: String,
    onTimeSelected: (LocalTime) -> Unit,
    onDismiss: () -> Unit
) {
    // Implementation of time picker dialog
}

@Composable
private fun LunchBreakDialog(
    currentBreak: Int,
    onBreakSelected: (Int) -> Unit,
    onDismiss: () -> Unit,
    language: String
) {
    // Implementation of lunch break dialog
}

@Composable
private fun EmployerSelectorDialog(
    employers: List<Employer>,
    selectedEmployer: Employer?,
    onEmployerSelected: (Employer) -> Unit,
    onDismiss: () -> Unit,
    language: String
) {
    // Implementation of employer selector dialog
}

private fun validateForm(): Boolean {
    // Form validation logic
    return true
}

@Composable
private fun DateValidationInfo(
    date: LocalDate,
    isShiftType: Boolean,
    language: String
) {
    val today = LocalDate.now()
    val isPastDateOrToday = date <= today
    val isFutureDate = date > today

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = when {
                isPastDateOrToday && !isShiftType -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                isFutureDate && isShiftType -> Color(0xFF9C27B0).copy(alpha = 0.1f) // Purple matching iOS
                else -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            }
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                when {
                    isPastDateOrToday && !isShiftType -> Icons.Default.CheckCircle
                    isFutureDate && isShiftType -> Icons.Default.Schedule
                    else -> Icons.Default.Info
                },
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = when {
                    isPastDateOrToday && !isShiftType -> MaterialTheme.colorScheme.primary
                    isFutureDate && isShiftType -> Color(0xFF9C27B0) // Purple matching iOS
                    else -> MaterialTheme.colorScheme.onSurfaceVariant
                }
            )
            
            Text(
                text = when {
                    isPastDateOrToday && !isShiftType -> when (language) {
                        "fr" -> "✓ Entrée recommandée pour les dates passées/aujourd'hui"
                        "es" -> "✓ Entrada recomendada para fechas pasadas/hoy"
                        else -> "✓ Entry recommended for past/today dates"
                    }
                    isFutureDate && isShiftType -> when (language) {
                        "fr" -> "✓ Quart recommandé pour les dates futures"
                        "es" -> "✓ Turno recomendado para fechas futuras"
                        else -> "✓ Shift recommended for future dates"
                    }
                    isPastDateOrToday && isShiftType -> when (language) {
                        "fr" -> "ℹ Quart pour date passée/aujourd'hui"
                        "es" -> "ℹ Turno para fecha pasada/hoy"
                        else -> "ℹ Shift for past/today date"
                    }
                    else -> when (language) {
                        "fr" -> "ℹ Entrée pour date future"
                        "es" -> "ℹ Entrada para fecha futura"
                        else -> "ℹ Entry for future date"
                    }
                },
                style = MaterialTheme.typography.bodySmall,
                color = when {
                    isPastDateOrToday && !isShiftType -> MaterialTheme.colorScheme.primary
                    isFutureDate && isShiftType -> Color(0xFF9C27B0) // Purple matching iOS
                    else -> MaterialTheme.colorScheme.onSurfaceVariant
                }
            )
        }
    }
}

private fun getLocalizedText(text: String, language: String): String {
    // Localization helper
    return when (language) {
        "fr" -> when (text) {
            "Add Shift" -> "Ajouter un quart"
            "Edit Shift" -> "Modifier le quart"
            "Add Entry" -> "Ajouter une entrée"
            "Edit Entry" -> "Modifier l'entrée"
            "Save" -> "Enregistrer"
            "Close" -> "Fermer"
            "Shift" -> "Quart"
            "Entry" -> "Entrée"
            "Date" -> "Date"
            "Start" -> "Début"
            "End" -> "Fin"
            "Break" -> "Pause"
            "None" -> "Aucune"
            "Total Hours" -> "Heures totales"
            "Employer" -> "Employeur"
            "Select Employer" -> "Sélectionner un employeur"
            "Financial Information" -> "Informations financières"
            "Hourly Rate" -> "Taux horaire"
            "Sales" -> "Ventes"
            "Tips" -> "Pourboires"
            "Tip-out" -> "Partage"
            "Other" -> "Autre"
            "Notes (Optional)" -> "Notes (Optionnel)"
            "Total Earnings" -> "Gains totaux"
            "Wages" -> "Salaire"
            "Tip Percentage" -> "Pourcentage de pourboire"
            else -> text
        }
        "es" -> when (text) {
            "Add Shift" -> "Agregar turno"
            "Edit Shift" -> "Editar turno"
            "Add Entry" -> "Agregar entrada"
            "Edit Entry" -> "Editar entrada"
            "Save" -> "Guardar"
            "Close" -> "Cerrar"
            "Shift" -> "Turno"
            "Entry" -> "Entrada"
            "Date" -> "Fecha"
            "Start" -> "Inicio"
            "End" -> "Fin"
            "Break" -> "Descanso"
            "None" -> "Ninguno"
            "Total Hours" -> "Horas totales"
            "Employer" -> "Empleador"
            "Select Employer" -> "Seleccionar empleador"
            "Financial Information" -> "Información financiera"
            "Hourly Rate" -> "Tarifa por hora"
            "Sales" -> "Ventas"
            "Tips" -> "Propinas"
            "Tip-out" -> "Reparto"
            "Other" -> "Otro"
            "Notes (Optional)" -> "Notas (Opcional)"
            "Total Earnings" -> "Ganancias totales"
            "Wages" -> "Salario"
            "Tip Percentage" -> "Porcentaje de propina"
            else -> text
        }
        else -> text
    }
}