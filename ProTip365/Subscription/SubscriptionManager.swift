import StoreKit
import SwiftUI
import Supabase

enum SubscriptionTier: String {
    case none = "none"
    case partTime = "part_time"
    case fullAccess = "full_access"

    var shiftsPerWeekLimit: Int? {
        switch self {
        case .partTime: return 3
        case .fullAccess, .none: return nil
        }
    }

    var entriesPerWeekLimit: Int? {
        switch self {
        case .partTime: return 3
        case .fullAccess, .none: return nil
        }
    }
}

class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var isInTrialPeriod = false
    @Published var isCheckingSubscription = false // Start as false - only check when authenticated
    @Published var products: [Product] = []
    @Published var currentTier: SubscriptionTier = .none
    @Published var currentWeekShifts = 0
    @Published var currentWeekEntries = 0

    // Product IDs for different subscription tiers (must match App Store Connect exactly)
    private let fullAccessMonthlyId = "com.protip365.monthly"
    private let fullAccessYearlyId = "com.protip365.annual"
    private let partTimeMonthlyId = "com.protip365.parttime.monthly"
    private let partTimeYearlyId = "com.protip365.parttime.Annual" // Note: capital 'A' as in App Store Connect

    private var allProductIds: [String] {
        [fullAccessMonthlyId, fullAccessYearlyId, partTimeMonthlyId, partTimeYearlyId]
    }

    private var transactionListener: Task<Void, Error>?

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
        case fullAccessMonthlyId, fullAccessYearlyId:
            return .fullAccess
        case partTimeMonthlyId, partTimeYearlyId:
            return .partTime
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
            self.currentWeekShifts = 0
            self.currentWeekEntries = 0
            self.isCheckingSubscription = false
            self.products = []
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
                self.products = products.sorted { first, second in
                    // Sort products: Part-time monthly, Part-time yearly, Full access monthly, Full access yearly
                    let order = [
                        partTimeMonthlyId: 0,
                        partTimeYearlyId: 1,
                        fullAccessMonthlyId: 2,
                        fullAccessYearlyId: 3
                    ]
                    return (order[first.id] ?? 99) < (order[second.id] ?? 99)
                }
            }

            // Print product details for debugging
            for product in products {
                print("Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
            
            if products.isEmpty {
                print("⚠️ No products loaded - this might cause subscription loading issues")
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            print("Make sure products are configured in App Store Connect with these IDs:")
            print("- \(fullAccessMonthlyId)")
            print("- \(fullAccessYearlyId)")
            print("- \(partTimeMonthlyId)")
            print("- \(partTimeYearlyId)")
        }
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
                    // Important: For a new user with an existing device subscription,
                    // we need to sync this transaction to THEIR user account
                    await syncSubscriptionToServer(transaction: transaction)
                    await transaction.finish()
                    await checkSubscriptionStatus()
                case .unverified:
                    print("Unverified transaction")
                }
            case .userCancelled:
                print("User cancelled purchase")
                // Check if there's an existing subscription that needs to be synced
                await checkAndSyncExistingSubscription()
            case .pending:
                print("Purchase pending")
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
            // If purchase fails because user already has subscription,
            // sync existing subscription to new user account
            if let storeKitError = error as? StoreKitError {
                print("StoreKit error: \(storeKitError)")
            }
            await checkAndSyncExistingSubscription()
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
        // Get current user ID - if no user is authenticated, clear subscription state
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            await MainActor.run {
                self.isSubscribed = false
                self.isInTrialPeriod = false
                self.currentTier = .none
                self.isCheckingSubscription = false
            }
            return
        }

        let currentUserId = session.user.id

        // First check server-side subscription (for cross-device sync)
        if await checkServerSubscription() {
            await MainActor.run {
                self.isCheckingSubscription = false
            }
            return // Found active subscription on server
        }

        // Then check local StoreKit transactions - but only process if we can verify user association
        // Note: StoreKit doesn't provide user-specific info, so we need to rely on server verification
        // We'll only process StoreKit transactions if they've been synced to our server for this user
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if allProductIds.contains(transaction.productID) {
                // Verify this transaction belongs to current user via server check
                if await verifyTransactionForCurrentUser(transaction: transaction, userId: currentUserId) {
                    let tier = getTierForProductId(transaction.productID)

                    await MainActor.run {
                        self.isSubscribed = true
                        self.currentTier = tier

                        // For subscriptions, check trial period (only for full access)
                        if transaction.productType == .autoRenewable && tier == .fullAccess {
                            // Simply check if we're within the first 7 days
                            let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
                            let timeSincePurchase = Date().timeIntervalSince(transaction.originalPurchaseDate)
                            self.isInTrialPeriod = timeSincePurchase <= trialDuration
                        }

                        self.isCheckingSubscription = false
                    }

                    // Sync to server for other devices
                    await syncSubscriptionToServer(transaction: transaction)

                    // Load current week usage for part-time tier
                    if tier == .partTime {
                        await loadCurrentWeekUsage()
                    }

                    return
                }
            }
        }

        await MainActor.run {
            self.isSubscribed = false
            self.isInTrialPeriod = false
            self.currentTier = .none
            self.isCheckingSubscription = false
        }
    }

    // Check server-side subscription status
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
            let subscriptions = try? decoder.decode([ServerSubscription].self, from: response.data)
            if let subscription = subscriptions?.first {
                // Check if subscription is still valid
                if let expiresAt = subscription.expires_at, expiresAt > Date() {
                    let tier = getTierForProductId(subscription.product_id ?? "")

                    await MainActor.run {
                        self.isSubscribed = true
                        self.currentTier = tier

                        // Check trial period based on purchase date (only for full access)
                        if let purchaseDate = subscription.purchase_date, tier == .fullAccess {
                            let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
                            let timeSincePurchase = Date().timeIntervalSince(purchaseDate)
                            self.isInTrialPeriod = timeSincePurchase <= trialDuration
                        }
                    }

                    // Load current week usage for part-time tier
                    if tier == .partTime {
                        await loadCurrentWeekUsage()
                    }

                    return true
                }
            }
        } catch {
            print("Server subscription check failed: \(error)")
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
        await checkSubscriptionStatus()
    }

    private func schedulePeriodicValidation() async {
        // Check subscription status every 6 hours to ensure it's still valid
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 6 * 60 * 60 * 1_000_000_000) // 6 hours
            await checkSubscriptionStatus()
        }
    }

    // Force refresh subscription status (can be called manually)
    func refreshSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }
    
    // Start subscription checking (call this only after user is authenticated)
    func startSubscriptionChecking() async {
        await MainActor.run {
            self.isCheckingSubscription = true
        }
        
        await loadProducts()
        await checkSubscriptionStatus()
        
        // Schedule periodic subscription validation
        await schedulePeriodicValidation()
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

    // MARK: - Part-time Tier Limit Management

    func loadCurrentWeekUsage() async {
        guard currentTier == .partTime else { return }

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id

            // Get start of current week (Sunday)
            let calendar = Calendar.current
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            let daysToSubtract = weekday - 1 // Sunday is 1
            let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
            let startOfWeekString = ISO8601DateFormatter().string(from: startOfWeek)

            // Count shifts this week
            let shiftsResponse = try await SupabaseManager.shared.client
                .from("shifts")
                .select("id")
                .eq("user_id", value: userId)
                .gte("date", value: startOfWeekString)
                .execute()

            let shiftsData = try JSONSerialization.jsonObject(with: shiftsResponse.data) as? [[String: Any]] ?? []
            let shiftsCount = shiftsData.count

            // Count entries this week (sum of all entries across shifts)
            let entriesResponse = try await SupabaseManager.shared.client
                .from("shift_entries")
                .select("id, shift_id")
                .eq("user_id", value: userId)
                .gte("created_at", value: startOfWeekString)
                .execute()

            let entriesData = try JSONSerialization.jsonObject(with: entriesResponse.data) as? [[String: Any]] ?? []
            let entriesCount = entriesData.count

            await MainActor.run {
                self.currentWeekShifts = shiftsCount
                self.currentWeekEntries = entriesCount
            }
        } catch {
            print("Failed to load weekly usage: \(error)")
        }
    }

    func canAddShift() -> Bool {
        guard currentTier == .partTime else { return true }
        return currentWeekShifts < (currentTier.shiftsPerWeekLimit ?? Int.max)
    }

    func canAddEntry() -> Bool {
        guard currentTier == .partTime else { return true }
        return currentWeekEntries < (currentTier.entriesPerWeekLimit ?? Int.max)
    }

    func incrementShiftCount() {
        currentWeekShifts += 1
    }

    func incrementEntryCount() {
        currentWeekEntries += 1
    }

    func getRemainingShifts() -> Int? {
        guard currentTier == .partTime,
              let limit = currentTier.shiftsPerWeekLimit else { return nil }
        return max(0, limit - currentWeekShifts)
    }

    func getRemainingEntries() -> Int? {
        guard currentTier == .partTime,
              let limit = currentTier.entriesPerWeekLimit else { return nil }
        return max(0, limit - currentWeekEntries)
    }
}
