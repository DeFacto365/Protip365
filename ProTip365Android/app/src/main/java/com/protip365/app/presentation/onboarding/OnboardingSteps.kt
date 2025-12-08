package com.protip365.app.presentation.onboarding

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.protip365.app.presentation.localization.OnboardingLocalization

// MARK: - Step 1: Language (Welcome)
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

// MARK: - Step 2: Setup (Consolidated)
@Composable
fun SetupStep(
    state: OnboardingState,
    onWeekStartChanged: (Int) -> Unit,
    onSecurityTypeChanged: (SecurityType) -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(32.dp)
    ) {
        Text(
            text = "Quick Setup",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )

        // Section 1: Week Start
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Text(
                text = "Week Starts On",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            // Reusing logic from old WeekStartStep but simplified
            var dropdownExpanded by remember { mutableStateOf(false) }
            val weekDays = listOf(
                Pair(0, "Sunday"),
                Pair(1, "Monday") // Only showing common options for simplicity, or we can show all
            )
            val allWeekDays = listOf(
                Pair(0, "Sunday"),
                Pair(1, "Monday"),
                Pair(2, "Tuesday"),
                Pair(3, "Wednesday"),
                Pair(4, "Thursday"),
                Pair(5, "Friday"),
                Pair(6, "Saturday")
            )

            ExposedDropdownMenuBox(
                expanded = dropdownExpanded,
                onExpandedChange = { dropdownExpanded = it }
            ) {
                OutlinedTextField(
                    value = allWeekDays.find { it.first == state.weekStart }?.second ?: "Sunday",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Select Day") },
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
                    allWeekDays.forEach { (dayCode, dayName) ->
                        DropdownMenuItem(
                            text = { Text(dayName) },
                            onClick = {
                                onWeekStartChanged(dayCode)
                                dropdownExpanded = false
                            },
                            contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                        )
                    }
                }
            }
        }

        Divider()

        // Section 2: Security
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
             Text(
                text = "App Security",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
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
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = state.securityType == securityType,
                            onClick = { onSecurityTypeChanged(securityType) }
                        )
                        
                        Spacer(modifier = Modifier.width(12.dp))
                        
                        Text(
                            text = when (securityType) {
                                SecurityType.NONE -> "None"
                                SecurityType.PIN -> "PIN Code"
                                SecurityType.BIOMETRIC -> "FaceID / TouchID"
                            },
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Step 3: Completion (How to Use)
@Composable
fun HowToUseStep(
    state: OnboardingState
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Text(
            text = "Ready to Go!",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = "Here's how to get the most out of ProTip365:",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                InstructionItem(
                    icon = "➕",
                    title = "Track Daily",
                    description = "Log your sales and tips after every shift."
                )
                InstructionItem(
                    icon = "📈",
                    title = "View Progress",
                    description = "Check the dashboard to see your earnings grow."
                )
                InstructionItem(
                    icon = "⚙️",
                    title = "Customize",
                    description = "Adjust your targets and settings anytime."
                )
            }
        }
    }
}

@Composable
fun InstructionItem(
    icon: String,
    title: String,
    description: String
) {
    Row(
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = icon,
            style = MaterialTheme.typography.headlineSmall
        )
        
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
