package com.protip365.app.presentation.auth

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.protip365.app.R
import com.protip365.app.presentation.components.LanguageSelector
import com.protip365.app.presentation.localization.LocalizationManager
import kotlinx.coroutines.launch
import java.util.*
import javax.inject.Inject

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AuthView(
    navController: NavController,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val authState by viewModel.state.collectAsState()
    val scope = rememberCoroutineScope()

    var isSignUpMode by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var confirmPasswordVisible by remember { mutableStateOf(false) }

    // Language selector state
    var selectedLanguage by remember { mutableStateOf("en") }

    // Form validation
    val isEmailValid = email.isNotBlank() && android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()
    val isPasswordValid = password.length >= 6
    val isPasswordMatch = if (isSignUpMode) password == confirmPassword else true
    val isNameValid = if (isSignUpMode) name.isNotBlank() else true
    val isFormValid = isEmailValid && isPasswordValid && isPasswordMatch && isNameValid && !authState.isLoading
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Language selector at top right (matching iOS)
        LanguageSelector(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(16.dp),
            currentLanguage = selectedLanguage,
            onLanguageSelected = { language ->
                selectedLanguage = language
                // Language update handled through preferences
            }
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Spacer(modifier = Modifier.height(60.dp)) // Account for language selector
            
            // Logo Section (matching iOS)
            Card(
                modifier = Modifier
                    .size(100.dp)
                    .shadow(10.dp, RoundedCornerShape(20.dp)),
                shape = RoundedCornerShape(20.dp)
            ) {
                Image(
                    painter = painterResource(id = R.drawable.protip365_logo),
                    contentDescription = "ProTip365 Logo",
                    modifier = Modifier.fillMaxSize()
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // App Title
            Text(
                text = "ProTip365",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground
            )
            
            // Welcome Text (localized based on selected language)
            Text(
                text = when (selectedLanguage) {
                    "fr" -> "Suivez vos pourboires facilement"
                    "es" -> "Rastrea tus propinas fácilmente"
                    else -> "Track your tips easily"
                },
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp)
            )
            
            Spacer(modifier = Modifier.height(48.dp))
            
            // Remove the toggle - we'll handle it differently like iOS
            // Auth Mode Toggle removed - using separate flows like iOS
            /*Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
                        shape = RoundedCornerShape(16.dp)
                    )
                    .padding(4.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    // Animated selection indicator
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .background(
                                color = if (!isSignUpMode) MaterialTheme.colorScheme.primary else Color.Transparent,
                                shape = RoundedCornerShape(12.dp)
                            )
                            .clickable { isSignUpMode = false }
                            .padding(vertical = 2.dp)
                    ) {
                        Text(
                            text = "Sign In",
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 14.dp),
                            textAlign = TextAlign.Center,
                            color = if (!isSignUpMode) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                            fontWeight = if (!isSignUpMode) FontWeight.SemiBold else FontWeight.Medium,
                            style = MaterialTheme.typography.labelLarge
                        )
                    }
                    
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .background(
                                color = if (isSignUpMode) MaterialTheme.colorScheme.primary else Color.Transparent,
                                shape = RoundedCornerShape(12.dp)
                            )
                            .clickable { isSignUpMode = true }
                            .padding(vertical = 2.dp)
                    ) {
                        Text(
                            text = "Sign Up",
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 14.dp),
                            textAlign = TextAlign.Center,
                            color = if (isSignUpMode) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                            fontWeight = if (isSignUpMode) FontWeight.SemiBold else FontWeight.Medium,
                            style = MaterialTheme.typography.labelLarge
                        )
                    }
                }
            }*/

            Spacer(modifier = Modifier.height(32.dp))
            
            // Form Fields
            // Name field (only for sign up)
            AnimatedVisibility(
                visible = isSignUpMode,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                Column {
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        label = { Text("Name") },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Text,
                            imeAction = ImeAction.Next
                        ),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        isError = isSignUpMode && name.isBlank(),
                        supportingText = if (isSignUpMode && name.isBlank()) {
                            { Text("Name is required", color = MaterialTheme.colorScheme.error) }
                        } else null
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }
            }
            
            // Email field
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = {
                    Text(
                        when (selectedLanguage) {
                            "fr" -> "Courriel"
                            "es" -> "Correo electrónico"
                            else -> "Email"
                        }
                    )
                },
                leadingIcon = { 
                    Icon(
                        Icons.Default.Email,
                        contentDescription = "Email",
                        tint = MaterialTheme.colorScheme.primary
                    ) 
                },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Next
                ),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                isError = email.isNotBlank() && !isEmailValid,
                supportingText = if (email.isNotBlank() && !isEmailValid) {
                    { Text("Invalid email address", color = MaterialTheme.colorScheme.error) }
                } else null,
                shape = MaterialTheme.shapes.large,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline
                )
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Password field
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = {
                    Text(
                        when (selectedLanguage) {
                            "fr" -> "Mot de passe"
                            "es" -> "Contraseña"
                            else -> "Password"
                        }
                    )
                },
                leadingIcon = { 
                    Icon(
                        Icons.Default.Lock,
                        contentDescription = "Password",
                        tint = MaterialTheme.colorScheme.primary
                    ) 
                },
                visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = if (isSignUpMode) ImeAction.Next else ImeAction.Done
                ),
                trailingIcon = {
                    IconButton(onClick = { passwordVisible = !passwordVisible }) {
                        Icon(
                            imageVector = if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                            contentDescription = if (passwordVisible) "Hide password" else "Show password",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                isError = password.isNotBlank() && !isPasswordValid,
                supportingText = if (password.isNotBlank() && !isPasswordValid) {
                    { Text("Password must be at least 6 characters", color = MaterialTheme.colorScheme.error) }
                } else null,
                shape = MaterialTheme.shapes.large,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline
                )
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Confirm Password field (only for sign up)
            AnimatedVisibility(
                visible = isSignUpMode,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                Column {
                    OutlinedTextField(
                        value = confirmPassword,
                        onValueChange = { confirmPassword = it },
                        label = { Text("Confirm Password") },
                        visualTransformation = if (confirmPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Done
                        ),
                        trailingIcon = {
                            IconButton(onClick = { confirmPasswordVisible = !confirmPasswordVisible }) {
                                Icon(
                                    imageVector = if (confirmPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                    contentDescription = if (confirmPasswordVisible) "Hide password" else "Show password"
                                )
                            }
                        },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        isError = isSignUpMode && confirmPassword.isNotBlank() && !isPasswordMatch,
                        supportingText = if (isSignUpMode && confirmPassword.isNotBlank() && !isPasswordMatch) {
                            { Text("Passwords don't match", color = MaterialTheme.colorScheme.error) }
                        } else null
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }
            }
            
            // Forgot password (only for sign in)
            if (!isSignUpMode) {
                TextButton(
                    onClick = { navController.navigate("forgot_password") },
                    modifier = Modifier.align(Alignment.End)
                ) {
                    Text(
                        when (selectedLanguage) {
                            "fr" -> "Mot de passe oublié?"
                            "es" -> "¿Olvidaste tu contraseña?"
                            else -> "Forgot Password?"
                        }
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Submit button
            Button(
                onClick = {
                    if (isSignUpMode) {
                        viewModel.updateEmail(email)
                        viewModel.updatePassword(password)
                        viewModel.updateName(name)
                        viewModel.signUp()
                    } else {
                        viewModel.updateEmail(email)
                        viewModel.updatePassword(password)
                        viewModel.signIn()
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = isFormValid,
                shape = MaterialTheme.shapes.large,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary
                ),
                elevation = ButtonDefaults.buttonElevation(
                    defaultElevation = 4.dp,
                    pressedElevation = 8.dp
                )
            ) {
                if (authState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 3.dp
                    )
                } else {
                    Text(
                        text = if (isSignUpMode) {
                            when (selectedLanguage) {
                                "fr" -> "Créer un compte"
                                "es" -> "Crear cuenta"
                                else -> "Create Account"
                            }
                        } else {
                            when (selectedLanguage) {
                                "fr" -> "Se connecter"
                                "es" -> "Iniciar sesión"
                                else -> "Sign In"
                            }
                        },
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Toggle mode button
            TextButton(
                onClick = { isSignUpMode = !isSignUpMode },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = if (isSignUpMode) {
                        when (selectedLanguage) {
                            "fr" -> "Déjà un compte? Se connecter"
                            "es" -> "¿Ya tienes cuenta? Iniciar sesión"
                            else -> "Have an account? Sign in"
                        }
                    } else {
                        when (selectedLanguage) {
                            "fr" -> "Pas de compte? Créer un compte"
                            "es" -> "¿Sin cuenta? Crear cuenta"
                            else -> "No account? Create one"
                        }
                    },
                    style = MaterialTheme.typography.bodyMedium
                )
            }
            
            // Error message
            AnimatedVisibility(
                visible = authState.generalError != null,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = authState.generalError ?: "",
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(16.dp),
                        textAlign = TextAlign.Center
                    )
                }
            }
            
            // Success message (for password reset)
            AnimatedVisibility(
                visible = authState.successMessage?.contains("reset", ignoreCase = true) == true,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer
                    )
                ) {
                    Text(
                        text = "Password reset link sent to your email",
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.padding(16.dp),
                        textAlign = TextAlign.Center
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(48.dp))
        }
    }
    
    // Navigate to appropriate screen on successful authentication
    LaunchedEffect(authState.isAuthenticated, authState.isNewUser) {
        if (authState.isAuthenticated) {
            if (authState.isNewUser) {
                navController.navigate("onboarding") {
                    popUpTo("auth") { inclusive = true }
                }
            } else {
                navController.navigate("main") {
                    popUpTo("auth") { inclusive = true }
                }
            }
        }
    }
}
