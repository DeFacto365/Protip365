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
    @Published var isCheckingSubscription = false
    @Published var products: [Product] = []
    @Published var currentTier: SubscriptionTier = .none
    @Published var trialDaysRemaining: Int = 0
    @Published var subscriptionExpirationDate: Date? = nil
    @Published var product: Product?
    
    // NEW: Error handling for UI feedback
    @Published var loadingError: String?
    @Published var purchaseError: String?
    
    // Single product ID for simplified pricing (must match App Store Connect exactly)
    private let premiumMonthlyId = "com.protip365.premium.monthly"

    // CRITICAL: Add your App Store Connect shared secret here
    // Get this from: App Store Connect > Your App > Features > In-App Purchases > App-Specific Shared Secret
    private let sharedSecret = "0b3c33127296426f9846d484f520f693" // TODO: Replace with your actual shared secret

    private var allProductIds: [String] {
        [premiumMonthlyId]
    }

    private var transactionListener: Task<Void, Error>?

    // Testing mode support (StoreKitTest framework may not be available)
    #if DEBUG && canImport(StoreKitTest)
    @Published var isTestingMode = false
    @Published var testTransactions: [[String: Any]] = []
    #endif

    init() {
        // Start listening for transaction updates immediately
        transactionListener = listenForTransactionUpdates()
    }

    deinit {
        transactionListener?.cancel()
    }

    private func listenForTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
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
            self.loadingError = nil
            self.purchaseError = nil
            print("Subscription state reset")
        }
    }

    // FIXED: Improved product loading with proper error handling
    func loadProducts() async {
        print("🔄 Loading products: \(allProductIds)")
        print("🔄 Loading products in current environment")

        await MainActor.run {
            self.loadingError = nil
        }

        do {
            let products = try await Product.products(for: allProductIds)
            print("✅ Loaded \(products.count) products: \(products.map { $0.id })")

            await MainActor.run {
                self.products = products
                self.product = products.first(where: { $0.id == premiumMonthlyId })
                
                if products.isEmpty {
                    self.loadingError = "No subscription products available. Please check your internet connection and try again."
                    print("⚠️ No products loaded - check App Store Connect configuration")
                } else {
                    self.loadingError = nil
                }
            }

            // Print product details for debugging
            for product in products {
                print("Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            let errorMessage = "Unable to load subscription products: \(error.localizedDescription)"
            print("❌ Failed to load products: \(error)")
            
            await MainActor.run {
                self.loadingError = errorMessage
            }
        }
    }

    // FIXED: Improved purchase handling with better error feedback
    func purchase(productId: String) async throws {
        print("Attempting to purchase product: \(productId)")
        print("Available products: \(products.map { $0.id })")

        await MainActor.run {
            self.purchaseError = nil
        }

        guard let product = products.first(where: { $0.id == productId }) else {
            let error = "Product not found. Please try reloading the subscription options."
            print("❌ Product not found: \(productId)")
            await MainActor.run {
                self.purchaseError = error
            }
            throw NSError(domain: "SubscriptionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
        }

        print("✅ Found product: \(product.id) - \(product.displayName)")

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("✅ Purchase verified, syncing to server...")
                    await syncSubscriptionToServer(transaction: transaction)
                    await transaction.finish()
                    await checkSubscriptionStatus()
                    
                case .unverified:
                    let error = "Purchase verification failed. Please contact support."
                    print("❌ Unverified transaction")
                    await MainActor.run {
                        self.purchaseError = error
                    }
                    throw NSError(domain: "SubscriptionManager", code: 2, userInfo: [NSLocalizedDescriptionKey: error])
                }
                
            case .userCancelled:
                print("User cancelled purchase")
                return
                
            case .pending:
                print("Purchase pending - waiting for approval")
                await MainActor.run {
                    self.purchaseError = "Purchase is pending approval. Please check back later."
                }
                return
                
            @unknown default:
                print("Unknown purchase result")
                break
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            
            let errorMessage: String
            if let storeKitError = error as? StoreKitError {
                // Log the specific StoreKit error details
                print("StoreKit error details: \(storeKitError)")
                
                switch storeKitError {
                case .userCancelled:
                    errorMessage = "Purchase cancelled"
                case .networkError(let underlyingError):
                    errorMessage = "Network error: \(underlyingError.localizedDescription)"
                case .notAvailableInStorefront:
                    errorMessage = "This subscription is not available in your region"
                case .notEntitled:
                    errorMessage = "You don't have access to this subscription"
                case .systemError(let underlyingError):
                    errorMessage = "System error: \(underlyingError.localizedDescription)"
                default:
                    errorMessage = "Purchase failed: \(storeKitError.localizedDescription)"
                }
            } else {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            
            await MainActor.run {
                self.purchaseError = errorMessage
            }
            
            throw error
        }
    }

    // Check for existing device subscription and sync to current user
    func checkAndSyncExistingSubscription() async {
        print("Checking for existing device subscription to sync...")

        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            print("No authenticated user, cannot sync subscription")
            return
        }

        let currentUserId = session.user.id

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if allProductIds.contains(transaction.productID) {
                print("Found active subscription: \(transaction.productID)")

                let isSynced = await verifyTransactionForCurrentUser(
                    transaction: transaction,
                    userId: currentUserId
                )

                if !isSynced {
                    print("Syncing existing subscription to current user...")
                    await syncSubscriptionToServer(transaction: transaction)
                }

                await checkSubscriptionStatus()
                return
            }
        }

        print("No existing subscription found to sync")
    }
    
    // FIXED: Better error handling in checkSubscriptionStatus
    func checkSubscriptionStatus() async {
        print("🔍 Starting subscription status check...")
        print("🌐 SERVER-ONLY MODE: Checking user's subscription from our database")

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

        do {
            if await checkServerSubscription() {
                print("✅ Active subscription found for user")
                await MainActor.run {
                    self.isCheckingSubscription = false
                    self.loadingError = nil
                }
                return
            }
        } catch {
            print("⚠️ Error checking server subscription: \(error)")
        }

        print("❌ No active subscription found for user: \(currentUserId)")
        await MainActor.run {
            self.isSubscribed = false
            self.isInTrialPeriod = false
            self.currentTier = .none
            self.isCheckingSubscription = false
        }
    }

    // FIXED: Receipt validation with proper shared secret and Apple's recommended flow
    private func validateReceiptWithAppleServers(transaction: StoreKit.Transaction) async -> Bool {
        print("🌐 Validating receipt ONLINE with Apple servers...")

        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            print("❌ No receipt found on device")
            return false
        }

        let receiptString = receiptData.base64EncodedString()
        print("📄 Receipt size: \(receiptData.count) bytes")

        // CRITICAL FIX: Apple's exact recommended approach
        // Try production first, if it returns 21007 (sandbox receipt), then try sandbox
        print("🔵 Trying PRODUCTION server first...")
        let productionResult = await verifyReceiptWithEnvironment(
            receiptString: receiptString,
            isProduction: true
        )
        
        switch productionResult {
        case .success:
            print("✅ PRODUCTION validation successful")
            return true
            
        case .sandboxReceipt:
            // This is the key fix: Apple returns 21007 when sandbox receipt is sent to production
            print("🟡 Sandbox receipt detected (21007), trying SANDBOX server...")
            let sandboxResult = await verifyReceiptWithEnvironment(
                receiptString: receiptString,
                isProduction: false
            )
            
            if case .success = sandboxResult {
                print("✅ SANDBOX validation successful")
                return true
            } else {
                print("❌ SANDBOX validation also failed")
                return false
            }
            
        case .failed:
            print("❌ PRODUCTION validation failed")
            return false
        }
    }

    // NEW: Result type for receipt validation
    private enum ReceiptValidationResult {
        case success
        case sandboxReceipt  // Status 21007 - sandbox receipt sent to production
        case failed
    }
    
    // FIXED: Proper receipt verification with comprehensive error handling
    private func verifyReceiptWithEnvironment(
        receiptString: String,
        isProduction: Bool
    ) async -> ReceiptValidationResult {
        let urlString = isProduction
            ? "https://buy.itunes.apple.com/verifyReceipt"
            : "https://sandbox.itunes.apple.com/verifyReceipt"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return .failed
        }

        print("🌐 Calling: \(urlString)")

        // CRITICAL FIX: Include the shared secret for auto-renewable subscriptions
        let requestBody: [String: Any] = [
            "receipt-data": receiptString,
            "password": sharedSecret, // Must not be empty for subscriptions!
            "exclude-old-transactions": true
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("❌ Failed to serialize request")
            return .failed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // Increased timeout for App Review

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                return .failed
            }

            print("📡 HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                print("❌ Server returned error status: \(httpResponse.statusCode)")
                return .failed
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Failed to parse response JSON")
                return .failed
            }

            let status = json["status"] as? Int ?? -1
            print("📋 Apple Response Status: \(status)")

            // Handle all Apple status codes properly
            switch status {
            case 0:
                print("✅ Receipt is VALID")
                // Verify we have subscription data
                if let latestReceiptInfo = json["latest_receipt_info"] as? [[String: Any]],
                   !latestReceiptInfo.isEmpty {
                    print("📱 Found \(latestReceiptInfo.count) subscription transactions")
                    return .success
                }
                if let receipt = json["receipt"] as? [String: Any],
                   let inApp = receipt["in_app"] as? [[String: Any]],
                   !inApp.isEmpty {
                    print("📱 Found \(inApp.count) in-app purchases")
                    return .success
                }
                print("⚠️ Valid receipt but no subscription data found")
                return .failed

            case 21007:
                // CRITICAL: This is the exact case Apple mentioned in their rejection
                print("⚠️ Status 21007: Sandbox receipt used in production")
                return .sandboxReceipt

            case 21008:
                print("⚠️ Status 21008: Production receipt used in sandbox")
                return .failed

            case 21000:
                print("❌ Status 21000: App Store could not read receipt")
                return .failed
                
            case 21002:
                print("❌ Status 21002: Receipt data was malformed")
                return .failed
                
            case 21003:
                print("❌ Status 21003: Receipt could not be authenticated")
                return .failed
                
            case 21005:
                print("❌ Status 21005: Receipt server unavailable")
                return .failed
                
            case 21009:
                print("❌ Status 21009: Shared secret does not match")
                print("⚠️ CHECK YOUR SHARED SECRET IN APP STORE CONNECT!")
                return .failed

            default:
                print("❌ Receipt validation failed with status: \(status)")
                return .failed
            }

        } catch {
            print("❌ Network error calling Apple servers: \(error.localizedDescription)")
            return .failed
        }
    }

    // Check server-side subscription status
    private func checkServerSubscription() async -> Bool {
        do {
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                print("Session not yet available, skipping server subscription check")
                return false
            }
            let userId = session.user.id

            let response = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let subscriptions = try decoder.decode([ServerSubscription].self, from: response.data)
            if let subscription = subscriptions.first {
                if let expiresAt = subscription.expires_at, expiresAt > Date() {
                    print("✅ Found valid server subscription, expires: \(expiresAt)")
                    let tier = getTierForProductId(subscription.product_id ?? "")

                    await MainActor.run {
                        self.isSubscribed = true
                        self.currentTier = tier

                        if let purchaseDate = subscription.purchase_date, tier == .premium {
                            let trialDuration: TimeInterval = 7 * 24 * 60 * 60
                            let timeSincePurchase = Date().timeIntervalSince(purchaseDate)
                            self.isInTrialPeriod = timeSincePurchase <= trialDuration

                            if self.isInTrialPeriod {
                                let daysRemaining = Int((trialDuration - timeSincePurchase) / (24 * 60 * 60))
                                self.trialDaysRemaining = max(0, daysRemaining + 1)
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

            let subscriptionRecord = SubscriptionRecord(
                user_id: userId.uuidString,
                product_id: transaction.productID,
                status: "active",
                expires_at: dateFormatter.string(from: transaction.expirationDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60)),
                transaction_id: String(transaction.id),
                purchase_date: dateFormatter.string(from: transaction.purchaseDate),
                environment: transaction.environment == StoreKit.AppStore.Environment.xcode ? "sandbox" : "production"
            )

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

        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            print("❌ No authenticated user, cannot restore purchases")
            return
        }

        let currentUserId = session.user.id
        print("✅ Restoring purchases for user: \(currentUserId)")

        var foundSubscription = false

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if allProductIds.contains(transaction.productID) {
                print("📱 Found device subscription: \(transaction.productID)")
                print("   Transaction ID: \(transaction.id)")

                let isValid = await validateReceiptWithAppleServers(transaction: transaction)

                if isValid {
                    print("✅ Subscription validated with Apple - syncing to user account")
                    await syncSubscriptionToServer(transaction: transaction)
                    foundSubscription = true
                } else {
                    print("❌ Subscription validation failed - not syncing")
                }
            }
        }

        if foundSubscription {
            await checkSubscriptionStatus()
            print("✅ Restore complete - subscription synced")
        } else {
            print("ℹ️ No device subscriptions found to restore")
        }
    }

    private func schedulePeriodicValidation() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 6 * 60 * 60 * 1_000_000_000)
                await self.checkSubscriptionStatus()
            }
        }
    }

    func refreshSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }

    func startSubscriptionChecking() async {
        print("🚀 Starting subscription checking...")

        await MainActor.run {
            self.isCheckingSubscription = true
        }

        await withTimeout(seconds: 5) {
            await self.loadProducts()
        }

        await withTimeout(seconds: 10) {
            await self.checkSubscriptionStatus()
        }

        await MainActor.run {
            self.isCheckingSubscription = false
        }

        schedulePeriodicValidation()

        print("✅ Subscription checking completed")
    }

    private func withTimeout(seconds: TimeInterval, operation: @escaping () async -> Void) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }

            _ = await group.next()
            group.cancelAll()
        }
    }

    private func verifyTransactionForCurrentUser(transaction: StoreKit.Transaction, userId: UUID) async -> Bool {
        do {
            let response = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .eq("transaction_id", value: String(transaction.id))
                .execute()

            if response.data.count > 2 {
                return true
            }
        } catch {
            print("Failed to verify transaction for user: \(error)")
        }

        return false
    }

    // MARK: - Simplified Access Management

    func canAddShift() -> Bool {
        return isSubscribed || isInTrialPeriod
    }

    func canAddEntry() -> Bool {
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
    func enableTestingMode() async {
        guard #available(iOS 15.0, *) else {
            print("❌ StoreKitTest requires iOS 15.0+")
            return
        }

        await MainActor.run {
            self.isTestingMode = true
        }

        print("✅ StoreKitTest mode enabled")
    }

    func addTestTransaction(productId: String, state: String = "purchased") async {
        guard #available(iOS 15.0, *) else {
            print("❌ StoreKitTest requires iOS 15.0+")
            return
        }

        guard isTestingMode else {
            print("❌ Testing mode not enabled")
            return
        }

        let testTransaction: [String: Any] = [
            "productID": productId,
            "state": state,
            "transactionID": UUID().uuidString,
            "timestamp": Date().timeIntervalSince1970,
            "originalTransactionID": UUID().uuidString
        ]

        await MainActor.run {
            self.testTransactions.append(testTransaction)
            
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
    }

    func clearTestTransactions() async {
        guard #available(iOS 15.0, *) else { return }

        guard isTestingMode else { return }

        await MainActor.run {
            self.testTransactions.removeAll()
            self.isSubscribed = false
            self.currentTier = .free
            self.subscriptionExpirationDate = nil
            self.isInTrialPeriod = false
        }

        print("✅ Cleared all test transactions and reset subscription status")
    }
    #endif
}
