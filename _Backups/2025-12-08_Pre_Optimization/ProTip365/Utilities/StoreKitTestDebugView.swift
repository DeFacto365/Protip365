import SwiftUI

#if DEBUG
/// Debug view for StoreKitTest functionality - only available in DEBUG builds
struct StoreKitTestDebugView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showTestTransactionSheet = false

    var body: some View {
        List {
            Section("Testing Mode") {
                #if DEBUG && canImport(StoreKitTest)
                Toggle("Enable StoreKit Testing", isOn: $subscriptionManager.isTestingMode)
                    .onChange(of: subscriptionManager.isTestingMode) { newValue in
                        Task {
                            if newValue {
                                await subscriptionManager.enableTestingMode()
                            }
                        }
                    }

                if subscriptionManager.isTestingMode {
                    Button("Add Test Transaction") {
                        showTestTransactionSheet = true
                    }
                    .foregroundColor(.blue)

                    Button("Clear All Test Transactions") {
                        Task {
                            await subscriptionManager.clearTestTransactions()
                        }
                    }
                    .foregroundColor(.red)
                }
                #else
                Text("StoreKitTest not available on this platform")
                    .foregroundColor(.secondary)
                #endif
            }

            Section("Subscription Status") {
                Text("Status: \(subscriptionManager.getSubscriptionStatusText())")
                Text("Products Loaded: \(subscriptionManager.products.count)")

                #if DEBUG && canImport(StoreKitTest)
                if !subscriptionManager.testTransactions.isEmpty {
                    Text("Test Transactions: \(subscriptionManager.testTransactions.count)")
                }
                #endif
            }

            Section("Actions") {
                Button("Load Products") {
                    Task {
                        await subscriptionManager.loadProducts()
                    }
                }

                Button("Check Subscription Status") {
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                }
            }
        }
        .navigationTitle("StoreKit Debug")
        .sheet(isPresented: $showTestTransactionSheet) {
            TestTransactionSheet(subscriptionManager: subscriptionManager)
        }
        .onAppear {
            // Auto-enable testing mode when view appears
            #if DEBUG && canImport(StoreKitTest)
            if !subscriptionManager.isTestingMode {
                Task {
                    await subscriptionManager.enableTestingMode()
                }
            }
            #endif
        }
    }
}

struct TestTransactionSheet: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                #if DEBUG && canImport(StoreKitTest)
                Button("Add Premium Subscription") {
                    Task {
                        await subscriptionManager.addTestTransaction(productId: "com.protip365.premium.monthly")
                        dismiss()
                    }
                }
                .foregroundColor(.green)

                Button("Add Failed Transaction") {
                    Task {
                        await subscriptionManager.addTestTransaction(
                            productId: "com.protip365.premium.monthly",
                            state: "failed"
                        )
                        dismiss()
                    }
                }
                .foregroundColor(.red)
                
                Button("Add Trial Subscription") {
                    Task {
                        await subscriptionManager.addTestTransaction(
                            productId: "com.protip365.premium.monthly",
                            state: "trial"
                        )
                        dismiss()
                    }
                }
                .foregroundColor(.orange)
                #else
                Text("StoreKitTest not available")
                    .foregroundColor(.secondary)
                #endif
            }
            .navigationTitle("Add Test Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Extension to make StoreKitTestDebugView accessible
extension View {
    #if DEBUG
    func storeKitDebug() -> some View {
        #if DEBUG
        return AnyView(
            NavigationLink("StoreKit Debug") {
                StoreKitTestDebugView()
            }
        )
        #else
        return AnyView(self)
        #endif
    }
    #endif
}
#endif
