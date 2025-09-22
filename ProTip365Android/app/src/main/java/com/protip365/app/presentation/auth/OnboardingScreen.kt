package com.protip365.app.presentation.auth

import androidx.compose.animation.*
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
import androidx.hilt.navigation.compose.hiltViewModel
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
        OnboardingStep("Welcome", Icons.Default.WavingHand),
        OnboardingStep("Work Settings", Icons.Default.Work),
        OnboardingStep("Security", Icons.Default.Security),
        OnboardingStep("Subscription", Icons.Default.CreditCard),
        OnboardingStep("Complete", Icons.Default.CheckCircle)
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
                        slideInHorizontally { it } + fadeIn() with
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
                            slideInHorizontally { it } + fadeIn() with
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
                                imageVector = Icons.Default.ArrowBack,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Back")
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
                                    0 -> "Get Started"
                                    steps.size - 1 -> "Complete Setup"
                                    else -> "Next"
                                }
                            )
                            if (currentStep < steps.size - 1) {
                                Spacer(modifier = Modifier.width(8.dp))
                                Icon(
                                    imageVector = Icons.Default.ArrowForward,
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
                                contentDescription = "Dismiss",
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
            text = "Welcome to ProTip365!",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Track your tips, manage earnings, and reach your financial goals.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            text = "Choose your language:",
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.align(Alignment.Start)
        )

        Spacer(modifier = Modifier.height(16.dp))

        val languages = listOf(
            "en" to "English",
            "fr" to "Français",
            "es" to "Español"
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

    Column {
        Text(
            text = "Set up your work preferences",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Employer Name
        OutlinedTextField(
            value = state.employerName,
            onValueChange = { viewModel.setEmployerName(it) },
            label = { Text("Employer Name") },
            placeholder = { Text("e.g., Restaurant Name") },
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
                    it.isEmpty() -> "Hourly rate is required"
                    it.toDoubleOrNull() == null -> "Invalid number"
                    it.toDouble() < 0 -> "Must be positive"
                    else -> null
                }
            },
            label = { Text("Default Hourly Rate") },
            prefix = { Text("$") },
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
                    it.isEmpty() -> "Tip target is required"
                    it.toDoubleOrNull() == null -> "Invalid number"
                    it.toDouble() < 0 || it.toDouble() > 100 -> "Must be 0-100"
                    else -> null
                }
            },
            label = { Text("Daily Tip Target") },
            suffix = { Text("%") },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Default.TrendingUp,
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

        // Week Start
        Text(
            text = "Week starts on",
            style = MaterialTheme.typography.bodyMedium
        )

        Spacer(modifier = Modifier.height(8.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            FilterChip(
                selected = state.weekStartsMonday == false,
                onClick = { viewModel.setWeekStart(false) },
                label = { Text("Sunday") },
                leadingIcon = if (state.weekStartsMonday == false) {{
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                }} else null
            )

            FilterChip(
                selected = state.weekStartsMonday == true,
                onClick = { viewModel.setWeekStart(true) },
                label = { Text("Monday") },
                leadingIcon = if (state.weekStartsMonday == true) {{
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                }} else null
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SecurityStep(state: OnboardingState, viewModel: OnboardingViewModel) {
    var confirmPin by remember { mutableStateOf("") }
    var pinError by remember { mutableStateOf<String?>(null) }
    var confirmPinError by remember { mutableStateOf<String?>(null) }

    Column {
        Text(
            text = "Secure your data",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Text(
            text = "Optional: Add a PIN for extra security",
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
                        text = if (state.usePin) "PIN Security Enabled" else "No PIN Security",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = if (state.usePin) "Your data will be protected"
                               else "Quick access without PIN",
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
                                value.length < 4 -> "PIN must be 4 digits"
                                else -> null
                            }
                        }
                    },
                    label = { Text("Create 4-digit PIN") },
                    placeholder = { Text("••••") },
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
                                value.isEmpty() -> "Please confirm PIN"
                                value != state.pin -> "PINs do not match"
                                else -> null
                            }
                        }
                    },
                    label = { Text("Confirm PIN") },
                    placeholder = { Text("••••") },
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
                                text = "Use Fingerprint/Face ID",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            Text(
                                text = "Quick and secure access",
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
                text = "Choose your plan",
                style = MaterialTheme.typography.bodyLarge
            )
            Badge(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ) {
                Text(
                    text = "7-DAY FREE TRIAL",
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Part-Time Card
        SubscriptionCard(
            title = "Part-Time",
            price = "$2.99",
            period = "month",
            features = listOf(
                "3 shifts per week",
                "3 entries per shift",
                "Basic analytics",
                "Single employer"
            ),
            selected = state.selectedSubscription == "parttime",
            onClick = { viewModel.selectSubscription("parttime") }
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Full Access Card
        SubscriptionCard(
            title = "Full Access",
            price = "$4.99",
            period = "month",
            features = listOf(
                "Unlimited shifts & entries",
                "Multiple employers",
                "Advanced analytics",
                "Export to CSV/PDF",
                "Priority support"
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
            Text("Decide later")
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
                    text = "You can change or cancel your subscription anytime",
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
            text = "All Set!",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Your ProTip365 account is ready.",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Start tracking your tips and reach your financial goals.",
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
                    text = "Your Settings",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(12.dp))

                SummaryItem(
                    icon = Icons.Default.Language,
                    label = "Language",
                    value = when(state.language) {
                        "fr" -> "Français"
                        "es" -> "Español"
                        else -> "English"
                    }
                )

                SummaryItem(
                    icon = Icons.Default.Business,
                    label = "Employer",
                    value = state.employerName.ifEmpty { "Not set" }
                )

                SummaryItem(
                    icon = Icons.Default.Security,
                    label = "Security",
                    value = if (state.usePin) "PIN enabled" else "No PIN"
                )

                SummaryItem(
                    icon = Icons.Default.CreditCard,
                    label = "Subscription",
                    value = when(state.selectedSubscription) {
                        "parttime" -> "Part-Time"
                        "full" -> "Full Access"
                        else -> "Free Trial"
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
                        Text("RECOMMENDED")
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
                        text = "Selected",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}