package com.protip365.app.presentation.dashboard

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.pullrefresh.PullRefreshIndicator
import androidx.compose.material.pullrefresh.pullRefresh
import androidx.compose.material.pullrefresh.rememberPullRefreshState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.R
import com.protip365.app.presentation.localization.DashboardLocalization
import com.protip365.app.utils.localizedString
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

    val localization = remember(currentLanguage) {
        DashboardLocalization(currentLanguage)
    }

    var isRefreshing by remember { mutableStateOf(false) }

    val pullRefreshState = rememberPullRefreshState(
        refreshing = isRefreshing,
        onRefresh = {
            scope.launch {
                isRefreshing = true
                viewModel.refreshData()
                delay(1000)
                isRefreshing = false
            }
        }
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .pullRefresh(pullRefreshState)
                .verticalScroll(rememberScrollState())
        ) {
            // Logo at the top
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

            // Performance Card - NEW
            DashboardPerformanceCard(
                currentStats = dashboardState,
                userTargets = userTargets,
                selectedPeriod = selectedPeriod,
                monthViewType = monthViewType,
                hasVariableSchedule = hasVariableSchedule,
                localization = localization,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )

            // Stats cards with all features
            DashboardStatsCards(
                currentStats = dashboardState,
                userTargets = userTargets,
                selectedPeriod = selectedPeriod.ordinal,
                monthViewType = if (monthViewType == MonthViewType.CALENDAR_MONTH) 0 else 1,
                averageDeductionPercentage = 30.0,
                defaultHourlyRate = 15.0,
                currentLanguage = currentLanguage,
                onDetailClick = { statType ->
                    navController.navigate("detail/$statType")
                }
            )

            // Empty state when no data
            if (!isLoading && dashboardState.totalRevenue == 0.0) {
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
        if (isLoading && !isRefreshing) {
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

// Old UI components removed - now using new components from separate files