package com.protip365.app.data.repository

import android.content.Context
import android.content.SharedPreferences
import com.protip365.app.data.models.UserProfile
import com.protip365.app.domain.repository.UserRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.PostgresAction
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class UserRepositoryImpl @Inject constructor(
    private val supabaseClient: SupabaseClient,
    @ApplicationContext private val context: Context
) : UserRepository {

    private val prefs: SharedPreferences = context.getSharedPreferences("protip365_prefs", Context.MODE_PRIVATE)

    override suspend fun getCurrentUser(): Flow<UserProfile?> = flow {
        val userId = getCurrentUserId()
        if (userId != null) {
            emit(getUserProfile(userId))
        } else {
            emit(null)
        }
    }

    override suspend fun getCurrentUserId(): String? {
        return try {
            supabaseClient.auth.currentUserOrNull()?.id
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun getUserProfile(userId: String): UserProfile? {
        return try {
            supabaseClient
                .from("users_profile")
                .select {
                    filter {
                        eq("user_id", userId)
                    }
                }
                .decodeSingleOrNull<UserProfile>()
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun updateUserProfile(userProfile: UserProfile): Result<Unit> {
        return try {
            supabaseClient
                .from("users_profile")
                .update(userProfile) {
                    filter {
                        eq("user_id", userProfile.userId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun createUserProfile(userProfile: UserProfile): Result<Unit> {
        return try {
            supabaseClient
                .from("users_profile")
                .insert(userProfile)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun observeUserProfile(userId: String): Flow<UserProfile?> {
        return flow {
            emit(getUserProfile(userId))
        }
    }

    override suspend fun getLanguagePreference(): String? {
        // First try to get from user profile if authenticated
        val currentUser = supabaseClient.auth.currentUserOrNull()
        if (currentUser != null) {
            val profile = getUserProfile(currentUser.id)
            if (profile != null) {
                return profile.preferredLanguage
            }
        }
        // Fall back to local preference
        return prefs.getString("language", "en")
    }

    override suspend fun setLanguagePreference(language: String) {
        // Save to local preferences
        prefs.edit().putString("language", language).apply()

        // If authenticated, update user profile
        val currentUser = supabaseClient.auth.currentUserOrNull()
        if (currentUser != null) {
            val profile = getUserProfile(currentUser.id)
            if (profile != null) {
                updateUserProfile(profile.copy(preferredLanguage = language))
            }
        }
    }

    override suspend fun updateUserProfile(updates: Map<String, Any?>): Result<Unit> {
        return try {
            val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("User not authenticated"))

            // Check if profile exists first
            val existingProfile = getUserProfile(userId)

            if (existingProfile == null) {
                // Profile doesn't exist, create it with the updates
                val newProfile = UserProfile(
                    userId = userId,
                    name = updates["name"] as? String
                )
                return createUserProfile(newProfile)
            }

            // Profile exists, update it
            supabaseClient
                .from("users_profile")
                .update(updates) {
                    filter {
                        eq("user_id", userId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateUserMetadata(metadata: Map<String, Any?>): Result<Unit> {
        return try {
            val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("User not authenticated"))

            // Get current profile
            val currentProfile = getUserProfile(userId) ?: return Result.failure(Exception("Profile not found"))

            // Merge metadata
            val updatedMetadata = currentProfile.metadata?.toMutableMap() ?: mutableMapOf()
            updatedMetadata.putAll(metadata)

            // Update profile with new metadata
            supabaseClient
                .from("users_profile")
                .update(mapOf("metadata" to updatedMetadata)) {
                    filter {
                        eq("user_id", userId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun setOnboardingCompleted(completed: Boolean): Result<Unit> {
        return try {
            val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("User not authenticated"))

            // Get current profile
            val currentProfile = getUserProfile(userId) ?: return Result.failure(Exception("Profile not found"))

            // Update metadata
            val updatedMetadata = currentProfile.metadata?.toMutableMap() ?: mutableMapOf()
            updatedMetadata["onboarding_completed"] = completed

            // Update profile
            supabaseClient
                .from("users_profile")
                .update(mapOf("metadata" to updatedMetadata)) {
                    filter {
                        eq("user_id", userId)
                    }
                }

            // Also save locally
            prefs.edit().putBoolean("onboarding_completed", completed).apply()

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}