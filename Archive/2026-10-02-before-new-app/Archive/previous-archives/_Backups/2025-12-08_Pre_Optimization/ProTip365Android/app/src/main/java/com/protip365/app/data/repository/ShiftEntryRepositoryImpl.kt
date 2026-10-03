package com.protip365.app.data.repository

import com.protip365.app.data.models.ShiftEntry
import com.protip365.app.domain.repository.ShiftEntryRepository
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
class ShiftEntryRepositoryImpl @Inject constructor(
    private val supabaseClient: SupabaseClient
) : ShiftEntryRepository {

    override suspend fun getShiftEntries(
        userId: String,
        startDate: LocalDate?,
        endDate: LocalDate?
    ): List<ShiftEntry> {
        return try {
            // Join with expected_shifts to filter by date since shift_entries doesn't have date
            val query = buildString {
                append("*, expected_shifts!inner(shift_date)")
                if (startDate != null || endDate != null) {
                    append(".select(shift_date)")
                }
            }

            supabaseClient
                .from("shift_entries")
                .select(columns = io.github.jan.supabase.postgrest.query.Columns.raw(query)) {
                    filter {
                        eq("user_id", userId)
                        if (startDate != null) {
                            gte("expected_shifts.shift_date", startDate.toString())
                        }
                        if (endDate != null) {
                            lte("expected_shifts.shift_date", endDate.toString())
                        }
                    }
                    order("expected_shifts.shift_date", Order.DESCENDING)
                }
                .decodeList<ShiftEntry>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getShiftEntry(entryId: String): ShiftEntry? {
        return try {
            supabaseClient
                .from("shift_entries")
                .select {
                    filter {
                        eq("id", entryId)
                    }
                }
                .decodeSingleOrNull<ShiftEntry>()
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun getShiftEntryByShiftId(shiftId: String): ShiftEntry? {
        return try {
            supabaseClient
                .from("shift_entries")
                .select {
                    filter {
                        eq("shift_id", shiftId)
                    }
                }
                .decodeSingleOrNull<ShiftEntry>()
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun createShiftEntry(entry: ShiftEntry): Result<ShiftEntry> {
        return try {
            val createdEntry = supabaseClient
                .from("shift_entries")
                .insert(entry) {
                    select()
                }
                .decodeSingle<ShiftEntry>()
            Result.success(createdEntry)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun createShiftEntryWithSnapshots(
        entry: ShiftEntry,
        hourlyRate: Double,
        deductionPercentage: Double
    ): Result<ShiftEntry> {
        return try {
            // Calculate snapshot values
            val grossIncome = entry.actualHours * hourlyRate
            val totalIncome = grossIncome + entry.totalTipIncome
            val deductions = grossIncome * (deductionPercentage / 100.0)
            val netIncome = totalIncome - deductions

            // Create entry with snapshot fields populated
            val entryWithSnapshots = entry.copy(
                hourlyRate = hourlyRate,
                grossIncome = grossIncome,
                totalIncome = totalIncome,
                netIncome = netIncome,
                deductionPercentage = deductionPercentage
            )

            val createdEntry = supabaseClient
                .from("shift_entries")
                .insert(entryWithSnapshots) {
                    select()
                }
                .decodeSingle<ShiftEntry>()
            Result.success(createdEntry)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateShiftEntry(entry: ShiftEntry): Result<ShiftEntry> {
        return try {
            val updatedEntry = supabaseClient
                .from("shift_entries")
                .update(entry) {
                    filter {
                        eq("id", entry.id)
                    }
                    select()
                }
                .decodeSingle<ShiftEntry>()
            Result.success(updatedEntry)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateShiftEntryWithSnapshots(
        entry: ShiftEntry,
        hourlyRate: Double,
        deductionPercentage: Double
    ): Result<ShiftEntry> {
        return try {
            // Calculate snapshot values
            val grossIncome = entry.actualHours * hourlyRate
            val totalIncome = grossIncome + entry.totalTipIncome
            val deductions = grossIncome * (deductionPercentage / 100.0)
            val netIncome = totalIncome - deductions

            // Update entry with snapshot fields populated
            val entryWithSnapshots = entry.copy(
                hourlyRate = hourlyRate,
                grossIncome = grossIncome,
                totalIncome = totalIncome,
                netIncome = netIncome,
                deductionPercentage = deductionPercentage
            )

            val updatedEntry = supabaseClient
                .from("shift_entries")
                .update(entryWithSnapshots) {
                    filter {
                        eq("id", entry.id)
                    }
                    select()
                }
                .decodeSingle<ShiftEntry>()
            Result.success(updatedEntry)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteShiftEntry(entryId: String): Result<Unit> {
        return try {
            supabaseClient
                .from("shift_entries")
                .delete {
                    filter {
                        eq("id", entryId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteShiftEntryByShiftId(shiftId: String): Result<Unit> {
        return try {
            supabaseClient
                .from("shift_entries")
                .delete {
                    filter {
                        eq("shift_id", shiftId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getEntriesForDate(userId: String, date: LocalDate): List<ShiftEntry> {
        return try {
            supabaseClient
                .from("shift_entries")
                .select(columns = io.github.jan.supabase.postgrest.query.Columns.raw("*, expected_shifts!inner(shift_date)")) {
                    filter {
                        eq("user_id", userId)
                        eq("expected_shifts.shift_date", date.toString())
                    }
                }
                .decodeList<ShiftEntry>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getEntriesForWeek(userId: String, weekStart: LocalDate): List<ShiftEntry> {
        val weekEnd = weekStart.plus(DatePeriod(days = 6))
        return getShiftEntries(userId, weekStart, weekEnd)
    }

    override suspend fun getEntriesForMonth(userId: String, year: Int, month: Int): List<ShiftEntry> {
        val startDate = LocalDate(year, month, 1)
        val endDate = LocalDate(year, month, startDate.monthNumber).let {
            LocalDate(year, month, it.dayOfMonth)
        }
        return getShiftEntries(userId, startDate, endDate)
    }

    override suspend fun getTotalIncome(userId: String, startDate: LocalDate, endDate: LocalDate): Double {
        return try {
            val entries = getShiftEntries(userId, startDate, endDate)
            entries.sumOf { it.tips + it.other - it.cashOut }
        } catch (e: Exception) {
            0.0
        }
    }

    override suspend fun getTotalTips(userId: String, startDate: LocalDate, endDate: LocalDate): Double {
        return try {
            val entries = getShiftEntries(userId, startDate, endDate)
            entries.sumOf { it.tips }
        } catch (e: Exception) {
            0.0
        }
    }

    override suspend fun getTotalSales(userId: String, startDate: LocalDate, endDate: LocalDate): Double {
        return try {
            val entries = getShiftEntries(userId, startDate, endDate)
            entries.sumOf { it.sales }
        } catch (e: Exception) {
            0.0
        }
    }

    override suspend fun getTotalHours(userId: String, startDate: LocalDate, endDate: LocalDate): Double {
        return try {
            val entries = getShiftEntries(userId, startDate, endDate)
            entries.sumOf { it.actualHours }
        } catch (e: Exception) {
            0.0
        }
    }

    override suspend fun getAverageTipPercentage(userId: String, startDate: LocalDate, endDate: LocalDate): Double {
        return try {
            val entries = getShiftEntries(userId, startDate, endDate).filter { it.sales > 0 }
            if (entries.isEmpty()) return 0.0

            entries.map { it.tipPercentage }.average()
        } catch (e: Exception) {
            0.0
        }
    }

    override suspend fun getAverageHourlyEarnings(userId: String, startDate: LocalDate, endDate: LocalDate): Double {
        return try {
            val entries = getShiftEntries(userId, startDate, endDate)
            val totalHours = entries.sumOf { it.actualHours }
            val totalEarnings = entries.sumOf { it.totalTipIncome }

            if (totalHours > 0) totalEarnings / totalHours else 0.0
        } catch (e: Exception) {
            0.0
        }
    }

    override fun observeShiftEntries(userId: String): Flow<List<ShiftEntry>> = flow {
        emit(getShiftEntries(userId))
    }

    override fun observeEntriesForShift(shiftId: String): Flow<ShiftEntry?> = flow {
        emit(getShiftEntryByShiftId(shiftId))
    }
}