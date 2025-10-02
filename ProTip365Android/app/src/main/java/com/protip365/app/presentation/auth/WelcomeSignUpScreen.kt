package com.protip365.app.presentation.auth

import androidx.compose.animation.*
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
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
import kotlinx.coroutines.launch
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WelcomeSignUpScreen(
    navController: NavController,
    onComplete: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val authState by viewModel.state.collectAsState()
    val scope = rememberCoroutineScope()
    
    var currentStep by remember { mutableStateOf(1) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var userName by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var confirmPasswordVisible by remember { mutableStateOf(false) }
    var selectedLanguage by remember { mutableStateOf("en") }
    var emailError by remember { mutableStateOf("") }
    var passwordError by remember { mutableStateOf("") }
    var isCheckingEmail by remember { mutableStateOf(false) }
    var emailIsValid by remember { mutableStateOf(false) }
    var emailAlreadyExists by remember { mutableStateOf(false) }
    
    val totalSteps = 3
    
    // Form validation
    val isEmailValid = email.isNotBlank() && android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()
    val isPasswordValid = password.length >= 6
    val isPasswordMatch = password == confirmPassword
    val isNameValid = userName.isNotBlank()
    
    val isStepValid = when (currentStep) {
        1 -> isEmailValid && emailIsValid && !emailAlreadyExists
        2 -> isPasswordValid && isPasswordMatch
        3 -> isNameValid
        else -> false
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when (currentStep) {
                            1 -> when (selectedLanguage) {
                                "fr" -> "Étape 1 sur 3"
                                "es" -> "Paso 1 de 3"
                                else -> "Step 1 of 3"
                            }
                            2 -> when (selectedLanguage) {
                                "fr" -> "Étape 2 sur 3"
                                "es" -> "Paso 2 de 3"
                                else -> "Step 2 of 3"
                            }
                            3 -> when (selectedLanguage) {
                                "fr" -> "Étape 3 sur 3"
                                "es" -> "Paso 3 de 3"
                                else -> "Step 3 of 3"
                            }
                            else -> ""
                        },
                        style = MaterialTheme.typography.headlineSmall
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { onComplete() }) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Base background
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MaterialTheme.colorScheme.background)
            )

            // Gradient overlay (iOS-style)
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        brush = androidx.compose.ui.graphics.Brush.linearGradient(
                            colors = listOf(
                                Color(0x99, 0xCC, 0xFF).copy(alpha = 0.2f),  // Light Blue
                                Color(0xFF, 0xB2, 0xE6).copy(alpha = 0.2f),  // Light Pink
                                Color(0xCC, 0xB2, 0xFF).copy(alpha = 0.2f)   // Light Purple
                            ),
                            start = androidx.compose.ui.geometry.Offset(0f, 0f),
                            end = androidx.compose.ui.geometry.Offset(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY)
                        )
                    )
            )

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Progress bar
                ProgressBar(currentStep = currentStep, totalSteps = totalSteps)
                
                Spacer(modifier = Modifier.height(32.dp))
                
                // Logo and welcome
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // App Logo
                    Image(
                        painter = painterResource(id = R.drawable.protip365_logo),
                        contentDescription = "ProTip365 Logo",
                        modifier = Modifier
                            .size(100.dp)
                            .clip(RoundedCornerShape(20.dp))
                            .shadow(10.dp, RoundedCornerShape(20.dp))
                    )

                    // App Name
                    Text(
                        text = "ProTip365",
                        style = MaterialTheme.typography.displaySmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground
                    )

                    // Primary message
                    Text(
                        text = when (selectedLanguage) {
                            "fr" -> "Suivez vos pourboires"
                            "es" -> "Rastrea tus propinas"
                            else -> "Track Your Tips"
                        },
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onBackground
                    )

                    // Multi-line catchphrase
                    Text(
                        text = when (selectedLanguage) {
                            "fr" -> "Suivez chaque pourboire.\nGérez chaque quart.\nAccédez à vos données partout."
                            "es" -> "Rastrea cada propina.\nGestiona cada turno.\nAccede a tus datos en cualquier lugar."
                            else -> "Track Every Tip.\nManage Every Shift.\nAccess Your Data Anywhere."
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 32.dp)
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = when (selectedLanguage) {
                        "fr" -> "Bienvenue à ProTip365"
                        "es" -> "Bienvenido a ProTip365"
                        else -> "Welcome to ProTip365"
                    },
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Text(
                    text = when (currentStep) {
                        1 -> when (selectedLanguage) {
                            "fr" -> "Commençons par créer votre compte"
                            "es" -> "Empecemos creando tu cuenta"
                            else -> "Let's get started by creating your account"
                        }
                        2 -> when (selectedLanguage) {
                            "fr" -> "Sécurisez votre compte avec un mot de passe"
                            "es" -> "Asegura tu cuenta con una contraseña"
                            else -> "Secure your account with a password"
                        }
                        3 -> when (selectedLanguage) {
                            "fr" -> "Presque terminé! Personnalisons votre profil"
                            "es" -> "¡Casi listo! Personalicemos tu perfil"
                            else -> "Almost there! Let's personalize your profile"
                        }
                        else -> ""
                    },
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )
                
                Spacer(modifier = Modifier.height(32.dp))
                
                // Step content
                when (currentStep) {
                    1 -> EmailStep(
                        email = email,
                        onEmailChange = { email = it },
                        emailError = emailError,
                        isCheckingEmail = isCheckingEmail,
                        emailIsValid = emailIsValid,
                        emailAlreadyExists = emailAlreadyExists,
                        selectedLanguage = selectedLanguage,
                        onValidateEmail = {
                            // Email validation logic
                            emailError = ""
                            emailIsValid = false
                            emailAlreadyExists = false

                            if (!isEmailValid) {
                                emailError = when (selectedLanguage) {
                                    "fr" -> "Format de courriel invalide"
                                    "es" -> "Formato de correo inválido"
                                    else -> "Invalid email format"
                                }
                                return@EmailStep
                            }

                            isCheckingEmail = true
                            // Check if email exists using Supabase RPC function
                            scope.launch {
                                try {
                                    val emailExists = viewModel.checkEmailExists(email)
                                    if (emailExists) {
                                        emailError = when (selectedLanguage) {
                                            "fr" -> "Cette adresse courriel est déjà utilisée"
                                            "es" -> "Este correo electrónico ya está en uso"
                                            else -> "This email is already in use"
                                        }
                                        emailAlreadyExists = true
                                        emailIsValid = false
                                    } else {
                                        emailIsValid = true
                                        emailAlreadyExists = false
                                    }
                                } catch (e: Exception) {
                                    // On error, allow to proceed (fail open)
                                    emailIsValid = true
                                    emailAlreadyExists = false
                                }
                                isCheckingEmail = false
                            }
                        }
                    )
                    2 -> PasswordStep(
                        password = password,
                        onPasswordChange = { password = it },
                        confirmPassword = confirmPassword,
                        onConfirmPasswordChange = { confirmPassword = it },
                        passwordError = passwordError,
                        passwordVisible = passwordVisible,
                        confirmPasswordVisible = confirmPasswordVisible,
                        onPasswordVisibleChange = { passwordVisible = it },
                        onConfirmPasswordVisibleChange = { confirmPasswordVisible = it },
                        selectedLanguage = selectedLanguage
                    )
                    3 -> ProfileStep(
                        userName = userName,
                        onUserNameChange = { userName = it },
                        email = email,
                        password = password,
                        selectedLanguage = selectedLanguage
                    )
                }
                
                Spacer(modifier = Modifier.height(32.dp))
                
                // Navigation buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    if (currentStep > 1) {
                        OutlinedButton(
                            onClick = { currentStep-- },
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(
                                when (selectedLanguage) {
                                    "fr" -> "Retour"
                                    "es" -> "Atrás"
                                    else -> "Back"
                                }
                            )
                        }
                    } else {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                    
                    Button(
                        onClick = {
                            if (currentStep < totalSteps) {
                                currentStep++
                            } else {
                                // Create account
                                viewModel.updateEmail(email)
                                viewModel.updatePassword(password)
                                viewModel.updateName(userName)
                                viewModel.signUp()
                            }
                        },
                        modifier = Modifier.weight(1f),
                        enabled = isStepValid && !authState.isLoading
                    ) {
                        if (authState.isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        } else {
                            Text(
                                when (currentStep) {
                                    3 -> when (selectedLanguage) {
                                        "fr" -> "Créer le compte"
                                        "es" -> "Crear cuenta"
                                        else -> "Create Account"
                                    }
                                    else -> when (selectedLanguage) {
                                        "fr" -> "Suivant"
                                        "es" -> "Siguiente"
                                        else -> "Next"
                                    }
                                }
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(48.dp))
            }
        }
    }
    
    // Navigate on successful authentication
    LaunchedEffect(authState.isAuthenticated) {
        if (authState.isAuthenticated) {
            onComplete()
        }
    }
}

