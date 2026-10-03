package com.protip365.app.presentation.localization

import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dagger.hilt.android.EntryPointAccessors
import javax.inject.Inject

@Composable
fun rememberLocalizationState(): LocalizationState {
@Suppress("UNUSED_VARIABLE")
    val context = LocalContext.current
    val localizationManager = remember {
        EntryPointAccessors.fromApplication(
            context.applicationContext,
            LocalizationEntryPoint::class.java
        ).localizationManager()
    }
    
    return localizationManager.state.collectAsStateWithLifecycle().value
}

@Composable
fun rememberDashboardLocalization(): DashboardLocalization {
    val localization = rememberLocalizationState()
    return remember(localization.currentLanguage.code) {
        DashboardLocalization(localization.currentLanguage.code)
    }
}

@Composable
fun rememberSettingsLocalization(): SettingsLocalization {
    val localization = rememberLocalizationState()
    return remember(localization.currentLanguage.code) {
        SettingsLocalization(localization.currentLanguage.code)
    }
}

@Composable
fun rememberOnboardingLocalization(): OnboardingLocalization {
    val localization = rememberLocalizationState()
    return remember(localization.currentLanguage.code) {
        OnboardingLocalization(localization.currentLanguage.code)
    }
}

@Composable
fun rememberNavigationLocalization(): NavigationLocalization {
    val localization = rememberLocalizationState()
    return remember(localization.currentLanguage.code) {
        NavigationLocalization(localization.currentLanguage.code)
    }
}

@Composable
fun rememberAuthLocalization(): AuthLocalization {
    val localization = rememberLocalizationState()
    return remember(localization.currentLanguage.code) {
        AuthLocalization(localization.currentLanguage.code)
    }
}

// Entry point for accessing LocalizationManager from Compose
@dagger.hilt.EntryPoint
@dagger.hilt.InstallIn(dagger.hilt.components.SingletonComponent::class)
interface LocalizationEntryPoint {
    fun localizationManager(): LocalizationManager
}
