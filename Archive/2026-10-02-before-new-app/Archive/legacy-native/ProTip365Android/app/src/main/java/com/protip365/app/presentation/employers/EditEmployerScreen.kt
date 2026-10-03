package com.protip365.app.presentation.employers

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.presentation.components.TopAppBarWithBack

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditEmployerScreen(
    navController: NavController,
    employerId: String,
    viewModel: EmployersViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    
    LaunchedEffect(employerId) {
        viewModel.loadEmployer(employerId)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Horizontal))
    ) {
        TopAppBarWithBack(
            title = "Edit Employer",
            onBackClick = { navController.popBackStack() }
        )
        
        if (state.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            state.selectedEmployer?.let { employer ->
                EditEmployerForm(
                    employer = employer,
                    onSave = { name, hourlyRate ->
                        viewModel.updateEmployer(employerId, name, hourlyRate)
                        navController.popBackStack()
                    },
                    onCancel = { navController.popBackStack() }
                )
            }
        }
    }
}

@Composable
fun EditEmployerForm(
    employer: com.protip365.app.data.models.Employer,
    onSave: (String, Double) -> Unit,
    onCancel: () -> Unit
) {
    var name by remember { mutableStateOf(employer.name) }
    var hourlyRate by remember { mutableStateOf(employer.hourlyRate.toString()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        OutlinedTextField(
            value = name,
            onValueChange = { name = it },
            label = { Text("Employer Name") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        
        OutlinedTextField(
            value = hourlyRate,
            onValueChange = { hourlyRate = it },
            label = { Text("Default Hourly Rate") },
            leadingIcon = { Text("$") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.weight(1f))
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedButton(
                onClick = onCancel,
                modifier = Modifier.weight(1f)
            ) {
                Text("Cancel")
            }
            
            Button(
                onClick = {
                    val rate = hourlyRate.toDoubleOrNull() ?: 0.0
                    if (name.isNotBlank() && rate > 0) {
                        onSave(name, rate)
                    }
                },
                enabled = name.isNotBlank() && (hourlyRate.toDoubleOrNull() ?: 0.0) > 0,
                modifier = Modifier.weight(1f)
            ) {
                Text("Save")
            }
        }
    }
}


