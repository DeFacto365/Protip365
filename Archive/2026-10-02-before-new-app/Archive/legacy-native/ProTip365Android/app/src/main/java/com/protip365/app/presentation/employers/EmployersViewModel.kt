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

    fun refreshEmployers() {
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
                
                    // iOS conformance: Load shift and entry counts (lines 186-277)
                    val shiftCounts = loadShiftCounts(it.userId, employers)
                    val entryCounts = loadEntryCounts(it.userId, employers)

                _state.value = _state.value.copy(
                    employers = employers,
                    defaultEmployerId = it.defaultEmployerId,
                    hasFullAccess = hasFullAccess,
                    employerShiftCounts = shiftCounts,
                    employerEntryCounts = entryCounts,
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

    /**
     * Load shift counts for each employer
     * Matches iOS loadShiftCounts (EmployersView.swift lines 197-222)
     */
    private suspend fun loadShiftCounts(userId: String, employers: List<Employer>): Map<String, Int> {
        val counts = mutableMapOf<String, Int>()
        
        try {
            for (employer in employers) {
                val shiftCount = employerRepository.getShiftCountForEmployer(userId, employer.id)
                counts[employer.id] = shiftCount
                println("DEBUG: Employer ${employer.name} has $shiftCount shifts")
            }
        } catch (e: Exception) {
            println("Error loading shift counts: ${e.message}")
        }
        
        return counts
    }

    /**
     * Load entry counts for each employer  
     * Matches iOS loadEntryCounts (EmployersView.swift lines 224-277)
     */
    private suspend fun loadEntryCounts(userId: String, employers: List<Employer>): Map<String, Int> {
        val counts = mutableMapOf<String, Int>()
        
        try {
            for (employer in employers) {
                val entryCount = employerRepository.getEntryCountForEmployer(userId, employer.id)
                counts[employer.id] = entryCount
                println("DEBUG: Employer ${employer.name} has $entryCount entries")
            }
        } catch (e: Exception) {
            println("Error loading entry counts: ${e.message}")
        }
        
        return counts
    }

    /**
     * Request employer deletion (iOS pattern with data protection)
     * Matches iOS handleEmployerDeletion (EmployersView.swift lines 397-407)
     */
    fun requestDeleteEmployer(employerId: String) {
        viewModelScope.launch {
            val employer = _state.value.employers.find { it.id == employerId } ?: return@launch
            
            // Can't delete default employer
            if (employerId == _state.value.defaultEmployerId) {
                _state.value = _state.value.copy(
                    error = "Cannot delete default employer. Set another employer as default first."
                )
                return@launch
            }
            
            // iOS conformance: Check if employer has shifts or entries
            val shiftCount = _state.value.employerShiftCounts[employerId] ?: 0
            val entryCount = _state.value.employerEntryCounts[employerId] ?: 0
            
            if (shiftCount > 0 || entryCount > 0) {
                // Cannot delete - show iOS-style alert with deactivate option
                _state.value = _state.value.copy(
                    showCannotDeleteAlert = true,
                    employerToDelete = employer,
                    cannotDeleteMessage = "Cannot delete ${employer.name} because it has $shiftCount shifts and $entryCount entries. You can deactivate it instead."
                )
            } else {
                // Safe to delete - proceed
                _state.value = _state.value.copy(
                    employerToDelete = employer
                )
            }
        }
    }

    /**
     * Confirm deletion after data check passed
     */
    fun confirmDeleteEmployer() {
        viewModelScope.launch {
            val employerId = _state.value.employerToDelete?.id ?: return@launch
            
            employerRepository.deleteEmployer(employerId).fold(
                onSuccess = {
                    _state.value = _state.value.copy(
                        employerToDelete = null
                    )
                    loadEmployers()
                },
                onFailure = { exception ->
                    _state.value = _state.value.copy(
                        error = exception.message ?: "Failed to delete employer",
                        employerToDelete = null
                    )
                }
            )
        }
    }

    /**
     * Cancel deletion request
     */
    fun cancelDelete() {
        _state.value = _state.value.copy(
            showCannotDeleteAlert = false,
            employerToDelete = null,
            cannotDeleteMessage = null
        )
    }

    /**
     * Deactivate employer instead of deleting (iOS pattern)
     * Matches iOS alert action (lines 105-110)
     */
    fun deactivateInsteadOfDelete() {
        viewModelScope.launch {
            val employerId = _state.value.employerToDelete?.id ?: return@launch
            toggleEmployerActive(employerId)
            cancelDelete()
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
    val error: String? = null,
    // iOS conformance: Shift and entry counts (EmployersView.swift lines 19-20)
    val employerShiftCounts: Map<String, Int> = emptyMap(),
    val employerEntryCounts: Map<String, Int> = emptyMap(),
    // Delete protection state (iOS lines 16-18)
    val showCannotDeleteAlert: Boolean = false,
    val employerToDelete: Employer? = null,
    val cannotDeleteMessage: String? = null
)