package com.protip365.app.presentation.main

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import com.protip365.app.presentation.design.IconMapping
import com.protip365.app.presentation.localization.rememberNavigationLocalization
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.protip365.app.presentation.calendar.CalendarScreen
import com.protip365.app.presentation.dashboard.DashboardScreen
import com.protip365.app.presentation.settings.*
import com.protip365.app.presentation.calculator.CalculatorScreen
import com.protip365.app.presentation.employers.EmployersScreen
import com.protip365.app.presentation.employers.EditEmployerScreen
import com.protip365.app.presentation.achievements.AchievementsScreen
import com.protip365.app.presentation.entries.AddEditEntryScreen
import com.protip365.app.presentation.shifts.AddEditShiftScreen
import com.protip365.app.presentation.onboarding.OnboardingScreen
import kotlinx.datetime.LocalDate
import com.protip365.app.presentation.localization.LocalizedBottomNavItems
import com.protip365.app.presentation.localization.rememberLocalization
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.runtime.collectAsState
import com.protip365.app.presentation.components.iOS26LiquidGlassTabBar
import com.protip365.app.presentation.components.getTabItems
import com.protip365.app.presentation.components.AdaptiveNavigationRail
import com.protip365.app.utilities.rememberWindowSizeClass
import com.protip365.app.utilities.WindowWidthSizeClass

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    parentNavController: androidx.navigation.NavHostController? = null,
    viewModel: MainViewModel = hiltViewModel()
) {
    val navController = rememberNavController()
    val useMultipleEmployers by viewModel.useMultipleEmployers.collectAsState()
    
    // WindowSizeClass detection for adaptive layouts (Android 16)
    val windowSizeClass = rememberWindowSizeClass()
    val isTablet = windowSizeClass.widthSizeClass == WindowWidthSizeClass.MEDIUM ||
                   windowSizeClass.widthSizeClass == WindowWidthSizeClass.EXPANDED

    // MARK: - Navigation Event Handling (Deep Linking Support)
    // Listens for navigation events from notifications, alerts, etc.
    LaunchedEffect(Unit) {
        viewModel.navigationEventManager.navigationEvents.collect { event ->
            when (event) {
                is com.protip365.app.presentation.navigation.NavigationEvent.NavigateToCalendar -> {
                    // Navigate to calendar tab and pass date
                    navController.navigate("calendar") {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                    }
                    // TODO: Pass date to calendar for selection
                    println("📅 Navigated to Calendar with date: ${event.date}")
                }
                is com.protip365.app.presentation.navigation.NavigationEvent.NavigateToShift -> {
                    // Navigate to shift editor
                    navController.navigate("edit_shift/${event.shiftId}")
                    println("✏️ Navigated to Edit Shift: ${event.shiftId}")
                }
                is com.protip365.app.presentation.navigation.NavigationEvent.NavigateToAddEntry -> {
                    // Navigate to add entry with date
                    navController.navigate("add_entry?initialDate=${event.date}")
                    println("➕ Navigated to Add Entry with date: ${event.date}")
                }
                is com.protip365.app.presentation.navigation.NavigationEvent.NavigateToEditEntry -> {
                    // Navigate to edit entry
                    navController.navigate("edit_entry/${event.entryId}")
                    println("✏️ Navigated to Edit Entry: ${event.entryId}")
                }
                is com.protip365.app.presentation.navigation.NavigationEvent.NavigateToDashboard -> {
                    // Navigate to dashboard tab
                    navController.navigate("dashboard") {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState = true
                    }
                    println("📊 Navigated to Dashboard")
                }
                is com.protip365.app.presentation.navigation.NavigationEvent.NavigateToTab -> {
                    // Navigate to specific tab
                    navController.navigate(event.tabId) {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState = true
                    }
                    println("📱 Navigated to Tab: ${event.tabId}")
                }
            }
        }
    }

    @Composable
    fun BottomBarContent() {
        iOS26LiquidGlassTabBar(
            selectedTabId = navController.currentBackStackEntryAsState().value?.destination?.route ?: "dashboard",
            onTabSelected = { tabId ->
                navController.navigate(tabId) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            },
            tabItems = getTabItems(useMultipleEmployers),
            modifier = Modifier.windowInsetsPadding(
                WindowInsets.navigationBars.only(WindowInsetsSides.Bottom)
            )
        )
    }

    @Composable
    fun NavigationRailContent() {
        AdaptiveNavigationRail(
            selectedTabId = navController.currentBackStackEntryAsState().value?.destination?.route ?: "dashboard",
            onTabSelected = { tabId ->
                navController.navigate(tabId) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            },
            tabItems = getTabItems(useMultipleEmployers),
            modifier = Modifier.windowInsetsPadding(
                WindowInsets.systemBars.only(WindowInsetsSides.Vertical)
            )
        )
    }

    Scaffold(
        modifier = Modifier.windowInsetsPadding(
            WindowInsets.systemBars.only(WindowInsetsSides.Horizontal)
        ),
        bottomBar = {
            if (!isTablet) {
                BottomBarContent()
            }
        }
    ) { paddingValues ->
        if (isTablet) {
            // Tablet layout: Navigation Rail + Content side-by-side
            Row(modifier = Modifier.fillMaxSize()) {
                // Navigation Rail on the left
                NavigationRailContent()
                
                // Content on the right
                NavHost(
                    navController = navController,
                    startDestination = "dashboard",
                    modifier = Modifier
                        .weight(1f)
                        .padding(paddingValues)
                        .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical))
                ) {
                    composable("dashboard") {
                        DashboardScreen(navController)
                    }
                    composable("calendar") {
                        CalendarScreen(
                            onNavigateToAddShift = { date -> 
                                navController.navigate("add_shift?date=$date") 
                            },
                            onNavigateToAddEntry = { date, shiftId -> 
                                val route = buildString {
                                    append("add_entry?initialDate=$date")
                                    shiftId?.let { append("&shiftId=$it") }
                                }
                                navController.navigate(route)
                            },
                            onNavigateToEditShift = { shiftId -> navController.navigate("edit_shift/$shiftId") },
                            onNavigateToEditEntry = { entryId -> navController.navigate("edit_entry/$entryId") }
                        )
                    }
                    composable("employers") {
                        EmployersScreen(navController = navController, fromOnboarding = false)
                    }
                    composable("calculator") {
                        CalculatorScreen()
                    }
                    composable("settings") {
                        SettingsScreen(parentNavController ?: navController)
                    }
                    composable(
                        route = "add_shift?date={date}",
                        arguments = listOf(
                            navArgument("date") {
                                type = NavType.StringType
                                nullable = true
                                defaultValue = null
                            }
                        )
                    ) { backStackEntry ->
                        val dateString = backStackEntry.arguments?.getString("date")
                        val initialDate = dateString?.let {
                            try {
                                LocalDate.parse(it)
                            } catch (e: Exception) {
                                null
                            }
                        }
                        AddEditShiftScreen(
                            navController = navController,
                            shiftId = null,
                            initialDate = initialDate
                        )
                    }
                    composable(
                        route = "add_entry?initialDate={initialDate}&shiftId={shiftId}&entryId={entryId}",
                        arguments = listOf(
                            navArgument("initialDate") {
                                type = NavType.StringType
                                nullable = true
                                defaultValue = null
                            },
                            navArgument("shiftId") {
                                type = NavType.StringType
                                nullable = true
                                defaultValue = null
                            },
                            navArgument("entryId") {
                                type = NavType.StringType
                                nullable = true
                                defaultValue = null
                            }
                        )
                    ) { backStackEntry ->
                        val dateString = backStackEntry.arguments?.getString("initialDate")
                        val initialDate = dateString?.let {
                            try {
                                LocalDate.parse(it)
                            } catch (e: Exception) {
                                null
                            }
                        }
                        val shiftId = backStackEntry.arguments?.getString("shiftId")
                        val entryId = backStackEntry.arguments?.getString("entryId")
                        
                        AddEditEntryScreen(
                            navController = navController,
                            entryId = entryId,
                            shiftId = shiftId,
                            initialDate = initialDate
                        )
                    }
                    composable("edit_shift/{shiftId}") { backStackEntry ->
                        val shiftId = backStackEntry.arguments?.getString("shiftId") ?: ""
                        AddEditShiftScreen(
                            navController = navController,
                            shiftId = shiftId
                        )
                    }
                    composable("edit_entry/{entryId}") { backStackEntry ->
                        val entryId = backStackEntry.arguments?.getString("entryId")
                        AddEditEntryScreen(
                            navController = navController,
                            entryId = entryId
                        )
                    }
                    composable("edit_employer/{employerId}") { backStackEntry ->
                        val employerId = backStackEntry.arguments?.getString("employerId") ?: ""
                        EditEmployerScreen(
                            navController = navController,
                            employerId = employerId
                        )
                    }
                }
            }
        } else {
            // Phone layout: Bottom navigation with content above
            NavHost(
                navController = navController,
                startDestination = "dashboard",
                modifier = Modifier
                    .padding(paddingValues)
                    .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical))
            ) {
                composable("dashboard") {
                    DashboardScreen(navController)
                }
                composable("calendar") {
                    CalendarScreen(
                        onNavigateToAddShift = { date -> 
                            navController.navigate("add_shift?date=$date") 
                        },
                        onNavigateToAddEntry = { date, shiftId -> 
                            val route = buildString {
                                append("add_entry?initialDate=$date")
                                shiftId?.let { append("&shiftId=$it") }
                            }
                            navController.navigate(route)
                        },
                        onNavigateToEditShift = { shiftId -> navController.navigate("edit_shift/$shiftId") },
                        onNavigateToEditEntry = { entryId -> navController.navigate("edit_entry/$entryId") }
                    )
                }
                composable("employers") {
                    EmployersScreen(navController = navController, fromOnboarding = false)
                }
                composable("calculator") {
                    CalculatorScreen()
                }
                composable("settings") {
                    SettingsScreen(parentNavController ?: navController)
                }
                composable(
                    route = "add_shift?date={date}",
                    arguments = listOf(
                        navArgument("date") {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        }
                    )
                ) { backStackEntry ->
                    val dateString = backStackEntry.arguments?.getString("date")
                    AddShiftScreen(
                        navController = navController,
                        initialDate = dateString
                    )
                }
                composable(
                    route = "add_entry?initialDate={initialDate}&shiftId={shiftId}&entryId={entryId}",
                    arguments = listOf(
                        navArgument("initialDate") {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        },
                        navArgument("shiftId") {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        },
                        navArgument("entryId") {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        }
                    )
                ) { backStackEntry ->
                    val dateString = backStackEntry.arguments?.getString("initialDate")
                    val initialDate = dateString?.let {
                        try {
                            LocalDate.parse(it)
                        } catch (e: Exception) {
                            null
                        }
                    }
                    val shiftId = backStackEntry.arguments?.getString("shiftId")
                    val entryId = backStackEntry.arguments?.getString("entryId")
                    
                    AddEditEntryScreen(
                        navController = navController,
                        entryId = entryId,
                        shiftId = shiftId,
                        initialDate = initialDate
                    )
                }
                composable("edit_shift/{shiftId}") { backStackEntry ->
                    val shiftId = backStackEntry.arguments?.getString("shiftId") ?: ""
                    AddEditShiftScreen(
                        navController = navController,
                        shiftId = shiftId
                    )
                }
                composable("edit_entry/{entryId}") { backStackEntry ->
                    val entryId = backStackEntry.arguments?.getString("entryId")
                    AddEditEntryScreen(
                        navController = navController,
                        entryId = entryId
                    )
                }
                composable("edit_employer/{employerId}") { backStackEntry ->
                    val employerId = backStackEntry.arguments?.getString("employerId") ?: ""
                    EditEmployerScreen(
                        navController = navController,
                        employerId = employerId
                    )
                }
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