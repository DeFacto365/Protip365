package com.protip365.app.presentation.calendar

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.pullrefresh.PullRefreshIndicator
import androidx.compose.material.pullrefresh.pullRefresh
import androidx.compose.material.pullrefresh.rememberPullRefreshState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.text.NumberFormat
import java.util.Locale
import com.protip365.app.data.models.CompletedShift

@Composable
fun CalendarLegend(
    currentLanguage: String = "en"
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            CalendarLegendItem(
                color = Color(0xFF4CAF50),
                label = when (currentLanguage) {
                    "fr" -> "500$+"
                    "es" -> "500$+"
                    else -> "$500+"
                }
            )
            CalendarLegendItem(
                color = Color(0xFF2196F3),
                label = when (currentLanguage) {
                    "fr" -> "300-499$"
                    "es" -> "300-499$"
                    else -> "$300-499"
                }
            )
            CalendarLegendItem(
                color = Color(0xFFFFC107),
                label = when (currentLanguage) {
                    "fr" -> "100-299$"
                    "es" -> "100-299$"
                    else -> "$100-299"
                }
            )
            CalendarLegendItem(
                color = Color(0xFF9E9E9E),
                label = when (currentLanguage) {
                    "fr" -> "<100$"
                    "es" -> "<100$"
                    else -> "<$100"
                }
            )
        }
    }
}

@Composable
private fun CalendarLegendItem(
    color: Color,
    label: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(color)
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun PartTimeLimitsIndicator(
    shiftsUsed: Int,
    entriesUsed: Int,
    currentLanguage: String = "en"
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.warningContainer
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            LimitIndicator(
                icon = Icons.Default.Schedule,
                used = shiftsUsed,
                limit = 3,
                label = when (currentLanguage) {
                    "fr" -> "Quarts"
                    "es" -> "Turnos"
                    else -> "Shifts"
                }
            )
            LimitIndicator(
                icon = Icons.Default.EditNote,
                used = entriesUsed,
                limit = 3,
                label = when (currentLanguage) {
                    "fr" -> "Entrées"
                    "es" -> "Entradas"
                    else -> "Entries"
                }
            )
        }
    }
}

@Composable
private fun LimitIndicator(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    used: Int,
    limit: Int,
    label: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = if (used >= limit) MaterialTheme.colorScheme.error
            else MaterialTheme.colorScheme.onWarningContainer
        )
        Column {
            Text(
                text = "$used/$limit",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = if (used >= limit) MaterialTheme.colorScheme.error
                else MaterialTheme.colorScheme.onWarningContainer
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onWarningContainer.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
fun CalendarActionButtons(
    selectedDate: java.time.LocalDate,
    onAddShift: () -> Unit,
    onQuickEntry: () -> Unit,
    canAddMore: Boolean = true,
    currentLanguage: String = "en"
) {
    val today = java.time.LocalDate.now()
    val isPastDateOrToday = selectedDate <= today
    @Suppress("UNUSED_VARIABLE")
    val isFutureDate = selectedDate > today

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        if (isPastDateOrToday) {
            // For past/today: Show "Add Entry" button (for actual data)
            Button(
                onClick = onQuickEntry,
                modifier = Modifier.weight(1f),
                enabled = canAddMore,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(
                    Icons.Default.Speed,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Ajouter Entrée"
                        "es" -> "Agregar Entrada"
                        else -> "Add Entry"
                    }
                )
            }
        } else {
            // For future dates: Show "Add Shift" button (for expected/planned shifts)
            Button(
                onClick = onAddShift,
                modifier = Modifier.weight(1f),
                enabled = canAddMore,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF9C27B0) // Purple color matching iOS
                )
            ) {
                Icon(
                    Icons.Default.Add,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Ajouter Quart"
                        "es" -> "Agregar Turno"
                        else -> "Add Shift"
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SwipeableShiftCard(
    shift: CompletedShift,
    employerName: String?,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    currentLanguage: String = "en"
) {
    var showDeleteDialog by remember { mutableStateOf(false) }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = {
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Supprimer le quart?"
                        "es" -> "¿Eliminar turno?"
                        else -> "Delete shift?"
                    }
                )
            },
            text = {
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Cette action ne peut pas être annulée."
                        "es" -> "Esta acción no se puede deshacer."
                        else -> "This action cannot be undone."
                    }
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete()
                        showDeleteDialog = false
                    }
                ) {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Supprimer"
                            "es" -> "Eliminar"
                            else -> "Delete"
                        },
                        color = MaterialTheme.colorScheme.error
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Annuler"
                            "es" -> "Cancelar"
                            else -> "Cancel"
                        }
                    )
                }
            }
        )
    }

    Card(
        onClick = onEdit,
        modifier = Modifier
            .fillMaxWidth()
            .animateContentSize(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                employerName?.let {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = it,
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                }

                Text(
                    text = formatCurrency(shift.totalEarnings),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            IconButton(onClick = { showDeleteDialog = true }) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Delete",
                    tint = MaterialTheme.colorScheme.error.copy(alpha = 0.6f)
                )
            }
        }
    }
}

private fun formatCurrency(amount: Double): String {
    return NumberFormat.getCurrencyInstance(Locale.US).format(amount)
}

// Extension property for warning container color
val ColorScheme.warningContainer: Color
    @Composable
    get() = Color(0xFFFFF3E0)

val ColorScheme.onWarningContainer: Color
    @Composable
    get() = Color(0xFF5D4037)