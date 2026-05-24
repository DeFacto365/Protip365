package com.protip365.app.presentation.entries

import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.platform.LocalHapticFeedback
import com.protip365.app.utils.HapticFeedbackUtils
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.heading
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.R
import com.protip365.app.data.models.Employer
import com.protip365.app.presentation.components.DatePickerDialog
import com.protip365.app.presentation.components.TimePickerDialog
import com.protip365.app.utilities.rememberWindowSizeClass
import com.protip365.app.utilities.WindowWidthSizeClass
import com.protip365.app.utilities.isLandscape
import kotlinx.datetime.*
import java.text.NumberFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditEntryScreen(
    navController: NavController,
    entryId: String? = null,
    shiftId: String? = null,
    initialDate: LocalDate? = null,
    viewModel: AddEditEntryViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    // WindowSizeClass detection for adaptive layouts (Android 16)
    val windowSizeClass = rememberWindowSizeClass()
    val isTablet = windowSizeClass.widthSizeClass == WindowWidthSizeClass.MEDIUM ||
                   windowSizeClass.widthSizeClass == WindowWidthSizeClass.EXPANDED
    
    // Landscape orientation detection for landscape optimizations
    val isLandscapeMode = isLandscape()
    
    // Use side-by-side layout for tablets OR phones in landscape
    val useSideBySideLayout = isTablet || (isLandscapeMode && !isTablet)
    val context = LocalContext.current
    val haptics = LocalHapticFeedback.current

    // Initialize with entry/shift data
    LaunchedEffect(entryId, shiftId) {
        entryId?.let {
            viewModel.loadEntry(it)
        }
        shiftId?.let {
            viewModel.loadShift(it)
        }
        initialDate?.let { date ->
            // Only set initial date if it's today or in the past
            val today = kotlinx.datetime.Clock.System.now()
                .toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date
            if (date <= today) {
                viewModel.updateDate(date)
            } else {
                // Default to today if future date was selected from calendar
                viewModel.updateDate(today)
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
            AddEditEntryTopBar(
                isEditMode = entryId != null,
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
                    viewModel.saveEntry(
                        onSuccess = { 
                            // Success haptic feedback
                            HapticFeedbackUtils.performSuccessHaptic(haptics)
                            navController.popBackStack() 
                        }
                    )
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

                // Work Info Card
                WorkInfoCard(
                    selectedEmployer = uiState.selectedEmployer,
                    didntWork = uiState.didntWork,
                    missedReason = uiState.missedReason,
                    calculatedHours = uiState.calculatedHours,
                    hourlyRate = uiState.selectedEmployer?.hourlyRate ?: uiState.defaultHourlyRate,
                    deductionPercentage = uiState.deductionPercentage,
                    tips = uiState.tips.toDoubleOrNull() ?: 0.0,
                    tipOut = uiState.tipOut.toDoubleOrNull() ?: 0.0,
                    other = uiState.other.toDoubleOrNull() ?: 0.0,
                    employers = uiState.employers,
                    showDidntWorkOption = entryId == null, // Only show for new entries
                    onEmployerSelected = viewModel::updateEmployer,
                    onDidntWorkChange = viewModel::updateDidntWork,
                    onMissedReasonSelected = viewModel::updateMissedReason
                )

                // Time Selection Card (only show if worked) (iOS-style)
                if (!uiState.didntWork) {
                    Spacer(modifier = Modifier.height(16.dp))
                    TimeSelectionCard(
                        selectedDate = uiState.selectedDate,
                        endDate = uiState.endDate,
                        startTime = uiState.startTime,
                        endTime = uiState.endTime,
                        lunchBreak = uiState.lunchBreak,
                        showStartDatePicker = showStartDatePicker,
                        showEndDatePicker = showEndDatePicker,
                        showStartTimePicker = showStartTimePicker,
                        showEndTimePicker = showEndTimePicker,
                        showLunchBreakPicker = false,
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
                        isTablet = useSideBySideLayout
                    )

                    // Earnings Card (only show if worked) (iOS-style)
                    Spacer(modifier = Modifier.height(16.dp))
                    EarningsCard(
                        sales = uiState.sales,
                        tips = uiState.tips,
                        tipOut = uiState.tipOut,
                        other = uiState.other,
                        comments = uiState.comments,
                        salesBudget = uiState.salesBudget,
                        onSalesChange = viewModel::updateSales,
                        onTipsChange = viewModel::updateTips,
                        onTipOutChange = viewModel::updateTipOut,
                        onOtherChange = viewModel::updateOther,
                        onCommentsChange = viewModel::updateComments,
                        isTablet = useSideBySideLayout
                    )
                }

                // Summary Card (iOS-style)
                Spacer(modifier = Modifier.height(16.dp))
                SummaryCard(
                    didntWork = uiState.didntWork,
                    missedReason = uiState.missedReason,
                    calculatedHours = uiState.calculatedHours,
                    sales = uiState.sales,
                    tips = uiState.tips,
                    tipOut = uiState.tipOut,
                    other = uiState.other,
                    hourlyRate = uiState.selectedEmployer?.hourlyRate ?: uiState.defaultHourlyRate,
                    totalEarnings = viewModel.calculateTotalEarnings(),
                    deductionPercentage = uiState.deductionPercentage,
                    salesBudget = uiState.salesBudget
                )

                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }

    // Date and Time Pickers
    if (showStartDatePicker) {
        DatePickerDialog(
            selectedDate = uiState.selectedDate,
            onDateSelected = { date ->
                viewModel.updateDate(date)
                showStartDatePicker = false
                // Selection haptic when date is selected
                HapticFeedbackUtils.performSelectionHaptic(haptics)
            },
            onDismiss = { showStartDatePicker = false },
            allowPastDates = true,
            allowFutureDates = true
        )
    }
    
    if (showEndDatePicker) {
        DatePickerDialog(
            selectedDate = uiState.endDate ?: uiState.selectedDate,
            onDateSelected = { date ->
                viewModel.updateEndDate(date)
                showEndDatePicker = false
                // Selection haptic when date is selected
                HapticFeedbackUtils.performSelectionHaptic(haptics)
            },
            onDismiss = { showEndDatePicker = false },
            allowPastDates = true,
            allowFutureDates = true
        )
    }
    
    if (showStartTimePicker) {
        TimePickerDialog(
            selectedTime = uiState.startTime,
            onTimeSelected = { time ->
                viewModel.updateStartTime(time)
                showStartTimePicker = false
                // Selection haptic when time is selected
                HapticFeedbackUtils.performSelectionHaptic(haptics)
            },
            onDismiss = { showStartTimePicker = false }
        )
    }
    
    if (showEndTimePicker) {
        TimePickerDialog(
            selectedTime = uiState.endTime,
            onTimeSelected = { time ->
                viewModel.updateEndTime(time)
                showEndTimePicker = false
                // Selection haptic when time is selected
                HapticFeedbackUtils.performSelectionHaptic(haptics)
            },
            onDismiss = { showEndTimePicker = false }
        )
    }

    // Only show delete dialog (iOS-style inline pickers are handled in cards)

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text(stringResource(R.string.delete_entry)) },
            text = { Text(stringResource(R.string.delete_entry_confirm)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        // Confirmation haptic for delete confirmation
                        HapticFeedbackUtils.performConfirmationHaptic(haptics)
                        viewModel.deleteEntry(
                            onSuccess = { 
                                // Success haptic feedback
                                HapticFeedbackUtils.performSuccessHaptic(haptics)
                                navController.popBackStack() 
                            }
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
        // Error haptic when error dialog appears
        LaunchedEffect(error) {
            HapticFeedbackUtils.performErrorHaptic(haptics)
        }
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text(stringResource(R.string.error)) },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text(stringResource(R.string.ok))
                }
            }
        )
    }
}

