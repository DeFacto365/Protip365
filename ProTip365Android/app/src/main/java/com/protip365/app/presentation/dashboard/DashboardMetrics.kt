package com.protip365.app.presentation.dashboard

import com.protip365.app.data.models.CompletedShift
import kotlinx.datetime.*
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Data structures and calculations for Dashboard metrics
 * Matches iOS DashboardMetrics implementation
 */
object DashboardMetrics {

    data class Stats(
        var hours: Double = 0.0,
        var sales: Double = 0.0,
        var tips: Double = 0.0,
        var tipOut: Double = 0.0,
        var other: Double = 0.0,
        var income: Double = 0.0,  // GROSS salary (hours × rate)
        var tipPercentage: Double = 0.0,
        var totalRevenue: Double = 0.0,  // NET salary + tips + other - tipout
        var completedShifts: List<CompletedShift> = emptyList()
    ) {
        // Calculate net salary after deductions
        fun netIncome(deductionPercentage: Double): Double {
            return income * (1 - deductionPercentage / 100)
        }
    }

    data class UserTargets(
        var tipTargetPercentage: Double = 20.0,
        var dailySales: Double = 0.0,
        var weeklySales: Double = 0.0,
        var monthlySales: Double = 0.0,
        var dailyHours: Double = 8.0,
        var weeklyHours: Double = 40.0,
        var monthlyHours: Double = 160.0,
        var dailyIncome: Double = 0.0,
        var weeklyIncome: Double = 0.0,
        var monthlyIncome: Double = 0.0
    )

    data class DetailViewData(
        val id: String,
        val type: String,
        val shifts: List<CompletedShift>,
        val period: String,
        val startDate: LocalDate? = null,  // Week start date for period display
        val endDate: LocalDate? = null     // Week end date for period display
    )


    /**
     * Calculate statistics from completed shift data (new simplified structure)
     */
    fun calculateStatsFromCompletedShifts(
        shifts: List<CompletedShift>,
        averageDeductionPercentage: Double = 30.0,
        defaultHourlyRate: Double = 15.0
    ): Stats {
        val stats = Stats()

        // Only include shifts that have been worked (have ShiftEntry data)
        stats.completedShifts = shifts.filter { it.isWorked }

        // Track total net income for revenue calculation
        var totalNetIncome = 0.0

        for (shift in stats.completedShifts) {
            // Use actual hours from shift entry or expected hours as fallback
            val actualHours = shift.shiftEntry?.actualHours ?: shift.expectedShift.expectedHours
            stats.hours += actualHours

            // Financial data from shift entry
            shift.shiftEntry?.let { entry ->
                stats.sales += entry.sales
                stats.tips += entry.tips
                stats.tipOut += entry.cashOut
                stats.other += entry.other

                // Use snapshot values if available, otherwise calculate
                if (entry.grossIncome != null && entry.netIncome != null) {
                    // Use snapshot values
                    stats.income += entry.grossIncome ?: 0.0
                    totalNetIncome += entry.netIncome ?: 0.0
                } else {
                    // Fallback: calculate income using hourly rate and actual hours
                    val hourlyRate = entry.hourlyRate ?: shift.expectedShift.hourlyRate
                    val grossIncome = actualHours * hourlyRate
                    stats.income += grossIncome

                    // Calculate net income with deduction
                    val deductionPct = entry.deductionPercentage ?: averageDeductionPercentage
                    val netIncome = grossIncome * (1 - deductionPct / 100)
                    totalNetIncome += netIncome
                }
            } ?: run {
                // No shift entry, use expected shift data
                val hourlyRate = shift.expectedShift.hourlyRate
                val grossIncome = actualHours * hourlyRate
                stats.income += grossIncome
                totalNetIncome += grossIncome * (1 - averageDeductionPercentage / 100)
            }
        }

        // Calculate total revenue: NET salary + tips + other - tip out
        stats.totalRevenue = totalNetIncome + stats.tips + stats.other - stats.tipOut

        // Calculate tip percentage
        stats.tipPercentage = if (stats.sales > 0 && !stats.sales.isNaN() && !stats.tips.isNaN()) {
            (stats.tips / stats.sales) * 100
        } else {
            0.0
        }

        return stats
    }

    /**
     * Get hours target based on selected period
     */
    fun getHoursTarget(
        selectedPeriod: DashboardPeriod,
        monthViewType: MonthViewType,
        userTargets: UserTargets
    ): Double {
        return when (selectedPeriod) {
            DashboardPeriod.TODAY -> userTargets.dailyHours
            DashboardPeriod.WEEK -> userTargets.weeklyHours
            DashboardPeriod.MONTH -> {
                // For month view, use monthly target or calculate from 4 weeks if in 4-week mode
                if (monthViewType == MonthViewType.FOUR_WEEKS && userTargets.weeklyHours > 0) {
                    userTargets.weeklyHours * 4
                } else {
                    userTargets.monthlyHours
                }
            }
            DashboardPeriod.YEAR -> {
                // For year view, calculate based on months elapsed
                val currentMonth = Clock.System.now()
                    .toLocalDateTime(TimeZone.currentSystemDefault()).monthNumber
                userTargets.monthlyHours * currentMonth
            }
            else -> 0.0
        }
    }

