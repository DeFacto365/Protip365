package com.protip365.app.presentation.calculator

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.protip365.app.presentation.design.IconMapping
import java.text.NumberFormat
import java.util.*

@Composable
fun CalculatorScreen() {
    var selectedTab by remember { mutableStateOf(0) }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TabRow(selectedTabIndex = selectedTab) {
            Tab(
                selected = selectedTab == 0,
                onClick = { selectedTab = 0 },
                text = { Text("Tip Calculator") },
                icon = { Icon(IconMapping.Financial.tips, contentDescription = null) }
            )
            Tab(
                selected = selectedTab == 1,
                onClick = { selectedTab = 1 },
                text = { Text("Tip-out") },
                icon = { Icon(IconMapping.Actions.share, contentDescription = null) }
            )
            Tab(
                selected = selectedTab == 2,
                onClick = { selectedTab = 2 },
                text = { Text("Hourly Rate") },
                icon = { Icon(IconMapping.Financial.hours, contentDescription = null) }
            )
        }

        when (selectedTab) {
            0 -> TipCalculator()
            1 -> TipOutCalculator()
            2 -> HourlyRateCalculator()
        }
    }
}

@Composable
fun TipCalculator() {
    var billAmount by remember { mutableStateOf("") }
    var tipPercentage by remember { mutableStateOf("20") }
    var numberOfPeople by remember { mutableStateOf("1") }

    val bill = billAmount.toDoubleOrNull() ?: 0.0
    val tip = tipPercentage.toDoubleOrNull() ?: 0.0
    val people = numberOfPeople.toIntOrNull()?.coerceAtLeast(1) ?: 1

    val tipAmount = bill * (tip / 100)
    val totalAmount = bill + tipAmount
    val perPersonAmount = totalAmount / people

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Bill amount input
        OutlinedTextField(
            value = billAmount,
            onValueChange = { billAmount = it },
            label = { Text("Bill Amount") },
            leadingIcon = { 
                Icon(
                    imageVector = IconMapping.Financial.sales,
                    contentDescription = "Bill amount",
                    tint = MaterialTheme.colorScheme.primary
                )
            },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Decimal,
                imeAction = ImeAction.Next
            ),
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        // Tip percentage
        Column {
            Text(
                text = "Tip Percentage: ${tipPercentage}%",
                style = MaterialTheme.typography.bodyLarge
            )
            Slider(
                value = tip.toFloat(),
                onValueChange = { tipPercentage = it.toInt().toString() },
                valueRange = 0f..50f,
                steps = 49,
                modifier = Modifier.fillMaxWidth()
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                listOf("15", "18", "20", "25").forEach { percent ->
                    FilterChip(
                        selected = tipPercentage == percent,
                        onClick = { tipPercentage = percent },
                        label = { Text("$percent%") }
                    )
                }
            }
        }

        // Number of people
        OutlinedTextField(
            value = numberOfPeople,
            onValueChange = { numberOfPeople = it },
            label = { Text("Number of People") },
            leadingIcon = { Icon(Icons.Default.People, contentDescription = null) },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Number,
                imeAction = ImeAction.Done
            ),
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        Divider()

        // Results
        ResultCard(
            title = "Tip Amount",
            amount = tipAmount,
            isHighlighted = false
        )

        ResultCard(
            title = "Total Amount",
            amount = totalAmount,
            isHighlighted = true
        )

        if (people > 1) {
            ResultCard(
                title = "Per Person",
                amount = perPersonAmount,
                isHighlighted = false
            )
        }
    }
}

