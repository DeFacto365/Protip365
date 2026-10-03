package com.protip365.app.presentation.entries

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Employer
import com.protip365.app.data.models.CompletedShift
import com.protip365.app.data.models.ShiftEntry
import com.protip365.app.data.models.ExpectedShift
import com.protip365.app.domain.repository.EmployerRepository
import com.protip365.app.domain.repository.CompletedShiftRepository
import com.protip365.app.domain.repository.ShiftEntryRepository
import com.protip365.app.domain.repository.ExpectedShiftRepository
import com.protip365.app.domain.repository.UserRepository
import com.protip365.app.presentation.alerts.AlertManager
import com.protip365.app.domain.repository.SubscriptionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.datetime.*
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AddEditEntryViewModel @Inject constructor(
    private val completedShiftRepository: CompletedShiftRepository,
    private val shiftEntryRepository: ShiftEntryRepository,
    private val expectedShiftRepository: ExpectedShiftRepository,
    private val userRepository: UserRepository,
    private val employerRepository: EmployerRepository,
    private val alertManager: AlertManager,
    private val subscriptionRepository: SubscriptionRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AddEditEntryUiState())
    val uiState: StateFlow<AddEditEntryUiState> = _uiState.asStateFlow()

    private var originalCompletedShift: CompletedShift? = null
    private var originalShiftEntry: ShiftEntry? = null
    private var originalExpectedShift: ExpectedShift? = null
    private var isEditingExistingEntry = false

    init {
        viewModelScope.launch {
            // Load user profile to get default hourly rate and sales budget
            userRepository.getCurrentUser().collect { user ->
                user?.let { currentUser ->
                    val profile = userRepository.getUserProfile(currentUser.userId)
                    _uiState.value = _uiState.value.copy(
                        defaultHourlyRate = profile?.defaultHourlyRate ?: 15.0,
                        deductionPercentage = profile?.averageDeductionPercentage ?: 30.0,
                        salesBudget = profile?.targetSalesDaily ?: 0.0
                    )
                }
            }
        }
    }

    fun loadEntry(entryId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isInitializing = true)
            try {
                // Load completed shift data (combines ExpectedShift + ShiftEntry)
                val completedShift = completedShiftRepository.getCompletedShift(entryId)
                if (completedShift != null) {
                    originalCompletedShift = completedShift
                    originalShiftEntry = completedShift.shiftEntry
                    originalExpectedShift = completedShift.expectedShift
                    isEditingExistingEntry = completedShift.shiftEntry != null
                    populateFromCompletedShift(completedShift)
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = "Failed to load entry: ${e.message}",
                    isInitializing = false
                )
            }
        }
    }

    fun loadShift(shiftId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isInitializing = true)
            try {
                // Load expected shift data to pre-populate entry
                val completedShift = completedShiftRepository.getCompletedShift(shiftId)
                if (completedShift != null) {
                    originalCompletedShift = completedShift
                    originalShiftEntry = completedShift.shiftEntry
                    originalExpectedShift = completedShift.expectedShift
                    isEditingExistingEntry = false // We're creating a new entry from an expected shift
                    populateFromCompletedShift(completedShift)
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = "Failed to load shift: ${e.message}",
                    isInitializing = false
                )
            }
        }
    }

    fun loadEmployers() {
        viewModelScope.launch {
            try {
                val userId = userRepository.getCurrentUserId() ?: return@launch
                val employers = employerRepository.getEmployers(userId)
                val activeEmployers = employers.filter { it.active }
                _uiState.value = _uiState.value.copy(
                    employers = activeEmployers,
                    selectedEmployer = activeEmployers.firstOrNull(),
                    isInitializing = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = "Failed to load employers: ${e.message}",
                    isInitializing = false
                )
            }
        }
    }

    private fun populateFromCompletedShift(completedShift: CompletedShift) {
        val expectedShift = completedShift.expectedShift
        val shiftEntry = completedShift.shiftEntry

        val date = LocalDate.parse(expectedShift.shiftDate)
        val startTime = parseTime(shiftEntry?.actualStartTime ?: expectedShift.startTime)
        val endTime = parseTime(shiftEntry?.actualEndTime ?: expectedShift.endTime)

        _uiState.value = _uiState.value.copy(
            selectedDate = date,
            startTime = startTime,
            endTime = endTime,
            lunchBreak = expectedShift.lunchBreakMinutes,
            sales = shiftEntry?.sales?.toString() ?: "",
            tips = shiftEntry?.tips?.toString() ?: "",
            tipOut = shiftEntry?.cashOut?.toString() ?: "",
            other = shiftEntry?.other?.toString() ?: "",
            comments = shiftEntry?.notes ?: expectedShift.notes ?: "",
            didntWork = expectedShift.status == "missed",
            missedReason = if (expectedShift.status == "missed") expectedShift.notes ?: "" else "",
            selectedEmployer = completedShift.employer,
            isInitializing = false
        )

        // Calculate if end date is different (overnight shift)
        val endDateTime = parseDateTime(expectedShift.shiftDate, endTime.toString())
        val startDateTime = parseDateTime(expectedShift.shiftDate, startTime.toString())
        if (endDateTime < startDateTime) {
            // Overnight shift
            val endDate = date.plus(1, DateTimeUnit.DAY)
            _uiState.value = _uiState.value.copy(endDate = endDate)
        }

        // Recalculate hours
        recalculateHours()
    }


    fun updateDate(date: LocalDate) {
        // Validate date is not in the future
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        if (date > today) {
            _uiState.value = _uiState.value.copy(errorMessage = "Cannot add entries for future dates")
            return
        }
        _uiState.value = _uiState.value.copy(selectedDate = date)
        recalculateHours()
    }

    fun updateEndDate(date: LocalDate?) {
        // Validate end date is not in the future
        if (date != null) {
            val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
            if (date > today) {
                _uiState.value = _uiState.value.copy(errorMessage = "Cannot add entries for future dates")
                return
            }
        }
        _uiState.value = _uiState.value.copy(endDate = date)
        recalculateHours()
    }

    fun updateStartTime(time: LocalTime) {
        _uiState.value = _uiState.value.copy(startTime = time)
        recalculateHours()
    }

    fun updateEndTime(time: LocalTime) {
        _uiState.value = _uiState.value.copy(endTime = time)
        recalculateHours()
    }

    fun updateLunchBreak(minutes: Int) {
        _uiState.value = _uiState.value.copy(lunchBreak = minutes)
        recalculateHours()
    }

    fun updateEmployer(employer: Employer) {
        _uiState.value = _uiState.value.copy(selectedEmployer = employer)
    }

    fun updateDidntWork(didntWork: Boolean) {
        _uiState.value = _uiState.value.copy(
            didntWork = didntWork,
            missedReason = if (!didntWork) "" else _uiState.value.missedReason
        )
        if (didntWork) {
            _uiState.value = _uiState.value.copy(calculatedHours = 0.0)
        } else {
            recalculateHours()
        }
    }

    fun updateMissedReason(reason: String) {
        _uiState.value = _uiState.value.copy(missedReason = reason)
    }

    fun updateSales(sales: String) {
        _uiState.value = _uiState.value.copy(sales = sales)
    }

    fun updateTips(tips: String) {
        _uiState.value = _uiState.value.copy(tips = tips)
    }

    fun updateTipOut(tipOut: String) {
        _uiState.value = _uiState.value.copy(tipOut = tipOut)
    }

    fun updateOther(other: String) {
        _uiState.value = _uiState.value.copy(other = other)
    }

    fun updateComments(comments: String) {
        _uiState.value = _uiState.value.copy(comments = comments)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    private fun recalculateHours() {
        if (_uiState.value.didntWork) {
            _uiState.value = _uiState.value.copy(calculatedHours = 0.0)
            return
        }

        val state = _uiState.value
        val startDateTime = state.selectedDate.atTime(state.startTime)
        val endDate = state.endDate ?: state.selectedDate
        val endDateTime = endDate.atTime(state.endTime)

        val duration = endDateTime.toInstant(TimeZone.currentSystemDefault()) -
                      startDateTime.toInstant(TimeZone.currentSystemDefault())
        val hoursWorked = duration.inWholeMinutes / 60.0
        val netHours = hoursWorked - (state.lunchBreak / 60.0)

        _uiState.value = _uiState.value.copy(
            calculatedHours = maxOf(0.0, netHours)
        )
    }

    fun calculateTotalEarnings(): Double {
        val state = _uiState.value
        val tipsAmount = state.tips.toDoubleOrNull() ?: 0.0
        val tipOutAmount = state.tipOut.toDoubleOrNull() ?: 0.0
        val otherAmount = state.other.toDoubleOrNull() ?: 0.0
        val hourlyRate = state.selectedEmployer?.hourlyRate ?: state.defaultHourlyRate
        val salary = state.calculatedHours * hourlyRate
        return salary + tipsAmount + otherAmount - tipOutAmount
    }

    fun saveEntry(onSuccess: () -> Unit) {
        viewModelScope.launch {
            val state = _uiState.value

            // Validation
            if (state.selectedEmployer == null && !state.didntWork) {
                _uiState.value = state.copy(errorMessage = "Please select an employer")
                return@launch
            }

            // Check if date is in the future
            val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
            if (state.selectedDate > today) {
                _uiState.value = state.copy(errorMessage = "Cannot add entries for future dates. Please select today or a past date.")
                return@launch
            }

            // Also check end date if it exists
            if (state.endDate != null && state.endDate > today) {
                _uiState.value = state.copy(errorMessage = "End date cannot be in the future. Please select today or a past date.")
                return@launch
            }

            // Check subscription limits
            if (!state.didntWork && !isEditingExistingEntry) {
                val canAddEntry = true // For now, allow all entries
                if (!canAddEntry) {
                    _uiState.value = state.copy(
                        errorMessage = "You've reached your weekly entry limit. Upgrade to add more entries."
                    )
                    return@launch
                }
            }

            _uiState.value = state.copy(isLoading = true)

            try {
                val userId = userRepository.getCurrentUserId() ?: throw Exception("User not authenticated")
                val shiftDate = state.selectedDate.toString()
                val startTimeStr = formatTime(state.startTime)
                val endTimeStr = formatTime(state.endTime)

                // Determine shift ID - either from original expected shift or need to create new
                val shiftId: String = originalExpectedShift?.id ?: run {
                    // Create new expected shift if needed
                    val newExpectedShift = ExpectedShift(
                        id = UUID.randomUUID().toString(),
                        userId = userId,
                        employerId = state.selectedEmployer?.id,
                        shiftDate = shiftDate,
                        startTime = startTimeStr,
                        endTime = endTimeStr,
                        expectedHours = state.calculatedHours,
                        hourlyRate = state.selectedEmployer?.hourlyRate ?: state.defaultHourlyRate,
                        lunchBreakMinutes = state.lunchBreak,
                        status = if (state.didntWork) "missed" else "completed",
                        notes = if (state.didntWork) state.missedReason else state.comments,
                        alertMinutes = null,
                        createdAt = Clock.System.now().toString(),
                        updatedAt = Clock.System.now().toString()
                    )
                    expectedShiftRepository.createExpectedShift(newExpectedShift)
                    newExpectedShift.id
                }

                // Update expected shift status if completing a planned shift
                if (originalExpectedShift != null && originalExpectedShift!!.status == "planned") {
                    expectedShiftRepository.updateShiftStatus(
                        shiftId = shiftId,
                        status = if (state.didntWork) "missed" else "completed"
                    )
                }

                if (!state.didntWork) {
                    // Save or update shift entry
                    val shiftEntry = ShiftEntry(
                        id = originalShiftEntry?.id ?: UUID.randomUUID().toString(),
                        shiftId = shiftId,
                        userId = userId,
                        actualStartTime = startTimeStr,
                        actualEndTime = endTimeStr,
                        actualHours = state.calculatedHours,
                        sales = state.sales.toDoubleOrNull() ?: 0.0,
                        tips = state.tips.toDoubleOrNull() ?: 0.0,
                        cashOut = state.tipOut.toDoubleOrNull() ?: 0.0,
                        other = state.other.toDoubleOrNull() ?: 0.0,
                        notes = state.comments,
                        createdAt = originalShiftEntry?.createdAt ?: Clock.System.now().toString(),
                        updatedAt = Clock.System.now().toString()
                    )

                    // Get hourly rate and deduction percentage for snapshot
                    val hourlyRate = state.selectedEmployer?.hourlyRate ?: state.defaultHourlyRate
                    val deductionPct = state.deductionPercentage

                    if (originalShiftEntry != null) {
                        // Update existing entry with snapshots
                        shiftEntryRepository.updateShiftEntryWithSnapshots(
                            shiftEntry,
                            hourlyRate,
                            deductionPct
                        )
                    } else {
                        // Create new entry with snapshots
                        shiftEntryRepository.createShiftEntryWithSnapshots(
                            shiftEntry,
                            hourlyRate,
                            deductionPct
                        )
                    }

                    // Track entry for subscription limits (implemented later)
                }

                // Update alert status if this was from a notification
                // Note: alertManager.markShiftCompleted method may need to be updated
                // alertManager.markShiftCompleted(shiftId)

                _uiState.value = state.copy(isLoading = false)
                onSuccess()

            } catch (e: Exception) {
                _uiState.value = state.copy(
                    isLoading = false,
                    errorMessage = "Failed to save entry: ${e.message}"
                )
            }
        }
    }

    fun deleteEntry(onSuccess: () -> Unit) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            try {
                originalShiftEntry?.let { entry ->
                    shiftEntryRepository.deleteShiftEntry(entry.id)
                }

                // Update expected shift status back to planned if in the future
                originalExpectedShift?.let { expectedShift ->
                    val shiftDate = LocalDate.parse(expectedShift.shiftDate)
                    val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
                    if (shiftDate > today) {
                        expectedShiftRepository.updateShiftStatus(expectedShift.id, "planned")
                    }
                }

                _uiState.value = _uiState.value.copy(isLoading = false)
                onSuccess()

            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Failed to delete entry: ${e.message}"
                )
            }
        }
    }

    private fun parseTime(timeString: String): LocalTime {
        val parts = timeString.split(":")
        return LocalTime(parts[0].toInt(), parts.getOrElse(1) { "0" }.toInt())
    }

    private fun formatTime(time: LocalTime): String {
        return "${time.hour.toString().padStart(2, '0')}:${time.minute.toString().padStart(2, '0')}"
    }

    private fun parseDateTime(dateStr: String, timeStr: String): Instant {
        val date = LocalDate.parse(dateStr)
        val time = if (timeStr.contains(":")) parseTime(timeStr) else LocalTime.parse(timeStr)
        return date.atTime(time).toInstant(TimeZone.currentSystemDefault())
    }
}

data class AddEditEntryUiState(
    // Date and time
    val selectedDate: LocalDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date,
    val endDate: LocalDate? = null, // For overnight shifts
    val startTime: LocalTime = LocalTime(9, 0),
    val endTime: LocalTime = LocalTime(17, 0),
    val lunchBreak: Int = 0, // in minutes

    // Work info
    val selectedEmployer: Employer? = null,
    val employers: List<Employer> = emptyList(),
    val didntWork: Boolean = false,
    val missedReason: String = "",

    // Earnings
    val sales: String = "",
    val tips: String = "",
    val tipOut: String = "",
    val other: String = "",
    val comments: String = "",

    // Calculated
    val calculatedHours: Double = 8.0,
    val defaultHourlyRate: Double = 15.0,
    val deductionPercentage: Double = 30.0, // Average deduction % from user profile
    val salesBudget: Double = 0.0, // Daily sales target from user profile

    // UI state
    val isInitializing: Boolean = false,
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)