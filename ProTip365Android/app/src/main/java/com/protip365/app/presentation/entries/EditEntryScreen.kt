package com.protip365.app.presentation.entries

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.presentation.components.TopAppBarWithBack

@Composable
fun EditEntryScreen(
    navController: NavController,
    entryId: String,
    viewModel: AddEditEntryViewModel = hiltViewModel()
) {
    LaunchedEffect(entryId) {
        viewModel.loadEntry(entryId)
    }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBarWithBack(
            title = "Edit Entry",
            onBackClick = { navController.popBackStack() }
        )

        AddEditEntryScreen(
            navController = navController,
            entryId = entryId,
            viewModel = viewModel
        )
    }
}


