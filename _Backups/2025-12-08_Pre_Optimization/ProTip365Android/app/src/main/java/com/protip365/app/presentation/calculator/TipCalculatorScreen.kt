package com.protip365.app.presentation.calculator

import androidx.compose.animation.*
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import java.text.NumberFormat
import java.util.*

@OptIn(ExperimentalAnimationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun TipCalculatorScreen(
    navController: NavController
) {
    var billAmount by remember { mutableStateOf("") }
    var tipPercentage by remember { mutableIntStateOf(18) }
    var customPercentage by remember { mutableStateOf("") }
    var useCustomPercentage by remember { mutableStateOf(false) }
    var splitCount by remember { mutableIntStateOf(1) }
    var selectedCalculatorTab by remember { mutableIntStateOf(0) }

    // For tip-out calculator
    var totalTips by remember { mutableStateOf("") }
    var tipOutPercentage by remember { mutableStateOf("") }

    // For hourly rate calculator
    var totalEarnings by remember { mutableStateOf("") }
    var hoursWorked by remember { mutableStateOf("") }

@Suppress("UNUSED_VARIABLE")
    val focusManager = LocalFocusManager.current
    val language = "en" // Get from settings/preferences

    val calculatedTip = remember(billAmount, tipPercentage, customPercentage, useCustomPercentage) {
        val bill = billAmount.toDoubleOrNull() ?: 0.0
        val percentage = if (useCustomPercentage) {
            customPercentage.toIntOrNull() ?: 0
        } else {
            tipPercentage
        }
        bill * percentage / 100
    }

    val totalWithTip = remember(billAmount, calculatedTip) {
        (billAmount.toDoubleOrNull() ?: 0.0) + calculatedTip
    }

    val perPersonAmount = remember(totalWithTip, splitCount) {
        if (splitCount > 0) totalWithTip / splitCount else 0.0
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = getLocalizedText("Tip Calculator", language),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = getLocalizedText("Back", language)
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
        ) {
            // Calculator Type Tabs
            TabRow(
                selectedTabIndex = selectedCalculatorTab,
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                Tab(
                    selected = selectedCalculatorTab == 0,
                    onClick = { selectedCalculatorTab = 0 },
                    text = { Text(getLocalizedText("Tip", language)) },
                    icon = { Icon(Icons.Default.Calculate, contentDescription = null) }
                )
                Tab(
                    selected = selectedCalculatorTab == 1,
                    onClick = { selectedCalculatorTab = 1 },
                    text = { Text(getLocalizedText("Tip-out", language)) },
                    icon = { Icon(Icons.Default.Share, contentDescription = null) }
                )
                Tab(
                    selected = selectedCalculatorTab == 2,
                    onClick = { selectedCalculatorTab = 2 },
                    text = { Text(getLocalizedText("Hourly", language)) },
                    icon = { Icon(Icons.Default.Schedule, contentDescription = null) }
                )
            }

            // Calculator Content
            AnimatedContent(
                targetState = selectedCalculatorTab,
                transitionSpec = {
                    slideInHorizontally { it } togetherWith slideOutHorizontally { -it }
                }
            ) { tab ->
                when (tab) {
                    0 -> TipCalculatorTab(
                        billAmount = billAmount,
                        onBillAmountChange = { billAmount = it },
                        tipPercentage = tipPercentage,
                        onTipPercentageChange = { tipPercentage = it },
                        customPercentage = customPercentage,
                        onCustomPercentageChange = { customPercentage = it },
                        useCustomPercentage = useCustomPercentage,
                        onUseCustomPercentageChange = { useCustomPercentage = it },
                        splitCount = splitCount,
                        onSplitCountChange = { splitCount = it },
                        calculatedTip = calculatedTip,
                        totalWithTip = totalWithTip,
                        perPersonAmount = perPersonAmount,
                        focusManager = focusManager,
                        language = language
                    )

                    1 -> TipOutCalculatorTab(
                        totalTips = totalTips,
                        onTotalTipsChange = { totalTips = it },
                        tipOutPercentage = tipOutPercentage,
                        onTipOutPercentageChange = { tipOutPercentage = it },
                        focusManager = focusManager,
                        language = language
                    )

                    2 -> HourlyRateCalculatorTab(
                        totalEarnings = totalEarnings,
                        onTotalEarningsChange = { totalEarnings = it },
                        hoursWorked = hoursWorked,
                        onHoursWorkedChange = { hoursWorked = it },
                        focusManager = focusManager,
                        language = language
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TipCalculatorTab(
    billAmount: String,
    onBillAmountChange: (String) -> Unit,
    tipPercentage: Int,
    onTipPercentageChange: (Int) -> Unit,
    customPercentage: String,
    onCustomPercentageChange: (String) -> Unit,
    useCustomPercentage: Boolean,
    onUseCustomPercentageChange: (Boolean) -> Unit,
    splitCount: Int,
    onSplitCountChange: (Int) -> Unit,
    calculatedTip: Double,
    totalWithTip: Double,
    perPersonAmount: Double,
    focusManager: androidx.compose.ui.focus.FocusManager,
    language: String
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Bill Amount Input
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = getLocalizedText("Bill Amount", language),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                OutlinedTextField(
                    value = billAmount,
                    onValueChange = { value ->
                        if (value.isEmpty() || value.matches(Regex("^\\d*\\.?\\d{0,2}$"))) {
                            onBillAmountChange(value)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("0.00") },
                    leadingIcon = { Text("$", style = MaterialTheme.typography.titleLarge) },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(androidx.compose.ui.focus.FocusDirection.Down) }
                    ),
                    singleLine = true,
                    textStyle = LocalTextStyle.current.copy(
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }

        // Tip Percentage Selection
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = getLocalizedText("Tip Percentage", language),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                // Quick percentage buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf(15, 18, 20, 25).forEach { percentage ->
                        PercentageButton(
                            percentage = percentage,
                            isSelected = !useCustomPercentage && tipPercentage == percentage,
                            onClick = {
                                onTipPercentageChange(percentage)
                                onUseCustomPercentageChange(false)
                            },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }

                // Custom percentage input
                OutlinedTextField(
                    value = customPercentage,
                    onValueChange = { value ->
                        if (value.isEmpty() || value.matches(Regex("^\\d{0,3}$"))) {
                            onCustomPercentageChange(value)
                            if (value.isNotEmpty()) {
                                onUseCustomPercentageChange(true)
                            }
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text(getLocalizedText("Custom %", language)) },
                    trailingIcon = { Text("%") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Number,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = { focusManager.clearFocus() }
                    ),
                    singleLine = true,
                    colors = if (useCustomPercentage) {
                        OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = MaterialTheme.colorScheme.primary,
                            unfocusedBorderColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
                        )
                    } else {
                        OutlinedTextFieldDefaults.colors()
                    }
                )

                // Tip percentage slider
                Column {
                    Text(
                        text = "${if (useCustomPercentage) customPercentage.toIntOrNull() ?: 0 else tipPercentage}%",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = TextAlign.Center
                    )
                    Slider(
                        value = (if (useCustomPercentage) customPercentage.toFloatOrNull() ?: 0f else tipPercentage.toFloat()),
                        onValueChange = { value ->
                            if (!useCustomPercentage) {
                                onTipPercentageChange(value.toInt())
                            } else {
                                onCustomPercentageChange(value.toInt().toString())
                            }
                        },
                        valueRange = 0f..50f,
                        steps = 49,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }

        // Split Bill Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = getLocalizedText("Split Bill", language),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = getLocalizedText("Number of People", language),
                        style = MaterialTheme.typography.bodyLarge
                    )

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        IconButton(
                            onClick = { if (splitCount > 1) onSplitCountChange(splitCount - 1) },
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Icon(
                                Icons.Default.Remove,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        Text(
                            text = splitCount.toString(),
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.widthIn(min = 40.dp),
                            textAlign = TextAlign.Center
                        )

                        IconButton(
                            onClick = { if (splitCount < 20) onSplitCountChange(splitCount + 1) },
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Icon(
                                Icons.Default.Add,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                if (splitCount > 1) {
                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.3f)
                        ),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                Icons.Default.Person,
                                contentDescription = null,
                                modifier = Modifier.size(20.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "${getLocalizedText("Per Person", language)}: ${
                                    NumberFormat.getCurrencyInstance(Locale.US).format(perPersonAmount)
                                }",
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        }

        // Results Summary
        ResultsCard(
            billAmount = billAmount.toDoubleOrNull() ?: 0.0,
            tipAmount = calculatedTip,
            totalAmount = totalWithTip,
            perPersonAmount = if (splitCount > 1) perPersonAmount else null,
            language = language
        )
    }
}

@Composable
private fun TipOutCalculatorTab(
    totalTips: String,
    onTotalTipsChange: (String) -> Unit,
    tipOutPercentage: String,
    onTipOutPercentageChange: (String) -> Unit,
    focusManager: androidx.compose.ui.focus.FocusManager,
    language: String
) {
    val tipOutAmount = remember(totalTips, tipOutPercentage) {
        val tips = totalTips.toDoubleOrNull() ?: 0.0
        val percentage = tipOutPercentage.toDoubleOrNull() ?: 0.0
        tips * percentage / 100
    }

    val keepAmount = remember(totalTips, tipOutAmount) {
        (totalTips.toDoubleOrNull() ?: 0.0) - tipOutAmount
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Total Tips Input
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = getLocalizedText("Total Tips", language),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                OutlinedTextField(
                    value = totalTips,
                    onValueChange = { value ->
                        if (value.isEmpty() || value.matches(Regex("^\\d*\\.?\\d{0,2}$"))) {
                            onTotalTipsChange(value)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("0.00") },
                    leadingIcon = { Text("$", style = MaterialTheme.typography.titleLarge) },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(androidx.compose.ui.focus.FocusDirection.Down) }
                    ),
                    singleLine = true,
                    textStyle = LocalTextStyle.current.copy(
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }

        // Tip-out Percentage
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = getLocalizedText("Tip-out Percentage", language),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                OutlinedTextField(
                    value = tipOutPercentage,
                    onValueChange = { value ->
                        if (value.isEmpty() || value.matches(Regex("^\\d{0,2}(\\.\\d{0,1})?${'$'}"))) {
                            onTipOutPercentageChange(value)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text(getLocalizedText("Percentage", language)) },
                    trailingIcon = { Text("%") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = { focusManager.clearFocus() }
                    ),
                    singleLine = true
                )

                // Common percentages
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("2", "2.5", "3", "5").forEach { percentage ->
                        FilterChip(
                            selected = tipOutPercentage == percentage,
                            onClick = { onTipOutPercentageChange(percentage) },
                            label = { Text("$percentage%") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }

        // Results
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            )
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = getLocalizedText("Breakdown", language),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                ResultRow(
                    label = getLocalizedText("Tip-out Amount", language),
                    value = NumberFormat.getCurrencyInstance(Locale.US).format(tipOutAmount),
                    color = MaterialTheme.colorScheme.error
                )

                ResultRow(
                    label = getLocalizedText("You Keep", language),
                    value = NumberFormat.getCurrencyInstance(Locale.US).format(keepAmount),
                    color = MaterialTheme.colorScheme.primary,
                    isHighlighted = true
                )
            }
        }
    }
}

@Composable
private fun HourlyRateCalculatorTab(
    totalEarnings: String,
    onTotalEarningsChange: (String) -> Unit,
    hoursWorked: String,
    onHoursWorkedChange: (String) -> Unit,
    focusManager: androidx.compose.ui.focus.FocusManager,
    language: String
) {
    val hourlyRate = remember(totalEarnings, hoursWorked) {
        val earnings = totalEarnings.toDoubleOrNull() ?: 0.0
        val hours = hoursWorked.toDoubleOrNull() ?: 0.0
        if (hours > 0) earnings / hours else 0.0
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Total Earnings Input
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = getLocalizedText("Total Earnings", language),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                OutlinedTextField(
                    value = totalEarnings,
                    onValueChange = { value ->
                        if (value.isEmpty() || value.matches(Regex("^\\d*\\.?\\d{0,2}$"))) {
                            onTotalEarningsChange(value)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("0.00") },
                    leadingIcon = { Text("$", style = MaterialTheme.typography.titleLarge) },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(androidx.compose.ui.focus.FocusDirection.Down) }
                    ),
                    singleLine = true,
                    textStyle = LocalTextStyle.current.copy(
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }

        // Hours Worked Input
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = getLocalizedText("Hours Worked", language),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                OutlinedTextField(
                    value = hoursWorked,
                    onValueChange = { value ->
                        if (value.isEmpty() || value.matches(Regex("^\\d{0,3}(\\.\\d{0,2})?${'$'}"))) {
                            onHoursWorkedChange(value)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("0.0") },
                    trailingIcon = { Text("hrs") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = { focusManager.clearFocus() }
                    ),
                    singleLine = true,
                    textStyle = LocalTextStyle.current.copy(
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }

        // Result
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = getLocalizedText("Hourly Rate", language),
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "${'$'}{NumberFormat.getCurrencyInstance(Locale.US).format(hourlyRate)}/hr",
                    style = MaterialTheme.typography.displayMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }

        // Comparison with targets
        if (hourlyRate > 0) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = getLocalizedText("Comparison", language),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )

                    // Minimum wage comparison (example: ${'$'}15)
                    ComparisonRow(
                        label = getLocalizedText("vs Minimum Wage", language),
                        baseValue = 15.0,
                        actualValue = hourlyRate
                    )

                    // Average service industry (example: ${'$'}25)
                    ComparisonRow(
                        label = getLocalizedText("vs Industry Average", language),
                        baseValue = 25.0,
                        actualValue = hourlyRate
                    )
                }
            }
        }
    }
}

@Composable
private fun PercentageButton(
    percentage: Int,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    FilledTonalButton(
        onClick = onClick,
        modifier = modifier,
        colors = if (isSelected) {
            ButtonDefaults.filledTonalButtonColors(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            )
        } else {
            ButtonDefaults.filledTonalButtonColors()
        }
    ) {
        Text(
            text = "$percentage%",
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
        )
    }
}

@Composable
private fun ResultsCard(
    billAmount: Double,
    tipAmount: Double,
    totalAmount: Double,
    perPersonAmount: Double?,
    language: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = getLocalizedText("Summary", language),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            ResultRow(
                label = getLocalizedText("Bill", language),
                value = NumberFormat.getCurrencyInstance(Locale.US).format(billAmount)
            )

            ResultRow(
                label = getLocalizedText("Tip", language),
                value = NumberFormat.getCurrencyInstance(Locale.US).format(tipAmount),
                color = MaterialTheme.colorScheme.primary
            )

            HorizontalDivider()

            ResultRow(
                label = getLocalizedText("Total", language),
                value = NumberFormat.getCurrencyInstance(Locale.US).format(totalAmount),
                isHighlighted = true
            )

            perPersonAmount?.let {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.5f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            Icons.Default.Groups,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp),
                            tint = MaterialTheme.colorScheme.secondary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "${getLocalizedText("Each Person Pays", language)}: ${
                                NumberFormat.getCurrencyInstance(Locale.US).format(it)
                            }",
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ResultRow(
    label: String,
    value: String,
    color: Color = MaterialTheme.colorScheme.onSurface,
    isHighlighted: Boolean = false
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = if (isHighlighted) MaterialTheme.typography.titleMedium else MaterialTheme.typography.bodyLarge,
            fontWeight = if (isHighlighted) FontWeight.Medium else FontWeight.Normal,
            color = color
        )
        Text(
            text = value,
            style = if (isHighlighted) MaterialTheme.typography.titleLarge else MaterialTheme.typography.bodyLarge,
            fontWeight = if (isHighlighted) FontWeight.Bold else FontWeight.Medium,
            color = color
        )
    }
}

@Composable
private fun ComparisonRow(
    label: String,
    baseValue: Double,
    actualValue: Double
) {
    val difference = actualValue - baseValue
    val percentDifference = (difference / baseValue) * 100
    val isPositive = difference >= 0

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium
        )
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                if (isPositive) Icons.AutoMirrored.Filled.TrendingUp else Icons.AutoMirrored.Filled.TrendingDown,
                contentDescription = null,
                tint = if (isPositive) Color(0xFF4CAF50) else MaterialTheme.colorScheme.error,
                modifier = Modifier.size(20.dp)
            )
            Text(
                text = "${if (isPositive) "+" else ""}${String.format("%.1f%%", percentDifference)}",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium,
                color = if (isPositive) Color(0xFF4CAF50) else MaterialTheme.colorScheme.error
            )
        }
    }
}

