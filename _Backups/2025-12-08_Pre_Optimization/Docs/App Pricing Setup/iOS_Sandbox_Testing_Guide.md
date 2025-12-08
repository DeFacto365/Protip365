# iOS Sandbox Testing Guide for ProTip365 Premium

## Overview
This guide walks you through testing the new simplified subscription model ($3.99/month with 7-day trial) in the iOS sandbox environment.

---

## Step 1: Xcode Configuration

### 1.1 Select StoreKit Configuration
1. Open **ProTip365.xcodeproj** in Xcode
2. Select your scheme (ProTip365) from the scheme selector
3. Click **Edit Scheme** (or press ⌘<)
4. Select **Run** from the left sidebar
5. Go to the **Options** tab
6. Under **StoreKit Configuration**, select: `Protip365.storekit`
7. Click **Close**

### 1.2 Verify Product ID in Code
Confirm the SubscriptionManager uses the correct product ID:
```swift
// In SubscriptionManager.swift
private let premiumMonthlyId = "com.protip365.premium.monthly"
```

### 1.3 Build Configuration
1. Select your target device or simulator
2. Ensure you're using **Debug** configuration (not Release)
3. Clean build folder: **Product → Clean Build Folder** (⇧⌘K)

---

## Step 2: Create Sandbox Test Accounts

### 2.1 Access App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access**
3. Select **Sandbox Testers** from the sidebar

### 2.2 Create Test Accounts
Create at least 3 test accounts for different scenarios:

**Account 1: New User (Will See Trial)**
- Email: `protip365.new@test.com`
- Password: `Test1234!`
- First Name: New
- Last Name: User
- Country: United States

**Account 2: Active Subscriber**
- Email: `protip365.active@test.com`
- Password: `Test1234!`
- First Name: Active
- Last Name: Subscriber
- Country: United States

**Account 3: Expired/Cancelled**
- Email: `protip365.expired@test.com`
- Password: `Test1234!`
- First Name: Expired
- Last Name: User
- Country: United States

### 2.3 Important Sandbox Notes
- Sandbox accounts MUST use emails that don't exist in production
- Passwords should be strong but memorable
- Keep track of which test account is in which state

---

## Step 3: Device/Simulator Setup

### 3.1 Sign Out of Production App Store
**On Physical Device:**
1. Go to **Settings → App Store**
2. Tap your Apple ID at the top
3. Scroll down and tap **Sign Out**
4. DO NOT sign in with sandbox account here!

**On Simulator:**
- Simulators are automatically sandboxed, no action needed

### 3.2 Clear Previous Purchases (If Testing Multiple Times)
1. Delete the app from device/simulator
2. In Xcode: **Window → Devices and Simulators**
3. Select your device
4. Find ProTip365 in installed apps
5. Click the gear icon → **Delete App**

---

## Step 4: Testing Scenarios

### Scenario 1: New User - Free Trial Flow

**Steps:**
1. Build and run the app on your device/simulator
2. Sign up with a new account (not sandbox account)
3. Navigate to subscription screen
4. You should see:
   - "7 DAYS FREE" badge
   - "$3.99/month after trial" text
   - "Start Free Trial" button
5. Tap "Start Free Trial"
6. When prompted, sign in with sandbox account: `protip365.new@test.com`
7. Complete the purchase (no charge for trial)
8. Verify:
   - ✅ Subscription is active
   - ✅ Trial badge shows in app
   - ✅ All premium features unlocked
   - ✅ No immediate charge

**Expected Results:**
- Transaction succeeds immediately (sandbox is faster)
- User gains premium access
- Trial status shows "7 days remaining"

### Scenario 2: Trial Expiration

**Sandbox Time Acceleration:**
- Real time: 7 days → Sandbox: ~3 minutes
- Real time: 1 month → Sandbox: ~5 minutes

**Steps:**
1. Complete Scenario 1
2. Wait 3-5 minutes for trial to expire
3. Close and reopen the app
4. Check subscription status
5. Verify:
   - ✅ Trial expired message
   - ✅ Subscription renewed at $3.99
   - ✅ Premium access continues

### Scenario 3: Purchase Without Trial (Existing User)

**Steps:**
1. Use sandbox account that already had trial
2. Navigate to subscription screen
3. You should see:
   - NO trial badge
   - "$3.99/month" price
   - "Subscribe Now" button (not "Start Free Trial")
4. Complete purchase
5. Verify immediate charge

### Scenario 4: Restore Purchases

**Steps:**
1. Delete and reinstall app
2. Sign in with same account
3. Navigate to subscription screen
4. Tap "Restore Purchases"
5. Sign in with sandbox account when prompted
6. Verify:
   - ✅ Subscription restored
   - ✅ Premium features active
   - ✅ Correct status displayed

### Scenario 5: Subscription Cancellation

**Steps:**
1. While subscribed, go to device Settings
2. Tap your name → Subscriptions
3. Find ProTip365 (Sandbox)
4. Tap "Cancel Subscription"
5. Confirm cancellation
6. Return to app
7. Verify:
   - ✅ Subscription still active until period ends
   - ✅ Shows expiration date
   - ✅ Can resubscribe

