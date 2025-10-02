# StoreKit Sandbox Testing Setup

## The Issue You're Experiencing

**Problem:** "Product not found" error when testing subscriptions

**Root Cause:** `Product.products(for:)` was trying to load from the **production App Store**, but your product isn't live yet.

---

## How StoreKit Testing Works

There are **THREE** environments for testing in-app purchases:

### 1. **Local StoreKit Configuration** (Simulator/Xcode Testing)
- **File**: `Protip365.storekit`
- **Purpose**: Test purchases WITHOUT any server calls
- **Use When**: Developing locally in Xcode/Simulator
- **Products**: Defined in .storekit file
- **Purchases**: Fake, no money involved
- **Receipt Validation**: Returns mock receipts

### 2. **Sandbox Environment** (TestFlight/Real Devices)
- **Server**: `https://sandbox.itunes.apple.com`
- **Purpose**: Test with real App Store infrastructure
- **Use When**: Testing on real devices via TestFlight
- **Products**: Must be configured in App Store Connect
- **Purchases**: Use sandbox test accounts
- **Receipt Validation**: Real receipts from Apple sandbox servers

### 3. **Production Environment** (Live App)
- **Server**: `https://buy.itunes.apple.com`
- **Purpose**: Real purchases from real customers
- **Use When**: App is live in App Store
- **Products**: Live products in App Store Connect
- **Purchases**: Real money from real customers
- **Receipt Validation**: Real receipts from Apple production servers

---

## What I Just Fixed

### ✅ Scheme Configuration Updated

**Changed:**
```xml
<!-- OLD - Wrong file -->
<StoreKitConfigurationFileReference
   identifier="../../ProTip365/StoreKitTestConfiguration.storekit">
</StoreKitConfigurationFileReference>

<!-- NEW - Correct file with your product -->
<StoreKitConfigurationFileReference
   identifier="../../ProTip365/Protip365.storekit">
</StoreKitConfigurationFileReference>
```

**Location:** `ProTip365.xcodeproj/xcshareddata/xcschemes/ProTip365.xcscheme`

### What This Means:

When you run in **Simulator**, it will now use:
- ✅ Your `Protip365.storekit` file
- ✅ Product ID: `com.protip365.premium.monthly`
- ✅ Price: $3.99
- ✅ 1-week free trial
- ✅ Mock purchases (no real money)

---

## Testing Flow

### Phase 1: Simulator Testing (Local StoreKit) ✅

**Environment:** Local .storekit file
**No Internet Required:** Products load instantly
**What Happens:**
```
🔄 Loading products: ["com.protip365.premium.monthly"]
✅ Loaded 1 products: ["com.protip365.premium.monthly"]
Product: com.protip365.premium.monthly - ProTip365 Premium - $3.99
```

**Steps:**
1. Open Xcode
2. Select scheme: **ProTip365**
3. Run on iPhone 16 Pro simulator
4. Sign in
5. Products should load instantly from .storekit file
6. Purchase with mock transaction
7. App grants access immediately

**Receipt Validation:**
- Uses mock receipts
- Always returns "valid"
- Good for testing UI flow
- **NOT good for testing real Apple server validation**

---

### Phase 2: TestFlight Testing (Sandbox) ⚠️

**Environment:** Apple's sandbox servers
**Internet Required:** Yes
**What Happens:**
```
🔵 Trying PRODUCTION server first...
⚠️ Sandbox receipt used in production (expected for TestFlight)
🟡 Production failed, trying SANDBOX server...
🌐 Calling: https://sandbox.itunes.apple.com/verifyReceipt
✅ SANDBOX validation successful
```

**Prerequisites:**
1. Product configured in **App Store Connect**
2. Product in "Ready to Submit" state
3. Sandbox test account created
4. Build uploaded to TestFlight

**Steps:**
1. Upload build to TestFlight
2. Install on real device
3. Sign OUT of real Apple ID in Settings
4. Launch app
5. Sign in with **sandbox test account** when prompted
6. Products load from App Store Connect
7. Purchase with sandbox account (no real money)
8. Receipt validated with sandbox.itunes.apple.com

**Receipt Validation:**
- Real receipts from Apple
- Status code 0 (valid) or error codes
- Tests actual server validation logic
- **THIS IS WHAT APPLE REVIEWS**

---

### Phase 3: Production (Live)

**Environment:** Apple's production servers
**Internet Required:** Yes
**What Happens:**
```
🔵 Trying PRODUCTION server first...
🌐 Calling: https://buy.itunes.apple.com/verifyReceipt
✅ PRODUCTION validation successful
```

**Steps:**
1. App approved by Apple
2. Released to App Store
3. Real customers download
4. Real purchases with real money
5. Receipt validated with buy.itunes.apple.com

---

## Current Implementation - How It Works

### When `Product.products(for:)` is Called:

**In Simulator with .storekit file:**
```swift
// Loads from Protip365.storekit
let products = try await Product.products(for: allProductIds)
// Returns: [Product(id: "com.protip365.premium.monthly", price: $3.99)]
```

