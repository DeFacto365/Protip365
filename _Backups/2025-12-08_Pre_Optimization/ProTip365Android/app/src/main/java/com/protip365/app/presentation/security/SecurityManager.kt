package com.protip365.app.presentation.security

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.IvParameterSpec
import android.util.Base64
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import javax.inject.Inject
import javax.inject.Singleton

enum class SecurityType {
    NONE,
    PIN,
    BIOMETRIC,
    BOTH
}

data class SecurityState(
    val currentSecurityType: SecurityType = SecurityType.NONE,
    val isUnlocked: Boolean = false,
    val showPINEntry: Boolean = false,
    val isBiometricAvailable: Boolean = false,
    val isPINSetup: Boolean = false,
    val error: String? = null
)

@Singleton
class SecurityManager @Inject constructor(
    private val context: Context
) {
    private val _state = MutableStateFlow(SecurityState())
    val state: StateFlow<SecurityState> = _state.asStateFlow()

    private val prefs: SharedPreferences = context.getSharedPreferences("security_prefs", Context.MODE_PRIVATE)
    private val keyStore: KeyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    init {
        checkBiometricAvailability()
        loadSecuritySettings()
    }

    private fun checkBiometricAvailability() {
        val biometricManager = BiometricManager.from(context)
        val isAvailable = when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
        
        _state.value = _state.value.copy(isBiometricAvailable = isAvailable)
    }

    private fun loadSecuritySettings() {
        val securityType = SecurityType.valueOf(
            prefs.getString("security_type", SecurityType.NONE.name) ?: SecurityType.NONE.name
        )
        val isPINSetup = prefs.getBoolean("pin_setup", false)
        
        _state.value = _state.value.copy(
            currentSecurityType = securityType,
            isPINSetup = isPINSetup
        )
    }

    fun setSecurityType(type: SecurityType) {
        _state.value = _state.value.copy(currentSecurityType = type)
        prefs.edit()
            .putString("security_type", type.name)
            .apply()
    }

    fun setPIN(pin: String): Boolean {
        return try {
            val encryptedPIN = encryptPIN(pin)
            prefs.edit()
                .putString("encrypted_pin", encryptedPIN)
                .putBoolean("pin_setup", true)
                .apply()
            
            _state.value = _state.value.copy(isPINSetup = true)
            true
        } catch (e: Exception) {
            _state.value = _state.value.copy(error = e.message)
            false
        }
    }

    fun verifyPIN(pin: String): Boolean {
        return try {
            val storedPIN = prefs.getString("encrypted_pin", null) ?: return false
            val decryptedPIN = decryptPIN(storedPIN)
            val isValid = pin == decryptedPIN
            
            if (isValid) {
                _state.value = _state.value.copy(
                    isUnlocked = true,
                    showPINEntry = false,
                    error = null
                )
            } else {
                _state.value = _state.value.copy(error = "Invalid PIN")
            }
            
            isValid
        } catch (e: Exception) {
            _state.value = _state.value.copy(error = e.message)
            false
        }
    }

    suspend fun authenticateWithBiometric(activity: FragmentActivity): Boolean {
        return suspendCancellableCoroutine { continuation ->
            val biometricPrompt = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity),
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        super.onAuthenticationSucceeded(result)
                        _state.value = _state.value.copy(
                            isUnlocked = true,
                            showPINEntry = false,
                            error = null
                        )
                        continuation.resume(true)
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        super.onAuthenticationError(errorCode, errString)
                        _state.value = _state.value.copy(
                            error = errString.toString(),
                            showPINEntry = _state.value.currentSecurityType == SecurityType.BOTH
                        )
                        continuation.resume(false)
                    }

                    override fun onAuthenticationFailed() {
                        super.onAuthenticationFailed()
                        _state.value = _state.value.copy(
                            error = "Authentication failed",
                            showPINEntry = _state.value.currentSecurityType == SecurityType.BOTH
                        )
                        continuation.resume(false)
                    }
                })

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle("ProTip365 Security")
                .setSubtitle("Use your biometric to unlock the app")
                .setNegativeButtonText("Cancel")
                .build()

            biometricPrompt.authenticate(promptInfo)
            
            continuation.invokeOnCancellation {
                biometricPrompt.cancelAuthentication()
            }
        }
    }

    fun lock() {
        _state.value = _state.value.copy(
            isUnlocked = false,
            showPINEntry = false
        )
    }

    fun showPINEntry() {
        _state.value = _state.value.copy(showPINEntry = true)
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }

    private fun encryptPIN(pin: String): String {
        val key = getOrCreateSecretKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        
        val iv = cipher.iv
        val encryptedBytes = cipher.doFinal(pin.toByteArray())
        
        val combined = iv + encryptedBytes
        return Base64.encodeToString(combined, Base64.DEFAULT)
    }

    private fun decryptPIN(encryptedPIN: String): String {
        val combined = Base64.decode(encryptedPIN, Base64.DEFAULT)
        val iv = combined.sliceArray(0..11) // First 12 bytes are IV
        val encryptedBytes = combined.sliceArray(12 until combined.size)
        
        val key = keyStore.getKey("ProTip365_PIN_Key", null) as SecretKey
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key, IvParameterSpec(iv))
        
        return String(cipher.doFinal(encryptedBytes))
    }

    private fun getOrCreateSecretKey(): SecretKey {
        val keyAlias = "ProTip365_PIN_Key"
        
        if (!keyStore.containsAlias(keyAlias)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setUserAuthenticationRequired(false)
                .build()
            
            keyGenerator.init(keyGenParameterSpec)
            keyGenerator.generateKey()
        }
        
        return keyStore.getKey(keyAlias, null) as SecretKey
    }

    fun changePIN(oldPIN: String, newPIN: String): Boolean {
        return if (verifyPIN(oldPIN)) {
            setPIN(newPIN)
        } else {
            _state.value = _state.value.copy(error = "Current PIN is incorrect")
            false
        }
    }

    fun removePIN(): Boolean {
        return try {
            prefs.edit()
                .remove("encrypted_pin")
                .putBoolean("pin_setup", false)
                .apply()
            
            _state.value = _state.value.copy(isPINSetup = false)
            true
        } catch (e: Exception) {
            _state.value = _state.value.copy(error = e.message)
            false
        }
    }

    // Additional methods for SecurityRepositoryImpl
    fun clearPin(): Boolean {
        return removePIN()
    }

    fun isPinSet(): Boolean {
        return prefs.getBoolean("pin_setup", false)
    }

    fun enableBiometric(): Boolean {
        return try {
            prefs.edit()
                .putBoolean("biometric_enabled", true)
                .apply()
            true
        } catch (e: Exception) {
            _state.value = _state.value.copy(error = e.message)
            false
        }
    }

    fun disableBiometric(): Boolean {
        return try {
            prefs.edit()
                .putBoolean("biometric_enabled", false)
                .apply()
            true
        } catch (e: Exception) {
            _state.value = _state.value.copy(error = e.message)
            false
        }
    }

    fun isBiometricEnabled(): Boolean {
        return prefs.getBoolean("biometric_enabled", false)
    }

    fun setAutoLockMinutes(minutes: Int): Boolean {
        return try {
            prefs.edit()
                .putInt("auto_lock_minutes", minutes)
                .apply()
            true
        } catch (e: Exception) {
            _state.value = _state.value.copy(error = e.message)
            false
        }
    }

    fun getAutoLockMinutes(): Int {
        return prefs.getInt("auto_lock_minutes", 5) // Default 5 minutes
    }

    fun setLastActiveTime(timestamp: Long): Boolean {
        return try {
            prefs.edit()
                .putLong("last_active_time", timestamp)
                .apply()
            true
        } catch (e: Exception) {
            _state.value = _state.value.copy(error = e.message)
            false
        }
    }

    fun getLastActiveTime(): Long {
        return prefs.getLong("last_active_time", System.currentTimeMillis())
    }

    fun shouldShowLockScreen(): Boolean {
        val autoLockMinutes = getAutoLockMinutes()
        if (autoLockMinutes == 0) return false // Never lock
        
        val lastActiveTime = getLastActiveTime()
        val currentTime = System.currentTimeMillis()
        val timeDifference = currentTime - lastActiveTime
        val lockThreshold = autoLockMinutes * 60 * 1000L // Convert to milliseconds
        
        return timeDifference > lockThreshold
    }

    fun resetSecuritySettings(): Boolean {
        return try {
            prefs.edit()
                .clear()
                .apply()
            
            _state.value = SecurityState()
            true
        } catch (e: Exception) {
            _state.value = _state.value.copy(error = e.message)
            false
        }
    }
}