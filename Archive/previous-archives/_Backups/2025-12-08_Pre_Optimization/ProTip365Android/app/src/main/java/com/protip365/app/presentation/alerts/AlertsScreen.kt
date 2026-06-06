package com.protip365.app.presentation.alerts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.ui.platform.LocalContext
import com.protip365.app.R
import com.protip365.app.presentation.localization.LocalizationManager
import com.protip365.app.data.models.Alert
import com.protip365.app.data.models.AlertType
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertsScreen(
    onNavigateBack: () -> Unit,
    viewModel: AlertsViewModel = hiltViewModel()
) {
    val alerts by viewModel.alerts.collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.notifications_title)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                    }
                },
                actions = {
                    if (alerts.any { !it.isRead }) {
                        TextButton(
                            onClick = { viewModel.markAllAsRead() }
                        ) {
                            Text(stringResource(R.string.mark_all_read))
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (alerts.isEmpty()) {
            EmptyAlertsState(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(16.dp)
            ) {
                items(
                    items = alerts,
                    key = { it.id }
                ) { alert ->
                    AlertCard(
                        alert = alert,
                        onMarkAsRead = { viewModel.markAsRead(alert.id) },
                        onDelete = { viewModel.deleteAlert(alert.id) }
                    )
                }
            }
        }
    }

    uiState.error?.let { error ->
        LaunchedEffect(error) {
            // Show error snackbar
            viewModel.clearError()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertCard(
    alert: Alert,
    onMarkAsRead: () -> Unit,
    @Suppress("UNUSED_PARAMETER")
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (alert.isRead) {
                MaterialTheme.colorScheme.surface
            } else {
                MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.1f)
            }
        ),
        onClick = {
            if (!alert.isRead) {
                onMarkAsRead()
            }
        }
    ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Alert icon
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(
                                getAlertColor(alert.alertType).copy(alpha = 0.2f)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = getAlertIcon(alert.alertType),
                            contentDescription = null,
                            tint = getAlertColor(alert.alertType),
                            modifier = Modifier.size(24.dp)
                        )
                    }

                    // Alert content
                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = alert.title,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = if (!alert.isRead) FontWeight.Bold else FontWeight.Normal,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f)
                            )

                            if (!alert.isRead) {
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .clip(CircleShape)
                                        .background(MaterialTheme.colorScheme.primary)
                                )
                            }
                        }

                        Text(
                            text = alert.message,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )

                        alert.createdAt?.let { createdAt ->
                            Text(
                                text = formatRelativeTime(createdAt),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                            )
                        }
                    }
                }
            }
}

@Composable
fun EmptyAlertsState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            Icons.Default.Notifications,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = stringResource(R.string.no_notifications),
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.youre_all_caught_up),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
        )
    }
}

fun getAlertIcon(alertType: String): androidx.compose.ui.graphics.vector.ImageVector {
    return when (AlertType.fromValue(alertType)) {
        AlertType.SHIFT_REMINDER -> Icons.Outlined.Schedule
        AlertType.MISSING_SHIFT -> Icons.Default.Warning
        AlertType.INCOMPLETE_SHIFT -> Icons.Outlined.ErrorOutline
        AlertType.TARGET_ACHIEVED -> Icons.Default.Star
        AlertType.PERSONAL_BEST -> Icons.AutoMirrored.Filled.TrendingUp
        AlertType.REMINDER -> Icons.Default.Notifications
        AlertType.SUBSCRIPTION_LIMIT -> Icons.Default.Info
        AlertType.WEEKLY_SUMMARY -> Icons.Default.BarChart
        AlertType.ACHIEVEMENT_UNLOCKED -> Icons.Default.EmojiEvents
        else -> Icons.Default.Notifications
    }
}

fun getAlertColor(alertType: String): androidx.compose.ui.graphics.Color {
    return when (AlertType.fromValue(alertType)) {
        AlertType.SHIFT_REMINDER -> androidx.compose.ui.graphics.Color(0xFF2196F3)
        AlertType.MISSING_SHIFT -> androidx.compose.ui.graphics.Color(0xFFFFA726)
        AlertType.INCOMPLETE_SHIFT -> androidx.compose.ui.graphics.Color(0xFFEF5350)
        AlertType.TARGET_ACHIEVED -> androidx.compose.ui.graphics.Color(0xFF66BB6A)
        AlertType.PERSONAL_BEST -> androidx.compose.ui.graphics.Color(0xFF9C27B0)
        AlertType.REMINDER -> androidx.compose.ui.graphics.Color(0xFF42A5F5)
        AlertType.SUBSCRIPTION_LIMIT -> androidx.compose.ui.graphics.Color(0xFFEF5350)
        AlertType.WEEKLY_SUMMARY -> androidx.compose.ui.graphics.Color(0xFF9C27B0)
        AlertType.ACHIEVEMENT_UNLOCKED -> androidx.compose.ui.graphics.Color(0xFFFFD54F)
        else -> androidx.compose.ui.graphics.Color.Gray
    }
}

@Composable
fun formatRelativeTime(dateTimeString: String): String {
        @Suppress("UNUSED_VARIABLE")
        val context = LocalContext.current

    // Parse the datetime safely first
    val timeInfo = remember(dateTimeString) {
        try {
            val instant = Instant.parse(dateTimeString)
            val now = kotlinx.datetime.Clock.System.now()
            val duration = now - instant
            TimeInfo(instant, duration, true)
        } catch (e: Exception) {
            TimeInfo(null, null, false)
        }
    }

    return if (!timeInfo.isValid) {
        "Unknown"
    } else {
        val duration = timeInfo.duration!!
        when {
            duration.inWholeMinutes < 1 -> stringResource(R.string.just_now)
            duration.inWholeMinutes < 60 -> stringResource(R.string.minutes_ago, duration.inWholeMinutes.toInt())
            duration.inWholeHours < 24 -> stringResource(R.string.hours_ago, duration.inWholeHours.toInt())
            duration.inWholeDays < 7 -> stringResource(R.string.days_ago, duration.inWholeDays.toInt())
            else -> {
                @Suppress("UNUSED_VARIABLE")
                val date = timeInfo.instant!!.toLocalDateTime(TimeZone.currentSystemDefault())
                SimpleDateFormat("MMM dd", Locale.getDefault()).format(
                    Date(timeInfo.instant.toEpochMilliseconds())
                )
            }
        }
    }
}

private data class TimeInfo(
    val instant: Instant?,
    val duration: kotlin.time.Duration?,
    val isValid: Boolean
)