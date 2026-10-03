# Android Implementation Guide - Subscription Sign Out Fix

## Overview
This guide documents the changes made to the iOS subscription screen to fix the sign-in/sign-out functionality and add product loading retry capabilities. The Android version should implement equivalent changes.

## Changes Made in iOS (v1.1.33)

### 1. Sign Out Button Implementation

**Issue**: The subscription screen had a non-functional "Sign In" button
**Fix**: Changed to "Sign Out" button with proper sign-out functionality

#### iOS Implementation
**File**: `ProTip365/Subscription/SubscriptionView.swift`

```swift
// Sign Out Button
Button(action: {
    Task {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            NotificationCenter.default.post(name: .userDidSignOut, object: nil)
        } catch {
            print("Error signing out: \(error)")
        }
    }
}) {
    Text(signOutButton)
        .font(.body)
        .foregroundColor(.blue)
}
.padding(.top, 20)
```

#### Localized Text (iOS)
```swift
var signOutButton: String {
    switch language {
    case "fr": return "Se déconnecter"
    case "es": return "Cerrar sesión"
    default: return "Sign Out"
    }
}
```

#### Android Equivalent

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/SubscriptionScreen.kt`

**Implementation**:
```kotlin
// Sign Out Button
TextButton(
    onClick = {
        scope.launch {
            try {
                supabaseClient.auth.signOut()
                // Navigate back to auth screen
                navController.navigate("auth") {
                    popUpTo(0) { inclusive = true }
                }
            } catch (e: Exception) {
                Log.e("SubscriptionScreen", "Error signing out: ${e.message}")
            }
        }
    },
    modifier = Modifier.padding(top = 20.dp)
) {
    Text(
        text = stringResource(R.string.sign_out),
        color = MaterialTheme.colorScheme.primary
    )
}
```

**Add to strings.xml**:
```xml
<!-- values/strings.xml -->
<string name="sign_out">Sign Out</string>

<!-- values-fr/strings.xml -->
<string name="sign_out">Se déconnecter</string>