@Composable
fun AddEditEntryTopBar(
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
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Cancel button - iOS style text button
            TextButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = stringResource(R.string.cancel),
                    modifier = Modifier.size(20.dp)
                )
                Spacer(Modifier.width(4.dp))
                Text(
                    stringResource(R.string.cancel),
                    style = MaterialTheme.typography.bodyLarge
                )
            }

            // Title
            Text(
                text = if (isEditMode) stringResource(R.string.edit_entry) else stringResource(R.string.new_entry),
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.semantics { heading() } // Screen title (h1)
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                // Delete button (only in edit mode)
                if (isEditMode) {
                    IconButton(
                        onClick = onDelete,
                        modifier = Modifier.size(40.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = stringResource(R.string.delete),
                            tint = MaterialTheme.colorScheme.error,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }

                // Save button - iOS style with checkmark
                Button(
                    onClick = onSave,
                    enabled = !isLoading,
                    modifier = Modifier.height(40.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp,
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = stringResource(R.string.save),
                            tint = MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkInfoCard(
    selectedEmployer: Employer?,
    didntWork: Boolean,
    missedReason: String,
    calculatedHours: Double,
    hourlyRate: Double,
    deductionPercentage: Double,
    tips: Double,
    tipOut: Double,
    other: Double,
    employers: List<Employer>,
    showDidntWorkOption: Boolean, // Control whether to show the "Didn't Work" toggle
    onEmployerSelected: (Employer) -> Unit,
    onDidntWorkChange: (Boolean) -> Unit,
    onMissedReasonSelected: (String) -> Unit
) {
    var expandedEmployer by remember { mutableStateOf(false) }
    var expandedMissedReason by remember { mutableStateOf(false) }
    val missedReasonOptions = listOf(
        stringResource(R.string.missed_reason_sick),
        stringResource(R.string.missed_reason_shift_cancelled),
        stringResource(R.string.missed_reason_personal_emergency),
        stringResource(R.string.missed_reason_no_show),
        stringResource(R.string.missed_reason_weather),
        stringResource(R.string.missed_reason_other)
    )
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp
        )
    ) {
        Column {
            // Employer Row with Dropdown
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp),
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
                modifier = Modifier.padding(horizontal = 20.dp),
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
            )

            // Didn't Work Toggle (only shown for new entries)
            if (showDidntWorkOption) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = stringResource(R.string.didnt_work),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Switch(
                        checked = didntWork,
                        onCheckedChange = {
                            onDidntWorkChange(it)
                            if (!it) {
                                // Clear reason when toggle is turned off
                                onMissedReasonSelected("")
                            }
                        }
                    )
                }

                // Missed Reason (if didn't work) with Dropdown
                if (didntWork) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp, vertical = 14.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = stringResource(R.string.reason),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface
                        )

                        ExposedDropdownMenuBox(
                            expanded = expandedMissedReason,
                            onExpandedChange = { expandedMissedReason = !expandedMissedReason }
                        ) {
                            OutlinedTextField(
                                value = missedReason,
                                onValueChange = {},
                                readOnly = true,
                                trailingIcon = {
                                    ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedMissedReason)
                                },
                                modifier = Modifier
                                    .width(180.dp)
                                    .menuAnchor(),
                                shape = RoundedCornerShape(8.dp),
                                colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors(
                                    focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                                    unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant
                                ),
                                placeholder = {
                                    Text(stringResource(R.string.select))
                                },
                                textStyle = MaterialTheme.typography.bodyLarge.copy(
                                    color = if (missedReason.isEmpty())
                                        MaterialTheme.colorScheme.onSurfaceVariant
                                    else
                                        MaterialTheme.colorScheme.onSurface
                                )
                            )
                            
                            ExposedDropdownMenu(
                                expanded = expandedMissedReason,
                                onDismissRequest = { expandedMissedReason = false }
                            ) {
                                missedReasonOptions.forEach { reason ->
                                    DropdownMenuItem(
                                        text = { Text(reason) },
                                        onClick = {
                                            onMissedReasonSelected(reason)
                                            expandedMissedReason = false
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // Divider
                    HorizontalDivider(
                        modifier = Modifier.padding(horizontal = 20.dp),
                        color = MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
                    )
                }
            }

            // Status Display (iOS-style)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp)
            ) {
                if (didntWork) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = stringResource(R.string.status),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface
                        )

                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text(
                                text = "DIDN'T WORK",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.error,
                                modifier = Modifier
                                    .background(
                                        MaterialTheme.colorScheme.error.copy(alpha = 0.1f),
                                        RoundedCornerShape(6.dp)
                                    )
                                    .padding(horizontal = 10.dp, vertical = 4.dp)
                            )

                            if (missedReason.isNotEmpty()) {
                                Text(
                                    text = "($missedReason)",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                } else {
                    Column(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = stringResource(R.string.total_hours),
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurface
                            )

                            Text(
                                text = String.format("%.1f hours", calculatedHours),
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        // Show Gross and Net PAY summary below Total Hours (iOS-style)
                        if (calculatedHours > 0) {
                            val grossPay = calculatedHours * hourlyRate
                            val netPay = grossPay * (1.0 - (deductionPercentage / 100.0))

                            Text(
                                text = buildString {
                                    append("Avg Net $")
                                    append(String.format("%.0f", netPay))
                                    append(" / Gross $")
                                    append(String.format("%.0f", grossPay))
                                },
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimeSelectionCard(
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
    onLunchBreakSelected: (Int) -> Unit,
    isTablet: Boolean = false
) {
    var expandedLunchBreak by remember { mutableStateOf(false) }
    
    // Landscape optimization: Use side-by-side layout for tablets OR phones in landscape
    val useSideBySideLayout = isTablet || (isLandscape() && !isTablet)
    
    val lunchBreakOptions = listOf(
        0 to stringResource(R.string.none),
        15 to "15 ${stringResource(R.string.minute_abbr)}",
        30 to "30 ${stringResource(R.string.minute_abbr)}",
        45 to "45 ${stringResource(R.string.minute_abbr)}",
        60 to "60 ${stringResource(R.string.minute_abbr)}"
    )
    val selectedLunchBreakText = lunchBreakOptions.find { it.first == lunchBreak }?.second ?: stringResource(R.string.none)
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp
        )
    ) {
        Column {
            // Adaptive layout: Two-column for tablets OR phones in landscape
            if (useSideBySideLayout) {
                // Two-column layout for tablets: Start and End side by side
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Start column
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = stringResource(R.string.starts),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = onStartDateClick,
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                                ),
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = formatDate(selectedDate),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                            Button(
                                onClick = onStartTimeClick,
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                                ),
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = formatTime(startTime),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                    // End column
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = stringResource(R.string.ends),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = onEndDateClick,
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                                ),
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = formatDate(endDate ?: selectedDate),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                            Button(
                                onClick = onEndTimeClick,
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                                ),
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = formatTime(endTime),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                }
            } else {
                // Single-column layout for phones (original)
                // Starts Row
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = stringResource(R.string.starts),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
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
                    modifier = Modifier.padding(horizontal = 20.dp),
                    color = MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
                )
                // Ends Row
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = stringResource(R.string.ends),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
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
            }

            // Divider
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 20.dp),
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
            )

            // Lunch Break Row with Dropdown
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp),
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
fun EarningsCard(
    sales: String,
    tips: String,
    tipOut: String,
    other: String,
    comments: String,
    salesBudget: Double,
    onSalesChange: (String) -> Unit,
    onTipsChange: (String) -> Unit,
    onTipOutChange: (String) -> Unit,
    onOtherChange: (String) -> Unit,
    onCommentsChange: (String) -> Unit,
    isTablet: Boolean = false
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp
        )
    ) {
        Column {
            // Sales Row (iOS-style)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Sales",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "$",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                    OutlinedTextField(
                        value = sales,
                        onValueChange = onSalesChange,
                        placeholder = { Text("0.00") },
                        modifier = Modifier.width(100.dp),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = MaterialTheme.colorScheme.outline,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                        )
                    )
                }
            }

            // Divider
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 20.dp),
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
            )

            // Tips Row (iOS-style)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = stringResource(R.string.tips),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "$",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                    OutlinedTextField(
                        value = tips,
                        onValueChange = onTipsChange,
                        placeholder = { Text("0.00") },
                        modifier = Modifier.width(100.dp),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = MaterialTheme.colorScheme.outline,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                        )
                    )
                }
            }

            // Divider
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 20.dp),
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
            )

            // Tip Out Row (iOS-style)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Tip Out",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "$",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                    OutlinedTextField(
                        value = tipOut,
                        onValueChange = onTipOutChange,
                        placeholder = { Text("0.00") },
                        modifier = Modifier.width(100.dp),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = MaterialTheme.colorScheme.outline,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                        )
                    )
                }
            }

            // Divider
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 20.dp),
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
            )

            // Other Row (iOS-style)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = stringResource(R.string.other_income),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "$",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                    OutlinedTextField(
                        value = other,
                        onValueChange = onOtherChange,
                        placeholder = { Text("0.00") },
                        modifier = Modifier.width(100.dp),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = MaterialTheme.colorScheme.outline,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                        )
                    )
                }
            }

            // Divider
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 20.dp),
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
            )

            // Comments Row (iOS-style)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Text(
                    text = "Notes",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )

                OutlinedTextField(
                    value = comments,
                    onValueChange = onCommentsChange,
                    placeholder = { Text("Add notes (optional)") },
                    modifier = Modifier.width(200.dp),
                    minLines = 3,
                    maxLines = 6,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = MaterialTheme.colorScheme.outline,
                        unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                    )
                )
            }
        }
    }
}

