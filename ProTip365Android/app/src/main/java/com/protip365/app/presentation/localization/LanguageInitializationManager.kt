package com.protip365.app.presentation.localization

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class LanguageInitializationManager @Inject constructor() {
    
    private val _isInitialized = MutableStateFlow(false)
    val isInitialized: StateFlow<Boolean> = _isInitialized.asStateFlow()
    
    private val _systemLanguage = MutableStateFlow<String?>(null)
    val systemLanguage: StateFlow<String?> = _systemLanguage.asStateFlow()
    
    fun initializeFromSystem(context: Context): String {
        val systemLanguage = getSystemLanguage(context)
        _systemLanguage.value = systemLanguage
        
        // Set to system language if supported, otherwise default to English
        val targetLanguage = if (isLanguageSupported(systemLanguage)) {
            systemLanguage
        } else {
            "en"
        }
        
        _isInitialized.value = true
        return targetLanguage
    }
    
    fun syncWithSystemLanguage(context: Context): String {
        val systemLanguage = getSystemLanguage(context)
        _systemLanguage.value = systemLanguage
        
        return if (isLanguageSupported(systemLanguage)) {
            systemLanguage
        } else {
            "en"
        }
    }
    
    private fun getSystemLanguage(context: Context): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Use the new API for Android 7.0+
            val localeList = context.resources.configuration.locales
            if (localeList.size() > 0) {
                localeList[0].language
            } else {
                Locale.getDefault().language
            }
        } else {
            // Fallback for older Android versions
            Locale.getDefault().language
        }
    }
    
    private fun isLanguageSupported(language: String): Boolean {
        return language in listOf("en", "fr", "es")
    }
    
    fun getSupportedLanguages(): List<SupportedLanguage> {
        return listOf(
            SupportedLanguage.ENGLISH,
            SupportedLanguage.FRENCH,
            SupportedLanguage.SPANISH
        )
    }
    
    fun getLanguageDisplayName(languageCode: String): String {
        return when (languageCode) {
            "fr" -> "Français"
            "es" -> "Español"
            else -> "English"
        }
    }
    
    fun getLanguageShortCode(languageCode: String): String {
        return when (languageCode) {
            "fr" -> "FR"
            "es" -> "ES"
            else -> "EN"
        }
    }
}

@Composable
fun rememberLanguageInitialization(
    context: Context,
    onLanguageInitialized: (String) -> Unit
) {
    var isInitialized by remember { mutableStateOf(false) }
    
    LaunchedEffect(Unit) {
        if (!isInitialized) {
            val languageInitializationManager = LanguageInitializationManager()
            val targetLanguage = languageInitializationManager.initializeFromSystem(context)
            onLanguageInitialized(targetLanguage)
            isInitialized = true
        }
    }
}

@Composable
fun rememberSystemLanguageSync(
    context: Context,
    onLanguageSynced: (String) -> Unit
) {
    LaunchedEffect(Unit) {
        val languageInitializationManager = LanguageInitializationManager()
        val targetLanguage = languageInitializationManager.syncWithSystemLanguage(context)
        onLanguageSynced(targetLanguage)
    }
}

// Extension function to get current language from context
fun Context.getCurrentLanguage(): String {
    val languageInitializationManager = LanguageInitializationManager()
    return languageInitializationManager.syncWithSystemLanguage(this)
}

// Extension function to check if language is supported
fun String.isSupportedLanguage(): Boolean {
    return this in listOf("en", "fr", "es")
}

// Extension function to get language display name
fun String.getLanguageDisplayName(): String {
    return when (this) {
        "fr" -> "Français"
        "es" -> "Español"
        else -> "English"
    }
}

// Extension function to get language short code
fun String.getLanguageShortCode(): String {
    return when (this) {
        "fr" -> "FR"
        "es" -> "ES"
        else -> "EN"
    }
}
