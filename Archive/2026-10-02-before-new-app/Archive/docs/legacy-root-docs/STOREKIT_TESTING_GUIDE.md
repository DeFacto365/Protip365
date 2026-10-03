# StoreKitTest Framework Integration Guide

## Overview

ProTip365 now includes integration with Apple's **StoreKitTest** framework for comprehensive testing of in-app purchase flows. This provides a more reliable and faster testing experience compared to traditional sandbox testing.

## What's New

### StoreKitTest Features
- **Programmatic Testing**: Write unit tests for purchase flows
- **Mock Transactions**: Generate test transactions without real purchases
- **Faster Iteration**: No need for sandbox accounts or waiting
- **Better Debugging**: Inspect transaction states programmatically
- **Deterministic Testing**: Predictable test scenarios

## Setup

### 1. Enable StoreKitTest Scheme

1. Open `ProTip365.xcodeproj` in Xcode
2. Select the **ProTip365_StoreKitTest** scheme from the scheme selector
3. This scheme is pre-configured with:
   - `enableStoreKitTesting = YES`
   - StoreKit configuration file reference

### 2. Access Debug Tools

In DEBUG builds only, a "StoreKit Debug" option appears in Settings under "Developer Tools":

1. Go to Settings → Developer Tools → StoreKit Debug
2. Toggle "Enable StoreKit Testing" to ON
3. Use the provided tools to test subscription flows

## Testing Capabilities

### Available Test Actions

1. **Enable Testing Mode**: Activates StoreKitTest framework
2. **Add Test Transaction**: Creates a mock subscription transaction
3. **Clear Test Transactions**: Removes all test transactions
4. **Load Products**: Tests product loading
5. **Check Subscription Status**: Verifies subscription validation

### Test Transaction Types

- **Premium Subscription**: `com.protip365.premium.monthly`
- **Failed Transaction**: Tests error handling
- **Trial Subscription**: Tests trial period logic

## Usage Examples

### Basic Testing Flow

```swift
// 1. Enable testing mode
await subscriptionManager.enableTestingMode()

// 2. Add a test subscription
await subscriptionManager.addTestTransaction(productId: "com.protip365.premium.monthly")

// 3. Verify subscription status
print(subscriptionManager.isSubscribed) // Should be true
print(subscriptionManager.getSubscriptionStatusText()) // "Premium"
```

### Unit Testing

```swift
func testSubscriptionPurchase() async throws {
    // Given
    await subscriptionManager.enableTestingMode()

    // When
    await subscriptionManager.addTestTransaction(productId: "com.protip365.premium.monthly")

    // Then
    XCTAssertTrue(subscriptionManager.isSubscribed)
    XCTAssertEqual(subscriptionManager.currentTier, .premium)
}
```

## Integration Details

### SubscriptionManager Updates

- Added `#if DEBUG` testing mode support
- New `isTestingMode` published property
- New `testTransactions` array for tracking test state
- Added testing methods: `enableTestingMode()`, `addTestTransaction()`, `clearTestTransactions()`

### StoreKitTest Configuration

- **File**: `StoreKitTestConfiguration.storekit`
- **Products**: Premium subscription with 7-day trial
- **Settings**: Configured for testing environment

### Scheme Configuration

- **Scheme**: `ProTip365_StoreKitTest.xcscheme`
- **StoreKit Testing**: Enabled (`enableStoreKitTesting = YES`)
- **Configuration**: References test StoreKit file

## Benefits Over Traditional Testing

| Feature | Traditional Sandbox | StoreKitTest |
|---------|-------------------|--------------|
| Setup Time | Minutes (accounts) | Seconds (automatic) |
| Test Speed | Real-time delays | Instant |
| Deterministic | Account-dependent | Fully controllable |
| Error Simulation | Limited | Full control |
| Unit Testing | Difficult | Native support |

## Troubleshooting

### Common Issues

**"StoreKitTest requires iOS 15.0+"**
- Ensure your test device/simulator is running iOS 15.0 or later
- The framework is only available on iOS 15+

**"Testing mode not enabled"**
- Make sure the StoreKitTest scheme is selected
- Check that "Enable StoreKit Testing" is toggled ON in the debug view

**"Failed to add test transaction"**
- Verify the product ID matches: `com.protip365.premium.monthly`
- Ensure testing mode is enabled first

## Migration from Traditional Testing

### If Currently Using Sandbox Testing

1. **Keep both approaches** - StoreKitTest for unit tests, sandbox for integration testing
2. **Gradually migrate** - Start with unit tests, then integration tests
3. **Update CI/CD** - Use StoreKitTest for automated testing

### Recommended Testing Strategy

- **Unit Tests**: Use StoreKitTest for isolated component testing
- **Integration Tests**: Use sandbox for full user flow testing
- **Manual Testing**: Use sandbox for final validation

## Documentation References

- [Apple StoreKitTest Documentation](https://developer.apple.com/documentation/StoreKitTest/)
- [Setting up StoreKit Testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode/)

## Support

For issues with StoreKitTest integration:
1. Check Apple Developer Forums
2. File Technical Support Incident (TSI) if needed
3. Review App Store Connect diagnostics

---

*Last Updated: December 2024*
*StoreKitTest Integration for ProTip365 v1.1.26*
