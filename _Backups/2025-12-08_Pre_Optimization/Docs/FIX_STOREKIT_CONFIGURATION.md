# Fix StoreKit Configuration in Xcode

## Issue
The app shows "No subscription found. Make sure you're connected to App Store" because StoreKit products aren't loading.

## Solution Steps

### 1. Open Xcode Project
1. Open `ProTip365.xcodeproj` in Xcode
2. Select the ProTip365 project in the navigator

### 2. Configure StoreKit File
1. In Xcode's file navigator, locate `ProTip365/Protip365.storekit`
2. If it's not there, drag it from Finder into the ProTip365 group in Xcode
3. Make sure "Copy items if needed" is checked
4. Select "ProTip365" as the target

### 3. Link StoreKit Configuration to Scheme
1. In Xcode, click on the scheme selector (next to the Run/Stop buttons)
2. Select "Edit Scheme..."
3. Select "Run" from the left sidebar
4. Go to the "Options" tab
5. Under "StoreKit Configuration", select `Protip365.storekit`
6. Click "Close"

### 4. Sync with App Store Connect
1. Open the `Protip365.storekit` file in Xcode
2. Click the "Sync" button at the bottom to sync with App Store Connect
3. Enter your Apple Developer credentials if prompted

### 5. Enable StoreKit Testing
For testing in the simulator:
1. In the StoreKit configuration file, make sure the subscription is properly configured:
   - Product ID: `com.protip365.premium.monthly`
   - Price: $3.99
   - Free trial: 7 days

### 6. Test the Configuration
1. Build and run the app in the simulator
2. The subscription should now load properly

## Alternative: Test Without StoreKit File (Production Testing)

If you want to test with real App Store products:

1. Remove the StoreKit configuration from the scheme:
   - Edit Scheme > Run > Options > StoreKit Configuration: None
2. Use a real device (not simulator)
3. Sign in with a Sandbox Test Account:
   - Settings > App Store > Sandbox Account
4. The app will load real products from App Store Connect

## Verify Product ID

Make sure the product ID in App Store Connect matches exactly:
- Expected: `com.protip365.premium.monthly`
- Status in App Store Connect: Should be "Ready to Submit" or "Approved"

## Important Notes

1. **Simulator Testing**: Requires StoreKit configuration file
2. **Device Testing**: Can use either StoreKit file or real App Store Connect products
3. **Production**: Remove StoreKit configuration before submitting to App Store

## Troubleshooting

If products still don't load:

1. **Check Bundle ID**: Ensure the app's bundle ID matches App Store Connect
2. **Check Capabilities**:
   - Select project > Target > Signing & Capabilities
   - Ensure "In-App Purchase" capability is enabled
3. **Clean Build**:
   - Product > Clean Build Folder (Shift+Cmd+K)
   - Delete derived data
   - Rebuild

## Console Output to Check

When products load successfully, you should see:
```
✅ Loaded 1 products: ["com.protip365.premium.monthly"]
Product: com.protip365.premium.monthly - ProTip365 Premium - $3.99
```

Instead of:
```
✅ Loaded 0 products: []
⚠️ No products loaded - this might cause subscription loading issues
```