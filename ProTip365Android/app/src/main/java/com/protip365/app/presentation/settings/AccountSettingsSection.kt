package com.protip365.app.presentation.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import kotlinx.coroutines.launch

@Composable
fun AccountSettingsSection(
    onExportData: () -> Unit,
    onChangePassword: () -> Unit,
    onSignOut: () -> Unit,
    onDeleteAccount: () -> Unit,
    currentLanguage: String = "en"
) {
    var showExportDialog by remember { mutableStateOf(false) }
    var showPasswordDialog by remember { mutableStateOf(false) }
    var showSignOutDialog by remember { mutableStateOf(false) }
    var showDeleteAccountDialog by remember { mutableStateOf(false) }

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
                    Icons.Default.AccountCircle,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Compte"
                        "es" -> "Cuenta"
                        else -> "Account"
                    },
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Divider(modifier = Modifier.padding(vertical = 4.dp))

            // Export Data
            AccountActionItem(
                icon = Icons.Default.Download,
                title = when (currentLanguage) {
                    "fr" -> "Exporter les données"
                    "es" -> "Exportar datos"
                    else -> "Export Data"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Télécharger vos données en CSV"
                    "es" -> "Descargar sus datos en CSV"
                    else -> "Download your data as CSV"
                },
                onClick = { showExportDialog = true }
            )

            // Change Password
            AccountActionItem(
                icon = Icons.Default.Lock,
                title = when (currentLanguage) {
                    "fr" -> "Changer le mot de passe"
                    "es" -> "Cambiar contraseña"
                    else -> "Change Password"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Mettre à jour votre mot de passe"
                    "es" -> "Actualizar su contraseña"
                    else -> "Update your password"
                },
                onClick = { showPasswordDialog = true }
            )

            // Sign Out
            AccountActionItem(
                icon = Icons.Default.Logout,
                title = when (currentLanguage) {
                    "fr" -> "Se déconnecter"
                    "es" -> "Cerrar sesión"
                    else -> "Sign Out"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Déconnexion de votre compte"
                    "es" -> "Cerrar sesión de su cuenta"
                    else -> "Sign out of your account"
                },
                onClick = { showSignOutDialog = true },
                tintColor = MaterialTheme.colorScheme.primary
            )

            Divider(modifier = Modifier.padding(vertical = 4.dp))

            // Delete Account (Danger Zone)
            AccountActionItem(
                icon = Icons.Default.DeleteForever,
                title = when (currentLanguage) {
                    "fr" -> "Supprimer le compte"
                    "es" -> "Eliminar cuenta"
                    else -> "Delete Account"
                },
                subtitle = when (currentLanguage) {
                    "fr" -> "Supprimer définitivement votre compte"
                    "es" -> "Eliminar permanentemente su cuenta"
                    else -> "Permanently delete your account"
                },
                onClick = { showDeleteAccountDialog = true },
                tintColor = MaterialTheme.colorScheme.error
            )
        }
    }

    // Export Data Dialog
    if (showExportDialog) {
        ExportDataDialog(
            onExport = { format ->
                onExportData()
                showExportDialog = false
            },
            onDismiss = { showExportDialog = false },
            currentLanguage = currentLanguage
        )
    }

    // Change Password Dialog
    if (showPasswordDialog) {
        ChangePasswordDialog(
            onChangePassword = {
                onChangePassword()
                showPasswordDialog = false
            },
            onDismiss = { showPasswordDialog = false },
            currentLanguage = currentLanguage
        )
    }

    // Sign Out Confirmation Dialog
    if (showSignOutDialog) {
        ConfirmationDialog(
            title = when (currentLanguage) {
                "fr" -> "Se déconnecter?"
                "es" -> "¿Cerrar sesión?"
                else -> "Sign Out?"
            },
            message = when (currentLanguage) {
                "fr" -> "Êtes-vous sûr de vouloir vous déconnecter?"
                "es" -> "¿Está seguro de que desea cerrar sesión?"
                else -> "Are you sure you want to sign out?"
            },
            confirmText = when (currentLanguage) {
                "fr" -> "Se déconnecter"
                "es" -> "Cerrar sesión"
                else -> "Sign Out"
            },
            onConfirm = {
                onSignOut()
                showSignOutDialog = false
            },
            onDismiss = { showSignOutDialog = false },
            confirmColor = MaterialTheme.colorScheme.primary
        )
    }

    // Delete Account Confirmation Dialog
    if (showDeleteAccountDialog) {
        DeleteAccountDialog(
            onDelete = {
                onDeleteAccount()
                showDeleteAccountDialog = false
            },
            onDismiss = { showDeleteAccountDialog = false },
            currentLanguage = currentLanguage
        )
    }
}

