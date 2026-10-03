package com.protip365.app.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.UserRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.gotrue.auth
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository,
    private val supabaseClient: SupabaseClient
) : ViewModel() {

    private val _state = MutableStateFlow(ProfileState())
    val state: StateFlow<ProfileState> = _state.asStateFlow()

    init {
        loadProfile()
    }

    private fun loadProfile() {
        viewModelScope.launch {
            try {
                // Get user profile from users_profile table (where name and other data is stored)
                val userProfile = userRepository.getCurrentUser().first()
                
                // Get email from Supabase auth
                val authUser = supabaseClient.auth.currentUserOrNull()
                val email = authUser?.email ?: ""
                
                userProfile?.let { profile ->
                    val dateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.US)
                    val memberSince = try {
                        val date = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).parse(profile.createdAt ?: "")
                        dateFormat.format(date ?: Date())
                    } catch (e: Exception) {
                        "Unknown"
                    }

                    _state.value = ProfileState(
                        userId = profile.userId,
                        name = profile.name ?: "",
                        email = email,
                        phone = "", // Phone not stored in profile
                        memberSince = memberSince,
                        isLoading = false
                    )
                    
                    println("✅ Profile loaded: name='${profile.name}', email='$email'")
                } ?: run {
                    // No profile found, create default state
                    _state.value = ProfileState(
                        userId = authUser?.id ?: "",
                        name = "",
                        email = email,
                        phone = "",
                        memberSince = "Unknown",
                        isLoading = false
                    )
                    println("⚠️ No user profile found, using auth data only")
                }
            } catch (e: Exception) {
                println("❌ Failed to load profile: ${e.message}")
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = "Failed to load profile: ${e.message}"
                )
            }
        }
    }

    fun updateProfile(name: String, email: String, phone: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            
            try {
                // Update name in users_profile table using the map-based update method
                val updateResult = userRepository.updateUserProfile(
                    mapOf("name" to name)
                )
                
                if (updateResult.isSuccess) {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        updateSuccess = true,
                        name = name // Update local state
                    )
                    println("✅ Profile updated successfully: name='$name'")
                } else {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = updateResult.exceptionOrNull()?.message ?: "Failed to update profile"
                    )
                    println("❌ Failed to update profile: ${updateResult.exceptionOrNull()?.message}")
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = "Failed to update profile: ${e.message}"
                )
                println("❌ Exception updating profile: ${e.message}")
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