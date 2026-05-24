import StoreKit
import SwiftUI
import Supabase

class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var isInTrialPeriod = false
    @Published var isCheckingSubscription = true // Start as true to prevent flash
    @Published var products: [Product] = []

    private let productId = "com.protip365.monthly"
    private var transactionListener: Task<Void, Error>?

    init() {
        // Start listening for transaction updates immediately
        transactionListener = listenForTransactionUpdates()

        Task {
            await loadProducts()
            await checkSubscriptionStatus()

            // Schedule periodic subscription validation
            await schedulePeriodicValidation()
        }
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
        if transaction.productID == productId {
            await checkSubscriptionStatus()
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productId])
            await MainActor.run {
                self.products = products
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase() async {
        guard let product = products.first else { return }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Sync to server immediately after purchase
                    await syncSubscriptionToServer(transaction: transaction)
                    await transaction.finish()
                    await checkSubscriptionStatus()
                case .unverified:
                    print("Unverified transaction")
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    func checkSubscriptionStatus() async {
        // First check server-side subscription (for cross-device sync)
        if await checkServerSubscription() {
            await MainActor.run {
                self.isCheckingSubscription = false
            }
            return // Found active subscription on server
        }

        // Then check local StoreKit transactions
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.productID == productId {
                await MainActor.run {
                    self.isSubscribed = true

                    // For subscriptions, check trial period
                    if transaction.productType == .autoRenewable {
                        // Simply check if we're within the first 7 days
                        let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
                        let timeSincePurchase = Date().timeIntervalSince(transaction.originalPurchaseDate)
                        self.isInTrialPeriod = timeSincePurchase <= trialDuration
                    }

                    self.isCheckingSubscription = false
                }

                // Sync to server for other devices
                await syncSubscriptionToServer(transaction: transaction)
                return
            }
        }

        await MainActor.run {
            self.isSubscribed = false
            self.isInTrialPeriod = false
            self.isCheckingSubscription = false
        }
    }

    // Check server-side subscription status
    private func checkServerSubscription() async -> Bool {
        do {
            // Get current user ID
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id

            // Query for active subscription
            let response = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .single()
                .execute()

            // Parse the response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let subscription = try? decoder.decode(ServerSubscription.self, from: response.data) {
                // Check if subscription is still valid
                if let expiresAt = subscription.expires_at, expiresAt > Date() {
                    await MainActor.run {
                        self.isSubscribed = true

                        // Check trial period based on purchase date
                        if let purchaseDate = subscription.purchase_date {
                            let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
                            let timeSincePurchase = Date().timeIntervalSince(purchaseDate)
                            self.isInTrialPeriod = timeSincePurchase <= trialDuration
                        }
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
}