@Composable
private fun AccountActionItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    tintColor: Color = MaterialTheme.colorScheme.onSurface
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
                tint = tintColor,
                modifier = Modifier.size(24.dp)
            )

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium,
                    color = tintColor
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
private fun ExportDataDialog(
    onExport: (String) -> Unit,
    onDismiss: () -> Unit,
    currentLanguage: String
) {
    var selectedFormat by remember { mutableStateOf("CSV") }
    var selectedPeriod by remember { mutableStateOf("all") }

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
                        "fr" -> "Exporter les données"
                        "es" -> "Exportar datos"
                        else -> "Export Data"
                    },
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )

                // Format Selection
                Column {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Format"
                            "es" -> "Formato"
                            else -> "Format"
                        },
                        style = MaterialTheme.typography.labelLarge,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = selectedFormat == "CSV",
                            onClick = { selectedFormat = "CSV" },
                            label = { Text("CSV") }
                        )
                        FilterChip(
                            selected = selectedFormat == "JSON",
                            onClick = { selectedFormat = "JSON" },
                            label = { Text("JSON") }
                        )
                        FilterChip(
                            selected = selectedFormat == "PDF",
                            onClick = { selectedFormat = "PDF" },
                            label = { Text("PDF") }
                        )
                    }
                }

                // Period Selection
                Column {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "Période"
                            "es" -> "Período"
                            else -> "Period"
                        },
                        style = MaterialTheme.typography.labelLarge,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    Column(
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        RadioButton(
                            label = when (currentLanguage) {
                                "fr" -> "Toutes les données"
                                "es" -> "Todos los datos"
                                else -> "All data"
                            },
                            selected = selectedPeriod == "all",
                            onClick = { selectedPeriod = "all" }
                        )
                        RadioButton(
                            label = when (currentLanguage) {
                                "fr" -> "Cette année"
                                "es" -> "Este año"
                                else -> "This year"
                            },
                            selected = selectedPeriod == "year",
                            onClick = { selectedPeriod = "year" }
                        )
                        RadioButton(
                            label = when (currentLanguage) {
                                "fr" -> "Ce mois"
                                "es" -> "Este mes"
                                else -> "This month"
                            },
                            selected = selectedPeriod == "month",
                            onClick = { selectedPeriod = "month" }
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
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(when (currentLanguage) {
                            "fr" -> "Annuler"
                            "es" -> "Cancelar"
                            else -> "Cancel"
                        })
                    }

                    Button(
                        onClick = { onExport(selectedFormat) },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(
                            Icons.Default.Download,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(when (currentLanguage) {
                            "fr" -> "Exporter"
                            "es" -> "Exportar"
                            else -> "Export"
                        })
                    }
                }
            }
        }
    }
}

@Composable
private fun RadioButton(
    label: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
    ) {
        RadioButton(
            selected = selected,
            onClick = onClick
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(start = 8.dp)
        )
    }
}

@Composable
private fun ChangePasswordDialog(
    onChangePassword: () -> Unit,
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
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Icon(
                    Icons.Default.Lock,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.primary
                )

                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Changer le mot de passe"
                        "es" -> "Cambiar contraseña"
                        else -> "Change Password"
                    },
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )

                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Un e-mail de réinitialisation du mot de passe sera envoyé à votre adresse e-mail enregistrée."
                        "es" -> "Se enviará un correo electrónico de restablecimiento de contraseña a su dirección de correo electrónico registrada."
                        else -> "A password reset email will be sent to your registered email address."
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

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
                        onClick = onChangePassword,
                        modifier = Modifier.weight(1f)
                    ) {
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

@Composable
private fun DeleteAccountDialog(
    onDelete: () -> Unit,
    onDismiss: () -> Unit,
    currentLanguage: String
) {
    var confirmationText by remember { mutableStateOf("") }
    val expectedText = "DELETE"

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.errorContainer
            )
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Icon(
                    Icons.Default.Warning,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.error
                )

                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Supprimer le compte?"
                        "es" -> "¿Eliminar cuenta?"
                        else -> "Delete Account?"
                    },
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.error
                )

                Column(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "⚠️ Cette action est irréversible!"
                            "es" -> "⚠️ ¡Esta acción es irreversible!"
                            else -> "⚠️ This action is irreversible!"
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )

                    Text(
                        text = when (currentLanguage) {
                            "fr" -> "La suppression de votre compte entraînera:\n• La perte permanente de toutes vos données\n• L'annulation de tous les abonnements\n• L'impossibilité de récupérer votre compte"
                            "es" -> "Eliminar su cuenta resultará en:\n• La pérdida permanente de todos sus datos\n• La cancelación de todas las suscripciones\n• La imposibilidad de recuperar su cuenta"
                            else -> "Deleting your account will result in:\n• Permanent loss of all your data\n• Cancellation of all subscriptions\n• Inability to recover your account"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }

                OutlinedTextField(
                    value = confirmationText,
                    onValueChange = { confirmationText = it },
                    label = {
                        Text(when (currentLanguage) {
                            "fr" -> "Tapez DELETE pour confirmer"
                            "es" -> "Escriba DELETE para confirmar"
                            else -> "Type DELETE to confirm"
                        })
                    },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = MaterialTheme.colorScheme.error,
                        unfocusedBorderColor = MaterialTheme.colorScheme.error.copy(alpha = 0.5f)
                    )
                )

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
                        onClick = onDelete,
                        modifier = Modifier.weight(1f),
                        enabled = confirmationText == expectedText,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Text(when (currentLanguage) {
                            "fr" -> "Supprimer"
                            "es" -> "Eliminar"
                            else -> "Delete"
                        })
                    }
                }
            }
        }
    }
}

@Composable
private fun ConfirmationDialog(
    title: String,
    message: String,
    confirmText: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    confirmColor: Color = MaterialTheme.colorScheme.primary
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
                    text = title,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )

                Text(
                    text = message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    TextButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Cancel")
                    }

                    Button(
                        onClick = onConfirm,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = confirmColor
                        )
                    ) {
                        Text(confirmText)
                    }
                }
            }
        }
    }
}