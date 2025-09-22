package com.protip365.app.presentation.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

// Profile Settings Section
@Composable
fun ProfileSettingsSection(
    name: String,
    email: String,
    language: String,
    currency: String,
    onNameChange: (String) -> Unit,
    onLanguageChange: (String) -> Unit,
    onCurrencyChange: (String) -> Unit,
    currentLanguage: String = "en"
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Profil"
                    "es" -> "Perfil"
                    else -> "Profile"
                },
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            // Name field
            OutlinedTextField(
                value = name,
                onValueChange = onNameChange,
                label = {
                    Text(when (currentLanguage) {
                        "fr" -> "Nom"
                        "es" -> "Nombre"
                        else -> "Name"
                    })
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Email (read-only)
            OutlinedTextField(
                value = email,
                onValueChange = {},
                label = {
                    Text(when (currentLanguage) {
                        "fr" -> "Courriel"
                        "es" -> "Correo"
                        else -> "Email"
                    })
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = false,
                singleLine = true
            )

            // Language selector
            LanguageSelector(
                currentLanguage = language,
                onLanguageSelected = onLanguageChange,
                label = when (currentLanguage) {
                    "fr" -> "Langue"
                    "es" -> "Idioma"
                    else -> "Language"
                }
            )

            // Currency selector
            CurrencySelector(
                currentCurrency = currency,
                onCurrencySelected = onCurrencyChange,
                currentLanguage = currentLanguage
            )
        }
    }
}

// Targets Settings Section
@Composable
fun TargetsSettingsSection(
    tipTargetPercentage: String,
    targetSalesDaily: String,
    targetSalesWeekly: String,
    targetSalesMonthly: String,
    targetHoursDaily: String,
    targetHoursWeekly: String,
    targetHoursMonthly: String,
    onTipTargetChange: (String) -> Unit,
    onSalesDailyChange: (String) -> Unit,
    onSalesWeeklyChange: (String) -> Unit,
    onSalesMonthlyChange: (String) -> Unit,
    onHoursDailyChange: (String) -> Unit,
    onHoursWeeklyChange: (String) -> Unit,
    onHoursMonthlyChange: (String) -> Unit,
    currentLanguage: String = "en"
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Objectifs"
                    "es" -> "Objetivos"
                    else -> "Targets"
                },
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            // Tip percentage target
            OutlinedTextField(
                value = tipTargetPercentage,
                onValueChange = onTipTargetChange,
                label = {
                    Text(when (currentLanguage) {
                        "fr" -> "Objectif pourboire (%)"
                        "es" -> "Objetivo propina (%)"
                        else -> "Tip Target (%)"
                    })
                },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                trailingIcon = { Text("%") }
            )

            // Sales targets
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Objectifs de ventes"
                    "es" -> "Objetivos de ventas"
                    else -> "Sales Targets"
                },
                style = MaterialTheme.typography.labelLarge
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = targetSalesDaily,
                    onValueChange = onSalesDailyChange,
                    label = { Text(when (currentLanguage) {
                        "fr" -> "Quotidien"
                        "es" -> "Diario"
                        else -> "Daily"
                    }) },
                    modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    leadingIcon = { Text("$") }
                )
                OutlinedTextField(
                    value = targetSalesWeekly,
                    onValueChange = onSalesWeeklyChange,
                    label = { Text(when (currentLanguage) {
                        "fr" -> "Hebdomadaire"
                        "es" -> "Semanal"
                        else -> "Weekly"
                    }) },
                    modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    leadingIcon = { Text("$") }
                )
            }

            OutlinedTextField(
                value = targetSalesMonthly,
                onValueChange = onSalesMonthlyChange,
                label = {
                    Text(when (currentLanguage) {
                        "fr" -> "Mensuel"
                        "es" -> "Mensual"
                        else -> "Monthly"
                    })
                },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                leadingIcon = { Text("$") }
            )

            // Hours targets
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Objectifs d'heures"
                    "es" -> "Objetivos de horas"
                    else -> "Hours Targets"
                },
                style = MaterialTheme.typography.labelLarge
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = targetHoursDaily,
                    onValueChange = onHoursDailyChange,
                    label = { Text(when (currentLanguage) {
                        "fr" -> "Quotidien"
                        "es" -> "Diario"
                        else -> "Daily"
                    }) },
                    modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    trailingIcon = { Text("h") }
                )
                OutlinedTextField(
                    value = targetHoursWeekly,
                    onValueChange = onHoursWeeklyChange,
                    label = { Text(when (currentLanguage) {
                        "fr" -> "Hebdomadaire"
                        "es" -> "Semanal"
                        else -> "Weekly"
                    }) },
                    modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    trailingIcon = { Text("h") }
                )
            }

            OutlinedTextField(
                value = targetHoursMonthly,
                onValueChange = onHoursMonthlyChange,
                label = {
                    Text(when (currentLanguage) {
                        "fr" -> "Mensuel"
                        "es" -> "Mensual"
                        else -> "Monthly"
                    })
                },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                trailingIcon = { Text("h") }
            )
        }
    }
}

