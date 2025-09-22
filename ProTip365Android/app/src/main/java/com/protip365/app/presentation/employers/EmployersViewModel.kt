package com.protip365.app.presentation.employers

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Employer
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.EmployerRepository
import com.protip365.app.domain.repository.SubscriptionRepository
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
    private val subscriptionRepository: SubscriptionRepository
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
        }
    }

    fun addEmployer(name: String, hourlyRate: Double) {
        viewModelScope.launch {
            val userId = currentUserId ?: return@launch
            
            // Check if user can add more employers
            if (!_state.value.hasFullAccess && _state.value.employers.size >= 1) {
                _state.value = _state.value.copy(
                    error = "Upgrade to Full Access for multiple employers"
                )
                return@launch
            }
            
            val employer = Employer(
                id = UUID.randomUUID().toString(),
                userId = userId,
                name = name,
                hourlyRate = hourlyRate,
                defaultHourlyRate = hourlyRate,
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
                hourlyRate = hourlyRate,
                defaultHourlyRate = hourlyRate
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

    fun setDefaultEmployer(employerId: String) {
        viewModelScope.launch {
            val userId = currentUserId ?: return@launch
            
            // TODO: Implement setDefaultEmployer through UserProfile repository
            // For now, just update the local state
            _state.value = _state.value.copy(
                defaultEmployerId = employerId
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
    val hasFullAccess: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)