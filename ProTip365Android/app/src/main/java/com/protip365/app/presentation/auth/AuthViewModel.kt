package com.protip365.app.presentation.auth

import android.util.Patterns
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.UserRepository
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
    private val userRepository: UserRepository
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
                    _state.value = _state.value.copy(
                        isAuthenticated = true,
                        isNewUser = user?.metadata?.get("is_new_user") as? Boolean ?: false,
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
                    generalError = "Failed to check authentication status"
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
                "Passwords do not match"
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
                        _state.value = _state.value.copy(
                            isAuthenticated = true,
                            isNewUser = false,
                            isLoading = false,
                            loadingMessage = null,
                            successMessage = "Successfully signed in!"
                        )
                    }
                    .onFailure { exception ->
                        val errorMessage = when {
                            exception.message?.contains("Invalid login") == true ->
                                "Invalid email or password"
                            exception.message?.contains("Email not confirmed") == true ->
                                "Please verify your email before signing in"
                            exception.message?.contains("Too many requests") == true ->
                                "Too many attempts. Please wait a moment and try again"
                            exception.message?.contains("Network") == true ->
                                "Network error. Please check your connection"
                            else -> exception.message ?: "Sign in failed"
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
                    generalError = "An unexpected error occurred"
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
                    .onSuccess { user ->
                        // Mark user as new for onboarding
                        userRepository.updateUserMetadata(mapOf("is_new_user" to true))

                        _state.value = _state.value.copy(
                            successMessage = "Account created! Please check your email to verify your account.",
                            isLoading = false,
                            loadingMessage = null,
                            authMode = AuthMode.SIGN_IN // Switch to sign in mode
                        )

                        // Clear success message after delay
                        delay(5000)
                        _state.value = _state.value.copy(successMessage = null)
                    }
                    .onFailure { exception ->
                        val errorMessage = when {
                            exception.message?.contains("already registered") == true ->
                                "An account with this email already exists"
                            exception.message?.contains("weak password") == true ->
                                "Password is too weak. Please use at least 6 characters"
                            exception.message?.contains("invalid email") == true ->
                                "Please enter a valid email address"
                            exception.message?.contains("Network") == true ->
                                "Network error. Please check your connection"
                            else -> exception.message ?: "Sign up failed"
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
                    generalError = "An unexpected error occurred"
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
                generalError = "Please enter a valid email address"
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
                    generalError = "An unexpected error occurred"
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
                "Passwords do not match"
            } else if (_state.value.confirmPassword.isEmpty()) {
                "Please confirm your password"
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
            email.isBlank() -> "Email is required"
            !Patterns.EMAIL_ADDRESS.matcher(email).matches() -> "Invalid email format"
            else -> null
        }
    }

    private fun validatePassword(password: String): String? {
        return when {
            password.isBlank() -> "Password is required"
            password.length < 6 -> "Password must be at least 6 characters"
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
    val isNewUser: Boolean = false
)