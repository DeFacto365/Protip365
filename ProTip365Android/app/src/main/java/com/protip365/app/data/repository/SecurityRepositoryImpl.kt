package com.protip365.app.data.repository

import android.content.Context
import androidx.biometric.BiometricManager
import com.protip365.app.domain.repository.SecurityRepository
import com.protip365.app.presentation.security.SecurityManager
import javax.inject.Inject

class SecurityRepositoryImpl @Inject constructor(
    private val context: Context,
    private val securityManager: SecurityManager
) : SecurityRepository {

    override suspend fun setPin(pin: String): Result<Unit> = try {
        val success = securityManager.setPIN(pin)
        if (success) Result.success(Unit) else Result.failure(Exception("Failed to set PIN"))
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun verifyPin(pin: String): Result<Boolean> = try {
        val isValid = securityManager.verifyPIN(pin)
        Result.success(isValid)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun clearPin(): Result<Unit> = try {
        // TODO: Add clearPin method to SecurityManager
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun isPinSet(): Boolean {
        // TODO: Add isPinSet method to SecurityManager
        return false
    }

    override suspend fun enableBiometric(): Result<Unit> = try {
        // TODO: Add enableBiometric method to SecurityManager
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun disableBiometric(): Result<Unit> = try {
        // TODO: Add disableBiometric method to SecurityManager
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun isBiometricEnabled(): Boolean {
        // TODO: Add isBiometricEnabled method to SecurityManager
        return false
    }

    override suspend fun isBiometricAvailable(): Boolean {
        val biometricManager = BiometricManager.from(context)
        return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS
    }

    override suspend fun setAutoLockMinutes(minutes: Int): Result<Unit> = try {
        // TODO: Add setAutoLockMinutes method to SecurityManager
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getAutoLockMinutes(): Int {
        // TODO: Add getAutoLockMinutes method to SecurityManager
        return 5 // Default 5 minutes
    }

    override suspend fun setLastActiveTime(timestamp: Long): Result<Unit> = try {
        // TODO: Add setLastActiveTime method to SecurityManager
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getLastActiveTime(): Long {
        // TODO: Add getLastActiveTime method to SecurityManager
        return System.currentTimeMillis()
    }

    override suspend fun shouldShowLockScreen(): Boolean {
        // TODO: Add shouldShowLockScreen method to SecurityManager
        return false
    }

    override suspend fun resetSecuritySettings(): Result<Unit> = try {
        // TODO: Add resetSecuritySettings method to SecurityManager
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }
}