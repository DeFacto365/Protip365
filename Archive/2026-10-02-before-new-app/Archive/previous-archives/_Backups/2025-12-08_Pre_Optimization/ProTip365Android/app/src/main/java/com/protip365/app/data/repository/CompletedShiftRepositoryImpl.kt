package com.protip365.app.data.repository

import com.protip365.app.data.models.CompletedShift
import com.protip365.app.data.models.ExpectedShift
import com.protip365.app.data.models.ShiftEntry
import com.protip365.app.domain.repository.CompletedShiftRepository
import com.protip365.app.domain.repository.DashboardStats
import com.protip365.app.domain.repository.EmployerRepository
import com.protip365.app.domain.repository.ExpectedShiftRepository
import com.protip365.app.domain.repository.ShiftEntryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.datetime.LocalDate
import kotlinx.datetime.plus
import kotlinx.datetime.DatePeriod
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CompletedShiftRepositoryImpl @Inject constructor(
    private val expectedShiftRepository: ExpectedShiftRepository,
    private val shiftEntryRepository: ShiftEntryRepository,
    private val employerRepository: EmployerRepository
) : CompletedShiftRepository {

    override suspend fun getCompletedShifts(
        userId: String,
        startDate: LocalDate?,
        endDate: LocalDate?,
        includeUnworked: Boolean
    ): List<CompletedShift> {
        return try {
            val expectedShifts = expectedShiftRepository.getExpectedShifts(userId, startDate, endDate)
            val shiftEntries = shiftEntryRepository.getShiftEntries(userId, startDate, endDate)
            val employers = employerRepository.getEmployers(userId)

            // Create a map for quick lookup
            val entriesByShiftId = shiftEntries.associateBy { it.shiftId }
            val employersById = employers.associateBy { it.id }

            expectedShifts.mapNotNull { expectedShift ->
                val entry = entriesByShiftId[expectedShift.id]
                val employer = expectedShift.employerId?.let { employersById[it] }

                // Include shift if it has entry data OR if includeUnworked is true
                if (entry != null || includeUnworked) {
                    CompletedShift(expectedShift, entry, employer)
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getCompletedShift(shiftId: String): CompletedShift? {
        return try {
            val expectedShift = expectedShiftRepository.getExpectedShift(shiftId) ?: return null
            val shiftEntry = shiftEntryRepository.getShiftEntryByShiftId(shiftId)
            val employer = expectedShift.employerId?.let { employerRepository.getEmployer(it) }

            CompletedShift(expectedShift, shiftEntry, employer)
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun createShift(expectedShift: ExpectedShift, shiftEntry: ShiftEntry?): Result<CompletedShift> {
        return try {
            // Create expected shift first
            val createdExpectedShift = expectedShiftRepository.createExpectedShift(expectedShift)
                .getOrThrow()

            // Create entry if provided
            val createdEntry = shiftEntry?.let { entry ->
                val entryWithShiftId = entry.copy(shiftId = createdExpectedShift.id)
                shiftEntryRepository.createShiftEntry(entryWithShiftId).getOrThrow()
            }

            // Update shift status to completed if entry was created
            if (createdEntry != null) {
                expectedShiftRepository.updateShiftStatus(createdExpectedShift.id, "completed")
            }

            val employer = createdExpectedShift.employerId?.let {
                employerRepository.getEmployer(it)
            }

            val completedShift = CompletedShift(createdExpectedShift, createdEntry, employer)
            Result.success(completedShift)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateShift(completedShift: CompletedShift): Result<CompletedShift> {
        return try {
            // Update expected shift
            val updatedExpectedShift = expectedShiftRepository.updateExpectedShift(completedShift.expectedShift)
                .getOrThrow()

            // Update or create entry
            val updatedEntry = completedShift.shiftEntry?.let { entry ->
                val existingEntry = shiftEntryRepository.getShiftEntryByShiftId(updatedExpectedShift.id)
                if (existingEntry != null) {
                    shiftEntryRepository.updateShiftEntry(entry).getOrThrow()
                } else {
                    shiftEntryRepository.createShiftEntry(entry).getOrThrow()
                }
            }

            // Update shift status based on entry existence
            val newStatus = when {
                updatedEntry != null -> "completed"
                completedShift.expectedShift.status == "missed" -> "missed"
                else -> "planned"
            }
            expectedShiftRepository.updateShiftStatus(updatedExpectedShift.id, newStatus)

            val employer = updatedExpectedShift.employerId?.let {
                employerRepository.getEmployer(it)
            }

            val updated = CompletedShift(updatedExpectedShift, updatedEntry, employer)
            Result.success(updated)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteShift(shiftId: String): Result<Unit> {
        return try {
            // Delete entry first (if exists) due to foreign key constraint
            shiftEntryRepository.deleteShiftEntryByShiftId(shiftId)
            // Then delete expected shift
            expectedShiftRepository.deleteExpectedShift(shiftId).getOrThrow()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun completeShift(shiftId: String, shiftEntry: ShiftEntry): Result<CompletedShift> {
        return try {
            val expectedShift = expectedShiftRepository.getExpectedShift(shiftId)
                ?: return Result.failure(Exception("Expected shift not found"))

            // Create the shift entry
            val entryWithShiftId = shiftEntry.copy(shiftId = shiftId)
            val createdEntry = shiftEntryRepository.createShiftEntry(entryWithShiftId).getOrThrow()

            // Update shift status to completed
            expectedShiftRepository.updateShiftStatus(shiftId, "completed")

            val employer = expectedShift.employerId?.let {
                employerRepository.getEmployer(it)
            }

            val completedShift = CompletedShift(expectedShift, createdEntry, employer)
            Result.success(completedShift)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun markShiftAsMissed(shiftId: String): Result<Unit> {
        return expectedShiftRepository.updateShiftStatus(shiftId, "missed")
    }

    override suspend fun getWorkedShifts(
        userId: String,
        startDate: LocalDate?,
        endDate: LocalDate?
    ): List<CompletedShift> {
        return getCompletedShifts(userId, startDate, endDate, false)
    }

    override suspend fun getPlannedShifts(userId: String): List<CompletedShift> {
        return try {
            val plannedShifts = expectedShiftRepository.getPlannedShifts(userId)
            val employers = employerRepository.getEmployers(userId)
            val employersById = employers.associateBy { it.id }

            plannedShifts.map { shift ->
                val employer = shift.employerId?.let { employersById[it] }
                CompletedShift(shift, null, employer)
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getMissedShifts(userId: String): List<CompletedShift> {
        return try {
            val missedShifts = expectedShiftRepository.getMissedShifts(userId)
            val employers = employerRepository.getEmployers(userId)
            val employersById = employers.associateBy { it.id }

            missedShifts.map { shift ->
                val employer = shift.employerId?.let { employersById[it] }
                CompletedShift(shift, null, employer)
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getShiftsForDate(userId: String, date: LocalDate): List<CompletedShift> {
        return getCompletedShifts(userId, date, date, true)
    }

    override suspend fun getShiftsForWeek(userId: String, weekStart: LocalDate): List<CompletedShift> {
        val weekEnd = weekStart.plus(DatePeriod(days = 6))
        return getCompletedShifts(userId, weekStart, weekEnd, true)
    }

    override suspend fun getShiftsForMonth(userId: String, year: Int, month: Int): List<CompletedShift> {
        val startDate = LocalDate(year, month, 1)
        val endDate = LocalDate(year, month, startDate.monthNumber).let {
            LocalDate(year, month, it.dayOfMonth)
        }
        return getCompletedShifts(userId, startDate, endDate, true)
    }

    override suspend fun getDashboardStats(
        userId: String,
        startDate: LocalDate,
        endDate: LocalDate
    ): DashboardStats {
        return try {
            val completedShifts = getCompletedShifts(userId, startDate, endDate, true)
            val workedShifts = completedShifts.filter { it.isWorked }

            val totalShifts = completedShifts.size
            val workedCount = workedShifts.size
            val missedCount = completedShifts.count { it.status == "missed" }

            val totalHours = workedShifts.sumOf { it.hours }
            val totalTips = workedShifts.sumOf { it.tips }
            val totalSales = workedShifts.sumOf { it.sales }
            val totalWages = workedShifts.sumOf { it.wages }
            val totalEarnings = totalWages + totalTips

            val averageTipPercentage = if (workedShifts.isNotEmpty() && totalSales > 0) {
                workedShifts.filter { it.sales > 0 }.map { it.tipPercentage }.average()
            } else 0.0

            val averageHourlyRate = if (workedShifts.isNotEmpty()) {
                workedShifts.map { it.expectedShift.hourlyRate }.average()
            } else 0.0

            val effectiveHourlyRate = if (totalHours > 0) {
                totalEarnings / totalHours
            } else 0.0

            DashboardStats(
                totalShifts = totalShifts,
                workedShifts = workedCount,
                missedShifts = missedCount,
                totalHours = totalHours,
                totalEarnings = totalEarnings,
                totalWages = totalWages,
                totalTips = totalTips,
                totalSales = totalSales,
                averageTipPercentage = averageTipPercentage,
                averageHourlyRate = averageHourlyRate,
                effectiveHourlyRate = effectiveHourlyRate
            )
        } catch (e: Exception) {
            DashboardStats(0, 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        }
    }

    override fun observeCompletedShifts(userId: String): Flow<List<CompletedShift>> {
        return combine(
            expectedShiftRepository.observeExpectedShifts(userId),
            shiftEntryRepository.observeShiftEntries(userId)
        ) { expectedShifts, shiftEntries ->
            val entriesByShiftId = shiftEntries.associateBy { it.shiftId }
            val employers = employerRepository.getEmployers(userId)
            val employersById = employers.associateBy { it.id }

            expectedShifts.map { expectedShift ->
                val entry = entriesByShiftId[expectedShift.id]
                val employer = expectedShift.employerId?.let { employersById[it] }
                CompletedShift(expectedShift, entry, employer)
            }
        }
    }

    override fun observeShiftsForDate(userId: String, date: LocalDate): Flow<List<CompletedShift>> {
        return combine(
            expectedShiftRepository.observeShiftsForDate(userId, date),
            shiftEntryRepository.observeShiftEntries(userId)
        ) { expectedShifts, allEntries ->
            val entriesByShiftId = allEntries.associateBy { it.shiftId }
            val employers = employerRepository.getEmployers(userId)
            val employersById = employers.associateBy { it.id }

            expectedShifts.map { expectedShift ->
                val entry = entriesByShiftId[expectedShift.id]
                val employer = expectedShift.employerId?.let { employersById[it] }
                CompletedShift(expectedShift, entry, employer)
            }
        }
    }

    override fun observeDashboardStats(
        userId: String,
        startDate: LocalDate,
        endDate: LocalDate
    ): Flow<DashboardStats> {
        return observeCompletedShifts(userId).map { allShifts ->
            // Filter shifts by date range
            val shiftsInRange = allShifts.filter { shift ->
                val shiftDate = LocalDate.parse(shift.shiftDate)
                shiftDate >= startDate && shiftDate <= endDate
            }

            val workedShifts = shiftsInRange.filter { it.isWorked }

            // Calculate stats (same logic as getDashboardStats)
            val totalShifts = shiftsInRange.size
            val workedCount = workedShifts.size
            val missedCount = shiftsInRange.count { it.status == "missed" }

            val totalHours = workedShifts.sumOf { it.hours }
            val totalTips = workedShifts.sumOf { it.tips }
            val totalSales = workedShifts.sumOf { it.sales }
            val totalWages = workedShifts.sumOf { it.wages }
            val totalEarnings = totalWages + totalTips

            val averageTipPercentage = if (workedShifts.isNotEmpty() && totalSales > 0) {
                workedShifts.filter { it.sales > 0 }.map { it.tipPercentage }.average()
            } else 0.0

            val averageHourlyRate = if (workedShifts.isNotEmpty()) {
                workedShifts.map { it.expectedShift.hourlyRate }.average()
            } else 0.0

            val effectiveHourlyRate = if (totalHours > 0) {
                totalEarnings / totalHours
            } else 0.0

            DashboardStats(
                totalShifts = totalShifts,
                workedShifts = workedCount,
                missedShifts = missedCount,
                totalHours = totalHours,
                totalEarnings = totalEarnings,
                totalWages = totalWages,
                totalTips = totalTips,
                totalSales = totalSales,
                averageTipPercentage = averageTipPercentage,
                averageHourlyRate = averageHourlyRate,
                effectiveHourlyRate = effectiveHourlyRate
            )
        }
    }
}