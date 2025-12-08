# Android Subscription Management - Server-Side Implementation Guide

## Overview

This guide implements the same server-side subscription management for Android that was implemented for iOS. The goal is to ensure subscriptions are tied to **app user accounts** (not Google Play accounts), enabling true cross-platform subscription access.

## Problem

Currently, Android may be checking Google Play Billing purchases at the device level, which causes:
- Multiple app users on the same device share the same subscription
- Subscriptions are tied to Google accounts instead of app users
- Users can't access their subscription across iOS, Android, and web

## Solution

Implement **server-side subscription management** where:
1. Subscriptions are stored in your Supabase database tied to `user_id`
2. All platforms (iOS, Android, web) check the **server** for subscription status
3. Google Play Billing is only checked when user clicks "Restore Purchases"
4. Purchase validation happens server-side before granting access

---

## Implementation Steps

### 1. Update SubscriptionRepositoryImpl.kt

**File:** `/ProTip365Android/app/src/main/java/com/protip365/app/data/repository/SubscriptionRepositoryImpl.kt`

#### Current Issue
The `queryPurchases()` function automatically checks Google Play Billing and syncs purchases to any logged-in user.

#### Fix: Server-Only Subscription Check

```kotlin
// Remove automatic device purchase checking from initialization
override suspend fun checkSubscriptionStatus(): SubscriptionTier {
    Log.d("SubscriptionRepo", "🔍 Checking subscription status...")
    Log.d("SubscriptionRepo", "🌐 SERVER-ONLY MODE: Checking user's subscription from database")

    return try {
        val userId = supabaseClient.auth.currentUserOrNull()?.id
        if (userId == null) {
            Log.d("SubscriptionRepo", "❌ No authenticated user")
            _subscriptionStatus.value = SubscriptionTier.NONE
            return SubscriptionTier.NONE
        }

        Log.d("SubscriptionRepo", "✅ Checking subscription for user: $userId")

        // Check server subscription for this specific user
        // This ensures subscriptions are tied to app users, not device/Google account
        val subscription = getCurrentSubscription(userId.toString())

        if (subscription != null && subscription.status == "active") {
            // Verify expiration date
            val expiresAt = subscription.expiresAt?.toInstant()
            if (expiresAt != null && expiresAt > Clock.System.now()) {
                Log.d("SubscriptionRepo", "✅ Active subscription found for user")
                val tier = when (subscription.productId) {
                    "com.protip365.premium.monthly",
                    "protip365_premium_monthly" -> SubscriptionTier.PREMIUM
                    else -> SubscriptionTier.NONE
                }
                _subscriptionStatus.value = tier
                tier
            } else {
                Log.d("SubscriptionRepo", "⚠️ Subscription expired")
                _subscriptionStatus.value = SubscriptionTier.NONE
                SubscriptionTier.NONE
            }
        } else {
            Log.d("SubscriptionRepo", "❌ No active subscription found")
            _subscriptionStatus.value = SubscriptionTier.NONE
            SubscriptionTier.NONE
        }
    } catch (e: Exception) {
        Log.e("SubscriptionRepo", "❌ Error checking subscription: ${e.message}")
        _subscriptionStatus.value = SubscriptionTier.NONE
        SubscriptionTier.NONE
    }
}
```

#### Remove Auto-Sync on Init

```kotlin
init {
    // DON'T automatically query Google Play purchases on init
    // Only initialize the billing client for when user makes a purchase
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
                // DON'T call queryPurchases() here
                // Only query when user clicks "Restore Purchases"
                Log.d("SubscriptionRepo", "✅ Billing client connected")
            }
        }

        override fun onBillingServiceDisconnected() {
            // Try to reconnect
            initializeBillingClient()
        }
    })
}
```

---

### 2. Update Restore Purchases Function

**Only check Google Play Billing when user explicitly clicks "Restore Purchases"**

