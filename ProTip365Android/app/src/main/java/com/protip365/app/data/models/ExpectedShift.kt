package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

/**
 * ExpectedShift represents a planned/scheduled shift
 * Maps to the 'expected_shifts' table in the simplified database structure
 */
@Serializable
data class ExpectedShift(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("user_id")
    val userId: String,

    @SerialName("employer_id")
    val employerId: String? = null,

    // Scheduling data
    @SerialName("shift_date")
    val shiftDate: String, // Date as string in ISO format (YYYY-MM-DD)

    @SerialName("start_time")
    val startTime: String, // Time as string (HH:MM:SS)

    @SerialName("end_time")
    val endTime: String, // Time as string (HH:MM:SS)

    @SerialName("expected_hours")
    val expectedHours: Double, // Expected duration in hours

    @SerialName("hourly_rate")
    val hourlyRate: Double, // Hourly rate for this shift

    // Break time (simplified - only minutes)
    @SerialName("lunch_break_minutes")
    val lunchBreakMinutes: Int = 0,

    // Custom sales target (NEW)
    @SerialName("sales_target")
    val salesTarget: Double? = null, // NULL means use default from settings

    // Status and metadata
    @SerialName("status")
    val status: String = "planned", // planned, completed, missed

    @SerialName("alert_minutes")
    val alertMinutes: Int? = null, // For notifications

    @SerialName("notes")
    val notes: String? = null, // Shift-specific planning notes

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    init {
        require(status in listOf("planned", "completed", "missed")) {
            "Status must be planned, completed, or missed"
        }
        require(expectedHours >= 0) { "Expected hours must be non-negative" }
        require(hourlyRate >= 0) { "Hourly rate must be non-negative" }
        require(lunchBreakMinutes >= 0) { "Lunch break minutes must be non-negative" }
    }

    /**
     * Calculate expected gross earnings (before deductions)
     */
    val expectedGrossEarnings: Double
        get() = hourlyRate * expectedHours

    /**
     * Calculate effective working hours (expected hours minus break time)
     */
    val effectiveExpectedHours: Double
        get() = maxOf(0.0, expectedHours - (lunchBreakMinutes / 60.0))

    /**
     * Calculate expected earnings after accounting for unpaid break time
     */
    val expectedNetEarnings: Double
        get() = hourlyRate * effectiveExpectedHours

    /**
     * Check if this shift is in the past
     */
    fun isPastShift(): Boolean {
        // This would need date parsing logic based on your date format
        // For now, returning false as placeholder
        return false
    }

    /**
     * Check if this shift is today
     */
    fun isTodayShift(): Boolean {
        // This would need date parsing logic
        return false
    }

    /**
     * Get formatted shift duration string
     */
    fun getFormattedDuration(): String {
        val hours = expectedHours.toInt()
        val minutes = ((expectedHours - hours) * 60).toInt()
        return if (minutes > 0) "${hours}h ${minutes}m" else "${hours}h"
    }
}