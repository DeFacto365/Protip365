package com.protip365.app.presentation.settings

import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    navController: NavController,
    onNavigateToProfile: () -> Unit = {},
    onNavigateToSecurity: () -> Unit = {},
    onNavigateToTargets: () -> Unit = {},
    onNavigateToSubscription: () -> Unit = {},
    onNavigateToExport: () -> Unit = {},
    onSignOut: () -> Unit = {},
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val user by viewModel.user.collectAsStateWithLifecycle()
    var showLanguagePicker by remember { mutableStateOf(false) }
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
                                Text("Cancel")
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
                                    Text("Save", color = MaterialTheme.colorScheme.primary)
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
            // Profile Section
            item {
                SettingsSection(
                    title = "Profile",
                    icon = IconMapping.Status.info
                ) {
                    SettingsItem(
                        title = user?.name ?: "Set your name",
                        subtitle = if (user?.name.isNullOrEmpty()) "Tap to set your profile" else "Tap to update profile",
                        icon = Icons.Default.Person,
                        onClick = {
                            navController.navigate("profile")
                        }
                    )
                }
            }

            // Targets Section
            item {
                SettingsSection(
                    title = "Targets",
                    icon = Icons.Default.TrendingUp
                ) {
                    SettingsItem(
                        title = "Daily Target",
                        subtitle = "$${state.dailyTarget.toInt()}",
                        icon = Icons.Default.CalendarToday,
                        onClick = {
                            navController.navigate("targets")
                        }
                    )
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

            // Work Defaults Section
            item {
                SettingsSection(
                    title = "Work Defaults",
                    icon = IconMapping.Financial.money
                ) {
                    SettingsItem(
                        title = "Default Hourly Rate",
                        subtitle = "$${state.defaultHourlyRate}/hour",
                        icon = IconMapping.Financial.hours,
                        onClick = {
                            navController.navigate("targets")
                        }
                    )
                    SettingsItem(
                        title = "Multiple Employers",
                        subtitle = if (state.useMultipleEmployers) "Enabled" else "Disabled",
                        icon = IconMapping.Navigation.employers,
                        onClick = {
                            navController.navigate("targets")
                        }
                    )
                    SettingsItem(
                        title = "Cash Out",
                        subtitle = if (state.trackCashOut) "Tracking enabled" else "Tracking disabled",
                        icon = IconMapping.Financial.tips,
                        onClick = {
                            navController.navigate("targets")
                        }
                    )
                    
                    // Variable Schedule Toggle
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(
                                text = localization.variableScheduleLabel,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Medium
                            )
                            Text(
                                text = localization.variableScheduleDescription,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        
                        Spacer(modifier = Modifier.width(16.dp))
                        
                        Switch(
                            checked = false, // TODO: Get from user preferences
                            onCheckedChange = { /* TODO: Update user preference */ }
                        )
                    }
                }
            }

            // Security Section
            item {
                SettingsSection(
                    title = "Security",
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
                        title = "Change Password",
                        subtitle = "Update your account password",
                        icon = IconMapping.Security.locked,
                        onClick = {
                            navController.navigate("change_password")
                        }
                    )
                }
            }

            // Subscription Section
            item {
                SettingsSection(
                    title = "Subscription",
                    icon = IconMapping.Achievements.crown
                ) {
                    val subscriptionTitle = when (state.subscriptionTier) {
                        "full_access" -> "Full Access"
                        "part_time" -> "Part-Time Pro"
                        else -> "Free Trial"
                    }
                    val subscriptionSubtitle = when (state.subscriptionTier) {
                        "full_access" -> "Unlimited shifts & entries"
                        "part_time" -> "3 shifts & 3 entries per week"
                        else -> "Limited features"
                    }
                    
                    SettingsItem(
                        title = subscriptionTitle,
                        subtitle = subscriptionSubtitle,
                        icon = IconMapping.Financial.money,
                        onClick = {
                            navController.navigate("subscription")
                        }
                    )
                    
                    if (state.subscriptionTier != "full_access") {
                        SettingsItem(
                            title = "Upgrade to Full Access",
                            subtitle = "$4.99/month - Unlimited everything",
                            icon = IconMapping.Actions.add,
                            onClick = {
                                navController.navigate("subscription")
                            }
                        )
                    }
                }
            }

            // App Settings Section
            item {
                SettingsSection(
                    title = localization.appSettingsText,
                    icon = IconMapping.Status.info
                ) {
                    SettingsItem(
                        title = localization.languageText,
                        subtitle = localization.choosePreferredLanguageText,
                        icon = IconMapping.Communication.language,
                        onClick = {
                            showLanguagePicker = true
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
                        title = "Help Center",
                        subtitle = "View guides and tutorials",
                        icon = IconMapping.Status.help,
                        onClick = {
                            navController.navigate("help")
                        }
                    )
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
                    SettingsItem(
                        title = "Terms of Service",
                        subtitle = "View terms and conditions",
                        icon = IconMapping.Status.info,
                        onClick = {
                            navController.navigate("terms")
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
                        title = "Sign Out",
                        subtitle = "Sign out of your account",
                        icon = Icons.Default.Logout,
                        textColor = MaterialTheme.colorScheme.error,
                        onClick = {
                            viewModel.signOut()
                            navController.navigate("auth") {
                                popUpTo(0) { inclusive = true }
                            }
                        }
                    )
                    SettingsItem(
                        title = "Delete Account",
                        subtitle = "Permanently delete your account",
                        icon = Icons.Default.DeleteForever,
                        textColor = MaterialTheme.colorScheme.error,
                        onClick = {
                            navController.navigate("delete_account")
                        }
                    )
                }
            }

            // App Info
            item {
                SettingsSection(
                    title = "About",
                    icon = Icons.Default.Info
                ) {
                    SettingsItem(
                        title = "Version",
                        subtitle = "1.0.0 (Build 1)",
                        icon = Icons.Default.AppSettingsAlt,
                        onClick = {}
                    )
                }
            }
        }
        
        // Language Picker Dialog
        LanguagePickerDialog(
            isOpen = showLanguagePicker,
            currentLanguage = localizationState.currentLanguage.code,
            onLanguageSelected = { languageCode ->
                // TODO: Update user language preference
                println("Language selected: $languageCode")
            },
            onDismiss = {
                showLanguagePicker = false
            }
        )
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