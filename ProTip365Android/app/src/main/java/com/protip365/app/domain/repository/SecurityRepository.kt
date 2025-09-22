package com.protip365.app.domain.repository

interface SecurityRepository {
    suspend fun setPin(pin: String): Result<Unit>
    suspend fun verifyPin(pin: String): Result<Boolean>
    suspend fun clearPin(): Result<Unit>
    suspend fun isPinSet(): Boolean

    suspend fun enableBiometric(): Result<Unit>
    suspend fun disableBiometric(): Result<Unit>
    suspend fun isBiometricEnabled(): Boolean
    suspend fun isBiometricAvailable(): Boolean

    suspend fun setAutoLockMinutes(minutes: Int): Result<Unit>
    suspend fun getAutoLockMinutes(): Int

    suspend fun setLastActiveTime(timestamp: Long): Result<Unit>
    suspend fun getLastActiveTime(): Long

    suspend fun shouldShowLockScreen(): Boolean
    suspend fun resetSecuritySettings(): Result<Unit>
}