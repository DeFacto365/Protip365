package com.protip365.app.presentation.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import kotlinx.coroutines.launch

@Composable
fun SupportSettingsSection(
    onSendSupport: (String, String) -> Unit,
    currentLanguage: String = "en"
) {
    var showSupportDialog by remember { mutableStateOf(false) }
    val uriHandler = LocalUriHandler.current

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
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.HelpOutline,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Support"
                        "es" -> "Soporte"
                        else -> "Support"
                    },
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))

            // Contact Support
            SupportActionItem(
                icon = Icons.Default.Email,
                title = when (currentLanguage) {
                    "fr" -> "Contacter le support"
                    "es" -> "Contactar soporte"
                    else -> "Contact Support"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Obtenir de l'aide de notre équipe"
                    "es" -> "Obtener ayuda de nuestro equipo"
                    else -> "Get help from our team"
                },
                onClick = { showSupportDialog = true }
            )

            // FAQ
            SupportActionItem(
                icon = Icons.Default.QuestionAnswer,
                title = when (currentLanguage) {
                    "fr" -> "Questions fréquentes"
                    "es" -> "Preguntas frecuentes"
                    else -> "Frequently Asked Questions"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Trouvez des réponses aux questions courantes"
                    "es" -> "Encuentre respuestas a preguntas comunes"
                    else -> "Find answers to common questions"
                },
                onClick = {
                    uriHandler.openUri("https://protip365.com/faq")
                }
            )

            // User Guide
            SupportActionItem(
                icon = Icons.AutoMirrored.Filled.MenuBook,
                title = when (currentLanguage) {
                    "fr" -> "Guide de l'utilisateur"
                    "es" -> "Guía del usuario"
                    else -> "User Guide"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Apprenez à utiliser ProTip365"
                    "es" -> "Aprenda a usar ProTip365"
                    else -> "Learn how to use ProTip365"
                },
                onClick = {
                    uriHandler.openUri("https://protip365.com/guide")
                }
            )

            // Video Tutorials
            SupportActionItem(
                icon = Icons.Default.PlayCircleOutline,
                title = when (currentLanguage) {
                    "fr" -> "Tutoriels vidéo"
                    "es" -> "Tutoriales en video"
                    else -> "Video Tutorials"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Regardez des guides vidéo étape par étape"
                    "es" -> "Vea guías en video paso a paso"
                    else -> "Watch step-by-step video guides"
                },
                onClick = {
                    uriHandler.openUri("https://youtube.com/@protip365")
                }
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))

            // Legal Section
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Légal"
                    "es" -> "Legal"
                    else -> "Legal"
                },
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )

            // Privacy Policy
            SupportActionItem(
                icon = Icons.Default.Security,
                title = when (currentLanguage) {
                    "fr" -> "Politique de confidentialité"
                    "es" -> "Política de privacidad"
                    else -> "Privacy Policy"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Comment nous protégeons vos données"
                    "es" -> "Cómo protegemos sus datos"
                    else -> "How we protect your data"
                },
                onClick = {
                    uriHandler.openUri("https://protip365.com/privacy")
                }
            )

            // Terms of Service
            SupportActionItem(
                icon = Icons.AutoMirrored.Filled.Article,
                title = when (currentLanguage) {
                    "fr" -> "Conditions d'utilisation"
                    "es" -> "Términos de servicio"
                    else -> "Terms of Service"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Nos conditions et accords"
                    "es" -> "Nuestros términos y acuerdos"
                    else -> "Our terms and agreements"
                },
                onClick = {
                    uriHandler.openUri("https://protip365.com/terms")
                }
            )

            // Acknowledgments
            SupportActionItem(
                icon = Icons.Default.Favorite,
                title = when (currentLanguage) {
                    "fr" -> "Remerciements"
                    "es" -> "Agradecimientos"
                    else -> "Acknowledgments"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Licences open source et crédits"
                    "es" -> "Licencias de código abierto y créditos"
                    else -> "Open source licenses and credits"
                },
                onClick = {
                    uriHandler.openUri("https://protip365.com/acknowledgments")
                }
            )
        }
    }

    // Support Dialog
    if (showSupportDialog) {
        SupportFormDialog(
            onSend = { subject, message ->
                onSendSupport(subject, message)
                showSupportDialog = false
            },
            onDismiss = { showSupportDialog = false },
            currentLanguage = currentLanguage
        )
    }
}

