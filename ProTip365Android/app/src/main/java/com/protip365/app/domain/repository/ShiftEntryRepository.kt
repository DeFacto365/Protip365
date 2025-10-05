package com.protip365.app.domain.repository

import com.protip365.app.data.models.ShiftEntry
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.LocalDate

/**
 * Repository for managing ShiftEntry data (actual work done + financial data)
 * Works with the simplified 'shift_entries' table
 */
interface ShiftEntryRepository {
    // Shift Entry operations
    suspend fun getShiftEntries(
        userId: String,
        startDate: LocalDate? = null,
        endDate: LocalDate? = null
    ): List<ShiftEntry>

    suspend fun getShiftEntry(entryId: String): ShiftEntry?

    suspend fun getShiftEntryByShiftId(shiftId: String): ShiftEntry?

    suspend fun createShiftEntry(entry: ShiftEntry): Result<ShiftEntry>

    suspend fun createShiftEntryWithSnapshots(
        entry: ShiftEntry,
        hourlyRate: Double,
        deductionPercentage: Double
    ): Result<ShiftEntry>

    suspend fun updateShiftEntry(entry: ShiftEntry): Result<ShiftEntry>

    suspend fun updateShiftEntryWithSnapshots(
        entry: ShiftEntry,
        hourlyRate: Double,
        deductionPercentage: Double
    ): Result<ShiftEntry>

    suspend fun deleteShiftEntry(entryId: String): Result<Unit>

    suspend fun deleteShiftEntryByShiftId(shiftId: String): Result<Unit>

    // Get entries for specific time periods
    suspend fun getEntriesForDate(userId: String, date: LocalDate): List<ShiftEntry>
    suspend fun getEntriesForWeek(userId: String, weekStart: LocalDate): List<ShiftEntry>
    suspend fun getEntriesForMonth(userId: String, year: Int, month: Int): List<ShiftEntry>

    // Financial aggregations
    suspend fun getTotalIncome(userId: String, startDate: LocalDate, endDate: LocalDate): Double
    suspend fun getTotalTips(userId: String, startDate: LocalDate, endDate: LocalDate): Double
    suspend fun getTotalSales(userId: String, startDate: LocalDate, endDate: LocalDate): Double
    suspend fun getTotalHours(userId: String, startDate: LocalDate, endDate: LocalDate): Double

    // Statistics
    suspend fun getAverageTipPercentage(userId: String, startDate: LocalDate, endDate: LocalDate): Double
    suspend fun getAverageHourlyEarnings(userId: String, startDate: LocalDate, endDate: LocalDate): Double

    // Reactive data streams
    fun observeShiftEntries(userId: String): Flow<List<ShiftEntry>>
    fun observeEntriesForShift(shiftId: String): Flow<ShiftEntry?>
}