package com.protip365.app.domain.repository

import com.protip365.app.data.models.CompletedShift
import com.protip365.app.data.models.ExpectedShift
import com.protip365.app.data.models.ShiftEntry
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.LocalDate

/**
 * Repository for working with complete shift data (ExpectedShift + ShiftEntry + Employer)
 * Provides high-level operations combining data from multiple sources
 */
interface CompletedShiftRepository {
    // Get complete shift data
    suspend fun getCompletedShifts(
        userId: String,
        startDate: LocalDate? = null,
        endDate: LocalDate? = null,
        includeUnworked: Boolean = true
    ): List<CompletedShift>

    suspend fun getCompletedShift(shiftId: String): CompletedShift?

    // Create a new shift with optional entry data
    suspend fun createShift(expectedShift: ExpectedShift, shiftEntry: ShiftEntry? = null): Result<CompletedShift>

    // Update shift data (can update either expected or entry data)
    suspend fun updateShift(completedShift: CompletedShift): Result<CompletedShift>

    // Delete complete shift (removes both expected and entry data)
    suspend fun deleteShift(shiftId: String): Result<Unit>

    // Mark a shift as worked (creates entry data)
    suspend fun completeShift(shiftId: String, shiftEntry: ShiftEntry): Result<CompletedShift>

    // Mark a shift as missed
    suspend fun markShiftAsMissed(shiftId: String): Result<Unit>

    // Get shifts by different criteria
    suspend fun getWorkedShifts(userId: String, startDate: LocalDate? = null, endDate: LocalDate? = null): List<CompletedShift>
    suspend fun getPlannedShifts(userId: String): List<CompletedShift>
    suspend fun getMissedShifts(userId: String): List<CompletedShift>

    // Time-based queries
    suspend fun getShiftsForDate(userId: String, date: LocalDate): List<CompletedShift>
    suspend fun getShiftsForWeek(userId: String, weekStart: LocalDate): List<CompletedShift>
    suspend fun getShiftsForMonth(userId: String, year: Int, month: Int): List<CompletedShift>

    // Dashboard statistics
    suspend fun getDashboardStats(
        userId: String,
        startDate: LocalDate,
        endDate: LocalDate
    ): DashboardStats

    // Reactive data streams
    fun observeCompletedShifts(userId: String): Flow<List<CompletedShift>>
    fun observeShiftsForDate(userId: String, date: LocalDate): Flow<List<CompletedShift>>
    fun observeDashboardStats(userId: String, startDate: LocalDate, endDate: LocalDate): Flow<DashboardStats>
}

/**
 * Dashboard statistics data class
 */
data class DashboardStats(
    val totalShifts: Int,
    val workedShifts: Int,
    val missedShifts: Int,
    val totalHours: Double,
    val totalEarnings: Double,
    val totalWages: Double,
    val totalTips: Double,
    val totalSales: Double,
    val averageTipPercentage: Double,
    val averageHourlyRate: Double,
    val effectiveHourlyRate: Double
)