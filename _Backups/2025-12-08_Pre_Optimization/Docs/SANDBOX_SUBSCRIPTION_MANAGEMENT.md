# Sandbox Subscription Management Guide

## Overview

This guide explains how to manage and clear sandbox subscriptions during testing, and addresses common issues with subscription cancellation in the sandbox environment.

---

## The Problem You Experienced

### Why "Cancel Free Trial" Did Nothing

When you clicked "Cancel Free Trial" in the app, nothing happened because:

1. **Bug in v1.1.36**: The button was opening iOS Settings app instead of App Store subscriptions page
2. **Sandbox Limitation**: Even with the correct link, sandbox subscriptions can't be managed through the normal App Store interface
3. **No Feedback**: The app didn't indicate the button was broken

### Fixed in v1.1.37

The "Cancel Subscription" button now correctly opens:
- **Production**: Opens App Store → Account → Subscriptions
- **Sandbox**: Opens the same page, but you'll need to use Xcode for sandbox management

---

## Understanding Sandbox Subscriptions

### Key Differences from Production

| Aspect | Production | Sandbox |
|--------|-----------|---------|
| **Trial Duration** | 7 days | ~3 minutes |
| **Monthly Billing** | 30 days | ~5 minutes |
| **Annual Billing** | 365 days | ~1 hour |
| **Cancellation** | Via App Store | Via Xcode Transaction Manager |
| **Refunds** | Contact Apple | Automatic (no real money) |
| **Auto-Renewal** | Real charges | Simulated (6 renewals max) |

### Sandbox Subscription Lifecycle

```
New User Purchase → Trial (3 min) → Renewal 1 (5 min) → Renewal 2 (5 min)
→ Renewal 3 (5 min) → Renewal 4 (5 min) → Renewal 5 (5 min)
→ Renewal 6 (5 min) → Expires
```

After 6 renewals (~30 minutes total), the subscription automatically expires.

---

## Method 1: Clear Sandbox Subscriptions via Xcode (Recommended)

### Using StoreKit Transaction Manager

**Steps:**

1. **Open Xcode**
2. **Window → Devices and Simulators** (or ⇧⌘2)
3. Select your device/simulator
4. Click **"Manage Transactions"** button (at bottom)
5. You'll see all sandbox transactions:
   ```
   Transaction ID: 2000000123456789
   Product: com.protip365.premium.monthly
   Status: Subscribed
   Purchase Date: [timestamp]
   ```
6. **Select the subscription transaction**
7. Click **"Delete Transaction"** button
8. The subscription is immediately cleared

### Alternative: StoreKit Configuration File

If using StoreKit testing (not sandbox):

1. **Xcode → Debug → StoreKit → Manage Transactions**
2. Or press: **Debug → Clear Transaction History**
3. All test transactions are cleared instantly

---

## Method 2: Delete App & Reinstall

### Quick Clear Method

**On Device:**
1. Long-press ProTip365 app icon
2. Select "Remove App" → "Delete App"
3. Rebuild and reinstall from Xcode

**On Simulator:**
1. **Xcode → Window → Devices and Simulators**
2. Select simulator
3. Find ProTip365 in installed apps
4. Click gear icon → **Delete App**
5. Rebuild and reinstall

**What This Clears:**
- ✅ All sandbox subscriptions
- ✅ Local app data
- ✅ Keychain entries
- ✅ User preferences
- ❌ Does NOT clear: Supabase database entries

---

## Method 3: Sign Out of Sandbox Test Account

### Device Sandbox Account Management

**To Sign Out:**
1. Go to **Settings → App Store**
2. Scroll to **"Sandbox Account"** section
3. Tap your sandbox email
4. Select **"Sign Out"**

**To Sign In:**
1. Launch ProTip365
2. Tap "Subscribe" or "Start Free Trial"
3. When prompted, sign in with sandbox account
4. DO NOT sign in via Settings app

**Note:** Signing out doesn't cancel subscriptions, but prevents the app from detecting them.

---

## Method 4: Database-Level Management

### Direct Supabase Database Access

For server-side subscription management:

```sql
-- View all subscriptions for a user
SELECT * FROM user_subscriptions
WHERE user_id = '[your-user-uuid]';

-- Clear a specific subscription
DELETE FROM user_subscriptions
WHERE user_id = '[your-user-uuid]'
AND transaction_id = '[sandbox-transaction-id]';

-- Clear ALL sandbox subscriptions
DELETE FROM user_subscriptions
WHERE environment = 'sandbox';

-- Update subscription to expired
UPDATE user_subscriptions
SET status = 'expired',
    expires_at = NOW() - INTERVAL '1 day'
WHERE user_id = '[your-user-uuid]';
```

---

## Testing Cancellation Flows

### Production Cancellation (Real Users)

**How Users Cancel:**
1. Open ProTip365 app
2. Go to **Settings → Account**
3. Tap **"Cancel Subscription"** button
4. App opens: **App Store → Account → Subscriptions**
5. User selects ProTip365 Premium
6. Taps **"Cancel Subscription"**
7. Confirms cancellation

