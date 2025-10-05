package com.protip365.app.presentation.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.presentation.dashboard.DashboardPeriod
import com.protip365.app.presentation.settings.SettingsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    navController: NavController,
    period: String = "today",
    statType: String = "total",
    viewModel: DetailViewModel = hiltViewModel(),
    settingsViewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val settingsState by settingsViewModel.state.collectAsState()
    
    val currentLanguage = settingsState.language
    val averageDeductionPercentage = settingsState.averageDeductionPercentage
    
    val localization = remember(currentLanguage) {
        DetailLocalization(currentLanguage)
    }
    
    val dashboardPeriod = when (period.lowercase()) {
        "week" -> DashboardPeriod.WEEK
        "month" -> DashboardPeriod.MONTH
        "year" -> DashboardPeriod.YEAR
        "four_weeks" -> DashboardPeriod.FOUR_WEEKS
        "custom" -> DashboardPeriod.CUSTOM
        else -> DashboardPeriod.TODAY
    }
    
    val targetAmount = when (dashboardPeriod) {
        DashboardPeriod.TODAY -> settingsState.dailyTarget
        DashboardPeriod.WEEK -> settingsState.weeklyTarget
        DashboardPeriod.MONTH -> settingsState.monthlyTarget
        DashboardPeriod.YEAR -> settingsState.yearlyTarget
        DashboardPeriod.FOUR_WEEKS -> settingsState.weeklyTarget * 4
        DashboardPeriod.CUSTOM -> settingsState.dailyTarget
    }
    
    LaunchedEffect(period, statType) {
        viewModel.loadShiftsForPeriod(dashboardPeriod, statType)
    }
    
    val titleText = "${localization.getPeriodText(period)} ${localization.detailTitle(statType)}"
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(titleText) },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = localization.doneText
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.background)
        ) {
            when {
                uiState.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                uiState.error != null -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Text(
                                text = uiState.error ?: "Error",
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.error
                            )
                            Button(onClick = { viewModel.refreshData() }) {
                                Text("Retry")
                            }
                        }
                    }
                }
                uiState.shifts.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                text = localization.noShiftsRecordedText,
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        }
                    }
                }
                else -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(vertical = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(20.dp)
                    ) {
                        DetailStatsSection(
                            shifts = uiState.shifts,
                            localization = localization,
                            averageDeductionPercentage = averageDeductionPercentage,
                            targetAmount = targetAmount
                        )
                        
                        DetailShiftsList(
                            shifts = uiState.shifts,
                            localization = localization,
                            averageDeductionPercentage = averageDeductionPercentage,
                            onEditShift = { shift ->
                                navController.navigate("edit_shift/${shift.id}")
                            }
                        )
                        
                        Spacer(modifier = Modifier.height(80.dp))
                    }
                }
            }
        }
    }
}

