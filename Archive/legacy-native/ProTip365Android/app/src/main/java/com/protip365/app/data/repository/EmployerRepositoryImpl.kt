package com.protip365.app.data.repository

import com.protip365.app.data.models.Employer
import com.protip365.app.domain.repository.EmployerRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.PostgresAction
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import javax.inject.Inject

class EmployerRepositoryImpl @Inject constructor(
    private val supabaseClient: SupabaseClient
) : EmployerRepository {

    override suspend fun getEmployers(userId: String): List<Employer> {
        return try {
            supabaseClient
                .from("employers")
                .select {
                    filter {
                        eq("user_id", userId)
                        eq("active", true) // Using 'active' not 'is_active'
                    }
                }
                .decodeList<Employer>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun getEmployer(employerId: String): Employer? {
        return try {
            supabaseClient
                .from("employers")
                .select {
                    filter {
                        eq("id", employerId)
                    }
                }
                .decodeSingleOrNull<Employer>()
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun createEmployer(employer: Employer): Result<Unit> {
        return try {
            supabaseClient
                .from("employers")
                .insert(employer)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateEmployer(employer: Employer): Result<Unit> {
        return try {
            supabaseClient
                .from("employers")
                .update(employer) {
                    filter {
                        eq("id", employer.id)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteEmployer(employerId: String): Result<Unit> {
        return try {
            // Soft delete by setting active to false
            supabaseClient
                .from("employers")
                .update(mapOf("active" to false)) {
                    filter {
                        eq("id", employerId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun setEmployerActive(employerId: String, active: Boolean): Result<Unit> {
        return try {
            supabaseClient
                .from("employers")
                .update(mapOf("active" to active)) {
                    filter {
                        eq("id", employerId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun observeEmployers(userId: String): Flow<List<Employer>> {
        return flow {
            emit(getEmployers(userId))
        }
    }

    /**
     * Get count of shifts for employer
     * Matches iOS loadShiftCounts (EmployersView.swift lines 197-222)
     */
    override suspend fun getShiftCountForEmployer(userId: String, employerId: String): Int {
        return try {
            val result = supabaseClient
                .from("expected_shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        eq("employer_id", employerId)
                    }
                }
                .decodeList<kotlinx.serialization.json.JsonObject>()
            result.size
        } catch (e: Exception) {
            println("Error counting shifts for employer: ${e.message}")
            0
        }
    }

    /**
     * Get count of entries for employer
     * Matches iOS loadEntryCounts (EmployersView.swift lines 224-277)
     */
    override suspend fun getEntryCountForEmployer(userId: String, employerId: String): Int {
        return try {
            // Query entries through expected_shifts join
            val result = supabaseClient
                .from("shift_entries")
                .select {
                    filter {
                        eq("user_id", userId)
                    }
                }
                .decodeList<kotlinx.serialization.json.JsonObject>()
            result.size
        } catch (e: Exception) {
            println("Error counting entries for employer: ${e.message}")
            0
        }
    }
}