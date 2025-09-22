package com.protip365.app.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import com.protip365.app.presentation.settings.SettingsState
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import com.google.gson.Gson
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PreferencesManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)

    private val encryptedPrefs: SharedPreferences = EncryptedSharedPreferences.create(
        "secure_prefs",
        masterKey,
        context,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private val regularPrefs: SharedPreferences = context.getSharedPreferences(
        "app_prefs",
        Context.MODE_PRIVATE
    )

    companion object {
        private const val KEY_PIN = "pin_code"
        private const val KEY_BIOMETRIC_ENABLED = "biometric_enabled"
        private const val KEY_AUTO_LOCK_MINUTES = "auto_lock_minutes"
        private const val KEY_LANGUAGE = "language"
        private const val KEY_DARK_MODE = "dark_mode"
        private const val KEY_SETTINGS = "settings_state"
        private const val KEY_ONBOARDING_COMPLETED = "onboarding_completed"
        private const val KEY_LAST_ACTIVE_TIME = "last_active_time"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USER_EMAIL = "user_email"
    }

    private val gson = Gson()

    suspend fun saveSettings(settings: SettingsState) = withContext(Dispatchers.IO) {
        try {
            val json = gson.toJson(settings)
            regularPrefs.edit()
                .putString(KEY_SETTINGS, json)
                .apply()
        } catch (e: Exception) {
            // Handle serialization error
        }
    }

    suspend fun getSettings(): SettingsState? = withContext(Dispatchers.IO) {
        return@withContext try {
            regularPrefs.getString(KEY_SETTINGS, null)?.let {
                gson.fromJson(it, SettingsState::class.java)
            }
        } catch (e: Exception) {
            null
        }
    }

    fun setPin(pin: String) {
        encryptedPrefs.edit()
            .putString(KEY_PIN, pin)
            .apply()
    }

    fun getPin(): String? {
        return encryptedPrefs.getString(KEY_PIN, null)
    }

    fun clearPin() {
        encryptedPrefs.edit()
            .remove(KEY_PIN)
            .apply()
    }

    fun isPinEnabled(): Boolean {
        return encryptedPrefs.contains(KEY_PIN)
    }

    fun enableBiometric() {
        encryptedPrefs.edit()
            .putBoolean(KEY_BIOMETRIC_ENABLED, true)
            .apply()
    }

    fun disableBiometric() {
        encryptedPrefs.edit()
            .putBoolean(KEY_BIOMETRIC_ENABLED, false)
            .apply()
    }

    fun isBiometricEnabled(): Boolean {
        return encryptedPrefs.getBoolean(KEY_BIOMETRIC_ENABLED, false)
    }

    fun setAutoLockMinutes(minutes: Int) {
        regularPrefs.edit()
            .putInt(KEY_AUTO_LOCK_MINUTES, minutes)
            .apply()
    }

    fun getAutoLockMinutes(): Int {
        return regularPrefs.getInt(KEY_AUTO_LOCK_MINUTES, 5)
    }

    fun setLanguage(language: String) {
        regularPrefs.edit()
            .putString(KEY_LANGUAGE, language)
            .apply()
    }

    fun getLanguage(): String {
        return regularPrefs.getString(KEY_LANGUAGE, "en") ?: "en"
    }

    fun setDarkMode(enabled: Boolean) {
        regularPrefs.edit()
            .putBoolean(KEY_DARK_MODE, enabled)
            .apply()
    }

    fun isDarkMode(): Boolean {
        return regularPrefs.getBoolean(KEY_DARK_MODE, false)
    }

    fun setOnboardingCompleted(completed: Boolean) {
        regularPrefs.edit()
            .putBoolean(KEY_ONBOARDING_COMPLETED, completed)
            .apply()
    }

    fun isOnboardingCompleted(): Boolean {
        return regularPrefs.getBoolean(KEY_ONBOARDING_COMPLETED, false)
    }

    fun setLastActiveTime(timestamp: Long) {
        regularPrefs.edit()
            .putLong(KEY_LAST_ACTIVE_TIME, timestamp)
            .apply()
    }

    fun getLastActiveTime(): Long {
        return regularPrefs.getLong(KEY_LAST_ACTIVE_TIME, 0L)
    }

    fun saveUserId(userId: String) {
        encryptedPrefs.edit()
            .putString(KEY_USER_ID, userId)
            .apply()
    }

    fun getUserId(): String? {
        return encryptedPrefs.getString(KEY_USER_ID, null)
    }

    fun saveUserEmail(email: String) {
        encryptedPrefs.edit()
            .putString(KEY_USER_EMAIL, email)
            .apply()
    }

    fun getUserEmail(): String? {
        return encryptedPrefs.getString(KEY_USER_EMAIL, null)
    }

    fun clearAll() {
        encryptedPrefs.edit().clear().apply()
        regularPrefs.edit().clear().apply()
    }

    fun clearUserData() {
        encryptedPrefs.edit()
            .remove(KEY_USER_ID)
            .remove(KEY_USER_EMAIL)
            .remove(KEY_PIN)
            .apply()
    }
}