### Scenario 6: Edge Cases

**Test these situations:**
1. **No Network:** Turn on Airplane Mode, try to purchase
2. **Purchase Interrupted:** Start purchase, force quit app
3. **Multiple Purchases:** Try to purchase while already subscribed
4. **Different Region:** Change device region, check price display
5. **Family Sharing:** If enabled, test with family member account

---

## Step 5: Debugging & Troubleshooting

### 5.1 Enable StoreKit Debug Logging
In Xcode, add to your scheme's environment variables:
- Name: `OS_ACTIVITY_MODE`
- Value: `debug`

### 5.2 Console Logging
Add to SubscriptionManager.swift:
```swift
print("🔄 Loading products: \(allProductIds)")
print("✅ Products loaded: \(products.map { $0.id })")
print("💳 Purchase result: \(result)")
print("📱 Subscription status: \(currentTier)")
```

### 5.3 Common Issues & Solutions

**Issue: "Cannot connect to iTunes Store"**
- Solution: Ensure StoreKit configuration is selected in scheme
- Check internet connection
- Verify bundle ID matches

**Issue: Products not loading**
- Solution: Check product ID matches exactly: `com.protip365.premium.monthly`
- Ensure products are in "Ready to Submit" state
- Wait 24 hours after creating products

**Issue: Trial not showing**
- Solution: Use fresh sandbox account that never purchased
- Clear purchase history in App Store Connect
- Delete and reinstall app

**Issue: Sandbox account won't work**
- Solution: Never sign into Settings → App Store with sandbox
- Only enter sandbox credentials in purchase dialog
- Create new sandbox account if corrupted

---

## Step 6: Transaction Verification

### 6.1 View Transaction History
1. In Xcode: **Debug → StoreKit → Manage Transactions**
2. You'll see all sandbox transactions
3. Can delete transactions to reset state

### 6.2 Check Receipt Validation
Monitor console for receipt validation:
```
✅ Transaction verified
✅ Subscription synced to server
✅ Trial period: true, Days remaining: 7
```

### 6.3 Server Sync Verification
Check Supabase database:
```sql
SELECT * FROM user_subscriptions
WHERE user_id = 'YOUR_USER_ID'
AND product_id = 'com.protip365.premium.monthly';
```

---

## Step 7: Testing Checklist

Before submitting to App Store:

### Functionality Tests
- [ ] New user can start 7-day trial
- [ ] Trial converts to paid after expiration
- [ ] Existing users see correct price (no trial)
- [ ] Restore purchases works
- [ ] Cancellation handled gracefully
- [ ] Resubscribe after cancellation works
- [ ] All premium features unlock correctly
- [ ] Features lock when subscription expires

### UI/UX Tests
- [ ] Correct price displayed: $3.99/month
- [ ] Trial badge shows for eligible users
- [ ] Loading states work properly
- [ ] Error messages are user-friendly
- [ ] Localization works (EN/FR/ES)
- [ ] iPad layout looks correct
- [ ] Dark mode compatible

### Edge Case Tests
- [ ] Offline mode handling
- [ ] Purchase interruption recovery
- [ ] Multiple device sync
- [ ] Region/currency changes
- [ ] Account switching

### Performance Tests
- [ ] Products load quickly
- [ ] Purchase completes in reasonable time
- [ ] No memory leaks
- [ ] Smooth UI transitions

---

## Step 8: Clean Up After Testing

### 8.1 Reset for Production
1. Delete sandbox test app
2. Sign out of sandbox accounts
3. Clear Keychain if needed:
   ```bash
   security delete-generic-password -s "ProTip365"
   ```
4. Switch scheme back to Release configuration

### 8.2 Document Results
Keep a log of:
- Test date and time
- Xcode version
- iOS version tested
- Issues found
- Screenshots of key flows

---

## Sandbox vs Production Differences

| Feature | Sandbox | Production |
|---------|---------|------------|
| Trial Period | 3 minutes | 7 days |
| Monthly Renewal | 5 minutes | 1 month |
| Purchase Speed | Instant | 1-2 seconds |
| Receipt Validation | Test server | Production server |
| Subscription Management | Settings → Sandbox | Settings → Subscriptions |
| Transaction Clear | Can delete | Permanent |

---

## Important Reminders

1. **NEVER** use production Apple ID in sandbox
2. **ALWAYS** use the StoreKit configuration file for testing
3. **DOCUMENT** any issues for App Review notes
4. **TEST** on multiple iOS versions (iOS 15+)
5. **VERIFY** server-side subscription sync

---

## Support Resources

- [StoreKit Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-in-app-purchases-in-xcode)
- [Sandbox Testing Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [Receipt Validation](https://developer.apple.com/documentation/appstorereceipts)

---

## Contact for Issues

If you encounter issues during testing:
1. Check Apple Developer Forums
2. File a Technical Support Incident (TSI) if needed
3. Review App Store Connect diagnostics

---

*Last Updated: December 2024*
*StoreKit 2 Configuration for iOS 15+*