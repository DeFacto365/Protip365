package com.protip365.app.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TargetsScreen(
    navController: NavController,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    var dailyTarget by remember { mutableStateOf(state.dailyTarget.toString()) }
    var weeklyTarget by remember { mutableStateOf(state.weeklyTarget.toString()) }
    var monthlyTarget by remember { mutableStateOf(state.monthlyTarget.toString()) }
    var hasChanges by remember { mutableStateOf(false) }

    LaunchedEffect(state) {
        dailyTarget = state.dailyTarget.toInt().toString()
        weeklyTarget = state.weeklyTarget.toInt().toString()
        monthlyTarget = state.monthlyTarget.toInt().toString()
    }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBar(
            title = { Text(stringResource(R.string.targets_section)) },
            navigationIcon = {
                IconButton(onClick = { navController.navigateUp() }) {
                    Icon(Icons.Default.ArrowBack, contentDescription = stringResource(R.string.back))
                }
            },
            actions = {
                if (hasChanges) {
                    TextButton(
                        onClick = {
                            val daily = dailyTarget.toDoubleOrNull() ?: state.dailyTarget
                            val weekly = weeklyTarget.toDoubleOrNull() ?: state.weeklyTarget
                            val monthly = monthlyTarget.toDoubleOrNull() ?: state.monthlyTarget
                            
                            viewModel.updateDailyTarget(daily)
                            viewModel.updateWeeklyTarget(weekly)
                            viewModel.updateMonthlyTarget(monthly)
                            
                            hasChanges = false
                            navController.navigateUp()
                        }
                    ) {
                        Text(stringResource(R.string.save))
                    }
                }
            }
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Info card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Text(
                        text = "Set your earning goals to track your progress and stay motivated.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }

            // Daily Target
            Column {
                Text(
                    text = "Daily Target",
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = dailyTarget,
                    onValueChange = { 
                        dailyTarget = it
                        hasChanges = true
                    },
                    label = { Text(stringResource(R.string.target_amount)) },
                    leadingIcon = { Text(stringResource(R.string.currency_symbol)) },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Number,
                        imeAction = ImeAction.Next
                    ),
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Text(
                    text = "Your daily earning goal",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }

            // Only show Weekly and Monthly targets if NOT variable schedule
            if (!state.hasVariableSchedule) {
                // Weekly Target
                Column {
                    Text(
                        text = "Weekly Target",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = weeklyTarget,
                        onValueChange = {
                            weeklyTarget = it
                            hasChanges = true
                        },
                        label = { Text(stringResource(R.string.target_amount)) },
                        leadingIcon = { Text(stringResource(R.string.currency_symbol)) },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Number,
                            imeAction = ImeAction.Next
                        ),
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Text(
                        text = "Your weekly earning goal",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }

                // Monthly Target
                Column {
                    Text(
                        text = "Monthly Target",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = monthlyTarget,
                        onValueChange = {
                            monthlyTarget = it
                            hasChanges = true
                        },
                        label = { Text(stringResource(R.string.target_amount)) },
                        leadingIcon = { Text(stringResource(R.string.currency_symbol)) },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Number,
                            imeAction = ImeAction.Done
                        ),
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Text(
                        text = "Your monthly earning goal",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            } else {
                // Show info card when variable schedule is enabled
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Info,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = "Weekly and monthly targets are hidden when Variable Schedule is enabled. Focus on your daily target!",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
            }

            // Quick presets
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Quick Presets",
                        style = MaterialTheme.typography.titleSmall
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = false,
                            onClick = {
                                dailyTarget = "150"
                                weeklyTarget = "1050"
                                monthlyTarget = "4500"
                                hasChanges = true
                            },
                            label = { Text("Starter") },
                            modifier = Modifier.weight(1f)
                        )
                        FilterChip(
                            selected = false,
                            onClick = {
                                dailyTarget = "200"
                                weeklyTarget = "1400"
                                monthlyTarget = "6000"
                                hasChanges = true
                            },
                            label = { Text("Regular") },
                            modifier = Modifier.weight(1f)
                        )
                        FilterChip(
                            selected = false,
                            onClick = {
                                dailyTarget = "300"
                                weeklyTarget = "2100"
                                monthlyTarget = "9000"
                                hasChanges = true
                            },
                            label = { Text("Pro") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }
    }
}