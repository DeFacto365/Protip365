import LocalAuthentication
import SwiftUI
import CryptoKit
import Supabase

enum SecurityType: String {
    case none = "none"
    case biometric = "biometric"
    case pinCode = "pin"
    case both = "both" // Face ID with PIN fallback
}

class SecurityManager: ObservableObject {
    @Published var isUnlocked = false
    @Published var showPINEntry = false

    // CRITICAL SECURITY FIX: Store per-user in database, not per-device in AppStorage!
    private var securityType = SecurityType.none.rawValue
    private var pinCodeHash = ""
    private var biometricEnabled = false
    private var currentUserId: UUID?

    var currentSecurityType: SecurityType {
        SecurityType(rawValue: securityType) ?? .none
    }

    // MARK: - User Session Management

    /// Load security settings from database for the current user
    func loadSecuritySettings(for userId: UUID) async {
        print("🔐 Loading security settings for user: \(userId)")
        self.currentUserId = userId

        do {
            let profile: UserProfile = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("security_type, pin_code_hash, biometric_enabled")
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value

            await MainActor.run {
                self.securityType = profile.security_type ?? "none"
                self.pinCodeHash = profile.pin_code_hash ?? ""
                self.biometricEnabled = profile.biometric_enabled ?? false
                print("✅ Security settings loaded: \(self.securityType)")
            }
        } catch {
            print("❌ Failed to load security settings: \(error)")
            // Default to no security if load fails
            await MainActor.run {
                self.securityType = "none"
                self.pinCodeHash = ""
                self.biometricEnabled = false
            }
        }
    }

    /// Save security settings to database for the current user
    private func saveSecuritySettings() async {
        guard let userId = currentUserId else {
            print("❌ Cannot save security settings - no user ID")
            return
        }

        print("💾 Saving security settings for user: \(userId)")

        do {
            struct SecurityUpdate: Encodable {
                let security_type: String
                let pin_code_hash: String?
                let biometric_enabled: Bool
            }

            let update = SecurityUpdate(
                security_type: securityType,
                pin_code_hash: pinCodeHash.isEmpty ? nil : pinCodeHash,
                biometric_enabled: biometricEnabled
            )

            try await SupabaseManager.shared.client
                .from("users_profile")
                .update(update)
                .eq("user_id", value: userId)
                .execute()

            print("✅ Security settings saved successfully")
        } catch {
            print("❌ Failed to save security settings: \(error)")
        }
    }

    /// Clear all security settings (call on sign out)
    func clearSecuritySettings() {
        print("🧹 Clearing security settings")
        securityType = "none"
        pinCodeHash = ""
        biometricEnabled = false
        currentUserId = nil
        isUnlocked = false
        showPINEntry = false
    }

    // MARK: - Authentication

    func authenticate() {
        switch currentSecurityType {
        case .none:
            isUnlocked = true
        case .biometric:
            authenticateWithBiometric()
        case .pinCode:
            showPINEntry = true
        case .both:
            // Try biometric first, fallback to PIN
            authenticateWithBiometric(fallbackToPIN: true)
        }
    }

    private func authenticateWithBiometric(fallbackToPIN: Bool = false) {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = NSLocalizedString("Unlock ProTip365 to view your data", comment: "")

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        self.showPINEntry = false
                    } else if fallbackToPIN {
                        // If biometric fails and we have fallback, show PIN entry
                        self.showPINEntry = true
                    }
                }
            }
        } else if fallbackToPIN || currentSecurityType == .pinCode {
            // No biometrics available, use PIN
            showPINEntry = true
        } else {
            // No security available
            isUnlocked = true
        }
    }

    // MARK: - PIN Code Management

    func setPINCode(_ pin: String) -> Bool {
        guard pin.count >= 4 && pin.count <= 8 else { return false }

        // Hash the PIN for secure storage
        if let data = pin.data(using: .utf8) {
            let hashed = SHA256.hash(data: data)
            pinCodeHash = hashed.compactMap { String(format: "%02x", $0) }.joined()

            // Save to database
            Task {
                await saveSecuritySettings()
            }

            return true
        }
        return false
    }

    func verifyPINCode(_ pin: String) -> Bool {
        guard !pinCodeHash.isEmpty else { return false }

        if let data = pin.data(using: .utf8) {
            let hashed = SHA256.hash(data: data)
            let inputHash = hashed.compactMap { String(format: "%02x", $0) }.joined()

            if inputHash == pinCodeHash {
                isUnlocked = true
                showPINEntry = false
                return true
            }
        }
        return false
    }

    func removePINCode() {
        pinCodeHash = ""
        if currentSecurityType == .pinCode {
            securityType = SecurityType.none.rawValue
        }
    }

    // MARK: - Security Settings

    func setSecurityType(_ type: SecurityType) {
        securityType = type.rawValue

        // Update biometric setting for compatibility
        biometricEnabled = (type == .biometric || type == .both)

        if type == .none {
            isUnlocked = true
            pinCodeHash = ""
        }

        // Save to database
        Task {
            await saveSecuritySettings()
        }
    }

    func disableAllSecurity() {
        securityType = SecurityType.none.rawValue
        biometricEnabled = false
        pinCodeHash = ""
        isUnlocked = true
        showPINEntry = false

        // Save to database
        Task {
            await saveSecuritySettings()
        }
    }

    // MARK: - Lock Management

    func lockApp() {
        isUnlocked = false
        showPINEntry = false
    }

    func unlockApp() {
        isUnlocked = true
        showPINEntry = false
    }

    // MARK: - Authentication with Completion Handler

    func authenticateWithBiometric(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = NSLocalizedString("Authenticate to change security settings", comment: "")

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}