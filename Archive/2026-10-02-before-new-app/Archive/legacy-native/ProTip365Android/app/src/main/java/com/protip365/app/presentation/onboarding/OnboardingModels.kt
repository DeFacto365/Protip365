package com.protip365.app.presentation.onboarding

data class OnboardingState(
    val currentStep: Int = 0, // Start with language step (matching iOS)
    val language: String = "en",
    val useMultipleEmployers: Boolean = true,
    val singleEmployerName: String = "", // For single employer mode
    val defaultEmployerId: String? = null, // Default employer for multiple employers mode
    val employers: List<com.protip365.app.data.models.Employer> = emptyList(), // List of employers loaded from database
    val weekStart: Int = 0, // 0=Sunday, 1=Monday
    val securityType: SecurityType = SecurityType.NONE,
    val hasVariableSchedule: Boolean = false,
    val tipTargetPercentage: String = "15", // Default 15% like iOS
    val averageDeductionPercentage: String = "30", // Default 30% like iOS
    val targetSalesDaily: String = "",
    val targetSalesWeekly: String = "",
    val targetSalesMonthly: String = "",
    val targetHoursDaily: String = "",
    val targetHoursWeekly: String = "",
    val targetHoursMonthly: String = "",
    val isCompleting: Boolean = false, // Loading state for finish button
    val completionError: String? = null // Error message if completion fails
) {
    fun isStepValid(): Boolean {
        return when (currentStep) {
            0 -> true // Language selection always valid
            1 -> useMultipleEmployers || singleEmployerName.trim().isNotEmpty() // Single employer name required if not using multiple
            2 -> true // Week start always valid
            3 -> true // Security always valid
            4 -> true // Variable schedule always valid (boolean)
            5 -> tipTargetPercentage.isNotEmpty() &&
                 averageDeductionPercentage.isNotEmpty() &&
                 targetSalesDaily.isNotEmpty() &&
                 targetHoursDaily.isNotEmpty() // Core targets + deduction required
            6 -> true // How to use page always valid
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
    LANGUAGE(0, "language_step_title", "language_step_description"),
    MULTIPLE_EMPLOYERS(1, "multiple_employers_step_title", "multiple_employers_step_description"),
    WEEK_START(2, "week_start_step_title", "week_start_step_description"),
    SECURITY(3, "security_step_title", "security_step_description"),
    VARIABLE_SCHEDULE(4, "variable_schedule_step_title", "variable_schedule_step_description"),
    TARGETS(5, "targets_step_title", "targets_step_description"),
    HOW_TO_USE(6, "how_to_use_step_title", "how_to_use_step_description")
}






