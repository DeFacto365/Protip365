package com.protip365.app.presentation.main

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val preferencesManager: PreferencesManager
) : ViewModel() {

    private val _useMultipleEmployers = MutableStateFlow(false)
    val useMultipleEmployers: StateFlow<Boolean> = _useMultipleEmployers.asStateFlow()

    init {
        loadUserPreferences()
        observePreferences()
    }

    private fun loadUserPreferences() {
        viewModelScope.launch {
            try {
                // First try to get from local preferences (immediate)
                val settings = preferencesManager.getSettings()
                settings?.let {
                    _useMultipleEmployers.value = it.useMultipleEmployers
                }

                // Then try to get from user profile (network)
                val userProfile = userRepository.getUserProfile("dummy_user_id")
                userProfile?.let { profile ->
                    _useMultipleEmployers.value = profile.useMultipleEmployers
                }
            } catch (e: Exception) {
                // Handle error - default to false
                _useMultipleEmployers.value = false
            }
        }
    }

    private fun observePreferences() {
        // Observe changes to preferences
        viewModelScope.launch {
            preferencesManager.observeSettings().collect { settings ->
                settings?.let {
                    _useMultipleEmployers.value = it.useMultipleEmployers
                }
            }
        }
    }
    
    fun updateMultipleEmployersSetting(enabled: Boolean) {
        _useMultipleEmployers.value = enabled
        viewModelScope.launch {
            try {
                // Update the setting in the repository
                // This would typically update the user profile in Supabase
            } catch (e: Exception) {
                // Handle error
            }
        }
    }
    
    fun getVisibleNavItems(): List<BottomNavItem> {
        return if (_useMultipleEmployers.value) {
            bottomNavItems
        } else {
            bottomNavItems.filter { it.route != "employers" }
        }
    }
}