**App Behavior:**
- User retains access until expiration date
- App shows "Expires on [date]" message
- At expiration, premium features are locked
- Database status updated via App Store Server Notifications

### Sandbox Cancellation (Testing)

**Option 1: Manual Database Update**
```swift
// In SubscriptionManager.swift (add for testing only)
#if DEBUG
func simulateCancellation() async {
    guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }

    let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

    try? await SupabaseManager.shared.client
        .from("user_subscriptions")
        .update([
            "status": "active", // Still active
            "will_renew": false, // But won't renew
            "expires_at": expiresAt.ISO8601Format()
        ])
        .eq("user_id", userId)
        .execute()

    print("✅ Simulated cancellation - subscription expires in 7 days")
}
#endif
```

**Option 2: Use Xcode Transaction Manager**
1. Open Transaction Manager (see Method 1)
2. Select the subscription
3. Change status to "Cancelled"
4. Subscription will expire at next billing date

---

## Troubleshooting

### Issue: "Cancel Subscription" Button Does Nothing

**Cause:** iOS didn't open the URL (rare bug)

**Solutions:**
1. Force quit the app and try again
2. Check if you're in sandbox mode (Settings → App Store → Sandbox Account)
3. Manually open: **Settings → App Store → [Your Apple ID] → Subscriptions**

### Issue: Subscription Re-Appears After Deleting

**Cause:** Sandbox auto-renewal is very aggressive

**Solutions:**
1. Sign out of sandbox account in Settings
2. Delete app AND sandbox test account data
3. Use a different sandbox test account

### Issue: Can't Access Subscription Settings

**Cause:** Not signed into sandbox account

**Solutions:**
1. Launch ProTip365
2. Trigger a purchase flow
3. Sign in with sandbox credentials when prompted
4. Then access subscription settings

### Issue: Subscription Shows in Database But Not in App

**Cause:** Sync issue between StoreKit and database

**Solutions:**
```swift
// Force refresh subscription status
Task {
    await subscriptionManager.checkSubscriptionStatus()
    await subscriptionManager.refreshSubscriptionStatus()
}
```

---

## Best Practices for Testing

### Test Account Organization

Create multiple sandbox accounts for different scenarios:

```
protip365.newtrial@test.com     - Fresh account, never subscribed
protip365.active@test.com       - Active subscription
protip365.expired@test.com      - Expired subscription
protip365.cancelled@test.com    - Cancelled (expires soon)
protip365.lapsed@test.com       - Lapsed (expired months ago)
```

### Testing Checklist

- [ ] New user starts free trial
- [ ] Trial converts to paid after 3 minutes (sandbox)
- [ ] Active subscription grants premium access
- [ ] "Restore Purchases" finds existing subscription
- [ ] "Cancel Subscription" opens App Store
- [ ] Cancelled subscription expires correctly
- [ ] Expired subscription removes premium access
- [ ] Re-subscription after cancellation works

### Clean Testing Procedure

**Between Test Runs:**
1. Delete app from device/simulator
2. Clear Transaction Manager (Xcode)
3. Clean database: `DELETE FROM user_subscriptions WHERE environment = 'sandbox'`
4. Rebuild and reinstall app
5. Sign in with fresh sandbox account

---

## App Store Connect Management

### Viewing Sandbox Test Purchases

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **Users and Access → Sandbox Testers**
3. Select a test account
4. View purchase history (limited info)

**Note:** Sandbox transactions are NOT visible in Sales & Trends reports.

---

## Summary

### Current Status (v1.1.37)

✅ **Fixed:** "Cancel Subscription" button now opens correct URL
✅ **Works in Production:** Users can cancel via App Store
⚠️ **Sandbox Limitation:** Must use Xcode Transaction Manager

### To Clear Sandbox Subscriptions:

**Quick Method:**
1. Xcode → Window → Devices and Simulators
2. Manage Transactions → Delete Transaction

**Thorough Method:**
1. Delete app
2. Clear Transaction Manager
3. Clean database
4. Use fresh sandbox account

### Production Cancellation:

Users cancel through:
- App → Settings → Cancel Subscription → App Store → Subscriptions

Server detects cancellation via:
- App Store Server Notifications v2 (future implementation)
- Manual status checks during app launches

---

## Future Improvements

### Planned Enhancements

1. **In-App Cancellation Feedback**
   - Show success message after opening App Store
   - Add "Cancellation confirmed" banner when app detects it

2. **App Store Server Notifications**
   - Real-time cancellation detection
   - Automatic database status updates
   - No need for manual checks

3. **Cancellation Survey**
   - Ask why user is cancelling
   - Offer alternatives (pause subscription)
   - Improve retention

4. **Better Sandbox Experience**
   - Add DEBUG-only "Force Cancel" button
   - Simulate cancellation for testing
   - Clear sandbox data within app

---

**Last Updated:** 2025-10-02
**Version:** v1.1.37
**Status:** Cancel button fixed, sandbox management documented
