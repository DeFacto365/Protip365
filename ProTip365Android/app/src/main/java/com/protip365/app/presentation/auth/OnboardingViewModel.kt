package com.protip365.app.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Employer
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.EmployerRepository
import com.protip365.app.domain.repository.SecurityRepository
import com.protip365.app.domain.repository.SubscriptionRepository
import com.protip365.app.domain.repository.UserRepository
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
    private val subscriptionRepository: SubscriptionRepository
) : ViewModel() {

    private val _state = MutableStateFlow(OnboardingState())
    val state: StateFlow<OnboardingState> = _state.asStateFlow()

    fun setLanguage(language: String) {
        _state.value = _state.value.copy(language = language)
        viewModelScope.launch {
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
            0 -> true // Welcome step - always valid
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
            0 -> _state.value.language.isNotBlank()
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

                userRepository.updateUserProfile(
                    mapOf(
                        "preferred_language" to _state.value.language,
                        "default_hourly_rate" to hourlyRate,
                        "tip_target_percentage" to tipTarget,
                        "week_starts_monday" to _state.value.weekStartsMonday,
                        "onboarding_completed" to true
                    )
                )

                // 2. Create default employer
                if (_state.value.employerName.isNotBlank()) {
                    val employer = Employer(
                        id = UUID.randomUUID().toString(),
                        userId = user.userId,
                        name = _state.value.employerName,
                        hourlyRate = hourlyRate,
                        defaultHourlyRate = hourlyRate,
                        active = true
                    )
                    employerRepository.createEmployer(employer)
                }

                // 3. Set up security
                if (_state.value.usePin) {
                    securityRepository.setPin(_state.value.pin)
                    if (_state.value.useBiometric) {
                        securityRepository.enableBiometric()
                    }
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
    // Welcome/Language
    val language: String = "en",

    // Work Settings
    val employerName: String = "",
    val hourlyRate: String = "15.00",
    val tipTarget: String = "20",
    val weekStartsMonday: Boolean = false,

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