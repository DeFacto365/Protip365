package com.protip365.app.presentation.shifts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Employer
import com.protip365.app.data.models.Entry
import com.protip365.app.data.models.Shift
import com.protip365.app.domain.repository.*
import com.protip365.app.presentation.notifications.ShiftAlertNotificationManager
import com.protip365.app.presentation.localization.LocalizationManager
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
    private val subscriptionRepository: SubscriptionRepository,
    private val userRepository: UserRepository,
    private val notificationManager: ShiftAlertNotificationManager,
    private val localizationManager: LocalizationManager
) : ViewModel() {

    private val _state = MutableStateFlow(AddShiftState())
    val state: StateFlow<AddShiftState> = _state.asStateFlow()

    private val _employers = MutableStateFlow<List<Employer>>(emptyList())
    val employers: StateFlow<List<Employer>> = _employers.asStateFlow()

    private val _selectedAlert = MutableStateFlow("60")
    val selectedAlert: StateFlow<String> = _selectedAlert.asStateFlow()

    private val _defaultAlertMinutes = MutableStateFlow(60)

    private var currentShiftId: String? = null
    private var currentUserId: String? = null

    init {
        loadEmployers()
        loadUserDefaults()
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

    private fun loadUserDefaults() {
        viewModelScope.launch {
            try {
                val user = authRepository.getCurrentUser()
                user?.let { currentUser ->
                    val profile = userRepository.getUserProfile(currentUser.userId)
                    profile?.defaultAlertMinutes?.let { minutes ->
                        _defaultAlertMinutes.value = minutes
                        _selectedAlert.value = minutes.toString()
                    }
                }
            } catch (e: Exception) {
                // Handle error silently, use default values
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
                    error = localizationManager.getString("error_shift_not_found")
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
        employerId: String?,
        alertMinutes: Int? = null
    ) {
        viewModelScope.launch {
            if (!_state.value.canAddShift && currentShiftId == null) {
                _state.value = _state.value.copy(
                    error = localizationManager.getString("error_shift_limit_reached")
                )
                return@launch
            }

            _state.value = _state.value.copy(isLoading = true, error = null)

            val userId = currentUserId ?: run {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = localizationManager.getString("error_user_not_logged_in")
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
                employerId = employerId,
                alertMinutes = alertMinutes ?: when(selectedAlert.value) {
                    "None" -> null
                    else -> selectedAlert.value.toIntOrNull()
                }
            )

            val result = if (currentShiftId != null) {
                shiftRepository.updateShift(shift)
            } else {
                shiftRepository.createShift(shift)
            }

            result.fold(
                onSuccess = { savedShift ->
                    // Schedule notification if alert is set
                    val finalAlertMinutes = alertMinutes ?: when(selectedAlert.value) {
                        "None" -> null
                        else -> selectedAlert.value.toIntOrNull()
                    }
                    
                    finalAlertMinutes?.let { minutes ->
                        savedShift.id?.let { shiftId ->
                            try {
                                val employerName = _employers.value.find { it.id == employerId }?.name ?: localizationManager.getString("default_employer_name")
                                notificationManager.scheduleShiftAlert(
                                    shiftId = shiftId,
                                    shiftDate = date,
                                    startTime = kotlinx.datetime.LocalTime.parse(startTime),
                                    employerName = employerName,
                                    alertMinutes = minutes
                                )
                            } catch (e: Exception) {
                                // Handle notification scheduling error silently
                            }
                        }
                    }
                    
                    _state.value = _state.value.copy(
                        isLoading = false,
                        isSaved = true
                    )
                },
                onFailure = { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message ?: localizationManager.getString("error_failed_to_save_shift")
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
                    error = localizationManager.getString("error_entry_limit_reached")
                )
                return@launch
            }

            _state.value = _state.value.copy(isLoading = true, error = null)

            val userId = currentUserId ?: run {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = localizationManager.getString("error_user_not_logged_in")
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
                        error = exception.message ?: localizationManager.getString("error_failed_to_save_entry")
                    )
                }
            )
        }
    }

    fun updateSelectedAlert(alert: String) {
        _selectedAlert.value = alert
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
                            error = exception.message ?: localizationManager.getString("error_failed_to_delete_shift")
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