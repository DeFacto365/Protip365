package com.protip365.app.presentation.calendar

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.platform.LocalHapticFeedback
import com.protip365.app.utils.HapticFeedbackUtils
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
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
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.navigation.NavController
import com.protip365.app.R
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.data.models.CompletedShift
import com.protip365.app.utilities.rememberWindowSizeClass
import com.protip365.app.utilities.WindowWidthSizeClass
import com.protip365.app.utilities.rememberFoldableDeviceState
import com.protip365.app.utilities.isUnfoldedForDualPane
import com.protip365.app.utilities.isLandscape
import kotlinx.datetime.*
import java.util.TimeZone
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarScreen(
    onNavigateToAddShift: (LocalDate) -> Unit,
    onNavigateToAddEntry: (LocalDate, String?) -> Unit,
    onNavigateToEditShift: (String) -> Unit,
    onNavigateToEditEntry: (String) -> Unit,
    viewModel: CalendarViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val shifts by viewModel.shifts.collectAsState()
    
    // WindowSizeClass detection for adaptive layouts (Android 16)
    val windowSizeClass = rememberWindowSizeClass()
    val isTablet = windowSizeClass.widthSizeClass == WindowWidthSizeClass.MEDIUM ||
                   windowSizeClass.widthSizeClass == WindowWidthSizeClass.EXPANDED
    
    // Landscape orientation detection for landscape optimizations
    val isLandscapeMode = isLandscape()
    
    // Foldable device detection for dual-pane layouts (Android 16)
    val foldableState = rememberFoldableDeviceState()
    val isUnfoldedDualPane = isUnfoldedForDualPane()
    
    // Use dual-pane layout when:
    // - Tablet-sized screen OR
    // - Foldable device unfolded OR
    // - Landscape mode (for phones)
    val useDualPaneLayout = isTablet || isUnfoldedDualPane || isLandscapeMode

    val context = LocalContext.current
    val haptics = LocalHapticFeedback.current
    val preferencesManager = remember { PreferencesManager(context) }
    val language = preferencesManager.getLanguage()
    val weekStartsMonday = preferencesManager.getWeekStartsMonday()
    
    // Load default tip percentage from settings
    var defaultTipPercentage by remember { mutableStateOf(20.0) }
    LaunchedEffect(Unit) {
        try {
            val settings = preferencesManager.getSettings()
            defaultTipPercentage = settings?.defaultTipPercentage ?: 20.0
        } catch (e: Exception) {
            defaultTipPercentage = 20.0
        }
    }

    // Refresh shifts when screen resumes
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                viewModel.refreshShifts()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    // Dialog states for Add Shift/Entry flows
    var showAddShiftDialog by remember { mutableStateOf(false) }
    var showAddEntryDialog by remember { mutableStateOf(false) }
    var showShiftSelectionDialog by remember { mutableStateOf(false) }
    var isEditingEntry by remember { mutableStateOf(false) } // true = edit entry, false = add entry
    
    // Delete dialog state
    var shiftToDelete by remember { mutableStateOf<CompletedShift?>(null) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    
    // Modify Shift/Entry dialog state (iOS-style)
    var shiftToModify by remember { mutableStateOf<CompletedShift?>(null) }
    var showModifyDialog by remember { mutableStateOf(false) }

    // Predictive back gesture: Handle dialogs
    // When any dialog is open, dismiss it first before navigating back
    BackHandler(
        enabled = showAddShiftDialog || showAddEntryDialog || 
                  showShiftSelectionDialog || showDeleteDialog || showModifyDialog
    ) {
        when {
            showAddShiftDialog -> showAddShiftDialog = false
            showAddEntryDialog -> showAddEntryDialog = false
            showShiftSelectionDialog -> showShiftSelectionDialog = false
            showDeleteDialog -> {
                showDeleteDialog = false
                shiftToDelete = null
            }
            showModifyDialog -> {
                showModifyDialog = false
                shiftToModify = null
            }
        }
    }

    Scaffold(
        modifier = Modifier.windowInsetsPadding(
            WindowInsets.systemBars.only(WindowInsetsSides.Horizontal)
        ),
        topBar = {
            TopAppBar(
                modifier = Modifier.windowInsetsPadding(
                    WindowInsets.statusBars.only(WindowInsetsSides.Top)
                ),
                title = {
                    Text(
                        text = stringResource(R.string.calendar_title),
                        modifier = Modifier.semantics { heading() } // Screen title (h1)
                    )
                }
            )
        }
    ) { paddingValues ->
        // Dual-pane layout for tablets, unfolded foldables, and landscape mode (Android 16)
        if (useDualPaneLayout) {
            // Landscape layout: Calendar on left, shifts list on right
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical))
            ) {
                // Left column: Calendar
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .padding(end = 16.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    // Month Navigation
                    MonthNavigationHeader(
                        currentMonth = uiState.currentMonth,
                        currentYear = uiState.currentYear,
                        onPreviousMonth = { viewModel.navigateToPreviousMonth() },
                        onNextMonth = { viewModel.navigateToNextMonth() },
                        language = language
                    )

                    // Calendar Grid with adaptive sizing
                    CalendarGrid(
                        currentMonth = uiState.currentMonth,
                        currentYear = uiState.currentYear,
                        selectedDate = uiState.selectedDate,
                        shifts = shifts,
                        onDateSelected = { viewModel.selectDate(it) },
                        language = language,
                        weekStartsOnSunday = !weekStartsMonday,
                        isTablet = useDualPaneLayout // Use tablet sizing in dual-pane mode
                    )

                    // Legend
                    ShiftLegend(language = language)

                    // Quick Actions Section
                    QuickActionsSection(
                        selectedDate = uiState.selectedDate,
                        shifts = shifts,
                        language = language,
                        onAddEntry = { onNavigateToAddEntry(uiState.selectedDate, null) },
                        onAddShift = { onNavigateToAddShift(uiState.selectedDate) },
                        onShowAddEntryDialog = { showAddEntryDialog = true },
                        onShowAddShiftDialog = { showAddShiftDialog = true }
                    )
                }

                // Right column: Shifts List
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                ) {
                    val selectedDateShifts = shifts.filter { it.shiftDate == uiState.selectedDate.toString() }
                    
                    if (selectedDateShifts.isNotEmpty()) {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            // Date header
                            item {
                                val dateFormatter = SimpleDateFormat("MMM d", Locale.getDefault())
                                val dateStr = try {
                                    val date = LocalDate.parse(uiState.selectedDate.toString())
                                    val calendar = Calendar.getInstance()
                                    calendar.set(date.year, date.monthNumber - 1, date.dayOfMonth)
                                    dateFormatter.format(calendar.time)
                                } catch (e: Exception) {
                                    uiState.selectedDate.toString()
                                }
                                
                                Text(
                                    text = when (language) {
                                        "fr" -> "Quarts pour le $dateStr"
                                        "es" -> "Turnos para el $dateStr"
                                        else -> "Shifts for $dateStr"
                                    },
                                    style = MaterialTheme.typography.headlineSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF333333),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 8.dp),
                                    textAlign = TextAlign.Center
                                )
                            }
                            
                            items(selectedDateShifts) { shift ->
                                ShiftCard(
                                    shift = shift,
                                    onClick = {
                                        // For planned shifts without entries, directly open edit shift
                                        // Otherwise show modify dialog
                                        if (shift.status == "planned" && shift.shiftEntry == null) {
                                            onNavigateToEditShift(shift.expectedShift.id)
                                        } else {
                                            shiftToModify = shift
                                            showModifyDialog = true
                                        }
                                    },
                                    language = language,
                                    defaultTipPercentage = defaultTipPercentage
                                )
                            }
                        }
                    } else {
                        // Empty state
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = when (language) {
                                    "fr" -> "Aucun quart sélectionné"
                                    "es" -> "No hay turnos seleccionados"
                                    else -> "No shifts selected"
                                },
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        } else {
            // Portrait layout: Single column (original layout)
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical))
            ) {
                // Month Navigation
                MonthNavigationHeader(
                    currentMonth = uiState.currentMonth,
                    currentYear = uiState.currentYear,
                    onPreviousMonth = { viewModel.navigateToPreviousMonth() },
                    onNextMonth = { viewModel.navigateToNextMonth() },
                    language = language
                )

                // Calendar Grid with adaptive sizing for tablets (Android 16)
                CalendarGrid(
                    currentMonth = uiState.currentMonth,
                    currentYear = uiState.currentYear,
                    selectedDate = uiState.selectedDate,
                    shifts = shifts,
                    onDateSelected = { viewModel.selectDate(it) },
                    language = language,
                    weekStartsOnSunday = !weekStartsMonday,
                    isTablet = isTablet
                )

                // Legend
                ShiftLegend(language = language)

                // Quick Actions Section (iOS-style buttons)
                QuickActionsSection(
                    selectedDate = uiState.selectedDate,
                    shifts = shifts,
                    language = language,
                    onAddEntry = { onNavigateToAddEntry(uiState.selectedDate, null) },
                    onAddShift = { onNavigateToAddShift(uiState.selectedDate) },
                    onShowAddEntryDialog = { showAddEntryDialog = true },
                    onShowAddShiftDialog = { showAddShiftDialog = true }
                )

                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                // Shifts List for selected date
                val selectedDateShifts = shifts.filter { it.shiftDate == uiState.selectedDate.toString() }

                if (selectedDateShifts.isNotEmpty()) {
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        // Date header
                        item {
                            val dateFormatter = SimpleDateFormat("MMM d", Locale.getDefault())
                            val dateStr = try {
                                val date = LocalDate.parse(uiState.selectedDate.toString())
                                val calendar = Calendar.getInstance()
                                calendar.set(date.year, date.monthNumber - 1, date.dayOfMonth)
                                dateFormatter.format(calendar.time)
                            } catch (e: Exception) {
                                uiState.selectedDate.toString()
                            }
                            
                            Text(
                                text = when (language) {
                                    "fr" -> "Quarts pour le $dateStr"
                                    "es" -> "Turnos para el $dateStr"
                                    else -> "Shifts for $dateStr"
                                },
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF333333),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp),
                                textAlign = TextAlign.Center
                            )
                        }
                        
                        items(
                            items = selectedDateShifts,
                            key = { it.expectedShift.id }
                        ) { shift ->
                            ShiftCard(
                                shift = shift,
                                onClick = {
                                    android.util.Log.d("CalendarScreen", "==== SHIFT CARD CLICKED ====")
                                    android.util.Log.d("CalendarScreen", "Shift ID: ${shift.expectedShift.id}")
                                    android.util.Log.d("CalendarScreen", "Shift Date: ${shift.expectedShift.shiftDate}")
                                    android.util.Log.d("CalendarScreen", "Start Time: ${shift.expectedShift.startTime}")
                                    android.util.Log.d("CalendarScreen", "End Time: ${shift.expectedShift.endTime}")
                                    android.util.Log.d("CalendarScreen", "Sales Target: ${shift.expectedShift.salesTarget}")
                                    
                                    // For planned shifts without entries, directly open edit shift
                                    // Otherwise show modify dialog
                                    if (shift.status == "planned" && shift.shiftEntry == null) {
                                        // Direct navigation to edit shift for planned shifts
                                        android.util.Log.d("CalendarScreen", "Navigating to edit shift: ${shift.expectedShift.id}")
                                        onNavigateToEditShift(shift.expectedShift.id)
                                    } else {
                                        // Show modify dialog for completed/missed shifts or shifts with entries
                                        shiftToModify = shift
                                        showModifyDialog = true
                                    }
                                },
                                language = language,
                                defaultTipPercentage = defaultTipPercentage
                            )
                        }
                    }
                } else {
                    // Empty state when no shifts for selected date
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = when (language) {
                                "fr" -> "Aucun quart pour cette date"
                                "es" -> "No hay turnos para esta fecha"
                                else -> "No shifts for this date"
                            },
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }

    // Add Shift Dialog
    if (showAddShiftDialog) {
        val selectedDateShifts = shifts.filter { it.shiftDate == uiState.selectedDate.toString() }
        val existingShift = selectedDateShifts.firstOrNull()

        AlertDialog(
            onDismissRequest = { showAddShiftDialog = false },
            title = { Text(stringResource(R.string.existing_shift_found)) },
            text = { Text(stringResource(R.string.existing_shift_message)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        // Navigation haptic for modify existing shift
                        HapticFeedbackUtils.performNavigationHaptic(haptics)
                        existingShift?.let { onNavigateToEditShift(it.expectedShift.id) }
                        showAddShiftDialog = false
                    }
                ) {
                    Text(stringResource(R.string.modify_existing_shift))
                }
            },
            dismissButton = {
                Column {
                    TextButton(
                        onClick = {
                            // Form interaction haptic for add new shift
                            HapticFeedbackUtils.performFormInteractionHaptic(haptics)
                            onNavigateToAddShift(uiState.selectedDate)
                            showAddShiftDialog = false
                        }
                    ) {
                        Text(stringResource(R.string.add_new_shift))
                    }
                    TextButton(
                        onClick = { showAddShiftDialog = false }
                    ) {
                        Text(stringResource(R.string.cancel))
                    }
                }
            }
        )
    }

    // Add Entry Dialog
    if (showAddEntryDialog) {
        val selectedDateShifts = shifts.filter { it.shiftDate == uiState.selectedDate.toString() }
        val existingShift = selectedDateShifts.firstOrNull()
        val hasEntry = existingShift?.isWorked == true

        AlertDialog(
            onDismissRequest = { showAddEntryDialog = false },
            title = { Text(stringResource(R.string.existing_shift_found)) },
            text = {
                Text(
                    if (hasEntry) {
                        stringResource(R.string.existing_shift_with_entry_message)
                    } else {
                        stringResource(R.string.existing_shift_no_entry_message)
                    }
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        if (hasEntry) {
                            // Edit existing entry
                            if (selectedDateShifts.size > 1) {
                                // Multiple shifts - show selection dialog
                                isEditingEntry = true
                                showShiftSelectionDialog = true
                                showAddEntryDialog = false
                            } else {
                                // Single shift - edit directly
                                existingShift?.let { onNavigateToEditShift(it.expectedShift.id) }
                                showAddEntryDialog = false
                            }
                        } else {
                            // Add entry to existing shift
                            if (selectedDateShifts.size > 1) {
                                // Multiple shifts - show selection dialog
                                isEditingEntry = false
                                showShiftSelectionDialog = true
                                showAddEntryDialog = false
                            } else {
                                // Single shift - navigate to add entry (iOS-conformant: pass shiftId to preselect)
                                onNavigateToAddEntry(uiState.selectedDate, existingShift?.expectedShift?.id)
                                showAddEntryDialog = false
                            }
                        }
                    }
                ) {
                    Text(
                        if (hasEntry) {
                            stringResource(R.string.edit_existing_entry)
                        } else {
                            stringResource(R.string.add_entry_to_existing_shift)
                        }
                    )
                }
            },
            dismissButton = {
                Column {
                    TextButton(
                        onClick = {
                            // Create new shift and entry (no preselected shift)
                            onNavigateToAddEntry(uiState.selectedDate, null)
                            showAddEntryDialog = false
                        }
                    ) {
                        Text(stringResource(R.string.create_new_shift_and_entry))
                    }
                    TextButton(
                        onClick = { showAddEntryDialog = false }
                    ) {
                        Text(stringResource(R.string.cancel))
                    }
                }
            }
        )
    }
    
    // Shift Selection Dialog (for multiple shifts on same date)
    if (showShiftSelectionDialog) {
        val selectedDateShifts = shifts.filter { it.shiftDate == uiState.selectedDate.toString() }
        
        AlertDialog(
            onDismissRequest = { showShiftSelectionDialog = false },
            title = { 
                Text(
                    stringResource(R.string.select_shift)
                ) 
            },
            text = {
                Text(
                    stringResource(R.string.multiple_shifts_exist)
                )
            },
            confirmButton = {},
            dismissButton = {
                Column(
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    selectedDateShifts.forEach { shift ->
                        TextButton(
                            onClick = {
                                if (isEditingEntry) {
                                    // Edit existing entry
                                    onNavigateToEditShift(shift.expectedShift.id)
                                } else {
                                    // Add entry to this shift (iOS-conformant: pass shiftId to preselect)
                                    onNavigateToAddEntry(uiState.selectedDate, shift.expectedShift.id)
                                }
                                showShiftSelectionDialog = false
                            }
                        ) {
                            Text(
                                text = "${shift.employerName ?: stringResource(R.string.no_employer)} (${shift.expectedShift.startTime} - ${shift.expectedShift.endTime})",
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }
                    
                    HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))
                    
                    TextButton(
                        onClick = { showShiftSelectionDialog = false }
                    ) {
                        Text(
                            stringResource(R.string.cancel)
                        )
                    }
                }
            }
        )
    }
    
    // Modify Shift/Entry Dialog (iOS-style)
    if (showModifyDialog && shiftToModify != null) {
        val shift = shiftToModify!!
        val shiftDate = try {
            LocalDate.parse(shift.shiftDate)
        } catch (e: Exception) {
            uiState.selectedDate
        }
        
        AlertDialog(
            onDismissRequest = {
                showModifyDialog = false
                shiftToModify = null
            },
            title = {
                Text(
                    text = stringResource(R.string.shift_for_date, shiftDate.toString())
                )
            },
            text = {
                Column(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    TextButton(
                        onClick = {
                            showModifyDialog = false
                            shiftToModify = null
                            // Navigate to edit shift
                            onNavigateToEditShift(shift.expectedShift.id)
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = stringResource(R.string.modify_shift),
                            modifier = Modifier.fillMaxWidth(),
                            textAlign = TextAlign.Center
                        )
                    }
                    
                    TextButton(
                        onClick = {
                            showModifyDialog = false
                            shiftToModify = null
                            // Navigate to edit entry if exists, otherwise add entry
                            if (shift.shiftEntry != null) {
                                onNavigateToEditEntry(shift.shiftEntry.id)
                            } else if (shift.status == "missed") {
                                // Missed shift - navigate to add entry with shiftId
                                onNavigateToAddEntry(shiftDate, shift.expectedShift.id)
                            } else {
                                // No entry - navigate to add entry with shiftId
                                onNavigateToAddEntry(shiftDate, shift.expectedShift.id)
                            }
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = stringResource(R.string.modify_entry),
                            modifier = Modifier.fillMaxWidth(),
                            textAlign = TextAlign.Center
                        )
                    }
                }
            },
            confirmButton = {},
            dismissButton = {
                TextButton(
                    onClick = {
                        showModifyDialog = false
                        shiftToModify = null
                    }
                ) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
    
    // Delete Confirmation Dialog
    if (showDeleteDialog && shiftToDelete != null) {
        val shift = shiftToDelete!!
        // Check if shift has entry data (actual entry OR missed shift with reason)
        val hasEntry = shift.shiftEntry != null || shift.status == "missed"
        
        AlertDialog(
            onDismissRequest = {
                showDeleteDialog = false
                shiftToDelete = null
            },
            title = {
                Text(stringResource(R.string.delete_shift))
            },
            text = {
                Text(
                    if (hasEntry) {
                        stringResource(R.string.delete_shift_with_entry_confirm)
                    } else {
                        stringResource(R.string.delete_shift_confirm)
                    }
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteShift(shift.expectedShift.id) {
                            showDeleteDialog = false
                            shiftToDelete = null
                        }
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text(stringResource(R.string.yes))
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        shiftToDelete = null
                    }
                ) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}

@Composable
fun MonthNavigationHeader(
    currentMonth: Int,
    currentYear: Int,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    language: String
) {
    val monthNames = listOf(
        stringResource(R.string.january),
        stringResource(R.string.february),
        stringResource(R.string.march),
        stringResource(R.string.april),
        stringResource(R.string.may),
        stringResource(R.string.june),
        stringResource(R.string.july),
        stringResource(R.string.august),
        stringResource(R.string.september),
        stringResource(R.string.october),
        stringResource(R.string.november),
        stringResource(R.string.december)
    )
    val monthName = monthNames[currentMonth - 1]

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onPreviousMonth) {
            Icon(Icons.Default.ChevronLeft, contentDescription = stringResource(R.string.previous_month))
        }

        Text(
            text = "$monthName $currentYear",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )

        IconButton(onClick = onNextMonth) {
            Icon(Icons.Default.ChevronRight, contentDescription = stringResource(R.string.next_month))
        }
    }
}

@Composable
fun CalendarGrid(
    currentMonth: Int,
    currentYear: Int,
    selectedDate: LocalDate,
    shifts: List<CompletedShift>,
    onDateSelected: (LocalDate) -> Unit,
    language: String,
    weekStartsOnSunday: Boolean,
    isTablet: Boolean = false
) {
    val daysOfWeek = if (weekStartsOnSunday) {
        listOf(
            stringResource(R.string.day_sun),
            stringResource(R.string.day_mon),
            stringResource(R.string.day_tue),
            stringResource(R.string.day_wed),
            stringResource(R.string.day_thu),
            stringResource(R.string.day_fri),
            stringResource(R.string.day_sat)
        )
    } else {
        listOf(
            stringResource(R.string.day_mon),
            stringResource(R.string.day_tue),
            stringResource(R.string.day_wed),
            stringResource(R.string.day_thu),
            stringResource(R.string.day_fri),
            stringResource(R.string.day_sat),
            stringResource(R.string.day_sun)
        )
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        // Week day headers
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            daysOfWeek.forEach { day ->
                Text(
                    text = day,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Calendar days grid - iOS-conformant: Generate exactly 35 days (5 weeks)
        val firstDayOfMonth = LocalDate(currentYear, currentMonth, 1)
        val startDayOfWeek = firstDayOfMonth.dayOfWeek
        val startOffset = if (weekStartsOnSunday) {
            startDayOfWeek.value % 7
        } else {
            (startDayOfWeek.value - 1) % 7
        }

        // Calculate the first date to show (including days from previous month)
        val firstDateToShow = firstDayOfMonth.minus(DatePeriod(days = startOffset))
        
        // Generate exactly 35 dates (5 weeks) to match iOS
        val allDates = (0 until 35).map { index ->
            firstDateToShow.plus(DatePeriod(days = index))
        }

        LazyVerticalGrid(
            columns = GridCells.Fixed(7),
            modifier = Modifier.height(
                if (isTablet) 420.dp else 300.dp // Larger calendar for tablets (6 weeks visible)
            ),
            userScrollEnabled = false,
            contentPadding = PaddingValues(horizontal = if (isTablet) 32.dp else 16.dp)
        ) {
            items(35) { index ->
                val date = allDates[index]
                val isToday = date == Clock.System.now().toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date
                val isSelected = date == selectedDate
                val isCurrentMonth = date.monthNumber == currentMonth
                val dayShifts = shifts.filter { it.shiftDate == date.toString() }

                CalendarDay(
                    day = date.dayOfMonth,
                    isToday = isToday,
                    isSelected = isSelected,
                    isCurrentMonth = isCurrentMonth,
                    shifts = dayShifts,
                    onClick = { onDateSelected(date) }
                )
            }
        }
    }
}

@Composable
fun CalendarDay(
    day: Int,
    isToday: Boolean,
    isSelected: Boolean,
    isCurrentMonth: Boolean = true,
    shifts: List<CompletedShift>,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(52.dp)
            .padding(4.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(
                when {
                    isSelected -> MaterialTheme.colorScheme.primary
                    isToday -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
                    else -> Color.Transparent
                }
            )
            .border(
                width = if (isToday && !isSelected) 2.dp else 0.dp,
                color = if (isToday && !isSelected)
                    MaterialTheme.colorScheme.primary
                else
                    Color.Transparent,
                shape = RoundedCornerShape(12.dp)
            )
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.alpha(if (isCurrentMonth) 1.0f else 0.3f) // iOS-conformant opacity
        ) {
            Text(
                text = day.toString(),
                style = MaterialTheme.typography.bodyLarge,  // Increased from bodyMedium
                color = when {
                    isSelected -> MaterialTheme.colorScheme.onPrimary
                    isToday -> MaterialTheme.colorScheme.primary
                    !isCurrentMonth -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                    else -> MaterialTheme.colorScheme.onSurface
                },
                fontWeight = if (isToday || isSelected) FontWeight.Bold else FontWeight.Normal
            )

            // Shift status indicators
            if (shifts.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(3.dp)
                ) {
                    shifts.take(3).forEach { shift ->
                        Box(
                            modifier = Modifier
                                .size(6.dp)
                                .background(
                                    color = when (shift.status) {
                                        "completed" -> Color(0xFF34C759)  // iOS green
                                        "planned" -> Color(0xFF007AFF)  // iOS blue
                                        "missed" -> Color(0xFFFF3B30)  // iOS red
                                        else -> Color.Gray
                                    },
                                    shape = CircleShape
                                )
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ShiftLegend(language: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        LegendItem(
            color = Color(0xFF007AFF),
            label = stringResource(R.string.planned)
        )
        LegendItem(
            color = Color(0xFF34C759),
            label = stringResource(R.string.completed)
        )
        LegendItem(
            color = Color(0xFFFF3B30),
            label = stringResource(R.string.missed)
        )
    }
}

@Composable
fun LegendItem(color: Color, label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .background(color = color, shape = RoundedCornerShape(2.dp))
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShiftCard(
    shift: CompletedShift,
    onClick: () -> Unit,
    language: String,
    defaultTipPercentage: Double = 20.0
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFFF8F8F8)
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp,
            pressedElevation = 4.dp
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            // Top section: Icon + Employer name + Shift type + Expected time
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                // Left side: Icon + Employer info
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    // Icon (light blue square with fork/knife)
                    Surface(
                        modifier = Modifier.size(48.dp),
                        color = Color(0xFFA0D4F7),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Store,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(24.dp)
                            )
                        }
                    }

                    // Employer name and shift type
                    Column {
                        Text(
                            text = shift.employerName,
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF333333)
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        // Shift type - infer from time or use notes
                        val shiftType = inferShiftType(shift.expectedShift.startTime, language)
                        Text(
                            text = shiftType,
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF666666)
                        )
                    }
                }

                // Right side: Expected time
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = "${formatTime(shift.expectedShift.startTime, language)} - ${formatTime(shift.expectedShift.endTime, language)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color(0xFF333333)
                    )
                    Text(
                        text = when (language) {
                            "fr" -> "(Prévu)"
                            "es" -> "(Esperado)"
                            else -> "(Expected)"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFF999999)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Actual time section (only for completed/missed shifts)
            if (shift.status == "completed" || shift.status == "missed") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = when (language) {
                            "fr" -> "Temps réel"
                            "es" -> "Tiempo real"
                            else -> "Actual Time"
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color(0xFF666666)
                    )
                    if (shift.status == "missed") {
                        val missedReason = shift.expectedShift.notes ?: stringResource(R.string.didnt_work)
                        Text(
                            text = missedReason,
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF333333)
                        )
                    } else if (shift.shiftEntry != null) {
                        Text(
                            text = "${formatTime(shift.shiftEntry.actualStartTime, language)} - ${formatTime(shift.shiftEntry.actualEndTime, language)}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF333333)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Hours and Tips comparison (two columns)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    // Hours column
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = when (language) {
                                "fr" -> "Heures"
                                "es" -> "Horas"
                                else -> "Hours"
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF666666)
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        if (shift.shiftEntry != null) {
                            val expectedHoursStr = String.format("%.1f", shift.expectedShift.expectedHours)
                            val actualHoursStr = String.format("%.1f", shift.shiftEntry.actualHours)
                            Text(
                                text = "${expectedHoursStr}h → ${actualHoursStr}h",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color(0xFF333333)
                            )
                        } else {
                            Text(
                                text = "${String.format("%.1f", shift.expectedShift.expectedHours)}h",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color(0xFF333333)
                            )
                        }
                    }

                    // Tips column
                    Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.End) {
                        Text(
                            text = when (language) {
                                "fr" -> "Pourboires"
                                "es" -> "Propinas"
                                else -> "Tips"
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF666666)
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        // Calculate expected tips from sales target
                        val expectedTips = shift.expectedShift.salesTarget?.let { salesTarget ->
                            salesTarget * (defaultTipPercentage / 100.0)
                        } ?: 0.0
                        val actualTips = shift.shiftEntry?.tips ?: 0.0
                        
                        if (shift.shiftEntry != null && actualTips > 0) {
                            // Show comparison if we have expected tips
                            if (expectedTips > 0) {
                                Text(
                                    text = "${formatCurrency(expectedTips)} → ${formatCurrency(actualTips)}",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Color(0xFF4CAF50)
                                )
                            } else {
                                // Just show actual tips if no expected tips
                                Text(
                                    text = formatCurrency(actualTips),
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Color(0xFF4CAF50)
                                )
                            }
                        } else if (expectedTips > 0) {
                            // Show expected tips only (for planned shifts with sales target)
                            Text(
                                text = formatCurrency(expectedTips),
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color(0xFF999999)
                            )
                        } else {
                            Text(
                                text = formatCurrency(0.0),
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color(0xFF999999)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
            } else {
                // For planned shifts, show duration and status badge
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "${String.format("%.1f", shift.expectedShift.expectedHours)}h",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color(0xFF333333)
                    )
                    Surface(
                        color = Color(0xFF007AFF).copy(alpha = 0.12f),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = stringResource(R.string.planned),
                            color = Color(0xFF007AFF),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                        )
                    }
                }
            }

            // Total Earnings section (light blue background) - only for completed shifts
            if (shift.status == "completed" && shift.shiftEntry != null) {
                Spacer(modifier = Modifier.height(16.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = Color(0xFFE0F2F7),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = when (language) {
                                "fr" -> "Gains totaux"
                                "es" -> "Ganancias totales"
                                else -> "Total Earnings"
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF2196F3),
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = formatCurrency(shift.totalEarnings),
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF2196F3)
                        )
                    }
                }
            }
        }
    }
}

