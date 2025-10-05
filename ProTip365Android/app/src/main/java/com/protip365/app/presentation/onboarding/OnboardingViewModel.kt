package com.protip365.app.presentation.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.UserRepository
import com.protip365.app.presentation.localization.LocalizationManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val authRepository: AuthRepository,
    private val employerRepository: com.protip365.app.domain.repository.EmployerRepository,
    private val preferencesManager: PreferencesManager,
    private val localizationManager: LocalizationManager
) : ViewModel() {

    private val _state = MutableStateFlow(OnboardingState())
    val state: StateFlow<OnboardingState> = _state.asStateFlow()

    init {
        // For onboarding, start with default values from OnboardingState
        // Don't load profile as it might override the desired defaults
        loadUserLanguagePreference()
    }

    private fun loadUserLanguagePreference() {
        viewModelScope.launch {
            try {
                val userId = userRepository.getCurrentUserId()
                userId?.let { id ->
                    val userProfile = userRepository.getUserProfile(id)
                    userProfile?.let { profile ->
                        // Only load language preference, keep other defaults
                        _state.value = _state.value.copy(
                            language = profile.preferredLanguage
                        )
                    }
                }
            } catch (e: Exception) {
                // Handle error - use default language
                println("Error loading user language: ${e.message}")
            }
        }
    }

    fun updateCurrentStep(step: Int) {
        _state.value = _state.value.copy(currentStep = step)
    }

    fun updateLanguage(language: String) {
        _state.value = _state.value.copy(language = language)
        viewModelScope.launch {
            // Save language preference immediately
            localizationManager.setLanguage(when(language) {
                "en" -> com.protip365.app.presentation.localization.SupportedLanguage.ENGLISH
                "fr" -> com.protip365.app.presentation.localization.SupportedLanguage.FRENCH
                "es" -> com.protip365.app.presentation.localization.SupportedLanguage.SPANISH
                else -> com.protip365.app.presentation.localization.SupportedLanguage.ENGLISH
            })
            userRepository.setLanguagePreference(language)
        }
    }

    fun updateSingleEmployerName(name: String) {
        _state.value = _state.value.copy(singleEmployerName = name)
    }

    fun updateMultipleEmployers(useMultiple: Boolean) {
        _state.value = _state.value.copy(
            useMultipleEmployers = useMultiple,
            singleEmployerName = if (useMultiple) "" else _state.value.singleEmployerName // Clear employer name if switching to multiple
        )
        viewModelScope.launch {
            preferencesManager.setMultipleEmployers(useMultiple)
        }
    }

    fun updateWeekStart(weekStartDay: Int) {
        _state.value = _state.value.copy(weekStart = weekStartDay)
        viewModelScope.launch {
            // For now, save as boolean (true = Monday, false = Sunday)
            // In future, update to support all days
            val startsMonday = weekStartDay == 1
            preferencesManager.setWeekStartsMonday(startsMonday)
        }
    }

    fun updateSecurityType(securityType: SecurityType) {
        _state.value = _state.value.copy(securityType = securityType)
        viewModelScope.launch {
            when (securityType) {
                SecurityType.PIN -> preferencesManager.setSecurityEnabled(true)
                SecurityType.BIOMETRIC -> preferencesManager.setBiometricEnabled(true)
                SecurityType.NONE -> {
                    preferencesManager.setSecurityEnabled(false)
                    preferencesManager.setBiometricEnabled(false)
                }
            }
        }
    }

    fun updateVariableSchedule(hasVariable: Boolean) {
        _state.value = _state.value.copy(hasVariableSchedule = hasVariable)
        viewModelScope.launch {
            preferencesManager.setVariableSchedule(hasVariable)
        }
    }

    fun updateDefaultEmployer(employerId: String?) {
        _state.value = _state.value.copy(defaultEmployerId = employerId)
        println("🔵 Default employer updated to: $employerId")
    }

    // Load employers from database (called after employer management sheet closes)
    fun loadEmployers() {
        viewModelScope.launch {
            try {
                val userId = userRepository.getCurrentUserId()
                if (userId != null) {
                    val employers = employerRepository.getEmployers(userId)
                        .sortedBy { it.name } // Sort alphabetically like iOS

                    _state.value = _state.value.copy(employers = employers)

                    // Auto-select first employer if none selected and list is not empty
                    if (_state.value.defaultEmployerId == null && employers.isNotEmpty()) {
                        _state.value = _state.value.copy(defaultEmployerId = employers.first().id)
                    }
                }
            } catch (e: Exception) {
                // Log error but don't fail onboarding
                println("Error loading employers: ${e.message}")
            }
        }
    }

    fun updateTargets(
        tipPercentage: String,
        averageDeduction: String,
        salesDaily: String,
        hoursDaily: String,
        salesWeekly: String,
        hoursWeekly: String,
        salesMonthly: String,
        hoursMonthly: String
    ) {
        _state.value = _state.value.copy(
            tipTargetPercentage = tipPercentage,
            averageDeductionPercentage = averageDeduction,
            targetSalesDaily = salesDaily,
            targetHoursDaily = hoursDaily,
            targetSalesWeekly = salesWeekly,
            targetHoursWeekly = hoursWeekly,
            targetSalesMonthly = salesMonthly,
            targetHoursMonthly = hoursMonthly
        )
    }

    fun completeOnboarding(onComplete: () -> Unit) {
        viewModelScope.launch {
            try {
                val userId = userRepository.getCurrentUserId()

                // Reload employers if using multiple employers to get latest default
                if (_state.value.useMultipleEmployers && userId != null) {
                    val employers = employerRepository.getEmployers(userId)
                    _state.value = _state.value.copy(employers = employers)

                    // Auto-select first employer if none selected and list is not empty
                    if (_state.value.defaultEmployerId == null && employers.isNotEmpty()) {
                        _state.value = _state.value.copy(defaultEmployerId = employers.first().id)
                        println("🔵 Auto-selected default employer: ${employers.first().name}")
                    }
                }

                // Save single employer if not using multiple employers (matching iOS)
                if (!_state.value.useMultipleEmployers && _state.value.singleEmployerName.trim().isNotEmpty() && userId != null) {
                    // Create employer in database (matching iOS)
                    // TODO: Add employer repository method
                }

                // Parse targets
                val tipTarget = _state.value.tipTargetPercentage.toDoubleOrNull() ?: 15.0
                val averageDeduction = _state.value.averageDeductionPercentage.toDoubleOrNull() ?: 30.0
                val salesDaily = _state.value.targetSalesDaily.toDoubleOrNull() ?: 0.0
                val salesWeekly = if (_state.value.hasVariableSchedule) 0.0 else (_state.value.targetSalesWeekly.toDoubleOrNull() ?: 0.0)
                val salesMonthly = if (_state.value.hasVariableSchedule) 0.0 else (_state.value.targetSalesMonthly.toDoubleOrNull() ?: 0.0)
                val hoursDaily = _state.value.targetHoursDaily.toDoubleOrNull() ?: 0.0
                val hoursWeekly = if (_state.value.hasVariableSchedule) 0.0 else (_state.value.targetHoursWeekly.toDoubleOrNull() ?: 0.0)
                val hoursMonthly = if (_state.value.hasVariableSchedule) 0.0 else (_state.value.targetHoursMonthly.toDoubleOrNull() ?: 0.0)

                println("🔵 Completing onboarding with data:")
                println("  Language: ${_state.value.language}")
                println("  Multiple Employers: ${_state.value.useMultipleEmployers}")
                println("  Default Employer ID: ${_state.value.defaultEmployerId}")
                println("  Week Start: ${_state.value.weekStart}")
                println("  Variable Schedule: ${_state.value.hasVariableSchedule}")
                println("  Tip Target: $tipTarget%")
                println("  Avg Deduction: $averageDeduction%")
                println("  Sales Daily: $$salesDaily")
                println("  Hours Daily: $hoursDaily hrs")

                // Update user profile with all onboarding data (matching iOS)
                val updateResult = userRepository.updateUserProfile(
                    mapOf(
                        "preferred_language" to _state.value.language,
                        "use_multiple_employers" to _state.value.useMultipleEmployers,
                        "week_start" to _state.value.weekStart,
                        "has_variable_schedule" to _state.value.hasVariableSchedule,
                        "tip_target_percentage" to tipTarget,
                        "target_sales_daily" to salesDaily,
                        "target_sales_weekly" to salesWeekly,
                        "target_sales_monthly" to salesMonthly,
                        "target_hours_daily" to hoursDaily,
                        "target_hours_weekly" to hoursWeekly,
                        "target_hours_monthly" to hoursMonthly,
                        "average_deduction_percentage" to averageDeduction,
                        "default_employer_id" to _state.value.defaultEmployerId, // Save default employer
                        "onboarding_completed" to true // ⭐ NEW: Mark onboarding as completed
                    )
                )

                if (updateResult.isFailure) {
                    println("❌ Failed to save onboarding data: ${updateResult.exceptionOrNull()?.message}")
                    updateResult.exceptionOrNull()?.printStackTrace()
                    throw updateResult.exceptionOrNull() ?: Exception("Failed to save onboarding data")
                }

                println("✅ Onboarding data saved successfully to database")

                // Save to preferences
                preferencesManager.setDailyTarget(salesDaily.toFloat())
                if (!_state.value.hasVariableSchedule) {
                    preferencesManager.setWeeklyTarget(salesWeekly.toFloat())
                    preferencesManager.setMonthlyTarget(salesMonthly.toFloat())
                }

                // Mark onboarding as complete in preferences
                preferencesManager.setOnboardingCompleted(true)
                println("✅ Onboarding marked complete in preferences")

                // Navigate to main screen
                onComplete()
            } catch (e: Exception) {
                // Handle error - show to user
                println("❌ Error completing onboarding: ${e.message}")
                e.printStackTrace()
                // Don't call onComplete() if there was an error
                // User will stay on onboarding screen and can try again
            }
        }
    }
}

