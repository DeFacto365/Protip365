package com.protip365.app.presentation.dashboard

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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
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
    val isLoading by viewModel.isLoading.collectAsState()

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
            // Period selector with localization
            DashboardPeriodSelector(
                selectedPeriod = selectedPeriod.ordinal,
                monthViewType = if (monthViewType == "grid") 0 else 1,
                onPeriodSelected = { viewModel.selectPeriod(DashboardPeriod.values()[it]) },
                onMonthViewTypeChanged = { /* Not implemented in ViewModel */ },
                currentLanguage = currentLanguage
            )

            // Stats cards with all features
            DashboardStatsCards(
                currentStats = DashboardStats(
                    totalRevenue = dashboardState.totalRevenue,
                    totalWages = dashboardState.totalWages,
                    totalTips = dashboardState.totalTips,
                    totalSales = dashboardState.totalSales,
                    totalHours = dashboardState.totalHours,
                    totalTipOut = dashboardState.totalTipOut,
                    otherIncome = dashboardState.otherIncome,
                    averageTipPercentage = dashboardState.averageTipPercentage,
                    hourlyRate = dashboardState.hourlyRate,
                    revenueChange = dashboardState.revenueChange,
                    wagesChange = dashboardState.wagesChange,
                    tipsChange = dashboardState.tipsChange,
                    hoursChange = dashboardState.hoursChange,
                    salesChange = dashboardState.salesChange,
                    tipOutChange = dashboardState.tipOutChange,
                    otherChange = dashboardState.otherChange
                ),
                userTargets = userTargets,
                selectedPeriod = selectedPeriod.ordinal,
                monthViewType = if (monthViewType == "grid") 0 else 1,
                averageDeductionPercentage = 0.0,
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
            text = when (currentLanguage) {
                "fr" -> "Aucune donnée encore"
                "es" -> "Sin datos aún"
                else -> "No data yet"
            },
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = when (currentLanguage) {
                "fr" -> "Commencez par ajouter votre premier quart de travail"
                "es" -> "Comience agregando su primer turno"
                else -> "Start by adding your first shift"
            },
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = onAddShift,
            modifier = Modifier.fillMaxWidth(0.6f)
        ) {
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Ajouter un quart"
                    "es" -> "Agregar turno"
                    else -> "Add Shift"
                }
            )
        }
    }
}

// Old UI components removed - now using new components from separate files