package com.protip365.app.presentation.shifts

import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.ui.platform.LocalHapticFeedback
import com.protip365.app.utils.HapticFeedbackUtils
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.material3.LocalTextStyle
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.OffsetMapping
import androidx.compose.foundation.text.KeyboardActions
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import androidx.activity.compose.BackHandler
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.data.models.Employer
import com.protip365.app.R
import com.protip365.app.presentation.components.DatePickerDialog
import com.protip365.app.presentation.components.TimePickerDialog
import com.protip365.app.utilities.rememberWindowSizeClass
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
    
    // WindowSizeClass detection for adaptive layouts
    val windowSizeClass = rememberWindowSizeClass()
    
    val context = LocalContext.current
    val haptics = LocalHapticFeedback.current

    // Debug: Log screen render
    LaunchedEffect(Unit) {
        android.util.Log.d("AddEditShiftScreen", "=== SCREEN RENDERED ===")
        android.util.Log.d("AddEditShiftScreen", "shiftId: $shiftId, initialDate: $initialDate")
    }

    // Debug: Log UI state changes
    LaunchedEffect(uiState) {
        android.util.Log.d("AddEditShiftScreen", "UI State: isLoading=${uiState.isLoading}, employer=${uiState.selectedEmployer?.name}, errorMessage=${uiState.errorMessage}")
    }

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

    // Inline picker states
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    var showStartTimePicker by remember { mutableStateOf(false) }
    var showEndTimePicker by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    // Predictive back gesture: Handle dialogs and pickers
    // When any dialog or picker is open, dismiss it first before navigating back
    BackHandler(
        enabled = showStartDatePicker || showEndDatePicker || 
                  showStartTimePicker || showEndTimePicker || 
                  showDeleteDialog || uiState.errorMessage != null
    ) {
        when {
            showStartDatePicker -> showStartDatePicker = false
            showEndDatePicker -> showEndDatePicker = false
            showStartTimePicker -> showStartTimePicker = false
            showEndTimePicker -> showEndTimePicker = false
            showDeleteDialog -> showDeleteDialog = false
            uiState.errorMessage != null -> viewModel.clearError()
        }
    }

    Scaffold(
        modifier = Modifier.windowInsetsPadding(
            WindowInsets.systemBars.only(WindowInsetsSides.Horizontal)
        ),
        containerColor = MaterialTheme.colorScheme.surfaceVariant,
        topBar = {
            AddEditShiftTopBar(
                isEditMode = shiftId != null,
                isLoading = uiState.isLoading,
                onBack = { navController.popBackStack() },
                onDelete = { 
                    // Confirmation haptic for delete button
                    HapticFeedbackUtils.performConfirmationHaptic(haptics)
                    showDeleteDialog = true 
                },
                onSave = {
                    // Confirmation haptic for save button (Android 16 Enhanced Haptic Feedback)
                    HapticFeedbackUtils.performConfirmationHaptic(haptics)
                    android.util.Log.d("AddEditShiftScreen", "Save button clicked - isLoading: ${uiState.isLoading}, hasEmployer: ${uiState.selectedEmployer != null}")
                    if (!uiState.isLoading) {
                        viewModel.saveShift(
                            onSuccess = { 
                                // Success haptic feedback
                                HapticFeedbackUtils.performSuccessHaptic(haptics)
                                android.util.Log.d("AddEditShiftScreen", "Save successful, navigating back")
                                navController.popBackStack() 
                            }
                        )
                    } else {
                        android.util.Log.w("AddEditShiftScreen", "Save clicked but already loading, ignoring")
                    }
                }
            )
        }
    ) { padding ->
        if (uiState.isInitializing) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical)),
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
                    .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical))
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
                        // Employer and Notes Section
                        ShiftDetailsSection(
                            selectedEmployer = uiState.selectedEmployer,
                            comments = uiState.comments,
                            salesTarget = uiState.salesTarget,
                            defaultSalesTarget = uiState.defaultSalesTarget,
                            employers = uiState.employerList,
                            onEmployerSelected = viewModel::updateEmployer,
                            onCommentsChange = viewModel::updateComments,
                            onSalesTargetChange = viewModel::updateSalesTarget
                        )

                        // Time Selection Section
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
                            onStartDateClick = { 
                                // Form interaction haptic for date picker
                                HapticFeedbackUtils.performFormInteractionHaptic(haptics)
                                showStartDatePicker = !showStartDatePicker 
                            },
                            onEndDateClick = { 
                                // Form interaction haptic for date picker
                                HapticFeedbackUtils.performFormInteractionHaptic(haptics)
                                showEndDatePicker = !showEndDatePicker 
                            },
                            onStartTimeClick = { 
                                // Form interaction haptic for time picker
                                HapticFeedbackUtils.performFormInteractionHaptic(haptics)
                                showStartTimePicker = !showStartTimePicker 
                            },
                            onEndTimeClick = { 
                                // Form interaction haptic for time picker
                                HapticFeedbackUtils.performFormInteractionHaptic(haptics)
                                showEndTimePicker = !showEndTimePicker 
                            },
                            onLunchBreakSelected = viewModel::updateLunchBreak,
                            onStartDateSelected = { date ->
                                viewModel.updateDate(date)
                                showStartDatePicker = false
                                // Selection haptic when date is selected
                                HapticFeedbackUtils.performSelectionHaptic(haptics)
                            },
                            onEndDateSelected = { date ->
                                viewModel.updateEndDate(date)
                                showEndDatePicker = false
                                // Selection haptic when date is selected
                                HapticFeedbackUtils.performSelectionHaptic(haptics)
                            },
                            onStartTimeSelected = { time ->
                                viewModel.updateStartTime(time)
                                showStartTimePicker = false
                                // Selection haptic when time is selected
                                HapticFeedbackUtils.performSelectionHaptic(haptics)
                            },
                            onEndTimeSelected = { time ->
                                viewModel.updateEndTime(time)
                                showEndTimePicker = false
                                // Selection haptic when time is selected
                                HapticFeedbackUtils.performSelectionHaptic(haptics)
                            }
                        )

                        // Alert Section
                        ShiftAlertSection(
                            selectedAlert = uiState.alertMinutes,
                            onAlertSelected = viewModel::updateAlertMinutes
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

    // Delete confirmation dialog with entry validation
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { 
                Text(
                    text = stringResource(R.string.delete_shift),
                    style = MaterialTheme.typography.titleLarge
                )
            },
            text = {
                Column(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    if (uiState.hasEntry) {
                        // Warning message when entry exists
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Warning,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.error,
                                modifier = Modifier.size(24.dp)
                            )
                            Text(
                                text = stringResource(R.string.this_shift_has_entry),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = stringResource(R.string.delete_shift_and_entry),
                            style = MaterialTheme.typography.bodyMedium
                        )
                    } else {
                        Text(
                            text = stringResource(R.string.delete_shift_confirm),
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            },
            confirmButton = {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // No button
                    TextButton(
                        onClick = { showDeleteDialog = false }
                    ) {
                        Text(stringResource(R.string.no))
                    }
                    // Yes button
                    Button(
                        onClick = {
                            // Confirmation haptic for delete confirmation
                            HapticFeedbackUtils.performConfirmationHaptic(haptics)
                            viewModel.deleteShift(
                                onSuccess = { 
                                    // Success haptic feedback
                                    HapticFeedbackUtils.performSuccessHaptic(haptics)
                                    navController.popBackStack() 
                                }
                            )
                            showDeleteDialog = false
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Text(stringResource(R.string.yes))
                    }
                }
            },
            dismissButton = {}
        )
    }

    // Error dialog - show error messages
    uiState.errorMessage?.let { error ->
        // Error haptic when error dialog appears
        LaunchedEffect(error) {
            HapticFeedbackUtils.performErrorHaptic(haptics)
        }
        android.util.Log.d("AddEditShiftScreen", "Showing error dialog: $error")
        AlertDialog(
            onDismissRequest = { 
                android.util.Log.d("AddEditShiftScreen", "Error dialog dismissed")
                viewModel.clearError() 
            },
            title = { 
                Text(
                    text = stringResource(R.string.error),
                    style = MaterialTheme.typography.titleLarge
                ) 
            },
            text = { 
                Text(
                    text = error,
                    style = MaterialTheme.typography.bodyMedium
                ) 
            },
            confirmButton = {
                TextButton(
                    onClick = { 
                        android.util.Log.d("AddEditShiftScreen", "Error dialog OK clicked")
                        viewModel.clearError() 
                    }
                ) {
                    Text(stringResource(R.string.ok))
                }
            },
            dismissButton = {}
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
        modifier = Modifier.windowInsetsPadding(
            WindowInsets.statusBars.only(WindowInsetsSides.Top)
        ),
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
                    onClick = {
                        android.util.Log.d("AddEditShiftScreen", "Save IconButton clicked - isLoading: $isLoading")
                        onSave()
                    },
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShiftDetailsSection(
    selectedEmployer: Employer?,
    comments: String,
    salesTarget: String,
    defaultSalesTarget: Double,
    employers: List<Employer>,
    onEmployerSelected: (Employer?) -> Unit,
    onCommentsChange: (String) -> Unit,
    onSalesTargetChange: (String) -> Unit
) {
    var expandedEmployer by remember { mutableStateOf(false) }
    
    Column {
        // Employer Row with Dropdown
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.employer),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            ExposedDropdownMenuBox(
                expanded = expandedEmployer,
                onExpandedChange = { expandedEmployer = !expandedEmployer }
            ) {
                OutlinedTextField(
                    value = selectedEmployer?.name ?: "",
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedEmployer)
                    },
                    modifier = Modifier
                        .width(150.dp)
                        .menuAnchor(),
                    shape = RoundedCornerShape(8.dp),
                    colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors(
                        focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                        unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant
                    ),
                    placeholder = {
                        Text(stringResource(R.string.select))
                    }
                )
                
                ExposedDropdownMenu(
                    expanded = expandedEmployer,
                    onDismissRequest = { expandedEmployer = false }
                ) {
                    employers.forEach { employer ->
                        DropdownMenuItem(
                            text = { Text(employer.name) },
                            onClick = {
                                onEmployerSelected(employer)
                                expandedEmployer = false
                            }
                        )
                    }
                }
            }
        }

        // Divider
        HorizontalDivider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Sales Target Row with Dollar Formatting
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

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = "$",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )
                OutlinedTextField(
                    value = salesTarget,
                    onValueChange = { newValue ->
                        val filtered = newValue.filter { it.isDigit() || it == '.' }
                        if (filtered.count { it == '.' } <= 1) {
                            val parts = filtered.split('.')
                            val integerPart = parts[0]
                            val decimalPart = if (parts.size > 1) parts[1].take(2) else ""
                            val finalValue = if (decimalPart.isNotEmpty()) "$integerPart.$decimalPart" else integerPart
                            onSalesTargetChange(finalValue)
                        }
                    },
                    visualTransformation = CurrencyVisualTransformation(),
                    placeholder = {
                        Text(
                            text = if (defaultSalesTarget > 0) {
                                DecimalFormat("#,##0.00").format(defaultSalesTarget)
                            } else {
                                "0.00"
                            },
                            textAlign = TextAlign.End
                        )
                    },
                    modifier = Modifier.width(140.dp),
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
        }

        // Divider
        HorizontalDivider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Comments Row (iOS-style)
        Column(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            Text(
                text = stringResource(R.string.comments),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            OutlinedTextField(
                value = comments,
                onValueChange = onCommentsChange,
                placeholder = { Text(stringResource(R.string.add_notes_optional)) },
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

@OptIn(ExperimentalMaterial3Api::class)
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
    onStartDateClick: () -> Unit,
    onEndDateClick: () -> Unit,
    onStartTimeClick: () -> Unit,
    onEndTimeClick: () -> Unit,
    onLunchBreakSelected: (Int) -> Unit,
    onStartDateSelected: (LocalDate) -> Unit,
    onEndDateSelected: (LocalDate) -> Unit,
    onStartTimeSelected: (LocalTime) -> Unit,
    onEndTimeSelected: (LocalTime) -> Unit
) {
    var expandedLunchBreak by remember { mutableStateOf(false) }
    val lunchBreakOptions = listOf(
        0 to stringResource(R.string.none),
        15 to "15 ${stringResource(R.string.minute_abbr)}",
        30 to "30 ${stringResource(R.string.minute_abbr)}",
        45 to "45 ${stringResource(R.string.minute_abbr)}",
        60 to "60 ${stringResource(R.string.minute_abbr)}"
    )
    val selectedLunchBreakText = lunchBreakOptions.find { it.first == lunchBreak }?.second ?: stringResource(R.string.none)
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
                text = stringResource(R.string.starts),
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

        // Divider
        HorizontalDivider(
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
                text = stringResource(R.string.ends),
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

        // Divider
        HorizontalDivider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Lunch Break Row with Dropdown
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.lunch_break),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            ExposedDropdownMenuBox(
                expanded = expandedLunchBreak,
                onExpandedChange = { expandedLunchBreak = !expandedLunchBreak }
            ) {
                OutlinedTextField(
                    value = selectedLunchBreakText,
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedLunchBreak)
                    },
                    modifier = Modifier
                        .width(150.dp)
                        .menuAnchor(),
                    shape = RoundedCornerShape(8.dp),
                    colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors(
                        focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                        unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                )
                
                ExposedDropdownMenu(
                    expanded = expandedLunchBreak,
                    onDismissRequest = { expandedLunchBreak = false }
                ) {
                    lunchBreakOptions.forEach { (minutes, label) ->
                        DropdownMenuItem(
                            text = { Text(label) },
                            onClick = {
                                onLunchBreakSelected(minutes)
                                expandedLunchBreak = false
                            }
                        )
                    }
                }
            }
        }

        // Date and Time Pickers
        if (showStartDatePicker) {
            DatePickerDialog(
                selectedDate = selectedDate,
                onDateSelected = onStartDateSelected,
                onDismiss = { onStartDateClick() },
                allowPastDates = true,
                allowFutureDates = true
            )
        }
        
        if (showEndDatePicker) {
            DatePickerDialog(
                selectedDate = endDate ?: selectedDate,
                onDateSelected = onEndDateSelected,
                onDismiss = { onEndDateClick() },
                allowPastDates = true,
                allowFutureDates = true
            )
        }
        
        if (showStartTimePicker) {
            TimePickerDialog(
                selectedTime = startTime,
                onTimeSelected = onStartTimeSelected,
                onDismiss = { onStartTimeClick() }
            )
        }
        
        if (showEndTimePicker) {
            TimePickerDialog(
                selectedTime = endTime,
                onTimeSelected = onEndTimeSelected,
                onDismiss = { onEndTimeClick() }
            )
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShiftAlertSection(
    selectedAlert: Int?,
    onAlertSelected: (Int?) -> Unit
) {
    var expandedAlert by remember { mutableStateOf(false) }
    val alertOptions = listOf(
        null to stringResource(R.string.alert_none),
        15 to stringResource(R.string.alert_15_minutes),
        30 to stringResource(R.string.alert_30_minutes),
        60 to stringResource(R.string.alert_60_minutes),
        1440 to stringResource(R.string.alert_1_day)
    )
    val selectedAlertText = alertOptions.find { it.first == selectedAlert }?.second ?: stringResource(R.string.alert_none)
    
    Column {
        // Divider
        HorizontalDivider(
            modifier = Modifier.padding(horizontal = 16.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )

        // Alert Row with Dropdown - EXACT SAME PATTERN AS EMPLOYER
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
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
                    text = stringResource(R.string.alert_label),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            ExposedDropdownMenuBox(
                expanded = expandedAlert,
                onExpandedChange = { expandedAlert = !expandedAlert }
            ) {
                OutlinedTextField(
                    value = selectedAlertText,
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedAlert)
                    },
                    modifier = Modifier
                        .width(180.dp)
                        .menuAnchor(),
                    shape = RoundedCornerShape(8.dp),
                    colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors(
                        focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                        unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                )
                
                ExposedDropdownMenu(
                    expanded = expandedAlert,
                    onDismissRequest = { expandedAlert = false }
                ) {
                    alertOptions.forEach { (minutes, label) ->
                        DropdownMenuItem(
                            text = { Text(label) },
                            onClick = {
                                onAlertSelected(minutes)
                                expandedAlert = false
                            }
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
        HorizontalDivider(
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
                text = stringResource(R.string.shift_expected_hours),
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
        HorizontalDivider(
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
                text = stringResource(R.string.gross_pay),
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
        HorizontalDivider(
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
                text = stringResource(R.string.expected_net_salary),
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

class CurrencyVisualTransformation : VisualTransformation {
    override fun filter(text: AnnotatedString): TransformedText {
        val numericText = text.text.filter { it.isDigit() || it == '.' }
        
        if (numericText.isEmpty()) {
            return TransformedText(
                AnnotatedString(""),
                OffsetMapping.Identity
            )
        }
        
        val amount = numericText.toDoubleOrNull() ?: 0.0
        val formatter = DecimalFormat("#,##0.00")
        val formatted = formatter.format(amount)
        
        return TransformedText(
            AnnotatedString(formatted),
            object : OffsetMapping {
                override fun originalToTransformed(offset: Int): Int {
                    if (offset <= 0) return 0
                    val numericValue = text.text.substring(0, offset.coerceAtMost(text.length))
                        .filter { it.isDigit() || it == '.' }
                    
                    if (numericValue.isEmpty()) return 0
                    
                    val amount = numericValue.toDoubleOrNull() ?: 0.0
                    val formatted = formatter.format(amount)
                    return formatted.length.coerceAtLeast(0)
                }
                
                override fun transformedToOriginal(offset: Int): Int {
                    val numericValue = text.text.filter { it.isDigit() || it == '.' }
                    return numericValue.length.coerceAtMost(offset).coerceAtLeast(0)
                }
            }
        )
    }
}

// Dialog Components removed - using iOS-style inline pickers instead