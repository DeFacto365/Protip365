package com.protip365.app.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.clickable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.presentation.components.TopAppBarWithBack

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HelpScreen(
    navController: NavController,
    viewModel: HelpViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBarWithBack(
            title = "Help & FAQ",
            onBackClick = { navController.popBackStack() }
        )

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Getting Started Section
            item {
                HelpSection(
                    title = "Getting Started",
                    items = listOf(
                        HelpItem(
                            question = "How do I add my first shift?",
                            answer = "Go to the Calendar tab, tap the + button, and select 'Add Shift'. Fill in your work details and save."
                        ),
                        HelpItem(
                            question = "How do I track my tips?",
                            answer = "After adding a shift, tap on it and select 'Add Entry' to record your tips, sales, and other earnings."
                        ),
                        HelpItem(
                            question = "How do I set up my employers?",
                            answer = "Go to Settings → Employers to add your workplace information, including hourly rates and addresses."
                        )
                    )
                )
            }

            // Dashboard Section
            item {
                HelpSection(
                    title = "Dashboard & Analytics",
                    items = listOf(
                        HelpItem(
                            question = "What do the dashboard stats show?",
                            answer = "The dashboard displays your earnings, hours worked, tips, and progress toward your goals for today, this week, and this month."
                        ),
                        HelpItem(
                            question = "How do I set my income targets?",
                            answer = "Go to Settings → Targets to set daily, weekly, and monthly goals for hours, tips, and sales."
                        ),
                        HelpItem(
                            question = "Can I export my data?",
                            answer = "Yes! Go to Settings → Export Data to download your shift and earnings data as CSV files."
                        )
                    )
                )
            }

            // Calendar Section
            item {
                HelpSection(
                    title = "Calendar & Shifts",
                    items = listOf(
                        HelpItem(
                            question = "How do I edit a shift?",
                            answer = "Tap on any shift in the calendar to view details, then tap 'Edit' to modify the information."
                        ),
                        HelpItem(
                            question = "What's the difference between planned and completed shifts?",
                            answer = "Planned shifts are your scheduled work. Completed shifts have actual earnings data recorded."
                        ),
                        HelpItem(
                            question = "How do I handle overnight shifts?",
                            answer = "When adding a shift that crosses midnight, the app automatically calculates the correct hours worked."
                        )
                    )
                )
            }

            // Notifications Section
            item {
                HelpSection(
                    title = "Notifications & Alerts",
                    items = listOf(
                        HelpItem(
                            question = "How do I set up shift reminders?",
                            answer = "When adding a shift, you can set reminder alerts for 15 minutes, 30 minutes, 1 hour, or 2 hours before your shift starts."
                        ),
                        HelpItem(
                            question = "Can I customize notification settings?",
                            answer = "Yes! Go to Settings → Notifications to enable or disable different types of alerts."
                        )
                    )
                )
            }

            // Security Section
            item {
                HelpSection(
                    title = "Security & Privacy",
                    items = listOf(
                        HelpItem(
                            question = "How do I protect my data?",
                            answer = "Go to Settings → Security to set up PIN protection or biometric authentication (fingerprint/face ID)."
                        ),
                        HelpItem(
                            question = "Is my data secure?",
                            answer = "Yes! All your data is encrypted and stored securely. We never share your personal information."
                        )
                    )
                )
            }

            // Troubleshooting Section
            item {
                HelpSection(
                    title = "Troubleshooting",
                    items = listOf(
                        HelpItem(
                            question = "The app is running slowly",
                            answer = "Try closing and reopening the app, or restart your device. Make sure you have a stable internet connection."
                        ),
                        HelpItem(
                            question = "I can't log in",
                            answer = "Check your internet connection and verify your email/password. Try resetting your password if needed."
                        ),
                        HelpItem(
                            question = "My data isn't syncing",
                            answer = "Ensure you have an active internet connection. Try signing out and back in to refresh the sync."
                        )
                    )
                )
            }

            // Contact Support
            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            Icons.Default.Support,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp)
                        )
                        
                        Text(
                            text = "Still need help?",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        
                        Text(
                            text = "Our support team is here to help you with any questions or issues.",
                            style = MaterialTheme.typography.bodyMedium
                        )
                        
                        Button(
                            onClick = { navController.navigate("contact") }
                        ) {
                            Icon(Icons.Default.Email, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Contact Support")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun HelpSection(
    title: String,
    items: List<HelpItem>
) {
    var expandedItems by remember { mutableStateOf(setOf<String>()) }
    
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 12.dp)
            )
            
            items.forEach { item ->
                val isExpanded = expandedItems.contains(item.question)
                
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { 
                                    expandedItems = if (isExpanded) {
                                        expandedItems - item.question
                                    } else {
                                        expandedItems + item.question
                                    }
                                }
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = item.question,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium,
                                modifier = Modifier.weight(1f)
                            )
                            
                            Icon(
                                if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                                contentDescription = null
                            )
                        }
                        
                        if (isExpanded) {
                            Text(
                                text = item.answer,
                                style = MaterialTheme.typography.bodySmall,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

data class HelpItem(
    val question: String,
    val answer: String
)
