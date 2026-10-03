package com.protip365.app.presentation.employers

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Employer
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.EmployerRepository
import com.protip365.app.domain.repository.SubscriptionRepository
import com.protip365.app.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class EmployersViewModel @Inject constructor(
    private val employerRepository: EmployerRepository,
    private val authRepository: AuthRepository,
    private val subscriptionRepository: SubscriptionRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _state = MutableStateFlow(EmployersState())
    val state: StateFlow<EmployersState> = _state.asStateFlow()

    private var currentUserId: String? = null

    init {
        loadEmployers()
    }

    private fun loadEmployers() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true)
            
            try {
                val user = authRepository.getCurrentUser()
                user?.let {
                    currentUserId = it.userId

                    // Check subscription status
                    val subscription = subscriptionRepository.getCurrentSubscription(it.userId)
                    val hasFullAccess = subscription?.status == "active" && subscription.productId?.contains("full") == true

                    // Load employers
                    val employers = employerRepository.getEmployers(it.userId)
                
                _state.value = _state.value.copy(
                    employers = employers,
                    defaultEmployerId = it.defaultEmployerId,
                    hasFullAccess = hasFullAccess,
                    isLoading = false
                )
                } ?: run {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = "User not logged in"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = "Error loading employers: ${e.message}"
                )
            }
        }
    }

    fun addEmployer(name: String, hourlyRate: Double) {
        viewModelScope.launch {
            val userId = currentUserId ?: return@launch
            
            // Check if user can add more employers (removed upgrade requirement - all users can add multiple employers)
            // Note: This check is disabled as we only have one subscription tier
            
            val employer = Employer(
                id = UUID.randomUUID().toString(),
                userId = userId,
                name = name,
                hourlyRate = hourlyRate,
                active = true
            )
            
            employerRepository.createEmployer(employer).fold(
                onSuccess = {
                    loadEmployers() // Reload to get updated list
                },
                onFailure = { exception ->
                    _state.value = _state.value.copy(
                        error = exception.message ?: "Failed to add employer"
                    )
                }
            )
        }
    }

    fun updateEmployer(employerId: String, name: String, hourlyRate: Double) {
        viewModelScope.launch {
            val employer = _state.value.employers.find { it.id == employerId } ?: return@launch
            val updatedEmployer = employer.copy(
                name = name,
                hourlyRate = hourlyRate
            )
            
            employerRepository.updateEmployer(updatedEmployer).fold(
                onSuccess = {
                    loadEmployers()
                },
                onFailure = { exception ->
                    _state.value = _state.value.copy(
                        error = exception.message ?: "Failed to update employer"
                    )
                }
            )
        }
    }

    fun loadEmployer(employerId: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true)
            
            try {
                val employer = employerRepository.getEmployer(employerId)
                if (employer != null) {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        selectedEmployer = employer
                    )
                } else {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = "Employer not found"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load employer"
                )
            }
        }
    }

    fun setDefaultEmployer(employerId: String) {
        viewModelScope.launch {
            val userId = currentUserId ?: return@launch
            
            // Update the default employer through UserProfile repository
            val metadata = mapOf("default_employer_id" to employerId)
            userRepository.updateUserMetadata(metadata).fold(
                onSuccess = {
                    _state.value = _state.value.copy(
                        defaultEmployerId = employerId
                    )
                },
                onFailure = { error ->
                    // Handle error - could show a toast or error message
                    println("Failed to set default employer: ${error.message}")
                }
            )
        }
    }

    fun toggleEmployerActive(employerId: String) {
        viewModelScope.launch {
            val employer = _state.value.employers.find { it.id == employerId } ?: return@launch
            val updatedEmployer = employer.copy(active = !employer.active)
            
            employerRepository.updateEmployer(updatedEmployer).fold(
                onSuccess = {
                    loadEmployers()
                },
                onFailure = { exception ->
                    _state.value = _state.value.copy(
                        error = exception.message ?: "Failed to update employer status"
                    )
                }
            )
        }
    }

    fun deleteEmployer(employerId: String) {
        viewModelScope.launch {
            // Can't delete default employer
            if (employerId == _state.value.defaultEmployerId) {
                _state.value = _state.value.copy(
                    error = "Cannot delete default employer. Set another employer as default first."
                )
                return@launch
            }
            
            employerRepository.deleteEmployer(employerId).fold(
                onSuccess = {
                    loadEmployers()
                },
                onFailure = { exception ->
                    _state.value = _state.value.copy(
                        error = exception.message ?: "Failed to delete employer"
                    )
                }
            )
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}

data class EmployersState(
    val employers: List<Employer> = emptyList(),
    val defaultEmployerId: String? = null,
    val selectedEmployer: Employer? = null,
    val hasFullAccess: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)