private fun inferShiftType(startTime: String, language: String): String {
    return try {
        val timeParts = startTime.split(":")
        val hour = timeParts[0].toIntOrNull() ?: return when (language) {
            "fr" -> "Quart"
            "es" -> "Turno"
            else -> "Shift"
        }
        
        when {
            hour < 12 -> when (language) {
                "fr" -> "Quart du matin"
                "es" -> "Turno matutino"
                else -> "Morning Shift"
            }
            hour < 17 -> when (language) {
                "fr" -> "Quart de l'après-midi"
                "es" -> "Turno vespertino"
                else -> "Afternoon Shift"
            }
            else -> when (language) {
                "fr" -> "Quart du soir"
                "es" -> "Turno nocturno"
                else -> "Evening Shift"
            }
        }
    } catch (e: Exception) {
        when (language) {
            "fr" -> "Quart"
            "es" -> "Turno"
            else -> "Shift"
        }
    }
}

@Composable
fun EmptyShiftsState(
    selectedDate: LocalDate,
    modifier: Modifier = Modifier
) {
    val formatter = SimpleDateFormat("EEEE, MMMM d", Locale.getDefault())
@Suppress("UNUSED_VARIABLE")
    val date = Date(selectedDate.toEpochDays() * 24 * 60 * 60 * 1000L)

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.EventAvailable,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = stringResource(R.string.no_shifts),
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Text(
            text = formatter.format(date),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
        )
    }
}

