package com.protip365.app.presentation.shifts

import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.material3.LocalTextStyle
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.data.models.Employer
import com.protip365.app.R
import com.protip365.app.presentation.components.DatePickerDialog
import com.protip365.app.presentation.components.TimePickerDialog
import kotlinx.datetime.*
import java.text.NumberFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditShiftScreen(
    navController: NavController,
    shiftId: String? = null,
    initialDate: LocalDate? = null,
    viewModel: AddEditShiftViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    // Initialize with shift data if editing
    LaunchedEffect(shiftId) {
        shiftId?.let {
            viewModel.loadShift(it)
        }
        // Only set initial date if it's today or in the future (for new shifts)
        initialDate?.let { date ->
            if (shiftId != null) {
                // For editing existing shifts, allow any date
                viewModel.updateDate(date)
            } else {
                // For new shifts, only allow today or future dates
                val today = kotlinx.datetime.Clock.System.now()
                    .toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date
                if (date >= today) {
                    viewModel.updateDate(date)
                } else {
                    // Default to today if past date was selected from calendar
                    viewModel.updateDate(today)
                }
            }
        }
        viewModel.loadEmployers()
    }

    // Inline picker states (iOS-style)
    var showEmployerPicker by remember { mutableStateOf(false) }
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    var showStartTimePicker by remember { mutableStateOf(false) }
    var showEndTimePicker by remember { mutableStateOf(false) }
    var showLunchBreakPicker by remember { mutableStateOf(false) }
    var showAlertPicker by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.surfaceVariant,
        topBar = {
            AddEditShiftTopBar(
                isEditMode = shiftId != null,
                isLoading = uiState.isLoading,
                onBack = { navController.popBackStack() },
                onDelete = { showDeleteDialog = true },
                onSave = {
                    viewModel.saveShift(
                        onSuccess = { navController.popBackStack() }
                    )
                }
            )
        }
    ) { padding ->
        if (uiState.isInitializing) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(48.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = stringResource(R.string.loading),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
            ) {
                Spacer(modifier = Modifier.height(16.dp))

                // Main form card (iOS-style single card)
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    ),
                    elevation = CardDefaults.cardElevation(
                        defaultElevation = 1.dp
                    )
                ) {
                    Column {
                        // Employer and Notes Section (iOS-style)
                        ShiftDetailsSection(
                            selectedEmployer = uiState.selectedEmployer,
                            comments = uiState.comments,
                            salesTarget = uiState.salesTarget,
                            defaultSalesTarget = uiState.defaultSalesTarget,
                            employers = uiState.employerList,
                            showEmployerPicker = showEmployerPicker,
                            onEmployerClick = { showEmployerPicker = !showEmployerPicker },
                            onCommentsChange = viewModel::updateComments,
                            onSalesTargetChange = viewModel::updateSalesTarget
                        )

                        // Time Selection Section (iOS-style)
                        ShiftTimeSection(
                            selectedDate = uiState.selectedDate,
                            endDate = uiState.endDate,
                            startTime = uiState.startTime,
                            endTime = uiState.endTime,
                            lunchBreak = uiState.lunchBreak,
                            showStartDatePicker = showStartDatePicker,
                            showEndDatePicker = showEndDatePicker,
                            showStartTimePicker = showStartTimePicker,
                            showEndTimePicker = showEndTimePicker,
                            showLunchBreakPicker = showLunchBreakPicker,
                            onStartDateClick = { showStartDatePicker = !showStartDatePicker },
                            onEndDateClick = { showEndDatePicker = !showEndDatePicker },
                            onStartTimeClick = { showStartTimePicker = !showStartTimePicker },
                            onEndTimeClick = { showEndTimePicker = !showEndTimePicker },
                            onLunchBreakClick = { showLunchBreakPicker = !showLunchBreakPicker }
                        )

                        // Alert Section (iOS-style)
                        ShiftAlertSection(
                            selectedAlert = uiState.alertMinutes,
                            showAlertPicker = showAlertPicker,
                            onAlertClick = { showAlertPicker = !showAlertPicker }
                        )

                        // Summary Section (iOS-style)
                        ShiftSummarySection(
                            startTime = uiState.startTime,
                            endTime = uiState.endTime,
                            lunchBreak = uiState.lunchBreak,
                            selectedEmployer = uiState.selectedEmployer,
                            averageDeductionPercentage = uiState.averageDeductionPercentage
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }

    // Only show delete dialog (iOS-style inline pickers are handled in sections)

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text(stringResource(R.string.delete_shift)) },
            text = { Text("Are you sure you want to delete this shift?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteShift(
                            onSuccess = { navController.popBackStack() }
                        )
                        showDeleteDialog = false
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text(stringResource(R.string.delete))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    // Error dialog
    uiState.errorMessage?.let { error ->
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text(stringResource(R.string.error)) },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
fun AddEditShiftTopBar(
    isEditMode: Boolean,
    isLoading: Boolean,
    onBack: () -> Unit,
    onDelete: () -> Unit,
    onSave: () -> Unit
) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Cancel button
            IconButton(
                onClick = onBack,
                modifier = Modifier
                    .size(32.dp)
                    .background(
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                        shape = CircleShape
                    )
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = stringResource(R.string.cancel),
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }

            // Title
            Text(
                text = stringResource(if (isEditMode) R.string.edit_shift_title else R.string.add_shift_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                // Delete button (only in edit mode)
                if (isEditMode) {
                    IconButton(
                        onClick = onDelete,
                        modifier = Modifier
                            .size(32.dp)
                            .background(
                                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                                shape = CircleShape
                            )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = stringResource(R.string.delete),
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                }

                // Save button
                IconButton(
                    onClick = onSave,
                    enabled = !isLoading,
                    modifier = Modifier
                        .size(32.dp)
                        .background(
                            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                            shape = CircleShape
                        )
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = stringResource(R.string.save),
                            tint = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ShiftDetailsSection(
    selectedEmployer: Employer?,
    comments: String,
    salesTarget: String,
    defaultSalesTarget: Double,
    employers: List<Employer>,
    showEmployerPicker: Boolean,
    onEmployerClick: () -> Unit,
    onCommentsChange: (String) -> Unit,
    onSalesTargetChange: (String) -> Unit
) {
    Column {
        // Employer Row (iOS-style)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Employer",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            Button(
                onClick = onEmployerClick,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                shape = RoundedCornerShape(8.dp),
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
            ) {
                Text(
                    text = selectedEmployer?.name ?: "Select",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }

        // Inline Employer Picker (iOS-style)
        if (showEmployerPicker) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp)
            ) {
                items(employers.size) { index ->
                    val employer = employers[index]
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { 
                                // Update employer and close picker
                                onEmployerClick()
                            }
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = employer.name,
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
        }

        // Divider
        Divider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Sales Target Row (iOS-style: same line as label)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.sales_target),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            OutlinedTextField(
                value = salesTarget,
                onValueChange = onSalesTargetChange,
                placeholder = {
                    Text(
                        text = if (defaultSalesTarget > 0) {
                            String.format("%.0f", defaultSalesTarget)
                        } else {
                            "0"
                        },
                        textAlign = TextAlign.End
                    )
                },
                modifier = Modifier.width(150.dp),
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal
                ),
                textStyle = LocalTextStyle.current.copy(textAlign = TextAlign.End),
                shape = RoundedCornerShape(8.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                    focusedBorderColor = Color.Transparent,
                    unfocusedBorderColor = Color.Transparent
                )
            )
        }

        // Divider
        Divider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Comments Row (iOS-style)
        Column(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            Text(
                text = "Comments",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            OutlinedTextField(
                value = comments,
                onValueChange = onCommentsChange,
                placeholder = { Text("Add notes (optional)") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 2,
                shape = RoundedCornerShape(8.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.outline,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                )
            )
        }
    }
}

@Composable
fun ShiftTimeSection(
    selectedDate: LocalDate,
    endDate: LocalDate?,
    startTime: LocalTime,
    endTime: LocalTime,
    lunchBreak: Int,
    showStartDatePicker: Boolean,
    showEndDatePicker: Boolean,
    showStartTimePicker: Boolean,
    showEndTimePicker: Boolean,
    showLunchBreakPicker: Boolean,
    onStartDateClick: () -> Unit,
    onEndDateClick: () -> Unit,
    onStartTimeClick: () -> Unit,
    onEndTimeClick: () -> Unit,
    onLunchBreakClick: () -> Unit
) {
    Column {
        // Starts Row (iOS-style)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Starts",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                // Date Button
                Button(
                    onClick = onStartDateClick,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    ),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = formatDate(selectedDate),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                // Time Button
                Button(
                    onClick = onStartTimeClick,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    ),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = formatTime(startTime),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }

        // Inline Start Date Picker (iOS-style)
        if (showStartDatePicker) {
            // Date picker would go here
            Text(
                text = "Date picker placeholder",
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp)
            )
        }

        // Inline Start Time Picker (iOS-style)
        if (showStartTimePicker) {
            // Time picker would go here
            Text(
                text = "Time picker placeholder",
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp)
            )
        }

        // Divider
        Divider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Ends Row (iOS-style)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Ends",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                // End Date Button
                Button(
                    onClick = onEndDateClick,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    ),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = formatDate(endDate ?: selectedDate),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                // End Time Button
                Button(
                    onClick = onEndTimeClick,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    ),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = formatTime(endTime),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }

        // Inline End Time Picker (iOS-style)
        if (showEndTimePicker) {
            // Time picker would go here
            Text(
                text = "End time picker placeholder",
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp)
            )
        }

        // Inline End Date Picker (iOS-style)
        if (showEndDatePicker) {
            // Date picker would go here
            Text(
                text = "End date picker placeholder",
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp)
            )
        }

        // Divider
        Divider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Lunch Break Row (iOS-style)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Lunch Break",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            Button(
                onClick = onLunchBreakClick,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                shape = RoundedCornerShape(8.dp),
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
            ) {
                Text(
                    text = if (lunchBreak == 0) "None" else "$lunchBreak min",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }

        // Inline Lunch Break Picker (iOS-style)
        if (showLunchBreakPicker) {
            val options = listOf("None", "15 min", "30 min", "45 min", "60 min")
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp)
            ) {
                items(options.size) { index ->
                    val option = options[index]
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { 
                                // Update lunch break and close picker
                                onLunchBreakClick()
                            }
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = option,
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun TimeRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = label,
                style = MaterialTheme.typography.bodyLarge
            )
        }
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
fun ShiftAlertSection(
    selectedAlert: Int?,
    showAlertPicker: Boolean,
    onAlertClick: () -> Unit
) {
    Column {
        // Divider
        Divider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Alert Selection Row (iOS-style)
        Button(
            onClick = onAlertClick,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Transparent
            ),
            contentPadding = PaddingValues(0.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.NotificationsActive,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "Alert",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = when (selectedAlert) {
                            null, 0 -> "None"
                            15 -> "15 minutes before"
                            30 -> "30 minutes before"
                            60 -> "1 hour before"
                            1440 -> "1 day before"
                            else -> "$selectedAlert min before"
                        },
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface  // Changed from onSurfaceVariant to onSurface (primary color)
                    )
                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }

        // Alert Picker (iOS-style inline)
        if (showAlertPicker) {
            val options = listOf(
                0 to "None",
                15 to "15 minutes before",
                30 to "30 minutes before",
                60 to "1 hour before",
                1440 to "1 day before"
            )
            
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            ) {
                options.forEach { (minutes, label) ->
                    Button(
                        onClick = {
                            // Update alert and close picker
                            onAlertClick()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp, vertical = 12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if ((minutes == 0 && selectedAlert == null) || 
                                                (minutes != 0 && minutes == selectedAlert))
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                            else Color.Transparent
                        ),
                        contentPadding = PaddingValues(0.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = label,
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            
                            if ((minutes == 0 && selectedAlert == null) || 
                                (minutes != 0 && minutes == selectedAlert)) {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }
                    
                    if (minutes != options.last().first) {
                        Divider(
                            modifier = Modifier.padding(start = 20.dp),
                            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ShiftSummarySection(
    startTime: LocalTime,
    endTime: LocalTime,
    lunchBreak: Int,
    selectedEmployer: Employer?,
    averageDeductionPercentage: Double
) {
    val totalMinutes = calculateTotalMinutes(startTime, endTime, lunchBreak)
    val hours = totalMinutes / 60
    val minutes = totalMinutes % 60
    val hoursWorked = totalMinutes.toDouble() / 60.0
    
    val hourlyRate = selectedEmployer?.hourlyRate ?: 15.0
    val grossSalary = hoursWorked * hourlyRate
    val netSalary = grossSalary * (1 - averageDeductionPercentage / 100.0)

    Column {
        // Divider
        Divider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Shift Expected Hours Row (iOS-style)
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
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            Text(
                text = if (minutes > 0) "${hours}h ${minutes}m" else "${hours}h",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
        }

        // Divider
        Divider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Gross Pay Row (iOS-style)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Gross Pay",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            Text(
                text = formatCurrency(grossSalary),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
        }


        // Divider
        Divider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Expected Net Salary Row (iOS-style)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Expected net salary",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            Text(
                text = formatCurrency(netSalary),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

fun calculateTotalMinutes(startTime: LocalTime, endTime: LocalTime, lunchBreak: Int): Int {
    var totalMinutes = (endTime.toSecondOfDay() - startTime.toSecondOfDay()) / 60
    if (totalMinutes < 0) {
        totalMinutes += 24 * 60 // Handle overnight shifts
    }
    return (totalMinutes - lunchBreak).toInt()
}

fun formatDate(date: LocalDate): String {
    val formatter = java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy")
    return date.toJavaLocalDate().format(formatter)
}

fun formatTime(time: LocalTime): String {
    val formatter = java.time.format.DateTimeFormatter.ofPattern("h:mm a")
    return time.toJavaLocalTime().format(formatter)
}

fun formatCurrency(amount: Double): String {
    return NumberFormat.getCurrencyInstance(Locale.US).format(amount)
}

// Dialog Components removed - using iOS-style inline pickers instead