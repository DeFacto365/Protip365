package com.protip365.app.presentation.subscription

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.SubscriptionTier
import com.protip365.app.data.models.UserSubscription
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.SubscriptionRepository
import com.protip365.app.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class EnhancedSubscriptionViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val subscriptionRepository: SubscriptionRepository,
    private val userRepository: UserRepository,
    private val billingManager: BillingManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(SubscriptionUiState())
    val uiState: StateFlow<SubscriptionUiState> = _uiState.asStateFlow()

    val billingState = billingManager.billingState
    val products = billingManager.products
    val weeklyLimits = _uiState.map { it.weeklyLimits }

    init {
        loadSubscriptionData()
        observeBillingState()
    }

    private fun loadSubscriptionData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            try {
                val user = authRepository.getCurrentUser()
                val userId = user?.userId
                if (userId != null) {
                    val subscription = subscriptionRepository.getCurrentSubscription(userId)
                    val limits = subscriptionRepository.checkWeeklyLimits(userId)

                    _uiState.update {
                        it.copy(
                            currentSubscription = subscription,
                            weeklyLimits = limits,
                            isLoading = false
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = e.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    private fun observeBillingState() {
        viewModelScope.launch {
            billingManager.billingState.collect { billingState ->
                _uiState.update {
                    it.copy(
                        currentTier = billingState.currentTier,
                        billingError = billingState.error
                    )
                }

                if (billingState.purchaseSuccessful) {
                    syncPurchaseWithBackend()
                }
            }
        }
    }

    fun purchaseSubscription(activity: Activity, productId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isPurchasing = true) }

            try {
                val result = billingManager.launchBillingFlow(activity, productId)
                // The result will be handled in the PurchasesUpdatedListener
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = e.message,
                        isPurchasing = false
                    )
                }
            }
        }
    }

    fun restorePurchases() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRestoring = true) }

            try {
                billingManager.queryPurchases()
                val result = subscriptionRepository.restorePurchases()

                if (result.isSuccess) {
                    loadSubscriptionData()
                    _uiState.update {
                        it.copy(
                            isRestoring = false,
                            message = "Purchases restored successfully"
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            isRestoring = false,
                            error = result.exceptionOrNull()?.message
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isRestoring = false,
                        error = e.message
                    )
                }
            }
        }
    }

    private suspend fun syncPurchaseWithBackend() {
        try {
            val currentProductId = billingManager.getCurrentSubscriptionProductId()
            val user = authRepository.getCurrentUser()
            val userId = user?.userId

            if (currentProductId != null && userId != null) {
                // Save subscription to database
                val subscription = UserSubscription(
                    userId = userId,
                    productId = currentProductId,
                    status = "active",
                    purchaseDate = kotlinx.datetime.Clock.System.now().toString(),
                    environment = if (billingManager.billingState.value.isConnected) "production" else "sandbox"
                )

                // This would call your backend to save the subscription
                // For now, we'll just reload the subscription data
                loadSubscriptionData()

                _uiState.update {
                    it.copy(
                        isPurchasing = false,
                        message = "Subscription activated successfully!"
                    )
                }
            }
        } catch (e: Exception) {
            _uiState.update {
                it.copy(
                    isPurchasing = false,
                    error = "Failed to sync subscription: ${e.message}"
                )
            }
        }
    }

    fun getProductPrice(productId: String): String? {
        return billingManager.getProductPrice(productId)
    }

    fun clearError() {
        _uiState.update { it.copy(error = null, billingError = null) }
    }

    fun clearMessage() {
        _uiState.update { it.copy(message = null) }
    }
}

data class SubscriptionUiState(
    val currentSubscription: UserSubscription? = null,
    val currentTier: SubscriptionTier = SubscriptionTier.NONE,
    val weeklyLimits: com.protip365.app.domain.repository.WeeklyLimits? = null,
    val isLoading: Boolean = false,
    val isPurchasing: Boolean = false,
    val isRestoring: Boolean = false,
    val error: String? = null,
    val billingError: String? = null,
    val message: String? = null
)