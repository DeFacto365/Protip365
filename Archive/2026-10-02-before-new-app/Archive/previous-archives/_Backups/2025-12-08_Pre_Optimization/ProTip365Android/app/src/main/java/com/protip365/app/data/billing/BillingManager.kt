package com.protip365.app.data.billing

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.*
import com.protip365.app.core.BillingConstants
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

    private val _purchaseState = MutableStateFlow<PurchaseState>(PurchaseState.Idle)
    val purchaseState: StateFlow<PurchaseState> = _purchaseState.asStateFlow()

    private var billingClient: BillingClient? = null
    private var productDetails: ProductDetails? = null

    private val purchasesUpdatedListener = PurchasesUpdatedListener { billingResult, purchases ->
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    handlePurchase(purchase)
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                _purchaseState.value = PurchaseState.Error("Purchase cancelled")
            }
            BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> {
                _purchaseState.value = PurchaseState.AlreadyOwned
            }
            else -> {
                _purchaseState.value = PurchaseState.Error(billingResult.debugMessage)
            }
        }
    }

    init {
        initializeBillingClient()
    }

    private fun initializeBillingClient() {
        billingClient = BillingClient.newBuilder(context)
            .setListener(purchasesUpdatedListener)
            .enablePendingPurchases()
            .build()
    }

    suspend fun connect(): Result<Unit> = withContext(Dispatchers.IO) {
        suspendCancellableCoroutine { continuation ->
            billingClient?.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(billingResult: BillingResult) {
                    if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                        continuation.resume(Result.success(Unit))
                    } else {
                        continuation.resume(
                            Result.failure(
                                Exception("Billing setup failed: ${billingResult.debugMessage}")
                            )
                        )
                    }
                }

                override fun onBillingServiceDisconnected() {
                    continuation.resume(
                        Result.failure(Exception("Billing service disconnected"))
                    )
                }
            })
        }
    }

    suspend fun loadProducts(): Result<ProductDetails?> = withContext(Dispatchers.IO) {
        try {
            val connectResult = connect()
            if (connectResult.isFailure) {
                return@withContext Result.failure(connectResult.exceptionOrNull()!!)
            }

            val productList = listOf(
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(BillingConstants.PREMIUM_MONTHLY_PRODUCT_ID)
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
            )

            val params = QueryProductDetailsParams.newBuilder()
                .setProductList(productList)
                .build()

            val result = billingClient?.queryProductDetails(params)

            if (result?.billingResult?.responseCode == BillingClient.BillingResponseCode.OK) {
                productDetails = result.productDetailsList?.firstOrNull()
                Result.success(productDetails)
            } else {
                Result.failure(
                    Exception("Failed to load products: ${result?.billingResult?.debugMessage}")
                )
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun launchPurchaseFlow(activity: Activity): Result<Unit> {
        return try {
            val currentProductDetails = productDetails
                ?: return Result.failure(Exception("Product details not loaded"))

            val offerToken = currentProductDetails.subscriptionOfferDetails?.firstOrNull()?.offerToken
                ?: return Result.failure(Exception("No subscription offers available"))

            val productDetailsParamsList = listOf(
                BillingFlowParams.ProductDetailsParams.newBuilder()
                    .setProductDetails(currentProductDetails)
                    .setOfferToken(offerToken)
                    .build()
            )

            val billingFlowParams = BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(productDetailsParamsList)
                .build()

            _purchaseState.value = PurchaseState.Loading

            val billingResult = withContext(Dispatchers.Main) {
                billingClient?.launchBillingFlow(activity, billingFlowParams)
            }

            if (billingResult?.responseCode == BillingClient.BillingResponseCode.OK) {
                Result.success(Unit)
            } else {
                _purchaseState.value = PurchaseState.Error(billingResult?.debugMessage ?: "Unknown error")
                Result.failure(Exception(billingResult?.debugMessage))
            }
        } catch (e: Exception) {
            _purchaseState.value = PurchaseState.Error(e.message ?: "Unknown error")
            Result.failure(e)
        }
    }

    private fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
            if (!purchase.isAcknowledged) {
                acknowledgePurchase(purchase)
            } else {
                _purchaseState.value = PurchaseState.Success(purchase)
            }
        } else if (purchase.purchaseState == Purchase.PurchaseState.PENDING) {
            _purchaseState.value = PurchaseState.Pending
        }
    }

    private fun acknowledgePurchase(purchase: Purchase) {
        val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()

        billingClient?.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                _purchaseState.value = PurchaseState.Success(purchase)
            } else {
                _purchaseState.value = PurchaseState.Error("Failed to acknowledge purchase")
            }
        }
    }

    suspend fun queryActivePurchases(): Result<List<Purchase>> = withContext(Dispatchers.IO) {
        try {
            val connectResult = connect()
            if (connectResult.isFailure) {
                return@withContext Result.failure(connectResult.exceptionOrNull()!!)
            }

            val params = QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build()

            val result = billingClient?.queryPurchasesAsync(params)

            if (result?.billingResult?.responseCode == BillingClient.BillingResponseCode.OK) {
                val activePurchases = result.purchasesList.filter {
                    it.purchaseState == Purchase.PurchaseState.PURCHASED
                }
                Result.success(activePurchases)
            } else {
                Result.failure(
                    Exception("Failed to query purchases: ${result?.billingResult?.debugMessage}")
                )
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun onPurchasesUpdated(billingResult: BillingResult, purchases: MutableList<Purchase>?) {
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    handlePurchase(purchase)
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                _purchaseState.value = PurchaseState.Error("Purchase cancelled")
            }
            else -> {
                _purchaseState.value = PurchaseState.Error(billingResult.debugMessage)
            }
        }
    }

    fun resetPurchaseState() {
        _purchaseState.value = PurchaseState.Idle
    }

    fun endConnection() {
        billingClient?.endConnection()
    }
}

sealed class PurchaseState {
    object Idle : PurchaseState()
    object Loading : PurchaseState()
    object Pending : PurchaseState()
    data class Success(val purchase: Purchase) : PurchaseState()
    object AlreadyOwned : PurchaseState()
    data class Error(val message: String) : PurchaseState()
}