// Work Defaults Section
@Composable
fun WorkDefaultsSection(
    weekStartDay: Int,
    defaultHourlyRate: String,
    useMultipleEmployers: Boolean,
    defaultEmployerName: String?,
    onWeekStartDayChange: (Int) -> Unit,
    onHourlyRateChange: (String) -> Unit,
    onMultipleEmployersChange: (Boolean) -> Unit,
    onDefaultEmployerClick: () -> Unit,
    currentLanguage: String = "en"
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Préférences de travail"
                    "es" -> "Preferencias de trabajo"
                    else -> "Work Defaults"
                },
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            // Week start day
            WeekStartDaySelector(
                weekStartDay = weekStartDay,
                onWeekStartDayChange = onWeekStartDayChange,
                currentLanguage = currentLanguage
            )

            // Default hourly rate
            OutlinedTextField(
                value = defaultHourlyRate,
                onValueChange = onHourlyRateChange,
                label = {
                    Text(when (currentLanguage) {
                        "fr" -> "Taux horaire par défaut"
                        "es" -> "Tarifa por hora predeterminada"
                        else -> "Default Hourly Rate"
                    })
                },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                singleLine = true,
                leadingIcon = { Text("$") },
                trailingIcon = { Text("/hr") }
            )

            // Multiple employers toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Employeurs multiples"
                        "es" -> "Múltiples empleadores"
                        else -> "Multiple Employers"
                    },
                    style = MaterialTheme.typography.bodyLarge
                )
                Switch(
                    checked = useMultipleEmployers,
                    onCheckedChange = onMultipleEmployersChange
                )
            }

            // Default employer (if multiple employers enabled)
            if (useMultipleEmployers && defaultEmployerName != null) {
                Card(
                    onClick = onDefaultEmployerClick,
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = when (currentLanguage) {
                                    "fr" -> "Employeur par défaut"
                                    "es" -> "Empleador predeterminado"
                                    else -> "Default Employer"
                                },
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = defaultEmployerName,
                                style = MaterialTheme.typography.bodyLarge
                            )
                        }
                        Icon(
                            Icons.Default.ChevronRight,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

// Helper Components
@Composable
private fun LanguageSelector(
    currentLanguage: String,
    onLanguageSelected: (String) -> Unit,
    label: String
) {
    var expanded by remember { mutableStateOf(false) }

    Box {
        OutlinedTextField(
            value = when (currentLanguage) {
                "fr" -> "Français"
                "es" -> "Español"
                else -> "English"
            },
            onValueChange = {},
            label = { Text(label) },
            modifier = Modifier.fillMaxWidth(),
            readOnly = true,
            trailingIcon = {
                Icon(
                    if (expanded) Icons.Default.ArrowDropUp else Icons.Default.ArrowDropDown,
                    contentDescription = null
                )
            },
            singleLine = true
        )

        // Clickable overlay
        Box(
            modifier = Modifier
                .matchParentSize()
                .clickable { expanded = true }
        )

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            DropdownMenuItem(
                text = { Text("English") },
                onClick = {
                    onLanguageSelected("en")
                    expanded = false
                }
            )
            DropdownMenuItem(
                text = { Text("Français") },
                onClick = {
                    onLanguageSelected("fr")
                    expanded = false
                }
            )
            DropdownMenuItem(
                text = { Text("Español") },
                onClick = {
                    onLanguageSelected("es")
                    expanded = false
                }
            )
        }
    }
}

@Composable
private fun CurrencySelector(
    currentCurrency: String,
    onCurrencySelected: (String) -> Unit,
    currentLanguage: String
) {
    var expanded by remember { mutableStateOf(false) }

    Box {
        OutlinedTextField(
            value = currentCurrency,
            onValueChange = {},
            label = {
                Text(when (currentLanguage) {
                    "fr" -> "Devise"
                    "es" -> "Moneda"
                    else -> "Currency"
                })
            },
            modifier = Modifier.fillMaxWidth(),
            readOnly = true,
            trailingIcon = {
                Icon(
                    if (expanded) Icons.Default.ArrowDropUp else Icons.Default.ArrowDropDown,
                    contentDescription = null
                )
            },
            singleLine = true
        )

        Box(
            modifier = Modifier
                .matchParentSize()
                .clickable { expanded = true }
        )

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            listOf("USD", "CAD", "EUR", "GBP", "MXN").forEach { currency ->
                DropdownMenuItem(
                    text = { Text(currency) },
                    onClick = {
                        onCurrencySelected(currency)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
private fun WeekStartDaySelector(
    weekStartDay: Int,
    onWeekStartDayChange: (Int) -> Unit,
    currentLanguage: String
) {
    var expanded by remember { mutableStateOf(false) }

    Box {
        OutlinedTextField(
            value = when (weekStartDay) {
                0 -> when (currentLanguage) {
                    "fr" -> "Dimanche"
                    "es" -> "Domingo"
                    else -> "Sunday"
                }
                else -> when (currentLanguage) {
                    "fr" -> "Lundi"
                    "es" -> "Lunes"
                    else -> "Monday"
                }
            },
            onValueChange = {},
            label = {
                Text(when (currentLanguage) {
                    "fr" -> "Début de semaine"
                    "es" -> "Inicio de semana"
                    else -> "Week Start"
                })
            },
            modifier = Modifier.fillMaxWidth(),
            readOnly = true,
            trailingIcon = {
                Icon(
                    if (expanded) Icons.Default.ArrowDropUp else Icons.Default.ArrowDropDown,
                    contentDescription = null
                )
            },
            singleLine = true
        )

        Box(
            modifier = Modifier
                .matchParentSize()
                .clickable { expanded = true }
        )

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            DropdownMenuItem(
                text = {
                    Text(when (currentLanguage) {
                        "fr" -> "Dimanche"
                        "es" -> "Domingo"
                        else -> "Sunday"
                    })
                },
                onClick = {
                    onWeekStartDayChange(0)
                    expanded = false
                }
            )
            DropdownMenuItem(
                text = {
                    Text(when (currentLanguage) {
                        "fr" -> "Lundi"
                        "es" -> "Lunes"
                        else -> "Monday"
                    })
                },
                onClick = {
                    onWeekStartDayChange(1)
                    expanded = false
                }
            )
        }
    }
}