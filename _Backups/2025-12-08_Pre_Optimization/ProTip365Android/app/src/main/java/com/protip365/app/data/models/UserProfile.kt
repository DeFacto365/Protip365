package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual
import kotlinx.datetime.Instant
import java.math.BigDecimal

@Serializable
data class UserProfile(
    @SerialName("user_id")
    val userId: String,

    @SerialName("name")
    val name: String? = null,


    @SerialName("default_hourly_rate")
    val defaultHourlyRate: Double? = 15.00,

    @SerialName("week_start")
    val weekStart: Int = 0, // 0=Sunday, 1=Monday

    // Legacy tip target fields (kept for compatibility)
    @SerialName("target_tip_daily")
    val targetTipDaily: Double? = 100.0,

    @SerialName("target_tip_weekly")
    val targetTipWeekly: Double? = 500.0,

    @SerialName("target_tip_monthly")
    val targetTipMonthly: Double? = 2000.0,

    @SerialName("language")
    val language: String? = "en", // Legacy field

    @SerialName("target_sales_daily")
    val targetSalesDaily: Double? = 0.0,

    @SerialName("target_sales_weekly")
    val targetSalesWeekly: Double? = 0.0,

    @SerialName("target_sales_monthly")
    val targetSalesMonthly: Double? = 0.0,

    @SerialName("target_hours_daily")
    val targetHoursDaily: Double? = 0.0,

    @SerialName("target_hours_weekly")
    val targetHoursWeekly: Double? = 0.0,

    @SerialName("target_hours_monthly")
    val targetHoursMonthly: Double? = 0.0,

    @SerialName("use_multiple_employers")
    val useMultipleEmployers: Boolean = false,

    @SerialName("default_employer_id")
    val defaultEmployerId: String? = null,

    @SerialName("tip_target_percentage")
    val tipTargetPercentage: Double? = 0.0,

    @SerialName("has_variable_schedule")
    val hasVariableSchedule: Boolean = false,

    @SerialName("average_deduction_percentage")
    val averageDeductionPercentage: Double = 30.0,

    @SerialName("preferred_language")
    val preferredLanguage: String = "en", // en, fr, es

    @SerialName("default_alert_minutes")
    val defaultAlertMinutes: Int? = 60,

    @SerialName("onboarding_completed")
    val onboardingCompleted: Boolean? = false,

    @SerialName("profile_photo_url")
    val profilePhotoURL: String? = null,

    @SerialName("subscription_tier")
    val subscriptionTier: String = "none", // none, parttime, full

    @SerialName("subscription_status")
    val subscriptionStatus: String = "active",

    @SerialName("subscription_expires_at")
    val subscriptionExpiresAt: String? = null,

    @SerialName("metadata")
    @Contextual
    val metadata: Map<String, @Contextual Any?>? = null,

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    init {
        require(weekStart in 0..6) { "Week start must be between 0 and 6" }
        require(averageDeductionPercentage in 0.0..100.0) { "Average deduction percentage must be between 0 and 100" }
        require(preferredLanguage in listOf("en", "fr", "es")) { "Preferred language must be en, fr, or es" }
        require(subscriptionTier in listOf("none", "parttime", "full")) { "Subscription tier must be none, parttime, or full" }
        require(subscriptionStatus in listOf("active", "expired", "cancelled")) { "Subscription status must be active, expired, or cancelled" }
    }
}

/**
 * Data class for checking onboarding completion status.
 * Used to prevent showing onboarding to users who have already completed it.
 */
@Serializable
data class OnboardingCheck(
    @SerialName("onboarding_completed")
    val onboarding_completed: Boolean? = false
)