@Composable
fun ProgressBar(currentStep: Int, totalSteps: Int) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Step $currentStep of $totalSteps",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = "${((currentStep.toFloat() / totalSteps) * 100).toInt()}%",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            LinearProgressIndicator(
                progress = currentStep.toFloat() / totalSteps,
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.outline
            )
        }
    }
}

@Composable
fun EmailStep(
    email: String,
    onEmailChange: (String) -> Unit,
    emailError: String,
    isCheckingEmail: Boolean,
    emailIsValid: Boolean,
    emailAlreadyExists: Boolean,
    selectedLanguage: String,
    onValidateEmail: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        OutlinedTextField(
            value = email,
            onValueChange = { 
                onEmailChange(it)
                if (it.isNotBlank()) {
                    onValidateEmail()
                }
            },
            label = {
                Text(
                    when (selectedLanguage) {
                        "fr" -> "Adresse courriel"
                        "es" -> "Correo electrónico"
                        else -> "Email Address"
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
            isError = emailError.isNotEmpty(),
            supportingText = if (emailError.isNotEmpty()) {
                { Text(emailError, color = MaterialTheme.colorScheme.error) }
            } else null
        )
        
        if (isCheckingEmail) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    strokeWidth = 2.dp
                )
                Text(
                    when (selectedLanguage) {
                        "fr" -> "Vérification..."
                        "es" -> "Verificando..."
                        else -> "Checking..."
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        if (emailIsValid && !emailAlreadyExists) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = "Valid",
                    tint = Color.Green,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    when (selectedLanguage) {
                        "fr" -> "Cette adresse est disponible"
                        "es" -> "Esta dirección está disponible"
                        else -> "This email is available"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Green
                )
            }
        }
        
        // Email requirements
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.Info,
                        contentDescription = "Info",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        when (selectedLanguage) {
                            "fr" -> "Exigences du courriel"
                            "es" -> "Requisitos del correo"
                            else -> "Email Requirements"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    when (selectedLanguage) {
                        "fr" -> "• Doit être une adresse valide\n• Ne doit pas être déjà enregistrée"
                        "es" -> "• Debe ser una dirección válida\n• No debe estar ya registrada"
                        else -> "• Must be a valid email address\n• Must not be already registered"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun PasswordStep(
    password: String,
    onPasswordChange: (String) -> Unit,
    confirmPassword: String,
    onConfirmPasswordChange: (String) -> Unit,
    passwordError: String,
    passwordVisible: Boolean,
    confirmPasswordVisible: Boolean,
    onPasswordVisibleChange: (Boolean) -> Unit,
    onConfirmPasswordVisibleChange: (Boolean) -> Unit,
    selectedLanguage: String
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        OutlinedTextField(
            value = password,
            onValueChange = onPasswordChange,
            label = {
                Text(
                    when (selectedLanguage) {
                        "fr" -> "Créer un mot de passe"
                        "es" -> "Crear una contraseña"
                        else -> "Create a Password"
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
                imeAction = ImeAction.Next
            ),
            trailingIcon = {
                IconButton(onClick = { onPasswordVisibleChange(!passwordVisible) }) {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                        contentDescription = if (passwordVisible) "Hide password" else "Show password"
                    )
                }
            },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        
        OutlinedTextField(
            value = confirmPassword,
            onValueChange = onConfirmPasswordChange,
            label = {
                Text(
                    when (selectedLanguage) {
                        "fr" -> "Confirmer le mot de passe"
                        "es" -> "Confirmar contraseña"
                        else -> "Confirm Password"
                    }
                )
            },
            visualTransformation = if (confirmPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            trailingIcon = {
                IconButton(onClick = { onConfirmPasswordVisibleChange(!confirmPasswordVisible) }) {
                    Icon(
                        imageVector = if (confirmPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                        contentDescription = if (confirmPasswordVisible) "Hide password" else "Show password"
                    )
                }
            },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            isError = confirmPassword.isNotBlank() && password != confirmPassword,
            supportingText = if (confirmPassword.isNotBlank() && password != confirmPassword) {
                { Text("Passwords don't match", color = MaterialTheme.colorScheme.error) }
            } else null
        )
        
        if (password.isNotEmpty() && confirmPassword.isNotEmpty() && password == confirmPassword) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = "Valid",
                    tint = Color.Green,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    when (selectedLanguage) {
                        "fr" -> "Les mots de passe correspondent"
                        "es" -> "Las contraseñas coinciden"
                        else -> "Passwords match"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Green
                )
            }
        }
        
        // Password requirements
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.Info,
                        contentDescription = "Info",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        when (selectedLanguage) {
                            "fr" -> "Exigences du mot de passe"
                            "es" -> "Requisitos de la contraseña"
                            else -> "Password Requirements"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = if (password.length >= 6) Icons.Default.CheckCircle else Icons.Default.Circle,
                        contentDescription = "Requirement",
                        tint = if (password.length >= 6) Color.Green else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        when (selectedLanguage) {
                            "fr" -> "Au moins 6 caractères"
                            "es" -> "Al menos 6 caracteres"
                            else -> "At least 6 characters"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = if (password == confirmPassword && password.isNotEmpty()) Icons.Default.CheckCircle else Icons.Default.Circle,
                        contentDescription = "Requirement",
                        tint = if (password == confirmPassword && password.isNotEmpty()) Color.Green else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        when (selectedLanguage) {
                            "fr" -> "Les deux mots de passe doivent correspondre"
                            "es" -> "Ambas contraseñas deben coincidir"
                            else -> "Both passwords must match"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
fun ProfileStep(
    userName: String,
    onUserNameChange: (String) -> Unit,
    email: String,
    password: String,
    selectedLanguage: String
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        OutlinedTextField(
            value = userName,
            onValueChange = onUserNameChange,
            label = {
                Text(
                    when (selectedLanguage) {
                        "fr" -> "Votre nom"
                        "es" -> "Tu nombre"
                        else -> "Your Name"
                    }
                )
            },
            leadingIcon = { 
                Icon(
                    Icons.Default.Person,
                    contentDescription = "Name",
                    tint = MaterialTheme.colorScheme.primary
                ) 
            },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Text,
                imeAction = ImeAction.Done
            ),
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        
        // Account summary
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = "Summary",
                        tint = Color.Green,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        when (selectedLanguage) {
                            "fr" -> "Résumé du compte"
                            "es" -> "Resumen de la cuenta"
                            else -> "Account Summary"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = Color.Green
                    )
                }
                
                Spacer(modifier = Modifier.height(12.dp))
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.Email,
                        contentDescription = "Email",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        email,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.Lock,
                        contentDescription = "Password",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        String(CharArray(password.length) { '•' }),
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                
                if (userName.isNotEmpty()) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            Icons.Default.Person,
                            contentDescription = "Name",
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            userName,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
        }
    }
}