private fun formatTime(timeString: String, language: String = "en"): String {
    return try {
        // Parse input time (HH:mm:ss or HH:mm format)
        val inputFormat = SimpleDateFormat("HH:mm:ss", Locale.US)
        val inputFormatShort = SimpleDateFormat("HH:mm", Locale.US)
        
        val date = inputFormat.parse(timeString) ?: inputFormatShort.parse(timeString) ?: return timeString
        
        // Format output based on language (iOS-conformant)
        val outputFormat = when (language) {
            "fr" -> SimpleDateFormat("HH:mm", Locale.FRANCE)  // 24-hour format
            "es" -> SimpleDateFormat("HH:mm", Locale("es", "ES"))  // 24-hour format
            else -> SimpleDateFormat("h:mm a", Locale.US)  // 12-hour format with AM/PM
        }
        
        outputFormat.format(date)
    } catch (e: Exception) {
        timeString
    }
}

private fun formatCurrency(amount: Double): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale.getDefault())
    return formatter.format(amount)
}

private fun calculateHours(startTime: String, endTime: String): String {
    return try {
        val startParts = startTime.split(":")
        val endParts = endTime.split(":")

        if (startParts.size >= 2 && endParts.size >= 2) {
            val startHour = startParts[0].toIntOrNull() ?: 0
            val startMinute = startParts[1].toIntOrNull() ?: 0
            val endHour = endParts[0].toIntOrNull() ?: 0
            val endMinute = endParts[1].toIntOrNull() ?: 0

            var totalMinutes = (endHour * 60 + endMinute) - (startHour * 60 + startMinute)

            // Handle overnight shifts
            if (totalMinutes < 0) {
                totalMinutes += 24 * 60
            }

            val hours = totalMinutes / 60
            val minutes = totalMinutes % 60

            if (minutes == 0) {
                "$hours.0"
            } else {
                String.format("%.1f", hours + minutes / 60.0)
            }
        } else {
            "0.0"
        }
    } catch (e: Exception) {
        "0.0"
    }
}

