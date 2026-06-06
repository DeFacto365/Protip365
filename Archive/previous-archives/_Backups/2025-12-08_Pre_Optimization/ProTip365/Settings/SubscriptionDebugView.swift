import SwiftUI
import StoreKit

struct SubscriptionDebugView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var transactions: [TransactionInfo] = []
    @State private var isLoading = false

    struct TransactionInfo: Identifiable {
        let id: UInt64
        let productId: String
        let purchaseDate: Date
        let expirationDate: Date?
        let environment: String
        let isVerified: Bool
    }

    var body: some View {
        List {
            Section("Current Subscription State") {
                HStack {
                    Text("Is Subscribed")
                    Spacer()
                    Text(subscriptionManager.isSubscribed ? "✅ Yes" : "❌ No")
                        .foregroundColor(subscriptionManager.isSubscribed ? .green : .red)
                }

                HStack {
                    Text("Current Tier")
                    Spacer()
                    Text(subscriptionManager.currentTier.rawValue)
                }

                HStack {
                    Text("In Trial")
                    Spacer()
                    Text(subscriptionManager.isInTrialPeriod ? "Yes" : "No")
                }

                if subscriptionManager.isInTrialPeriod {
                    HStack {
                        Text("Trial Days Left")
                        Spacer()
                        Text("\(subscriptionManager.trialDaysRemaining)")
                    }
                }
            }

            Section("StoreKit Transactions") {
                if transactions.isEmpty && !isLoading {
                    Text("No active transactions found")
                        .foregroundColor(.secondary)
                } else if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach(transactions) { transaction in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(transaction.productId)
                                    .font(.headline)
                                Spacer()
                                Text(transaction.isVerified ? "✅" : "⚠️")
                            }

                            HStack {
                                Text("ID:")
                                    .foregroundColor(.secondary)
                                Text("\(transaction.id)")
                                    .font(.caption)
                            }

                            HStack {
                                Text("Purchased:")
                                    .foregroundColor(.secondary)
                                Text(transaction.purchaseDate.formatted())
                                    .font(.caption)
                            }

                            if let expiration = transaction.expirationDate {
                                HStack {
                                    Text("Expires:")
                                        .foregroundColor(.secondary)
                                    Text(expiration.formatted())
                                        .font(.caption)
                                }
                            }

                            HStack {
                                Text("Environment:")
                                    .foregroundColor(.secondary)
                                Text(transaction.environment)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Actions") {
                Button("Refresh Subscription Status") {
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                        await loadTransactions()
                    }
                }

                Button("Clear Local Subscription State", role: .destructive) {
                    subscriptionManager.resetSubscriptionState()
                }

                #if DEBUG
                Button("Clear All StoreKit Transactions", role: .destructive) {
                    Task {
                        await clearAllTransactions()
                    }
                }
                #endif
            }

            Section("Instructions") {
                Text("If you see transactions you didn't purchase:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. These are test purchases from development")
                    Text("2. Go to Settings → Your Name → Subscriptions")
                    Text("3. Cancel any ProTip365 test subscriptions")
                    Text("4. Or clear StoreKit transactions (DEBUG mode)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Subscription Debug")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTransactions()
        }
    }

    private func loadTransactions() async {
        isLoading = true
        var txs: [TransactionInfo] = []

        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                txs.append(TransactionInfo(
                    id: transaction.id,
                    productId: transaction.productID,
                    purchaseDate: transaction.purchaseDate,
                    expirationDate: transaction.expirationDate,
                    environment: transaction.environment.rawValue,
                    isVerified: true
                ))
            case .unverified(let transaction, _):
                txs.append(TransactionInfo(
                    id: transaction.id,
                    productId: transaction.productID,
                    purchaseDate: transaction.purchaseDate,
                    expirationDate: transaction.expirationDate,
                    environment: transaction.environment.rawValue,
                    isVerified: false
                ))
            }
        }

        await MainActor.run {
            transactions = txs
            isLoading = false
        }
    }

    #if DEBUG
    private func clearAllTransactions() async {
        // This only works in DEBUG/Sandbox mode
        // It clears the local StoreKit transaction cache
        for await result in StoreKit.Transaction.all {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
        }

        await loadTransactions()
    }
    #endif
}
