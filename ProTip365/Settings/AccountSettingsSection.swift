import SwiftUI
import Supabase

struct AccountSettingsSection: View {
    @Binding var showSignOutAlert: Bool
    @Binding var showDeleteAccountAlert: Bool
    @Binding var isDeletingAccount: Bool

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
        Section(localization.accountSection) {
            VStack(spacing: Constants.formFieldSpacing) {
                // Manage Subscription
                Button(action: openSubscriptionSettings) {
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundStyle(.blue)
                            .frame(width: 24, height: 24)

                        Text(localization.manageSubscription)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Constants.formPadding)
                }
                .buttonStyle(SecondaryButtonStyle())
                .liquidGlassForm()

                // Sign Out
                Button(action: {
                    showSignOutAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .foregroundStyle(.orange)
                            .frame(width: 24, height: 24)

                        Text(localization.signOut)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(Constants.formPadding)
                }
                .buttonStyle(SecondaryButtonStyle())
                .liquidGlassForm()

                // Delete Account
                Button(action: {
                    showDeleteAccountAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                            .frame(width: 24, height: 24)

                        Text(localization.deleteAccount)
                            .foregroundStyle(.red)

                        Spacer()
                    }
                    .padding(Constants.formPadding)
                }
                .buttonStyle(SecondaryButtonStyle())
                .liquidGlassForm()
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
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

    private func deleteAccount() {
        isDeletingAccount = true

        Task {
            do {
                // Get current user
                let userId = try await SupabaseManager.shared.client.auth.session.user.id

                // Note: In Supabase, CASCADE DELETE should handle related records
                // when the user is deleted, but we'll try to delete them first
                // to ensure clean removal

                // Delete shift_income records first (child records)
                _ = try? await SupabaseManager.shared.client
                    .from("shift_income")
                    .delete()
                    .eq("user_id", value: userId)
                    .execute()

                // Delete shifts
                _ = try? await SupabaseManager.shared.client
                    .from("shifts")
                    .delete()
                    .eq("user_id", value: userId)
                    .execute()

                // Delete employers
                _ = try? await SupabaseManager.shared.client
                    .from("employers")
                    .delete()
                    .eq("user_id", value: userId)
                    .execute()

                // Delete profile
                _ = try? await SupabaseManager.shared.client
                    .from("users_profile")
                    .delete()
                    .eq("user_id", value: userId)
                    .execute()

                // Try to use RPC to delete the user account if available
                // This requires a database function that the user can call
                do {
                    try await SupabaseManager.shared.client
                        .rpc("delete_user_account")
                        .execute()
                } catch {
                    print("RPC delete_user_account not available or failed: \(error)")
                    // Continue anyway - data is already deleted
                }

                // IMPORTANT: Sign out the user to clear the session
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