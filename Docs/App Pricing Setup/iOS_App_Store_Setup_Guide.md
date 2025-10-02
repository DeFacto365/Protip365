# iOS App Store Pricing Setup Guide for ProTip365

## Overview
ProTip365 will have a single subscription tier:
- **7-day free trial**
- **$3.99/month** after trial
- **Single tier** (no more Part-Time vs Full Access)

---

## Step 1: App Store Connect - Product Setup

### 1.1 Access App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Select your app: **ProTip365**
4. Navigate to **Monetization** → **Subscriptions**

### 1.2 Remove Existing Products (if any)
1. Click on each existing subscription product
2. Select **Remove from Sale** for all old tiers:
   - Part-Time Monthly ($2.99)
   - Part-Time Annual ($30)
   - Full Access Monthly ($4.99)
   - Full Access Annual ($49.99)
3. Wait for status to change to "Removed from Sale"

### 1.3 Create New Subscription Group
1. Click **Create** under Subscription Groups
2. Name: `ProTip365 Premium`
3. Click **Create**

### 1.4 Create Single Subscription Product
1. Inside the subscription group, click **Create**
2. Fill in the following details:

**Reference Name:** `ProTip365 Premium Monthly`
**Product ID:** `com.protip365.premium.monthly`
**Duration:** 1 Month
**Price:** $3.99 USD

3. Click **Create**

### 1.5 Set Up Pricing
1. Click on **Pricing** for your subscription
2. Select **USD - United States** as base territory
3. Enter: **$3.99**
4. Click **Next**
5. Review automatic pricing for other territories
6. Click **Confirm**

### 1.6 Configure Free Trial
1. Go to **Subscription Prices**
2. Click **Set Up Introductory Offer**
3. Select **Free Trial**
4. Duration: **7 days**
5. Territories: **All Territories**
6. Click **Confirm**

### 1.7 Add Localization
1. Click **App Store Localization**
2. Add for each language (EN, FR, ES):

**English:**
- Display Name: `ProTip365 Premium`
- Description: `Unlock all features: unlimited shifts, multiple employers, advanced analytics, and data export`

**French:**
- Display Name: `ProTip365 Premium`
- Description: `Débloquez toutes les fonctionnalités: shifts illimités, employeurs multiples, analyses avancées et export de données`

**Spanish:**
- Display Name: `ProTip365 Premium`
- Description: `Desbloquea todas las funciones: turnos ilimitados, múltiples empleadores, análisis avanzados y exportación de datos`

---

## Step 2: Review Guidelines Compliance

### 2.1 Subscription Description
Update your app description to clearly state:
```
Subscription Information:
• 7-day free trial for new users
• $3.99/month after trial
• Payment will be charged to iTunes Account at confirmation of purchase
• Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period
• Account will be charged for renewal within 24-hours prior to the end of the current period
• Subscriptions may be managed by the user and auto-renewal may be turned off by going to the user's Account Settings after purchase
```

### 2.2 Required Links
Ensure these are accessible from within the app:
- Privacy Policy: `https://www.protip365.com/privacy`
- Terms of Service: `https://www.protip365.com/terms`

---

## Step 3: StoreKit Configuration File

### 3.1 Update StoreKit Configuration
In Xcode, update your `Protip365.storekit` file:

```json
{
  "identifier": "com.protip365.storekit",
  "displayName": "ProTip365",
  "products": [
    {
      "id": "com.protip365.premium.monthly",
      "type": "autoRenewable",
      "displayName": "ProTip365 Premium",
      "description": "Unlock all features",
      "price": 3.99,
      "subscriptionGroupID": "ProTip365Premium",
      "subscriptionPeriod": {
        "value": 1,
        "unit": "month"
      },
      "introductoryOffer": {
        "type": "freeTrial",
        "period": {
          "value": 7,
          "unit": "day"
        }
      }
    }
  ],
  "subscriptionGroups": [
    {
      "id": "ProTip365Premium",
      "displayName": "ProTip365 Premium"
    }
  ]
}
```

---

## Step 4: Code Implementation

### 4.1 Update Product IDs
In `ProTip365/Subscription/SubscriptionManager.swift`, update:
```swift
private let productIds = ["com.protip365.premium.monthly"]
```

### 4.2 Simplify Subscription Logic
Remove all Part-Time vs Full Access logic. All users get full features after subscribing.

### 4.3 Update UI
- Remove tier selection screens
- Show single subscription option with trial information
- Update all subscription-related text

---

## Step 5: Testing

### 5.1 Sandbox Testing Setup
1. In App Store Connect, go to **Users and Access**
2. Navigate to **Sandbox Testers**
3. Create test accounts for:
   - New user (will see trial)
   - Existing subscriber
   - Expired subscription

### 5.2 Test Scenarios
1. **New User Flow:**
   - Install app fresh
   - Verify 7-day trial appears
   - Complete subscription
   - Verify no charge during trial

2. **Renewal:**
   - Fast-forward sandbox time
   - Verify renewal at $3.99

3. **Cancellation:**
   - Cancel subscription
   - Verify access until period ends

---

## Step 6: Submission Checklist

### Before Submitting:
- [ ] Single product configured at $3.99/month
- [ ] 7-day free trial active for all territories
- [ ] Old products removed from sale
- [ ] App description updated with subscription info
- [ ] Privacy Policy and Terms of Service links working
- [ ] StoreKit configuration updated
- [ ] Code updated to use new product ID
- [ ] All tier-specific logic removed
- [ ] Tested in sandbox environment
- [ ] Screenshots updated if needed

### App Review Notes:
Include in your review notes:
```
We have simplified our subscription model to a single tier:
- 7-day free trial for all new users
- $3.99/month after trial
- All features included (no more tier restrictions)
This change improves user experience and reduces complexity.
```

---

## Step 7: Post-Launch Monitoring

### 7.1 Monitor Metrics
- Trial conversion rate
- Monthly retention
- Cancellation reasons
- Revenue per user

### 7.2 Customer Communication
- Email existing subscribers about simplified pricing
- Update website with new pricing
- Update in-app messaging

---

## Important Notes

1. **Grace Period:** Consider enabling grace period for failed payments (Settings → Manage → Grace Period)
2. **Promotional Offers:** Can be added later for win-back campaigns
3. **Family Sharing:** Consider enabling for better value proposition
4. **Price Changes:** Existing subscribers at higher prices will continue at their current rate unless they cancel and resubscribe

---

## Support Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)

---

*Last Updated: December 2024*
*Version: 1.0*