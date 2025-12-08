package com.protip365.app.domain.repository

import com.protip365.app.data.models.UserProfile
import kotlinx.coroutines.flow.Flow

interface UserRepository {
    suspend fun getCurrentUser(): Flow<UserProfile?>
    suspend fun getCurrentUserId(): String?
    suspend fun getUserProfile(userId: String): UserProfile?
    suspend fun updateUserProfile(userProfile: UserProfile): Result<Unit>
    suspend fun updateUserProfile(updates: Map<String, Any?>): Result<Unit>
    suspend fun updateUserMetadata(metadata: Map<String, Any?>): Result<Unit>
    suspend fun createUserProfile(userProfile: UserProfile): Result<Unit>
    fun observeUserProfile(userId: String): Flow<UserProfile?>
    suspend fun getLanguagePreference(): String?
    suspend fun setLanguagePreference(language: String)
    suspend fun setOnboardingCompleted(completed: Boolean): Result<Unit>
}