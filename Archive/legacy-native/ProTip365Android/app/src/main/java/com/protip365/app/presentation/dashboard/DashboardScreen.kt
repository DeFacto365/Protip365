package com.protip365.app.presentation.dashboard

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.pullrefresh.PullRefreshIndicator
import androidx.compose.material.pullrefresh.pullRefresh
import androidx.compose.material.pullrefresh.rememberPullRefreshState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import com.protip365.app.utils.HapticFeedbackUtils
import com.protip365.app.presentation.components.FadeTransition
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.heading
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.navigation.NavController
import com.protip365.app.R
import com.protip365.app.presentation.localization.DashboardLocalization
import com.protip365.app.utils.localizedString
import com.protip365.app.utilities.rememberWindowSizeClass
import com.protip365.app.utilities.WindowWidthSizeClass
import com.protip365.app.utilities.isLandscape
import com.protip365.app.utilities.rememberFoldableDeviceState
import com.protip365.app.utilities.isUnfoldedForDualPane
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterialApi::class)
@Composable
fun DashboardScreen(
    navController: NavController,
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val scope = rememberCoroutineScope()
    val dashboardState by viewModel.dashboardState.collectAsState()
    val selectedPeriod by viewModel.selectedPeriod.collectAsState()
    val monthViewType by viewModel.monthViewType.collectAsState()
    val userTargets by viewModel.userTargets.collectAsState()
    val currentLanguage by viewModel.currentLanguage.collectAsState()
    val hasVariableSchedule by viewModel.hasVariableSchedule.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    // WindowSizeClass detection for adaptive layouts (Android 16)
    val windowSizeClass = rememberWindowSizeClass()
    val isTablet = windowSizeClass.widthSizeClass == WindowWidthSizeClass.MEDIUM ||
                   windowSizeClass.widthSizeClass == WindowWidthSizeClass.EXPANDED
    
    // Landscape orientation detection for landscape optimizations
    val isLandscapeMode = isLandscape()
    
    // Foldable device detection for dual-pane layouts (Android 16)
    val foldableState = rememberFoldableDeviceState()
    val isUnfoldedDualPane = isUnfoldedForDualPane()
    
    // Use dual-pane layout when:
    // - Tablet-sized screen OR
    // - Foldable device unfolded OR
    // - Phone in landscape mode (better use of horizontal space)
    val useDualPaneLayout = isTablet || isUnfoldedDualPane || (isLandscapeMode && !isTablet)

    val localization = remember(currentLanguage) {
        DashboardLocalization(currentLanguage)
    }

    // Haptic feedback for pull-to-refresh (iOS matches this)
    val haptics = LocalHapticFeedback.current

    var isRefreshing by remember { mutableStateOf(false) }

    val pullRefreshState = rememberPullRefreshState(
        refreshing = isRefreshing,
        onRefresh = {
            scope.launch {
                isRefreshing = true
                viewModel.refreshData()
                delay(1000)
                isRefreshing = false
                // Haptic feedback on successful refresh (Android 16 Enhanced Haptic Feedback)
                HapticFeedbackUtils.performSuccessHaptic(haptics)
            }
        }
    )

    // MARK: - Background Refresh (iOS DashboardView.swift lines 209-215)
    // Refresh data when app returns to foreground if cache is stale
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> {
                    // Smart refresh: only if cache is stale
                    viewModel.refreshDataIfStale()
                }
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.systemBars)
            .background(MaterialTheme.colorScheme.background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .pullRefresh(pullRefreshState)
                .verticalScroll(rememberScrollState())
        ) {
            // Logo at the top - enhanced with better spacing
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 24.dp)
                    .semantics { heading() }, // Screen title (h1)
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = painterResource(id = R.drawable.protip365_logo),
                    contentDescription = "ProTip365 Logo",
                    modifier = Modifier.size(96.dp)
                )
            }

            // Error Banner (iOS DashboardView.swift error handling)
            FadeTransition(isVisible = dashboardState.error != null && !isLoading) {
                ErrorBanner(
                    message = dashboardState.error ?: "An error occurred",
                    onRetry = {
                        scope.launch {
                            viewModel.refreshData()
                        }
                    },
                    onDismiss = {
                        // Clear error by forcing a refresh
                        viewModel.refreshData()
                    }
                )
            }

            // Period selector with localization
            DashboardPeriodSelector(
                selectedPeriod = selectedPeriod.ordinal,
                monthViewType = if (monthViewType == MonthViewType.CALENDAR_MONTH) 0 else 1,
                onPeriodSelected = { viewModel.selectPeriod(DashboardPeriod.values()[it]) },
                onMonthViewTypeChanged = {
                    viewModel.setMonthViewType(
                        if (it == 0) MonthViewType.CALENDAR_MONTH else MonthViewType.FOUR_WEEKS
                    )
                },
                currentLanguage = currentLanguage
            )

            // Performance Card and Stats Cards with adaptive layout (Android 16)
            // Dual-pane layout for tablets and unfolded foldables
            if (useDualPaneLayout) {
                // Two-column layout - Performance Card and Stats Cards side by side
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Left column: Performance Card
                    DashboardPerformanceCard(
                        currentStats = dashboardState,
                        userTargets = userTargets,
                        selectedPeriod = selectedPeriod,
                        monthViewType = monthViewType,
                        hasVariableSchedule = hasVariableSchedule,
                        localization = localization,
                        modifier = Modifier.weight(1f).padding(vertical = 8.dp)
                    )
                    
                    // Right column: Stats Cards
                    DashboardStatsCards(
                        currentStats = dashboardState,
                        userTargets = userTargets,
                        selectedPeriod = selectedPeriod.ordinal,
                        monthViewType = if (monthViewType == MonthViewType.CALENDAR_MONTH) 0 else 1,
                        averageDeductionPercentage = 30.0,
                        defaultHourlyRate = 15.0,
                        currentLanguage = currentLanguage,
                        onDetailClick = { statType ->
                            val period = when (selectedPeriod) {
                                DashboardPeriod.TODAY -> "today"
                                DashboardPeriod.WEEK -> "week"
                                DashboardPeriod.MONTH -> "month"
                                DashboardPeriod.YEAR -> "year"
                                DashboardPeriod.FOUR_WEEKS -> "four_weeks"
                                DashboardPeriod.CUSTOM -> "custom"
                            }
                            navController.navigate("detail/$period/$statType")
                        },
                        modifier = Modifier.weight(1f)
                    )
                }
            } else {
                // Single-column layout for phones and folded foldables
                DashboardPerformanceCard(
                    currentStats = dashboardState,
                    userTargets = userTargets,
                    selectedPeriod = selectedPeriod,
                    monthViewType = monthViewType,
                    hasVariableSchedule = hasVariableSchedule,
                    localization = localization,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
                
                DashboardStatsCards(
                    currentStats = dashboardState,
                    userTargets = userTargets,
                    selectedPeriod = selectedPeriod.ordinal,
                    monthViewType = if (monthViewType == MonthViewType.CALENDAR_MONTH) 0 else 1,
                    averageDeductionPercentage = 30.0,
                    defaultHourlyRate = 15.0,
                    currentLanguage = currentLanguage,
                    onDetailClick = { statType ->
                        val period = when (selectedPeriod) {
                            DashboardPeriod.TODAY -> "today"
                            DashboardPeriod.WEEK -> "week"
                            DashboardPeriod.MONTH -> "month"
                            DashboardPeriod.YEAR -> "year"
                            DashboardPeriod.FOUR_WEEKS -> "four_weeks"
                            DashboardPeriod.CUSTOM -> "custom"
                        }
                        navController.navigate("detail/$period/$statType")
                    }
                )
            }

            // Empty state when no data
            FadeTransition(isVisible = !isLoading && dashboardState.totalRevenue == 0.0) {
                EmptyDashboardState(
                    onAddShift = {
                        navController.navigate("add_shift")
                    },
                    currentLanguage = currentLanguage
                )
            }

            Spacer(modifier = Modifier.height(80.dp))
        }

        // Pull refresh indicator
        PullRefreshIndicator(
            refreshing = isRefreshing,
            state = pullRefreshState,
            modifier = Modifier.align(Alignment.TopCenter)
        )

        // Loading overlay
        FadeTransition(isVisible = isLoading && !isRefreshing) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }
    }
}

/**
 * Error Banner with retry button
 * Matches iOS error handling pattern (DashboardView.swift error states)
 */
@Composable
fun ErrorBanner(
    message: String,
    onRetry: () -> Unit,
    onDismiss: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFFFFEBEE) // Light red background
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = stringResource(R.string.error),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFC62828) // Dark red
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFFC62828)
                )
            }

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Retry button
                TextButton(
                    onClick = onRetry,
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = Color(0xFFC62828)
                    )
                ) {
                    Text(
                        text = stringResource(R.string.retry),
                        fontWeight = FontWeight.Medium
                    )
                }

                // Dismiss button
                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier.size(24.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = stringResource(R.string.dismiss),
                        tint = Color(0xFFC62828),
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun EmptyDashboardState(
    onAddShift: () -> Unit,
    currentLanguage: String
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(48.dp))
        Text(
            text = localizedString(R.string.no_data_yet),
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = localizedString(R.string.add_first_shift),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = onAddShift,
            modifier = Modifier.fillMaxWidth(0.6f)
        ) {
            Text(
                text = localizedString(R.string.add_shift_title)
            )
        }
    }
}
