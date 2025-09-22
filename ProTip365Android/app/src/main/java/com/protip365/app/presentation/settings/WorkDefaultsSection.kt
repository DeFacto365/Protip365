package com.protip365.app.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.clickable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun WorkDefaultsSection(
    modifier: Modifier = Modifier,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val currentLanguage = state.language
    var showWeekStartDialog by remember { mutableStateOf(false) }
    
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Section Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Default.Work,
                    contentDescription = "Work Defaults",
                    tint = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Défauts de travail"
                        "es" -> "Valores por defecto de trabajo"
                        else -> "Work Defaults"
                    },
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Default Hourly Rate
            OutlinedTextField(
                value = state.defaultHourlyRate.toString(),
                onValueChange = { 
                    try {
                        val rate = it.toDoubleOrNull() ?: 0.0
                        viewModel.updateDefaultHourlyRate(rate)
                    } catch (e: NumberFormatException) {
                        // Handle invalid input
                    }
                },
                label = {
                    Text(
                        when (currentLanguage) {
                            "fr" -> "Taux horaire par défaut"
                            "es" -> "Tarifa por hora por defecto"
                            else -> "Default Hourly Rate"
                        }
                    )
                },
                leadingIcon = {
                    Icon(
                        Icons.Default.AttachMoney,
                        contentDescription = "Hourly Rate",
                        tint = MaterialTheme.colorScheme.primary
                    )
                },
                suffix = {
                    Text("$/hr")
                },
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                    keyboardType = androidx.compose.ui.text.input.KeyboardType.Decimal
                ),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                isError = state.defaultHourlyRate < 0,
                supportingText = if (state.defaultHourlyRate < 0) {
                    { Text("Rate must be positive", color = MaterialTheme.colorScheme.error) }
                } else null
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Average Deduction Percentage
            OutlinedTextField(
                value = state.averageDeductionPercentage.toString(),
                onValueChange = { 
                    try {
                        val percentage = it.toDoubleOrNull() ?: 0.0
                        viewModel.updateAverageDeductionPercentage(percentage)
                    } catch (e: NumberFormatException) {
                        // Handle invalid input
                    }
                },
                label = {
                    Text(
                        when (currentLanguage) {
                            "fr" -> "Pourcentage de déduction moyen"
                            "es" -> "Porcentaje de deducción promedio"
                            else -> "Average Deduction Percentage"
                        }
                    )
                },
                leadingIcon = {
                    Icon(
                        Icons.Default.Percent,
                        contentDescription = "Deduction Percentage",
                        tint = MaterialTheme.colorScheme.primary
                    )
                },
                suffix = {
                    Text("%")
                },
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                    keyboardType = androidx.compose.ui.text.input.KeyboardType.Decimal
                ),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                isError = state.averageDeductionPercentage < 0 || state.averageDeductionPercentage > 100,
                supportingText = if (state.averageDeductionPercentage < 0 || state.averageDeductionPercentage > 100) {
                    { Text("Percentage must be between 0-100", color = MaterialTheme.colorScheme.error) }
                } else {
                    { Text("Typical tip-out percentage for your industry") }
                }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Week Start Day
            OutlinedTextField(
        value = getWeekStartDayText(state.weekStartDay, currentLanguage),
        onValueChange = { },
        label = {
            Text(
                when (currentLanguage) {
                    "fr" -> "Début de semaine"
                    "es" -> "Inicio de semana"
                    else -> "Week Start Day"
                }
            )
        },
        leadingIcon = {
            Icon(
                Icons.Default.CalendarToday,
                contentDescription = "Week Start",
                tint = MaterialTheme.colorScheme.primary
            )
        },
        trailingIcon = {
            Icon(
                Icons.Default.ArrowDropDown,
                contentDescription = "Select Week Start",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        },
        readOnly = true,
        singleLine = true,
        modifier = Modifier
            .fillMaxWidth()
            .clickable { showWeekStartDialog = true },
        supportingText = {
            Text("Choose which day your work week begins")
        }
    )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Multiple Employers Toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Employeurs multiples"
                            "es" -> "Empleadores múltiples"
                            else -> "Multiple Employers"
                        },
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Activez si vous travaillez pour plusieurs employeurs"
                            "es" -> "Activar si trabajas para múltiples empleadores"
                            else -> "Enable if you work for multiple employers"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Switch(
                    checked = state.useMultipleEmployers,
                    onCheckedChange = { viewModel.updateUseMultipleEmployers(it) },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = MaterialTheme.colorScheme.primary,
                        checkedTrackColor = MaterialTheme.colorScheme.primaryContainer
                    )
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Variable Schedule Toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Horaire variable"
                            "es" -> "Horario variable"
                            else -> "Variable Schedule"
                        },
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Activez si vos heures varient chaque semaine"
                            "es" -> "Activar si tus horas varían cada semana"
                            else -> "Enable if your hours vary each week"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Switch(
                    checked = state.hasVariableSchedule,
                    onCheckedChange = { viewModel.updateHasVariableSchedule(it) },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = MaterialTheme.colorScheme.primary,
                        checkedTrackColor = MaterialTheme.colorScheme.primaryContainer
                    )
                )
            }
        }
    }
    
    // Week Start Day Dialog
    if (showWeekStartDialog) {
        WeekStartDayDialog(
            currentSelection = state.weekStartDay,
            onSelectionChange = { viewModel.updateWeekStartDay(it) },
            onDismiss = { showWeekStartDialog = false },
            currentLanguage = currentLanguage
        )
    }
}

