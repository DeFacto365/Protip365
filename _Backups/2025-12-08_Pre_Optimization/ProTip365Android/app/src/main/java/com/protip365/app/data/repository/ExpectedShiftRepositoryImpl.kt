package com.protip365.app.data.repository

import com.protip365.app.data.models.ExpectedShift
import com.protip365.app.domain.repository.ExpectedShiftRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.datetime.LocalDate
import kotlinx.datetime.plus
import kotlinx.datetime.DatePeriod
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ExpectedShiftRepositoryImpl @Inject constructor(
    private val supabaseClient: SupabaseClient
) : ExpectedShiftRepository {

    override suspend fun getExpectedShifts(
        userId: String,
        startDate: LocalDate?,
        endDate: LocalDate?
    ): List<ExpectedShift> {
        return try {
            supabaseClient
                .from("expected_shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        startDate?.let { gte("shift_date", it.toString()) }
                        endDate?.let { lte("shift_date", it.toString()) }
                    }
                    order("shift_date", Order.DESCENDING)
                    order("start_time", Order.ASCENDING)
                }
                .decodeList<ExpectedShift>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getExpectedShift(shiftId: String): ExpectedShift? {
        return try {
            supabaseClient
                .from("expected_shifts")
                .select {
                    filter {
                        eq("id", shiftId)
                    }
                }
                .decodeSingleOrNull<ExpectedShift>()
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun createExpectedShift(shift: ExpectedShift): Result<ExpectedShift> {
        return try {
            val createdShift = supabaseClient
                .from("expected_shifts")
                .insert(shift) {
                    select()
                }
                .decodeSingle<ExpectedShift>()
            Result.success(createdShift)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateExpectedShift(shift: ExpectedShift): Result<ExpectedShift> {
        return try {
            val updatedShift = supabaseClient
                .from("expected_shifts")
                .update(shift) {
                    filter {
                        eq("id", shift.id)
                    }
                    select()
                }
                .decodeSingle<ExpectedShift>()
            Result.success(updatedShift)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteExpectedShift(shiftId: String): Result<Unit> {
        return try {
            supabaseClient
                .from("expected_shifts")
                .delete {
                    filter {
                        eq("id", shiftId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateShiftStatus(shiftId: String, status: String): Result<Unit> {
        return try {
            supabaseClient
                .from("expected_shifts")
                .update(mapOf("status" to status, "updated_at" to "now()")) {
                    filter {
                        eq("id", shiftId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getPlannedShifts(userId: String): List<ExpectedShift> {
        return try {
            supabaseClient
                .from("expected_shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        eq("status", "planned")
                    }
                    order("shift_date", Order.ASCENDING)
                    order("start_time", Order.ASCENDING)
                }
                .decodeList<ExpectedShift>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getCompletedShifts(userId: String): List<ExpectedShift> {
        return try {
            supabaseClient
                .from("expected_shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        eq("status", "completed")
                    }
                    order("shift_date", Order.DESCENDING)
                }
                .decodeList<ExpectedShift>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getMissedShifts(userId: String): List<ExpectedShift> {
        return try {
            supabaseClient
                .from("expected_shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        eq("status", "missed")
                    }
                    order("shift_date", Order.DESCENDING)
                }
                .decodeList<ExpectedShift>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getShiftsForDate(userId: String, date: LocalDate): List<ExpectedShift> {
        return try {
            supabaseClient
                .from("expected_shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        eq("shift_date", date.toString())
                    }
                    order("start_time", Order.ASCENDING)
                }
                .decodeList<ExpectedShift>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getShiftsForWeek(userId: String, weekStart: LocalDate): List<ExpectedShift> {
        val weekEnd = weekStart.plus(DatePeriod(days = 6))
        return getExpectedShifts(userId, weekStart, weekEnd)
    }

    override suspend fun getShiftsForMonth(userId: String, year: Int, month: Int): List<ExpectedShift> {
        val startDate = LocalDate(year, month, 1)
        val endDate = LocalDate(year, month, startDate.monthNumber).let {
            LocalDate(year, month, it.dayOfMonth)
        }
        return getExpectedShifts(userId, startDate, endDate)
    }

    override fun observeExpectedShifts(userId: String): Flow<List<ExpectedShift>> = flow {
        emit(getExpectedShifts(userId))
    }

    override fun observeShiftsForDate(userId: String, date: LocalDate): Flow<List<ExpectedShift>> = flow {
        emit(getShiftsForDate(userId, date))
    }

    override fun observeUpcomingShifts(userId: String): Flow<List<ExpectedShift>> = flow {
        val today = LocalDate.fromEpochDays(System.currentTimeMillis().toInt() / 86400000)
        emit(getExpectedShifts(userId, today, null))
    }

    override suspend fun getOverlappingShifts(
        userId: String,
        startDate: String,
        startTime: String,
        endDate: String,
        endTime: String,
        excludeShiftId: String?
    ): List<ExpectedShift> {
        return try {
            // Get all shifts for the user in the date range
            val allShifts = supabaseClient
                .from("expected_shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        // Get shifts that could potentially overlap
                        gte("shift_date", startDate)
                        lte("shift_date", endDate)
                        // Don't include "missed" shifts in overlap check
                        neq("status", "missed")
                        // Exclude the current shift if editing
                        excludeShiftId?.let { neq("id", it) }
                    }
                }
                .decodeList<ExpectedShift>()

            // Filter for actual overlaps
            allShifts.filter { shift ->
                isOverlapping(
                    shiftStartDate = shift.shiftDate,
                    shiftStartTime = shift.startTime,
                    shiftEndDate = shift.shiftDate, // Assuming single day shift for existing
                    shiftEndTime = shift.endTime,
                    checkStartDate = startDate,
                    checkStartTime = startTime,
                    checkEndDate = endDate,
                    checkEndTime = endTime
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun isOverlapping(
        shiftStartDate: String,
        shiftStartTime: String,
        shiftEndDate: String,
        shiftEndTime: String,
        checkStartDate: String,
        checkStartTime: String,
        checkEndDate: String,
        checkEndTime: String
    ): Boolean {
        // Convert to comparable datetime strings (YYYY-MM-DD HH:MM)
        val shiftStart = "$shiftStartDate $shiftStartTime"
        val shiftEnd = if (shiftEndTime < shiftStartTime && shiftEndDate == shiftStartDate) {
            // Handle overnight shift for existing shift
            val nextDay = LocalDate.parse(shiftStartDate).plus(DatePeriod(days = 1))
            "$nextDay $shiftEndTime"
        } else {
            "$shiftEndDate $shiftEndTime"
        }

        val checkStart = "$checkStartDate $checkStartTime"
        val checkEnd = "$checkEndDate $checkEndTime"

        // Check for overlap: shifts overlap if one starts before the other ends
        return (checkStart < shiftEnd && checkEnd > shiftStart)
    }
}