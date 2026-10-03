package com.protip365.app.presentation.settings

import androidx.compose.foundation.Image
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
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.protip365.app.R

@Composable
fun AppInfoSection(
    currentLanguage: String = "en"
) {
    var showAboutDialog by remember { mutableStateOf(false) }
    var showWhatsNewDialog by remember { mutableStateOf(false) }
@Suppress("UNUSED_VARIABLE")
    val context = LocalContext.current
    val packageInfo = remember {
        try {
            context.packageManager.getPackageInfo(context.packageName, 0)
        } catch (e: Exception) {
            null
        }
    }

    val versionName = packageInfo?.versionName ?: "1.0.0"
    val versionCode = packageInfo?.versionCode ?: 1

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Header with app icon
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.padding(bottom = 8.dp)
            ) {
                // App Icon
                Card(
                    modifier = Modifier.size(56.dp),
                    shape = RoundedCornerShape(12.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                MaterialTheme.colorScheme.primaryContainer
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.MonetizationOn,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }

                // App Info
                Column {
                    Text(
                        text = "ProTip365",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Version $versionName (Build $versionCode)"
                            "es" -> "Versión $versionName (Build $versionCode)"
                            else -> "Version $versionName (Build $versionCode)"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Suivez vos pourboires facilement"
                            "es" -> "Rastree sus propinas fácilmente"
                            else -> "Track your tips effortlessly"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))

            // What's New
            InfoActionItem(
                icon = Icons.Default.NewReleases,
                title = when (currentLanguage) {
                    "fr" -> "Quoi de neuf"
                    "es" -> "Novedades"
                    else -> "What's New"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Voir les dernières fonctionnalités et améliorations"
                    "es" -> "Ver las últimas características y mejoras"
                    else -> "See latest features and improvements"
                },
                onClick = { showWhatsNewDialog = true },
                showBadge = true
            )

            // About
            InfoActionItem(
                icon = Icons.Default.Info,
                title = when (currentLanguage) {
                    "fr" -> "À propos"
                    "es" -> "Acerca de"
                    else -> "About"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "En savoir plus sur ProTip365"
                    "es" -> "Más información sobre ProTip365"
                    else -> "Learn more about ProTip365"
                },
                onClick = { showAboutDialog = true }
            )

            // Rate App
            InfoActionItem(
                icon = Icons.Default.Star,
                title = when (currentLanguage) {
                    "fr" -> "Évaluer l'application"
                    "es" -> "Calificar aplicación"
                    else -> "Rate App"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Aimez-vous ProTip365? Laissez un avis!"
                    "es" -> "¿Te gusta ProTip365? ¡Deja una reseña!"
                    else -> "Love ProTip365? Leave a review!"
                },
                onClick = {
                    // Open Play Store for rating
                }
            )

            // Share App
            InfoActionItem(
                icon = Icons.Default.Share,
                title = when (currentLanguage) {
                    "fr" -> "Partager l'application"
                    "es" -> "Compartir aplicación"
                    else -> "Share App"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Recommander ProTip365 à vos amis"
                    "es" -> "Recomendar ProTip365 a sus amigos"
                    else -> "Recommend ProTip365 to friends"
                },
                onClick = {
                    // Share app link
                }
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))

            // Developer Section
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Développeur"
                    "es" -> "Desarrollador"
                    else -> "Developer"
                },
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )

            // Developer Info
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                )
            ) {
                Column(
                    modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "ProTip365 Inc.",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "contact@protip365.com",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.clickable {
                            // Copy email to clipboard
                        }
                    )
                    Text(
                        text = "© 2025 ProTip365 Inc. All rights reserved.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }

    // What's New Dialog
    if (showWhatsNewDialog) {
        WhatsNewDialog(
            onDismiss = { showWhatsNewDialog = false },
            currentLanguage = currentLanguage
        )
    }

    // About Dialog
    if (showAboutDialog) {
        AboutDialog(
            onDismiss = { showAboutDialog = false },
            currentLanguage = currentLanguage,
            versionName = versionName
        )
    }
}

@Composable
private fun InfoActionItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    showBadge: Boolean = false
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        colors = CardDefaults.cardColors(
            containerColor = Color.Transparent
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp, horizontal = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
                if (showBadge) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .background(
                                MaterialTheme.colorScheme.error,
                                CircleShape
                            )
                            .align(Alignment.TopEnd)
                    )
                }
            }

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium
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
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun WhatsNewDialog(
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
                // Header
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Default.NewReleases,
                        contentDescription = null,
                        modifier = Modifier.size(32.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Quoi de neuf"
                            "es" -> "Novedades"
                            else -> "What's New"
                        },
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }

                // Version 1.1.0
                ReleaseNotes(
                    version = "1.1.0",
                    date = when (currentLanguage) {
                        "fr" -> "Décembre 2024"
                        "es" -> "Diciembre 2024"
                        else -> "December 2024"
                    },
                    features = listOf(
                        when (currentLanguage) {
                            "fr" -> "✨ Nouveau design Material You"
                            "es" -> "✨ Nuevo diseño Material You"
                            else -> "✨ New Material You design"
                        },
                        when (currentLanguage) {
                            "fr" -> "🔒 Authentification biométrique améliorée"
                            "es" -> "🔒 Autenticación biométrica mejorada"
                            else -> "🔒 Enhanced biometric authentication"
                        },
                        when (currentLanguage) {
                            "fr" -> "📊 Nouveaux graphiques de performance"
                            "es" -> "📊 Nuevos gráficos de rendimiento"
                            else -> "📊 New performance charts"
                        },
                        when (currentLanguage) {
                            "fr" -> "🌍 Support complet pour FR/ES/EN"
                            "es" -> "🌍 Soporte completo para FR/ES/EN"
                            else -> "🌍 Full support for FR/ES/EN"
                        },
                        when (currentLanguage) {
                            "fr" -> "🐛 Corrections de bugs et améliorations"
                            "es" -> "🐛 Corrección de errores y mejoras"
                            else -> "🐛 Bug fixes and improvements"
                        }
                    )
                )

                // Close Button
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(when (currentLanguage) {
                        "fr" -> "Compris!"
                        "es" -> "¡Entendido!"
                        else -> "Got it!"
                    })
                }
            }
        }
    }
}

