package com.protip365.app.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.NavType
import androidx.navigation.navArgument
import com.protip365.app.presentation.auth.*
import com.protip365.app.presentation.main.MainScreen
import com.protip365.app.presentation.main.AddShiftScreen
import com.protip365.app.presentation.settings.*
import com.protip365.app.presentation.employers.EmployersScreen
import com.protip365.app.presentation.onboarding.OnboardingScreen

@Composable
fun AppNavigation(
    navController: NavHostController
) {
    val authViewModel: AuthViewModel = hiltViewModel()

    NavHost(
        navController = navController,
        startDestination = "splash"
    ) {
        composable("splash") {
            SplashScreen()
            SplashNavigator(navController, authViewModel)
        }

        composable("auth") {
            AuthView(navController)
        }

        composable("login") {
            LoginScreen(navController)
        }

        composable("signup") {
            SignUpScreen(navController)
        }

        composable("forgot_password") {
            ForgotPasswordScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("onboarding") {
            OnboardingScreen(
                navController = navController,
                onComplete = {
                    navController.navigate("main") {
                        popUpTo("onboarding") { inclusive = true }
                    }
                }
            )
        }

        composable("main") {
            MainScreen()
        }
        
        // Add/Edit Shift and Entry routes
        composable(
            route = "add_shift?date={date}",
            arguments = listOf(
                navArgument("date") {
                    type = NavType.StringType
                    defaultValue = ""
                }
            )
        ) { backStackEntry ->
            val date = backStackEntry.arguments?.getString("date") ?: ""
            AddShiftScreen(
                navController = navController,
                shiftId = null
            )
        }
        
        composable("edit_shift/{shiftId}") { backStackEntry ->
            val shiftId = backStackEntry.arguments?.getString("shiftId") ?: ""
            AddShiftScreen(
                navController = navController,
                shiftId = shiftId
            )
        }
        
        composable("edit_entry/{entryId}") { backStackEntry ->
            val entryId = backStackEntry.arguments?.getString("entryId") ?: ""
            // TODO: Implement EditEntryScreen
        }
        
        // Settings routes
        composable("profile") {
            ProfileScreen(navController)
        }
        
        composable("targets") {
            TargetsScreen(navController)
        }
        
        composable("security") {
            SecurityScreen(navController)
        }
        
        composable("subscription") {
            SubscriptionScreen(navController)
        }
        
        // Employer routes
        composable("edit_employer/{employerId}") { backStackEntry ->
            val employerId = backStackEntry.arguments?.getString("employerId") ?: ""
            // TODO: Implement EditEmployerScreen
        }
        
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
        
        // Account routes
        composable("change_password") {
            // TODO: Implement ChangePasswordScreen
        }
        
        composable("delete_account") {
            // TODO: Implement DeleteAccountScreen
        }
    }
}

@Composable
fun SplashNavigator(
    navController: NavHostController,
    authViewModel: AuthViewModel
) {
    val authState = authViewModel.state.collectAsState()

    LaunchedEffect(authState.value.isLoading) {
        if (!authState.value.isLoading) {
            if (authState.value.isAuthenticated) {
                navController.navigate("main") {
                    popUpTo("splash") { inclusive = true }
                }
            } else {
                navController.navigate("auth") {
                    popUpTo("splash") { inclusive = true }
                }
            }
        }
    }
}