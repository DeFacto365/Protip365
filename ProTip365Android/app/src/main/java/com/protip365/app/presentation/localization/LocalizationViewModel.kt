package com.protip365.app.presentation.localization

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class LocalizationViewModel @Inject constructor(
    val localizationManager: LocalizationManager
) : ViewModel() {
    
    private val _state = MutableStateFlow(localizationManager.state.value)
    val state: StateFlow<LocalizationState> = _state.asStateFlow()
    
    init {
        // Observe localization manager state
        _state.value = localizationManager.state.value
    }
    
    fun setLanguage(language: SupportedLanguage) {
        localizationManager.setLanguage(language)
        _state.value = localizationManager.state.value
    }
    
    fun getString(key: String, vararg args: Any): String {
        return localizationManager.getString(key, *args)
    }
}




