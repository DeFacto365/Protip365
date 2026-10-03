package com.protip365.app.presentation.settings

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

enum class SubscriptionTier {
    FREE_TRIAL,
    PART_TIME,
    FULL_ACCESS
}

data class SubscriptionStatus(
    val tier: SubscriptionTier,
    val isActive: Boolean,
    val expiryDate: LocalDate?,
    val shiftsThisWeek: Int = 0,
    val entriesThisWeek: Int = 0,
    val isTrialPeriod: Boolean = false,
    val daysRemainingInTrial: Int = 0
)

@Composable
fun SubscriptionSettingsSection(
    subscriptionStatus: SubscriptionStatus,
    onUpgrade: () -> Unit,
    onManageSubscription: () -> Unit,
    onRestorePurchases: () -> Unit,
    currentLanguage: String = "en"
) {
    var showUpgradeDialog by remember { mutableStateOf(false) }
    var showDetailsDialog by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header with crown icon
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(
                            when (subscriptionStatus.tier) {
                                SubscriptionTier.FULL_ACCESS -> Color(0xFFFFD700) // Gold
                                SubscriptionTier.PART_TIME -> Color(0xFFC0C0C0) // Silver
                                else -> MaterialTheme.colorScheme.surfaceVariant
                            }
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.WorkspacePremium,
                        contentDescription = null,
                        tint = when (subscriptionStatus.tier) {
                            SubscriptionTier.FULL_ACCESS -> Color.White
                            SubscriptionTier.PART_TIME -> Color.White
                            else -> MaterialTheme.colorScheme.onSurfaceVariant
                        },
                        modifier = Modifier.size(24.dp)
                    )
                }

                Column {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Abonnement"
                            "es" -> "Suscripción"
                            else -> "Subscription"
                        },
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = getCurrentPlanName(subscriptionStatus.tier, currentLanguage),
                        style = MaterialTheme.typography.bodySmall,
                        color = when (subscriptionStatus.tier) {
                            SubscriptionTier.FULL_ACCESS -> Color(0xFFFFD700)
                            SubscriptionTier.PART_TIME -> Color(0xFFC0C0C0)
                            else -> MaterialTheme.colorScheme.onSurfaceVariant
                        },
                        fontWeight = FontWeight.Medium
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                // Status Badge
                if (subscriptionStatus.isTrialPeriod) {
                    Badge(
                        containerColor = MaterialTheme.colorScheme.tertiary
                    ) {
                        Text(
                            text = when (currentLanguage) {
                                "fr" -> "ESSAI"
                                "es" -> "PRUEBA"
                                else -> "TRIAL"
                            },
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                }
            }

            // Trial remaining days (if applicable)
            if (subscriptionStatus.isTrialPeriod && subscriptionStatus.daysRemainingInTrial > 0) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.3f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Timer,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.tertiary,
                            modifier = Modifier.size(20.dp)
                        )
                        Text(
                            text = when (currentLanguage) {
                                "fr" -> "${subscriptionStatus.daysRemainingInTrial} jours restants dans votre essai gratuit"
                                "es" -> "${subscriptionStatus.daysRemainingInTrial} días restantes en su prueba gratuita"
                                else -> "${subscriptionStatus.daysRemainingInTrial} days remaining in your free trial"
                            },
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Usage limits for Part-Time tier
            if (subscriptionStatus.tier == SubscriptionTier.PART_TIME) {
                UsageLimitsCard(
                    shiftsThisWeek = subscriptionStatus.shiftsThisWeek,
                    entriesThisWeek = subscriptionStatus.entriesThisWeek,
                    currentLanguage = currentLanguage
                )
            }

            HorizontalDivider()

            // Plan Details Button
            SubscriptionActionItem(
                icon = Icons.Default.Info,
                title = when (currentLanguage) {
                    "fr" -> "Détails du plan"
                    "es" -> "Detalles del plan"
                    else -> "Plan Details"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Voir ce qui est inclus dans votre plan"
                    "es" -> "Ver qué está incluido en su plan"
                    else -> "See what's included in your plan"
                },
                onClick = { showDetailsDialog = true }
            )

            // Upgrade/Manage Subscription
            if (subscriptionStatus.tier != SubscriptionTier.FULL_ACCESS) {
                SubscriptionActionItem(
                    icon = Icons.Default.Upgrade,
                    title = when (currentLanguage) {
                        "fr" -> "Passer à l'accès complet"
                        "es" -> "Actualizar a acceso completo"
                        else -> "Upgrade to Full Access"
                    },
                    subtitle = when (currentLanguage) {
                        "fr" -> "Débloquez toutes les fonctionnalités"
                        "es" -> "Desbloquear todas las funciones"
                        else -> "Unlock all features"
                    },
                    onClick = { showUpgradeDialog = true },
                    isPrimary = true
                )
            } else {
                SubscriptionActionItem(
                    icon = Icons.Default.Settings,
                    title = when (currentLanguage) {
                        "fr" -> "Gérer l'abonnement"
                        "es" -> "Administrar suscripción"
                        else -> "Manage Subscription"
                    },
                    subtitle = when (currentLanguage) {
                        "fr" -> "Modifier ou annuler votre abonnement"
                        "es" -> "Modificar o cancelar su suscripción"
                        else -> "Modify or cancel your subscription"
                    },
                    onClick = onManageSubscription
                )
            }

            // Restore Purchases
            SubscriptionActionItem(
                icon = Icons.Default.Restore,
                title = when (currentLanguage) {
                    "fr" -> "Restaurer les achats"
                    "es" -> "Restaurar compras"
                    else -> "Restore Purchases"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Récupérer vos achats précédents"
                    "es" -> "Recuperar sus compras anteriores"
                    else -> "Recover your previous purchases"
                },
                onClick = onRestorePurchases
            )

            // Expiry date (if applicable)
            subscriptionStatus.expiryDate?.let { expiry ->
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Renouvellement: ${expiry.format(DateTimeFormatter.ofPattern("d MMMM yyyy"))}"
                        "es" -> "Renovación: ${expiry.format(DateTimeFormatter.ofPattern("d 'de' MMMM 'de' yyyy"))}"
                        else -> "Renewal: ${expiry.format(DateTimeFormatter.ofPattern("MMMM d, yyyy"))}"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }
    }

    // Upgrade Dialog
    if (showUpgradeDialog) {
        UpgradeDialog(
            currentTier = subscriptionStatus.tier,
            onSelectPlan = { plan ->
                onUpgrade()
                showUpgradeDialog = false
            },
            onDismiss = { showUpgradeDialog = false },
            currentLanguage = currentLanguage
        )
    }

    // Plan Details Dialog
    if (showDetailsDialog) {
        PlanDetailsDialog(
            currentTier = subscriptionStatus.tier,
            onDismiss = { showDetailsDialog = false },
            currentLanguage = currentLanguage
        )
    }
}

