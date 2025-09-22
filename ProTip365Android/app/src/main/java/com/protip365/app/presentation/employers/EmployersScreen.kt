package com.protip365.app.presentation.employers

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmployersScreen(
    navController: NavController,
    viewModel: EmployersViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    var showAddDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBar(
            title = { Text("Employers") },
            navigationIcon = {
                IconButton(onClick = { navController.navigateUp() }) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
            },
            actions = {
                IconButton(onClick = { showAddDialog = true }) {
                    Icon(Icons.Default.Add, contentDescription = "Add Employer")
                }
            }
        )

        if (state.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
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
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(state.employers) { employer ->
                    EmployerCard(
                        employer = employer,
                        isDefault = employer.id == state.defaultEmployerId,
                        onSetDefault = { viewModel.setDefaultEmployer(employer.id) },
                        onEdit = { navController.navigate("edit_employer/${employer.id}") },
                        onToggleActive = { viewModel.toggleEmployerActive(employer.id) },
                        onDelete = { viewModel.deleteEmployer(employer.id) }
                    )
                }

                item {
                    // Info card about employer limits
                    if (!state.hasFullAccess) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(top = 8.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.secondaryContainer
                            )
                        ) {
                            Row(
                                modifier = Modifier.padding(16.dp),
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Icon(
                                    Icons.Default.Info,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSecondaryContainer
                                )
                                Column {
                                    Text(
                                        text = "Upgrade for Multiple Employers",
                                        style = MaterialTheme.typography.titleSmall,
                                        fontWeight = FontWeight.Medium,
                                        color = MaterialTheme.colorScheme.onSecondaryContainer
                                    )
                                    Text(
                                        text = "Full Access subscription allows unlimited employers with per-employer analytics.",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSecondaryContainer
                                    )
                                    Spacer(modifier = Modifier.height(8.dp))
                                    TextButton(
                                        onClick = { navController.navigate("subscription") }
                                    ) {
                                        Text("View Plans")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Add Employer Dialog
    if (showAddDialog) {
        AddEmployerDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { name, hourlyRate ->
                viewModel.addEmployer(name, hourlyRate)
                showAddDialog = false
            }
        )
    }

    // Error handling
    state.error?.let { error ->
        LaunchedEffect(error) {
            // Show snackbar or handle error
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmployerCard(
    employer: com.protip365.app.data.models.Employer,
    isDefault: Boolean,
    onSetDefault: () -> Unit,
    onEdit: () -> Unit,
    onToggleActive: () -> Unit,
    onDelete: () -> Unit
) {
    var showDeleteDialog by remember { mutableStateOf(false) }

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
                    
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            text = "$${employer.defaultHourlyRate}/hour",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        if (employer.totalEarnings > 0) {
                            Text(
                                text = "Total: $${"%,.2f".format(employer.totalEarnings)}",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }

                // Actions menu
                Box {
                    var expanded by remember { mutableStateOf(false) }
                    IconButton(onClick = { expanded = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "More options")
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
                                    showDeleteDialog = true
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

    // Delete confirmation dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Employer") },
            text = { Text("Are you sure you want to delete ${employer.name}? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete()
                        showDeleteDialog = false
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
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
                text = "No Employers Yet",
                style = MaterialTheme.typography.titleLarge
            )
            Text(
                text = "Add your employers to track earnings per workplace",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Button(onClick = onAddEmployer) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Add Employer")
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
        title = { Text("Add Employer") },
        text = {
            Column(
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
                Text("Add")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}