    /**
     * Get sales target based on selected period
     */
    fun getSalesTarget(
        selectedPeriod: DashboardPeriod,
        monthViewType: MonthViewType,
        userTargets: UserTargets
    ): Double {
        return when (selectedPeriod) {
            DashboardPeriod.TODAY -> userTargets.dailySales
            DashboardPeriod.WEEK -> userTargets.weeklySales
            DashboardPeriod.MONTH -> {
                if (monthViewType == MonthViewType.FOUR_WEEKS && userTargets.weeklySales > 0) {
                    userTargets.weeklySales * 4
                } else {
                    userTargets.monthlySales
                }
            }
            DashboardPeriod.YEAR -> {
                val currentMonth = Clock.System.now()
                    .toLocalDateTime(TimeZone.currentSystemDefault()).monthNumber
                userTargets.monthlySales * currentMonth
            }
            else -> 0.0
        }
    }

    /**
     * Format currency amount
     */
    fun formatCurrency(amount: Double): String {
        val formatter = NumberFormat.getCurrencyInstance(Locale.US)
        return formatter.format(amount)
    }

    /**
     * Format hours with unit
     */
    fun formatHours(hours: Double): String {
        return "${hours.roundToInt()} hrs"
    }

    /**
     * Format percentage
     */
    fun formatPercentage(percentage: Double): String {
        return "${percentage.roundToInt()}%"
    }

    /**
     * Format income with optional target
     */
    fun formatIncomeWithTarget(
        currentStats: Stats,
        selectedPeriod: DashboardPeriod,
        userTargets: UserTargets
    ): String {
        val income = formatCurrency(currentStats.income)
        // Only show target for Today tab
        return if (selectedPeriod == DashboardPeriod.TODAY) {
            val target = userTargets.dailyIncome
            if (target > 0) "$income/${formatCurrency(target)}" else income
        } else {
            income
        }
    }

    /**
     * Format tips with percentage
     */
    fun formatTipsWithTarget(
        currentStats: Stats,
        selectedPeriod: DashboardPeriod,
        userTargets: UserTargets
    ): String {
        val tips = formatCurrency(currentStats.tips)
        val percentage = if (currentStats.tipPercentage > 0) {
            " • ${formatPercentage(currentStats.tipPercentage)}"
        } else ""

        // Show target percentage for Today only
        return if (selectedPeriod == DashboardPeriod.TODAY && userTargets.tipTargetPercentage > 0) {
            "$tips$percentage/${formatPercentage(userTargets.tipTargetPercentage)}"
        } else {
            "$tips$percentage"
        }
    }

    /**
     * Calculate change percentage between two values
     */
    fun calculateChangePercentage(current: Double, previous: Double): Double {
        return if (previous != 0.0) {
            ((current - previous) / previous) * 100
        } else if (current > 0) {
            100.0
        } else {
            0.0
        }
    }

    /**
     * Get date range for selected period
     */
    /**
     * Calculate the start of the week based on the configured week start day.
     *
     * CRITICAL: This is the SINGLE SOURCE OF TRUTH for week calculation across the entire app.
     * Used by:
     * 1. getDateRangeForPeriod() - Filters weekly shift data
     * 2. DashboardViewModel - Displays week period dates
     * 3. Future: Week navigation for viewing past/future weeks
     *
     * @param date The reference date (typically today, but can be any date for navigation)
     * @param weekStartDay Integer 0-6 (Sunday=0, Monday=1, ..., Saturday=6)
     * @return The start date of the week containing the given date
     *
     * Algorithm:
     * 1. Get current weekday (0-6, Sunday=0)
     * 2. Calculate days to subtract: (currentWeekday - weekStartDay + 7) % 7
     *    - The + 7 ensures positive values before modulo
     *    - The % 7 handles wrap-around
     * 3. Subtract those days from the reference date
     *
     * Example:
     * - Today: October 2, 2025 (Thursday)
     * - Week start: Monday (1)
     * - Current weekday: 4 (Thursday, 0-indexed)
     * - Days to subtract: (4 - 1 + 7) % 7 = 3
     * - Week start: September 29, 2025 (Monday)
     * - Week end: September 29 + 6 days = October 5, 2025 (Sunday)
     */
    fun getStartOfWeek(date: LocalDate, weekStartDay: Int): LocalDate {
        // Convert kotlinx.datetime.DayOfWeek to 0-based (Sunday=0)
        // DayOfWeek: MONDAY=1, TUESDAY=2, ..., SUNDAY=7
        val currentWeekday = (date.dayOfWeek.value % 7) // Sunday becomes 0

        // Calculate days to subtract to reach week start
        val daysToSubtract = (currentWeekday - weekStartDay + 7) % 7

        return date.minus(daysToSubtract, DateTimeUnit.DAY)
    }

