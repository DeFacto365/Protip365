package com.protip365.app.presentation.localization

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.ui.graphics.vector.ImageVector
import com.protip365.app.presentation.design.IconMapping

data class LocalizedBottomNavItem(
    val route: String,
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)

class LocalizedBottomNavItems(localization: LocalizationState) {
    val items: List<LocalizedBottomNavItem> = listOf(
        LocalizedBottomNavItem(
            route = "dashboard",
            label = when (localization.currentLanguage.code) {
                "fr" -> "Tableau"
                "es" -> "Panel"
                else -> "Dashboard"
            },
            selectedIcon = IconMapping.Navigation.dashboardFill,
            unselectedIcon = IconMapping.Navigation.dashboard
        ),
        LocalizedBottomNavItem(
            route = "calendar",
            label = when (localization.currentLanguage.code) {
                "fr" -> "Calendrier"
                "es" -> "Calendario"
                else -> "Calendar"
            },
            selectedIcon = IconMapping.Navigation.calendarFill,
            unselectedIcon = IconMapping.Navigation.calendar
        ),
        LocalizedBottomNavItem(
            route = "employers",
            label = when (localization.currentLanguage.code) {
                "fr" -> "Employeurs"
                "es" -> "Empleadores"
                else -> "Employers"
            },
            selectedIcon = IconMapping.Navigation.employersFill,
            unselectedIcon = IconMapping.Navigation.employers
        ),
        LocalizedBottomNavItem(
            route = "calculator",
            label = when (localization.currentLanguage.code) {
                "fr" -> "Calculer"
                "es" -> "Calcular"
                else -> "Calculator"
            },
            selectedIcon = IconMapping.Navigation.calculatorFill,
            unselectedIcon = IconMapping.Navigation.calculator
        ),
        LocalizedBottomNavItem(
            route = "settings",
            label = when (localization.currentLanguage.code) {
                "fr" -> "Réglages"
                "es" -> "Ajustes"
                else -> "Settings"
            },
            selectedIcon = IconMapping.Navigation.settingsFill,
            unselectedIcon = IconMapping.Navigation.settings
        )
    )
}
