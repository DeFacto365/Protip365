package com.protip365.app.presentation.security

import androidx.lifecycle.ViewModel
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LockScreenState(
    val enteredPIN: String = "",
    val currentSecurityType: SecurityType = SecurityType.NONE,
    val isBiometricAvailable: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class LockScreenViewModel @Inject constructor(
    private val securityManager: SecurityManager
) : ViewModel() {
    
    private val _state = MutableStateFlow(LockScreenState())
    val state: StateFlow<LockScreenState> = _state.asStateFlow()
    
    init {
        // Observe security manager state
        viewModelScope.launch {
            securityManager.state.collect { securityState ->
                _state.value = _state.value.copy(
                    currentSecurityType = securityState.currentSecurityType,
                    isBiometricAvailable = securityState.isBiometricAvailable,
                    error = securityState.error
                )
            }
        }
    }
    
    fun updatePIN(pin: String) {
        _state.value = _state.value.copy(enteredPIN = pin)
        
        // Auto-verify when PIN is 4 digits
        if (pin.length == 4) {
            verifyPIN(pin)
        }
    }
    
    private fun verifyPIN(pin: String) {
        val isValid = securityManager.verifyPIN(pin)
        if (!isValid) {
            _state.value = _state.value.copy(
                enteredPIN = "",
                error = "Invalid PIN"
            )
        }
    }
    
    suspend fun authenticateWithBiometric(activity: FragmentActivity): Boolean {
        return securityManager.authenticateWithBiometric(activity)
    }
    
    fun clearError() {
        _state.value = _state.value.copy(error = null)
        securityManager.clearError()
    }
}