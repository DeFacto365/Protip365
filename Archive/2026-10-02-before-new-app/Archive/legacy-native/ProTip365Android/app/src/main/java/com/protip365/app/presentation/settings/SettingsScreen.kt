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
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.OffsetMapping
import java.text.DecimalFormat
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.BuildConfig
import com.protip365.app.R
import com.protip365.app.utilities.rememberWindowSizeClass
import com.protip365.app.utilities.WindowWidthSizeClass
import com.protip365.app.utilities.rememberFoldableDeviceState
import com.protip365.app.utilities.isUnfoldedForDualPane

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
    val context = androidx.compose.ui.platform.LocalContext.current
    
    // WindowSizeClass detection for adaptive layouts (Android 16)
    val windowSizeClass = rememberWindowSizeClass()
    val isTablet = windowSizeClass.widthSizeClass == WindowWidthSizeClass.MEDIUM ||
                   windowSizeClass.widthSizeClass == WindowWidthSizeClass.EXPANDED
    
    // Foldable device detection for dual-pane layouts (Android 16)
    val foldableState = rememberFoldableDeviceState()
    val isUnfoldedDualPane = isUnfoldedForDualPane()
    
    // Use dual-pane layout when:
    // - Tablet-sized screen OR
    // - Foldable device unfolded
    val useDualPaneLayout = isTablet || isUnfoldedDualPane

    // Predictive back gesture: Handle dialogs
    // When any dialog is open, dismiss it first before navigating back
    BackHandler(
        enabled = showLanguagePicker || showAlertPicker
    ) {
        when {
            showLanguagePicker -> showLanguagePicker = false
            showAlertPicker -> showAlertPicker = false
        }
    }

    // Refresh settings when screen is displayed (e.g., returning from onboarding or employers)
    LaunchedEffect(navController.currentBackStackEntry) {
        viewModel.refreshSettings()
    }

    // Handle navigation after sign out
    LaunchedEffect(state.shouldNavigateToAuth) {
        if (state.shouldNavigateToAuth) {
            // Navigate to auth screen and clear back stack
            navController.navigate("auth") {
                // Clear entire back stack
                popUpTo(navController.graph.startDestinationId) { inclusive = true }
            }
            // Reset the flag after navigation
            viewModel.resetNavigateToAuth()
        }
    }

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
        modifier = Modifier.windowInsetsPadding(
            WindowInsets.systemBars.only(WindowInsetsSides.Horizontal)
        ),
        topBar = {
            TopAppBar(
                modifier = Modifier.windowInsetsPadding(
                    WindowInsets.statusBars.only(WindowInsetsSides.Top)
                ),
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
        // Adaptive layout: Use max width constraint for tablets, full width for phones
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .windowInsetsPadding(WindowInsets.systemBars.only(WindowInsetsSides.Vertical))
        ) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxHeight()
                    .then(
                        if (useDualPaneLayout) {
                            Modifier
                                .fillMaxWidth()
                                .widthIn(max = 800.dp) // Center content on tablets/foldables with max width
                        } else {
                            Modifier.fillMaxWidth()
                        }
                    )
                    .align(Alignment.TopCenter),
                contentPadding = PaddingValues(
                    horizontal = if (useDualPaneLayout) 32.dp else 16.dp,
                    vertical = 16.dp
                ),
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
                        title = stringResource(R.string.version_label),
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
                        title = stringResource(R.string.name_label),
                        subtitle = stringResource(R.string.your_display_name),
                        icon = Icons.Default.Person,
                        value = user?.name ?: "",
                        onValueChange = { newName ->
                            viewModel.updateName(newName)
                        }
                    )
                    // Email display (read-only)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Email,
                            contentDescription = null,
                            modifier = Modifier.size(24.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(16.dp))
                        Text(
                            text = stringResource(R.string.email_format, user?.email ?: ""),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }

            // Work Defaults Section
            item {
                SettingsSection(
                    title = stringResource(R.string.work_defaults),
                    icon = IconMapping.Financial.money
                ) {
                    // Default Hourly Rate
                    SettingsNumberFieldItem(
                        title = stringResource(R.string.default_hourly_rate_setting),
                        subtitle = stringResource(R.string.set_default_hourly_rate),
                        icon = IconMapping.Financial.hours,
                        value = state.defaultHourlyRate,
                        onValueChange = { newValue ->
                            viewModel.updateDefaultHourlyRate(newValue)
                        },
                        suffix = "/hr",
                        decimalPlaces = 2,
                        isCurrency = true
                    )

                    // Average Deduction Percentage
                    SettingsNumberFieldItem(
                        title = stringResource(R.string.avg_deductions),
                        subtitle = stringResource(R.string.average_deduction_percentage),
                        icon = Icons.Default.Percent,
                        value = state.averageDeductionPercentage,
                        onValueChange = { newValue ->
                            viewModel.updateAverageDeductionPercentage(newValue)
                        },
                        suffix = "%",
                        decimalPlaces = 1
                    )
                    
                    // Info box for Average Deductions
                    InfoBox(
                        title = stringResource(R.string.about_deductions),
                        text = stringResource(R.string.about_deductions_text)
                    )


                    // Multiple Employers Toggle
                    SettingsToggleItem(
                        title = stringResource(R.string.multiple_employers_setting),
                        subtitle = stringResource(R.string.track_multiple_employers),
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
                    
                    // Info box for Variable Schedule
                    InfoBox(
                        title = stringResource(R.string.variable_schedule_setting),
                        text = stringResource(R.string.variable_schedule_info)
                    )

                    // Default Employer Dropdown (only shown if multiple employers is enabled)
                    if (state.useMultipleEmployers) {
                        SettingsDropdownStringItem(
                            title = stringResource(R.string.default_employer),
                            subtitle = stringResource(R.string.select_default_employer),
                            icon = IconMapping.Navigation.employers,
                            selectedValue = state.defaultEmployerId,
                            options = listOf(null to stringResource(R.string.none)) + state.employers.map { it.id to it.name },
                            onValueSelected = { employerId ->
                                viewModel.updateDefaultEmployer(employerId)
                            }
                        )
                    }

                    // Week Start Day
                    SettingsDropdownItem(
                        title = stringResource(R.string.week_start_day),
                        subtitle = stringResource(R.string.choose_week_start_day),
                        icon = Icons.Default.CalendarMonth,
                        selectedValue = state.weekStartDay,
                        options = listOf(
                            0 to stringResource(R.string.sunday),
                            1 to stringResource(R.string.monday),
                            2 to stringResource(R.string.tuesday),
                            3 to stringResource(R.string.wednesday),
                            4 to stringResource(R.string.thursday),
                            5 to stringResource(R.string.friday),
                            6 to stringResource(R.string.saturday)
                        ),
                        onValueSelected = { day ->
                            viewModel.updateWeekStartDay(day ?: 1)
                        }
                    )

                    // Default Shift Alert
                    SettingsDropdownItem(
                        title = stringResource(R.string.default_shift_alert),
                        subtitle = stringResource(R.string.set_default_shift_reminder),
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
                    title = stringResource(R.string.targets_section),
                    icon = Icons.AutoMirrored.Filled.TrendingUp
                ) {
                    // Tip Percentage (matches iOS order)
                    SettingsNumberFieldItem(
                        title = stringResource(R.string.tip_percentage_setting),
                        subtitle = stringResource(R.string.default_tip_percentage),
                        icon = Icons.Default.Percent,
                        value = state.defaultTipPercentage,
                        onValueChange = { newValue ->
                            viewModel.updateDefaultTipPercentage(newValue)
                        },
                        suffix = "%",
                        decimalPlaces = 0
                    )
                    
                    // Info box for Tip Percentage
                    InfoBox(
                        title = stringResource(R.string.percentage_of_sales),
                        text = stringResource(R.string.percentage_of_sales_info)
                    )
                    
                    // Daily Sales (matches iOS order)
                    SettingsNumberFieldItem(
                        title = stringResource(R.string.daily_sales_setting),
                        subtitle = stringResource(R.string.target_sales_per_day),
                        icon = Icons.Default.CalendarToday,
                        value = state.dailyTarget,
                        onValueChange = { newValue ->
                            viewModel.updateDailyTarget(newValue)
                        },
                        suffix = "$",
                        decimalPlaces = 0
                    )
                    
                    // Info box for Daily Sales
                    InfoBox(
                        title = stringResource(R.string.variable_schedule_setting),
                        text = stringResource(R.string.variable_schedule_info)
                    )
                    
                    // Daily Hours (matches iOS order)
                    SettingsNumberFieldItem(
                        title = stringResource(R.string.daily_hours_setting),
                        subtitle = stringResource(R.string.target_hours_per_day),
                        icon = Icons.Default.AccessTime,
                        value = state.dailyHoursTarget,
                        onValueChange = { newValue ->
                            viewModel.updateDailyHoursTarget(newValue)
                        },
                        suffix = " hrs",
                        decimalPlaces = 1
                    )
                    
                    // Only show Weekly and Monthly targets if NOT using variable schedule (matches iOS)
                    if (!state.hasVariableSchedule) {
                        // Weekly Sales
                        SettingsNumberFieldItem(
                            title = stringResource(R.string.weekly_sales_setting),
                            subtitle = stringResource(R.string.target_sales_per_week),
                            icon = Icons.Default.DateRange,
                            value = state.weeklyTarget,
                            onValueChange = { newValue ->
                                viewModel.updateWeeklyTarget(newValue)
                            },
                            suffix = "$",
                            decimalPlaces = 0
                        )
                        
                        // Weekly Hours
                        SettingsNumberFieldItem(
                            title = stringResource(R.string.weekly_hours_setting),
                            subtitle = stringResource(R.string.target_hours_per_week),
                            icon = Icons.Default.Schedule,
                            value = state.weeklyHoursTarget,
                            onValueChange = { newValue ->
                                viewModel.updateWeeklyHoursTarget(newValue)
                            },
                            suffix = " hrs",
                            decimalPlaces = 1
                        )
                        
                        // Monthly Sales
                        SettingsNumberFieldItem(
                            title = stringResource(R.string.monthly_sales_setting),
                            subtitle = stringResource(R.string.target_sales_per_month),
                            icon = Icons.Default.CalendarMonth,
                            value = state.monthlyTarget,
                            onValueChange = { newValue ->
                                viewModel.updateMonthlyTarget(newValue)
                            },
                            suffix = "$",
                            decimalPlaces = 0
                        )
                        
                        // Monthly Hours
                        SettingsNumberFieldItem(
                            title = stringResource(R.string.monthly_hours_setting),
                            subtitle = stringResource(R.string.target_hours_per_month),
                            icon = Icons.Default.Schedule,
                            value = state.monthlyHoursTarget,
                            onValueChange = { newValue ->
                                viewModel.updateMonthlyHoursTarget(newValue)
                            },
                            suffix = " hrs",
                            decimalPlaces = 1
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
                        title = stringResource(R.string.biometric_authentication),
                        subtitle = if (state.biometricEnabled) stringResource(R.string.enabled) else stringResource(R.string.disabled),
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
                    title = stringResource(R.string.subscription_section_title),
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
                    title = stringResource(R.string.support_section_title),
                    icon = IconMapping.Status.help
                ) {
                    SettingsItem(
                        title = stringResource(R.string.setup_guide),
                        subtitle = stringResource(R.string.complete_onboarding_again),
                        icon = Icons.Default.PlayArrow,
                        onClick = {
                            navController.navigate("onboarding")
                        }
                    )
                    SettingsItem(
                        title = stringResource(R.string.contact_support_option),
                        subtitle = stringResource(R.string.get_help_from_team),
                        icon = IconMapping.Communication.email,
                        onClick = {
                            navController.navigate("contact")
                        }
                    )
                    SettingsItem(
                        title = stringResource(R.string.suggest_ideas),
                        subtitle = stringResource(R.string.share_ideas_to_improve),
                        icon = Icons.Default.Lightbulb,
                        onClick = {
                            navController.navigate("suggest_ideas")
                        }
                    )
                }
            }

            // Account Section
            item {
                SettingsSection(
                    title = stringResource(R.string.account_section_title),
                    icon = Icons.Default.AccountBox
                ) {
                    SettingsItem(
                        title = stringResource(R.string.achievements_option),
                        subtitle = stringResource(R.string.view_progress_achievements),
                        icon = IconMapping.Achievements.trophy,
                        onClick = {
                            navController.navigate("achievements")
                        }
                    )
                    SettingsItem(
                        title = stringResource(R.string.export_data_option),
                        subtitle = stringResource(R.string.export_data_coming_soon),
                        icon = IconMapping.Actions.export,
                        onClick = {
                            // Coming soon - disabled for now
                        }
                    )
                    SettingsItem(
                        title = stringResource(R.string.sign_out),
                        subtitle = stringResource(R.string.sign_out_subtitle),
                        icon = Icons.AutoMirrored.Filled.Logout,
                        textColor = MaterialTheme.colorScheme.error,
                        onClick = {
                            viewModel.signOut()
                        }
                    )
                    SettingsItem(
                        title = stringResource(R.string.delete_account),
                        subtitle = stringResource(R.string.delete_account_subtitle),
                        icon = Icons.Default.DeleteForever,
                        textColor = MaterialTheme.colorScheme.error,
                        onClick = {
                            navController.navigate("delete_account")
                        }
                    )
                }
                }
            }
        }
    }
        
        // Language Picker Dialog
        if (showLanguagePicker) {
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
        }

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
                placeholder = { Text(stringResource(R.string.enter_name)) },
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
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.semantics { heading() } // Section heading (h2)
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

class CurrencyVisualTransformation : VisualTransformation {
    override fun filter(text: AnnotatedString): TransformedText {
        val numericText = text.text.filter { it.isDigit() || it == '.' }
        
        if (numericText.isEmpty()) {
            return TransformedText(
                AnnotatedString(""),
                OffsetMapping.Identity
            )
        }
        
        val amount = numericText.toDoubleOrNull() ?: 0.0
        val formatter = DecimalFormat("#,##0.00")
        val formatted = formatter.format(amount)
        
        return TransformedText(
            AnnotatedString(formatted),
            object : OffsetMapping {
                override fun originalToTransformed(offset: Int): Int {
                    if (offset <= 0) return 0
                    val numericValue = text.text.substring(0, offset.coerceAtMost(text.length))
                        .filter { it.isDigit() || it == '.' }
                    
                    if (numericValue.isEmpty()) return 0
                    
                    val amount = numericValue.toDoubleOrNull() ?: 0.0
                    val formatted = formatter.format(amount)
                    return formatted.length.coerceAtLeast(0)
                }
                
                override fun transformedToOriginal(offset: Int): Int {
                    val numericValue = text.text.filter { it.isDigit() || it == '.' }
                    return numericValue.length.coerceAtMost(offset).coerceAtLeast(0)
                }
            }
        )
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
    decimalPlaces: Int = 2,
    isCurrency: Boolean = false
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
        Column {
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
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    if (isCurrency) {
                        Text(
                            text = "$",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                    OutlinedTextField(
                        value = textValue,
                        onValueChange = { newValue ->
                            val filtered = if (isCurrency) {
                                newValue.filter { it.isDigit() || it == '.' }
                            } else {
                                newValue
                            }
                            if (filtered.count { it == '.' } <= 1) {
                                val parts = filtered.split('.')
                                val integerPart = parts[0]
                                val decimalPart = if (parts.size > 1) parts[1].take(decimalPlaces) else ""
                                val finalValue = if (decimalPart.isNotEmpty()) "$integerPart.$decimalPart" else integerPart
                                textValue = finalValue
                                finalValue.toDoubleOrNull()?.let {
                                    onValueChange(it)
                                }
                            }
                        },
                        visualTransformation = if (isCurrency) CurrencyVisualTransformation() else VisualTransformation.None,
                        suffix = { if (suffix.isNotEmpty()) Text(suffix) },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Decimal,
                            imeAction = ImeAction.Done
                        ),
                        singleLine = true,
                        modifier = Modifier.width(if (isCurrency) 140.dp else 120.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun InfoBox(
    title: String,
    text: String
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
        ),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            Icon(
                imageVector = Icons.Default.Info,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = text,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
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