```kotlin
override suspend fun restorePurchases(): Result<Unit> {
    Log.d("SubscriptionRepo", "🔄 Restore Purchases: Checking device for existing subscriptions...")

    return try {
        val userId = supabaseClient.auth.currentUserOrNull()?.id
        if (userId == null) {
            Log.d("SubscriptionRepo", "❌ No authenticated user, cannot restore purchases")
            return Result.failure(Exception("User not authenticated"))
        }

        Log.d("SubscriptionRepo", "✅ Restoring purchases for user: $userId")

        // Query Google Play Billing for active subscriptions
        val queryPurchasesResult = suspendCancellableCoroutine<List<Purchase>> { continuation ->
            val params = QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build()

            billingClient.queryPurchasesAsync(params) { billingResult, purchases ->
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    continuation.resume(purchases)
                } else {
                    continuation.resume(emptyList())
                }
            }
        }

        var foundSubscription = false

        for (purchase in queryPurchasesResult) {
            if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
                Log.d("SubscriptionRepo", "📱 Found device subscription")

                // Validate and sync to current user
                val validated = validatePurchase(purchase)
                if (validated) {
                    syncPurchaseToServer(purchase, userId.toString())
                    foundSubscription = true
                }
            }
        }

        if (foundSubscription) {
            // Refresh subscription status after restoring
            checkSubscriptionStatus()
            Log.d("SubscriptionRepo", "✅ Restore complete - subscription synced")
        } else {
            Log.d("SubscriptionRepo", "ℹ️ No device subscriptions found to restore")
        }

        Result.success(Unit)
    } catch (e: Exception) {
        Log.e("SubscriptionRepo", "❌ Error restoring purchases: ${e.message}")
        Result.failure(e)
    }
}
```

---

### 3. Add Sync Purchase to Server Function

```kotlin
private suspend fun syncPurchaseToServer(purchase: Purchase, userId: String) {
    try {
        // Extract purchase details
        val productId = purchase.products.firstOrNull() ?: return
        val purchaseTime = Instant.fromEpochMilliseconds(purchase.purchaseTime)

        // For subscriptions, calculate expiration (monthly = 30 days)
        val expiresAt = purchaseTime.plus(30, DateTimeUnit.DAY, TimeZone.UTC)

        val subscriptionData = mapOf(
            "user_id" to userId,
            "product_id" to productId,
            "status" to "active",
            "transaction_id" to purchase.orderId,
            "purchase_date" to purchaseTime.toString(),
            "expires_at" to expiresAt.toString(),
            "environment" to "production"
        )

        // Upsert to database
        supabaseClient
            .from("user_subscriptions")
            .upsert(subscriptionData)

        Log.d("SubscriptionRepo", "✅ Subscription synced to server")
    } catch (e: Exception) {
        Log.e("SubscriptionRepo", "❌ Failed to sync subscription: ${e.message}")
    }
}
```

---

### 4. Update Purchase Flow

Ensure new purchases are synced to the server:

```kotlin
override fun onPurchasesUpdated(billingResult: BillingResult, purchases: List<Purchase>?) {
    if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
        for (purchase in purchases) {
            if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
                // Verify purchase
                if (!purchase.isAcknowledged) {
                    acknowledgePurchase(purchase)
                }

                // Sync to current user's account
                kotlinx.coroutines.GlobalScope.launch {
                    val userId = supabaseClient.auth.currentUserOrNull()?.id
                    if (userId != null) {
                        syncPurchaseToServer(purchase, userId.toString())
                        checkSubscriptionStatus()
                    }
                }
            }
        }
    } else if (billingResult.responseCode == BillingClient.BillingResponseCode.USER_CANCELED) {
        // User cancelled - don't auto-sync device subscriptions
        Log.d("SubscriptionRepo", "User cancelled purchase")
    } else {
        // Purchase failed - don't auto-sync
        Log.d("SubscriptionRepo", "Purchase failed: ${billingResult.debugMessage}")
    }
}

private fun acknowledgePurchase(purchase: Purchase) {
    val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
        .setPurchaseToken(purchase.purchaseToken)
        .build()

    billingClient.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
            Log.d("SubscriptionRepo", "✅ Purchase acknowledged")
        }
    }
}
```

---

### 5. Update Login Flow (AuthViewModel or MainActivity)

**Make subscription check non-blocking and background:**

```kotlin
// In your login success handler or MainActivity onCreate
fun onLoginSuccess() {
    // Allow user to access app immediately
    _isAuthenticated.value = true

    // Check subscription in background (non-blocking)
    viewModelScope.launch {
        subscriptionRepository.checkSubscriptionStatus()
    }
}
```

---

### 6. Add "Keep Me Signed In" Feature

**File:** `LoginScreen.kt` or `AuthViewModel.kt`

Add a checkbox to the login screen:

```kotlin
// In LoginScreen.kt
var keepMeSignedIn by remember { mutableStateOf(true) }

// In login form
Row(
    modifier = Modifier
        .fillMaxWidth()
        .padding(vertical = 8.dp),
    verticalAlignment = Alignment.CenterVertically
) {
    Checkbox(
        checked = keepMeSignedIn,
        onCheckedChange = { keepMeSignedIn = it }
    )
    Spacer(modifier = Modifier.width(8.dp))
    Text(
        text = "Keep me signed in",
        style = MaterialTheme.typography.bodyMedium
    )
}
```