@Composable
private fun UsageLimitsCard(
    shiftsThisWeek: Int,
    entriesThisWeek: Int,
    currentLanguage: String
) {
    val maxShifts = 3
    val maxEntries = 3

    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.3f)
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Limites hebdomadaires"
                    "es" -> "Límites semanales"
                    else -> "Weekly Limits"
                },
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Medium
            )

            // Shifts Progress
            UsageProgressItem(
                label = when (currentLanguage) {
                    "fr" -> "Quarts"
                    "es" -> "Turnos"
                    else -> "Shifts"
                },
                current = shiftsThisWeek,
                max = maxShifts,
                icon = Icons.Default.Schedule
            )

            // Entries Progress
            UsageProgressItem(
                label = when (currentLanguage) {
                    "fr" -> "Entrées"
                    "es" -> "Entradas"
                    else -> "Entries"
                },
                current = entriesThisWeek,
                max = maxEntries,
                icon = Icons.Default.Receipt
            )
        }
    }
}

@Composable
private fun UsageProgressItem(
    label: String,
    current: Int,
    max: Int,
    icon: androidx.compose.ui.graphics.vector.ImageVector
) {
    val progress = (current.toFloat() / max.toFloat()).coerceIn(0f, 1f)
    val animatedProgress by animateFloatAsState(targetValue = progress)
    val progressColor by animateColorAsState(
        targetValue = when {
            progress >= 1f -> MaterialTheme.colorScheme.error
            progress >= 0.67f -> MaterialTheme.colorScheme.tertiary
            else -> MaterialTheme.colorScheme.primary
        }
    )

    Column(
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = progressColor
                )
                Text(
                    text = label,
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Text(
                text = "$current / $max",
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium,
                color = progressColor
            )
        }
        LinearProgressIndicator(
            progress = animatedProgress,
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp)),
            color = progressColor,
            trackColor = MaterialTheme.colorScheme.surfaceVariant
        )
    }
}

