package com.protip365.app.data.repository

import com.protip365.app.data.models.Entry
import com.protip365.app.data.models.Shift
import com.protip365.app.domain.repository.ShiftRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.PostgresAction
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.datetime.LocalDate
import javax.inject.Inject

class ShiftRepositoryImpl @Inject constructor(
    private val supabaseClient: SupabaseClient
) : ShiftRepository {

    override suspend fun getShifts(
        userId: String,
        startDate: LocalDate?,
        endDate: LocalDate?
    ): List<Shift> {
        return try {
            supabaseClient
                .from("shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        startDate?.let { gte("shift_date", it.toString()) }
                        endDate?.let { lte("shift_date", it.toString()) }
                    }
                    order("shift_date", Order.DESCENDING)
                }
                .decodeList<Shift>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getShift(shiftId: String): Shift? {
        return try {
            supabaseClient
                .from("shifts")
                .select {
                    filter {
                        eq("id", shiftId)
                    }
                }
                .decodeSingleOrNull<Shift>()
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun createShift(shift: Shift): Result<Unit> {
        return try {
            supabaseClient
                .from("shifts")
                .insert(shift)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateShift(shift: Shift): Result<Unit> {
        return try {
            supabaseClient
                .from("shifts")
                .update(shift) {
                    filter {
                        eq("id", shift.id)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteShift(shiftId: String): Result<Unit> {
        return try {
            supabaseClient
                .from("shifts")
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

    override suspend fun getEntries(
        userId: String,
        startDate: LocalDate?,
        endDate: LocalDate?
    ): List<Entry> {
        return try {
            supabaseClient
                .from("entries")
                .select {
                    filter {
                        eq("user_id", userId)
                        startDate?.let { gte("entry_date", it.toString()) }
                        endDate?.let { lte("entry_date", it.toString()) }
                    }
                    order("entry_date", Order.DESCENDING)
                }
                .decodeList<Entry>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getEntry(entryId: String): Entry? {
        return try {
            supabaseClient
                .from("entries")
                .select()
                .decodeSingleOrNull<Entry>()
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun createEntry(entry: Entry): Result<Unit> {
        return try {
            supabaseClient
                .from("entries")
                .insert(entry)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateEntry(entry: Entry): Result<Unit> {
        return try {
            supabaseClient
                .from("entries")
                .update(entry) {
                    filter {
                        eq("id", entry.id)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteEntry(entryId: String): Result<Unit> {
        return try {
            supabaseClient
                .from("entries")
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

    override fun observeShifts(userId: String): Flow<List<Shift>> {
        // TODO: Implement realtime subscription
        return flow { emit(emptyList()) }
    }

    override fun observeEntries(userId: String): Flow<List<Entry>> {
        // TODO: Implement realtime subscription
        return flow { emit(emptyList()) }
    }
}