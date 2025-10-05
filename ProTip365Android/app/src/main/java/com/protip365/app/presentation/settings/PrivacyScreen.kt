package com.protip365.app.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
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
fun PrivacyScreen(
    navController: NavController,
    viewModel: PrivacyViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
    ) {
        TopAppBarWithBack(
            title = "Privacy Policy",
            onBackClick = { navController.popBackStack() }
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Last Updated
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Last Updated: January 2025",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Introduction
            PrivacySection(
                title = "Introduction",
                content = "ProTip365 is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application."
            )

            // Information We Collect
            PrivacySection(
                title = "Information We Collect",
                content = "We collect information you provide directly to us, such as when you create an account, add shifts, or contact us for support."
            )

            PrivacySubsection(
                title = "Personal Information",
                items = listOf(
                    "Email address and password for account creation",
                    "Name and profile information",
                    "Work schedule and shift data",
                    "Tip and earnings information",
                    "Employer information and workplace details"
                )
            )

            PrivacySubsection(
                title = "Usage Information",
                items = listOf(
                    "App usage patterns and preferences",
                    "Device information and operating system",
                    "Crash reports and performance data",
                    "Analytics data to improve our service"
                )
            )

            // How We Use Your Information
            PrivacySection(
                title = "How We Use Your Information",
                content = "We use the information we collect to provide, maintain, and improve our services."
            )

            PrivacySubsection(
                title = "Service Provision",
                items = listOf(
                    "Process and store your shift and earnings data",
                    "Generate reports and analytics",
                    "Send notifications and reminders",
                    "Provide customer support"
                )
            )

            PrivacySubsection(
                title = "Service Improvement",
                items = listOf(
                    "Analyze usage patterns to improve the app",
                    "Develop new features and functionality",
                    "Ensure app security and prevent fraud",
                    "Comply with legal obligations"
                )
            )

            // Data Security
            PrivacySection(
                title = "Data Security",
                content = "We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction."
            )

            PrivacySubsection(
                title = "Security Measures",
                items = listOf(
                    "Encryption of data in transit and at rest",
                    "Secure authentication and authorization",
                    "Regular security audits and updates",
                    "Access controls and monitoring"
                )
            )

            // Data Sharing
            PrivacySection(
                title = "Data Sharing",
                content = "We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy."
            )

            PrivacySubsection(
                title = "Limited Sharing",
                items = listOf(
                    "Service providers who assist in app operation",
                    "Legal requirements or court orders",
                    "Protection of rights and safety",
                    "Business transfers (with notice)"
                )
            )

            // Your Rights
            PrivacySection(
                title = "Your Rights",
                content = "You have certain rights regarding your personal information, including the right to access, update, or delete your data."
            )

            PrivacySubsection(
                title = "Your Choices",
                items = listOf(
                    "Access and update your account information",
                    "Export your data at any time",
                    "Delete your account and associated data",
                    "Opt out of certain communications",
                    "Control notification preferences"
                )
            )

            // Account Deletion
            PrivacySection(
                title = "Account Deletion",
                content = "You can delete your account and all associated data at any time through the app settings or by contacting us directly."
            )

            PrivacySubsection(
                title = "Deletion Methods",
                items = listOf(
                    "In-App: Settings → Account → Delete Account",
                    "Email: support@protip365.com",
                    "Web: protip365.com/delete-account"
                )
            )

            // Children's Privacy
            PrivacySection(
                title = "Children's Privacy",
                content = "Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13."
            )

            // Changes to This Policy
            PrivacySection(
                title = "Changes to This Policy",
                content = "We may update this Privacy Policy from time to time. We will notify you of any changes by updating the 'Last Updated' date and posting the new policy in the app."
            )

            // Contact Information
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Contact Us",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = "If you have questions about this Privacy Policy or your personal information, please contact us:",
                        style = MaterialTheme.typography.bodyMedium
                    )

                    ContactInfoRow(
                        icon = Icons.Default.Email,
                        label = "Email",
                        value = "support@protip365.com"
                    )

                    ContactInfoRow(
                        icon = Icons.Default.Phone,
                        label = "Response Time",
                        value = "Within 24-48 hours"
                    )

                    Button(
                        onClick = { navController.navigate("contact") },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.AutoMirrored.Filled.Message, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Contact Support")
                    }
                }
            }

            // Consent
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Consent",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = "By using the ProTip365 app, you consent to our Privacy Policy and agree to its terms.",
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
private fun PrivacySection(
    title: String,
    content: String
) {
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
                modifier = Modifier.padding(bottom = 8.dp)
            )
            Text(
                text = content,
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

@Composable
private fun PrivacySubsection(
    title: String,
    items: List<String>
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
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            items.forEach { item ->
                Row(
                    modifier = Modifier.padding(vertical = 2.dp)
                ) {
                    Text(
                        text = "• ",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Text(
                        text = item,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
    }
}

@Composable
private fun ContactInfoRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary
        )
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
        }
    }
}


