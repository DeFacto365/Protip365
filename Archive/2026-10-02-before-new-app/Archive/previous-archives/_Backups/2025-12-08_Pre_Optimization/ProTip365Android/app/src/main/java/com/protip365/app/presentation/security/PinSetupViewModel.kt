package com.protip365.app.presentation.security

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PINSetupState(
    val step: PINSetupStep = PINSetupStep.ENTER_PIN,
    val newPIN: String = "",
    val confirmPIN: String = "",
    val error: String? = null
)

@HiltViewModel
class PINSetupViewModel @Inject constructor(
    private val securityManager: SecurityManager
) : ViewModel() {
    
    private val _state = MutableStateFlow(PINSetupState())
    val state: StateFlow<PINSetupState> = _state.asStateFlow()
    
    fun updateNewPIN(pin: String) {
        _state.value = _state.value.copy(
            newPIN = pin,
            error = null
        )
    }
    
    fun updateConfirmPIN(pin: String) {
        _state.value = _state.value.copy(
            confirmPIN = pin,
            error = null
        )
    }
    
    fun proceedToConfirm() {
        if (_state.value.newPIN.length == 4) {
            _state.value = _state.value.copy(
                step = PINSetupStep.CONFIRM_PIN,
                error = null
            )
        } else {
            _state.value = _state.value.copy(
                error = "PIN must be 4 digits"
            )
        }
    }
    
    fun confirmPIN(): Boolean {
        val currentState = _state.value
        
        return if (currentState.newPIN == currentState.confirmPIN) {
            val success = securityManager.setPIN(currentState.newPIN)
            if (!success) {
                _state.value = _state.value.copy(
                    error = "Failed to set PIN. Please try again."
                )
            }
            success
        } else {
            _state.value = _state.value.copy(
                error = "PINs do not match"
            )
            false
        }
    }
    
    fun reset() {
        _state.value = PINSetupState()
    }
}