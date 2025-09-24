package com.protip365.app.presentation.onboarding

data class OnboardingState(
    val currentStep: Int = 1,
    val language: String = "en",
    val useMultipleEmployers: Boolean = false,
    val weekStart: Int = 0, // 0=Sunday, 1=Monday
    val securityType: SecurityType = SecurityType.NONE,
    val hasVariableSchedule: Boolean = false,
    val tipTargetPercentage: String = "",
    val targetSalesDaily: String = "",
    val targetHoursDaily: String = ""
) {
    fun isStepValid(): Boolean {
        return when (currentStep) {
            1 -> true // Language selection always valid
            2 -> true // Multiple employers always valid (boolean)
            3 -> true // Week start always valid
            4 -> true // Security always valid
            5 -> true // Variable schedule always valid (boolean)
            6 -> tipTargetPercentage.isNotEmpty() && 
                 targetSalesDaily.isNotEmpty() && 
                 targetHoursDaily.isNotEmpty() // All targets required
            7 -> true // How to use page always valid
            else -> false
        }
    }
    
    fun resetToDefaults() {
        // Reset all values to defaults
    }
}

enum class SecurityType {
    NONE,
    PIN,
    BIOMETRIC
}

enum class OnboardingStep(val stepNumber: Int, val titleKey: String, val descriptionKey: String) {
    LANGUAGE(1, "language_step_title", "language_step_description"),
    MULTIPLE_EMPLOYERS(2, "multiple_employers_step_title", "multiple_employers_step_description"),
    WEEK_START(3, "week_start_step_title", "week_start_step_description"),
    SECURITY(4, "security_step_title", "security_step_description"),
    VARIABLE_SCHEDULE(5, "variable_schedule_step_title", "variable_schedule_step_description"),
    TARGETS(6, "targets_step_title", "targets_step_description"),
    COMPLETION(7, "completion_step_title", "completion_step_description")
}



