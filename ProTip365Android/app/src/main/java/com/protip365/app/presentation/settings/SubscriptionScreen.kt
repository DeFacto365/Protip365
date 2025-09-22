package com.protip365.app.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SubscriptionScreen(
    navController: NavController,
    viewModel: SubscriptionViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBar(
            title = { Text("Subscription") },
            navigationIcon = {
                IconButton(onClick = { navController.navigateUp() }) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
            }
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Current Subscription
            CurrentSubscriptionCard(state)

            // Subscription Options
            Text(
                text = "Available Plans",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Medium
            )

            // Part-Time Pro
            SubscriptionPlanCard(
                title = "Part-Time Pro",
                price = "$2.99",
                period = "/month",
                features = listOf(
                    "3 shifts per week",
                    "3 entries per week",
                    "Basic analytics",
                    "Export to CSV",
                    "Single employer"
                ),
                isCurrentPlan = state.currentTier == "part_time",
                isRecommended = false,
                onSubscribe = {
                    viewModel.subscribeToPlan("part_time")
                }
            )

            // Full Access
            SubscriptionPlanCard(
                title = "Full Access",
                price = "$4.99",
                period = "/month",
                features = listOf(
                    "Unlimited shifts",
                    "Unlimited entries",
                    "Advanced analytics",
                    "Export to CSV",
                    "Multiple employers",
                    "Priority support",
                    "Achievements & badges",
                    "Custom targets"
                ),
                isCurrentPlan = state.currentTier == "full_access",
                isRecommended = true,
                onSubscribe = {
                    viewModel.subscribeToPlan("full_access")
                }
            )

            // Features comparison
            Spacer(modifier = Modifier.height(8.dp))
            
            // Manage Subscription
            if (state.currentTier != "free") {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text(
                            text = "Manage Subscription",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Medium
                        )
                        
                        OutlinedButton(
                            onClick = { viewModel.cancelSubscription() },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Text("Cancel Subscription")
                        }
                        
                        Text(
                            text = "You can cancel anytime. Your subscription will remain active until the end of the current billing period.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }

            // Terms
            Text(
                text = "Subscriptions are billed monthly and can be cancelled anytime. All prices are in USD.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }
    }

    if (state.isLoading) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
    }
}

@Composable
fun CurrentSubscriptionCard(state: SubscriptionState) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when (state.currentTier) {
                "full_access" -> MaterialTheme.colorScheme.primaryContainer
                "part_time" -> MaterialTheme.colorScheme.secondaryContainer
                else -> MaterialTheme.colorScheme.surfaceVariant
            }
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                when (state.currentTier) {
                    "full_access" -> Icons.Default.Star
                    "part_time" -> Icons.Default.Schedule
                    else -> Icons.Default.Lock
                },
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = when (state.currentTier) {
                    "full_access" -> MaterialTheme.colorScheme.onPrimaryContainer
                    "part_time" -> MaterialTheme.colorScheme.onSecondaryContainer
                    else -> MaterialTheme.colorScheme.onSurfaceVariant
                }
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = when (state.currentTier) {
                    "full_access" -> "Full Access"
                    "part_time" -> "Part-Time Pro"
                    else -> "Free Trial"
                },
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = when (state.currentTier) {
                    "full_access" -> "Unlimited everything"
                    "part_time" -> "3 shifts & entries per week"
                    else -> "Limited features"
                },
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            if (state.expiresAt != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = if (state.willRenew) {
                        "Renews on ${state.expiresAt}"
                    } else {
                        "Expires on ${state.expiresAt}"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            if (state.currentTier != "free") {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    AssistChip(
                        onClick = { },
                        label = { Text("Active") },
                        leadingIcon = {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SubscriptionPlanCard(
    title: String,
    price: String,
    period: String,
    features: List<String>,
    isCurrentPlan: Boolean,
    isRecommended: Boolean,
    onSubscribe: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = if (isRecommended) {
            CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        } else {
            CardDefaults.cardColors()
        }
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            if (isRecommended) {
                AssistChip(
                    onClick = { },
                    label = { Text("RECOMMENDED") },
                    colors = AssistChipDefaults.assistChipColors(
                        containerColor = MaterialTheme.colorScheme.primary,
                        labelColor = MaterialTheme.colorScheme.onPrimary
                    ),
                    border = null
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

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
                        text = period,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(bottom = 4.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            features.forEach { feature ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                        tint = if (isRecommended) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.primary
                        }
                    )
                    Text(
                        text = feature,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            if (isCurrentPlan) {
                OutlinedButton(
                    onClick = { },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = false
                ) {
                    Text("Current Plan")
                }
            } else {
                Button(
                    onClick = onSubscribe,
                    modifier = Modifier.fillMaxWidth(),
                    colors = if (!isRecommended) {
                        ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.secondary
                        )
                    } else {
                        ButtonDefaults.buttonColors()
                    }
                ) {
                    Text("Subscribe")
                }
            }
        }
    }
}