@Composable
private fun ReleaseNotes(
    version: String,
    date: String,
    features: List<String>
) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "v$version",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = date,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            features.forEach { feature ->
                Text(
                    text = feature,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(vertical = 2.dp)
                )
            }
        }
    }
}

@Composable
private fun AboutDialog(
    onDismiss: () -> Unit,
    currentLanguage: String,
    versionName: String
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
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // App Icon
                Card(
                    modifier = Modifier.size(80.dp),
                    shape = RoundedCornerShape(16.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                MaterialTheme.colorScheme.primaryContainer
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.MonetizationOn,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(48.dp)
                        )
                    }
                }

                // App Name and Version
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "ProTip365",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Version $versionName"
                            "es" -> "Versión $versionName"
                            else -> "Version $versionName"
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Description
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "ProTip365 est l'application ultime pour suivre vos pourboires, gérer vos quarts de travail et atteindre vos objectifs financiers dans l'industrie des services."
                        "es" -> "ProTip365 es la aplicación definitiva para rastrear sus propinas, gestionar sus turnos y alcanzar sus objetivos financieros en la industria de servicios."
                        else -> "ProTip365 is the ultimate app for tracking tips, managing shifts, and achieving your financial goals in the service industry."
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // Mission Statement
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.Favorite,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier
                                .size(24.dp)
                                .padding(bottom = 8.dp)
                        )
                        Text(
                            text = when (currentLanguage) {
                                "fr" -> "Notre mission"
                                "es" -> "Nuestra misión"
                                else -> "Our Mission"
                            },
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(bottom = 4.dp)
                        )
                        Text(
                            text = when (currentLanguage) {
                                "fr" -> "Aider les travailleurs du service à maximiser leurs revenus et à gérer leurs finances efficacement."
                                "es" -> "Ayudar a los trabajadores de servicio a maximizar sus ingresos y gestionar sus finanzas de manera efectiva."
                                else -> "Help service workers maximize their earnings and manage their finances effectively."
                            },
                            style = MaterialTheme.typography.bodySmall,
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Copyright
                Text(
                    text = "© 2025 ProTip365 Inc.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // Close Button
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