package com.protip365.app.presentation.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.pullrefresh.PullRefreshIndicator
import androidx.compose.material.pullrefresh.pullRefresh
import androidx.compose.material.pullrefresh.rememberPullRefreshState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.data.models.Entry
import com.protip365.app.data.models.Shift
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle as JavaTextStyle
import java.time.DayOfWeek
import java.util.*
import com.kizitonwose.calendar.compose.CalendarState
import com.kizitonwose.calendar.core.CalendarDay
import com.kizitonwose.calendar.core.DayPosition

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterialApi::class)
@Composable
fun CalendarScreen(
    navController: NavController,
    viewModel: CalendarViewModel = hiltViewModel()
) {
    val scope = rememberCoroutineScope()
    val state by viewModel.state.collectAsState()
    val selectedDate by viewModel.selectedDate.collectAsState()
    val currentLanguage by viewModel.currentLanguage.collectAsState()
    // Subscription features disabled for testing
    // val subscriptionTier by viewModel.subscriptionTier.collectAsState()
    // val weeklyLimits by viewModel.weeklyLimits.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    var isRefreshing by remember { mutableStateOf(false) }

    val pullRefreshState = rememberPullRefreshState(
        refreshing = isRefreshing,
        onRefresh = {
            scope.launch {
                isRefreshing = true
                viewModel.refreshData()
                delay(1000)
                isRefreshing = false
            }
        }
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Calendrier"
                            "es" -> "Calendario"
                            else -> "Calendar"
                        }
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .pullRefresh(pullRefreshState)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .background(MaterialTheme.colorScheme.background)
                    .padding(vertical = 12.dp)
            ) {
                // Custom Calendar matching iOS style
                CustomCalendarView(
                    selectedDate = selectedDate ?: LocalDate.now(),
                    shiftsForDate = { date ->
                        val shiftData = state.shiftsDataMap[date]
                        shiftData?.shifts ?: emptyList()
                    },
                    onDateTapped = { date ->
                        viewModel.selectDate(date)
                    },
                    language = currentLanguage
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Calendar legend
                CustomCalendarLegend(
                    language = currentLanguage
                )

                // Part-time limits indicator - DISABLED FOR TESTING
                /*
                if (subscriptionTier == "part_time") {
                    Spacer(modifier = Modifier.height(12.dp))
                    PartTimeLimitsIndicator(
                        shiftsUsed = weeklyLimits.shiftsUsed,
                        entriesUsed = weeklyLimits.entriesUsed,
                        currentLanguage = currentLanguage
                    )
                }
                */

                Spacer(modifier = Modifier.height(16.dp))

                // Action buttons with date validation
                CalendarActionButtons(
                    selectedDate = selectedDate ?: LocalDate.now(),
                    onAddShift = {
                        navController.navigate("add_shift?date=$selectedDate")
                    },
                    onQuickEntry = {
                        navController.navigate("add_entry?date=$selectedDate")
                    },
                    canAddMore = true, // Subscription limits disabled for testing
                    currentLanguage = currentLanguage
                )

                // Selected date shifts/entries
                if (state.selectedDateShifts.isNotEmpty() || state.selectedDateEntries.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(20.dp))

                    SelectedDateSection(
                        date = selectedDate ?: LocalDate.now(),
                        shifts = state.selectedDateShifts,
                        entries = state.selectedDateEntries,
                        onEditShift = { shift ->
                            navController.navigate("edit_shift/${shift.id}")
                        },
                        onEditEntry = { entry ->
                            navController.navigate("edit_entry/${entry.id}")
                        },
                        onDeleteShift = { shift ->
                            viewModel.deleteShift(shift)
                        },
                        onDeleteEntry = { entry ->
                            viewModel.deleteEntry(entry)
                        },
                        currentLanguage = currentLanguage
                    )
                }

                // Bottom padding for scrolling
                Spacer(modifier = Modifier.height(100.dp))
            }

            // Pull refresh indicator
            PullRefreshIndicator(
                refreshing = isRefreshing,
                state = pullRefreshState,
                modifier = Modifier.align(Alignment.TopCenter)
            )

            // Loading overlay
            if (isLoading && !isRefreshing) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}