@Composable
private fun SupportActionItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit
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
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )

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
                Icons.AutoMirrored.Filled.OpenInNew,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SupportFormDialog(
    onSend: (String, String) -> Unit,
    onDismiss: () -> Unit,
    currentLanguage: String
) {
    var subject by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf("general") }
    var expanded by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    var isSending by remember { mutableStateOf(false) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(24.dp)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Header
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Default.Email,
                        contentDescription = null,
                        modifier = Modifier.size(32.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Contacter le support"
                            "es" -> "Contactar soporte"
                            else -> "Contact Support"
                        },
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                // Category Selector
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = it }
                ) {
                    OutlinedTextField(
                        value = getCategoryLabel(selectedCategory, currentLanguage),
                        onValueChange = {},
                        readOnly = true,
                        label = {
                            Text(when (currentLanguage) {
                                "fr" -> "Catégorie"
                                "es" -> "Categoría"
                                else -> "Category"
                            })
                        },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        listOf("general", "bug", "feature", "billing", "account", "other").forEach { category ->
                            DropdownMenuItem(
                                text = { Text(getCategoryLabel(category, currentLanguage)) },
                                onClick = {
                                    selectedCategory = category
                                    expanded = false
                                }
                            )
                        }
                    }
                }

                // Subject Field
                OutlinedTextField(
                    value = subject,
                    onValueChange = { subject = it },
                    label = {
                        Text(when (currentLanguage) {
                            "fr" -> "Sujet"
                            "es" -> "Asunto"
                            else -> "Subject"
                        })
                    },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(
                        imeAction = ImeAction.Next
                    )
                )

                // Message Field
                OutlinedTextField(
                    value = message,
                    onValueChange = { message = it },
                    label = {
                        Text(when (currentLanguage) {
                            "fr" -> "Message"
                            "es" -> "Mensaje"
                            else -> "Message"
                        })
                    },
                    placeholder = {
                        Text(when (currentLanguage) {
                            "fr" -> "Décrivez votre problème ou question..."
                            "es" -> "Describa su problema o pregunta..."
                            else -> "Describe your issue or question..."
                        })
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(150.dp),
                    maxLines = 6,
                    keyboardOptions = KeyboardOptions(
                        imeAction = ImeAction.Default
                    )
                )

                // Info Text
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.Top
                    ) {
                        Icon(
                            Icons.Default.Info,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = when (currentLanguage) {
                                "fr" -> "Nous répondons généralement dans les 24 heures"
                                "es" -> "Generalmente respondemos dentro de 24 horas"
                                else -> "We typically respond within 24 hours"
                            },
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    TextButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        enabled = !isSending
                    ) {
                        Text(when (currentLanguage) {
                            "fr" -> "Annuler"
                            "es" -> "Cancelar"
                            else -> "Cancel"
                        })
                    }

                    Button(
                        onClick = {
                            scope.launch {
                                isSending = true
                                val fullSubject = "[${getCategoryLabel(selectedCategory, "en")}] $subject"
                                onSend(fullSubject, message)
                                isSending = false
                            }
                        },
                        modifier = Modifier.weight(1f),
                        enabled = subject.isNotBlank() && message.isNotBlank() && !isSending
                    ) {
                        if (isSending) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                color = MaterialTheme.colorScheme.onPrimary,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Icon(
                                Icons.AutoMirrored.Filled.Send,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(when (currentLanguage) {
                                "fr" -> "Envoyer"
                                "es" -> "Enviar"
                                else -> "Send"
                            })
                        }
                    }
                }
            }
        }
    }
}

private fun getCategoryLabel(category: String, language: String): String {
    return when (category) {
        "general" -> when (language) {
            "fr" -> "Général"
            "es" -> "General"
            else -> "General"
        }
        "bug" -> when (language) {
            "fr" -> "Signaler un bug"
            "es" -> "Reportar error"
            else -> "Report a Bug"
        }
        "feature" -> when (language) {
            "fr" -> "Demande de fonctionnalité"
            "es" -> "Solicitud de función"
            else -> "Feature Request"
        }
        "billing" -> when (language) {
            "fr" -> "Facturation"
            "es" -> "Facturación"
            else -> "Billing"
        }
        "account" -> when (language) {
            "fr" -> "Compte"
            "es" -> "Cuenta"
            else -> "Account"
        }
        "other" -> when (language) {
            "fr" -> "Autre"
            "es" -> "Otro"
            else -> "Other"
        }
        else -> category
    }
}