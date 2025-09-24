package com.protip365.app.presentation.main

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import com.protip365.app.presentation.design.IconMapping
import com.protip365.app.presentation.localization.rememberNavigationLocalization
import com.protip365.app.presentation.localization.LocalizedText
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.protip365.app.presentation.calendar.CalendarScreen
import com.protip365.app.presentation.dashboard.DashboardScreen
import com.protip365.app.presentation.settings.*
import com.protip365.app.presentation.calculator.CalculatorScreen
import com.protip365.app.presentation.employers.EmployersScreen
import com.protip365.app.presentation.achievements.AchievementsScreen
import com.protip365.app.presentation.localization.LocalizedBottomNavItems
import com.protip365.app.presentation.localization.rememberLocalization
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.runtime.collectAsState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    viewModel: MainViewModel = hiltViewModel()
) {
    val navController = rememberNavController()
    val useMultipleEmployers by viewModel.useMultipleEmployers.collectAsState()
    val localization = rememberNavigationLocalization()

    Scaffold(
        bottomBar = {
            BottomNavBar(navController, useMultipleEmployers)
        },
        floatingActionButton = {
            val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route
            if (currentRoute == "dashboard" || currentRoute == "calendar") {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.Bottom
                ) {
                    // + Entry button
                    FloatingActionButton(
                        onClick = {
                            navController.navigate("add_shift?isEntry=true")
                        },
                        containerColor = MaterialTheme.colorScheme.secondaryContainer,
                        contentColor = MaterialTheme.colorScheme.onSecondaryContainer
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Text(
                                text = LocalizedText("quick_entry"),
                                style = MaterialTheme.typography.labelSmall
                            )
                        }
                    }
                    
                    // + Shift button
                    FloatingActionButton(
                        onClick = {
                            navController.navigate("add_shift")
                        }
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Icon(Icons.Default.Add, contentDescription = "Add Shift")
                            Text(
                                text = "Shift",
                                style = MaterialTheme.typography.labelSmall
                            )
                        }
                    }
                }
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = "dashboard",
            modifier = Modifier.padding(paddingValues)
        ) {
            composable("dashboard") {
                DashboardScreen(navController)
            }
            composable("calendar") {
                CalendarScreen(navController)
            }
            if (useMultipleEmployers) {
                composable("employers") {
                    EmployersScreen(navController)
                }
            }
            composable("calculator") {
                CalculatorScreen()
            }
            composable("settings") {
                SettingsScreen(navController)
            }
            composable("add_shift") {
                AddShiftScreen(navController)
            }
            composable("achievements") {
                AchievementsScreen(navController)
            }
            // Settings-related routes
            composable("profile") {
                ProfileScreen(navController)
            }
            composable("targets") {
                TargetsScreen(navController)
            }
            composable("security") {
                SecurityScreen(navController)
            }
            // Subscription screen disabled for testing
            // composable("subscription") {
            //     SubscriptionScreen(navController)
            // }
            // Support routes
            composable("help") {
                // TODO: Implement HelpScreen
            }
            composable("contact") {
                // TODO: Implement ContactScreen
            }
            composable("privacy") {
                // TODO: Implement PrivacyScreen
            }
            composable("terms") {
                // TODO: Implement TermsScreen
            }
        }
    }
}

@Composable
fun BottomNavBar(
    navController: androidx.navigation.NavController,
    useMultipleEmployers: Boolean
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val localizationManager = rememberLocalization()
    
    val localizedNavItems = LocalizedBottomNavItems(localizationManager)
    val visibleNavItems = if (useMultipleEmployers) {
        localizedNavItems
    } else {
        localizedNavItems.filter { it.route != "employers" }
    }

    NavigationBar {
        visibleNavItems.forEach { item ->
            NavigationBarItem(
                icon = {
                    Icon(
                        imageVector = if (currentDestination?.hierarchy?.any { it.route == item.route } == true) {
                            item.selectedIcon
                        } else {
                            item.unselectedIcon
                        },
                        contentDescription = item.label
                    )
                },
                label = { Text(item.label) },
                selected = currentDestination?.hierarchy?.any { it.route == item.route } == true,
                onClick = {
                    navController.navigate(item.route) {
                        // Pop up to the start destination of the graph to
                        // avoid building up a large stack of destinations
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        // Avoid multiple copies of the same destination when
                        // reselecting the same item
                        launchSingleTop = true
                        // Restore state when reselecting a previously selected item
                        restoreState = true
                    }
                }
            )
        }
    }
}

data class BottomNavItem(
    val route: String,
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)

val bottomNavItems = listOf(
    BottomNavItem(
        route = "dashboard",
        label = "Dashboard",
        selectedIcon = IconMapping.Navigation.dashboardFill,
        unselectedIcon = IconMapping.Navigation.dashboard
    ),
    BottomNavItem(
        route = "calendar",
        label = "Calendar",
        selectedIcon = IconMapping.Navigation.calendarFill,
        unselectedIcon = IconMapping.Navigation.calendar
    ),
    BottomNavItem(
        route = "employers",
        label = "Employers",
        selectedIcon = IconMapping.Navigation.employersFill,
        unselectedIcon = IconMapping.Navigation.employers
    ),
    BottomNavItem(
        route = "calculator",
        label = "Calculator",
        selectedIcon = IconMapping.Navigation.calculatorFill,
        unselectedIcon = IconMapping.Navigation.calculator
    ),
    BottomNavItem(
        route = "settings",
        label = "Settings",
        selectedIcon = IconMapping.Navigation.settingsFill,
        unselectedIcon = IconMapping.Navigation.settings
    )
)