package com.protip365.app.domain.repository

import com.protip365.app.data.models.Entry
import com.protip365.app.data.models.Shift
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.LocalDate

interface ShiftRepository {
    suspend fun getShifts(userId: String, startDate: LocalDate? = null, endDate: LocalDate? = null): List<Shift>
    suspend fun getShift(shiftId: String): Shift?
    suspend fun createShift(shift: Shift): Result<Unit>
    suspend fun updateShift(shift: Shift): Result<Unit>
    suspend fun deleteShift(shiftId: String): Result<Unit>

    suspend fun getEntries(userId: String, startDate: LocalDate? = null, endDate: LocalDate? = null): List<Entry>
    suspend fun getEntry(entryId: String): Entry?
    suspend fun createEntry(entry: Entry): Result<Unit>
    suspend fun updateEntry(entry: Entry): Result<Unit>
    suspend fun deleteEntry(entryId: String): Result<Unit>

    fun observeShifts(userId: String): Flow<List<Shift>>
    fun observeEntries(userId: String): Flow<List<Entry>>
}