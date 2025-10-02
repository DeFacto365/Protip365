package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

/**
 * ShiftEntry represents the actual work done and financial data for a shift
 * Maps to the 'shift_entries' table in the simplified database structure
 * One-to-one relationship with ExpectedShift
 */
@Serializable
data class ShiftEntry(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("shift_id")
    val shiftId: String, // References expected_shifts.id

    @SerialName("user_id")
    val userId: String,

    // Actual work times (what really happened)
    @SerialName("actual_start_time")
    val actualStartTime: String, // Time as string (HH:MM:SS)

    @SerialName("actual_end_time")
    val actualEndTime: String, // Time as string (HH:MM:SS)

    @SerialName("actual_hours")
    val actualHours: Double, // Actual hours worked

    // Financial data (entry-specific, not planning-specific)
    @SerialName("sales")
    val sales: Double = 0.0,

    @SerialName("tips")
    val tips: Double = 0.0,

    @SerialName("cash_out")
    val cashOut: Double = 0.0,

    @SerialName("other")
    val other: Double = 0.0, // Other income

    // Entry-specific notes
    @SerialName("notes")
    val notes: String? = null,

    // Income snapshot fields (to preserve historical data)
    @SerialName("hourly_rate")
    val hourlyRate: Double? = null, // Snapshot of hourly rate at entry time

    @SerialName("gross_income")
    val grossIncome: Double? = null, // Snapshot of wages (hourly_rate * actual_hours)

    @SerialName("total_income")
    val totalIncome: Double? = null, // Snapshot of total earnings (wages + tips)

    @SerialName("net_income")
    val netIncome: Double? = null, // Snapshot of after-deduction income

    @SerialName("deduction_percentage")
    val deductionPercentage: Double? = null, // Snapshot of deduction % at entry time

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    init {
        require(actualHours >= 0) { "Actual hours must be non-negative" }
        require(sales >= 0) { "Sales must be non-negative" }
        require(tips >= 0) { "Tips must be non-negative" }
        require(cashOut >= 0) { "Cash out must be non-negative" }
        require(other >= 0) { "Other income must be non-negative" }
    }

    /**
     * Calculate total tip income (tips + other - cash_out)
     */
    val totalTipIncome: Double
        get() = tips + other - cashOut

    /**
     * Calculate tip percentage based on sales
     */
    val tipPercentage: Double
        get() = if (sales > 0) (tips / sales) * 100 else 0.0

    /**
     * Get gross income (wages only) - uses snapshot if available, otherwise calculates
     */
    fun getGrossIncome(employerHourlyRate: Double = 15.0): Double {
        return grossIncome ?: (actualHours * employerHourlyRate)
    }

    /**
     * Get total income (wages + tips) - uses snapshot if available, otherwise calculates
     */
    fun getTotalIncome(employerHourlyRate: Double = 15.0): Double {
        return totalIncome ?: (getGrossIncome(employerHourlyRate) + totalTipIncome)
    }

    /**
     * Get net income after deductions - uses snapshot if available, otherwise calculates
     */
    fun getNetIncome(employerHourlyRate: Double = 15.0, deductionPct: Double = 30.0): Double {
        return netIncome ?: run {
            val total = getTotalIncome(employerHourlyRate)
            val gross = getGrossIncome(employerHourlyRate)
            val deductions = gross * (deductionPct / 100.0)
            total - deductions
        }
    }

    /**
     * Calculate total earnings including wages (requires ExpectedShift data)
     * DEPRECATED: Use getTotalIncome() instead
     */
    @Deprecated("Use getTotalIncome() instead", ReplaceWith("getTotalIncome(hourlyRate)"))
    fun getTotalEarnings(hourlyRate: Double): Double {
        return getTotalIncome(hourlyRate)
    }

    /**
     * Calculate effective hourly rate including all income
     */
    fun getEffectiveHourlyRate(employerHourlyRate: Double = 15.0): Double {
        return if (actualHours > 0) getTotalIncome(employerHourlyRate) / actualHours else 0.0
    }

    /**
     * Get formatted actual duration string
     */
    fun getFormattedDuration(): String {
        val hours = actualHours.toInt()
        val minutes = ((actualHours - hours) * 60).toInt()
        return if (minutes > 0) "${hours}h ${minutes}m" else "${hours}h"
    }

    /**
     * Calculate variance from expected hours
     */
    fun getHoursVariance(expectedHours: Double): Double {
        return actualHours - expectedHours
    }

    /**
     * Check if worked overtime compared to expected
     */
    fun isOvertime(expectedHours: Double): Boolean {
        return actualHours > expectedHours
    }
}