# Subscription Sandbox Setup

RFP-65 app-side sandbox behavior is implemented in `src/features/subscriptions/subscriptionSandbox.ts`.

## Current Local State

- The app can simulate iOS and Android subscription products.
- Successful purchase starts a 7-day trial entitlement.
- Canceled purchases keep the user on the free plan and do not block logging.
- Failed purchases return a user-safe retry message.
- Real native checkout is blocked until store products and a development build are configured.

## Native Store Setup Required

Expo's current in-app purchase guide recommends native IAP through a development build. Expo Go is not enough because store billing requires native modules.

1. Choose IAP provider:
   - Preferred for this app: `expo-iap` for direct StoreKit / Google Play Billing access.
   - Alternative: RevenueCat if we want managed receipt validation and entitlement sync.
2. Create products in App Store Connect:
   - `protip365_premium_monthly`
   - `protip365_premium_yearly`
   - 7-day trial on both products.
3. Create matching Google Play subscriptions:
   - `protip365_premium_monthly`
   - `protip365_premium_yearly`
   - 7-day trial or introductory offer.
4. Create an Expo development build with the chosen IAP native module.
5. Configure Apple sandbox tester and Google Play license tester accounts.
6. Run the purchase matrix:
   - iOS monthly success, cancel, error.
   - iOS yearly success, cancel, error.
   - Android monthly success, cancel, error.
   - Android yearly success, cancel, error.
7. Verify entitlement state after app restart and restore purchase.

## References

- Expo guide: https://docs.expo.dev/guides/in-app-purchases/
- Apple In-App Purchase docs: https://developer.apple.com/documentation/storekit/in-app-purchase
