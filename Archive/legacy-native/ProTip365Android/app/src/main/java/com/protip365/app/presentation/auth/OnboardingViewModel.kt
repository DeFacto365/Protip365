package com.protip365.app.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.data.models.Employer
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.EmployerRepository
import com.protip365.app.domain.repository.SecurityRepository
import com.protip365.app.domain.repository.SubscriptionRepository
import com.protip365.app.domain.repository.UserRepository
import com.protip365.app.presentation.localization.LocalizationManager
import com.protip365.app.presentation.localization.SupportedLanguage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository,
    private val employerRepository: EmployerRepository,
    private val securityRepository: SecurityRepository,
    private val subscriptionRepository: SubscriptionRepository,
    private val preferencesManager: PreferencesManager,
    private val localizationManager: LocalizationManager
) : ViewModel() {

    private val _state = MutableStateFlow(OnboardingState())
    val state: StateFlow<OnboardingState> = _state.asStateFlow()

    init {
        // Load user profile to pre-fill name from signup
        loadUserProfile()
    }

    private fun loadUserProfile() {
        viewModelScope.launch {
            try {
                val userId = userRepository.getCurrentUserId()
                userId?.let { id ->
                    val userProfile = userRepository.getUserProfile(id)
                    userProfile?.let { profile ->
                        _state.value = _state.value.copy(
                            name = profile.name ?: ""
                        )
                    }
                }
            } catch (e: Exception) {
                // Handle error silently - use empty name as default
            }
        }
    }

    fun setName(name: String) {
        _state.value = _state.value.copy(name = name)
    }

    fun setLanguage(language: String) {
        _state.value = _state.value.copy(language = language)
        viewModelScope.launch {
            // Set language in LocalizationManager immediately for UI updates
            localizationManager.setLanguage(when(language) {
                "en" -> SupportedLanguage.ENGLISH
                "fr" -> SupportedLanguage.FRENCH
                "es" -> SupportedLanguage.SPANISH
                else -> SupportedLanguage.ENGLISH
            })

            // Also save to user preferences and database
            preferencesManager.setLanguage(language)
            userRepository.setLanguagePreference(language)
        }
    }

    fun setEmployerName(name: String) {
        _state.value = _state.value.copy(employerName = name)
    }

    fun setHourlyRate(rate: String) {
        _state.value = _state.value.copy(hourlyRate = rate)
    }

    fun setTipTarget(target: String) {
        _state.value = _state.value.copy(tipTarget = target)
    }

    fun setWeekStart(startsMonday: Boolean) {
        _state.value = _state.value.copy(weekStartsMonday = startsMonday)
        viewModelScope.launch {
            // Save to preferences immediately
            preferencesManager.setWeekStartsMonday(startsMonday)
        }
    }

    fun setUseMultipleEmployers(useMultiple: Boolean) {
        _state.value = _state.value.copy(useMultipleEmployers = useMultiple)
        viewModelScope.launch {
            preferencesManager.setMultipleEmployers(useMultiple)
        }
    }

    fun setVariableSchedule(hasVariable: Boolean) {
        _state.value = _state.value.copy(hasVariableSchedule = hasVariable)
        viewModelScope.launch {
            preferencesManager.setVariableSchedule(hasVariable)
        }
    }

    fun toggleSecurity() {
        _state.value = _state.value.copy(
            usePin = !_state.value.usePin,
            pin = if (!_state.value.usePin) "" else _state.value.pin,
            useBiometric = if (!_state.value.usePin) false else _state.value.useBiometric
        )
    }

    fun setPin(pin: String) {
        _state.value = _state.value.copy(pin = pin)
    }

    fun toggleBiometric() {
        _state.value = _state.value.copy(useBiometric = !_state.value.useBiometric)
    }

    fun selectSubscription(tier: String) {
        _state.value = _state.value.copy(selectedSubscription = tier)
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }

    fun validateStep(step: Int): Boolean {
        return when (step) {
            0 -> _state.value.name.isNotBlank() && _state.value.language.isNotBlank() // Welcome step - require name and language
            1 -> validateWorkSettings()
            2 -> validateSecuritySettings()
            3 -> true // Subscription step - always valid
            else -> true
        }
    }

    private fun validateWorkSettings(): Boolean {
        val hourlyRate = _state.value.hourlyRate.toDoubleOrNull()
        val tipTarget = _state.value.tipTarget.toDoubleOrNull()

        if (_state.value.employerName.isBlank()) {
            _state.value = _state.value.copy(error = "Please enter your employer name")
            return false
        }

        if (hourlyRate == null || hourlyRate <= 0) {
            _state.value = _state.value.copy(error = "Please enter a valid hourly rate")
            return false
        }

        if (tipTarget == null || tipTarget < 0 || tipTarget > 100) {
            _state.value = _state.value.copy(error = "Please enter a valid tip target (0-100%)")
            return false
        }

        return true
    }

    private fun validateSecuritySettings(): Boolean {
        if (_state.value.usePin) {
            if (_state.value.pin.length != 4) {
                _state.value = _state.value.copy(error = "PIN must be 4 digits")
                return false
            }
        }
        return true
    }

    fun canProceed(step: Int): Boolean {
        return when (step) {
            0 -> _state.value.name.isNotBlank() && _state.value.language.isNotBlank()
            1 -> _state.value.employerName.isNotBlank() &&
                 _state.value.hourlyRate.isNotBlank() &&
                 _state.value.tipTarget.isNotBlank()
            2 -> !_state.value.usePin || _state.value.pin.length == 4
            3 -> true // Can always proceed from subscription
            4 -> true // Completion step
            else -> true
        }
    }

    fun completeOnboarding() {
        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = true,
                error = null
            )

            try {
                val user = authRepository.getCurrentUser()
                if (user == null) {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = "User not authenticated"
                    )
                    return@launch
                }

                // 1. Update user profile
                val hourlyRate = _state.value.hourlyRate.toDoubleOrNull() ?: 15.0
                val tipTarget = _state.value.tipTarget.toDoubleOrNull() ?: 20.0

                // Update user profile with comprehensive settings
                userRepository.updateUserProfile(
                    mapOf(
                        "name" to _state.value.name,
                        "preferred_language" to _state.value.language,
                        "default_hourly_rate" to hourlyRate,
                        "tip_target_percentage" to tipTarget,
                        "week_starts_monday" to _state.value.weekStartsMonday,
                        "use_multiple_employers" to _state.value.useMultipleEmployers,
                        "has_variable_schedule" to _state.value.hasVariableSchedule,
                        "onboarding_completed" to true
                    )
                )

                // Save additional preferences locally for immediate access
                preferencesManager.setDailyTarget(400.0f) // Default daily target
                preferencesManager.setWeeklyTarget(2800.0f) // Default weekly target
                preferencesManager.setMonthlyTarget(12000.0f) // Default monthly target
                preferencesManager.setOnboardingCompleted(true)

                // 2. Create default employer
                if (_state.value.employerName.isNotBlank()) {
                    val employer = Employer(
                        id = UUID.randomUUID().toString(),
                        userId = user.userId,
                        name = _state.value.employerName,
                        hourlyRate = hourlyRate,
                        active = true
                    )
                    employerRepository.createEmployer(employer)
                }

                // 3. Set up security
                if (_state.value.usePin) {
                    securityRepository.setPin(_state.value.pin)
                    preferencesManager.setSecurityEnabled(true)
                    if (_state.value.useBiometric) {
                        securityRepository.enableBiometric()
                        preferencesManager.setBiometricEnabled(true)
                    }
                } else {
                    preferencesManager.setSecurityEnabled(false)
                    preferencesManager.setBiometricEnabled(false)
                }

                // 4. Initialize subscription
                when (_state.value.selectedSubscription) {
                    "parttime" -> {
                        subscriptionRepository.startFreeTrial("parttime")
                    }
                    "full" -> {
                        subscriptionRepository.startFreeTrial("full")
                    }
                    else -> {
                        // User skipped - initialize with free tier
                        subscriptionRepository.initializeFree()
                    }
                }

                // Mark onboarding as complete
                userRepository.setOnboardingCompleted(true)

                // Add a small delay for UX
                delay(500)

                _state.value = _state.value.copy(
                    isLoading = false,
                    isComplete = true
                )

            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to complete setup"
                )
            }
        }
    }
}

data class OnboardingState(
    // Personal Info
    val name: String = "",

    // Welcome/Language
    val language: String = "en",

    // Work Settings
    val employerName: String = "",
    val hourlyRate: String = "15.00",
    val tipTarget: String = "20",
    val weekStartsMonday: Boolean = false,
    val useMultipleEmployers: Boolean = false,
    val hasVariableSchedule: Boolean = false,

    // Security
    val usePin: Boolean = false,
    val pin: String = "",
    val useBiometric: Boolean = false,

    // Subscription
    val selectedSubscription: String = "", // "parttime", "full", or "skip"

    // UI State
    val isLoading: Boolean = false,
    val error: String? = null,
    val isComplete: Boolean = false
)