@Composable
fun WeekStartDayDialog(
    currentSelection: Int,
    onSelectionChange: (Int) -> Unit,
    onDismiss: () -> Unit,
    currentLanguage: String
) {
    val weekDays = listOf(
        "Sunday" to when (currentLanguage) {
            "fr" -> "Dimanche"
            "es" -> "Domingo"
            else -> "Sunday"
        },
        "Monday" to when (currentLanguage) {
            "fr" -> "Lundi"
            "es" -> "Lunes"
            else -> "Monday"
        },
        "Tuesday" to when (currentLanguage) {
            "fr" -> "Mardi"
            "es" -> "Martes"
            else -> "Tuesday"
        },
        "Wednesday" to when (currentLanguage) {
            "fr" -> "Mercredi"
            "es" -> "Miércoles"
            else -> "Wednesday"
        },
        "Thursday" to when (currentLanguage) {
            "fr" -> "Jeudi"
            "es" -> "Jueves"
            else -> "Thursday"
        },
        "Friday" to when (currentLanguage) {
            "fr" -> "Vendredi"
            "es" -> "Viernes"
            else -> "Friday"
        },
        "Saturday" to when (currentLanguage) {
            "fr" -> "Samedi"
            "es" -> "Sábado"
            else -> "Saturday"
        }
    )
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                when (currentLanguage) {
                    "fr" -> "Choisir le début de semaine"
                    "es" -> "Elegir inicio de semana"
                    else -> "Choose Week Start Day"
                }
            )
        },
        text = {
            Column {
                weekDays.forEachIndexed { index, (_, displayName) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { 
                                onSelectionChange(index)
                                onDismiss()
                            }
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = currentSelection == index,
                            onClick = { 
                                onSelectionChange(index)
                                onDismiss()
                            }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = displayName,
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(
                    when (currentLanguage) {
                        "fr" -> "Annuler"
                        "es" -> "Cancelar"
                        else -> "Cancel"
                    }
                )
            }
        }
    )
}

private fun getWeekStartDayText(weekStartDay: Int, language: String): String {
    return when (weekStartDay) {
        0 -> when (language) {
            "fr" -> "Dimanche"
            "es" -> "Domingo"
            else -> "Sunday"
        }
        1 -> when (language) {
            "fr" -> "Lundi"
            "es" -> "Lunes"
            else -> "Monday"
        }
        2 -> when (language) {
            "fr" -> "Mardi"
            "es" -> "Martes"
            else -> "Tuesday"
        }
        3 -> when (language) {
            "fr" -> "Mercredi"
            "es" -> "Miércoles"
            else -> "Wednesday"
        }
        4 -> when (language) {
            "fr" -> "Jeudi"
            "es" -> "Jueves"
            else -> "Thursday"
        }
        5 -> when (language) {
            "fr" -> "Vendredi"
            "es" -> "Viernes"
            else -> "Friday"
        }
        6 -> when (language) {
            "fr" -> "Samedi"
            "es" -> "Sábado"
            else -> "Saturday"
        }
        else -> when (language) {
            "fr" -> "Lundi"
            "es" -> "Lunes"
            else -> "Monday"
        }
    }
}
