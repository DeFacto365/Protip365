package com.protip365.app.presentation.localization

import android.content.Context
import androidx.annotation.StringRes
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.protip365.app.data.local.PreferencesManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

enum class SupportedLanguage(val code: String, val displayName: String, val shortCode: String) {
    ENGLISH("en", "English", "EN"),
    FRENCH("fr", "Français", "FR"),
    SPANISH("es", "Español", "ES")
}

data class LocalizationState(
    val currentLanguage: SupportedLanguage = SupportedLanguage.ENGLISH,
    val isLoaded: Boolean = false
)

@Singleton
class LocalizationManager @Inject constructor(
    private val context: Context,
    private val preferencesManager: PreferencesManager
) {
    private val _state = MutableStateFlow(LocalizationState())
    val state: StateFlow<LocalizationState> = _state.asStateFlow()

    var currentLanguage by mutableStateOf(SupportedLanguage.ENGLISH)
        private set

    init {
        // Initialize with user preference or system language
        val preferredLanguage = preferencesManager.getLanguage()
        currentLanguage = when (preferredLanguage) {
            "fr" -> SupportedLanguage.FRENCH
            "es" -> SupportedLanguage.SPANISH
            else -> SupportedLanguage.ENGLISH
        }
        _state.value = _state.value.copy(currentLanguage = currentLanguage, isLoaded = true)
    }

    fun setLanguage(language: SupportedLanguage) {
        currentLanguage = language
        _state.value = _state.value.copy(currentLanguage = language)

        // Save preference
        preferencesManager.setLanguage(language.code)

        // Update system locale
        val locale = when (language) {
            SupportedLanguage.FRENCH -> Locale("fr")
            SupportedLanguage.SPANISH -> Locale("es")
            SupportedLanguage.ENGLISH -> Locale("en")
        }
        Locale.setDefault(locale)
    }

    /**
     * Get localized string using Android string resources
     */
    fun getString(@StringRes stringRes: Int, vararg formatArgs: Any): String {
        val locale = when (currentLanguage) {
            SupportedLanguage.FRENCH -> Locale("fr")
            SupportedLanguage.SPANISH -> Locale("es")
            SupportedLanguage.ENGLISH -> Locale("en")
        }

        val config = context.resources.configuration
        val originalLocale = config.locales[0]

        return try {
            config.setLocale(locale)
            val localizedContext = context.createConfigurationContext(config)
            localizedContext.getString(stringRes, *formatArgs)
        } catch (e: Exception) {
            // Fallback to English if translation fails
            config.setLocale(Locale.ENGLISH)
            val fallbackContext = context.createConfigurationContext(config)
            fallbackContext.getString(stringRes, *formatArgs)
        } finally {
            // Restore original locale
            config.setLocale(originalLocale)
        }
    }

    /**
     * Get localized context for the current user language
     */
    fun getLocalizedContext(): Context {
        val locale = when (currentLanguage) {
            SupportedLanguage.FRENCH -> Locale("fr")
            SupportedLanguage.SPANISH -> Locale("es")
            SupportedLanguage.ENGLISH -> Locale("en")
        }
        val config = context.resources.configuration
        config.setLocale(locale)
        return context.createConfigurationContext(config)
    }

    fun applyLanguage(context: Context, languageCode: String): Context {
        val locale = Locale(languageCode)
        val config = context.resources.configuration
        config.setLocale(locale)
        return context.createConfigurationContext(config)
    }

    @Deprecated("Use getString(@StringRes) instead for proper resource-based localization")
    fun getString(key: String, vararg args: Any): String {
        // Legacy support - this method should be replaced with resource-based calls
        return key
    }

    // Legacy hardcoded strings removed - now using Android string resources
}