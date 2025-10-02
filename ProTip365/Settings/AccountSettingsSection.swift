import SwiftUI
import Supabase
import StoreKit

struct AccountSettingsSection: View {
    @Binding var showSignOutAlert: Bool
    @Binding var showDeleteAccountAlert: Bool
    @Binding var isDeletingAccount: Bool
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let language: String
    private let localization: SettingsLocalization

    init(
        showSignOutAlert: Binding<Bool>,
        showDeleteAccountAlert: Binding<Bool>,
        isDeletingAccount: Binding<Bool>,
        language: String
    ) {
        self._showSignOutAlert = showSignOutAlert
        self._showDeleteAccountAlert = showDeleteAccountAlert
        self._isDeletingAccount = isDeletingAccount
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Cancel Subscription Card - only show if user has active subscription
            if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
                VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.tint)
                            .symbolRenderingMode(.monochrome)
                            .frame(width: 28, height: 28)
                        Text(localization.cancelSubscriptionTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.cancelSubscriptionInstructions)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(localization.cancelSubscriptionWarning)
                            .font(.caption)
                            .foregroundStyle(.tint)
                            .fontWeight(.medium)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: {
                        HapticFeedback.selection()
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }) {
                        HStack {
                            Image(systemName: IconNames.Navigation.settings)
                            Text(localization.goToAppleAccountText)
                            Spacer()
                            Image(systemName: IconNames.Form.next)
                        }
                        .foregroundStyle(.tint)
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            }

            // Sign Out & Delete Account Card
            VStack(spacing: 0) {
                // Sign Out
                Button(action: {
                    HapticFeedback.medium()
                    showSignOutAlert = true
                }) {
                    HStack {
                        Text(localization.signOut)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding()
                }

                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 0.5)

                // Delete Account
                Button(action: {
                    HapticFeedback.medium()
                    showDeleteAccountAlert = true
                }) {
                    HStack {
                        Text(localization.deleteAccount)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .alert(localization.signOutConfirmTitle, isPresented: $showSignOutAlert) {
            Button(localization.cancelButton, role: .cancel) { }
            Button(localization.signOut, role: .destructive) {
                signOut()
            }
        } message: {
            Text(localization.signOutConfirmMessage)
        }
        .alert(localization.deleteAccountConfirmTitle, isPresented: $showDeleteAccountAlert) {
            Button(localization.cancelButton, role: .cancel) { }
            Button(localization.deleteAccount, role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(localization.deleteAccountConfirmMessage)
        }
        .overlay {
            if isDeletingAccount {
                deletingAccountOverlay
            }
        }
    }

    private var deletingAccountOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Deleting Account...")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Please wait while we process your request.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(40)
        }
    }

    private func openSubscriptionSettings() {
        #if os(iOS)
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func signOut() {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
                await MainActor.run {
                    // Reset to auth view - this would typically be handled by the parent view
                    NotificationCenter.default.post(name: .userDidSignOut, object: nil)
                }
            } catch {
                print("Error signing out: \(error)")
            }
        }
    }

    private func clearAllStoreKitTransactions() async {
        // Finish all pending transactions to clear the subscription state
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            // Finish the transaction to remove it from currentEntitlements
            await transaction.finish()
            print("Cleared StoreKit transaction: \(transaction.productID)")
        }
        print("All StoreKit transactions cleared")
    }

    private func deleteAccount() {
        isDeletingAccount = true

        Task {
            do {
                // Get current session
                let session = try await SupabaseManager.shared.client.auth.session
                let authToken = session.accessToken

                // Call the Edge Function to delete the user completely
                // Get the Supabase URL directly from Info.plist
                guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
                    print("❌ Failed to get Supabase URL from Info.plist")
                    throw NSError(domain: "ProTip365", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing Supabase URL"])
                }
                let edgeFunctionURL = "\(baseURL)/functions/v1/delete-user"

                var request = URLRequest(url: URL(string: edgeFunctionURL)!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Account deleted successfully via Edge Function")
                    } else {
                        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                        print("❌ Edge Function deletion failed: \(errorMessage)")

                        // Fallback to manual deletion
                        let userId = session.user.id

                        // Delete all user data manually using new simplified structure
                        _ = try? await SupabaseManager.shared.client
                            .from("shift_entries")
                            .delete()
                            .eq("user_id", value: userId)
                            .execute()

                        _ = try? await SupabaseManager.shared.client
                            .from("expected_shifts")
                            .delete()
                            .eq("user_id", value: userId)
                            .execute()

                        _ = try? await SupabaseManager.shared.client
                            .from("employers")
                            .delete()
                            .eq("user_id", value: userId)
                            .execute()

                        _ = try? await SupabaseManager.shared.client
                            .from("users_profile")
                            .delete()
                            .eq("user_id", value: userId)
                            .execute()

                        // Try RPC as last resort
                        do {
                            try await SupabaseManager.shared.client
                                .rpc("delete_account")
                                .execute()
                        } catch {
                            print("RPC delete_account also failed: \(error)")
                        }
                    }
                }

                // IMPORTANT: Clear all StoreKit transactions for this user
                // This prevents the subscription from persisting when recreating the account
                await clearAllStoreKitTransactions()

                // Sign out the user to clear the session
                try await SupabaseManager.shared.client.auth.signOut()

                await MainActor.run {
                    isDeletingAccount = false
                    // Post notification to trigger app reset
                    NotificationCenter.default.post(name: .userDidDeleteAccount, object: nil)
                }

            } catch {
                print("Error during account deletion process: \(error)")

                // Always try to sign out even if something fails
                do {
                    try await SupabaseManager.shared.client.auth.signOut()
                } catch {
                    print("Failed to sign out after deletion error: \(error)")
                }

                await MainActor.run {
                    isDeletingAccount = false
                    // Still post notification to reset the app
                    NotificationCenter.default.post(name: .userDidDeleteAccount, object: nil)
                }
            }
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let userDidDeleteAccount = Notification.Name("userDidDeleteAccount")
}