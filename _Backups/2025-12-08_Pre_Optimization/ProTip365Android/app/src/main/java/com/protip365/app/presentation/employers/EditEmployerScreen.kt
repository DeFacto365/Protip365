package com.protip365.app.presentation.employers

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.presentation.components.TopAppBarWithBack

@Composable
fun EditEmployerScreen(
    navController: NavController,
    employerId: String,
    viewModel: EmployersViewModel = hiltViewModel()
) {
    LaunchedEffect(employerId) {
        viewModel.loadEmployer(employerId)
    }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBarWithBack(
            title = "Edit Employer",
            onBackClick = { navController.popBackStack() }
        )

        // Use the existing add/edit dialog from EmployersScreen
        // This will be handled by the ViewModel state
        val state by viewModel.state.collectAsState()
        
        if (state.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = androidx.compose.ui.Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            // Navigate back to employers screen with edit mode
            LaunchedEffect(Unit) {
                navController.navigate("employers") {
                    popUpTo("edit_employer") { inclusive = true }
                }
            }
        }
    }
}


