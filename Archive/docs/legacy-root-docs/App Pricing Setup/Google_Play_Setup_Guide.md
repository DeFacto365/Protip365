# Google Play Console Pricing Setup Guide for ProTip365

## Overview
ProTip365 will have a single subscription tier:
- **7-day free trial**
- **$3.99/month** after trial
- **Single tier** (no more Part-Time vs Full Access)

---

## Step 1: Google Play Console - Initial Setup

### 1.1 Access Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google Developer account
3. Select your app: **ProTip365**
4. Navigate to **Monetize** → **Products** → **Subscriptions**

### 1.2 Remove/Archive Existing Products (if any)
1. Click on each existing subscription
2. Select **Archive** for all old tiers:
   - Part-Time Monthly
   - Part-Time Annual
   - Full Access Monthly
   - Full Access Annual
3. Confirm archival (Note: Cannot delete, only archive)

---

## Step 2: Create New Subscription Product

### 2.1 Create Subscription
1. Click **Create subscription**
2. Fill in the following:

**Product ID:** `protip365_premium_monthly`
*(Note: Cannot contain uppercase or spaces, must be unique)*

**Name:** `ProTip365 Premium`

**Description:** `Unlock all features with ProTip365 Premium`

3. Click **Create**

### 2.2 Configure Subscription Details

#### Basic Information:
- **Default language:** English (United States)
- **Subscription benefits:**
  ```
  • Unlimited shift tracking
  • Multiple employers support
  • Advanced analytics & insights
  • Data export (CSV)
  • Priority support
  • All future premium features
  ```

#### Billing Period:
- Select: **Monthly**
- Auto-renewing: **Yes**

---

## Step 3: Set Up Pricing

### 3.1 Base Price Configuration
1. Click **Add base plan**
2. **Base plan ID:** `monthly`
3. **Renewal type:** Auto-renewing
4. **Billing period:** Monthly
5. Click **Save**

### 3.2 Set Regional Pricing
1. Click **Set prices**
2. **Default price (USD):** $3.99
3. Click **Review other prices**
4. Review auto-converted prices for other countries
5. Adjust if needed for specific markets
6. Click **Update prices**

### 3.3 Important Regional Considerations
- EU prices must include VAT
- Consider purchasing power parity for emerging markets
- Round to logical price points (e.g., €3.99, £3.49)

---

## Step 4: Configure Free Trial

### 4.1 Add Offer
1. In your subscription, click **Add offer**
2. **Offer ID:** `freetrial7days`
3. **Eligibility:** New customers only
4. Click **Create**

### 4.2 Configure Trial Phase
1. **Offer type:** Free trial
2. **Duration:** 7 days
3. **Number of billing periods:** 1
4. **Regional availability:** All regions
5. Click **Save**

### 4.3 Activation
1. Set **Start time:** Immediately
2. **End time:** No end time
3. **Promo code:** Not required
4. Click **Activate**

---

## Step 5: Google Play Billing Library Integration

### 5.1 Update Dependencies
In `ProTip365Android/app/build.gradle.kts`:
```kotlin
dependencies {
    implementation("com.android.billingclient:billing-ktx:6.1.0")
    implementation("com.google.accompanist:accompanist-permissions:0.32.0")
}
```

### 5.2 Add Billing Permission
In `ProTip365Android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### 5.3 Create BillingManager
Create a new file with billing implementation that:
- Connects to Google Play
- Queries available products
- Handles purchase flow
- Verifies purchases
- Manages subscription state

---

## Step 6: Store Listing Updates

### 6.1 Update App Description
Add subscription information:
```
Subscription Details:
• 7-day FREE trial for new users
• $3.99/month after trial ends
• Cancel anytime in Google Play subscriptions
• Subscription auto-renews monthly
• Payment charged to Google Play account
```

### 6.2 Required Disclosures
1. Go to **Policy** → **App content**
2. Update **Data safety** section
3. Declare that you collect purchase history
4. Update financial info collection

### 6.3 Screenshots
Update screenshots if they show pricing to reflect new single tier

---

## Step 7: Testing Configuration

### 7.1 Set Up License Testing
1. Go to **Setup** → **License testing**
2. Add tester email addresses:
   - Your development team emails
   - QA tester emails
3. Set **License response:** RESPOND_NORMALLY

### 7.2 Create Test Tracks
1. Go to **Testing** → **Internal testing**
2. Create a new release with subscription changes
3. Add testers to internal track
4. Share testing link

### 7.3 Testing Scenarios

#### Test Account Types:
1. **New User:**
   - Verify 7-day trial appears
   - Complete subscription flow
   - Verify no immediate charge

2. **Active Subscriber:**
   - Verify continued access
   - Check renewal flow

3. **Cancelled Subscription:**
   - Verify grace period
   - Test resubscription

### 7.4 Sandbox Testing Speed
Google Play sandbox accelerates subscription periods:
- Monthly = renews every 5 minutes
- Trial = 3 minutes

---

## Step 8: Code Implementation

### 8.1 Update Product Configuration
In `ProTip365Android/app/src/main/java/com/protip365/app/utils/Constants.kt`:
```kotlin
object SubscriptionConfig {
    const val PRODUCT_ID = "protip365_premium_monthly"
    const val OFFER_ID = "freetrial7days"
    const val TRIAL_DAYS = 7
    const val MONTHLY_PRICE = "$3.99"
}
```

### 8.2 Simplify Subscription Logic
Remove all tier checking code:
```kotlin
// Before:
if (subscriptionTier == "part_time") {
    limitShifts()
}

