package com.protip365.app.presentation.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.data.models.Alert
import com.protip365.app.data.models.AlertType
import com.protip365.app.presentation.alerts.AlertManager
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlin.time.Duration.Companion.milliseconds

@Composable
fun NotificationBell(
    alertManager: AlertManager,
    modifier: Modifier = Modifier,
    navController: NavController? = null
) {
    val alerts by alertManager.alerts.collectAsState()
    val hasUnreadAlerts by alertManager.hasUnreadAlerts.collectAsState()
    val unreadCount by alertManager.unreadCount.collectAsState()

    var showAlertsList by remember { mutableStateOf(false) }
    var animateBell by remember { mutableStateOf(false) }

    val haptics = LocalHapticFeedback.current
    val scope = rememberCoroutineScope()

    // Animate bell when new alerts arrive
    LaunchedEffect(hasUnreadAlerts) {
        if (hasUnreadAlerts) {
            animateBell = true
            delay(200)
            animateBell = false
        }
    }

    val bellScale by animateFloatAsState(
        targetValue = if (animateBell) 1.1f else 1.0f,
        label = "bell_scale"
    )

    val bellColor by animateColorAsState(
        targetValue = if (hasUnreadAlerts) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
        label = "bell_color"
    )

    Box(
        modifier = modifier
            .size(48.dp)
            .clip(CircleShape)
            .clickable {
                haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                showAlertsList = true
            },
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = if (hasUnreadAlerts) Icons.Filled.Notifications else Icons.Outlined.Notifications,
            contentDescription = "Notifications",
            modifier = Modifier
                .size(24.dp)
                .scale(bellScale),
            tint = bellColor
        )

        // Badge with count
        if (hasUnreadAlerts && unreadCount > 0) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(x = 4.dp, y = (-4).dp)
                    .size(if (unreadCount > 9) 20.dp else 16.dp)
                    .background(
                        color = MaterialTheme.colorScheme.error,
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = if (unreadCount > 99) "99+" else unreadCount.toString(),
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }

    // Alerts list modal
    if (showAlertsList) {
        AlertsListModal(
            alerts = alerts,
            alertManager = alertManager,
            navController = navController,
            onDismiss = { showAlertsList = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertsListModal(
    alerts: List<Alert>,
    alertManager: AlertManager,
    navController: NavController?,
    onDismiss: () -> Unit
) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val preferencesManager = remember { PreferencesManager(context) }

    val language = preferencesManager.getLanguage()

    val title = when (language) {
        "fr" -> "Notifications"
        "es" -> "Notificaciones"
        else -> "Notifications"
    }

    val noAlertsMessage = when (language) {
        "fr" -> "Aucune notification"
        "es" -> "Sin notificaciones"
        else -> "No notifications"
    }

    val clearAllText = when (language) {
        "fr" -> "Tout effacer"
        "es" -> "Borrar todo"
        else -> "Clear All"
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp)
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )

                if (alerts.isNotEmpty()) {
                    TextButton(
                        onClick = {
                            scope.launch {
                                alertManager.clearAllAlerts()
                            }
                        }
                    ) {
                        Text(
                            text = clearAllText,
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }

            Divider()

            // Content
            if (alerts.isEmpty()) {
                EmptyAlertsContent(noAlertsMessage)
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f, fill = false),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    contentPadding = PaddingValues(16.dp)
                ) {
                    items(
                        items = alerts,
                        key = { it.id }
                    ) { alert ->
                        AlertRowItem(
                            alert = alert,
                            onTap = {
                                handleAlertTap(alert, alertManager, navController, onDismiss)
                            },
                            onDelete = {
                                scope.launch {
                                    alertManager.clearAlert(alert)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertRowItem(
    alert: Alert,
    onTap: () -> Unit,
    onDelete: () -> Unit
) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { dismissValue ->
            if (dismissValue == SwipeToDismissBoxValue.EndToStart) {
                onDelete()
                true
            } else {
                false
            }
        }
    )

    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        color = MaterialTheme.colorScheme.error,
                        shape = RoundedCornerShape(12.dp)
                    ),
                contentAlignment = Alignment.CenterEnd
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "Delete",
                    modifier = Modifier.padding(end = 16.dp),
                    tint = Color.White
                )
            }
        },
        content = {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onTap() },
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (alert.isRead) {
                        MaterialTheme.colorScheme.surface
                    } else {
                        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.1f)
                    }
                )
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
                        Text(
                            text = alert.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = if (!alert.isRead) FontWeight.Bold else FontWeight.Normal,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )

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

                    // Action button
                    if (!alert.action.isNullOrEmpty() && isNavigationAction(alert.alertType)) {
                        IconButton(
                            onClick = onTap,
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.ArrowForward,
                                contentDescription = alert.action,
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        }
    )
}

@Composable
fun EmptyAlertsContent(message: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Outlined.Notifications,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = message,
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

fun getAlertIcon(alertType: String): androidx.compose.ui.graphics.vector.ImageVector {
    return when (AlertType.fromValue(alertType)) {
        AlertType.SHIFT_REMINDER -> Icons.Default.Schedule
        AlertType.MISSING_SHIFT -> Icons.Default.Warning
        AlertType.INCOMPLETE_SHIFT -> Icons.Default.ErrorOutline
        AlertType.TARGET_ACHIEVED -> Icons.Default.Star
        AlertType.PERSONAL_BEST -> Icons.Default.TrendingUp
        AlertType.REMINDER -> Icons.Default.Notifications
        AlertType.SUBSCRIPTION_LIMIT -> Icons.Default.Info
        AlertType.WEEKLY_SUMMARY -> Icons.Default.BarChart
        AlertType.ACHIEVEMENT_UNLOCKED -> Icons.Default.EmojiEvents
        else -> Icons.Default.Notifications
    }
}

fun getAlertColor(alertType: String): Color {
    return when (AlertType.fromValue(alertType)) {
        AlertType.SHIFT_REMINDER -> Color(0xFF2196F3)
        AlertType.MISSING_SHIFT -> Color(0xFFFFA726)
        AlertType.INCOMPLETE_SHIFT -> Color(0xFFEF5350)
        AlertType.TARGET_ACHIEVED -> Color(0xFF66BB6A)
        AlertType.PERSONAL_BEST -> Color(0xFF9C27B0)
        AlertType.REMINDER -> Color(0xFF42A5F5)
        AlertType.SUBSCRIPTION_LIMIT -> Color(0xFFEF5350)
        AlertType.WEEKLY_SUMMARY -> Color(0xFF9C27B0)
        AlertType.ACHIEVEMENT_UNLOCKED -> Color(0xFFFFD54F)
        else -> Color.Gray
    }
}

fun isNavigationAction(alertType: String): Boolean {
    return listOf("shiftReminder", "incompleteShift", "missingShift").contains(alertType)
}

fun formatRelativeTime(dateTimeString: String): String {
    return try {
        val instant = Instant.parse(dateTimeString)
        val now = Clock.System.now()
        val duration = now - instant

        when {
            duration.inWholeMinutes < 1 -> "Now"
            duration.inWholeMinutes < 60 -> "${duration.inWholeMinutes}m"
            duration.inWholeHours < 24 -> "${duration.inWholeHours}h"
            duration.inWholeDays < 7 -> "${duration.inWholeDays}d"
            else -> "${duration.inWholeDays / 7}w"
        }
    } catch (e: Exception) {
        "Unknown"
    }
}

private fun handleAlertTap(
    alert: Alert,
    alertManager: AlertManager,
    navController: NavController?,
    onDismiss: () -> Unit
) {
    // Dismiss the modal first
    onDismiss()

    // Clear the alert since user has acted on it
    if (!listOf("targetAchieved", "personalBest").contains(alert.alertType)) {
        kotlinx.coroutines.GlobalScope.launch {
            alertManager.clearAlert(alert)
        }
    }

    // Navigate based on alert type
    navController?.let { nav ->
        when (alert.alertType) {
            "missingShift", "incompleteShift" -> {
                nav.navigate("calendar")
            }
            "shiftReminder" -> {
                alert.getShiftId()?.let { shiftId ->
                    nav.navigate("shift/$shiftId")
                } ?: nav.navigate("calendar")
            }
            "targetAchieved", "personalBest" -> {
                kotlinx.coroutines.GlobalScope.launch {
                    alertManager.clearAlert(alert)
                }
            }
            else -> {
                // Handle unknown alert types
                nav.navigate("dashboard")
            }
        }
    }
}