private fun getLocalizedText(text: String, language: String): String {
    return when (language) {
        "fr" -> when (text) {
            "Tip Calculator" -> "Calculateur de pourboire"
            "Back" -> "Retour"
            "Tip" -> "Pourboire"
            "Tip-out" -> "Partage"
            "Hourly" -> "Taux horaire"
            "Bill Amount" -> "Montant de la facture"
            "Tip Percentage" -> "Pourcentage de pourboire"
            "Custom %" -> "% personnalisé"
            "Split Bill" -> "Diviser la facture"
            "Number of People" -> "Nombre de personnes"
            "Per Person" -> "Par personne"
            "Summary" -> "Résumé"
            "Bill" -> "Facture"
            "Total" -> "Total"
            "Each Person Pays" -> "Chaque personne paie"
            "Total Tips" -> "Pourboires totaux"
            "Tip-out Percentage" -> "Pourcentage de partage"
            "Percentage" -> "Pourcentage"
            "Breakdown" -> "Répartition"
            "Tip-out Amount" -> "Montant du partage"
            "You Keep" -> "Vous gardez"
            "Total Earnings" -> "Gains totaux"
            "Hours Worked" -> "Heures travaillées"
            "Hourly Rate" -> "Taux horaire"
            "Comparison" -> "Comparaison"
            "vs Minimum Wage" -> "vs Salaire minimum"
            "vs Industry Average" -> "vs Moyenne de l'industrie"
            else -> text
        }
        "es" -> when (text) {
            "Tip Calculator" -> "Calculadora de propinas"
            "Back" -> "Atrás"
            "Tip" -> "Propina"
            "Tip-out" -> "Reparto"
            "Hourly" -> "Por hora"
            "Bill Amount" -> "Monto de la factura"
            "Tip Percentage" -> "Porcentaje de propina"
            "Custom %" -> "% personalizado"
            "Split Bill" -> "Dividir factura"
            "Number of People" -> "Número de personas"
            "Per Person" -> "Por persona"
            "Summary" -> "Resumen"
            "Bill" -> "Factura"
            "Total" -> "Total"
            "Each Person Pays" -> "Cada persona paga"
            "Total Tips" -> "Propinas totales"
            "Tip-out Percentage" -> "Porcentaje de reparto"
            "Percentage" -> "Porcentaje"
            "Breakdown" -> "Desglose"
            "Tip-out Amount" -> "Cantidad de reparto"
            "You Keep" -> "Te quedas con"
            "Total Earnings" -> "Ganancias totales"
            "Hours Worked" -> "Horas trabajadas"
            "Hourly Rate" -> "Tarifa por hora"
            "Comparison" -> "Comparación"
            "vs Minimum Wage" -> "vs Salario mínimo"
            "vs Industry Average" -> "vs Promedio de la industria"
            else -> text
        }
        else -> text
    }
}