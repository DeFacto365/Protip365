package com.protip365.app.presentation.main

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {
    
    private val _useMultipleEmployers = MutableStateFlow(false)
    val useMultipleEmployers: StateFlow<Boolean> = _useMultipleEmployers.asStateFlow()
    
    init {
        loadUserPreferences()
    }
    
    private fun loadUserPreferences() {
        viewModelScope.launch {
            try {
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
