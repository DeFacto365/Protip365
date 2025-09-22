package com.protip365.app.presentation.settings

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import kotlinx.coroutines.launch

enum class SecurityType {
    NONE,
    PIN_CODE,
    BIOMETRIC,
    BOTH
}

@Composable
fun SecuritySettingsSection(
    currentSecurityType: SecurityType,
    onSecurityTypeChange: (SecurityType) -> Unit,
    onPINChange: (String) -> Unit,
    currentLanguage: String = "en"
) {
    var showPINSetup by remember { mutableStateOf(false) }
    var showVerifyDialog by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val biometricManager = remember { BiometricManager.from(context) }
    val isBiometricAvailable = remember {
        biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) ==
        BiometricManager.BIOMETRIC_SUCCESS
    }

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
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Default.Security,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Sécurité"
                        "es" -> "Seguridad"
                        else -> "Security"
                    },
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            // App Lock Security
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Verrouillage de l'application"
                        "es" -> "Bloqueo de aplicación"
                        else -> "App Lock Security"
                    },
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )

                // None Option
                SecurityOptionButton(
                    type = SecurityType.NONE,
                    title = when (currentLanguage) {
                        "fr" -> "Aucun"
                        "es" -> "Ninguno"
                        else -> "None"
                    },
                    subtitle = when (currentLanguage) {
                        "fr" -> "Pas de sécurité supplémentaire"
                        "es" -> "Sin seguridad adicional"
                        else -> "No additional security"
                    },
                    icon = Icons.Default.LockOpen,
                    isSelected = currentSecurityType == SecurityType.NONE,
                    onClick = {
                        if (currentSecurityType != SecurityType.NONE) {
                            showVerifyDialog = true
                        }
                    }
                )

                // PIN Option
                SecurityOptionButton(
                    type = SecurityType.PIN_CODE,
                    title = when (currentLanguage) {
                        "fr" -> "Code PIN"
                        "es" -> "Código PIN"
                        else -> "PIN Code"
                    },
                    subtitle = when (currentLanguage) {
                        "fr" -> "Code à 4 chiffres"
                        "es" -> "Código de 4 dígitos"
                        else -> "4-digit code"
                    },
                    icon = Icons.Default.Pin,
                    isSelected = currentSecurityType == SecurityType.PIN_CODE,
                    onClick = {
                        showPINSetup = true
                    }
                )

                // Biometric Option (if available)
                if (isBiometricAvailable) {
                    SecurityOptionButton(
                        type = SecurityType.BIOMETRIC,
                        title = when (currentLanguage) {
                            "fr" -> "Biométrie"
                            "es" -> "Biometría"
                            else -> "Biometric"
                        },
                        subtitle = when (currentLanguage) {
                            "fr" -> "Empreinte ou reconnaissance faciale"
                            "es" -> "Huella dactilar o reconocimiento facial"
                            else -> "Fingerprint or Face ID"
                        },
                        icon = Icons.Default.Fingerprint,
                        isSelected = currentSecurityType == SecurityType.BIOMETRIC,
                        onClick = {
                            authenticateAndSetBiometric(
                                context = context,
                                onSuccess = {
                                    onSecurityTypeChange(SecurityType.BIOMETRIC)
                                },
                                language = currentLanguage
                            )
                        }
                    )

                    // Both Option
                    SecurityOptionButton(
                        type = SecurityType.BOTH,
                        title = when (currentLanguage) {
                            "fr" -> "PIN et Biométrie"
                            "es" -> "PIN y Biometría"
                            else -> "PIN & Biometric"
                        },
                        subtitle = when (currentLanguage) {
                            "fr" -> "Double authentification"
                            "es" -> "Doble autenticación"
                            else -> "Double authentication"
                        },
                        icon = Icons.Default.Shield,
                        isSelected = currentSecurityType == SecurityType.BOTH,
                        onClick = {
                            showPINSetup = true
                        }
                    )
                }
            }

            // Auto-lock settings
            AutoLockSettings(currentLanguage)
        }
    }

    // PIN Setup Dialog
    if (showPINSetup) {
        PINSetupDialog(
            onPINSet = { pin ->
                onPINChange(pin)
                if (currentSecurityType == SecurityType.BOTH) {
                    authenticateAndSetBiometric(
                        context = context,
                        onSuccess = {
                            onSecurityTypeChange(SecurityType.BOTH)
                        },
                        language = currentLanguage
                    )
                } else {
                    onSecurityTypeChange(SecurityType.PIN_CODE)
                }
                showPINSetup = false
            },
            onDismiss = { showPINSetup = false },
            currentLanguage = currentLanguage
        )
    }

    // Verify Dialog for disabling security
    if (showVerifyDialog) {
        VerifySecurityDialog(
            currentType = currentSecurityType,
            onVerified = {
                onSecurityTypeChange(SecurityType.NONE)
                showVerifyDialog = false
            },
            onDismiss = { showVerifyDialog = false },
            currentLanguage = currentLanguage
        )
    }
}