<!-- values-es/strings.xml -->
<string name="sign_out">Cerrar sesión</string>
```

### 2. Product Loading Retry Functionality

**Issue**: When subscription products fail to load from Google Play Billing, users see nothing and clicking subscribe does nothing
**Fix**: Added warning message and retry button when products fail to load

#### iOS Implementation
```swift
// Debug info (only show if products failed to load)
if subscriptionManager.products.isEmpty {
    VStack(spacing: 12) {
        Text("⚠️ Unable to load subscription products")
            .font(.caption)
            .foregroundColor(.orange)

        Button(action: {
            Task {
                await subscriptionManager.loadProducts()
            }
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Retry Loading Products")
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.bottom, 8)
    }
}

// Subscribe Button
Button(action: {
    // Check if products are loaded first
    if subscriptionManager.products.isEmpty {
        print("❌ Cannot purchase - no products loaded")
        return
    }

    // ... purchase logic
}) {
    // ... button UI
}
```

#### Android Equivalent

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/SubscriptionScreen.kt`

**Implementation**:
```kotlin
// Check if products are loaded
val products by viewModel.products.collectAsState()

// Warning message when products are empty
if (products.isEmpty()) {
    Column(
        modifier = Modifier.padding(horizontal = 30.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = "⚠️ ${stringResource(R.string.unable_to_load_products)}",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error
        )

        TextButton(
            onClick = {
                scope.launch {
                    viewModel.loadProducts()
                }
            }
        ) {
            Icon(
                imageVector = Icons.Default.Refresh,
                contentDescription = "Retry"
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(stringResource(R.string.retry_loading_products))
        }
    }
}

// Subscribe Button
Button(
    onClick = {
        // Check if products are loaded first
        if (products.isEmpty()) {
            Log.e("SubscriptionScreen", "Cannot purchase - no products loaded")
            return@Button
        }

        scope.launch {
            viewModel.purchase(productId)
        }
    },
    enabled = products.isNotEmpty() && !isLoading,
    modifier = Modifier
        .fillMaxWidth()
        .padding(horizontal = 30.dp)
        .height(54.dp),
    shape = RoundedCornerShape(12.dp)
) {
    if (isLoading) {
        CircularProgressIndicator(
            color = MaterialTheme.colorScheme.onPrimary,
            modifier = Modifier.size(24.dp)
        )
    } else {
        Text(stringResource(R.string.subscribe))
    }
}
```

**Add to strings.xml**:
```xml
<!-- values/strings.xml -->
<string name="unable_to_load_products">Unable to load subscription products</string>
<string name="retry_loading_products">Retry Loading Products</string>

<!-- values-fr/strings.xml -->
<string name="unable_to_load_products">Impossible de charger les produits d\'abonnement</string>
<string name="retry_loading_products">Réessayer de charger les produits</string>

<!-- values-es/strings.xml -->
<string name="unable_to_load_products">No se pueden cargar los productos de suscripción</string>
<string name="retry_loading_products">Reintentar carga de productos</string>
```

### 3. ViewModel Changes Required

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/SubscriptionViewModel.kt`

Add product loading with retry capability:

```kotlin
private val _products = MutableStateFlow<List<ProductDetails>>(emptyList())
val products: StateFlow<List<ProductDetails>> = _products.asStateFlow()

suspend fun loadProducts() {
    try {
        val productList = billingClient.queryProductDetails(
            QueryProductDetailsParams.newBuilder()
                .setProductList(
                    listOf(
                        QueryProductDetailsParams.Product.newBuilder()
                            .setProductId("com.protip365.premium.monthly")
                            .setProductType(BillingClient.ProductType.SUBS)
                            .build()
                    )
                )
                .build()
        )

        _products.value = productList.productDetailsList ?: emptyList()

        if (_products.value.isEmpty()) {
            Log.w("SubscriptionViewModel", "No products loaded from Google Play")
        }
    } catch (e: Exception) {
        Log.e("SubscriptionViewModel", "Failed to load products: ${e.message}")
        _products.value = emptyList()
    }
}

suspend fun purchase(productId: String) {
    if (_products.value.isEmpty()) {
        Log.e("SubscriptionViewModel", "Cannot purchase - no products loaded")
        return
    }

    // ... existing purchase logic
}
```

## Summary of Changes

### iOS (v1.1.33)
1. ✅ Changed "Sign In" button to "Sign Out" with proper functionality
2. ✅ Added localized text for Sign Out (EN, FR, ES)
3. ✅ Added warning when products fail to load
4. ✅ Added retry button to reload products
5. ✅ Prevent purchase when products array is empty
6. ✅ Added console logging for debugging

### Android (To Implement)
1. ⏳ Change "Sign In" to "Sign Out" in SubscriptionScreen
2. ⏳ Implement sign out functionality using Supabase auth
3. ⏳ Add localized strings for Sign Out
4. ⏳ Add product loading status check
5. ⏳ Show warning when products fail to load
6. ⏳ Add retry button for product loading
7. ⏳ Disable subscribe button when products are empty
8. ⏳ Add logging for debugging billing issues

## Testing Checklist

### Sign Out Functionality
- [ ] Sign Out button appears on subscription screen
- [ ] Clicking Sign Out successfully logs user out
- [ ] User is redirected to auth/login screen after sign out
- [ ] Subscription state is cleared on sign out
- [ ] Works correctly in all languages (EN, FR, ES)

### Product Loading Retry
- [ ] Warning appears when products fail to load
- [ ] Retry button successfully reloads products
- [ ] Subscribe button is disabled when products are empty
- [ ] Subscribe button is enabled when products load successfully
- [ ] Console logs show helpful debugging information

## Files Modified

### iOS
- `ProTip365/Subscription/SubscriptionView.swift` - Sign out button + retry UI
- `ProTip365/Info.plist` - Version updated to 1.1.33 (Build 33)

### Android (Need to Modify)
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/SubscriptionScreen.kt`
- `ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/SubscriptionViewModel.kt`
- `ProTip365Android/app/src/main/res/values/strings.xml`
- `ProTip365Android/app/src/main/res/values-fr/strings.xml`
- `ProTip365Android/app/src/main/res/values-es/strings.xml`
- `ProTip365Android/app/build.gradle.kts` - Update version to 1.1.33 (versionCode 33)

## Notes

- The iOS version uses StoreKit 2 for in-app purchases
- Android should use Google Play Billing Library v6+
- Product ID must match exactly: `com.protip365.premium.monthly`
- Ensure product is configured in Google Play Console before testing
- TestFlight/Internal Testing should use sandbox environment automatically

## Questions?

If you need clarification on any aspect of this implementation, refer to the iOS source files listed above or ask for additional details.
