package com.protip365.app.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.SubscriptionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class SubscriptionViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val subscriptionRepository: SubscriptionRepository
) : ViewModel() {

    private val _state = MutableStateFlow(SubscriptionState())
    val state: StateFlow<SubscriptionState> = _state.asStateFlow()

    init {
        loadSubscription()
    }

    private fun loadSubscription() {
        viewModelScope.launch {
            val user = authRepository.getCurrentUser()
            user?.let {
                val subscription = subscriptionRepository.getCurrentSubscription(it.userId)
                
                if (subscription != null) {
                    val dateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.US)
                    val expiresAt = try {
                        val date = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
                            .parse(subscription.expiresAt)
                        dateFormat.format(date ?: Date())
                    } catch (e: Exception) {
                        null
                    }

                    _state.value = SubscriptionState(
                        currentTier = if (subscription.status == "active") "full" else "free",
                        expiresAt = expiresAt,
                        willRenew = subscription.status == "active",
                        isLoading = false
                    )
                } else {
                    _state.value = SubscriptionState(
                        currentTier = "free",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun subscribeToPlan(tier: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            
            // In a real app, this would integrate with Google Play Billing
            // For now, we'll simulate the subscription
            _state.value = _state.value.copy(
                isLoading = false,
                error = "Google Play Billing not implemented yet"
            )
        }
    }

    fun cancelSubscription() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            
            val user = authRepository.getCurrentUser()
            user?.let {
                subscriptionRepository.cancelSubscription().fold(
                    onSuccess = {
                        _state.value = _state.value.copy(
                            isLoading = false,
                            willRenew = false
                        )
                    },
                    onFailure = { exception ->
                        _state.value = _state.value.copy(
                            isLoading = false,
                            error = exception.message ?: "Failed to cancel subscription"
                        )
                    }
                )
            }
        }
    }

    fun restoreSubscription() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            
            // In a real app, this would restore from Google Play Billing
            // For now, we'll just reload from the database
            loadSubscription()
        }
    }
}

data class SubscriptionState(
    val currentTier: String = "free", // free, part_time, full_access
    val expiresAt: String? = null,
    val willRenew: Boolean = true,
    val isLoading: Boolean = true,
    val error: String? = null
)