@Composable
fun MoneyInputField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    icon: androidx.compose.ui.graphics.vector.ImageVector
) {
    OutlinedTextField(
        value = value,
        onValueChange = { newValue ->
            // Only allow numbers and decimal point
            if (newValue.all { it.isDigit() || it == '.' }) {
                onValueChange(newValue)
            }
        },
        label = { Text(label) },
        leadingIcon = {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
        },
        prefix = { Text("$") },
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Decimal
        ),
        modifier = Modifier.fillMaxWidth(),
        singleLine = true
    )
}

@Composable
fun SummaryCard(
    didntWork: Boolean,
    missedReason: String,
    calculatedHours: Double,
    sales: String,
    tips: String,
    tipOut: String,
    other: String,
    hourlyRate: Double,
    totalEarnings: Double,
    deductionPercentage: Double,
    salesBudget: Double
) {
    // Calculate expected net salary (after deductions)
    val expectedNetSalary = totalEarnings * (1.0 - (deductionPercentage / 100.0))
    
    // Check if values are greater than 0
    val otherAmount = other.toDoubleOrNull() ?: 0.0
    val tipOutAmount = tipOut.toDoubleOrNull() ?: 0.0
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header with status badge (iOS-style)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Summary",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )

                // Show status badge if didn't work
                if (didntWork) {
                    Text(
                        text = "DIDN'T WORK",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier
                            .background(
                                MaterialTheme.colorScheme.error.copy(alpha = 0.1f),
                                RoundedCornerShape(6.dp)
                            )
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    )
                }
            }

            // Show reason if didn't work
            if (didntWork && missedReason.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Reason",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = missedReason,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.error
                    )
                }
                HorizontalDivider()
            }

            if (!didntWork) {
                // Sales
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Sales",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = formatCurrency(sales.toDoubleOrNull() ?: 0.0),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }

                HorizontalDivider()

                // Gross Pay
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = stringResource(R.string.gross_pay),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = formatCurrency(calculatedHours * hourlyRate),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }

                HorizontalDivider()

                // Tips
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = stringResource(R.string.tips),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = formatCurrency(tips.toDoubleOrNull() ?: 0.0),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }

                HorizontalDivider()

                // Other (only show if > 0)
                if (otherAmount > 0) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = stringResource(R.string.other_income),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = formatCurrency(otherAmount),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium
                        )
                    }

                    HorizontalDivider()
                }

                // Tip Out (negative in red, only show if > 0)
                if (tipOutAmount > 0) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Tip Out",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "-${formatCurrency(tipOutAmount)}",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.error
                        )
                    }

                    HorizontalDivider()
                }

                // Expected net salary (bold)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = stringResource(R.string.expected_net_salary),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = formatCurrency(expectedNetSalary),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }
    }
}

@Composable
fun SummaryRow(label: String, value: String, isNegative: Boolean = false) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = if (isNegative) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
        )
    }
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

