package com.protip365.app.data.repository

import android.content.Context
import com.android.billingclient.api.*
import com.protip365.app.data.models.SubscriptionTier
import com.protip365.app.data.models.UserSubscription
import com.protip365.app.domain.repository.SubscriptionRepository
import com.protip365.app.domain.repository.WeeklyLimits
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.datetime.*
import javax.inject.Inject
import kotlin.coroutines.resume

class SubscriptionRepositoryImpl @Inject constructor(
    private val context: Context,
    private val supabaseClient: SupabaseClient
) : SubscriptionRepository, PurchasesUpdatedListener {

    private val _subscriptionStatus = MutableStateFlow(SubscriptionTier.NONE)
    private lateinit var billingClient: BillingClient
    private val productIds = mapOf(
        "protip365_premium_monthly" to SubscriptionTier.PREMIUM
    )
    private val TRIAL_OFFER_ID = "freetrial7days"

    init {
        initializeBillingClient()
    }

    private fun initializeBillingClient() {
        billingClient = BillingClient.newBuilder(context)
            .setListener(this)
            .enablePendingPurchases()
            .build()

        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    // Query purchases to get current status
                    queryPurchases()
                }
            }

            override fun onBillingServiceDisconnected() {
                // Try to reconnect
                initializeBillingClient()
            }
        })
    }

    override suspend fun getCurrentSubscription(userId: String?): UserSubscription? {
        return try {
            val actualUserId = userId ?: supabaseClient.auth.currentUserOrNull()?.id ?: return null
            supabaseClient
                .from("user_subscriptions")
                .select {
                    filter {
                        eq("user_id", actualUserId)
                        eq("status", "active")
                    }
                }
                .decodeSingleOrNull<UserSubscription>()
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun purchaseSubscription(tier: SubscriptionTier): Result<Unit> {
        // This would trigger the Google Play Billing flow
        // Implementation depends on your activity/fragment context
        return Result.success(Unit)
    }

    override suspend fun restorePurchases(): Result<Unit> {
        return try {
            queryPurchases()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun cancelSubscription(): Result<Unit> {
        return try {
            val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("Not logged in"))

            supabaseClient
                .from("user_subscriptions")
                .update(mapOf("status" to "cancelled")) {
                    filter {
                        eq("user_id", userId)
                        eq("status", "active")
                    }
                }

            _subscriptionStatus.value = SubscriptionTier.NONE
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun observeSubscriptionStatus(): Flow<SubscriptionTier> = _subscriptionStatus.asStateFlow()

    override suspend fun checkWeeklyLimits(userId: String): WeeklyLimits {
        val subscription = getCurrentSubscription(userId)
        val tier = subscription?.let {
            when (it.productId) {
                in productIds.keys -> productIds[it.productId]
                else -> SubscriptionTier.NONE
            }
        } ?: SubscriptionTier.NONE

        // If Full Access, no limits
        if (tier == SubscriptionTier.FULL_ACCESS || tier == SubscriptionTier.NONE) {
            return WeeklyLimits(
                shiftsUsed = 0,
                entriesUsed = 0,
                shiftsLimit = null,
                entriesLimit = null,
                canAddShift = true,
                canAddEntry = true
            )
        }

        // Calculate week boundaries based on user's week start preference
        val userProfile = supabaseClient
            .from("users_profile")
            .select {
                filter {
                    eq("user_id", userId)
                }
            }
            .decodeSingleOrNull<com.protip365.app.data.models.UserProfile>()

        val weekStart = userProfile?.weekStart ?: 0 // 0 = Sunday, 1 = Monday
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        val startOfWeek = today.minus(today.dayOfWeek.ordinal - weekStart, DateTimeUnit.DAY)
        val endOfWeek = startOfWeek.plus(6, DateTimeUnit.DAY)

        // Count expected shifts and shift entries for this week
        val expectedShifts = supabaseClient
            .from("expected_shifts")
            .select {
                filter {
                    eq("user_id", userId)
                    gte("shift_date", startOfWeek.toString())
                    lte("shift_date", endOfWeek.toString())
                }
            }
            .decodeList<com.protip365.app.data.models.ExpectedShift>()

        val shiftEntries = supabaseClient
            .from("shift_entries")
            .select {
                filter {
                    eq("user_id", userId)
                    // Join with expected_shifts to filter by date
                }
            }
            .decodeList<com.protip365.app.data.models.ShiftEntry>()
            // Filter by week in memory since shift_entries doesn't have date directly
            .filter { entry ->
                expectedShifts.any { shift -> shift.id == entry.shiftId }
            }

        val shiftsUsed = expectedShifts.size
        val entriesUsed = shiftEntries.size

        return WeeklyLimits(
            shiftsUsed = shiftsUsed,
            entriesUsed = entriesUsed,
            shiftsLimit = tier.shiftsPerWeek,
            entriesLimit = tier.entriesPerWeek,
            canAddShift = shiftsUsed < (tier.shiftsPerWeek ?: 0),
            canAddEntry = entriesUsed < (tier.entriesPerWeek ?: 0)
        )
    }

    override fun onPurchasesUpdated(billingResult: BillingResult, purchases: MutableList<Purchase>?) {
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (purchase in purchases) {
                handlePurchase(purchase)
            }
        }
    }

    private fun handlePurchase(purchase: Purchase) {
        // Acknowledge purchase and update database
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
            // Update local state
            productIds[purchase.products.firstOrNull()]?.let {
                _subscriptionStatus.value = it
            }

            // Verify purchase and update user_subscriptions table
            kotlinx.coroutines.runBlocking {
                verifyAndUpdateSubscription(purchase)
            }
        }
    }

    private fun queryPurchases() {
        billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        ) { billingResult, purchases ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                for (purchase in purchases) {
                    handlePurchase(purchase)
                }
            }
        }
    }

    private suspend fun verifyAndUpdateSubscription(purchase: Purchase) {
        try {
            val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return
            val productId = purchase.products.firstOrNull() ?: return
            
            // Determine subscription tier based on product ID
            val tier = when (productId) {
                "com.protip365.parttime.monthly", "com.protip365.parttime.annual" -> SubscriptionTier.PART_TIME
                "com.protip365.monthly", "com.protip365.annual" -> SubscriptionTier.FULL_ACCESS
                else -> SubscriptionTier.NONE
            }
            
            // Calculate expiration date based on product type
            val expiresAt = if (productId.contains("annual")) {
                Clock.System.now().plus(365, DateTimeUnit.DAY, TimeZone.currentSystemDefault())
            } else {
                Clock.System.now().plus(30, DateTimeUnit.DAY, TimeZone.currentSystemDefault())
            }
            
            // Create or update subscription record
            val subscription = UserSubscription(
                userId = userId,
                productId = productId,
                status = "active",
                expiresAt = expiresAt.toString(),
                transactionId = purchase.orderId,
                purchaseDate = Clock.System.now().toString(),
                environment = if (purchase.isAcknowledged) "production" else "sandbox"
            )
            
            // Check if subscription already exists
            val existingSubscription = getCurrentSubscription(userId)
            if (existingSubscription != null) {
                // Update existing subscription
                supabaseClient
                    .from("user_subscriptions")
                    .update(subscription) {
                        filter {
                            eq("user_id", userId)
                        }
                    }
            } else {
                // Insert new subscription
                supabaseClient
                    .from("user_subscriptions")
                    .insert(subscription)
            }
            
            // Update local state
            _subscriptionStatus.value = tier
            
        } catch (e: Exception) {
            // Log error but don't fail the purchase
            e.printStackTrace()
        }
    }

    override suspend fun startFreeTrial(tier: String): Result<Unit> {
        return try {
            val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("Not logged in"))

            // Check if user already has ANY subscription (due to unique constraint)
            val existingSubscription = getCurrentSubscription(userId)

            // If they have an active paid subscription, don't downgrade to trial
            if (existingSubscription != null && existingSubscription.productId?.contains("trial") != true) {
                return Result.failure(Exception("Already have an active subscription"))
            }

            // Check if they already used a trial
            if (existingSubscription?.productId?.contains("trial") == true) {
                return Result.failure(Exception("Trial already used"))
            }

            // Create trial subscription
            val trialEnd = Clock.System.now().plus(7, DateTimeUnit.DAY, TimeZone.currentSystemDefault())
            val subscription = UserSubscription(
                userId = userId,
                productId = "${tier}_trial",
                status = "active",
                expiresAt = trialEnd.toString(),
                transactionId = "trial_${System.currentTimeMillis()}",
                purchaseDate = Clock.System.now().toString(),
                environment = "sandbox" // Use sandbox for trials since DB only allows sandbox/production
            )

            // Upsert (insert or update if exists)
            if (existingSubscription != null) {
                supabaseClient
                    .from("user_subscriptions")
                    .update(subscription) {
                        filter {
                            eq("user_id", userId)
                        }
                    }
            } else {
                supabaseClient
                    .from("user_subscriptions")
                    .insert(subscription)
            }

            // Update local status
            _subscriptionStatus.value = when (tier) {
                "parttime" -> SubscriptionTier.PART_TIME
                "full" -> SubscriptionTier.FULL_ACCESS
                else -> SubscriptionTier.NONE
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun initializeFree(): Result<Unit> {
        return try {
            val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("Not logged in"))

            // Check if user already has any subscription
            val existing = getCurrentSubscription(userId)

            // If they have a paid or trial subscription, don't downgrade
            if (existing != null && existing.productId != "free") {
                return Result.success(Unit) // Keep existing subscription
            }

            // Create or update to free subscription record
            val subscription = UserSubscription(
                userId = userId,
                productId = "free",
                status = "active",
                expiresAt = null, // Free tier never expires
                transactionId = "free_${System.currentTimeMillis()}",
                purchaseDate = Clock.System.now().toString(),
                environment = "production"
            )

            // Upsert due to unique constraint
            if (existing != null) {
                supabaseClient
                    .from("user_subscriptions")
                    .update(subscription) {
                        filter {
                            eq("user_id", userId)
                        }
                    }
            } else {
                supabaseClient
                    .from("user_subscriptions")
                    .insert(subscription)
            }

            _subscriptionStatus.value = SubscriptionTier.NONE
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}