**In TestFlight:**
```swift
// Loads from App Store Connect (sandbox)
let products = try await Product.products(for: allProductIds)
// Returns: Products configured in App Store Connect
```

**In Production:**
```swift
// Loads from App Store Connect (production)
let products = try await Product.products(for: allProductIds)
// Returns: Live products from App Store
```

---

## Troubleshooting

### "Product not found" in Simulator

**Cause:** StoreKit configuration file not selected or wrong file

**Fix:**
1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run** in left sidebar
3. Go to **Options** tab
4. Under **StoreKit Configuration**, select **Protip365.storekit**
5. Click Close
6. Clean build (⌘ + Shift + K)
7. Run again

**OR** - The scheme file should now be correct after my fix.

### "Product not found" in TestFlight

**Cause:** Product not configured in App Store Connect

**Fix:**
1. Go to App Store Connect
2. Your App → Subscriptions
3. Ensure product `com.protip365.premium.monthly` exists
4. Ensure product is in "Ready to Submit" state
5. Wait 10-15 minutes for propagation
6. Try again

### "Receipt validation failed" in TestFlight

**Cause:** Using production Apple ID instead of sandbox test account

**Fix:**
1. On device: Settings → App Store → Sign Out
2. Launch app
3. When prompted for Apple ID, use **sandbox test account**
4. Purchase subscription
5. Receipt will validate with sandbox servers

---

## What Happens in Each Environment

| Aspect | Simulator (.storekit) | TestFlight (Sandbox) | Production |
|--------|----------------------|---------------------|------------|
| Products Source | Protip365.storekit file | App Store Connect (sandbox) | App Store Connect (live) |
| Purchase Type | Mock/Fake | Sandbox (test) | Real money |
| Apple ID | Any/None | Sandbox test account | Real Apple ID |
| Receipt Server | Mock/None | sandbox.itunes.apple.com | buy.itunes.apple.com |
| Internet Required | No | Yes | Yes |
| Money Involved | No | No | Yes |
| What Apple Reviews | ❌ No | ✅ Yes | ✅ Yes |

---

## Testing Checklist

### ✅ Phase 1: Simulator (Now Should Work)

- [ ] Clean build
- [ ] Run on iPhone 16 Pro simulator
- [ ] Sign in
- [ ] Check console: "✅ Loaded 1 products"
- [ ] Should see subscription screen
- [ ] Click purchase
- [ ] Should show mock payment UI
- [ ] Should grant access immediately

**Expected Console:**
```
🔄 Loading products: ["com.protip365.premium.monthly"]
✅ Loaded 1 products: ["com.protip365.premium.monthly"]
Product: com.protip365.premium.monthly - ProTip365 Premium - $3.99
```

### ⏳ Phase 2: TestFlight (Next Step)

- [ ] Ensure product exists in App Store Connect
- [ ] Upload build to TestFlight
- [ ] Install on real device
- [ ] Sign out of real Apple ID
- [ ] Launch app with sandbox test account
- [ ] Products should load from App Store Connect
- [ ] Purchase with sandbox account
- [ ] Watch console for sandbox server calls

**Expected Console:**
```
🔵 Trying PRODUCTION server first...
📋 Apple Response Status: 21007
🟡 Production failed, trying SANDBOX server...
🌐 Calling: https://sandbox.itunes.apple.com/verifyReceipt
📋 Apple Response Status: 0
✅ SANDBOX validation successful
```

---

## Why Both Approaches Are Important

### Online Validation (verifyReceipt API)
- ✅ Tests real server communication
- ✅ Tests sandbox/production switching
- ✅ What Apple reviews in TestFlight/Production
- ✅ Required for cross-device subscription sync
- ❌ Requires internet connection
- ❌ Requires product in App Store Connect

### Local StoreKit Configuration
- ✅ Works offline
- ✅ Fast development iteration
- ✅ Tests UI/UX flow
- ✅ No App Store Connect setup needed
- ❌ Doesn't test real server validation
- ❌ Not what Apple reviews

**Our Implementation Uses BOTH:**
- Simulator: Uses .storekit for fast development
- TestFlight/Production: Uses online validation with Apple servers

---

## Next Steps

1. ✅ Scheme is now configured to use `Protip365.storekit`
2. ⏳ Clean build and test in simulator
3. ⏳ Verify products load successfully
4. ⏳ Test purchase flow in simulator
5. ⏳ Upload to TestFlight
6. ⏳ Test with sandbox account on real device

---

## Key Takeaway

**You were right to be concerned!** The app needs to work with:

1. **Simulator**: Uses .storekit file (now fixed)
2. **TestFlight**: Uses sandbox.itunes.apple.com (already implemented)
3. **Production**: Uses buy.itunes.apple.com (already implemented)

All three are now properly configured. The "product not found" error should be gone now that the scheme points to the correct .storekit file.

---

**Author**: Claude
**Date**: 2025-10-01
**Issue Fixed**: Scheme now uses correct StoreKit configuration file
**Next Test**: Run in simulator and verify products load
