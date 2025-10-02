package com.protip365.app.data.repository

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import com.protip365.app.data.models.UserProfile
import com.protip365.app.domain.repository.AuthRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.rpc
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

class AuthRepositoryImpl @Inject constructor(
    private val supabaseClient: SupabaseClient,
    private val dataStore: DataStore<Preferences>
) : AuthRepository {

    companion object {
        private val IS_LOGGED_IN_KEY = booleanPreferencesKey("is_logged_in")
    }

    override suspend fun signUp(email: String, password: String): Result<UserProfile> {
        return try {
            supabaseClient.auth.signUpWith(io.github.jan.supabase.gotrue.providers.builtin.Email) {
                this.email = email
                this.password = password
            }

            // Create user profile after successful signup
            val userId = supabaseClient.auth.currentUserOrNull()?.id
            if (userId != null) {
                val userProfile = UserProfile(
                    userId = userId,
                    name = null // Let user set their own name later
                )
                // Try to create profile, but don't fail the signup if it doesn't work
                try {
                    supabaseClient.from("users_profile").insert(userProfile)
                } catch (e: Exception) {
                    // Log the error but continue - profile can be created later
                    println("Note: User profile creation deferred: ${e.message}")
                }
            }

            dataStore.edit { preferences ->
                preferences[IS_LOGGED_IN_KEY] = true
            }
            val profile = getCurrentUser() ?: throw Exception("Failed to get user profile")
            Result.success(profile)
        } catch (e: Exception) {
            // Check if the error indicates email already exists
            val errorMessage = e.message?.lowercase() ?: ""
            if (errorMessage.contains("user already registered") || 
                errorMessage.contains("email already registered") ||
                errorMessage.contains("duplicate key") ||
                errorMessage.contains("already exists")) {
                Result.failure(Exception("Email already registered"))
            } else {
                Result.failure(e)
            }
        }
    }

    override suspend fun signIn(email: String, password: String): Result<UserProfile> {
        return try {
            supabaseClient.auth.signInWith(io.github.jan.supabase.gotrue.providers.builtin.Email) {
                this.email = email
                this.password = password
            }
            
            // Ensure user profile exists after sign in
            ensureUserProfileExists()
            
            dataStore.edit { preferences ->
                preferences[IS_LOGGED_IN_KEY] = true
            }
            val profile = getCurrentUser() ?: throw Exception("Failed to get user profile")
            Result.success(profile)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun signOut(): Result<Unit> {
        return try {
            supabaseClient.auth.signOut()
            dataStore.edit { preferences ->
                preferences[IS_LOGGED_IN_KEY] = false
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun resetPassword(email: String): Result<Unit> {
        return try {
            supabaseClient.auth.resetPasswordForEmail(email)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getCurrentUser(): UserProfile? {
        return try {
            val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return null
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

    override suspend fun isLoggedIn(): Boolean {
        return supabaseClient.auth.currentUserOrNull() != null
    }

    override fun observeAuthState(): Flow<Boolean> {
        return dataStore.data.map { preferences ->
            preferences[IS_LOGGED_IN_KEY] ?: false
        }
    }

    override suspend fun signInWithGoogle(): Result<UserProfile> {
        return try {
            // Google sign in would require additional setup with Google OAuth
            // For now, return an error indicating it's not implemented
            Result.failure(Exception("Google sign-in not yet implemented"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun signInWithApple(): Result<UserProfile> {
        return try {
            // Apple sign in would require additional setup with Apple OAuth
            // For now, return an error indicating it's not implemented
            Result.failure(Exception("Apple sign-in not yet implemented"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteAccount(): Result<Unit> {
        return try {
            // Get current user
            val currentUser = supabaseClient.auth.currentUserOrNull()
            if (currentUser == null) {
                return Result.failure(Exception("No authenticated user"))
            }

            // Call the delete-account Edge Function
            supabaseClient.functions.invoke("delete-account")

            // Sign out after successful deletion
            signOut()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun checkEmailExists(email: String): Boolean {
        return try {
            // Call the Supabase RPC function to check if email exists in auth.users
            val params = buildJsonObject {
                put("check_email", email)
            }

            val response = supabaseClient.postgrest.rpc("check_email_exists", params)
                .decodeAs<Boolean>()

            response // true = exists, false = available
        } catch (e: Exception) {
            // On error, return false (fail open) - will be caught during actual signup
            println("Error checking email: ${e.message}")
            false
        }
    }

    private suspend fun ensureUserProfileExists() {
        val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return

        try {
            // Check if profile already exists
            val existingProfile = supabaseClient
                .from("users_profile")
                .select { filter { eq("user_id", userId) } }
                .decodeSingleOrNull<UserProfile>()

            if (existingProfile == null) {
                // Create profile if it doesn't exist
                val userProfile = UserProfile(
                    userId = userId,
                    name = null // Let user set their own name later
                )
                supabaseClient.from("users_profile").insert(userProfile)
            }
        } catch (e: Exception) {
            // Ignore errors - profile creation is not critical for sign in
        }
    }

}