package com.protip365.app.presentation.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CloudSync
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.protip365.app.presentation.localization.OnboardingLocalization

@Composable
fun LanguageStep(
    state: OnboardingState,
    localization: OnboardingLocalization,
    onLanguageSelected: (String) -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Text(
            text = localization.languageStepTitle,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = localization.languageStepDescription,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Column(
            modifier = Modifier.selectableGroup(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val languages = listOf(
                Triple("en", "English", "English"),
                Triple("fr", "French", "Français"),
                Triple("es", "Spanish", "Español")
            )
            
            languages.forEach { (code, name, nativeName) ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .selectable(
                            selected = state.language == code,
                            onClick = { onLanguageSelected(code) }
                        )
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = state.language == code,
                        onClick = { onLanguageSelected(code) }
                    )
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Column {
                        Text(
                            text = name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = nativeName,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MultipleEmployersStep(
    state: OnboardingState,
    onMultipleEmployersChanged: (Boolean) -> Unit,
    onSingleEmployerNameChanged: (String) -> Unit,
    onDefaultEmployerChanged: (String?) -> Unit,
    onNavigateToEmployers: () -> Unit = {}
) {
    var dropdownExpanded by remember { mutableStateOf(false) }
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Text(
            text = "Multiple Employers?",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )

        Text(
            text = "Do you work for multiple employers or businesses?",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = if (state.useMultipleEmployers)
                    MaterialTheme.colorScheme.primaryContainer
                else
                    MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = state.useMultipleEmployers,
                        onClick = {
                            onMultipleEmployersChanged(true)
                            onNavigateToEmployers()
                        }
                    )

                    Spacer(modifier = Modifier.width(16.dp))

                    Column {
                        Text(
                            text = "Yes, I work for multiple employers",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "Track shifts and tips separately for each employer",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = if (!state.useMultipleEmployers)
                    MaterialTheme.colorScheme.primaryContainer
                else
                    MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = !state.useMultipleEmployers,
                        onClick = { onMultipleEmployersChanged(false) }
                    )

                    Spacer(modifier = Modifier.width(16.dp))

                    Column {
                        Text(
                            text = "No, I work for one employer",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "Simplified tracking for single employer",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }

        // Show employer name input for single employer mode (matching iOS)
        if (!state.useMultipleEmployers) {
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = state.singleEmployerName,
                onValueChange = onSingleEmployerNameChanged,
                label = { Text("Employer Name") },
                placeholder = { Text("Enter employer name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Next
                )
            )
        }

        // Show default employer dropdown for multiple employers mode (matching iOS)
        if (state.useMultipleEmployers && state.employers.isNotEmpty()) {
            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Default Employer",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(4.dp))

            ExposedDropdownMenuBox(
                expanded = dropdownExpanded,
                onExpandedChange = { dropdownExpanded = it }
            ) {
                OutlinedTextField(
                    value = state.employers.find { it.id == state.defaultEmployerId }?.name
                        ?: "Select Employer",
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = dropdownExpanded)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    colors = OutlinedTextFieldDefaults.colors()
                )

                ExposedDropdownMenu(
                    expanded = dropdownExpanded,
                    onDismissRequest = { dropdownExpanded = false }
                ) {
                    state.employers.forEach { employer ->
                        DropdownMenuItem(
                            text = { Text(employer.name) },
                            onClick = {
                                onDefaultEmployerChanged(employer.id)
                                dropdownExpanded = false
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun WeekStartStep(
    state: OnboardingState,
    onWeekStartChanged: (Int) -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Text(
            text = "Week Start Day",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = "When does your work week begin?",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Column(
            modifier = Modifier.selectableGroup(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val weekDays = listOf(
                Pair(0, "Sunday"),
                Pair(1, "Monday"),
                Pair(2, "Tuesday"),
                Pair(3, "Wednesday"),
                Pair(4, "Thursday"),
                Pair(5, "Friday"),
                Pair(6, "Saturday")
            )
            
            weekDays.forEach { (dayCode, dayName) ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .selectable(
                            selected = state.weekStart == dayCode,
                            onClick = { onWeekStartChanged(dayCode) }
                        )
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = state.weekStart == dayCode,
                        onClick = { onWeekStartChanged(dayCode) }
                    )
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Text(
                        text = dayName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

@Composable
fun SecurityStep(
    state: OnboardingState,
    onSecurityTypeChanged: (SecurityType) -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Text(
            text = "Security Settings",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = "Protect your financial data with security features",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Column(
            modifier = Modifier.selectableGroup(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            SecurityType.values().forEach { securityType ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .selectable(
                            selected = state.securityType == securityType,
                            onClick = { onSecurityTypeChanged(securityType) }
                        )
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = state.securityType == securityType,
                        onClick = { onSecurityTypeChanged(securityType) }
                    )
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Column {
                        Text(
                            text = when (securityType) {
                                SecurityType.NONE -> "No Security"
                                SecurityType.PIN -> "PIN Protection"
                                SecurityType.BIOMETRIC -> "Biometric Protection"
                            },
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = when (securityType) {
                                SecurityType.NONE -> "No additional security"
                                SecurityType.PIN -> "Protect with a 4-digit PIN"
                                SecurityType.BIOMETRIC -> "Use fingerprint or face recognition"
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun VariableScheduleStep(
    state: OnboardingState,
    onVariableScheduleChanged: (Boolean) -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Text(
            text = "Schedule Type",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = "Do you have a variable or fixed work schedule?",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = if (state.hasVariableSchedule) 
                    MaterialTheme.colorScheme.primaryContainer 
                else 
                    MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = state.hasVariableSchedule,
                        onClick = { onVariableScheduleChanged(true) }
                    )
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Column {
                        Text(
                            text = "Variable Schedule",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "My work hours change from week to week",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = if (!state.hasVariableSchedule) 
                    MaterialTheme.colorScheme.primaryContainer 
                else 
                    MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = !state.hasVariableSchedule,
                        onClick = { onVariableScheduleChanged(false) }
                    )
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Column {
                        Text(
                            text = "Fixed Schedule",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "My work hours are consistent each week",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun TargetsStep(
    state: OnboardingState,
    onTargetsChanged: (tipPercentage: String, averageDeduction: String, salesDaily: String, hoursDaily: String, salesWeekly: String, hoursWeekly: String, salesMonthly: String, hoursMonthly: String) -> Unit
) {
    var tipPercentage by remember { mutableStateOf(state.tipTargetPercentage) }
    var averageDeduction by remember { mutableStateOf(state.averageDeductionPercentage) }
    var salesDaily by remember { mutableStateOf(state.targetSalesDaily) }
    var hoursDaily by remember { mutableStateOf(state.targetHoursDaily) }
    var salesWeekly by remember { mutableStateOf(state.targetSalesWeekly) }
    var hoursWeekly by remember { mutableStateOf(state.targetHoursWeekly) }
    var salesMonthly by remember { mutableStateOf(state.targetSalesMonthly) }
    var hoursMonthly by remember { mutableStateOf(state.targetHoursMonthly) }
    
    val focusManager = LocalFocusManager.current
    val tipFocusRequester = remember { FocusRequester() }
    val salesFocusRequester = remember { FocusRequester() }
    val hoursFocusRequester = remember { FocusRequester() }
    val deductionFocusRequester = remember { FocusRequester() }
    
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Text(
            text = "Set Your Goals",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = "Set daily targets to track your progress",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Column(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedTextField(
                value = tipPercentage,
                onValueChange = { newValue ->
                    if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d*$"))) {
                        tipPercentage = newValue
                        onTargetsChanged(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                    }
                },
                label = { Text("Tip Target %") },
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(tipFocusRequester),
                suffix = { Text("%") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal
                ),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = MaterialTheme.colorScheme.onSurface,
                    unfocusedTextColor = MaterialTheme.colorScheme.onSurface
                )
            )

            OutlinedTextField(
                value = averageDeduction,
                onValueChange = { newValue ->
                    if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d*$"))) {
                        averageDeduction = newValue
                        onTargetsChanged(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                    }
                },
                label = { Text("Average Deduction %") },
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(deductionFocusRequester),
                suffix = { Text("%") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal
                ),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = MaterialTheme.colorScheme.onSurface,
                    unfocusedTextColor = MaterialTheme.colorScheme.onSurface
                ),
                supportingText = {
                    Text(
                        text = "Average percentage of tips shared with support staff (bussers, hosts, etc.)",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            )

            OutlinedTextField(
                value = salesDaily,
                onValueChange = { newValue ->
                    if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d*$"))) {
                        salesDaily = newValue
                        onTargetsChanged(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                    }
                },
                label = { Text("Daily Sales Target") },
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(salesFocusRequester),
                prefix = { Text("$") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal
                ),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = MaterialTheme.colorScheme.onSurface,
                    unfocusedTextColor = MaterialTheme.colorScheme.onSurface
                )
            )

            // Show weekly/monthly targets only if not variable schedule (matching iOS)
            if (!state.hasVariableSchedule) {
                OutlinedTextField(
                    value = salesWeekly,
                    onValueChange = { newValue ->
                        if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d*$"))) {
                            salesWeekly = newValue
                            onTargetsChanged(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                        }
                    },
                    label = { Text("Weekly Sales Target") },
                    modifier = Modifier.fillMaxWidth(),
                    prefix = { Text("$") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true
                )

                OutlinedTextField(
                    value = salesMonthly,
                    onValueChange = { newValue ->
                        if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d*$"))) {
                            salesMonthly = newValue
                            onTargetsChanged(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                        }
                    },
                    label = { Text("Monthly Sales Target") },
                    modifier = Modifier.fillMaxWidth(),
                    prefix = { Text("$") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true
                )
            }

            OutlinedTextField(
                value = hoursDaily,
                onValueChange = { newValue ->
                    if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d*$"))) {
                        hoursDaily = newValue
                        onTargetsChanged(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                    }
                },
                label = { Text("Daily Hours Target") },
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(hoursFocusRequester),
                suffix = { Text("hrs") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal
                ),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = MaterialTheme.colorScheme.onSurface,
                    unfocusedTextColor = MaterialTheme.colorScheme.onSurface
                )
            )

            if (!state.hasVariableSchedule) {
                OutlinedTextField(
                    value = hoursWeekly,
                    onValueChange = { newValue ->
                        if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d*$"))) {
                            hoursWeekly = newValue
                            onTargetsChanged(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                        }
                    },
                    label = { Text("Weekly Hours Target") },
                    modifier = Modifier.fillMaxWidth(),
                    suffix = { Text("hrs") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true
                )

                OutlinedTextField(
                    value = hoursMonthly,
                    onValueChange = { newValue ->
                        if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d*$"))) {
                            hoursMonthly = newValue
                            onTargetsChanged(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                        }
                    },
                    label = { Text("Monthly Hours Target") },
                    modifier = Modifier.fillMaxWidth(),
                    suffix = { Text("hrs") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true
                )
            }

            // Variable schedule note (matching iOS)
            if (state.hasVariableSchedule) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Info,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = "Since you have a variable schedule, only daily targets are shown.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun HowToUseStep(
    state: OnboardingState
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        Text(
            text = "How to Use ProTip365",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )

        Text(
            text = "Follow these simple steps to track your earnings",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        // Step 1: Employers (conditional - only show if multiple employers)
        if (state.useMultipleEmployers) {
            StepCard(
                number = "1",
                title = "Set Up Employers",
                description = "Add all the businesses you work for in the Employers tab",
                color = MaterialTheme.colorScheme.primary
            )
        }

        // Step 2: Calendar & Shifts
        StepCard(
            number = if (state.useMultipleEmployers) "2" else "1",
            title = "Schedule Shifts",
            description = "Use the Calendar to plan your upcoming shifts with expected hours",
            color = Color(0xFF4CAF50) // Green
        )

        // Step 3: Entries
        StepCard(
            number = if (state.useMultipleEmployers) "3" else "2",
            title = "Track Earnings",
            description = "After each shift, add your sales, tips, and hours worked",
            color = Color(0xFFFF9800) // Orange
        )

        // Step 4: Dashboard
        StepCard(
            number = if (state.useMultipleEmployers) "4" else "3",
            title = "Monitor Progress",
            description = "View your earnings, trends, and performance on the Dashboard",
            color = Color(0xFF9C27B0) // Purple
        )

        // Sync Feature Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            )
        ) {
            Row(
                modifier = Modifier.padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.CloudSync,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(32.dp)
                )
                Column {
                    Text(
                        text = "Cloud Sync",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "Your data syncs automatically across all your devices",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun StepCard(
    number: String,
    title: String,
    description: String,
    color: Color
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = color.copy(alpha = 0.1f)
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .background(color, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = number,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