@Composable
fun TipOutCalculator() {
    var totalTips by remember { mutableStateOf("") }
    var barPercentage by remember { mutableStateOf("5") }
    var busserPercentage by remember { mutableStateOf("3") }
    var runnerPercentage by remember { mutableStateOf("2") }

    val tips = totalTips.toDoubleOrNull() ?: 0.0
    val bar = barPercentage.toDoubleOrNull() ?: 0.0
    val busser = busserPercentage.toDoubleOrNull() ?: 0.0
    val runner = runnerPercentage.toDoubleOrNull() ?: 0.0

    val barAmount = tips * (bar / 100)
    val busserAmount = tips * (busser / 100)
    val runnerAmount = tips * (runner / 100)
    val totalTipOut = barAmount + busserAmount + runnerAmount
    val keepAmount = tips - totalTipOut

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Total tips input
        OutlinedTextField(
            value = totalTips,
            onValueChange = { totalTips = it },
            label = { Text("Total Tips") },
            leadingIcon = { Text("$", style = MaterialTheme.typography.bodyLarge) },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Decimal,
                imeAction = ImeAction.Done
            ),
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        // Tip-out percentages
        Text(
            text = "Tip-out Distribution",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Medium
        )

        TipOutField(
            label = "Bar",
            percentage = barPercentage,
            amount = barAmount,
            onPercentageChange = { barPercentage = it }
        )

        TipOutField(
            label = "Busser",
            percentage = busserPercentage,
            amount = busserAmount,
            onPercentageChange = { busserPercentage = it }
        )

        TipOutField(
            label = "Runner",
            percentage = runnerPercentage,
            amount = runnerAmount,
            onPercentageChange = { runnerPercentage = it }
        )

        Divider()

        // Results
        ResultCard(
            title = "Total Tip-out",
            amount = totalTipOut,
            isHighlighted = false
        )

        ResultCard(
            title = "You Keep",
            amount = keepAmount,
            isHighlighted = true
        )

        // Percentage kept
        if (tips > 0) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Text(
                    text = "You keep ${((keepAmount / tips) * 100).format(1)}% of your tips",
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.padding(16.dp),
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
fun HourlyRateCalculator() {
    var totalEarnings by remember { mutableStateOf("") }
    var hoursWorked by remember { mutableStateOf("") }
    var includeBreaks by remember { mutableStateOf(false) }
    var breakMinutes by remember { mutableStateOf("30") }

    val earnings = totalEarnings.toDoubleOrNull() ?: 0.0
    val hours = hoursWorked.toDoubleOrNull() ?: 0.0
    val breaks = if (includeBreaks) (breakMinutes.toDoubleOrNull() ?: 0.0) / 60 else 0.0
    val effectiveHours = (hours - breaks).coerceAtLeast(0.0)

    val hourlyRate = if (effectiveHours > 0) earnings / effectiveHours else 0.0

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Total earnings input
        OutlinedTextField(
            value = totalEarnings,
            onValueChange = { totalEarnings = it },
            label = { Text("Total Earnings") },
            leadingIcon = { Text("$", style = MaterialTheme.typography.bodyLarge) },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Decimal,
                imeAction = ImeAction.Next
            ),
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        // Hours worked
        OutlinedTextField(
            value = hoursWorked,
            onValueChange = { hoursWorked = it },
            label = { Text("Hours Worked") },
            leadingIcon = { Icon(Icons.Default.Timer, contentDescription = null) },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Decimal,
                imeAction = if (includeBreaks) ImeAction.Next else ImeAction.Done
            ),
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        // Break time
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = includeBreaks,
                onCheckedChange = { includeBreaks = it }
            )
            Text("Subtract break time")
        }

        if (includeBreaks) {
            OutlinedTextField(
                value = breakMinutes,
                onValueChange = { breakMinutes = it },
                label = { Text("Break Minutes") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Number,
                    imeAction = ImeAction.Done
                ),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
        }

        Divider()

        // Results
        ResultCard(
            title = "Effective Hourly Rate",
            amount = hourlyRate,
            isHighlighted = true,
            suffix = "/hr"
        )

        if (effectiveHours > 0) {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Breakdown",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Medium
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Effective hours")
                        Text("${effectiveHours.format(2)}h")
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Daily (8h)")
                        Text(formatCurrency(hourlyRate * 8))
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Weekly (40h)")
                        Text(formatCurrency(hourlyRate * 40))
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Monthly (160h)")
                        Text(formatCurrency(hourlyRate * 160))
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Yearly (2080h)")
                        Text(formatCurrency(hourlyRate * 2080))
                    }
                }
            }
        }
    }
}

@Composable
fun TipOutField(
    label: String,
    percentage: String,
    amount: Double,
    onPercentageChange: (String) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        OutlinedTextField(
            value = percentage,
            onValueChange = onPercentageChange,
            label = { Text(label) },
            suffix = { Text("%") },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Number,
                imeAction = ImeAction.Next
            ),
            modifier = Modifier.weight(1f),
            singleLine = true
        )
        Text(
            text = formatCurrency(amount),
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f),
            textAlign = TextAlign.End
        )
    }
}

@Composable
fun ResultCard(
    title: String,
    amount: Double,
    isHighlighted: Boolean,
    suffix: String = ""
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = if (isHighlighted) {
            CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        } else {
            CardDefaults.cardColors()
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = if (suffix.isNotEmpty()) {
                    "${formatCurrency(amount)}$suffix"
                } else {
                    formatCurrency(amount)
                },
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = if (isHighlighted) {
                    MaterialTheme.colorScheme.onPrimaryContainer
                } else {
                    MaterialTheme.colorScheme.onSurface
                }
            )
        }
    }
}

private fun formatCurrency(amount: Double): String {
    return NumberFormat.getCurrencyInstance(Locale.US).format(amount)
}

private fun Double.format(decimals: Int) = "%.${decimals}f".format(this)