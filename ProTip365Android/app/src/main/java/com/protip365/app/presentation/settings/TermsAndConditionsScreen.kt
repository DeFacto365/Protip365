package com.protip365.app.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.protip365.app.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermsAndConditionsScreen(
    navController: NavController
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.terms_title),
                        style = MaterialTheme.typography.headlineSmall
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
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
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Last Updated
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Text(
                    text = stringResource(R.string.terms_last_updated),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    modifier = Modifier.padding(12.dp)
                )
            }

            // Introduction
            Text(
                text = stringResource(R.string.terms_intro),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            // Terms Sections
            TermsSection(
                title = stringResource(R.string.terms_section1_title),
                content = stringResource(R.string.terms_section1_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section2_title),
                content = stringResource(R.string.terms_section2_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section3_title),
                content = stringResource(R.string.terms_section3_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section4_title),
                content = stringResource(R.string.terms_section4_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section5_title),
                content = stringResource(R.string.terms_section5_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section6_title),
                content = stringResource(R.string.terms_section6_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section7_title),
                content = stringResource(R.string.terms_section7_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section8_title),
                content = stringResource(R.string.terms_section8_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section9_title),
                content = stringResource(R.string.terms_section9_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section10_title),
                content = stringResource(R.string.terms_section10_content)
            )

            TermsSection(
                title = stringResource(R.string.terms_section11_title),
                content = stringResource(R.string.terms_section11_content)
            )

            // Accept/Decline Buttons (optional - for first time viewing)
            Spacer(modifier = Modifier.height(24.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = { navController.popBackStack() },
                    modifier = Modifier.weight(1f)
                ) {
                    Text(stringResource(R.string.terms_decline_button))
                }

                Button(
                    onClick = {
                        // User accepted terms, navigate back
                        navController.popBackStack()
                    },
                    modifier = Modifier.weight(1f)
                ) {
                    Text(stringResource(R.string.terms_accept_button))
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun TermsSection(
    title: String,
    content: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )

            Text(
                text = content,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}