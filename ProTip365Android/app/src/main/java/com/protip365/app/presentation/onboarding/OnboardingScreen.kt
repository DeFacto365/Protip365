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
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.presentation.localization.rememberOnboardingLocalization

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OnboardingScreen(
    navController: NavController,
    onComplete: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val currentStep = state.currentStep // Use currentStep from ViewModel state
    val totalSteps = 7 // Matching iOS: Language, Employers, Week Start, Security, Variable, Targets, How To Use
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
                    0 -> LanguageStep(
                        state = state,
                        localization = localization,
                        onLanguageSelected = { language ->
                            viewModel.updateLanguage(language)
                        }
                    )
                    1 -> {
                        // Load employers when entering this step (in case user just created them)
                        LaunchedEffect(Unit) {
                            if (state.useMultipleEmployers) {
                                viewModel.loadEmployers()
                            }
                        }

                        MultipleEmployersStep(
                            state = state,
                            onMultipleEmployersChanged = { useMultiple ->
                                viewModel.updateMultipleEmployers(useMultiple)
                            },
                            onSingleEmployerNameChanged = { name ->
                                viewModel.updateSingleEmployerName(name)
                            },
                            onDefaultEmployerChanged = { employerId ->
                                viewModel.updateDefaultEmployer(employerId)
                            },
                            onNavigateToEmployers = {
                                // Navigate to employers screen in onboarding mode
                                navController.navigate("employers?fromOnboarding=true")
                            }
                        )
                    }
                    2 -> WeekStartStep(
                        state = state,
                        onWeekStartChanged = { weekStart ->
                            viewModel.updateWeekStart(weekStart)
                        }
                    )
                    3 -> SecurityStep(
                        state = state,
                        onSecurityTypeChanged = { securityType ->
                            viewModel.updateSecurityType(securityType)
                        }
                    )
                    4 -> VariableScheduleStep(
                        state = state,
                        onVariableScheduleChanged = { hasVariable ->
                            viewModel.updateVariableSchedule(hasVariable)
                        }
                    )
                    5 -> TargetsStep(
                        state = state,
                        onTargetsChanged = { tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly ->
                            viewModel.updateTargets(tipPercentage, averageDeduction, salesDaily, hoursDaily, salesWeekly, hoursWeekly, salesMonthly, hoursMonthly)
                        }
                    )
                    6 -> HowToUseStep(
                        state = state
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))

            // Error message
            state.completionError?.let { error ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = error,
                        modifier = Modifier.padding(16.dp),
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Navigation buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                if (currentStep > 0) {
                OutlinedButton(
                    onClick = { viewModel.updateCurrentStep(currentStep - 1) },
                    modifier = Modifier.weight(1f)
                ) {
                    Text(localization.backButtonText)
                }
                } else {
                    Spacer(modifier = Modifier.weight(1f))
                }

                Button(
                    onClick = {
                        if (currentStep < totalSteps - 1) {
                            viewModel.updateCurrentStep(currentStep + 1)
                        } else {
                            // Last step - complete onboarding
                            viewModel.completeOnboarding(onComplete)
                        }
                    },
                    modifier = Modifier.weight(1f),
                    enabled = state.isStepValid() && !state.isCompleting
                ) {
                    if (state.isCompleting) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text(
                            text = if (currentStep < totalSteps - 1) localization.nextButtonText else "Finish"
                        )
                    }
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
                    text = "Step ${currentStep + 1} of $totalSteps",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = "${(((currentStep + 1).toFloat() / totalSteps) * 100).toInt()}%",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            LinearProgressIndicator(
                progress = (currentStep + 1).toFloat() / totalSteps,
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.outline
            )
        }
    }
}
