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
        val success = securityManager.clearPin()
        if (success) Result.success(Unit) else Result.failure(Exception("Failed to clear PIN"))
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun isPinSet(): Boolean {
        return securityManager.isPinSet()
    }

    override suspend fun enableBiometric(): Result<Unit> = try {
        val success = securityManager.enableBiometric()
        if (success) Result.success(Unit) else Result.failure(Exception("Failed to enable biometric"))
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun disableBiometric(): Result<Unit> = try {
        val success = securityManager.disableBiometric()
        if (success) Result.success(Unit) else Result.failure(Exception("Failed to disable biometric"))
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun isBiometricEnabled(): Boolean {
        return securityManager.isBiometricEnabled()
    }

    override suspend fun isBiometricAvailable(): Boolean {
        val biometricManager = BiometricManager.from(context)
        return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS
    }

    override suspend fun setAutoLockMinutes(minutes: Int): Result<Unit> = try {
        val success = securityManager.setAutoLockMinutes(minutes)
        if (success) Result.success(Unit) else Result.failure(Exception("Failed to set auto-lock minutes"))
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getAutoLockMinutes(): Int {
        return securityManager.getAutoLockMinutes()
    }

    override suspend fun setLastActiveTime(timestamp: Long): Result<Unit> = try {
        val success = securityManager.setLastActiveTime(timestamp)
        if (success) Result.success(Unit) else Result.failure(Exception("Failed to set last active time"))
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getLastActiveTime(): Long {
        return securityManager.getLastActiveTime()
    }

    override suspend fun shouldShowLockScreen(): Boolean {
        return securityManager.shouldShowLockScreen()
    }

    override suspend fun resetSecuritySettings(): Result<Unit> = try {
        val success = securityManager.resetSecuritySettings()
        if (success) Result.success(Unit) else Result.failure(Exception("Failed to reset security settings"))
    } catch (e: Exception) {
        Result.failure(e)
    }
}