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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.R
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.data.models.CompletedShift
import kotlinx.datetime.*
import java.util.TimeZone
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarScreen(
    onNavigateToAddShift: () -> Unit,
    onNavigateToAddEntry: (LocalDate) -> Unit,
    onNavigateToEditShift: (String) -> Unit,
    viewModel: CalendarViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val shifts by viewModel.shifts.collectAsState()

@Suppress("UNUSED_VARIABLE")
    val context = LocalContext.current
    val preferencesManager = remember { PreferencesManager(context) }
    val language = preferencesManager.getLanguage()
    val weekStartsMonday = preferencesManager.getWeekStartsMonday()

    // Dialog states for Add Shift/Entry flows
    var showAddShiftDialog by remember { mutableStateOf(false) }
    var showAddEntryDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when (language) {
                            "fr" -> "Calendrier"
                            "es" -> "Calendario"
                            else -> "Calendar"
                        }
                    )
                }
            )
        },
        floatingActionButton = {
            val today = Clock.System.now().toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date
            val isPastOrToday = uiState.selectedDate <= today
            val isTodayOrFuture = uiState.selectedDate >= today

            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.Bottom,
                modifier = Modifier.padding(horizontal = 8.dp)
            ) {
                // Add Entry button - only visible for today or past dates
                if (isPastOrToday) {
                    ExtendedFloatingActionButton(
                        onClick = {
                            val existingShifts = shifts.filter {
                                it.shiftDate == uiState.selectedDate.toString()
                            }
                            if (existingShifts.isNotEmpty()) {
                                showAddEntryDialog = true
                            } else {
                                onNavigateToAddEntry(uiState.selectedDate)
                            }
                        },
                        containerColor = MaterialTheme.colorScheme.primary,
                        contentColor = MaterialTheme.colorScheme.onPrimary,
                        icon = {
                            Icon(
                                Icons.Default.Add,
                                contentDescription = null,
                                modifier = Modifier.size(24.dp)
                            )
                        },
                        text = {
                            Text(
                                text = when (language) {
                                    "fr" -> "Ajouter Entrée"
                                    "es" -> "Agregar Entrada"
                                    else -> "Add Entry"
                                }
                            )
                        }
                    )
                }

                // Add Shift button - only visible for today or future dates
                if (isTodayOrFuture) {
                    ExtendedFloatingActionButton(
                        onClick = {
                            val existingShifts = shifts.filter {
                                it.shiftDate == uiState.selectedDate.toString()
                            }
                            if (existingShifts.isNotEmpty()) {
                                showAddShiftDialog = true
                            } else {
                                onNavigateToAddShift()
                            }
                        },
                        containerColor = MaterialTheme.colorScheme.secondaryContainer,
                        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                        icon = {
                            Icon(
                                Icons.Default.CalendarMonth,
                                contentDescription = null,
                                modifier = Modifier.size(24.dp)
                            )
                        },
                        text = {
                            Text(
                                text = when (language) {
                                    "fr" -> "Ajouter Quart"
                                    "es" -> "Agregar Turno"
                                    else -> "Add Shift"
                                }
                            )
                        }
                    )
                }
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Month Navigation
            MonthNavigationHeader(
                currentMonth = uiState.currentMonth,
                currentYear = uiState.currentYear,
                onPreviousMonth = { viewModel.navigateToPreviousMonth() },
                onNextMonth = { viewModel.navigateToNextMonth() },
                language = language
            )

            // Calendar Grid
            CalendarGrid(
                currentMonth = uiState.currentMonth,
                currentYear = uiState.currentYear,
                selectedDate = uiState.selectedDate,
                shifts = shifts,
                onDateSelected = { viewModel.selectDate(it) },
                language = language,
                weekStartsOnSunday = !weekStartsMonday
            )

            // Legend
            ShiftLegend(language = language)

            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

            // Shifts List for selected date (header removed per iOS update)
            val selectedDateShifts = shifts.filter { it.shiftDate == uiState.selectedDate.toString() }

            if (selectedDateShifts.isEmpty()) {
                EmptyShiftsState(
                    selectedDate = uiState.selectedDate,
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f)
                )
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = selectedDateShifts,
                        key = { it.expectedShift.id }
                    ) { shift ->
                        ShiftCard(
                            shift = shift,
                            onClick = { onNavigateToEditShift(shift.expectedShift.id) },
                            language = language
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
                            onNavigateToAddShift()
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
                            existingShift?.let { onNavigateToEditShift(it.expectedShift.id) }
                        } else {
                            // Add entry to existing shift (navigate to add entry with preselected shift)
                            onNavigateToAddEntry(uiState.selectedDate)
                        }
                        showAddEntryDialog = false
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
                            // Create new shift and entry
                            onNavigateToAddEntry(uiState.selectedDate)
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
}

