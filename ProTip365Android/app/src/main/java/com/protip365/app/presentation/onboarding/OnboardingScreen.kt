package com.protip365.app.presentation.onboarding

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.protip365.app.presentation.localization.rememberOnboardingLocalization

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OnboardingScreen(
    navController: NavController,
    onComplete: () -> Unit
) {
    var currentStep by remember { mutableStateOf(1) }
    var state by remember { mutableStateOf(OnboardingState()) }
    val totalSteps = 7
    val localization = rememberOnboardingLocalization()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        text = localization.welcomeTitle,
                        style = MaterialTheme.typography.headlineSmall
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp)
        ) {
            // Progress indicator
            OnboardingProgressBar(
                currentStep = currentStep,
                totalSteps = totalSteps
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Step content
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                when (currentStep) {
                    1 -> LanguageStep(
                        state = state,
                        localization = localization,
                        onLanguageSelected = { language ->
                            state = state.copy(language = language)
                        }
                    )
                    2 -> MultipleEmployersStep(
                        state = state,
                        onMultipleEmployersChanged = { useMultiple ->
                            state = state.copy(useMultipleEmployers = useMultiple)
                        }
                    )
                    3 -> WeekStartStep(
                        state = state,
                        onWeekStartChanged = { weekStart ->
                            state = state.copy(weekStart = weekStart)
                        }
                    )
                    4 -> SecurityStep(
                        state = state,
                        onSecurityTypeChanged = { securityType ->
                            state = state.copy(securityType = securityType)
                        }
                    )
                    5 -> VariableScheduleStep(
                        state = state,
                        onVariableScheduleChanged = { hasVariable ->
                            state = state.copy(hasVariableSchedule = hasVariable)
                        }
                    )
                    6 -> TargetsStep(
                        state = state,
                        onTargetsChanged = { tipPercentage, salesDaily, hoursDaily ->
                            state = state.copy(
                                tipTargetPercentage = tipPercentage,
                                targetSalesDaily = salesDaily,
                                targetHoursDaily = hoursDaily
                            )
                        }
                    )
                    7 -> CompletionStep(
                        onComplete = onComplete
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Navigation buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                if (currentStep > 1) {
                OutlinedButton(
                    onClick = { currentStep-- },
                    modifier = Modifier.weight(1f)
                ) {
                    Text(localization.backButtonText)
                }
                } else {
                    Spacer(modifier = Modifier.weight(1f))
                }
                
                Button(
                    onClick = {
                        if (currentStep < totalSteps) {
                            currentStep++
                        } else {
                            onComplete()
                        }
                    },
                    modifier = Modifier.weight(1f),
                    enabled = state.isStepValid()
                ) {
                    Text(
                        text = if (currentStep < totalSteps) localization.nextButtonText else localization.getStartedText
                    )
                }
            }
        }
    }
}

@Composable
fun OnboardingProgressBar(
    currentStep: Int,
    totalSteps: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Step $currentStep of $totalSteps",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = "${((currentStep.toFloat() / totalSteps) * 100).toInt()}%",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            LinearProgressIndicator(
                progress = currentStep.toFloat() / totalSteps,
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.outline
            )
        }
    }
}
