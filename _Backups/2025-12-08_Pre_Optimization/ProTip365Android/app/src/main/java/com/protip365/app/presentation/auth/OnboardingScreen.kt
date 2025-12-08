package com.protip365.app.presentation.auth

import androidx.compose.animation.*
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.hilt.navigation.compose.hiltViewModel
import com.protip365.app.R
import com.protip365.app.presentation.localization.LocalizationManager
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class, ExperimentalAnimationApi::class)
@Composable
fun OnboardingScreen(
    onComplete: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val scope = rememberCoroutineScope()

    var currentStep by remember { mutableStateOf(0) }
    val steps = listOf(
        OnboardingStep(stringResource(R.string.welcome), Icons.Default.WavingHand),
        OnboardingStep(stringResource(R.string.work_settings), Icons.Default.Work),
        OnboardingStep(stringResource(R.string.security), Icons.Default.Security),
        OnboardingStep(stringResource(R.string.subscription), Icons.Default.CreditCard),
        OnboardingStep(stringResource(R.string.complete), Icons.Default.CheckCircle)
    )

    // Handle completion
    LaunchedEffect(state.isComplete) {
        if (state.isComplete) {
            delay(500)
            onComplete()
        }
    }

    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Progress indicator
            LinearProgressIndicator(
                progress = { (currentStep + 1) / steps.size.toFloat() },
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.surfaceVariant
            )
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(24.dp)
            ) {
                // Step indicator
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    steps.forEachIndexed { index, _ ->
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(
                                    if (index <= currentStep) MaterialTheme.colorScheme.primary
                                    else MaterialTheme.colorScheme.surfaceVariant
                                )
                        )
                        if (index < steps.size - 1) {
                            Spacer(modifier = Modifier.width(8.dp))
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Step icon and title
                AnimatedContent(
                    targetState = currentStep,
                    transitionSpec = {
                        slideInHorizontally { it } + fadeIn() togetherWith
                        slideOutHorizontally { -it } + fadeOut()
                    }
                ) { step ->
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Box(
                            modifier = Modifier
                                .size(80.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primaryContainer),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = steps[step].icon,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        Text(
                            text = steps[step].title,
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Step content
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    ),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    AnimatedContent(
                        targetState = currentStep,
                        transitionSpec = {
                            slideInHorizontally { it } + fadeIn() togetherWith
                            slideOutHorizontally { -it } + fadeOut()
                        },
                        modifier = Modifier.padding(24.dp)
                    ) { step ->
                        when (step) {
                            0 -> WelcomeStep(state, viewModel)
                            1 -> WorkSettingsStep(state, viewModel)
                            2 -> SecurityStep(state, viewModel)
                            3 -> SubscriptionStep(state, viewModel)
                            4 -> CompletionStep(state)
                        }
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                // Navigation buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    AnimatedVisibility(
                        visible = currentStep > 0 && currentStep < steps.size - 1,
                        enter = fadeIn() + slideInHorizontally(),
                        exit = fadeOut() + slideOutHorizontally()
                    ) {
                        OutlinedButton(
                            onClick = { currentStep-- },
                            enabled = !state.isLoading
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(stringResource(R.string.back))
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    Button(
                        onClick = {
                            scope.launch {
                                if (currentStep < steps.size - 1) {
                                    if (viewModel.validateStep(currentStep)) {
                                        currentStep++
                                    }
                                } else {
                                    viewModel.completeOnboarding()
                                }
                            }
                        },
                        enabled = !state.isLoading && viewModel.canProceed(currentStep),
                        modifier = Modifier.widthIn(min = 120.dp)
                    ) {
                        if (state.isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = MaterialTheme.colorScheme.onPrimary,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text(
                                text = when (currentStep) {
                                    0 -> stringResource(R.string.get_started)
                                    steps.size - 1 -> stringResource(R.string.complete_setup)
                                    else -> stringResource(R.string.next)
                                }
                            )
                            if (currentStep < steps.size - 1) {
                                Spacer(modifier = Modifier.width(8.dp))
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }
                    }
                }
            }
        }

        // Error overlay
        AnimatedVisibility(
            visible = state.error != null,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            state.error?.let { error ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Error,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onErrorContainer
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = error,
                                color = MaterialTheme.colorScheme.onErrorContainer,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        IconButton(
                            onClick = { viewModel.clearError() }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = stringResource(R.string.cancel),
                                tint = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                }
            }
        }
    }
}

data class OnboardingStep(
    val title: String,
    val icon: ImageVector
)

@Composable
fun WelcomeStep(state: OnboardingState, viewModel: OnboardingViewModel) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = stringResource(R.string.welcome_to_protip365),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = stringResource(R.string.welcome_description),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Name field
        Text(
            text = "What's your name?",
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.align(Alignment.Start)
        )

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = state.name,
            onValueChange = { viewModel.setName(it) },
            label = { Text("Full Name") },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Text,
                imeAction = ImeAction.Next
            ),
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Enter your name") }
        )

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = stringResource(R.string.choose_your_language),
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.align(Alignment.Start)
        )

        Spacer(modifier = Modifier.height(16.dp))

        val languages = listOf(
            "en" to stringResource(R.string.english),
            "fr" to stringResource(R.string.french),
            "es" to stringResource(R.string.spanish)
        )

        languages.forEach { (code, name) ->
            RadioButtonOption(
                text = name,
                selected = state.language == code,
                onClick = { viewModel.setLanguage(code) }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkSettingsStep(state: OnboardingState, viewModel: OnboardingViewModel) {
    var hourlyRateError by remember { mutableStateOf<String?>(null) }
    var tipTargetError by remember { mutableStateOf<String?>(null) }

    // Pre-load string resources outside lambdas
    val errorRequiredField = stringResource(R.string.error_required_field)
    val invalidNumber = stringResource(R.string.invalid_number)
    val mustBePositive = stringResource(R.string.must_be_positive)
    val mustBe0To100 = stringResource(R.string.must_be_0_100)

    Column {
        Text(
            text = stringResource(R.string.set_up_work_preferences),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Employer Name
        OutlinedTextField(
            value = state.employerName,
            onValueChange = { viewModel.setEmployerName(it) },
            label = { Text(stringResource(R.string.employer_name)) },
            placeholder = { Text(stringResource(R.string.eg_restaurant_name)) },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Default.Business,
                    contentDescription = null
                )
            },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Hourly Rate
        OutlinedTextField(
            value = state.hourlyRate,
            onValueChange = {
                viewModel.setHourlyRate(it)
                hourlyRateError = when {
                    it.isEmpty() -> errorRequiredField
                    it.toDoubleOrNull() == null -> invalidNumber
                    it.toDouble() < 0 -> mustBePositive
                    else -> null
                }
            },
            label = { Text(stringResource(R.string.default_hourly_rate)) },
            prefix = { Text(stringResource(R.string.currency_symbol)) },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Default.AttachMoney,
                    contentDescription = null
                )
            },
            isError = hourlyRateError != null,
            supportingText = hourlyRateError?.let { { Text(it) } },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Decimal,
                imeAction = ImeAction.Next
            ),
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Tip Target
        OutlinedTextField(
            value = state.tipTarget,
            onValueChange = {
                viewModel.setTipTarget(it)
                tipTargetError = when {
                    it.isEmpty() -> errorRequiredField
                    it.toDoubleOrNull() == null -> invalidNumber
                    it.toDouble() < 0 || it.toDouble() > 100 -> mustBe0To100
                    else -> null
                }
            },
            label = { Text(stringResource(R.string.tip_percentage_target)) },
            suffix = { Text(stringResource(R.string.percentage_symbol)) },
            leadingIcon = {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.TrendingUp,
                    contentDescription = null
                )
            },
            isError = tipTargetError != null,
            supportingText = tipTargetError?.let { { Text(it) } },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Number,
                imeAction = ImeAction.Done
            ),
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Week Start Day Dropdown
        var weekStartExpanded by remember { mutableStateOf(false) }

        val weekDays = listOf(
            0 to stringResource(R.string.sunday),
            1 to stringResource(R.string.monday),
            2 to stringResource(R.string.tuesday),
            3 to stringResource(R.string.wednesday),
            4 to stringResource(R.string.thursday),
            5 to stringResource(R.string.friday),
            6 to stringResource(R.string.saturday)
        )

        // Convert boolean weekStartsMonday to day index (0-6)
        val selectedDayIndex = if (state.weekStartsMonday == true) 1 else 0
        val selectedDayName = weekDays.find { it.first == selectedDayIndex }?.second ?: weekDays[0].second

        ExposedDropdownMenuBox(
            expanded = weekStartExpanded,
            onExpandedChange = { weekStartExpanded = it },
            modifier = Modifier.fillMaxWidth()
        ) {
            OutlinedTextField(
                value = selectedDayName,
                onValueChange = {},
                readOnly = true,
                label = { Text(stringResource(R.string.week_start_day)) },
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = weekStartExpanded) },
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor(),
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.CalendarToday,
                        contentDescription = null
                    )
                }
            )

            ExposedDropdownMenu(
                expanded = weekStartExpanded,
                onDismissRequest = { weekStartExpanded = false },
                modifier = Modifier.fillMaxWidth()
            ) {
                weekDays.forEach { (dayIndex, dayName) ->
                    DropdownMenuItem(
                        text = { Text(dayName) },
                        onClick = {
                            // For now, only support Sunday (0) and Monday (1) in the backend
                            // but show all days in UI for better UX
                            viewModel.setWeekStart(dayIndex == 1)
                            weekStartExpanded = false
                        },
                        leadingIcon = if (dayIndex == selectedDayIndex) {
                            {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary
                                )
                            }
                        } else null
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Multiple Employers Toggle
        Card(
            modifier = Modifier.fillMaxWidth(),
            onClick = { viewModel.setUseMultipleEmployers(!state.useMultipleEmployers) }
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Business,
                    contentDescription = null,
                    tint = if (state.useMultipleEmployers) MaterialTheme.colorScheme.primary
                           else MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(16.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = stringResource(R.string.multiple_employers),
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = stringResource(R.string.work_for_multiple_employers),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Switch(
                    checked = state.useMultipleEmployers,
                    onCheckedChange = { viewModel.setUseMultipleEmployers(it) }
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Variable Schedule Toggle
        Card(
            modifier = Modifier.fillMaxWidth(),
            onClick = { viewModel.setVariableSchedule(!state.hasVariableSchedule) }
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Schedule,
                    contentDescription = null,
                    tint = if (state.hasVariableSchedule) MaterialTheme.colorScheme.primary
                           else MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(16.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = stringResource(R.string.variable_schedule),
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = stringResource(R.string.work_irregular_hours),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Switch(
                    checked = state.hasVariableSchedule,
                    onCheckedChange = { viewModel.setVariableSchedule(it) }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SecurityStep(state: OnboardingState, viewModel: OnboardingViewModel) {
    var confirmPin by remember { mutableStateOf("") }
    var pinError by remember { mutableStateOf<String?>(null) }
    var confirmPinError by remember { mutableStateOf<String?>(null) }

    // Pre-load string resources for PIN validation
    val pinMustBe4Digits = stringResource(R.string.pin_must_be_4_digits)
    val pleaseConfirmPin = stringResource(R.string.please_confirm_pin)
    val pinMismatch = stringResource(R.string.pin_mismatch)

    Column {
        Text(
            text = stringResource(R.string.secure_your_data),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Text(
            text = stringResource(R.string.optional_pin_security),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 4.dp)
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Security toggle
        Card(
            modifier = Modifier.fillMaxWidth(),
            onClick = { viewModel.toggleSecurity() }
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = if (state.usePin) Icons.Default.Lock else Icons.Default.LockOpen,
                    contentDescription = null,
                    tint = if (state.usePin) MaterialTheme.colorScheme.primary
                           else MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(16.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = if (state.usePin) stringResource(R.string.pin_security_enabled) else stringResource(R.string.no_pin_security),
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = if (state.usePin) stringResource(R.string.data_will_be_protected)
                               else stringResource(R.string.quick_access_without_pin),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Switch(
                    checked = state.usePin,
                    onCheckedChange = { viewModel.toggleSecurity() }
                )
            }
        }

        // PIN fields
        AnimatedVisibility(
            visible = state.usePin,
            enter = fadeIn() + expandVertically(),
            exit = fadeOut() + shrinkVertically()
        ) {
            Column {
                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = state.pin,
                    onValueChange = { value ->
                        if (value.length <= 4 && value.all { it.isDigit() }) {
                            viewModel.setPin(value)
                            pinError = when {
                                value.length < 4 -> pinMustBe4Digits
                                else -> null
                            }
                        }
                    },
                    label = { Text(stringResource(R.string.create_4_digit_pin)) },
                    placeholder = { Text(stringResource(R.string.placeholder_dots)) },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Pin,
                            contentDescription = null
                        )
                    },
                    isError = pinError != null,
                    supportingText = pinError?.let { { Text(it) } },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.NumberPassword,
                        imeAction = ImeAction.Next
                    ),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = confirmPin,
                    onValueChange = { value ->
                        if (value.length <= 4 && value.all { it.isDigit() }) {
                            confirmPin = value
                            confirmPinError = when {
                                value.isEmpty() -> pleaseConfirmPin
                                value != state.pin -> pinMismatch
                                else -> null
                            }
                        }
                    },
                    label = { Text(stringResource(R.string.confirm_pin)) },
                    placeholder = { Text(stringResource(R.string.placeholder_dots)) },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = null
                        )
                    },
                    isError = confirmPinError != null,
                    supportingText = confirmPinError?.let { { Text(it) } },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.NumberPassword,
                        imeAction = ImeAction.Done
                    ),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Biometric option
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    onClick = { viewModel.toggleBiometric() }
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Fingerprint,
                            contentDescription = null,
                            tint = if (state.useBiometric) MaterialTheme.colorScheme.primary
                                   else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(16.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = stringResource(R.string.use_fingerprint_face_id),
                                style = MaterialTheme.typography.bodyLarge
                            )
                            Text(
                                text = stringResource(R.string.quick_and_secure_access),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Switch(
                            checked = state.useBiometric,
                            onCheckedChange = { viewModel.toggleBiometric() }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun SubscriptionStep(state: OnboardingState, viewModel: OnboardingViewModel) {

    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.choose_your_plan),
                style = MaterialTheme.typography.bodyLarge
            )
            Badge(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ) {
                Text(
                    text = stringResource(R.string.free_trial).uppercase(),
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Part-Time Card
        SubscriptionCard(
            title = stringResource(R.string.part_time),
            price = "$2.99",
            period = stringResource(R.string.month),
            features = listOf(
                stringResource(R.string.three_shifts_per_week),
                stringResource(R.string.three_entries_per_shift),
                stringResource(R.string.basic_analytics),
                stringResource(R.string.single_employer)
            ),
            selected = state.selectedSubscription == "parttime",
            onClick = { viewModel.selectSubscription("parttime") }
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Full Access Card
        SubscriptionCard(
            title = stringResource(R.string.full_access),
            price = "$4.99",
            period = stringResource(R.string.month),
            features = listOf(
                stringResource(R.string.unlimited_everything),
                stringResource(R.string.multiple_employers),
                stringResource(R.string.advanced_analytics),
                stringResource(R.string.export_to_csv),
                stringResource(R.string.priority_support)
            ),
            selected = state.selectedSubscription == "full",
            recommended = true,
            onClick = { viewModel.selectSubscription("full") }
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Skip option
        TextButton(
            onClick = { viewModel.selectSubscription("skip") },
            modifier = Modifier.align(Alignment.CenterHorizontally)
        ) {
            Icon(
                imageVector = Icons.Default.Schedule,
                contentDescription = null,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(stringResource(R.string.decide_later))
        }

        // Info card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.secondaryContainer
            )
        ) {
            Row(
                modifier = Modifier.padding(12.dp),
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    imageVector = Icons.Default.Info,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSecondaryContainer
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = stringResource(R.string.subscription_cancel_anytime),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSecondaryContainer
                )
            }
        }
    }
}

@Composable
fun CompletionStep(state: OnboardingState) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.fillMaxWidth()
    ) {
        AnimatedVisibility(
            visible = true,
            enter = scaleIn() + fadeIn()
        ) {
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    modifier = Modifier.size(80.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            text = stringResource(R.string.all_set),
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = stringResource(R.string.protip365_account_ready),
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = stringResource(R.string.start_tracking_tips),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Summary card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = stringResource(R.string.your_settings),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(12.dp))

                SummaryItem(
                    icon = Icons.Default.Language,
                    label = stringResource(R.string.language),
                    value = when(state.language) {
                        "fr" -> stringResource(R.string.french)
                        "es" -> stringResource(R.string.spanish)
                        else -> stringResource(R.string.english)
                    }
                )

                SummaryItem(
                    icon = Icons.Default.Business,
                    label = stringResource(R.string.employer),
                    value = state.employerName.ifEmpty { stringResource(R.string.not_set) }
                )

                SummaryItem(
                    icon = Icons.Default.Security,
                    label = stringResource(R.string.security),
                    value = if (state.usePin) stringResource(R.string.pin_enabled) else stringResource(R.string.no_pin)
                )

                SummaryItem(
                    icon = Icons.Default.Work,
                    label = stringResource(R.string.multiple_employers),
                    value = if (state.useMultipleEmployers) stringResource(R.string.yes) else stringResource(R.string.no)
                )

                SummaryItem(
                    icon = Icons.Default.Schedule,
                    label = stringResource(R.string.variable_schedule),
                    value = if (state.hasVariableSchedule) stringResource(R.string.yes) else stringResource(R.string.no)
                )

                SummaryItem(
                    icon = Icons.Default.CreditCard,
                    label = stringResource(R.string.subscription),
                    value = when(state.selectedSubscription) {
                        "parttime" -> stringResource(R.string.part_time)
                        "full" -> stringResource(R.string.full_access)
                        else -> stringResource(R.string.free_trial)
                    }
                )
            }
        }
    }
}

@Composable
private fun SummaryItem(
    icon: ImageVector,
    label: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.width(80.dp)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
fun RadioButtonOption(
    text: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RadioButton(
            selected = selected,
            onClick = onClick
        )
        Spacer(modifier = Modifier.width(16.dp))
        Text(text = text, style = MaterialTheme.typography.bodyLarge)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SubscriptionCard(
    title: String,
    price: String,
    period: String,
    features: List<String>,
    selected: Boolean,
    recommended: Boolean = false,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        border = if (selected) {
            BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
        } else null,
        colors = CardDefaults.cardColors(
            containerColor = if (selected) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                           else MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                if (recommended) {
                    Badge(
                        containerColor = MaterialTheme.colorScheme.tertiary
                    ) {
                        Text(stringResource(R.string.recommended))
                    }
                }
            }

            Row(
                verticalAlignment = Alignment.Bottom
            ) {
                Text(
                    text = price,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "/$period",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                    modifier = Modifier.padding(start = 4.dp, bottom = 2.dp)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            features.forEach { feature ->
                Row(
                    modifier = Modifier.padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = feature,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }

            if (selected) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = stringResource(R.string.selected),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}