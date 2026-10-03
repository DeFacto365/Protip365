package com.protip365.app.presentation.subscription

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.*
import com.protip365.app.data.models.SubscriptionTier
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume

@Singleton
class BillingManager @Inject constructor(
    @ApplicationContext private val context: Context
) : PurchasesUpdatedListener {

    private val billingClient = BillingClient.newBuilder(context)
        .setListener(this)
        .enablePendingPurchases()
        .build()

    private val _billingState = MutableStateFlow(BillingState())
    val billingState: StateFlow<BillingState> = _billingState.asStateFlow()

    private val _products = MutableStateFlow<List<ProductDetails>>(emptyList())
    val products: StateFlow<List<ProductDetails>> = _products.asStateFlow()

    private val _purchases = MutableStateFlow<List<Purchase>>(emptyList())
    val purchases: StateFlow<List<Purchase>> = _purchases.asStateFlow()

    companion object {
        // Product IDs matching iOS
        const val PART_TIME_MONTHLY = "com.protip365.parttime.monthly"
        const val PART_TIME_ANNUAL = "com.protip365.parttime.annual"
        const val FULL_ACCESS_MONTHLY = "com.protip365.monthly"
        const val FULL_ACCESS_ANNUAL = "com.protip365.annual"

        val PRODUCT_IDS = listOf(
            PART_TIME_MONTHLY,
            PART_TIME_ANNUAL,
            FULL_ACCESS_MONTHLY,
            FULL_ACCESS_ANNUAL
        )
    }

    init {
        startConnection()
    }

    private fun startConnection() {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    _billingState.value = _billingState.value.copy(isConnected = true)
                    queryProducts()
                    queryPurchases()
                } else {
                    _billingState.value = _billingState.value.copy(
                        isConnected = false,
                        error = "Billing setup failed: ${billingResult.debugMessage}"
                    )
                }
            }

            override fun onBillingServiceDisconnected() {
                _billingState.value = _billingState.value.copy(isConnected = false)
                // Try to reconnect
                startConnection()
            }
        })
    }

    private fun queryProducts() {
        val productList = PRODUCT_IDS.map { productId ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        }

        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(productList)
            .build()

        billingClient.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                _products.value = productDetailsList
                _billingState.value = _billingState.value.copy(productsLoaded = true)
            } else {
                _billingState.value = _billingState.value.copy(
                    error = "Failed to load products: ${billingResult.debugMessage}"
                )
            }
        }
    }

    fun queryPurchases() {
        billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        ) { billingResult, purchasesList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                _purchases.value = purchasesList
                purchasesList.forEach { purchase ->
                    if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED && !purchase.isAcknowledged) {
                        acknowledgePurchase(purchase)
                    }
                }
                updateSubscriptionTier(purchasesList)
            } else {
                _billingState.value = _billingState.value.copy(
                    error = "Failed to query purchases: ${billingResult.debugMessage}"
                )
            }
        }
    }

    suspend fun launchBillingFlow(activity: Activity, productId: String): BillingResult {
        return withContext(Dispatchers.Main) {
            val productDetails = _products.value.find { it.productId == productId }
                ?: return@withContext BillingResult.newBuilder()
                    .setResponseCode(BillingClient.BillingResponseCode.ITEM_UNAVAILABLE)
                    .build()

            val offerToken = productDetails.subscriptionOfferDetails?.firstOrNull()?.offerToken
                ?: return@withContext BillingResult.newBuilder()
                    .setResponseCode(BillingClient.BillingResponseCode.DEVELOPER_ERROR)
                    .build()

            val productDetailsParamsList = listOf(
                BillingFlowParams.ProductDetailsParams.newBuilder()
                    .setProductDetails(productDetails)
                    .setOfferToken(offerToken)
                    .build()
            )

            val billingFlowParams = BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(productDetailsParamsList)
                .build()

            billingClient.launchBillingFlow(activity, billingFlowParams)
        }
    }

    override fun onPurchasesUpdated(billingResult: BillingResult, purchases: List<Purchase>?) {
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    handlePurchase(purchase)
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                _billingState.value = _billingState.value.copy(
                    error = "Purchase cancelled"
                )
            }
            else -> {
                _billingState.value = _billingState.value.copy(
                    error = "Purchase failed: ${billingResult.debugMessage}"
                )
            }
        }
    }

    private fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
            if (!purchase.isAcknowledged) {
                acknowledgePurchase(purchase)
            }

            // Update local purchases list
            val updatedPurchases = _purchases.value.toMutableList()
            updatedPurchases.removeAll { it.purchaseToken == purchase.purchaseToken }
            updatedPurchases.add(purchase)
            _purchases.value = updatedPurchases

            updateSubscriptionTier(updatedPurchases)

            _billingState.value = _billingState.value.copy(
                purchaseSuccessful = true,
                error = null
            )
        }
    }

    private fun acknowledgePurchase(purchase: Purchase) {
        val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()

        billingClient.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                _billingState.value = _billingState.value.copy(
                    error = "Failed to acknowledge purchase: ${billingResult.debugMessage}"
                )
            }
        }
    }

    private fun updateSubscriptionTier(purchases: List<Purchase>) {
        val activePurchase = purchases.firstOrNull {
            it.purchaseState == Purchase.PurchaseState.PURCHASED
        }

        val tier = when (activePurchase?.products?.firstOrNull()) {
            PART_TIME_MONTHLY, PART_TIME_ANNUAL -> SubscriptionTier.PART_TIME
            FULL_ACCESS_MONTHLY, FULL_ACCESS_ANNUAL -> SubscriptionTier.FULL_ACCESS
            else -> SubscriptionTier.NONE
        }

        _billingState.value = _billingState.value.copy(currentTier = tier)
    }

    fun getProductPrice(productId: String): String? {
        return _products.value.find { it.productId == productId }
            ?.subscriptionOfferDetails?.firstOrNull()
            ?.pricingPhases?.pricingPhaseList?.firstOrNull()
            ?.formattedPrice
    }

    fun isSubscriptionActive(): Boolean {
        return _purchases.value.any { purchase ->
            purchase.purchaseState == Purchase.PurchaseState.PURCHASED &&
            purchase.products.any { it in PRODUCT_IDS }
        }
    }

    fun getCurrentSubscriptionProductId(): String? {
        return _purchases.value.firstOrNull { purchase ->
            purchase.purchaseState == Purchase.PurchaseState.PURCHASED
        }?.products?.firstOrNull()
    }
}

data class BillingState(
    val isConnected: Boolean = false,
    val productsLoaded: Boolean = false,
    val currentTier: SubscriptionTier = SubscriptionTier.NONE,
    val purchaseSuccessful: Boolean = false,
    val error: String? = null
)