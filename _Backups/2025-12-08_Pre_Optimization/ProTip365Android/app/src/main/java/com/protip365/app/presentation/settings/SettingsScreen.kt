package com.protip365.app.presentation.settings

import androidx.compose.animation.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.*
import com.protip365.app.presentation.design.IconMapping
import com.protip365.app.presentation.components.LanguagePickerDialog
import com.protip365.app.presentation.localization.rememberSettingsLocalization
import com.protip365.app.presentation.localization.rememberLocalizationState
import com.protip365.app.presentation.localization.SupportedLanguage
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.BuildConfig
import com.protip365.app.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    navController: NavController,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val user by viewModel.user.collectAsStateWithLifecycle()
    var showLanguagePicker by remember { mutableStateOf(false) }
    var showAlertPicker by remember { mutableStateOf(false) }
    val localization = rememberSettingsLocalization()
    val localizationState = rememberLocalizationState()

    // Show loading state
    if (state.isLoading && user == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = localization.settingsTitle,
                        style = MaterialTheme.typography.headlineSmall
                    )
                },
                actions = {
                    // Save button
                    AnimatedVisibility(
                        visible = state.hasChanges,
                        enter = fadeIn() + slideInHorizontally { it },
                        exit = fadeOut() + slideOutHorizontally { it }
                    ) {
                        Row {
                            TextButton(
                                onClick = { viewModel.cancelChanges() },
                                enabled = !state.isSaving
                            ) {
                                Text(stringResource(R.string.cancel))
                            }
                            TextButton(
                                onClick = { viewModel.saveSettings() },
                                enabled = !state.isSaving
                            ) {
                                if (state.isSaving) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(16.dp),
                                        strokeWidth = 2.dp
                                    )
                                } else {
                                    Text(stringResource(R.string.save), color = MaterialTheme.colorScheme.primary)
                                }
                            }
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Logo at the top
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Image(
                        painter = painterResource(id = R.drawable.protip365_logo),
                        contentDescription = "ProTip365 Logo",
                        modifier = Modifier.size(80.dp)
                    )
                }
            }

            // App Info & Language Section - iOS ordering
            item {
                SettingsSection(
                    title = localization.appSettingsText,
                    icon = IconMapping.Status.info
                ) {
                    SettingsItem(
                        title = "Version",
                        subtitle = "${BuildConfig.VERSION_NAME} (Build ${BuildConfig.VERSION_CODE})",
                        icon = Icons.Default.AppSettingsAlt,
                        onClick = {}
                    )
                    SettingsItem(
                        title = localization.languageText,
                        subtitle = localizationState.currentLanguage.displayName,
                        icon = IconMapping.Communication.language,
                        onClick = {
                            showLanguagePicker = true
                        }
                    )
                }
            }

            // Profile Section
            item {
                SettingsSection(
                    title = stringResource(R.string.profile),
                    icon = IconMapping.Status.info
                ) {
                    SettingsTextFieldItem(
                        title = "Name",
                        subtitle = "Your display name",
                        icon = Icons.Default.Person,
                        value = user?.name ?: "",
                        onValueChange = { newName ->
                            viewModel.updateName(newName)
                        }
                    )
                }
            }

            // Work Defaults Section
            item {
                SettingsSection(
                    title = "Work Defaults",
                    icon = IconMapping.Financial.money
                ) {
                    // Default Hourly Rate
                    SettingsNumberFieldItem(
                        title = "Default Hourly Rate",
                        subtitle = "Set your default hourly rate",
                        icon = IconMapping.Financial.hours,
                        value = state.defaultHourlyRate,
                        onValueChange = { newValue ->
                            viewModel.updateDefaultHourlyRate(newValue)
                        },
                        suffix = "/hr",
                        decimalPlaces = 2
                    )

                    // Average Deduction
                    SettingsNumberFieldItem(
                        title = when (localizationState.currentLanguage.code) {
                            "fr" -> "Déductions moyennes"
                            "es" -> "Deducciones promedio"
                            else -> "Average Deduction"
                        },
                        subtitle = when (localizationState.currentLanguage.code) {
                            "fr" -> "Déductions fiscales et salariales"
                            "es" -> "Deducciones fiscales y salariales"
                            else -> "Tax and salary deductions"
                        },
                        icon = Icons.Default.Percent,
                        value = state.averageDeductionPercentage,
                        onValueChange = { newValue ->
                            viewModel.updateAverageDeductionPercentage(newValue)
                        },
                        suffix = "%",
                        decimalPlaces = 1
                    )

                    // Multiple Employers Toggle
                    SettingsToggleItem(
                        title = "Multiple Employers",
                        subtitle = "Track shifts for multiple employers",
                        icon = IconMapping.Navigation.employers,
                        checked = state.useMultipleEmployers,
                        onCheckedChange = { enabled ->
                            viewModel.updateMultipleEmployers(enabled)
                        }
                    )

                    // Variable Schedule Toggle
                    SettingsToggleItem(
                        title = localization.variableScheduleLabel,
                        subtitle = localization.variableScheduleDescription,
                        icon = Icons.Default.Schedule,
                        checked = state.hasVariableSchedule,
                        onCheckedChange = { enabled ->
                            viewModel.updateHasVariableSchedule(enabled)
                        }
                    )

                    // Default Employer Dropdown (only shown if multiple employers is enabled)
                    if (state.useMultipleEmployers) {
                        SettingsDropdownStringItem(
                            title = "Default Employer",
                            subtitle = "Select default employer for new shifts",
                            icon = IconMapping.Navigation.employers,
                            selectedValue = state.defaultEmployerId,
                            options = listOf(null to "None") + state.employers.map { it.id to it.name },
                            onValueSelected = { employerId ->
                                viewModel.updateDefaultEmployer(employerId)
                            }
                        )
                    }

                    // Week Start Day
                    SettingsDropdownItem(
                        title = "Week Start Day",
                        subtitle = "Choose which day starts your work week",
                        icon = Icons.Default.CalendarMonth,
                        selectedValue = state.weekStartDay,
                        options = listOf(
                            0 to "Sunday",
                            1 to "Monday",
                            2 to "Tuesday",
                            3 to "Wednesday",
                            4 to "Thursday",
                            5 to "Friday",
                            6 to "Saturday"
                        ),
                        onValueSelected = { day ->
                            viewModel.updateWeekStartDay(day ?: 1)
                        }
                    )

                    // Default Shift Alert
                    SettingsDropdownItem(
                        title = "Default Shift Alert",
                        subtitle = "Set default shift reminder time",
                        icon = Icons.Default.NotificationsActive,
                        selectedValue = state.defaultAlertMinutes,
                        options = listOf(
                            null to localization.alertNone,
                            15 to localization.alert15Minutes,
                            30 to localization.alert30Minutes,
                            60 to localization.alert1Hour,
                            1440 to localization.alert1Day
                        ),
                        onValueSelected = { minutes ->
                            viewModel.updateDefaultAlertMinutes(minutes ?: 0)
                        }
                    )
                }
            }

            // Targets Section
            item {
                SettingsSection(
                    title = "Targets",
                    icon = Icons.AutoMirrored.Filled.TrendingUp
                ) {
                    SettingsItem(
                        title = "Daily Target",
                        subtitle = "$${state.dailyTarget.toInt()}",
                        icon = Icons.Default.CalendarToday,
                        onClick = {
                            navController.navigate("targets")
                        }
                    )
                    
                    // Only show Weekly and Monthly targets if NOT using variable schedule
                    if (!state.hasVariableSchedule) {
                        SettingsItem(
                            title = "Weekly Target",
                            subtitle = "$${state.weeklyTarget.toInt()}",
                            icon = Icons.Default.DateRange,
                            onClick = {
                                navController.navigate("targets")
                            }
                        )
                        SettingsItem(
                            title = "Monthly Target",
                            subtitle = "$${state.monthlyTarget.toInt()}",
                            icon = Icons.Default.CalendarMonth,
                            onClick = {
                                navController.navigate("targets")
                            }
                        )
                    }
                }
            }

            // Security Section
            item {
                SettingsSection(
                    title = stringResource(R.string.security),
                    icon = IconMapping.Security.shield
                ) {
                    SettingsItem(
                        title = "Biometric Authentication",
                        subtitle = if (state.biometricEnabled) "Enabled" else "Disabled",
                        icon = IconMapping.Security.touchID,
                        onClick = {
                            navController.navigate("security")
                        }
                    )
                    SettingsItem(
                        title = stringResource(R.string.change_password),
                        subtitle = stringResource(R.string.update_account_password),
                        icon = IconMapping.Security.locked,
                        onClick = {
                            navController.navigate("change_password")
                        }
                    )
                }
            }

            // Subscription Section (only show management card if subscribed/trial)
            item {
                SettingsSection(
                    title = "Subscription",
                    icon = IconMapping.Achievements.crown
                ) {
                    // Always show subscription option
                    SettingsItem(
                        title = if (state.subscriptionTier == "full") {
                            "ProTip365 Premium"
                        } else {
                            "Subscribe to ProTip365 Premium"
                        },
                        subtitle = if (state.subscriptionTier == "full") {
                            "Active subscription - Unlimited access"
                        } else {
                            "$3.99/month - 7 days free trial"
                        },
                        icon = if (state.subscriptionTier == "full") {
                            IconMapping.Financial.money
                        } else {
                            IconMapping.Actions.add
                        },
                        onClick = {
                            navController.navigate("subscription")
                        }
                    )
                }
            }

            // Support Section
            item {
                SettingsSection(
                    title = "Support",
                    icon = IconMapping.Status.help
                ) {
                    SettingsItem(
                        title = "Contact Support",
                        subtitle = "Get help from our team",
                        icon = IconMapping.Communication.email,
                        onClick = {
                            navController.navigate("contact")
                        }
                    )
                    SettingsItem(
                        title = "Privacy Policy",
                        subtitle = "View our privacy policy",
                        icon = IconMapping.Security.shield,
                        onClick = {
                            navController.navigate("privacy")
                        }
                    )
                }
            }

            // Account Section
            item {
                SettingsSection(
                    title = "Account",
                    icon = Icons.Default.AccountBox
                ) {
                    SettingsItem(
                        title = "Achievements",
                        subtitle = "View your progress and unlocked achievements",
                        icon = IconMapping.Achievements.trophy,
                        onClick = {
                            navController.navigate("achievements")
                        }
                    )
                    SettingsItem(
                        title = "Export Data",
                        subtitle = "Download your data as CSV",
                        icon = IconMapping.Actions.export,
                        onClick = {
                            viewModel.exportData()
                        }
                    )
                    SettingsItem(
                        title = stringResource(R.string.sign_out),
                        subtitle = "Sign out of your account",
                        icon = Icons.AutoMirrored.Filled.Logout,
                        textColor = MaterialTheme.colorScheme.error,
                        onClick = {
                            viewModel.signOut()
                            navController.navigate("auth") {
                                popUpTo(0) { inclusive = true }
                            }
                        }
                    )
                    SettingsItem(
                        title = stringResource(R.string.delete_account),
                        subtitle = "Permanently delete your account",
                        icon = Icons.Default.DeleteForever,
                        textColor = MaterialTheme.colorScheme.error,
                        onClick = {
                            navController.navigate("delete_account")
                        }
                    )
                }
            }
        }
        
        // Language Picker Dialog
        LanguagePickerDialog(
            isOpen = showLanguagePicker,
            currentLanguage = localizationState.currentLanguage.code,
            onLanguageSelected = { languageCode ->
                viewModel.updateLanguage(languageCode)
                showLanguagePicker = false
            },
            onDismiss = {
                showLanguagePicker = false
            }
        )

        // Alert Picker Dialog
        if (showAlertPicker) {
            DefaultAlertPickerDialog(
                selectedMinutes = state.defaultAlertMinutes,
                onMinutesSelected = { minutes ->
                    viewModel.updateDefaultAlertMinutes(minutes ?: 0)
                    showAlertPicker = false
                },
                onDismiss = {
                    showAlertPicker = false
                }
            )
        }
    }
}

