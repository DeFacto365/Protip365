package com.protip365.app.presentation.localization

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import com.protip365.app.presentation.localization.LocalizationManager

@Composable
fun rememberLocalization(): LocalizationManager {
    return hiltViewModel<LocalizationViewModel>().localizationManager
}

@Composable
fun LocalizedText(
    key: String,
    vararg args: Any,
    localizationManager: LocalizationManager = rememberLocalization()
): String {
    return remember(key, args, localizationManager.currentLanguage) {
        localizationManager.getString(key, *args)
    }
}

@Composable
fun LocalizedBottomNavItems(
    localizationManager: LocalizationManager = rememberLocalization()
): List<com.protip365.app.presentation.main.BottomNavItem> {
    return remember(localizationManager.currentLanguage) {
        listOf(
            com.protip365.app.presentation.main.BottomNavItem(
                route = "dashboard",
                label = localizationManager.getString("dashboard"),
                selectedIcon = Icons.Default.Home,
                unselectedIcon = Icons.Default.Home
            ),
            com.protip365.app.presentation.main.BottomNavItem(
                route = "calendar",
                label = localizationManager.getString("calendar"),
                selectedIcon = Icons.Default.CalendarMonth,
                unselectedIcon = Icons.Default.CalendarMonth
            ),
            com.protip365.app.presentation.main.BottomNavItem(
                route = "employers",
                label = localizationManager.getString("employers"),
                selectedIcon = Icons.Default.Business,
                unselectedIcon = Icons.Default.Business
            ),
            com.protip365.app.presentation.main.BottomNavItem(
                route = "calculator",
                label = localizationManager.getString("calculator"),
                selectedIcon = Icons.Default.Calculate,
                unselectedIcon = Icons.Default.Calculate
            ),
            com.protip365.app.presentation.main.BottomNavItem(
                route = "settings",
                label = localizationManager.getString("settings"),
                selectedIcon = Icons.Default.Settings,
                unselectedIcon = Icons.Default.Settings
            )
        )
    }
}