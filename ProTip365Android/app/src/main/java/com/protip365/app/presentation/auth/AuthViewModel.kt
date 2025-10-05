package com.protip365.app.presentation.auth

import android.util.Patterns
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.UserRepository
import com.protip365.app.presentation.localization.LocalizationManager
import com.protip365.app.R
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository,
    private val localizationManager: LocalizationManager
) : ViewModel() {

    private val _state = MutableStateFlow(AuthUiState())
    val state: StateFlow<AuthUiState> = _state.asStateFlow()

    init {
        checkAuthStatus()
    }

    private fun checkAuthStatus() {
        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = true,
                loadingMessage = "Checking authentication..."
            )

            try {
                val isLoggedIn = authRepository.isLoggedIn()
                if (isLoggedIn) {
                    val user = authRepository.getCurrentUser()
                    // ✅ NEW: Check onboarding_completed flag from database
                    val profile = user?.userId?.let { userRepository.getUserProfile(it) }
                    val needsOnboarding = !(profile?.onboardingCompleted ?: false)

                    _state.value = _state.value.copy(
                        isAuthenticated = true,
                        isNewUser = needsOnboarding, // true if onboarding not completed
                        isLoading = false,
                        loadingMessage = null
                    )
                } else {
                    _state.value = _state.value.copy(
                        isAuthenticated = false,
                        isLoading = false,
                        loadingMessage = null
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    loadingMessage = null,
                    generalError = localizationManager.getString(R.string.error_load_failed)
                )
            }
        }
    }

    fun setAuthMode(mode: AuthMode) {
        _state.value = _state.value.copy(
            authMode = mode,
            // Clear errors when switching modes
            emailError = null,
            passwordError = null,
            confirmPasswordError = null,
            generalError = null
        )
    }

    fun setEmail(email: String) {
        _state.value = _state.value.copy(
            email = email,
            emailError = validateEmail(email)
        )
    }

    fun setPassword(password: String) {
        _state.value = _state.value.copy(
            password = password,
            passwordError = validatePassword(password)
        )
    }

    fun setConfirmPassword(confirmPassword: String) {
        _state.value = _state.value.copy(
            confirmPassword = confirmPassword,
            confirmPasswordError = if (confirmPassword != _state.value.password) {
                localizationManager.getString(R.string.passwords_dont_match)
            } else null
        )
    }

    fun signIn() {
        if (!validateFields()) return

        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = true,
                loadingMessage = "Signing in...",
                generalError = null
            )

            try {
                authRepository.signIn(_state.value.email, _state.value.password)
                    .onSuccess { user ->
                        // ✅ NEW: Check onboarding_completed flag from database
                        val profile = userRepository.getUserProfile(user.userId)
                        val needsOnboarding = !(profile?.onboardingCompleted ?: false)

                        _state.value = _state.value.copy(
                            isAuthenticated = true,
                            isNewUser = needsOnboarding, // true if onboarding not completed
                            isLoading = false,
                            loadingMessage = null,
                            successMessage = "Successfully signed in!"
                        )
                    }
                    .onFailure { exception ->
                        val errorMessage = when {
                            exception.message?.contains("Invalid login") == true ->
                                localizationManager.getString(R.string.invalid_credentials)
                            exception.message?.contains("Email not confirmed") == true ->
                                "Please verify your email before signing in"
                            exception.message?.contains("Too many requests") == true ->
                                "Too many attempts. Please wait a moment and try again"
                            exception.message?.contains("Network") == true ->
                                localizationManager.getString(R.string.network_error)
                            else -> exception.message ?: localizationManager.getString(R.string.error_login_failed)
                        }

                        _state.value = _state.value.copy(
                            isLoading = false,
                            loadingMessage = null,
                            generalError = errorMessage
                        )
                    }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    loadingMessage = null,
                    generalError = localizationManager.getString(R.string.unexpected_error)
                )
            }
        }
    }

    fun signUp() {
        if (!validateFields()) return

        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = true,
                loadingMessage = "Creating account...",
                generalError = null
            )

            try {
                authRepository.signUp(_state.value.email, _state.value.password)
                    .onSuccess { userProfile ->
                        // Save the name to user profile if provided
                        if (_state.value.name.isNotBlank()) {
                            val updateResult = userRepository.updateUserProfile(mapOf("name" to _state.value.name))
                            if (updateResult.isFailure) {
                                println("Warning: Failed to save name to profile: ${updateResult.exceptionOrNull()?.message}")
                            }
                        }

                        // Mark user as new for onboarding
                        userRepository.updateUserMetadata(mapOf("is_new_user" to true))

                        _state.value = _state.value.copy(
                            isAuthenticated = true,  // Set authenticated to true
                            isNewUser = true,  // Mark as new user for onboarding
                            successMessage = "Account created successfully!",
                            isLoading = false,
                            loadingMessage = null
                        )

                        // Clear success message after delay
                        delay(2000)
                        _state.value = _state.value.copy(successMessage = null)
                    }
                    .onFailure { exception ->
                        val errorMessage = when {
                            exception.message?.contains("already registered") == true ->
                                localizationManager.getString(R.string.email_already_exists)
                            exception.message?.contains("weak password") == true ->
                                localizationManager.getString(R.string.weak_password)
                            exception.message?.contains("invalid email") == true ->
                                localizationManager.getString(R.string.error_invalid_email)
                            exception.message?.contains("Network") == true ->
                                localizationManager.getString(R.string.network_error)
                            else -> exception.message ?: localizationManager.getString(R.string.error_signup_failed)
                        }

                        _state.value = _state.value.copy(
                            isLoading = false,
                            loadingMessage = null,
                            generalError = errorMessage
                        )
                    }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    loadingMessage = null,
                    generalError = localizationManager.getString(R.string.unexpected_error)
                )
            }
        }
    }

    fun signInWithGoogle() {
        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = true,
                loadingMessage = "Signing in with Google...",
                generalError = null
            )

            try {
                authRepository.signInWithGoogle()
                    .onSuccess {
                        _state.value = _state.value.copy(
                            isAuthenticated = true,
                            isLoading = false,
                            loadingMessage = null
                        )
                    }
                    .onFailure { exception ->
                        _state.value = _state.value.copy(
                            isLoading = false,
                            loadingMessage = null,
                            generalError = exception.message ?: "Google sign in failed"
                        )
                    }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    loadingMessage = null,
                    generalError = "Google sign in not available"
                )
            }
        }
    }

    fun updateEmail(email: String) {
        _state.value = _state.value.copy(
            email = email,
            emailError = null
        )
    }

    // Validate email availability for signup
    fun validateEmailAvailability(email: String) {
        // Only check during signup mode
        if (_state.value.authMode != AuthMode.SIGN_UP) return

        // First check format
        if (email.isBlank() || !Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            return // Don't check availability if format is invalid
        }

        viewModelScope.launch {
            _state.value = _state.value.copy(isCheckingEmail = true)

            try {
                val emailExists = authRepository.checkEmailExists(email)
                _state.value = _state.value.copy(
                    isCheckingEmail = false,
                    emailError = if (emailExists) {
                        "This email is already in use"
                    } else null
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isCheckingEmail = false,
                    emailError = null // On error, allow to proceed (fail open)
                )
            }
        }
    }

    // Public function for checking email exists (for WelcomeSignUpScreen)
    suspend fun checkEmailExists(email: String): Boolean {
        return try {
            authRepository.checkEmailExists(email)
        } catch (e: Exception) {
            false // On error, allow to proceed (fail open)
        }
    }

    fun updatePassword(password: String) {
        _state.value = _state.value.copy(
            password = password,
            passwordError = null
        )
    }

    fun updateConfirmPassword(confirmPassword: String) {
        _state.value = _state.value.copy(
            confirmPassword = confirmPassword,
            confirmPasswordError = null
        )
    }

    fun updateName(name: String) {
        _state.value = _state.value.copy(
            name = name,
            nameError = null
        )
    }

    fun signInWithApple() {
        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = true,
                loadingMessage = "Signing in with Apple...",
                generalError = null
            )

            try {
                authRepository.signInWithApple()
                    .onSuccess {
                        _state.value = _state.value.copy(
                            isAuthenticated = true,
                            isLoading = false,
                            loadingMessage = null
                        )
                    }
                    .onFailure { exception ->
                        _state.value = _state.value.copy(
                            isLoading = false,
                            loadingMessage = null,
                            generalError = exception.message ?: "Apple sign in failed"
                        )
                    }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    loadingMessage = null,
                    generalError = "Apple sign in not available"
                )
            }
        }
    }

    fun resetPassword(email: String) {
        if (email.isBlank() || !Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            _state.value = _state.value.copy(
                generalError = localizationManager.getString(R.string.error_invalid_email)
            )
            return
        }

        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = true,
                loadingMessage = "Sending password reset email...",
                generalError = null
            )

            try {
                authRepository.resetPassword(email)
                    .onSuccess {
                        _state.value = _state.value.copy(
                            isLoading = false,
                            loadingMessage = null,
                            successMessage = "Password reset email sent! Please check your inbox."
                        )

                        // Clear success message after delay
                        delay(5000)
                        _state.value = _state.value.copy(successMessage = null)
                    }
                    .onFailure { exception ->
                        _state.value = _state.value.copy(
                            isLoading = false,
                            loadingMessage = null,
                            generalError = exception.message ?: "Failed to send password reset email"
                        )
                    }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    loadingMessage = null,
                    generalError = localizationManager.getString(R.string.unexpected_error)
                )
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = true,
                loadingMessage = "Signing out..."
            )

            authRepository.signOut()

            _state.value = AuthUiState() // Reset to initial state
        }
    }

    fun clearErrors() {
        _state.value = _state.value.copy(
            emailError = null,
            passwordError = null,
            confirmPasswordError = null,
            generalError = null
        )
    }

    private fun validateFields(): Boolean {
        val emailError = validateEmail(_state.value.email)
        val passwordError = validatePassword(_state.value.password)
        val confirmPasswordError = if (_state.value.authMode == AuthMode.SIGN_UP) {
            if (_state.value.confirmPassword != _state.value.password) {
                localizationManager.getString(R.string.passwords_dont_match)
            } else if (_state.value.confirmPassword.isEmpty()) {
                localizationManager.getString(R.string.confirm_password_hint)
            } else null
        } else null

        _state.value = _state.value.copy(
            emailError = emailError,
            passwordError = passwordError,
            confirmPasswordError = confirmPasswordError
        )

        return emailError == null && passwordError == null && confirmPasswordError == null
    }

    private fun validateEmail(email: String): String? {
        return when {
            email.isBlank() -> localizationManager.getString(R.string.error_required_field)
            !Patterns.EMAIL_ADDRESS.matcher(email).matches() -> localizationManager.getString(R.string.error_invalid_email)
            else -> null
        }
    }

    private fun validatePassword(password: String): String? {
        return when {
            password.isBlank() -> localizationManager.getString(R.string.error_required_field)
            password.length < 6 -> localizationManager.getString(R.string.error_password_too_short)
            _state.value.authMode == AuthMode.SIGN_UP && !password.any { it.isDigit() } ->
                "Password must contain at least one number"
            _state.value.authMode == AuthMode.SIGN_UP && !password.any { it.isLetter() } ->
                "Password must contain at least one letter"
            else -> null
        }
    }
}

data class AuthUiState(
    val authMode: AuthMode = AuthMode.SIGN_IN,
    val email: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val name: String = "",
    val emailError: String? = null,
    val passwordError: String? = null,
    val confirmPasswordError: String? = null,
    val nameError: String? = null,
    val generalError: String? = null,
    val successMessage: String? = null,
    val isLoading: Boolean = false,
    val loadingMessage: String? = null,
    val isAuthenticated: Boolean = false,
    val isNewUser: Boolean = false,
    val isCheckingEmail: Boolean = false
)