// After: All features available with subscription
if (hasActiveSubscription) {
    // Full access to all features
}
```

### 8.3 Update UI Components
- Remove tier selection screens
- Show single subscription option
- Display trial information prominently
- Update all subscription-related strings

---

## Step 9: Play Console Settings

### 9.1 Payments Profile
1. Go to **Setup** → **Payments profile**
2. Verify bank account information
3. Set up tax information if needed
4. Configure payout schedule

### 9.2 Pricing Templates (Optional)
1. Go to **Monetize** → **Pricing templates**
2. Create template: "Standard Monthly - $3.99"
3. Use for consistent pricing across products

### 9.3 Subscription Settings
1. **Grace period:** Enable 7 days for payment recovery
2. **Account hold:** 30 days maximum
3. **Restore:** Allow restore purchases
4. **Upgrade/Downgrade:** Not applicable (single tier)

---

## Step 10: Compliance Requirements

### 10.1 Subscription Terms
Include in app and store listing:
```
Terms & Conditions:
• Free trial available to new subscribers only
• Subscription automatically renews unless turned off 24 hours before period ends
• Manage or cancel in Google Play Store → Subscriptions
• No refund for unused portion when cancelling
• Price subject to change with notice
```

### 10.2 Required Links
Provide accessible links to:
- Privacy Policy: `https://www.protip365.com/privacy`
- Terms of Service: `https://www.protip365.com/terms`

### 10.3 GDPR Compliance (EU)
- Obtain explicit consent for data processing
- Provide data deletion options
- Include cookie policy if applicable

---

## Step 11: Pre-Launch Checklist

### Configuration:
- [ ] Single subscription product created
- [ ] Price set to $3.99/month
- [ ] 7-day free trial configured
- [ ] Old products archived
- [ ] Regional pricing reviewed

### Implementation:
- [ ] Billing library integrated
- [ ] Product ID updated in code
- [ ] Tier logic removed
- [ ] UI updated for single tier
- [ ] Purchase flow tested

### Store Listing:
- [ ] Description updated with pricing
- [ ] Screenshots current
- [ ] Privacy policy linked
- [ ] Terms of service linked
- [ ] Data safety section updated

### Testing:
- [ ] Internal testing track created
- [ ] License testers added
- [ ] Trial flow tested
- [ ] Renewal tested
- [ ] Cancellation tested

---

## Step 12: Launch Process

### 12.1 Staged Rollout
1. Start with 10% of users
2. Monitor for 48 hours
3. Check metrics:
   - Crash rate
   - Purchase completion rate
   - Trial conversion
4. Gradually increase to 100%

### 12.2 Monitor Key Metrics
- Trial start rate
- Trial conversion rate
- First renewal rate
- Churn rate
- Average revenue per user (ARPU)

### 12.3 User Communication
- In-app announcement about simplified pricing
- Email to existing users
- Update website pricing page
- Social media announcement

---

## Step 13: Post-Launch Optimization

### 13.1 A/B Testing (Future)
Consider testing:
- Trial length (7 vs 14 days)
- Price points ($2.99 vs $3.99 vs $4.99)
- Onboarding flow
- Paywall design

### 13.2 Promotional Campaigns
- Seasonal discounts (via promo codes)
- Win-back offers for churned users
- Referral programs

### 13.3 Retention Strategies
- Grace period for failed payments
- Pause subscription option
- Engagement campaigns

---

## Important Notes

1. **Migration:** Existing subscribers at different prices will maintain their current rate
2. **Grandfathering:** Consider honoring old prices for loyal users
3. **Refunds:** Have a clear refund policy (Google Play allows 48-hour window)
4. **Taxes:** Prices shown are before applicable taxes
5. **Currency:** Google handles currency conversion automatically

---

## Troubleshooting

### Common Issues:

**Problem:** Free trial not showing
- **Solution:** Verify offer configuration and eligibility settings

**Problem:** Purchase fails
- **Solution:** Check product ID matches exactly, verify billing permissions

**Problem:** Subscription not recognized
- **Solution:** Implement proper purchase verification and restore functionality

**Problem:** Price showing incorrectly
- **Solution:** Clear Play Store cache, check regional settings

---

## Support Resources

- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Billing Library Samples](https://github.com/android/play-billing-samples)
- [Subscription Best Practices](https://developer.android.com/google/play/billing/subscriptions)

---

## Contact Information

For technical issues:
- Google Play Developer Support: Available in Play Console
- Stack Overflow: Tag with `google-play-billing`
- Reddit: r/androiddev

---

*Last Updated: December 2024*
*Version: 1.0*