    fun getDateRangeForPeriod(
        period: DashboardPeriod,
        weekStartDay: Int = 0  // Default to Sunday for backwards compatibility
    ): Pair<LocalDate, LocalDate> {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date

        return when (period) {
            DashboardPeriod.TODAY -> today to today

            DashboardPeriod.WEEK -> {
                val startOfWeek = getStartOfWeek(today, weekStartDay)
                val endOfWeek = startOfWeek.plus(6, DateTimeUnit.DAY)
                startOfWeek to endOfWeek
            }

            DashboardPeriod.MONTH -> {
                val startOfMonth = LocalDate(today.year, today.month, 1)
                val endOfMonth = startOfMonth.plus(1, DateTimeUnit.MONTH).minus(1, DateTimeUnit.DAY)
                startOfMonth to endOfMonth
            }

            DashboardPeriod.YEAR -> {
                val startOfYear = LocalDate(today.year, 1, 1)
                val endOfYear = LocalDate(today.year, 12, 31)
                startOfYear to endOfYear
            }

            DashboardPeriod.FOUR_WEEKS -> {
                // 4 weeks from start of current week
                val startOfWeek = getStartOfWeek(today, weekStartDay)
                val endOf4Weeks = startOfWeek.plus(27, DateTimeUnit.DAY) // 4 weeks - 1 day
                startOfWeek to endOf4Weeks
            }

            DashboardPeriod.CUSTOM -> {
                // Default to current month for custom (should be overridden by user selection)
                val startOfMonth = LocalDate(today.year, today.month, 1)
                val endOfMonth = startOfMonth.plus(1, DateTimeUnit.MONTH).minus(1, DateTimeUnit.DAY)
                startOfMonth to endOfMonth
            }
        }
    }

    /**
     * Get previous date range for comparison
     */
    fun getPreviousDateRange(
        period: DashboardPeriod,
        weekStartDay: Int = 0  // Must match getDateRangeForPeriod for consistency
    ): Pair<LocalDate, LocalDate> {
        val (currentStart, currentEnd) = getDateRangeForPeriod(period, weekStartDay)
        val daysDiff = currentStart.daysUntil(currentEnd) + 1

        return when (period) {
            DashboardPeriod.TODAY -> {
                val yesterday = currentStart.minus(1, DateTimeUnit.DAY)
                yesterday to yesterday
            }

            DashboardPeriod.WEEK -> {
                val prevWeekStart = currentStart.minus(7, DateTimeUnit.DAY)
                val prevWeekEnd = currentEnd.minus(7, DateTimeUnit.DAY)
                prevWeekStart to prevWeekEnd
            }

            DashboardPeriod.MONTH -> {
                val prevMonthStart = currentStart.minus(1, DateTimeUnit.MONTH)
                val prevMonthEnd = currentStart.minus(1, DateTimeUnit.DAY)
                prevMonthStart to prevMonthEnd
            }

            DashboardPeriod.YEAR -> {
                val prevYearStart = currentStart.minus(1, DateTimeUnit.YEAR)
                val prevYearEnd = currentEnd.minus(1, DateTimeUnit.YEAR)
                prevYearStart to prevYearEnd
            }

            DashboardPeriod.FOUR_WEEKS -> {
                val prev4WeeksStart = currentStart.minus(28, DateTimeUnit.DAY)
                val prev4WeeksEnd = currentStart.minus(1, DateTimeUnit.DAY)
                prev4WeeksStart to prev4WeeksEnd
            }

            DashboardPeriod.CUSTOM -> {
                // For custom, use the same duration but shifted back
                val prevStart = currentStart.minus(daysDiff, DateTimeUnit.DAY)
                val prevEnd = currentEnd.minus(daysDiff, DateTimeUnit.DAY)
                prevStart to prevEnd
            }
        }
    }
}

enum class DashboardPeriod {
    TODAY,
    WEEK,
    MONTH,
    YEAR,
    FOUR_WEEKS,
    CUSTOM
}

enum class MonthViewType {
    CALENDAR_MONTH,
    FOUR_WEEKS
}

// Extension function to calculate days between two dates
fun LocalDate.daysUntil(other: LocalDate): Int {
    return (other.toEpochDays() - this.toEpochDays()).toInt()
}