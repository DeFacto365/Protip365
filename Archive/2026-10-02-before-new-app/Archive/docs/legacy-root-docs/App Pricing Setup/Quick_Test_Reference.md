# ProTip365 Subscription Testing - Quick Reference

## 🚀 Quick Setup

### 1. Xcode Settings
```
Edit Scheme → Run → Options → StoreKit Configuration: Protip365.storekit
```

### 2. Product Details
- **Product ID:** `com.protip365.premium.monthly`
- **Price:** $3.99/month
- **Trial:** 7 days free
- **Localization:** EN, FR, ES

### 3. Test Accounts Setup
```
Email: protip365.test1@test.com
Pass: Test1234!
Purpose: New user (will see trial)
```

---

## ⚡ Quick Test Flows

### Test 1: Free Trial (2 min)
1. Fresh install → Sign up
2. Go to Settings → Subscription
3. Tap "Start Free Trial"
4. Sign in with sandbox account
5. ✅ Should see "Trial - 7 days remaining"

### Test 2: Restore Purchase (1 min)
1. Delete app → Reinstall
2. Sign in same account
3. Settings → Subscription → Restore
4. ✅ Should restore premium access

### Test 3: Cancel & Resubscribe (3 min)
1. Settings (iOS) → Subscriptions → Cancel
2. Return to app
3. Wait 5 min (sandbox renewal)
4. Resubscribe from app
5. ✅ Should charge $3.99 (no trial)

---

## 🕐 Sandbox Time Scale

| Real Time | Sandbox Time |
|-----------|--------------|
| 7 days (trial) | 3 minutes |
| 1 month | 5 minutes |
| 1 year | 1 hour |

---

## 🐛 Common Issues & Fixes

### "Cannot Connect to iTunes"
```bash
# Fix: Select StoreKit config in scheme
Edit Scheme → Run → Options → StoreKit Configuration
```

### Products Not Loading
```swift
// Check product ID matches exactly:
"com.protip365.premium.monthly"  // ✅ Correct
"com.protip365.premium.Monthly"  // ❌ Wrong (capital M)
```

### Trial Not Showing
- Use NEW sandbox account
- Never used for ProTip365 before
- Delete app & reinstall

### Sandbox Account Issues
- NEVER sign into Settings → App Store
- ONLY use in purchase dialog
- Create new account if broken

---

## 📱 Debug Console Commands

### In SubscriptionManager.swift
```swift
// Add these for debugging:
print("🔄 Loading products: \(allProductIds)")
print("✅ Product found: \(product.id)")
print("💳 Purchase state: \(result)")
print("📱 Tier: \(currentTier)")
print("⏰ Trial: \(isInTrialPeriod)")
```

### View Transactions (Xcode)
```
Debug → StoreKit → Manage Transactions
```

### Clear Purchase History
```
1. Delete app from device
2. In Manage Transactions → Delete all
3. Reinstall app
```

---

## ✅ Pre-Submission Checklist

**Must Test:**
- [ ] New user → 7-day trial starts
- [ ] Trial badge shows correctly
- [ ] After 3 min → Subscription renews
- [ ] Restore purchases works
- [ ] Cancel → Still active until expiry
- [ ] Resubscribe → No trial, $3.99 charge
- [ ] All features unlock with subscription
- [ ] French & Spanish text correct

**Edge Cases:**
- [ ] No network → Error message
- [ ] Already subscribed → Can't purchase again
- [ ] Force quit during purchase → Recovers

---

## 📊 What to Log for App Review

Include in App Review Notes:
```
Subscription Model:
- Single tier: ProTip365 Premium
- Price: $3.99/month
- Free trial: 7 days for new users
- Product ID: com.protip365.premium.monthly

Test Account:
Email: [provide sandbox email]
Password: [provide password]

The app offers a 7-day free trial. After trial,
users are charged $3.99/month. All features are
included - no limitations.
```

---

## 🆘 Emergency Fixes

### Reset Everything
```bash
# 1. Delete app
# 2. Clear Keychain
security delete-generic-password -s "ProTip365"
# 3. Create new sandbox account
# 4. Reinstall app
```

### Force Sync from App Store
```swift
// In SubscriptionManager
await Transaction.currentEntitlements
await checkSubscriptionStatus()
```

### Manual Receipt Refresh
```swift
// Force receipt refresh
SKReceiptRefreshRequest().start()
```

---

## 📞 Quick Support

**Can't resolve?**
1. Screenshot Xcode console
2. Note exact error message
3. Check transaction history
4. Try with different sandbox account

**Still stuck?**
- Apple Developer Forums
- Technical Support Incident (TSI)
- Stack Overflow: tag `storekit2`

---

*Keep this card handy during testing!*