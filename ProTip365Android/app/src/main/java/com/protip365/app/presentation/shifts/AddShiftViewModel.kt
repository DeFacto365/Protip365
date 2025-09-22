package com.protip365.app.presentation.shifts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Employer
import com.protip365.app.data.models.Entry
import com.protip365.app.data.models.Shift
import com.protip365.app.domain.repository.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.LocalDate
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AddShiftViewModel @Inject constructor(
    private val shiftRepository: ShiftRepository,
    private val employerRepository: EmployerRepository,
    private val authRepository: AuthRepository,
    private val subscriptionRepository: SubscriptionRepository
) : ViewModel() {

    private val _state = MutableStateFlow(AddShiftState())
    val state: StateFlow<AddShiftState> = _state.asStateFlow()

    private val _employers = MutableStateFlow<List<Employer>>(emptyList())
    val employers: StateFlow<List<Employer>> = _employers.asStateFlow()

    private var currentShiftId: String? = null
    private var currentUserId: String? = null

    init {
        loadEmployers()
        checkSubscriptionLimits()
    }

    private fun loadEmployers() {
        viewModelScope.launch {
            val user = authRepository.getCurrentUser()
            user?.let {
                currentUserId = it.userId
                if (it.useMultipleEmployers) {
                    val employerList = employerRepository.getEmployers(it.userId)
                    _employers.value = employerList
                }
            }
        }
    }

    private fun checkSubscriptionLimits() {
        viewModelScope.launch {
            currentUserId?.let { userId ->
                val limits = subscriptionRepository.checkWeeklyLimits(userId)
                _state.value = _state.value.copy(
                    canAddShift = limits.canAddShift,
                    canAddEntry = limits.canAddEntry,
                    shiftsUsedThisWeek = limits.shiftsUsed,
                    entriesUsedThisWeek = limits.entriesUsed,
                    weeklyShiftLimit = limits.shiftsLimit,
                    weeklyEntryLimit = limits.entriesLimit
                )
            }
        }
    }

    fun loadShift(shiftId: String) {
        currentShiftId = shiftId
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true)
            val shift = shiftRepository.getShift(shiftId)
            shift?.let {
                _state.value = _state.value.copy(
                    isLoading = false,
                    isEditing = true
                )
            } ?: run {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = "Shift not found"
                )
            }
        }
    }

    fun saveShift(
        date: LocalDate,
        startTime: String,
        endTime: String,
        hours: Double,
        sales: Double,
        tips: Double,
        hourlyRate: Double,
        cashOut: Double,
        other: Double,
        notes: String,
        employerId: String?
    ) {
        viewModelScope.launch {
            if (!_state.value.canAddShift && currentShiftId == null) {
                _state.value = _state.value.copy(
                    error = "You've reached your weekly shift limit. Upgrade to Full Access for unlimited shifts."
                )
                return@launch
            }

            _state.value = _state.value.copy(isLoading = true, error = null)

            val userId = currentUserId ?: run {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = "User not logged in"
                )
                return@launch
            }

            val shift = Shift(
                id = currentShiftId ?: UUID.randomUUID().toString(),
                userId = userId,
                shiftDate = date.toString(),
                startTime = startTime,
                endTime = endTime,
                hours = hours,
                sales = sales,
                tips = tips,
                hourlyRate = hourlyRate,
                cashOut = cashOut,
                other = other,
                notes = notes,
                employerId = employerId
            )

            val result = if (currentShiftId != null) {
                shiftRepository.updateShift(shift)
            } else {
                shiftRepository.createShift(shift)
            }

            result.fold(
                onSuccess = {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        isSaved = true
                    )
                },
                onFailure = { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Failed to save shift"
                    )
                }
            )
        }
    }

    fun saveEntry(
        date: LocalDate,
        sales: Double,
        tips: Double,
        cashOut: Double,
        other: Double,
        notes: String,
        employerId: String?
    ) {
        viewModelScope.launch {
            if (!_state.value.canAddEntry) {
                _state.value = _state.value.copy(
                    error = "You've reached your weekly entry limit. Upgrade to Full Access for unlimited entries."
                )
                return@launch
            }

            _state.value = _state.value.copy(isLoading = true, error = null)

            val userId = currentUserId ?: run {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = "User not logged in"
                )
                return@launch
            }

            val entry = Entry(
                id = UUID.randomUUID().toString(),
                userId = userId,
                entryDate = date.toString(),
                sales = sales,
                tips = tips,
                cashOut = cashOut,
                other = other,
                notes = notes,
                employerId = employerId
            )

            shiftRepository.createEntry(entry).fold(
                onSuccess = {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        isSaved = true
                    )
                },
                onFailure = { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Failed to save entry"
                    )
                }
            )
        }
    }

    fun deleteShift() {
        currentShiftId?.let { id ->
            viewModelScope.launch {
                _state.value = _state.value.copy(isLoading = true)
                shiftRepository.deleteShift(id).fold(
                    onSuccess = {
                        _state.value = _state.value.copy(
                            isLoading = false,
                            isDeleted = true
                        )
                    },
                    onFailure = { exception ->
                        _state.value = _state.value.copy(
                            isLoading = false,
                            error = exception.message ?: "Failed to delete shift"
                        )
                    }
                )
            }
        }
    }
}

data class AddShiftState(
    val isLoading: Boolean = false,
    val isEditing: Boolean = false,
    val isSaved: Boolean = false,
    val isDeleted: Boolean = false,
    val error: String? = null,
    val canAddShift: Boolean = true,
    val canAddEntry: Boolean = true,
    val shiftsUsedThisWeek: Int = 0,
    val entriesUsedThisWeek: Int = 0,
    val weeklyShiftLimit: Int? = null,
    val weeklyEntryLimit: Int? = null
)