@Composable
private fun SecurityOptionButton(
    type: SecurityType,
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    isSelected: Boolean,
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
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = if (isSelected)
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
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    color = if (isSelected)
                        MaterialTheme.colorScheme.onPrimaryContainer
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = if (isSelected)
                        MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            }

            if (isSelected) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@Composable
private fun AutoLockSettings(
    currentLanguage: String
) {
    var autoLockEnabled by remember { mutableStateOf(true) }
    var selectedTimeout by remember { mutableStateOf("immediate") }

    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Divider()

        // Auto-lock toggle
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = when (currentLanguage) {
                    "fr" -> "Verrouillage automatique"
                    "es" -> "Bloqueo automático"
                    else -> "Auto-lock"
                },
                style = MaterialTheme.typography.bodyLarge
            )
            Switch(
                checked = autoLockEnabled,
                onCheckedChange = { autoLockEnabled = it }
            )
        }

        // Timeout selector
        if (autoLockEnabled) {
            var expanded by remember { mutableStateOf(false) }

            Box {
                OutlinedTextField(
                    value = when (selectedTimeout) {
                        "immediate" -> when (currentLanguage) {
                            "fr" -> "Immédiatement"
                            "es" -> "Inmediatamente"
                            else -> "Immediately"
                        }
                        "1min" -> when (currentLanguage) {
                            "fr" -> "Après 1 minute"
                            "es" -> "Después de 1 minuto"
                            else -> "After 1 minute"
                        }
                        "5min" -> when (currentLanguage) {
                            "fr" -> "Après 5 minutes"
                            "es" -> "Después de 5 minutos"
                            else -> "After 5 minutes"
                        }
                        else -> selectedTimeout
                    },
                    onValueChange = {},
                    label = {
                        Text(when (currentLanguage) {
                            "fr" -> "Délai de verrouillage"
                            "es" -> "Tiempo de bloqueo"
                            else -> "Lock timeout"
                        })
                    },
                    modifier = Modifier.fillMaxWidth(),
                    readOnly = true,
                    trailingIcon = {
                        Icon(
                            if (expanded) Icons.Default.ArrowDropUp else Icons.Default.ArrowDropDown,
                            contentDescription = null
                        )
                    },
                    singleLine = true
                )

                Box(
                    modifier = Modifier
                        .matchParentSize()
                        .clickable { expanded = true }
                )

                DropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    listOf("immediate", "1min", "5min").forEach { timeout ->
                        DropdownMenuItem(
                            text = {
                                Text(when (timeout) {
                                    "immediate" -> when (currentLanguage) {
                                        "fr" -> "Immédiatement"
                                        "es" -> "Inmediatamente"
                                        else -> "Immediately"
                                    }
                                    "1min" -> when (currentLanguage) {
                                        "fr" -> "Après 1 minute"
                                        "es" -> "Después de 1 minuto"
                                        else -> "After 1 minute"
                                    }
                                    "5min" -> when (currentLanguage) {
                                        "fr" -> "Après 5 minutes"
                                        "es" -> "Después de 5 minutos"
                                        else -> "After 5 minutes"
                                    }
                                    else -> timeout
                                })
                            },
                            onClick = {
                                selectedTimeout = timeout
                                expanded = false
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PINSetupDialog(
    onPINSet: (String) -> Unit,
    onDismiss: () -> Unit,
    currentLanguage: String
) {
    var pin by remember { mutableStateOf("") }
    var confirmPin by remember { mutableStateOf("") }
    var step by remember { mutableStateOf(1) } // 1: Enter PIN, 2: Confirm PIN
    var error by remember { mutableStateOf(false) }

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
                    text = when (step) {
                        1 -> when (currentLanguage) {
                            "fr" -> "Créer un code PIN"
                            "es" -> "Crear código PIN"
                            else -> "Create PIN Code"
                        }
                        else -> when (currentLanguage) {
                            "fr" -> "Confirmer le code PIN"
                            "es" -> "Confirmar código PIN"
                            else -> "Confirm PIN Code"
                        }
                    },
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )

                Text(
                    text = when (step) {
                        1 -> when (currentLanguage) {
                            "fr" -> "Entrez un code à 4 chiffres"
                            "es" -> "Ingrese un código de 4 dígitos"
                            else -> "Enter a 4-digit code"
                        }
                        else -> when (currentLanguage) {
                            "fr" -> "Entrez à nouveau le code PIN"
                            "es" -> "Ingrese el código PIN nuevamente"
                            else -> "Enter PIN code again"
                        }
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // PIN Input
                OutlinedTextField(
                    value = if (step == 1) pin else confirmPin,
                    onValueChange = { newValue ->
                        if (newValue.length <= 4 && newValue.all { it.isDigit() }) {
                            if (step == 1) {
                                pin = newValue
                            } else {
                                confirmPin = newValue
                            }
                            error = false
                        }
                    },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.NumberPassword
                    ),
                    visualTransformation = PasswordVisualTransformation(),
                    isError = error,
                    supportingText = if (error) {
                        {
                            Text(
                                text = when (currentLanguage) {
                                    "fr" -> "Les codes PIN ne correspondent pas"
                                    "es" -> "Los códigos PIN no coinciden"
                                    else -> "PIN codes don't match"
                                },
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    } else null,
                    modifier = Modifier.fillMaxWidth(),
                    textStyle = LocalTextStyle.current.copy(
                        textAlign = TextAlign.Center,
                        letterSpacing = 8.sp
                    ),
                    singleLine = true
                )

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
                        onClick = {
                            if (step == 1) {
                                if (pin.length == 4) {
                                    step = 2
                                }
                            } else {
                                if (pin == confirmPin) {
                                    onPINSet(pin)
                                } else {
                                    error = true
                                    confirmPin = ""
                                }
                            }
                        },
                        modifier = Modifier.weight(1f),
                        enabled = (step == 1 && pin.length == 4) ||
                                 (step == 2 && confirmPin.length == 4)
                    ) {
                        Text(when (step) {
                            1 -> when (currentLanguage) {
                                "fr" -> "Suivant"
                                "es" -> "Siguiente"
                                else -> "Next"
                            }
                            else -> when (currentLanguage) {
                                "fr" -> "Confirmer"
                                "es" -> "Confirmar"
                                else -> "Confirm"
                            }
                        })
                    }
                }
            }
        }
    }
}

@Composable
private fun VerifySecurityDialog(
    currentType: SecurityType,
    onVerified: () -> Unit,
    onDismiss: () -> Unit,
    currentLanguage: String
) {
    // Simplified verification dialog
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
                    Icons.Default.Warning,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.error
                )

                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Désactiver la sécurité?"
                        "es" -> "¿Desactivar seguridad?"
                        else -> "Disable Security?"
                    },
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )

                Text(
                    text = when (currentLanguage) {
                        "fr" -> "Cela supprimera toute protection de sécurité de l'application"
                        "es" -> "Esto eliminará toda la protección de seguridad de la aplicación"
                        else -> "This will remove all security protection from the app"
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
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
                        onClick = onVerified,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Text(when (currentLanguage) {
                            "fr" -> "Désactiver"
                            "es" -> "Desactivar"
                            else -> "Disable"
                        })
                    }
                }
            }
        }
    }
}

private fun authenticateAndSetBiometric(
    context: android.content.Context,
    onSuccess: () -> Unit,
    language: String
) {
    val activity = context as? FragmentActivity ?: return

    val executor = ContextCompat.getMainExecutor(context)
    val biometricPrompt = BiometricPrompt(
        activity,
        executor,
        object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                onSuccess()
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                // Handle error
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                // Handle failure
            }
        }
    )

    val promptInfo = BiometricPrompt.PromptInfo.Builder()
        .setTitle(when (language) {
            "fr" -> "Authentification biométrique"
            "es" -> "Autenticación biométrica"
            else -> "Biometric Authentication"
        })
        .setSubtitle(when (language) {
            "fr" -> "Configurez l'authentification biométrique"
            "es" -> "Configure la autenticación biométrica"
            else -> "Set up biometric authentication"
        })
        .setNegativeButtonText(when (language) {
            "fr" -> "Annuler"
            "es" -> "Cancelar"
            else -> "Cancel"
        })
        .build()

    biometricPrompt.authenticate(promptInfo)
}