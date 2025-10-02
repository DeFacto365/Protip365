package com.protip365.app.utils

import android.content.Context
import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import com.protip365.app.R
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.presentation.localization.LocalizationManager
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TranslationManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val preferencesManager: PreferencesManager
) {

    /**
     * Get translated string based on user's language preference
     */
    fun getString(@StringRes stringRes: Int, vararg formatArgs: Any): String {
        val language = preferencesManager.getLanguage()
        val locale = getLocaleFromLanguageCode(language)
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
        val language = preferencesManager.getLanguage()
        val locale = getLocaleFromLanguageCode(language)
        val config = context.resources.configuration
        config.setLocale(locale)
        return context.createConfigurationContext(config)
    }

    /**
     * Convert language code to Locale
     */
    private fun getLocaleFromLanguageCode(languageCode: String): Locale {
        return when (languageCode) {
            "fr" -> Locale.FRENCH
            "es" -> Locale("es", "ES")
            else -> Locale.ENGLISH
        }
    }

    /**
     * Get supported languages
     */
    fun getSupportedLanguages(): List<LanguageOption> {
        return listOf(
            LanguageOption("en", "English", "🇺🇸"),
            LanguageOption("fr", "Français", "🇫🇷"),
            LanguageOption("es", "Español", "🇪🇸")
        )
    }

    /**
     * Get current language display name
     */
    fun getCurrentLanguageDisplayName(): String {
        val currentLang = preferencesManager.getLanguage()
        return getSupportedLanguages().find { it.code == currentLang }?.name ?: "English"
    }

    // Common translation helpers
    fun getCommonStrings(): CommonStrings {
        return CommonStrings(this)
    }
}

data class LanguageOption(
    val code: String,
    val name: String,
    val flag: String
)

class CommonStrings(private val translationManager: TranslationManager) {
    // Navigation
    val dashboard: String get() = translationManager.getString(R.string.dashboard_title)
    val calendar: String get() = translationManager.getString(R.string.calendar_title)
    val settings: String get() = translationManager.getString(R.string.settings_title)

    // Time periods
    val today: String get() = translationManager.getString(R.string.today)
    val week: String get() = translationManager.getString(R.string.week)
    val month: String get() = translationManager.getString(R.string.month)
    val year: String get() = translationManager.getString(R.string.year)

    // Actions
    val save: String get() = translationManager.getString(R.string.save)
    val cancel: String get() = translationManager.getString(R.string.cancel)
    val delete: String get() = translationManager.getString(R.string.delete)
    val loading: String get() = translationManager.getString(R.string.loading)

    // Financial terms
    val tips: String get() = translationManager.getString(R.string.tips)
    val sales: String get() = translationManager.getString(R.string.sales)
    val hours: String get() = translationManager.getString(R.string.hours)
    val salary: String get() = translationManager.getString(R.string.salary)
    val totalRevenue: String get() = translationManager.getString(R.string.total_revenue)

    // Shift related
    val addShift: String get() = translationManager.getString(R.string.add_shift_title)
    val editShift: String get() = translationManager.getString(R.string.edit_shift_title)
    val employer: String get() = translationManager.getString(R.string.employer)
    val startTime: String get() = translationManager.getString(R.string.start_time)
    val endTime: String get() = translationManager.getString(R.string.end_time)
    val hourlyRate: String get() = translationManager.getString(R.string.hourly_rate)

    // Language names
    val english: String get() = translationManager.getString(R.string.english)
    val french: String get() = translationManager.getString(R.string.french)
    val spanish: String get() = translationManager.getString(R.string.spanish)
}

/**
 * Composable helper to get translation manager
 */
@Composable
fun rememberTranslationManager(): TranslationManager {
    val context = LocalContext.current
    return remember {
        val preferencesManager = PreferencesManager(context)
        TranslationManager(context, preferencesManager)
    }
}

/**
 * Extension function to get localized string in Compose using LocalizationManager
 */
@Composable
fun localizedString(@StringRes stringRes: Int, vararg formatArgs: Any): String {
    val context = LocalContext.current
    val preferencesManager = remember { PreferencesManager(context) }
    val localizationManager = remember { LocalizationManager(context, preferencesManager) }

    return remember(stringRes, formatArgs) {
        localizationManager.getString(stringRes, *formatArgs)
    }
}

