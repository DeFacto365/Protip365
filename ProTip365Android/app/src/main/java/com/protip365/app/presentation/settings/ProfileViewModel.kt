package com.protip365.app.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _state = MutableStateFlow(ProfileState())
    val state: StateFlow<ProfileState> = _state.asStateFlow()

    init {
        loadProfile()
    }

    private fun loadProfile() {
        viewModelScope.launch {
            val user = authRepository.getCurrentUser()
            user?.let {
                val dateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.US)
                val memberSince = try {
                    val date = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).parse(it.createdAt)
                    dateFormat.format(date ?: Date())
                } catch (e: Exception) {
                    "Unknown"
                }

                _state.value = ProfileState(
                    userId = it.userId,
                    name = it.name ?: "",
                    email = "", // Email not stored in profile
                    phone = "", // Phone not stored in profile
                    memberSince = memberSince,
                    isLoading = false
                )
            }
        }
    }

    fun updateProfile(name: String, email: String, phone: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            
            val user = authRepository.getCurrentUser()
            user?.let {
                val updatedUser = it.copy(
                    name = name
                    // phone not stored in profile
                )
                
                userRepository.updateUserProfile(updatedUser).fold(
                    onSuccess = {
                        _state.value = _state.value.copy(
                            isLoading = false,
                            updateSuccess = true
                        )
                    },
                    onFailure = { exception ->
                        _state.value = _state.value.copy(
                            isLoading = false,
                            error = exception.message ?: "Failed to update profile"
                        )
                    }
                )
            }
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}

data class ProfileState(
    val userId: String = "",
    val name: String = "",
    val email: String = "",
    val phone: String = "",
    val memberSince: String = "",
    val isLoading: Boolean = true,
    val updateSuccess: Boolean = false,
    val error: String? = null
)