@Composable
fun MonthNavigationHeader(
    currentMonth: Int,
    currentYear: Int,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    language: String
) {
    val monthName = when (language) {
        "fr" -> listOf("Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                       "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre")[currentMonth - 1]
        "es" -> listOf("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                       "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")[currentMonth - 1]
        else -> listOf("January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December")[currentMonth - 1]
    }

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
    weekStartsOnSunday: Boolean
) {
    val daysOfWeek = if (weekStartsOnSunday) {
        when (language) {
            "fr" -> listOf("Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam")
            "es" -> listOf("Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb")
            else -> listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
        }
    } else {
        when (language) {
            "fr" -> listOf("Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim")
            "es" -> listOf("Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom")
            else -> listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        }
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

        // Calendar days grid
        val firstDayOfMonth = LocalDate(currentYear, currentMonth, 1)
        val lastDayOfMonth = firstDayOfMonth.plus(DatePeriod(months = 1)).minus(DatePeriod(days = 1))

        val daysInMonth = lastDayOfMonth.dayOfMonth
        val startDayOfWeek = firstDayOfMonth.dayOfWeek
        val startOffset = if (weekStartsOnSunday) {
            startDayOfWeek.value % 7
        } else {
            (startDayOfWeek.value - 1) % 7
        }

        val totalCells = startOffset + daysInMonth
        val weeks = (totalCells + 6) / 7

        LazyVerticalGrid(
            columns = GridCells.Fixed(7),
            modifier = Modifier.height((weeks * 60).dp),
            userScrollEnabled = false
        ) {
            // Empty cells before month starts
            items(startOffset) {
                Box(modifier = Modifier.size(48.dp))
            }

            // Days of the month
            items(daysInMonth) { dayIndex ->
                val day = dayIndex + 1
                val date = LocalDate(currentYear, currentMonth, day)
                val isToday = date == Clock.System.now().toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date
                val isSelected = date == selectedDate
                val dayShifts = shifts.filter { it.shiftDate == date.toString() }

                CalendarDay(
                    day = day,
                    isToday = isToday,
                    isSelected = isSelected,
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
    shifts: List<CompletedShift>,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .padding(2.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(
                when {
                    isSelected -> MaterialTheme.colorScheme.primary
                    isToday -> MaterialTheme.colorScheme.primaryContainer
                    else -> Color.Transparent
                }
            )
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = day.toString(),
                style = MaterialTheme.typography.bodyMedium,
                color = when {
                    isSelected -> MaterialTheme.colorScheme.onPrimary
                    isToday -> MaterialTheme.colorScheme.onPrimaryContainer
                    else -> MaterialTheme.colorScheme.onSurface
                },
                fontWeight = if (isToday || isSelected) FontWeight.Bold else FontWeight.Normal
            )

            // Shift status indicators
            if (shifts.isNotEmpty()) {
                Row(
                    modifier = Modifier.padding(top = 2.dp),
                    horizontalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    shifts.take(3).forEach { shift ->
                        Box(
                            modifier = Modifier
                                .size(4.dp)
                                .background(
                                    color = when (shift.status) {
                                        "completed" -> Color(0xFF4CAF50) // Green
                                        "planned" -> Color(0xFF9C27B0) // Purple
                                        "missed" -> Color(0xFFF44336) // Red
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
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        LegendItem(
            color = Color(0xFF9C27B0),
            label = when (language) {
                "fr" -> "Planifié"
                "es" -> "Planificado"
                else -> "Planned"
            }
        )
        LegendItem(
            color = Color(0xFF4CAF50),
            label = when (language) {
                "fr" -> "Complété"
                "es" -> "Completado"
                else -> "Completed"
            }
        )
        LegendItem(
            color = Color(0xFFF44336),
            label = when (language) {
                "fr" -> "Manqué"
                "es" -> "Perdido"
                else -> "Missed"
            }
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
    language: String
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header with employer name and status
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                // Employer name
                Text(
                    text = shift.employerName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )

                // Status badge (if completed)
                if (shift.isWorked) {
                    Surface(
                        color = Color(0xFF4CAF50),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.padding(start = 8.dp)
                    ) {
                        Text(
                            text = when (language) {
                                "fr" -> "Complété"
                                "es" -> "Completado"
                                else -> "Completed"
                            },
                            color = Color.White,
                            style = MaterialTheme.typography.labelSmall,
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Expected shift information
            Column {
                Text(
                    text = when (language) {
                        "fr" -> "Prévu:"
                        "es" -> "Esperado:"
                        else -> "Expected:"
                    },
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontWeight = FontWeight.Medium
                )

                Text(
                    text = "${formatTime(shift.expectedShift.startTime)} - ${formatTime(shift.expectedShift.endTime)}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Text(
                    text = "${calculateHours(shift.expectedShift.startTime, shift.expectedShift.endTime)} ${
                        when (language) {
                            "fr" -> "heures"
                            "es" -> "horas"
                            else -> "hours"
                        }
                    }",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Actual shift information (if worked)
            if (shift.isWorked && shift.shiftEntry != null) {
                Spacer(modifier = Modifier.height(8.dp))

                Column {
                    Text(
                        text = when (language) {
                            "fr" -> "Réel:"
                            "es" -> "Actual:"
                            else -> "Actual:"
                        },
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontWeight = FontWeight.Medium
                    )

                    Text(
                        text = "${formatTime(shift.shiftEntry.actualStartTime)} - ${formatTime(shift.shiftEntry.actualEndTime)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Text(
                        text = "${calculateHours(shift.shiftEntry.actualStartTime, shift.shiftEntry.actualEndTime)} ${
                            when (language) {
                                "fr" -> "heures"
                                "es" -> "horas"
                                else -> "hours"
                            }
                        }",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Entry note if exists
            val notes = shift.notes
            if (!notes.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = notes,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
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

private fun formatTime(timeString: String): String {
    return try {
        val parts = timeString.split(":")
        if (parts.size >= 2) {
            val hour = parts[0].toIntOrNull() ?: 0
            val minute = parts[1].toIntOrNull() ?: 0
            val isPM = hour >= 12
            val displayHour = when {
                hour == 0 -> 12
                hour > 12 -> hour - 12
                else -> hour
            }
            String.format("%d:%02d %s", displayHour, minute, if (isPM) "PM" else "AM")
        } else timeString
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