**Store preference and implement sign-out on app close:**

```kotlin
// In PreferencesManager.kt
suspend fun setKeepMeSignedIn(keep: Boolean) {
    dataStore.edit { preferences ->
        preferences[KEEP_ME_SIGNED_IN] = keep
    }
}

fun getKeepMeSignedIn(): Flow<Boolean> {
    return dataStore.data.map { preferences ->
        preferences[KEEP_ME_SIGNED_IN] ?: true
    }
}

// In MainActivity
override fun onPause() {
    super.onPause()
    lifecycleScope.launch {
        val keepSignedIn = preferencesManager.getKeepMeSignedIn().first()
        if (!keepSignedIn) {
            // Sign out when app goes to background
            supabaseClient.auth.signOut()
        }
    }
}
```

---

## Testing Checklist

### Test Case 1: Multiple Users on Same Device
1. Sign in as User A on Android device
2. User A purchases subscription
3. Verify User A has access
4. Sign out User A
5. Sign in as User B on same Android device
6. **Expected:** User B should NOT have subscription (must purchase separately)

### Test Case 2: Cross-Platform Access
1. User A purchases on iOS
2. Sign in as User A on Android
3. **Expected:** User A should have access (subscription from server)
4. Click "Restore Purchases" if needed

### Test Case 3: Restore Purchases
1. User A purchases on Android Device 1
2. Sign in as User A on Android Device 2
3. Click "Restore Purchases"
4. **Expected:** Subscription should sync from Device 1 to User A's account

### Test Case 4: Keep Me Signed In
1. Sign in with "Keep me signed in" unchecked
2. Close app
3. Reopen app
4. **Expected:** User should be signed out

---

## Database Schema

Ensure your `user_subscriptions` table has:

```sql
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    status TEXT NOT NULL,
    transaction_id TEXT UNIQUE NOT NULL,
    purchase_date TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    environment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id) -- One subscription per user
);

CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(status);
```

---

## Key Differences from iOS

| Aspect | iOS (StoreKit 2) | Android (Google Play Billing) |
|--------|------------------|-------------------------------|
| **Purchase API** | `Product.purchase()` | `BillingClient.launchBillingFlow()` |
| **Current Entitlements** | `Transaction.currentEntitlements` | `queryPurchasesAsync()` |
| **Receipt Validation** | App Store Server API | Google Play Developer API |
| **Product IDs** | `com.protip365.premium.monthly` | `protip365_premium_monthly` |

---

## Additional Recommendations

### 1. Server-Side Purchase Verification

For production, validate Google Play purchases on your backend:

```kotlin
// Send purchase token to your backend
suspend fun verifyPurchaseOnServer(purchaseToken: String): Boolean {
    return try {
        val response = yourBackendApi.verifyGooglePlayPurchase(purchaseToken)
        response.isValid
    } catch (e: Exception) {
        false
    }
}
```

### 2. Handle Subscription Lifecycle Events

Use Google Play Billing Real-Time Developer Notifications:
- Subscription renewals
- Subscription cancellations
- Subscription expirations
- Grace periods

### 3. Localization

Add translations for subscription-related strings:

```xml
<!-- strings.xml -->
<string name="keep_me_signed_in">Keep me signed in</string>
<string name="restore_purchases">Restore Purchases</string>
<string name="subscription_restored">Subscription restored successfully</string>
<string name="no_subscription_found">No subscription found on this device</string>
```

---

## Summary

This implementation ensures:
- ✅ Subscriptions are tied to app users, not devices/Google accounts
- ✅ True cross-platform access (iOS, Android, Web)
- ✅ Server is the single source of truth
- ✅ Google Play Billing only checked on "Restore Purchases"
- ✅ Fast login without blocking on subscription checks
- ✅ "Keep me signed in" feature for user convenience

---

## Next Steps

1. Implement the changes in `SubscriptionRepositoryImpl.kt`
2. Update `LoginScreen.kt` with "Keep me signed in" checkbox
3. Test with multiple users on the same device
4. Test cross-platform subscription access
5. Deploy to staging/TestFlight for testing
6. Monitor subscription sync logs in production

---

**Generated:** 2025-10-02
**iOS Implementation:** Completed in v1.1.35
**Android Implementation:** Follow this guide
