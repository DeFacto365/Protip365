package com.protip365.app.presentation.employers

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.platform.LocalHapticFeedback
import com.protip365.app.utils.HapticFeedbackUtils
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.heading
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.R
import com.protip365.app.utilities.rememberWindowSizeClass

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmployersScreen(
    navController: NavController,
    fromOnboarding: Boolean = false,
    viewModel: EmployersViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val haptics = LocalHapticFeedback.current
    var showAddDialog by remember { mutableStateOf(false) }
    
    // WindowSizeClass detection for adaptive layouts
    val windowSizeClass = rememberWindowSizeClass()

    // Predictive back gesture: Handle dialogs
    // When any dialog is open, dismiss it first before navigating back
    BackHandler(
        enabled = showAddDialog || state.showCannotDeleteAlert || state.employerToDelete != null
    ) {
        when {
            showAddDialog -> showAddDialog = false
            state.showCannotDeleteAlert -> viewModel.cancelDelete()
            state.employerToDelete != null -> viewModel.cancelDelete()
        }
    }

    // Refresh employers list when returning from edit screen
    LaunchedEffect(navController.currentBackStackEntry) {
        viewModel.refreshEmployers()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Horizontal))
    ) {
        TopAppBar(
            modifier = Modifier.windowInsetsPadding(
                WindowInsets.statusBars.only(WindowInsetsSides.Top)
            ),
            title = { 
                Text(
                    stringResource(R.string.employers_title),
                    modifier = Modifier.semantics { heading() } // Screen title (h1)
                ) 
            },
            navigationIcon = {
                if (fromOnboarding) {
                    // Show "Done" text button in onboarding mode
                    TextButton(onClick = { navController.navigateUp() }) {
                        Text(
                            text = stringResource(R.string.done),
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                } else {
                    // Show back arrow in normal mode
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                    }
                }
            },
            actions = {
                IconButton(onClick = { 
                    // Form interaction haptic for add button
                    HapticFeedbackUtils.performFormInteractionHaptic(haptics)
                    showAddDialog = true 
                }) {
                    Icon(Icons.Default.Add, contentDescription = stringResource(R.string.add_employer))
                }
            }
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
        } else if (state.employers.isEmpty()) {
            EmptyEmployersState(
                onAddEmployer = { showAddDialog = true }
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical)),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(state.employers) { employer ->
                    EmployerCard(
                        employer = employer,
                        isDefault = employer.id == state.defaultEmployerId,
                        shiftCount = state.employerShiftCounts[employer.id] ?: 0,
                        entryCount = state.employerEntryCounts[employer.id] ?: 0,
                        onSetDefault = { viewModel.setDefaultEmployer(employer.id) },
                        onEdit = { navController.navigate("edit_employer/${employer.id}") },
                        onToggleActive = { viewModel.toggleEmployerActive(employer.id) },
                        onDelete = { viewModel.requestDeleteEmployer(employer.id) }
                    )
                }
            }
        }
    }

    // Add Employer Dialog
    if (showAddDialog) {
        AddEmployerDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { name, hourlyRate ->
                // Confirmation haptic for add employer
                HapticFeedbackUtils.performConfirmationHaptic(haptics)
                viewModel.addEmployer(name, hourlyRate)
                showAddDialog = false
                // Success haptic will be handled by ViewModel success callback if available
            }
        )
    }

    // iOS conformance: Cannot Delete Alert with Deactivate Option
    // Matches iOS showCannotDeleteAlert (EmployersView.swift lines 101-113)
    if (state.showCannotDeleteAlert) {
        AlertDialog(
            onDismissRequest = { viewModel.cancelDelete() },
            title = { Text("Cannot Delete Employer") },
            text = { Text(state.cannotDeleteMessage ?: "This employer has associated data and cannot be deleted.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        // Confirmation haptic for deactivate action
                        HapticFeedbackUtils.performConfirmationHaptic(haptics)
                        viewModel.deactivateInsteadOfDelete()
                    }
                ) {
                    Text("Deactivate Instead")
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.cancelDelete() }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Normal Delete Confirmation Dialog
    if (state.employerToDelete != null && !state.showCannotDeleteAlert) {
        AlertDialog(
            onDismissRequest = { viewModel.cancelDelete() },
            title = { Text("Delete Employer") },
            text = { 
                Text("Are you sure you want to delete ${state.employerToDelete?.name}? This action cannot be undone.") 
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        // Confirmation haptic for delete confirmation
                        HapticFeedbackUtils.performConfirmationHaptic(haptics)
                        viewModel.confirmDeleteEmployer()
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.cancelDelete() }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Error handling
    state.error?.let { error ->
        LaunchedEffect(error) {
            // Error haptic when error occurs
            HapticFeedbackUtils.performErrorHaptic(haptics)
            // Show snackbar or handle error
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmployerCard(
    employer: com.protip365.app.data.models.Employer,
    isDefault: Boolean,
    shiftCount: Int,
    entryCount: Int,
    onSetDefault: () -> Unit,
    onEdit: () -> Unit,
    onToggleActive: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = if (isDefault) {
            CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        } else {
            CardDefaults.cardColors()
        }
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = employer.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        if (isDefault) {
                            AssistChip(
                                onClick = { },
                                label = { Text("Default") },
                                colors = AssistChipDefaults.assistChipColors(
                                    containerColor = MaterialTheme.colorScheme.primary,
                                    labelColor = MaterialTheme.colorScheme.onPrimary
                                ),
                                border = null,
                                modifier = Modifier.height(24.dp)
                            )
                        }
                        if (!employer.active) {
                            AssistChip(
                                onClick = { },
                                label = { Text("Inactive") },
                                colors = AssistChipDefaults.assistChipColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                                ),
                                modifier = Modifier.height(24.dp)
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Column(
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        // Hourly rate
                        Text(
                            text = "$${employer.hourlyRate}/hour",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        // iOS conformance: Display shift count (EmployerCard.swift lines 38-53)
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.CalendarMonth,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "$shiftCount ${if (shiftCount == 1) "shift" else "shifts"}",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        
                        // iOS conformance: Display entry count (EmployerCard.swift lines 54-59)
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "$entryCount ${if (entryCount == 1) "entry" else "entries"}",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                // Actions menu
                Box {
                    var expanded by remember { mutableStateOf(false) }
                    IconButton(onClick = { expanded = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = stringResource(R.string.more_options))
                    }
                    DropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        if (!isDefault) {
                            DropdownMenuItem(
                                text = { Text("Set as Default") },
                                onClick = {
                                    onSetDefault()
                                    expanded = false
                                },
                                leadingIcon = { Icon(Icons.Default.Star, contentDescription = null) }
                            )
                        }
                        DropdownMenuItem(
                            text = { Text("Edit") },
                            onClick = {
                                onEdit()
                                expanded = false
                            },
                            leadingIcon = { Icon(Icons.Default.Edit, contentDescription = null) }
                        )
                        DropdownMenuItem(
                            text = { Text(if (employer.active) "Deactivate" else "Activate") },
                            onClick = {
                                onToggleActive()
                                expanded = false
                            },
                            leadingIcon = {
                                Icon(
                                    if (employer.active) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                    contentDescription = null
                                )
                            }
                        )
                        if (!isDefault) {
                            HorizontalDivider()
                            DropdownMenuItem(
                                text = { Text("Delete", color = MaterialTheme.colorScheme.error) },
                                onClick = {
                                    onDelete() // Trigger iOS-conformant delete flow
                                    expanded = false
                                },
                                leadingIcon = {
                                    Icon(
                                        Icons.Default.Delete,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.error
                                    )
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun EmptyEmployersState(
    onAddEmployer: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                Icons.Default.Business,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = stringResource(R.string.no_employers_yet),
                style = MaterialTheme.typography.titleLarge
            )
            Text(
                text = stringResource(R.string.add_employers_to_track),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Button(onClick = onAddEmployer) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text(stringResource(R.string.add_employer))
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEmployerDialog(
    onDismiss: () -> Unit,
    onConfirm: (String, Double) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var hourlyRate by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.add_employer_dialog_title)) },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(stringResource(R.string.employer_name_label)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = hourlyRate,
                    onValueChange = { hourlyRate = it },
                    label = { Text(stringResource(R.string.default_hourly_rate_setting)) },
                    leadingIcon = { Text("$") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val rate = hourlyRate.toDoubleOrNull() ?: 0.0
                    if (name.isNotBlank() && rate > 0) {
                        onConfirm(name, rate)
                    }
                },
                enabled = name.isNotBlank() && (hourlyRate.toDoubleOrNull() ?: 0.0) > 0
            ) {
                Text(stringResource(R.string.save))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}