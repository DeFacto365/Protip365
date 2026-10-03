package com.protip365.app.presentation.security

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.fragment.app.FragmentActivity
import androidx.hilt.navigation.compose.hiltViewModel
import kotlinx.coroutines.launch

@Composable
fun LockScreen(
    viewModel: LockScreenViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
@Suppress("UNUSED_VARIABLE")
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                        MaterialTheme.colorScheme.secondary.copy(alpha = 0.1f)
                    )
                )
            )
    ) {
        // Blurred background content would go here
        // For now, we'll just show the lock screen UI
        
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // App icon and title
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Security,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Text(
                text = "ProTip365",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Enter your PIN to continue",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // PIN entry field
            OutlinedTextField(
                value = state.enteredPIN,
                onValueChange = { viewModel.updatePIN(it) },
                label = { Text("PIN") },
                placeholder = { Text("Enter 4-digit PIN") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                visualTransformation = androidx.compose.ui.text.input.PasswordVisualTransformation(),
                singleLine = true,
                modifier = Modifier.width(200.dp),
                isError = state.error != null
            )
            
            if (state.error != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = state.error ?: "",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                    textAlign = TextAlign.Center
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Biometric authentication button
            if (state.isBiometricAvailable && state.currentSecurityType != SecurityType.PIN) {
                Button(
                    onClick = {
                        scope.launch {
                            if (context is FragmentActivity) {
                                viewModel.authenticateWithBiometric(context)
                            }
                        }
                    },
                    modifier = Modifier.width(200.dp)
                ) {
                    Icon(Icons.Default.Fingerprint, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Use Biometric")
                }
                
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            // Security type info
            Text(
                text = when (state.currentSecurityType) {
                    SecurityType.PIN -> "PIN Protection"
                    SecurityType.BIOMETRIC -> "Biometric Protection"
                    SecurityType.BOTH -> "PIN + Biometric Protection"
                    else -> "No Protection"
                },
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
fun PINSetupScreen(
    onPINSet: () -> Unit,
    viewModel: PINSetupViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Setup icon
        Box(
            modifier = Modifier
                .size(120.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Default.Lock,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onPrimary
            )
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "Set Up PIN",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Create a 4-digit PIN to secure your app",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        // PIN entry fields
        if (state.step == PINSetupStep.ENTER_PIN) {
            OutlinedTextField(
                value = state.newPIN,
                onValueChange = { viewModel.updateNewPIN(it) },
                label = { Text("Enter PIN") },
                placeholder = { Text("4 digits") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                visualTransformation = androidx.compose.ui.text.input.PasswordVisualTransformation(),
                singleLine = true,
                modifier = Modifier.width(200.dp),
                isError = state.error != null
            )
        } else {
            OutlinedTextField(
                value = state.confirmPIN,
                onValueChange = { viewModel.updateConfirmPIN(it) },
                label = { Text("Confirm PIN") },
                placeholder = { Text("Re-enter PIN") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                visualTransformation = androidx.compose.ui.text.input.PasswordVisualTransformation(),
                singleLine = true,
                modifier = Modifier.width(200.dp),
                isError = state.error != null
            )
        }
        
        if (state.error != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = state.error ?: "",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center
            )
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Button(
            onClick = {
                if (state.step == PINSetupStep.ENTER_PIN) {
                    viewModel.proceedToConfirm()
                } else {
                    if (viewModel.confirmPIN()) {
                        onPINSet()
                    }
                }
            },
            modifier = Modifier.width(200.dp),
            enabled = when (state.step) {
                PINSetupStep.ENTER_PIN -> state.newPIN.length == 4
                PINSetupStep.CONFIRM_PIN -> state.confirmPIN.length == 4
            }
        ) {
            Text(if (state.step == PINSetupStep.ENTER_PIN) "Continue" else "Set PIN")
        }
    }
}

enum class PINSetupStep {
    ENTER_PIN,
    CONFIRM_PIN
}