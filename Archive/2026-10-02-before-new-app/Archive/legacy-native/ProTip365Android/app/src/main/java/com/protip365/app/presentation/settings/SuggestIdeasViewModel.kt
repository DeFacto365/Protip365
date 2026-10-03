package com.protip365.app.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class SuggestIdeasViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(SuggestIdeasUiState())
    val uiState: StateFlow<SuggestIdeasUiState> = _uiState.asStateFlow()

    fun updateEmail(email: String) {
        _uiState.value = _uiState.value.copy(email = email)
    }

    fun updateSuggestion(suggestion: String) {
        _uiState.value = _uiState.value.copy(suggestion = suggestion)
    }
}

data class SuggestIdeasUiState(
    val email: String = "",
    val suggestion: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)
