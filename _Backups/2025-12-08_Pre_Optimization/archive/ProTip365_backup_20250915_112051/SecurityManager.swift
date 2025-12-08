import LocalAuthentication
import SwiftUI
import CryptoKit

enum SecurityType: String {
    case none = "none"
    case biometric = "biometric"
    case pinCode = "pin"
    case both = "both" // Face ID with PIN fallback
}

class SecurityManager: ObservableObject {
    @Published var isUnlocked = false
    @Published var showPINEntry = false

    @AppStorage("securityType") private var securityType = SecurityType.none.rawValue
    @AppStorage("pinCodeHash") var pinCodeHash = ""
    @AppStorage("biometricEnabled") var biometricEnabled = false

    var currentSecurityType: SecurityType {
        SecurityType(rawValue: securityType) ?? .none
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
    }

    func disableAllSecurity() {
        securityType = SecurityType.none.rawValue
        biometricEnabled = false
        pinCodeHash = ""
        isUnlocked = true
        showPINEntry = false
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