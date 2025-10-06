import StoreKit
import SwiftUI
import Supabase

enum SubscriptionTier: String {
    case none = "none"
    case premium = "premium" // Single tier
    case free = "free" // For testing purposes
}

class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var isInTrialPeriod = false
    @Published var isCheckingSubscription = false // Start as false - only check when authenticated
    @Published var products: [Product] = []
    @Published var currentTier: SubscriptionTier = .none
    @Published var trialDaysRemaining: Int = 0
    @Published var subscriptionExpirationDate: Date? = nil
    @Published var product: Product?
    // Single product ID for simplified pricing (must match App Store Connect exactly)
    private let premiumMonthlyId = "com.protip365.premium.monthly"

    private var allProductIds: [String] {
        [premiumMonthlyId]
    }

    private var transactionListener: Task<Void, Error>?

    // Testing mode support (StoreKitTest framework may not be available)
    #if DEBUG && canImport(StoreKitTest)
    @Published var isTestingMode = false
    @Published var testTransactions: [[String: Any]] = [] // Array of test transaction dictionaries
    #endif

    init() {
        // Start listening for transaction updates immediately
        transactionListener = listenForTransactionUpdates()

        // Don't automatically check subscriptions - wait for authentication
        // This prevents showing subscription screen before login
    }

    deinit {
        transactionListener?.cancel()
    }

    private func listenForTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus(for: transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func updateSubscriptionStatus(for transaction: StoreKit.Transaction) async {
        if allProductIds.contains(transaction.productID) {
            await checkSubscriptionStatus()
        }
    }

    private func getTierForProductId(_ productId: String) -> SubscriptionTier {
        switch productId {
        case premiumMonthlyId:
            return .premium
        default:
            return .none
        }
    }

    enum StoreError: Error {
        case failedVerification
    }

    // Reset all subscription state (used when deleting account)
    func resetSubscriptionState() {
        Task { @MainActor in
            self.isSubscribed = false
            self.isInTrialPeriod = false
            self.currentTier = .none
            self.trialDaysRemaining = 0
            self.isCheckingSubscription = false
            self.products = []
            self.product = nil
            print("Subscription state reset")
        }
    }

    func loadProducts() async {
        print("🔄 Loading products: \(allProductIds)")
        print("🔄 Loading products in current environment")

        do {
            let products = try await Product.products(for: allProductIds)
            print("✅ Loaded \(products.count) products: \(products.map { $0.id })")

            await MainActor.run {
                self.products = products // Single product, no sorting needed
                self.product = products.first(where: { $0.id == premiumMonthlyId })
            }

            // Print product details for debugging
            for product in products {
                print("Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }

            if products.isEmpty {
                print("⚠️ No products loaded - will show subscription screen with fallback option")
                // Don't auto-grant access - let user see the subscription screen
                // They can choose "Continue Anyway" if they want
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            print("Will show subscription screen with fallback option")
            // Don't auto-grant access - show subscription screen instead
        }
    }

    // Test mode subscription for development - or fallback when App Store fails
    private func enableTestModeSubscription() async {
        print("🧪 Enabling fallback access mode")

        // Just grant access locally without hitting the database
        // This ensures users can always use the app even if everything fails
        await MainActor.run {
            self.isSubscribed = true
            self.isInTrialPeriod = true
            self.currentTier = .premium
            self.trialDaysRemaining = 999 // Generous trial for fallback mode
        }

        print("✅ Fallback access granted - users can use the app")

        // Try to save to database but don't fail if it doesn't work
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            return
        }

        let userId = session.user.id
        let testTransactionId = "fallback_\(UUID().uuidString)"

        // Try to create a fallback subscription record
        let testSubscription = SubscriptionRecord(
            user_id: userId.uuidString,
            product_id: premiumMonthlyId,
            status: "active",
            expires_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(365 * 24 * 60 * 60)), // 1 year fallback
            transaction_id: testTransactionId,
            purchase_date: ISO8601DateFormatter().string(from: Date()),
            environment: "fallback"
        )

        // Try to save but don't worry if it fails
        _ = try? await SupabaseManager.shared.client
            .from("user_subscriptions")
            .upsert(testSubscription, onConflict: "user_id")
            .execute()
    }

    func purchase(productId: String) async {
        print("Attempting to purchase product: \(productId)")
        print("Available products: \(products.map { $0.id })")

        guard let product = products.first(where: { $0.id == productId }) else {
            print("❌ Product not found: \(productId)")
            print("Make sure the product IDs are configured in App Store Connect")
            return
        }

        print("✅ Found product: \(product.id) - \(product.displayName)")

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Sync this new purchase to the user's account
                    await syncSubscriptionToServer(transaction: transaction)
                    await transaction.finish()
                    await checkSubscriptionStatus()
                case .unverified:
                    print("Unverified transaction")
                }
            case .userCancelled:
                print("User cancelled purchase")
                // User cancelled - don't auto-sync device subscriptions
                // They can use "Restore Purchases" if needed
            case .pending:
                print("Purchase pending")
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
            if let storeKitError = error as? StoreKitError {
                print("StoreKit error: \(storeKitError)")
            }
            // Don't auto-sync on purchase failure
            // User can use "Restore Purchases" if they already have a subscription
        }
    }

    // Check for existing device subscription and sync to current user
    func checkAndSyncExistingSubscription() async {
        print("Checking for existing device subscription to sync...")

        // Get current user
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            print("No authenticated user, cannot sync subscription")
            return
        }

        let currentUserId = session.user.id

        // Check for any active StoreKit transactions
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if allProductIds.contains(transaction.productID) {
                print("Found active subscription: \(transaction.productID)")

                // Check if this subscription is already synced to current user
                let isSynced = await verifyTransactionForCurrentUser(
                    transaction: transaction,
                    userId: currentUserId
                )

                if !isSynced {
                    print("Syncing existing subscription to current user...")
                    await syncSubscriptionToServer(transaction: transaction)
                }

                // Update local subscription state
                await checkSubscriptionStatus()
                return
            }
        }

        print("No existing subscription found to sync")
    }
    
    func checkSubscriptionStatus() async {
        print("🔍 Starting subscription status check...")
        print("🌐 SERVER-ONLY MODE: Checking user's subscription from our database")

        // Get current user ID - if no user is authenticated, clear subscription state
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            print("❌ No session - clearing subscription state")
            await MainActor.run {
                self.isSubscribed = false
                self.isInTrialPeriod = false
                self.currentTier = .none
                self.isCheckingSubscription = false
            }
            return
        }

        let currentUserId = session.user.id
        print("✅ Session found for user: \(currentUserId)")

        // Check server subscription for this specific user
        // This ensures subscriptions are tied to app users, not device/Apple ID
        if await checkServerSubscription() {
            print("✅ Active subscription found for user")
            await MainActor.run {
                self.isCheckingSubscription = false
            }
            return
        }

        // No subscription found for this user
        print("❌ No active subscription found for user: \(currentUserId)")
        await MainActor.run {
            self.isSubscribed = false
            self.isInTrialPeriod = false
            self.currentTier = .none
            self.isCheckingSubscription = false
        }
    }

    // ONLINE receipt validation with Apple's verifyReceipt API
    // This explicitly calls Apple's servers (sandbox or production)
    private func validateReceiptWithAppleServers(transaction: StoreKit.Transaction) async -> Bool {
        print("🌐 Validating receipt ONLINE with Apple servers...")

        // Get the app receipt
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            print("❌ No receipt found on device")
            return false
        }

        let receiptString = receiptData.base64EncodedString()
        print("📄 Receipt size: \(receiptData.count) bytes")

        // Try production first (Apple's recommendation)
        print("🔵 Trying PRODUCTION server first...")
        if await verifyReceiptWithEnvironment(receiptString: receiptString, isProduction: true) {
            print("✅ PRODUCTION validation successful")
            return true
        }

        // If production fails with sandbox error, try sandbox
        print("🟡 Production failed, trying SANDBOX server...")
        if await verifyReceiptWithEnvironment(receiptString: receiptString, isProduction: false) {
            print("✅ SANDBOX validation successful")
            return true
        }

        print("❌ Both PRODUCTION and SANDBOX validation failed")
        return false
    }

    // Call Apple's verifyReceipt API
    private func verifyReceiptWithEnvironment(receiptString: String, isProduction: Bool) async -> Bool {
        let urlString = isProduction
            ? "https://buy.itunes.apple.com/verifyReceipt"
            : "https://sandbox.itunes.apple.com/verifyReceipt"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return false
        }

        print("🌐 Calling: \(urlString)")

        let requestBody: [String: Any] = [
            "receipt-data": receiptString,
            "password": "", // Shared secret - leave empty if not using auto-renewable subscriptions with shared secret
            "exclude-old-transactions": true
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("❌ Failed to serialize request")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15 // 15 second timeout

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                return false
            }

            print("📡 HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                print("❌ Server returned error status: \(httpResponse.statusCode)")
                return false
            }

            // Parse response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Failed to parse response JSON")
                return false
            }

            let status = json["status"] as? Int ?? -1
            print("📋 Apple Response Status: \(status)")

            // Status codes:
            // 0: Valid receipt
            // 21007: Sandbox receipt sent to production
            // 21008: Production receipt sent to sandbox

            switch status {
            case 0:
                print("✅ Receipt is VALID")
                // Check for active subscriptions
                if let receipt = json["receipt"] as? [String: Any],
                   let inApp = receipt["in_app"] as? [[String: Any]] {
                    print("📱 Found \(inApp.count) in-app purchases")
                    return true
                }
                if let latestReceiptInfo = json["latest_receipt_info"] as? [[String: Any]] {
                    print("📱 Found \(latestReceiptInfo.count) subscription transactions")
                    return !latestReceiptInfo.isEmpty
                }
                return true

            case 21007:
                print("⚠️ Sandbox receipt used in production (expected for TestFlight)")
                return false // Signal to try sandbox

            case 21008:
                print("⚠️ Production receipt used in sandbox")
                return false

            default:
                print("❌ Receipt validation failed with status: \(status)")
                return false
            }

        } catch {
            print("❌ Network error calling Apple servers: \(error.localizedDescription)")
            return false
        }
    }

    // Check server-side subscription status (for cross-device sync only)
    private func checkServerSubscription() async -> Bool {
        do {
            // Get current user ID - handle case where session might not be ready
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                print("Session not yet available, skipping server subscription check")
                return false
            }
            let userId = session.user.id

            // Query for active subscription - don't use .single() as it fails when no results
            let response = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .execute()

            // Parse the response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Decode as array since we removed .single()
            let subscriptions = try decoder.decode([ServerSubscription].self, from: response.data)
            if let subscription = subscriptions.first {
                // Check if subscription is still valid
                if let expiresAt = subscription.expires_at, expiresAt > Date() {
                    print("✅ Found valid server subscription, expires: \(expiresAt)")
                    let tier = getTierForProductId(subscription.product_id ?? "")

                    await MainActor.run {
                        self.isSubscribed = true
                        self.currentTier = tier

                        // Check trial period based on purchase date
                        if let purchaseDate = subscription.purchase_date, tier == .premium {
                            let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
                            let timeSincePurchase = Date().timeIntervalSince(purchaseDate)
                            self.isInTrialPeriod = timeSincePurchase <= trialDuration

                            if self.isInTrialPeriod {
                                let daysRemaining = Int((trialDuration - timeSincePurchase) / (24 * 60 * 60))
                                self.trialDaysRemaining = max(0, daysRemaining + 1) // +1 to include today
                            }
                        }
                    }

                    return true
                } else {
                    print("⚠️ Server subscription found but expired")
                }
            } else {
                print("ℹ️ No server subscription found")
            }
        } catch {
            print("⚠️ Server subscription check failed: \(error)")
        }
        return false
    }

    // Sync local subscription to server
    private func syncSubscriptionToServer(transaction: StoreKit.Transaction) async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id

            let dateFormatter = ISO8601DateFormatter()

            // Create subscription record for upsert
            let subscriptionRecord = SubscriptionRecord(
                user_id: userId.uuidString,
                product_id: transaction.productID,
                status: "active",
                expires_at: dateFormatter.string(from: transaction.expirationDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60)),
                transaction_id: String(transaction.id),
                purchase_date: dateFormatter.string(from: transaction.purchaseDate),
                environment: transaction.environment == StoreKit.AppStore.Environment.xcode ? "sandbox" : "production"
            )

            // Upsert subscription (insert or update if exists)
            _ = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .upsert(subscriptionRecord, onConflict: "user_id")
                .execute()

            print("✅ Subscription synced to server")
        } catch {
            print("Failed to sync subscription: \(error)")
        }
    }

    // Server subscription model for reading
    private struct ServerSubscription: Decodable {
        let user_id: String
        let product_id: String?
        let status: String
        let expires_at: Date?
        let transaction_id: String?
        let purchase_date: Date?
        let environment: String?
    }

    // Subscription record for writing/upserting
    private struct SubscriptionRecord: Codable {
        let user_id: String
        let product_id: String
        let status: String
        let expires_at: String
        let transaction_id: String
        let purchase_date: String
        let environment: String
    }
    
    func restorePurchases() async {
        print("🔄 Restore Purchases: Checking device for existing subscriptions...")

        // Get current user
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            print("❌ No authenticated user, cannot restore purchases")
            return
        }

        let currentUserId = session.user.id
        print("✅ Restoring purchases for user: \(currentUserId)")

        // Check for any active StoreKit transactions on this device
        var foundSubscription = false

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if allProductIds.contains(transaction.productID) {
                print("📱 Found device subscription: \(transaction.productID)")
                print("   Transaction ID: \(transaction.id)")

                // Validate with Apple servers before syncing
                let isValid = await validateReceiptWithAppleServers(transaction: transaction)

                if isValid {
                    print("✅ Subscription validated with Apple - syncing to user account")
                    // Sync this subscription to the current user
                    await syncSubscriptionToServer(transaction: transaction)
                    foundSubscription = true
                } else {
                    print("❌ Subscription validation failed - not syncing")
                }
            }
        }

        if foundSubscription {
            // Refresh subscription status after restoring
            await checkSubscriptionStatus()
            print("✅ Restore complete - subscription synced")
        } else {
            print("ℹ️ No device subscriptions found to restore")
        }
    }

    private func schedulePeriodicValidation() {
        // Check subscription status every 6 hours to ensure it's still valid
        // Run in background task, don't await
        Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 6 * 60 * 60 * 1_000_000_000) // 6 hours
                await self.checkSubscriptionStatus()
            }
        }
    }

    // Force refresh subscription status (can be called manually)
    func refreshSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }

    // Start subscription checking (call this only after user is authenticated)
    func startSubscriptionChecking() async {
        print("🚀 Starting subscription checking...")

        await MainActor.run {
            self.isCheckingSubscription = true
        }

        // Load products with timeout
        await withTimeout(seconds: 5) {
            await self.loadProducts()
        }

        // Check subscription status with timeout
        await withTimeout(seconds: 10) {
            await self.checkSubscriptionStatus()
        }

        // Always clear the checking flag after timeout
        await MainActor.run {
            self.isCheckingSubscription = false
        }

        // Schedule periodic subscription validation (non-blocking)
        schedulePeriodicValidation()

        print("✅ Subscription checking completed")
    }

    // Helper function to run async code with timeout
    private func withTimeout(seconds: TimeInterval, operation: @escaping () async -> Void) async {
        await withTaskGroup(of: Void.self) { group in
            // Start the operation
            group.addTask {
                await operation()
            }

            // Start timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }

            // Wait for first to complete, then cancel the rest
            _ = await group.next()
            group.cancelAll()
        }
    }

    // Verify if a StoreKit transaction belongs to the current user
    private func verifyTransactionForCurrentUser(transaction: StoreKit.Transaction, userId: UUID) async -> Bool {
        do {
            // Check if this transaction has been synced to our server for this user
            let response = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .eq("transaction_id", value: String(transaction.id))
                .execute()

            // If we found a matching record, this transaction belongs to current user
            // Check if the response has any data
            if response.data.count > 2 {  // Empty JSON array is "[]" which is 2 bytes
                return true
            }
        } catch {
            print("Failed to verify transaction for user: \(error)")
        }

        // If no server record exists for this transaction/user combo, it's likely from a previous user
        return false
    }

    // MARK: - Simplified Access Management

    func canAddShift() -> Bool {
        // With single tier, always allow if subscribed
        return isSubscribed || isInTrialPeriod
    }

    func canAddEntry() -> Bool {
        // With single tier, always allow if subscribed
        return isSubscribed || isInTrialPeriod
    }

    func hasFullAccess() -> Bool {
        return isSubscribed || isInTrialPeriod
    }

    func getSubscriptionStatusText() -> String {
        if isInTrialPeriod {
            return "Trial - \(trialDaysRemaining) days left"
        } else if isSubscribed {
            return "Premium"
        } else {
            return "Free Trial Available"
        }
    }

    // MARK: - Testing Support

    #if DEBUG && canImport(StoreKitTest)
    /// Enable testing mode with StoreKitTest framework
    func enableTestingMode() async {
        #if DEBUG && canImport(StoreKitTest)
        // Check if StoreKitTest is available (iOS 15+)
        guard #available(iOS 15.0, *) else {
            print("❌ StoreKitTest requires iOS 15.0+")
            return
        }

        // In StoreKitTest, the session is automatically created when enableStoreKitTesting = YES in scheme
        // We don't need to manually create a session

        await MainActor.run {
            self.isTestingMode = true
        }

        print("✅ StoreKitTest mode enabled")
        #endif
    }

    /// Add a test transaction for testing
    func addTestTransaction(productId: String, state: String = "purchased") async {
        #if DEBUG && canImport(StoreKitTest)
        guard #available(iOS 15.0, *) else {
            print("❌ StoreKitTest requires iOS 15.0+")
            return
        }

        guard isTestingMode else {
            print("❌ Testing mode not enabled")
            return
        }

        // Create a test transaction dictionary
        let testTransaction: [String: Any] = [
            "productID": productId,
            "state": state,
            "transactionID": UUID().uuidString,
            "timestamp": Date().timeIntervalSince1970,
            "originalTransactionID": UUID().uuidString
        ]

        // Add to test transactions list
        await MainActor.run {
            self.testTransactions.append(testTransaction)
            
            // Simulate subscription status change for testing
            if productId == "com.protip365.premium.monthly" {
                switch state {
                case "purchased":
                    self.isSubscribed = true
                    self.currentTier = .premium
                    self.subscriptionExpirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                    self.isInTrialPeriod = false
                    print("✅ Test subscription activated: Premium")
                case "trial":
                    self.isSubscribed = true
                    self.currentTier = .premium
                    self.subscriptionExpirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                    self.isInTrialPeriod = true
                    print("✅ Test trial activated: Premium (7 days)")
                case "failed":
                    self.isSubscribed = false
                    self.currentTier = .free
                    self.subscriptionExpirationDate = nil
                    self.isInTrialPeriod = false
                    print("✅ Test transaction failed")
                default:
                    break
                }
            }
        }

        print("✅ Added test transaction: \(productId) with state: \(state)")
        #endif
    }

    /// Clear all test transactions
    func clearTestTransactions() async {
        #if DEBUG && canImport(StoreKitTest)
        guard #available(iOS 15.0, *) else { return }

        guard isTestingMode else { return }

        // Clear test transactions and reset subscription status
        await MainActor.run {
            self.testTransactions.removeAll()
            
            // Reset subscription status for testing
            self.isSubscribed = false
            self.currentTier = .free
            self.subscriptionExpirationDate = nil
            self.isInTrialPeriod = false
        }

        print("✅ Cleared all test transactions and reset subscription status")
        #endif
    }
    #endif
}