@Composable
fun SettingsTextFieldItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    value: String,
    onValueChange: (String) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        ),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.width(16.dp))
            OutlinedTextField(
                value = value,
                onValueChange = onValueChange,
                placeholder = { Text("Enter name") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Done
                ),
                singleLine = true,
                modifier = Modifier.width(150.dp)
            )
        }
    }
}

@Composable
fun SettingsSection(
    title: String,
    icon: ImageVector,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp
        ),
        shape = MaterialTheme.shapes.medium
    ) {
        Column(
            modifier = Modifier.padding(vertical = 12.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )
            }
            content()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    textColor: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurface,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        ),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium,
                    color = textColor
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
fun SettingsToggleItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    textColor: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurface
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        ),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium,
                    color = textColor
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.width(16.dp))
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange
            )
        }
    }
}

@Composable
fun SettingsNumberFieldItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    value: Double,
    onValueChange: (Double) -> Unit,
    suffix: String = "",
    decimalPlaces: Int = 2
) {
    var textValue by remember(value) {
        mutableStateOf(String.format("%.${decimalPlaces}f", value))
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        ),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.width(16.dp))
            OutlinedTextField(
                value = textValue,
                onValueChange = { newValue ->
                    textValue = newValue
                    newValue.toDoubleOrNull()?.let {
                        onValueChange(it)
                    }
                },
                suffix = { if (suffix.isNotEmpty()) Text(suffix) },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal,
                    imeAction = ImeAction.Done
                ),
                singleLine = true,
                modifier = Modifier.width(120.dp)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsDropdownItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    selectedValue: Int?,
    options: List<Pair<Int?, String>>,
    onValueSelected: (Int?) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        ),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.width(16.dp))
            ExposedDropdownMenuBox(
                expanded = expanded,
                onExpandedChange = { expanded = !expanded },
                modifier = Modifier.width(150.dp)
            ) {
                OutlinedTextField(
                    value = options.find { it.first == selectedValue }?.second ?: options.find { it.first == null }?.second ?: "",
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                    modifier = Modifier.menuAnchor(),
                    singleLine = true
                )
                ExposedDropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    options.forEach { (value, label) ->
                        DropdownMenuItem(
                            text = { Text(label) },
                            onClick = {
                                onValueSelected(value)
                                expanded = false
                            }
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsDropdownStringItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    selectedValue: String?,
    options: List<Pair<String?, String>>,
    onValueSelected: (String?) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        ),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.width(16.dp))
            ExposedDropdownMenuBox(
                expanded = expanded,
                onExpandedChange = { expanded = !expanded },
                modifier = Modifier.width(150.dp)
            ) {
                OutlinedTextField(
                    value = options.find { it.first == selectedValue }?.second ?: options.find { it.first == null }?.second ?: "",
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                    modifier = Modifier.menuAnchor(),
                    singleLine = true
                )
                ExposedDropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    options.forEach { (value, label) ->
                        DropdownMenuItem(
                            text = { Text(label) },
                            onClick = {
                                onValueSelected(value)
                                expanded = false
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DefaultAlertPickerDialog(
    selectedMinutes: Int?,
    onMinutesSelected: (Int?) -> Unit,
    onDismiss: () -> Unit
) {
    val localization = rememberSettingsLocalization()
    val options = listOf(
        0 to localization.alertNone,
        15 to localization.alert15Minutes,
        30 to localization.alert30Minutes,
        60 to localization.alert1Hour,
        1440 to localization.alert1Day
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(localization.defaultAlertLabel) },
        text = {
            Column {
                options.forEach { (minutes, label) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                onMinutesSelected(if (minutes == 0) null else minutes)
                            }
                            .padding(vertical = 12.dp, horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = (minutes == 0 && selectedMinutes == null) ||
                                      (minutes != 0 && minutes == selectedMinutes),
                            onClick = {
                                onMinutesSelected(if (minutes == 0) null else minutes)
                            }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = label,
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}