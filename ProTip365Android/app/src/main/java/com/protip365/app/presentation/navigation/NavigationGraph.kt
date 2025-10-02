package com.protip365.app.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import androidx.navigation.navDeepLink
import com.protip365.app.presentation.auth.AuthScreen
import com.protip365.app.presentation.auth.ForgotPasswordScreen
import com.protip365.app.presentation.auth.OnboardingScreen
import com.protip365.app.presentation.calendar.CalendarScreen
import com.protip365.app.presentation.calculator.TipCalculatorScreen
import com.protip365.app.presentation.dashboard.DashboardScreen
import com.protip365.app.presentation.employers.EmployersScreen
import com.protip365.app.presentation.settings.SettingsScreen
import com.protip365.app.presentation.settings.ProfileScreen
import com.protip365.app.presentation.settings.SecurityScreen
import com.protip365.app.presentation.settings.SubscriptionScreen
import com.protip365.app.presentation.settings.TargetsScreen
import com.protip365.app.presentation.shifts.AddEditShiftScreen
import java.time.LocalDate

sealed class Screen(val route: String) {
    // Auth screens
    object Auth : Screen("auth")
    object Onboarding : Screen("onboarding")
    object ForgotPassword : Screen("forgot_password")

    // Main screens
    object Dashboard : Screen("dashboard")
    object Calendar : Screen("calendar")
    object Employers : Screen("employers")
    object Calculator : Screen("calculator")
    object Settings : Screen("settings")


    // Add/Edit screens
    object AddShift : Screen("add_shift?date={date}") {
        fun createRoute(date: LocalDate? = null) =
            if (date != null) "add_shift?date=$date" else "add_shift"
    }

    object EditShift : Screen("edit_shift/{shiftId}") {
        fun createRoute(shiftId: String) = "edit_shift/$shiftId"
    }

    object AddEmployer : Screen("add_employer")
    object EditEmployer : Screen("edit_employer/{employerId}") {
        fun createRoute(employerId: String) = "edit_employer/$employerId"
    }

    // Settings sub-screens
    object Profile : Screen("settings/profile")
    object Security : Screen("settings/security")
    object Targets : Screen("settings/targets")
    object Subscription : Screen("settings/subscription")
    object Export : Screen("settings/export")
}

@Composable
fun NavigationGraph(
    navController: NavHostController,
    startDestination: String = Screen.Auth.route,
    isAuthenticated: Boolean = false
) {
    NavHost(
        navController = navController,
        startDestination = if (isAuthenticated) Screen.Dashboard.route else startDestination
    ) {
        // Authentication Flow
        composable(Screen.Auth.route) {
            AuthScreen(
                onNavigateToOnboarding = {
                    navController.navigate(Screen.Onboarding.route) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                },
                onNavigateToDashboard = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                },
                onNavigateToForgotPassword = {
                    navController.navigate(Screen.ForgotPassword.route)
                }
            )
        }

        composable(Screen.Onboarding.route) {
            OnboardingScreen(
                onComplete = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.Onboarding.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.ForgotPassword.route) {
            ForgotPasswordScreen(
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        // Main Navigation
        composable(Screen.Dashboard.route) {
            DashboardScreen(navController)
        }

        composable(Screen.Calendar.route) {
            CalendarScreen(
                onNavigateToAddShift = { navController.navigate("add_shift") },
                onNavigateToAddEntry = { date -> navController.navigate("add_entry?initialDate=${date}") },
                onNavigateToEditShift = { shiftId -> navController.navigate("edit_shift/$shiftId") }
            )
        }

        composable(Screen.Employers.route) {
            EmployersScreen(
                navController = navController
            )
        }

        composable(Screen.Calculator.route) {
            TipCalculatorScreen(
                navController = navController
            )
        }

        composable(Screen.Settings.route) {
            SettingsScreen(
                navController = navController
            )
        }


        // Add/Edit Shift
        composable(
            route = Screen.AddShift.route,
            arguments = listOf(
                navArgument("date") {
                    type = NavType.StringType
                    nullable = true
                    defaultValue = null
                }
            )
        ) { backStackEntry ->
            val date = backStackEntry.arguments?.getString("date")?.let {
                kotlinx.datetime.LocalDate.parse(it)
            }

            AddEditShiftScreen(
                navController = navController,
                initialDate = date
            )
        }

        composable(
            route = Screen.EditShift.route,
            arguments = listOf(
                navArgument("shiftId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val shiftId = backStackEntry.arguments?.getString("shiftId")

            AddEditShiftScreen(
                navController = navController,
                shiftId = shiftId
            )
        }

        // Settings Sub-screens
        composable(Screen.Profile.route) {
            ProfileScreen(navController = navController)
        }

        composable(Screen.Security.route) {
            SecurityScreen(navController = navController)
        }

        composable(Screen.Targets.route) {
            TargetsScreen(navController = navController)
        }

        composable(Screen.Subscription.route) {
            SubscriptionScreen(navController)
        }

        // Deep Links
        composable(
            route = "app://protip365/shift/{shiftId}",
            deepLinks = listOf(
                navDeepLink { uriPattern = "app://protip365/shift/{shiftId}" },
                navDeepLink { uriPattern = "https://protip365.com/shift/{shiftId}" }
            ),
            arguments = listOf(
                navArgument("shiftId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val shiftId = backStackEntry.arguments?.getString("shiftId")

            AddEditShiftScreen(
                navController = navController,
                shiftId = shiftId
            )
        }
    }
}

// Navigation state management
data class NavigationState(
    val currentRoute: String = Screen.Dashboard.route,
    val previousRoute: String? = null,
    val isBottomBarVisible: Boolean = true,
    val isTopBarVisible: Boolean = true
)

// Extension functions for navigation
fun NavHostController.navigateToAddShift(date: LocalDate? = null) {
    navigate(Screen.AddShift.createRoute(date))
}

fun NavHostController.navigateToEditShift(shiftId: String) {
    navigate(Screen.EditShift.createRoute(shiftId))
}


fun NavHostController.navigateToEditEmployer(employerId: String) {
    navigate(Screen.EditEmployer.createRoute(employerId))
}

fun NavHostController.signOut() {
    navigate(Screen.Auth.route) {
        popUpTo(0) { inclusive = true }
    }
}

// Check if current route should show bottom navigation
fun shouldShowBottomBar(route: String?): Boolean {
    return when (route) {
        Screen.Dashboard.route,
        Screen.Calendar.route,
        Screen.Employers.route,
        Screen.Calculator.route,
        Screen.Settings.route -> true
        else -> false
    }
}

// Check if current route should show top bar
fun shouldShowTopBar(route: String?): Boolean {
    return when (route) {
        Screen.Auth.route,
        Screen.Onboarding.route -> false
        else -> true
    }
}