package com.protip365.app.presentation.shifts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.ExpectedShift
import com.protip365.app.data.models.Employer
import com.protip365.app.domain.repository.CompletedShiftRepository
import com.protip365.app.domain.repository.ExpectedShiftRepository
import com.protip365.app.domain.repository.UserRepository
import com.protip365.app.domain.repository.EmployerRepository
import com.protip365.app.presentation.notifications.ShiftAlertNotificationManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.datetime.*
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AddEditShiftViewModel @Inject constructor(
    private val completedShiftRepository: CompletedShiftRepository,
    private val expectedShiftRepository: ExpectedShiftRepository,
    private val userRepository: UserRepository,
    private val employerRepository: EmployerRepository,
    private val notificationManager: ShiftAlertNotificationManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(AddEditShiftUiState())
    val uiState: StateFlow<AddEditShiftUiState> = _uiState.asStateFlow()

    private var editingShiftId: String? = null

    init {
        loadEmployers()
        loadUserDefaults()
    }

    fun loadEmployers() {
        viewModelScope.launch {
            try {
                val currentUser = userRepository.getCurrentUser().first()
                val userId = currentUser?.userId ?: return@launch

                val employers = employerRepository.getEmployers(userId)
                _uiState.update { state ->
                    state.copy(
                        employerList = employers,
                        isInitializing = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update { state ->
                    state.copy(
                        employerList = emptyList(),
                        isInitializing = false,
                        errorMessage = "Could not load employers: ${e.message}"
                    )
                }
            }
        }
    }

    private fun loadUserDefaults() {
        viewModelScope.launch {
            try {
                val currentUser = userRepository.getCurrentUser().first()
                val userId = currentUser?.userId ?: return@launch

                userRepository.getUserProfile(userId)?.let { profile ->
                    // Only update alert minutes if not editing an existing shift
                    if (editingShiftId == null) {
                        _uiState.update { state ->
                            state.copy(
                                alertMinutes = profile.defaultAlertMinutes,
                                averageDeductionPercentage = profile.averageDeductionPercentage,
                                defaultSalesTarget = profile.targetSalesDaily ?: 0.0
                            )
                        }
                    } else {
                        // For editing, only update default sales target and deduction percentage
                        _uiState.update { state ->
                            state.copy(
                                averageDeductionPercentage = profile.averageDeductionPercentage,
                                defaultSalesTarget = profile.targetSalesDaily ?: 0.0
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                // Silently fail - defaults are optional
            }
        }
    }

    fun loadShift(shiftId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isInitializing = true) }

            try {
                editingShiftId = shiftId

                val completedShift = completedShiftRepository.getCompletedShift(shiftId)
                if (completedShift == null) {
                    _uiState.update { state ->
                        state.copy(
                            isInitializing = false,
                            errorMessage = "Shift not found"
                        )
                    }
                    return@launch
                }

                val expectedShift = completedShift.expectedShift
                val shiftDate = LocalDate.parse(expectedShift.shiftDate)
                val startTime = LocalTime.parse(expectedShift.startTime)
                val endTime = LocalTime.parse(expectedShift.endTime)

                // Determine end date (cross-day detection)
                val endDate = if (endTime < startTime) {
                    shiftDate.plus(1, DateTimeUnit.DAY)
                } else {
                    shiftDate
                }

                _uiState.update { state ->
                    state.copy(
                        selectedEmployer = completedShift.employer,
                        selectedDate = shiftDate,
                        endDate = endDate,
                        startTime = startTime,
                        endTime = endTime,
                        lunchBreak = expectedShift.lunchBreakMinutes ?: 0,
                        alertMinutes = expectedShift.alertMinutes,
                        comments = expectedShift.notes ?: "",
                        salesTarget = expectedShift.salesTarget?.let {
                            String.format("%.0f", it)
                        } ?: "",
                        isInitializing = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update { state ->
                    state.copy(
                        isInitializing = false,
                        errorMessage = "Failed to load shift: ${e.message}\n${e.stackTraceToString()}"
                    )
                }
            }
        }
    }

    fun updateEmployer(employer: Employer?) {
        _uiState.update { it.copy(selectedEmployer = employer) }
    }

    fun updateDate(date: LocalDate) {
        // Validate date is not in the past for new shifts
        if (editingShiftId == null) {
            val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
            if (date < today) {
                _uiState.update { it.copy(errorMessage = "Cannot select past dates for new shifts") }
                return
            }
        }

        // AUTO-SYNC: If end date is on a different day, update it to match start date
        // (User can still manually change for overnight shifts)
        val currentEndDate = _uiState.value.endDate
        if (currentEndDate != null && currentEndDate != date) {
            _uiState.update { it.copy(selectedDate = date, endDate = date) }
        } else if (currentEndDate == null) {
            // If no end date set yet, default it to same as start date
            _uiState.update { it.copy(selectedDate = date, endDate = date) }
        } else {
            _uiState.update { it.copy(selectedDate = date) }
        }
    }

    fun updateEndDate(date: LocalDate?) {
        // Validate end date is not in the past for new shifts
        if (editingShiftId == null && date != null) {
            val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
            if (date < today) {
                _uiState.update { it.copy(errorMessage = "Cannot select past dates for new shifts") }
                return
            }
        }

        // Validate end date is not before start date
        if (date != null && date < _uiState.value.selectedDate) {
            _uiState.update { it.copy(errorMessage = "End date cannot be before start date") }
            return
        }

        _uiState.update { it.copy(endDate = date) }
    }

    fun updateStartTime(time: LocalTime) {
        _uiState.update { it.copy(startTime = time) }
    }

    fun updateEndTime(time: LocalTime) {
        val state = _uiState.value

        // If dates are the same and end time is before start time, automatically set end date to next day
        if (state.endDate == null || state.endDate == state.selectedDate) {
            if (time < state.startTime) {
                // This is an overnight shift - automatically set end date to next day
                val nextDay = state.selectedDate.plus(1, DateTimeUnit.DAY)
                _uiState.update { it.copy(endTime = time, endDate = nextDay) }
                return
            }
        }

        _uiState.update { it.copy(endTime = time) }
    }

    fun updateLunchBreak(minutes: Int) {
        _uiState.update { it.copy(lunchBreak = minutes) }
    }

    fun updateAlertMinutes(minutes: Int?) {
        _uiState.update { it.copy(alertMinutes = minutes) }
    }

    fun updateComments(comments: String) {
        _uiState.update { it.copy(comments = comments) }
    }

    fun updateSalesTarget(target: String) {
        _uiState.update { it.copy(salesTarget = target) }
    }

    fun saveShift(onSuccess: () -> Unit) {
        val state = _uiState.value

        // Validation
        if (state.selectedEmployer == null) {
            _uiState.update { it.copy(errorMessage = "Please select an employer") }
            return
        }


        // Allow past dates for shift creation

        // Validate end date/time
        val effectiveEndDate = state.endDate ?: state.selectedDate
        val startDateTime = state.selectedDate.atTime(state.startTime)
        val endDateTime = effectiveEndDate.atTime(state.endTime)

        // Check if end is before start
        if (endDateTime <= startDateTime) {
            _uiState.update { it.copy(errorMessage = "End time must be after start time. For overnight shifts, the end date will be automatically set to the next day.") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            try {
                val currentUser = userRepository.getCurrentUser().first()
                val userId = currentUser?.userId ?: throw Exception("User not found")

                val shiftId = editingShiftId ?: UUID.randomUUID().toString()

                // Determine actual end date (handle overnight shifts)
                val actualEndDate = if (state.endDate != null) {
                    state.endDate
                } else if (state.endTime < state.startTime) {
                    // Overnight shift - end date is next day
                    state.selectedDate.plus(1, DateTimeUnit.DAY)
                } else {
                    state.selectedDate
                }

                // Check for overlapping shifts
                val overlappingShifts = expectedShiftRepository.getOverlappingShifts(
                    userId = userId,
                    startDate = state.selectedDate.toString(),
                    startTime = state.startTime.toString(),
                    endDate = actualEndDate.toString(),
                    endTime = state.endTime.toString(),
                    excludeShiftId = editingShiftId
                )

                if (overlappingShifts.isNotEmpty()) {
                    val firstOverlap = overlappingShifts.first()
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = "This shift overlaps with an existing shift on ${firstOverlap.shiftDate} from ${firstOverlap.startTime} to ${firstOverlap.endTime}. Please choose a different time."
                        )
                    }
                    return@launch
                }

                // Calculate expected hours (excluding lunch break)
                val startDateTime = state.selectedDate.atTime(state.startTime)
                val endDateTime = actualEndDate.atTime(state.endTime)
                // Calculate duration in minutes
                val startInstant = startDateTime.toInstant(TimeZone.currentSystemDefault())
                val endInstant = endDateTime.toInstant(TimeZone.currentSystemDefault())
                val totalMinutes = (endInstant - startInstant).inWholeMinutes.toInt()

                val lunchBreakMinutes = if (state.lunchBreak > 0) state.lunchBreak else 0
                val expectedHours = maxOf(0.0, (totalMinutes - lunchBreakMinutes) / 60.0)

                // Determine status: preserve existing for edits, calculate for new shifts
                val shiftStatus = if (editingShiftId != null) {
                    // Editing existing shift - PRESERVE existing status
                    val existingShift = completedShiftRepository.getCompletedShift(editingShiftId!!)
                    existingShift?.expectedShift?.status ?: "planned"
                } else {
                    // Creating new shift - calculate status based on DATE ONLY (not time)
                    // Today's shifts are "planned" even if start time has passed
                    val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
                    val shiftDate = state.selectedDate
                    if (shiftDate >= today) "planned" else "completed"
                }

                // Parse custom sales target (empty string means use default)
                val customSalesTarget = if (state.salesTarget.isEmpty()) {
                    null
                } else {
                    state.salesTarget.toDoubleOrNull()
                }

                val expectedShift = ExpectedShift(
                    id = shiftId,
                    userId = userId,
                    employerId = state.selectedEmployer?.id ?: "",
                    shiftDate = state.selectedDate.toString(),
                    startTime = state.startTime.toString(),
                    endTime = state.endTime.toString(),
                    expectedHours = expectedHours,
                    hourlyRate = state.selectedEmployer?.hourlyRate ?: 15.0,
                    lunchBreakMinutes = if (state.lunchBreak > 0) state.lunchBreak else 0,
                    salesTarget = customSalesTarget,
                    status = shiftStatus,
                    alertMinutes = state.alertMinutes,
                    notes = state.comments.ifEmpty { null }
                )

                if (editingShiftId != null) {
                    // Get the existing completed shift to preserve entry data
                    val existingShift = completedShiftRepository.getCompletedShift(editingShiftId!!)
                    val updatedCompletedShift = existingShift?.copy(expectedShift = expectedShift)
                        ?: throw Exception("Shift not found")

                    completedShiftRepository.updateShift(updatedCompletedShift).getOrThrow()

                    // Update notification if alert changed
                    state.alertMinutes?.let { minutes ->
                        notificationManager.scheduleShiftAlert(
                            shiftId = shiftId,
                            shiftDate = state.selectedDate,
                            startTime = state.startTime,
                            employerName = state.selectedEmployer!!.name,
                            alertMinutes = minutes
                        )
                    } ?: run {
                        // Cancel notification if alert removed
                        notificationManager.cancelShiftAlert(shiftId)
                    }
                } else {
                    completedShiftRepository.createShift(expectedShift, null).getOrThrow()

                    // Schedule notification if alert is set
                    state.alertMinutes?.let { minutes ->
                        notificationManager.scheduleShiftAlert(
                            shiftId = shiftId,
                            shiftDate = state.selectedDate,
                            startTime = state.startTime,
                            employerName = state.selectedEmployer!!.name,
                            alertMinutes = minutes
                        )
                    }
                }

                _uiState.update { it.copy(isLoading = false) }
                onSuccess()

            } catch (e: Exception) {
                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        errorMessage = "Failed to save shift: ${e.message}"
                    )
                }
            }
        }
    }

    fun deleteShift(onSuccess: () -> Unit) {
        editingShiftId?.let { shiftId ->
            viewModelScope.launch {
                _uiState.update { it.copy(isLoading = true) }

                try {
                    completedShiftRepository.deleteShift(shiftId).getOrThrow()

                    // Cancel any notifications
                    notificationManager.cancelShiftAlert(shiftId)

                    _uiState.update { it.copy(isLoading = false) }
                    onSuccess()

                } catch (e: Exception) {
                    _uiState.update { state ->
                        state.copy(
                            isLoading = false,
                            errorMessage = "Failed to delete shift: ${e.message}"
                        )
                    }
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}

data class AddEditShiftUiState(
    val selectedEmployer: Employer? = null,
    val employerList: List<Employer> = emptyList(),
    val selectedDate: LocalDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date,
    val endDate: LocalDate? = null, // For cross-day shifts
    val startTime: LocalTime = LocalTime(9, 0),
    val endTime: LocalTime = LocalTime(17, 0),
    val lunchBreak: Int = 0,
    val alertMinutes: Int? = null,
    val comments: String = "",
    val salesTarget: String = "", // Empty string means use default target
    val defaultSalesTarget: Double = 0.0, // Default from user settings
    val averageDeductionPercentage: Double = 30.0, // From settings
    val isInitializing: Boolean = true,
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)