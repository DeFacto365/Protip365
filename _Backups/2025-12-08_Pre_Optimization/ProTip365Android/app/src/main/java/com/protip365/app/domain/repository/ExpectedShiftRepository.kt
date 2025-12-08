package com.protip365.app.domain.repository

import com.protip365.app.data.models.CompletedShift
import com.protip365.app.data.models.ExpectedShift
import com.protip365.app.data.models.ShiftEntry
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.LocalDate

/**
 * Repository for managing ExpectedShift data (planned shifts)
 * Works with the simplified 'expected_shifts' table
 */
interface ExpectedShiftRepository {
    // Expected Shift operations
    suspend fun getExpectedShifts(
        userId: String,
        startDate: LocalDate? = null,
        endDate: LocalDate? = null
    ): List<ExpectedShift>

    suspend fun getExpectedShift(shiftId: String): ExpectedShift?

    suspend fun createExpectedShift(shift: ExpectedShift): Result<ExpectedShift>

    suspend fun updateExpectedShift(shift: ExpectedShift): Result<ExpectedShift>

    suspend fun deleteExpectedShift(shiftId: String): Result<Unit>

    suspend fun updateShiftStatus(shiftId: String, status: String): Result<Unit>

    // Get shifts by status
    suspend fun getPlannedShifts(userId: String): List<ExpectedShift>
    suspend fun getCompletedShifts(userId: String): List<ExpectedShift>
    suspend fun getMissedShifts(userId: String): List<ExpectedShift>

    // Get shifts for specific date range
    suspend fun getShiftsForDate(userId: String, date: LocalDate): List<ExpectedShift>
    suspend fun getShiftsForWeek(userId: String, weekStart: LocalDate): List<ExpectedShift>
    suspend fun getShiftsForMonth(userId: String, year: Int, month: Int): List<ExpectedShift>

    // Check for overlapping shifts
    suspend fun getOverlappingShifts(
        userId: String,
        startDate: String,
        startTime: String,
        endDate: String,
        endTime: String,
        excludeShiftId: String? = null
    ): List<ExpectedShift>

    // Reactive data streams
    fun observeExpectedShifts(userId: String): Flow<List<ExpectedShift>>
    fun observeShiftsForDate(userId: String, date: LocalDate): Flow<List<ExpectedShift>>
    fun observeUpcomingShifts(userId: String): Flow<List<ExpectedShift>>
}