@Composable
private fun SubscriptionActionItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    isPrimary: Boolean = false
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        colors = if (isPrimary) {
            CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
            )
        } else {
            CardDefaults.cardColors(
                containerColor = Color.Transparent
            )
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp, horizontal = if (isPrimary) 12.dp else 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = if (isPrimary)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(24.dp)
            )

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = if (isPrimary) FontWeight.SemiBold else FontWeight.Medium,
                    color = if (isPrimary)
                        MaterialTheme.colorScheme.primary
                    else
                        MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = if (isPrimary)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun UpgradeDialog(
    currentTier: SubscriptionTier,
    onSelectPlan: (String) -> Unit,
    onDismiss: () -> Unit,
    currentLanguage: String
) {
    var selectedPlan by remember { mutableStateOf("monthly") }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Header
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        Icons.Default.WorkspacePremium,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = Color(0xFFFFD700)
                    )
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Passer à l'accès complet"
                            "es" -> "Actualizar a acceso completo"
                            else -> "Upgrade to Full Access"
                        },
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    )
                }

                // Plan Options
                Column(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Monthly Plan
                    PlanOptionCard(
                        isSelected = selectedPlan == "monthly",
                        title = when (currentLanguage) {
                            "fr" -> "Mensuel"
                            "es" -> "Mensual"
                            else -> "Monthly"
                        },
                        price = "$4.99",
                        period = when (currentLanguage) {
                            "fr" -> "/mois"
                            "es" -> "/mes"
                            else -> "/month"
                        },
                        onClick = { selectedPlan = "monthly" }
                    )

                    // Annual Plan
                    PlanOptionCard(
                        isSelected = selectedPlan == "annual",
                        title = when (currentLanguage) {
                            "fr" -> "Annuel"
                            "es" -> "Anual"
                            else -> "Annual"
                        },
                        price = "$49.99",
                        period = when (currentLanguage) {
                            "fr" -> "/an"
                            "es" -> "/año"
                            else -> "/year"
                        },
                        savings = when (currentLanguage) {
                            "fr" -> "Économisez 17%"
                            "es" -> "Ahorre 17%"
                            else -> "Save 17%"
                        },
                        onClick = { selectedPlan = "annual" }
                    )
                }

                // Features List
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FeatureItem("✅", when (currentLanguage) {
                            "fr" -> "Quarts et entrées illimités"
                            "es" -> "Turnos y entradas ilimitados"
                            else -> "Unlimited shifts and entries"
                        })
                        FeatureItem("✅", when (currentLanguage) {
                            "fr" -> "Employeurs multiples"
                            "es" -> "Múltiples empleadores"
                            else -> "Multiple employers"
                        })
                        FeatureItem("✅", when (currentLanguage) {
                            "fr" -> "Analyses avancées"
                            "es" -> "Análisis avanzado"
                            else -> "Advanced analytics"
                        })
                        FeatureItem("✅", when (currentLanguage) {
                            "fr" -> "Exportation de données"
                            "es" -> "Exportación de datos"
                            else -> "Data export"
                        })
                        FeatureItem("✅", when (currentLanguage) {
                            "fr" -> "Support prioritaire"
                            "es" -> "Soporte prioritario"
                            else -> "Priority support"
                        })
                    }
                }

                // Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    TextButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(when (currentLanguage) {
                            "fr" -> "Annuler"
                            "es" -> "Cancelar"
                            else -> "Cancel"
                        })
                    }

                    Button(
                        onClick = { onSelectPlan(selectedPlan) },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFFFD700)
                        )
                    ) {
                        Text(
                            text = when (currentLanguage) {
                                "fr" -> "S'abonner"
                                "es" -> "Suscribirse"
                                else -> "Subscribe"
                            },
                            color = Color.Black
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PlanOptionCard(
    isSelected: Boolean,
    title: String,
    price: String,
    period: String,
    savings: String? = null,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected)
                MaterialTheme.colorScheme.primaryContainer
            else
                MaterialTheme.colorScheme.surfaceVariant
        ),
        border = if (isSelected) {
            CardDefaults.outlinedCardBorder()
        } else null
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium
                )
                savings?.let {
                    Badge(
                        containerColor = MaterialTheme.colorScheme.tertiary
                    ) {
                        Text(
                            text = it,
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                }
            }

            Row(
                verticalAlignment = Alignment.Bottom
            ) {
                Text(
                    text = price,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = period,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(bottom = 2.dp)
                )
            }
        }
    }
}

