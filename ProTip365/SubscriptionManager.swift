import StoreKit
import SwiftUI

class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var isInTrialPeriod = false
    @Published var products: [Product] = []
    
    private let productId = "com.protip365.monthly"
    
    init() {
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
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
        for await result in Transaction.currentEntitlements {
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
                }
                return
            }
        }
        
        await MainActor.run {
            self.isSubscribed = false
            self.isInTrialPeriod = false
        }
    }
    
    func restorePurchases() async {
        await checkSubscriptionStatus()
    }
}