private fun formatDateForHeader(date: LocalDate): String {
    val formatter = SimpleDateFormat("MMMM d, yyyy", Locale.getDefault())
    val calendar = Calendar.getInstance()
    calendar.set(date.year, date.monthNumber - 1, date.dayOfMonth)
    return formatter.format(calendar.time)
}

@Composable
private fun getHoursVarianceColor(expectedHours: Double, actualHours: Double): Color {
    val variance = actualHours - expectedHours
    
    return when {
        variance > 0.5 -> Color(0xFF4CAF50)  // Green - worked more than expected by 30+ minutes
        variance < -0.5 -> Color(0xFFFF9800)  // Orange - worked less than expected by 30+ minutes
        else -> MaterialTheme.colorScheme.primary  // Close to expected
    }
}

@Composable
fun QuickActionsSection(
    selectedDate: LocalDate,
    shifts: List<CompletedShift>,
    language: String,
    onAddEntry: () -> Unit,
    onAddShift: () -> Unit,
    onShowAddEntryDialog: () -> Unit,
    onShowAddShiftDialog: () -> Unit
) {
    val today = Clock.System.now().toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date
    
    // iOS Logic: Add Entry enabled for today OR past (selected <= today)
    // iOS Logic: Add Shift enabled for today OR future (selected >= today)
    val entryEnabled = selectedDate <= today
    val shiftEnabled = selectedDate >= today

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Add Entry button
        Button(
            onClick = {
                val existingShifts = shifts.filter {
                    it.shiftDate == selectedDate.toString()
                }
                if (existingShifts.isNotEmpty()) {
                    onShowAddEntryDialog()
                } else {
                    onAddEntry()
                }
            },
            enabled = entryEnabled,
            modifier = Modifier
                .weight(1f)
                .height(52.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                disabledContentColor = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
            ),
            shape = RoundedCornerShape(16.dp),
            elevation = ButtonDefaults.buttonElevation(
                defaultElevation = 2.dp,
                pressedElevation = 4.dp,
                disabledElevation = 0.dp
            ),
            contentPadding = PaddingValues(vertical = 12.dp)
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Add,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Text(
                    text = stringResource(R.string.add_entry_action),
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        // Add Shift button
        Button(
            onClick = {
                val existingShifts = shifts.filter {
                    it.shiftDate == selectedDate.toString()
                }
                if (existingShifts.isNotEmpty()) {
                    onShowAddShiftDialog()
                } else {
                    onAddShift()
                }
            },
            enabled = shiftEnabled,
            modifier = Modifier
                .weight(1f)
                .height(52.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color(0xFF007AFF),
                contentColor = Color.White,
                disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                disabledContentColor = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
            ),
            shape = RoundedCornerShape(16.dp),
            elevation = ButtonDefaults.buttonElevation(
                defaultElevation = 2.dp,
                pressedElevation = 4.dp,
                disabledElevation = 0.dp
            ),
            contentPadding = PaddingValues(vertical = 12.dp)
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.CalendarMonth,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Text(
                    text = stringResource(R.string.add_shift_action),
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}