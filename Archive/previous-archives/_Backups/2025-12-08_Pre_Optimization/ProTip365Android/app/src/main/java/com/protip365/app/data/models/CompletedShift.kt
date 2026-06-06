package com.protip365.app.data.models

/**
 * CompletedShift combines ExpectedShift and ShiftEntry data for UI convenience
 * Represents a shift with both planning and actual execution data
 */
data class CompletedShift(
    val expectedShift: ExpectedShift,
    val shiftEntry: ShiftEntry? = null, // Null if shift hasn't been worked yet
    val employer: Employer? = null // Employer details for display
) {
    /**
     * Get the status based on expected shift and whether entry exists
     */
    val status: String
        get() = when {
            shiftEntry != null -> "completed"
            expectedShift.status == "missed" -> "missed"
            else -> "planned"
        }

    /**
     * Check if this shift has been worked (has entry data)
     */
    val isWorked: Boolean
        get() = shiftEntry != null

    /**
     * Get total earnings for this shift
     */
    val totalEarnings: Double
        get() = shiftEntry?.getTotalIncome(expectedShift.hourlyRate)
            ?: expectedShift.expectedNetEarnings

    /**
     * Get effective hourly rate for this shift
     */
    val effectiveHourlyRate: Double
        get() = shiftEntry?.getEffectiveHourlyRate(expectedShift.hourlyRate)
            ?: expectedShift.hourlyRate

    /**
     * Get actual or expected hours
     */
    val hours: Double
        get() = shiftEntry?.actualHours ?: expectedShift.expectedHours

    /**
     * Get tips earned (0 if not worked yet)
     */
    val tips: Double
        get() = shiftEntry?.tips ?: 0.0

    /**
     * Get sales made (0 if not worked yet)
     */
    val sales: Double
        get() = shiftEntry?.sales ?: 0.0

    /**
     * Get tip percentage (0 if not worked yet)
     */
    val tipPercentage: Double
        get() = shiftEntry?.tipPercentage ?: 0.0

    /**
     * Get wages earned (hourly rate * hours)
     */
    val wages: Double
        get() = expectedShift.hourlyRate * hours

    /**
     * Get variance between expected and actual hours
     */
    val hoursVariance: Double?
        get() = shiftEntry?.getHoursVariance(expectedShift.expectedHours)

    /**
     * Check if worked overtime
     */
    val isOvertime: Boolean
        get() = shiftEntry?.isOvertime(expectedShift.expectedHours) ?: false

    /**
     * Get display-friendly shift date
     */
    val shiftDate: String
        get() = expectedShift.shiftDate

    /**
     * Get display-friendly time range
     */
    val timeRange: String
        get() = "${expectedShift.startTime} - ${expectedShift.endTime}"

    /**
     * Get actual time range if worked
     */
    val actualTimeRange: String?
        get() = shiftEntry?.let { "${it.actualStartTime} - ${it.actualEndTime}" }

    /**
     * Get employer name for display
     */
    val employerName: String
        get() = employer?.name ?: "Unknown Employer"

    /**
     * Get notes (prioritize entry notes over expected shift notes)
     */
    val notes: String?
        get() = shiftEntry?.notes?.takeIf { it.isNotBlank() }
            ?: expectedShift.notes?.takeIf { it.isNotBlank() }

    /**
     * Get formatted duration string
     */
    fun getFormattedDuration(): String {
        return if (isWorked) {
            shiftEntry!!.getFormattedDuration()
        } else {
            expectedShift.getFormattedDuration()
        }
    }
}