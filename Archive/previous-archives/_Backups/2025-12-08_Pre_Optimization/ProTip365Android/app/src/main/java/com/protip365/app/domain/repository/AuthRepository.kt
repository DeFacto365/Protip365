package com.protip365.app.domain.repository

import com.protip365.app.data.models.UserProfile
import kotlinx.coroutines.flow.Flow

interface AuthRepository {
    suspend fun signUp(email: String, password: String): Result<UserProfile>
    suspend fun signIn(email: String, password: String): Result<UserProfile>
    suspend fun signInWithGoogle(): Result<UserProfile>
    suspend fun signInWithApple(): Result<UserProfile>
    suspend fun signOut(): Result<Unit>
    suspend fun resetPassword(email: String): Result<Unit>
    suspend fun getCurrentUser(): UserProfile?
    suspend fun isLoggedIn(): Boolean
    fun observeAuthState(): Flow<Boolean>
    suspend fun deleteAccount(): Result<Unit>
    suspend fun checkEmailExists(email: String): Boolean
}