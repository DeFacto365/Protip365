package com.protip365.app.presentation.shifts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Employer
import com.protip365.app.data.models.ExpectedShift
import com.protip365.app.data.models.ShiftEntry
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
    private val expectedShiftRepository: ExpectedShiftRepository,
    private val shiftEntryRepository: ShiftEntryRepository,
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

    private val _selectedEmployerId = MutableStateFlow<String?>(null)
    val selectedEmployerId: StateFlow<String?> = _selectedEmployerId.asStateFlow()

    private val _hourlyRate = MutableStateFlow("15.00")
    val hourlyRate: StateFlow<String> = _hourlyRate.asStateFlow()

    private val _selectedAlert = MutableStateFlow("60")
    val selectedAlert: StateFlow<String> = _selectedAlert.asStateFlow()

    private val _defaultAlertMinutes = MutableStateFlow(60)

    private var currentShiftId: String? = null
    private var currentUserId: String? = null

    init {
        viewModelScope.launch {
            loadEmployersAndDefaults()
            checkSubscriptionLimits()
        }
    }

    private suspend fun loadEmployersAndDefaults() {
        try {
            val user = authRepository.getCurrentUser()
            user?.let { currentUser ->
                currentUserId = currentUser.userId

                // Load employers first if using multiple employers
                if (currentUser.useMultipleEmployers) {
                    val employerList = employerRepository.getEmployers(currentUser.userId)
                    _employers.value = employerList
                }

                // Now load user defaults
                val profile = userRepository.getUserProfile(currentUser.userId)

                // Set default alert minutes
                profile?.defaultAlertMinutes?.let { minutes ->
                    _defaultAlertMinutes.value = minutes
                    _selectedAlert.value = minutes.toString()
                }

                // Set default employer and hourly rate
                profile?.defaultEmployerId?.let { employerId ->
                    _selectedEmployerId.value = employerId
                    // Find employer and set their hourly rate
                    _employers.value.find { it.id == employerId }?.let { employer ->
                        _hourlyRate.value = employer.hourlyRate.toString()
                        println("🔵 Auto-selected default employer: ${employer.name} @ $${employer.hourlyRate}/hr")
                    }
                }

                // Set default hourly rate if no employer selected
                if (_selectedEmployerId.value == null) {
                    profile?.defaultHourlyRate?.let { rate ->
                        _hourlyRate.value = rate.toString()
                        println("🔵 Using default hourly rate: $${rate}/hr")
                    }
                }
            }
        } catch (e: Exception) {
            println("❌ Error loading employer/user defaults: ${e.message}")
            e.printStackTrace()
        }
    }

    fun selectEmployer(employerId: String?) {
        _selectedEmployerId.value = employerId
        // Update hourly rate when employer changes
        employerId?.let { id ->
            _employers.value.find { it.id == id }?.let { employer ->
                _hourlyRate.value = employer.hourlyRate.toString()
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
            val shift = expectedShiftRepository.getExpectedShift(shiftId)
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

            val shift = ExpectedShift(
                id = currentShiftId ?: UUID.randomUUID().toString(),
                userId = userId,
                shiftDate = date.toString(),
                startTime = startTime,
                endTime = endTime,
                expectedHours = hours,
                hourlyRate = hourlyRate,
                employerId = employerId,
                alertMinutes = alertMinutes ?: when(selectedAlert.value) {
                    "None" -> null
                    else -> selectedAlert.value.toIntOrNull()
                },
                notes = notes
            )

            val result = if (currentShiftId != null) {
                expectedShiftRepository.updateExpectedShift(shift)
            } else {
                expectedShiftRepository.createExpectedShift(shift)
            }

            result.fold(
                onSuccess = { savedShift: ExpectedShift ->
                    // Schedule notification if alert is set
                    val finalAlertMinutes = alertMinutes ?: when(selectedAlert.value) {
                        "None" -> null
                        else -> selectedAlert.value.toIntOrNull()
                    }

                    finalAlertMinutes?.let { minutes ->
                        try {
                            val employerName = _employers.value.find { it.id == employerId }?.name ?: localizationManager.getString("default_employer_name")
                            notificationManager.scheduleShiftAlert(
                                shiftId = savedShift.id,
                                shiftDate = date,
                                startTime = kotlinx.datetime.LocalTime.parse(startTime),
                                employerName = employerName,
                                alertMinutes = minutes
                            )
                        } catch (e: Exception) {
                            // Handle notification scheduling error silently
                        }
                    }

                    _state.value = _state.value.copy(
                        isLoading = false,
                        isSaved = true
                    )
                },
                onFailure = { exception: Throwable ->
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
        startTime: String,
        endTime: String,
        actualHours: Double,
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

            // First create an expected shift for this entry
            val expectedShift = ExpectedShift(
                id = UUID.randomUUID().toString(),
                userId = userId,
                shiftDate = date.toString(),
                startTime = startTime,
                endTime = endTime,
                expectedHours = actualHours, // Use actual hours as expected for standalone entries
                hourlyRate = 0.0, // Default for entry-only mode
                employerId = employerId,
                status = "completed", // Mark as completed since we're adding actual data
                notes = notes
            )

            // Create the expected shift first
            expectedShiftRepository.createExpectedShift(expectedShift).fold(
                onSuccess = { savedShift: ExpectedShift ->
                    // Now create the shift entry
                    val entry = ShiftEntry(
                        id = UUID.randomUUID().toString(),
                        shiftId = savedShift.id,
                        userId = userId,
                        actualStartTime = startTime,
                        actualEndTime = endTime,
                        actualHours = actualHours,
                        sales = sales,
                        tips = tips,
                        cashOut = cashOut,
                        other = other,
                        notes = notes
                    )

                    shiftEntryRepository.createShiftEntry(entry).fold(
                        onSuccess = { _: ShiftEntry ->
                            _state.value = _state.value.copy(
                                isLoading = false,
                                isSaved = true
                            )
                        },
                        onFailure = { exception: Throwable ->
                            _state.value = _state.value.copy(
                                isLoading = false,
                                error = exception.message ?: localizationManager.getString("error_failed_to_save_entry")
                            )
                        }
                    )
                },
                onFailure = { exception: Throwable ->
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
                expectedShiftRepository.deleteExpectedShift(id).fold(
                    onSuccess = { _: Unit ->
                        _state.value = _state.value.copy(
                            isLoading = false,
                            isDeleted = true
                        )
                    },
                    onFailure = { exception: Throwable ->
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