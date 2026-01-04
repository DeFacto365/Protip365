package com.protip365.app.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
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
    var tipPercentage by remember { mutableStateOf(state.defaultTipPercentage.toString()) }
    var averageDeduction by remember { mutableStateOf(state.averageDeductionPercentage.toString()) }
    var dailyTarget by remember { mutableStateOf(state.dailyTarget.toString()) }
    var dailyHoursTarget by remember { mutableStateOf(state.dailyHoursTarget.toString()) }
    var weeklyTarget by remember { mutableStateOf(state.weeklyTarget.toString()) }
    var monthlyTarget by remember { mutableStateOf(state.monthlyTarget.toString()) }
    var hasChanges by remember { mutableStateOf(false) }

    LaunchedEffect(state) {
        tipPercentage = state.defaultTipPercentage.toInt().toString()
        averageDeduction = state.averageDeductionPercentage.toInt().toString()
        dailyTarget = state.dailyTarget.toInt().toString()
        dailyHoursTarget = state.dailyHoursTarget.toString()
        weeklyTarget = state.weeklyTarget.toInt().toString()
        monthlyTarget = state.monthlyTarget.toInt().toString()
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
            title = { Text(stringResource(R.string.targets_section)) },
            navigationIcon = {
                IconButton(onClick = { navController.navigateUp() }) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                }
            },
            actions = {
                if (hasChanges) {
                    TextButton(
                        onClick = {
                            val tip = tipPercentage.toDoubleOrNull() ?: state.defaultTipPercentage
                            val deduction = averageDeduction.toDoubleOrNull() ?: state.averageDeductionPercentage
                            val daily = dailyTarget.toDoubleOrNull() ?: state.dailyTarget
                            val dailyHours = dailyHoursTarget.toDoubleOrNull() ?: state.dailyHoursTarget
                            val weekly = weeklyTarget.toDoubleOrNull() ?: state.weeklyTarget
                            val monthly = monthlyTarget.toDoubleOrNull() ?: state.monthlyTarget
                            
                            viewModel.updateDefaultTipPercentage(tip)
                            viewModel.updateAverageDeductionPercentage(deduction)
                            viewModel.updateDailyTarget(daily)
                            viewModel.updateDailyHoursTarget(dailyHours)
                            viewModel.updateWeeklyTarget(weekly)
                            viewModel.updateMonthlyTarget(monthly)
                            viewModel.saveSettings()
                            
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
                .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical))
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

            // Tip Targets Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceContainerLow
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            Icons.Default.Percent,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = "Tip Targets",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Target Tip Percentage
                    OutlinedTextField(
                        value = tipPercentage,
                        onValueChange = { 
                            tipPercentage = it
                            hasChanges = true
                        },
                        label = { Text("Target Tip %") },
                        trailingIcon = { Text("%") },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Decimal,
                            imeAction = ImeAction.Next
                        ),
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Text(
                        text = "Your target tip percentage on sales",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Average Deduction Percentage
                    OutlinedTextField(
                        value = averageDeduction,
                        onValueChange = { 
                            averageDeduction = it
                            hasChanges = true
                        },
                        label = { Text("Avg Deduction %") },
                        trailingIcon = { Text("%") },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Decimal,
                            imeAction = ImeAction.Next
                        ),
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Text(
                        text = "Tax and payroll deductions percentage",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }

            // Daily Targets Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceContainerLow
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            Icons.Default.Today,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = "Daily Targets",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Daily Sales Target
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
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Daily Hours Target
                    OutlinedTextField(
                        value = dailyHoursTarget,
                        onValueChange = { 
                            dailyHoursTarget = it
                            hasChanges = true
                        },
                        label = { Text(stringResource(R.string.target_hours)) },
                        leadingIcon = { Icon(Icons.Default.AccessTime, contentDescription = null) },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Decimal,
                            imeAction = ImeAction.Next
                        ),
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Text(
                        text = "Your daily hours goal",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }

            // Only show Weekly and Monthly targets if NOT variable schedule
            if (!state.hasVariableSchedule) {
                // Weekly & Monthly Targets Card
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainerLow
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                Icons.Default.CalendarMonth,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "Weekly & Monthly Targets",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Weekly Target
                        OutlinedTextField(
                            value = weeklyTarget,
                            onValueChange = {
                                weeklyTarget = it
                                hasChanges = true
                            },
                            label = { Text("Weekly " + stringResource(R.string.target_amount)) },
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
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Monthly Target
                        OutlinedTextField(
                            value = monthlyTarget,
                            onValueChange = {
                                monthlyTarget = it
                                hasChanges = true
                            },
                            label = { Text("Monthly " + stringResource(R.string.target_amount)) },
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