@Composable
fun SelectedDateSection(
    date: LocalDate,
    shifts: List<Shift>,
    entries: List<Entry>,
    onEditShift: (Shift) -> Unit,
    onEditEntry: (Entry) -> Unit,
    onDeleteShift: (Shift) -> Unit,
    onDeleteEntry: (Entry) -> Unit,
    currentLanguage: String
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        // Date header
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = date.format(
                        DateTimeFormatter.ofPattern(
                            when (currentLanguage) {
                                "fr" -> "EEEE d MMMM"
                                "es" -> "EEEE d 'de' MMMM"
                                else -> "EEEE, MMMM d"
                            },
                            when (currentLanguage) {
                                "fr" -> Locale.FRENCH
                                "es" -> Locale("es", "ES")
                                else -> Locale.ENGLISH
                            }
                        )
                    ),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                val totalEarnings = shifts.sumOf { it.totalEarnings } +
                                   entries.sumOf { it.totalEarnings }
                if (totalEarnings > 0) {
                    Text(
                        text = formatCurrency(totalEarnings),
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Shifts
        shifts.forEach { shift ->
            SwipeableShiftCard(
                shift = ShiftData(
                    shifts = listOf(shift),
                    entries = emptyList(),
                    totalEarnings = shift.totalEarnings,
                    totalHours = shift.hours
                ),
                employerName = shift.employerName,
                onEdit = { onEditShift(shift) },
                onDelete = { onDeleteShift(shift) },
                currentLanguage = currentLanguage
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        // Entries
        entries.forEach { entry ->
            SwipeableShiftCard(
                shift = ShiftData(
                    shifts = emptyList(),
                    entries = listOf(entry),
                    totalEarnings = entry.totalEarnings,
                    totalHours = 0.0
                ),
                employerName = when (currentLanguage) {
                    "fr" -> "Entrée rapide"
                    "es" -> "Entrada rápida"
                    else -> "Quick Entry"
                },
                onEdit = { onEditEntry(entry) },
                onDelete = { onDeleteEntry(entry) },
                currentLanguage = currentLanguage
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

// Keep existing helper components but update them
@Composable
private fun Day(
    day: CalendarDay,
    isSelected: Boolean,
    hasShift: Boolean,
    earnings: Double,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .aspectRatio(1f)
            .clip(CircleShape)
            .background(
                color = when {
                    isSelected -> MaterialTheme.colorScheme.primary
                    day.date == LocalDate.now() -> MaterialTheme.colorScheme.primaryContainer
                    else -> Color.Transparent
                }
            )
            .clickable(enabled = day.position == DayPosition.MonthDate) { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = day.date.dayOfMonth.toString(),
                style = MaterialTheme.typography.bodyMedium,
                color = when {
                    isSelected -> MaterialTheme.colorScheme.onPrimary
                    day.position != DayPosition.MonthDate -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                    else -> MaterialTheme.colorScheme.onSurface
                }
            )

            if (hasShift && day.position == DayPosition.MonthDate) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .clip(CircleShape)
                        .background(
                            color = when {
                                earnings >= 500 -> MaterialTheme.colorScheme.tertiary
                                earnings >= 300 -> MaterialTheme.colorScheme.primary
                                else -> MaterialTheme.colorScheme.secondary
                            }
                        )
                )
            }
        }
    }
}

@Composable
fun MonthHeader(daysOfWeek: List<DayOfWeek>) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 8.dp)
    ) {
        for (dayOfWeek in daysOfWeek) {
            Text(
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Center,
                text = dayOfWeek.getDisplayName(JavaTextStyle.SHORT, Locale.getDefault()),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun SelectedDateHeader(
    date: LocalDate,
    totalEarnings: Double
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = date.format(DateTimeFormatter.ofPattern("EEEE, MMMM d")),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                if (totalEarnings > 0) {
                    Text(
                        text = "Total: ${formatCurrency(totalEarnings)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShiftCard(
    shift: Shift,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Schedule,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${shift.startTime ?: "?"} - ${shift.endTime ?: "?"}",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "${shift.hours}h",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Row(
                    modifier = Modifier.padding(top = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (shift.sales > 0) {
                        Text(
                            text = "Sales: ${formatCurrency(shift.sales)}",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                    if (shift.tips > 0) {
                        Text(
                            text = "Tips: ${formatCurrency(shift.tips)}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = formatCurrency(shift.totalEarnings),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                if (shift.tipPercentage > 0) {
                    Text(
                        text = "${shift.tipPercentage.format(1)}%",
                        style = MaterialTheme.typography.bodySmall,
                        color = when {
                            shift.tipPercentage >= 20 -> MaterialTheme.colorScheme.tertiary
                            shift.tipPercentage >= 15 -> MaterialTheme.colorScheme.primary
                            else -> MaterialTheme.colorScheme.error
                        }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EntryCard(
    entry: Entry,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.AttachMoney,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Quick Entry",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                Row(
                    modifier = Modifier.padding(top = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (entry.sales > 0) {
                        Text(
                            text = "Sales: ${formatCurrency(entry.sales)}",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                    if (entry.tips > 0) {
                        Text(
                            text = "Tips: ${formatCurrency(entry.tips)}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = formatCurrency(entry.totalEarnings),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                if (entry.tipPercentage > 0) {
                    Text(
                        text = "${entry.tipPercentage.format(1)}%",
                        style = MaterialTheme.typography.bodySmall,
                        color = when {
                            entry.tipPercentage >= 20 -> MaterialTheme.colorScheme.tertiary
                            entry.tipPercentage >= 15 -> MaterialTheme.colorScheme.primary
                            else -> MaterialTheme.colorScheme.error
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun EmptyDateCard(
    date: LocalDate,
    onAddShift: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                Icons.Default.EventBusy,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "No shifts or entries",
                style = MaterialTheme.typography.bodyLarge
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onAddShift) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Add Shift")
            }
        }
    }
}

private fun formatCurrency(amount: Double): String {
    return NumberFormat.getCurrencyInstance(Locale.US).format(amount)
}

private fun Double.format(decimals: Int) = "%.${decimals}f".format(this)

// Extensions for models (temporary until proper models are updated)
private val Shift.employerName: String?
    get() = null // TODO: Implement proper employer name from employer ID

private val Shift.totalEarnings: Double
    get() = (hourlyRate ?: 0.0) * hours + tips + other - cashOut

private val Entry.totalEarnings: Double
    get() = tips + other - cashOut