@Composable
private fun FeatureItem(
    icon: String,
    text: String
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(icon)
        Text(
            text = text,
            style = MaterialTheme.typography.bodySmall
        )
    }
}

@Composable
private fun PlanDetailsDialog(
    currentTier: SubscriptionTier,
    onDismiss: () -> Unit,
    currentLanguage: String
) {
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Comparaison des plans"
                        "es" -> "Comparación de planes"
                        else -> "Plan Comparison"
                    },
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )

                // Part-Time Plan
                PlanComparisonCard(
                    title = when (currentLanguage) {
                        "fr" -> "Temps partiel"
                        "es" -> "Tiempo parcial"
                        else -> "Part-Time"
                    },
                    price = "$2.99",
                    features = listOf(
                        when (currentLanguage) {
                            "fr" -> "3 quarts par semaine"
                            "es" -> "3 turnos por semana"
                            else -> "3 shifts per week"
                        },
                        when (currentLanguage) {
                            "fr" -> "3 entrées par semaine"
                            "es" -> "3 entradas por semana"
                            else -> "3 entries per week"
                        },
                        when (currentLanguage) {
                            "fr" -> "Un employeur"
                            "es" -> "Un empleador"
                            else -> "Single employer"
                        },
                        when (currentLanguage) {
                            "fr" -> "Analyses de base"
                            "es" -> "Análisis básico"
                            else -> "Basic analytics"
                        }
                    ),
                    isCurrentPlan = currentTier == SubscriptionTier.PART_TIME
                )

                // Full Access Plan
                PlanComparisonCard(
                    title = when (currentLanguage) {
                        "fr" -> "Accès complet"
                        "es" -> "Acceso completo"
                        else -> "Full Access"
                    },
                    price = "$4.99",
                    features = listOf(
                        when (currentLanguage) {
                            "fr" -> "Quarts illimités"
                            "es" -> "Turnos ilimitados"
                            else -> "Unlimited shifts"
                        },
                        when (currentLanguage) {
                            "fr" -> "Entrées illimitées"
                            "es" -> "Entradas ilimitadas"
                            else -> "Unlimited entries"
                        },
                        when (currentLanguage) {
                            "fr" -> "Employeurs multiples"
                            "es" -> "Múltiples empleadores"
                            else -> "Multiple employers"
                        },
                        when (currentLanguage) {
                            "fr" -> "Analyses avancées"
                            "es" -> "Análisis avanzado"
                            else -> "Advanced analytics"
                        },
                        when (currentLanguage) {
                            "fr" -> "Exportation de données"
                            "es" -> "Exportación de datos"
                            else -> "Data export"
                        },
                        when (currentLanguage) {
                            "fr" -> "Support prioritaire"
                            "es" -> "Soporte prioritario"
                            else -> "Priority support"
                        }
                    ),
                    isCurrentPlan = currentTier == SubscriptionTier.FULL_ACCESS,
                    isRecommended = true
                )

                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(when (currentLanguage) {
                        "fr" -> "Fermer"
                        "es" -> "Cerrar"
                        else -> "Close"
                    })
                }
            }
        }
    }
}

@Composable
private fun PlanComparisonCard(
    title: String,
    price: String,
    features: List<String>,
    isCurrentPlan: Boolean = false,
    isRecommended: Boolean = false
) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = if (isCurrentPlan)
                MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            else
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "$price/month",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    if (isCurrentPlan) {
                        Badge {
                            Text("CURRENT", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                    if (isRecommended) {
                        Badge(
                            containerColor = Color(0xFFFFD700)
                        ) {
                            Text("BEST VALUE", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }

            features.forEach { feature ->
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = feature,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
    }
}

private fun getCurrentPlanName(tier: SubscriptionTier, language: String): String {
    return when (tier) {
        SubscriptionTier.FULL_ACCESS -> when (language) {
            "fr" -> "Accès complet"
            "es" -> "Acceso completo"
            else -> "Full Access"
        }
        SubscriptionTier.PART_TIME -> when (language) {
            "fr" -> "Temps partiel"
            "es" -> "Tiempo parcial"
            else -> "Part-Time"
        }
        SubscriptionTier.FREE_TRIAL -> when (language) {
            "fr" -> "Essai gratuit"
            "es" -> "Prueba gratuita"
            else -> "Free Trial"
        }
    }
}