# Google Play Console Subscription Configuration Guide

This guide will help you set up subscriptions for ProTip365 in the Google Play Console.

## Prerequisites
- Google Play Developer account
- App published or in internal testing track
- Merchant account linked to Play Console

## Product IDs Used in App
The app is configured to use these product IDs:
- `com.protip365.parttime.monthly` - Part-time Monthly ($2.99)
- `com.protip365.parttime.annual` - Part-time Annual ($29.99)
- `com.protip365.monthly` - Full Access Monthly ($4.99)
- `com.protip365.annual` - Full Access Annual ($49.99)

## Step-by-Step Setup

### 1. Access Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your ProTip365 app
3. Navigate to **Monetization** > **Subscriptions**

### 2. Create Part-Time Monthly Subscription
1. Click **Create subscription**
2. Enter details:
   - **Product ID**: `com.protip365.parttime.monthly`
   - **Name**: ProTip365 Part-Time (Monthly)
   - **Description**: Perfect for part-time workers - Track up to 3 shifts and 10 entries per week
   - **Billing period**: Monthly
   - **Price**: $2.99 USD (adjust for other regions)

3. Benefits to highlight:
   - 3 shifts per week
   - 10 entries per week
   - Basic analytics
   - Export data (CSV)
   - Multiple employers support

4. **Grace period**: 7 days (recommended)
5. **Free trial**: Optional - 7 days recommended

### 3. Create Part-Time Annual Subscription
1. Click **Create subscription**
2. Enter details:
   - **Product ID**: `com.protip365.parttime.annual`
   - **Name**: ProTip365 Part-Time (Annual)
   - **Description**: Best value for part-time workers - Save $5.88 per year!
   - **Billing period**: Annual
   - **Price**: $29.99 USD (save ~17%)

3. Use same benefits as monthly

### 4. Create Full Access Monthly Subscription
1. Click **Create subscription**
2. Enter details:
   - **Product ID**: `com.protip365.monthly`
   - **Name**: ProTip365 Full Access (Monthly)
   - **Description**: Unlimited tracking for full-time professionals
   - **Billing period**: Monthly
   - **Price**: $4.99 USD

3. Benefits to highlight:
   - Unlimited shifts
   - Unlimited entries
   - Advanced analytics & trends
   - Priority support
   - PDF & Excel exports
   - Custom categories
   - Cloud backup
   - Achievement system

4. **Grace period**: 7 days
5. **Free trial**: 14 days recommended (longer for premium tier)

### 5. Create Full Access Annual Subscription
1. Click **Create subscription**
2. Enter details:
   - **Product ID**: `com.protip365.annual`
   - **Name**: ProTip365 Full Access (Annual)
   - **Description**: Best value for professionals - Save $9.88 per year!
   - **Billing period**: Annual
   - **Price**: $49.99 USD (save ~17%)

3. Use same benefits as monthly

### 6. Configure Base Plans
For each subscription:
1. Click on the subscription
2. Add a **Base plan**:
   - Auto-renewing
   - Set regional pricing
   - Configure proration mode: IMMEDIATE_WITH_TIME_PRORATION

### 7. Add Special Offers (Optional)
Consider adding:
- **Free trial**: 7 days for Part-Time, 14 days for Full Access
- **Introductory pricing**: First month at 50% off
- **Win-back offers**: For churned users

### 8. Testing Setup
1. Create a **License testing** group:
   - Go to **Setup** > **License testing**
   - Add test email addresses
   - These accounts won't be charged

2. Upload signed APK/AAB to testing track:
   - Internal testing recommended for initial tests
   - Ensure version code matches production

### 9. Supabase Database Setup
The `user_subscriptions` table is already configured in your database with the following schema:

```sql
CREATE TABLE public.user_subscriptions (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NULL,
    product_id TEXT NULL,
    status TEXT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NULL,
    transaction_id TEXT NULL,
    purchase_date TIMESTAMP WITH TIME ZONE NULL,
    environment TEXT NULL,
    created_at TIMESTAMP WITH TIME ZONE NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NULL DEFAULT NOW(),
    CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id),
    CONSTRAINT user_subscriptions_user_id_key UNIQUE (user_id),
    CONSTRAINT user_subscriptions_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT user_subscriptions_environment_check CHECK (
        environment = ANY(ARRAY['sandbox'::text, 'production'::text])
    ),
    CONSTRAINT user_subscriptions_status_check CHECK (
        status = ANY(ARRAY['active'::text, 'expired'::text, 'cancelled'::text])
    )
);

-- Existing indexes
CREATE INDEX idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX idx_user_subscriptions_expires_at ON public.user_subscriptions(expires_at);
```

**Important Database Constraints:**
- **UNIQUE on `user_id`**: Each user can only have ONE subscription record
  - When upgrading/downgrading, UPDATE the existing record (don't INSERT new)
  - Use UPSERT operations to handle this automatically
- **Status values**: Must be 'active', 'expired', or 'cancelled'
  - 'active' - Subscription is current and paid
  - 'expired' - Past expiration date or payment failed
  - 'cancelled' - User cancelled but may still have access until expiry
- **Environment values**: Must be 'sandbox' or 'production'
  - 'sandbox' - Test purchases and trials
  - 'production' - Real purchases from Play Store
- All fields except `id` are nullable to handle various subscription states

### 10. Environment Variables
Add to your app's build configuration:

```kotlin
// In app/build.gradle.kts
android {
    defaultConfig {
        // For debug builds
        buildConfigField("String", "GOOGLE_PLAY_LICENSE_KEY", "\"YOUR_LICENSE_KEY_HERE\"")
    }
}
```

Get your license key from:
**Play Console** > **Monetization setup** > **Licensing**

### 11. Required Permissions
Ensure AndroidManifest.xml includes:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 12. Post-Setup Testing
1. Install app via testing track URL
2. Test purchase flow for each subscription
3. Verify subscription status syncs with Supabase
4. Test upgrade/downgrade between tiers
5. Test cancellation and grace period
6. Test restoration on app reinstall

## Subscription Tiers Logic

### Free Tier (Default)
- No subscription required
- Limited to 2 shifts/week
- Limited to 5 entries/week
- Basic features only

### Part-Time Tier
- 3 shifts per week
- 10 entries per week
- Export functionality
- Multiple employers
- Basic analytics

### Full Access Tier
- Unlimited everything
- All premium features
- Priority support

## Revenue Tracking
1. Enable **Financial reports** in Play Console
2. Set up **Play Console notifications** for subscription events
3. Configure webhook endpoint in your backend (optional)

## Important Notes
- Always test with test accounts first
- Price changes require user consent
- Subscription downgrades take effect at next billing cycle
- Upgrades can be immediate or deferred
- Google takes 15-30% commission (15% after first $1M/year)

## Support Resources
- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [Subscription Best Practices](https://developer.android.com/google/play/billing/subscriptions)
- [Testing Subscriptions](https://developer.android.com/google/play/billing/test)

## Troubleshooting
If subscriptions don't appear in app:
1. Check product IDs match exactly
2. Ensure app is signed with release key
3. Verify subscription is active in Console
4. Wait 2-3 hours for propagation
5. Clear Play Store cache on device

For production release:
1. Complete all testing
2. Set up customer support flow
3. Prepare refund policy
4. Monitor subscription metrics
5. Set up alerting for failed renewals