import SwiftUI
import LocalAuthentication

struct SecuritySettingsSection: View {
    @Binding var showPINSetup: Bool
    @Binding var isVerifyingToDisable: Bool
    @Binding var selectedSecurityType: SecurityType
    @ObservedObject var securityManager: SecurityManager

    let language: String
    private let localization: SettingsLocalization

    init(
        showPINSetup: Binding<Bool>,
        isVerifyingToDisable: Binding<Bool>,
        selectedSecurityType: Binding<SecurityType>,
        securityManager: SecurityManager,
        language: String
    ) {
        self._showPINSetup = showPINSetup
        self._isVerifyingToDisable = isVerifyingToDisable
        self._selectedSecurityType = selectedSecurityType
        self.securityManager = securityManager
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title with icon
            HStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.securitySection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            VStack(spacing: Constants.formFieldSpacing) {
                // App Lock Security
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.appLockSecurity)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    VStack(spacing: 8) {
                        // None Option
                        securityOptionButton(
                            type: .none,
                            title: localization.noneSecurityType,
                            icon: "lock.open",
                            isSelected: selectedSecurityType == .none
                        )

                        // PIN Option
                        securityOptionButton(
                            type: .pinCode,
                            title: localization.pinSecurityType,
                            icon: "lock.fill",
                            isSelected: selectedSecurityType == .pinCode
                        )

                        // Biometric Option (if available)
                        if canUseBiometrics {
                            securityOptionButton(
                                type: .biometric,
                                title: biometricTitle,
                                icon: biometricIcon,
                                isSelected: selectedSecurityType == .biometric
                            )
                        }
                    }
                }
                .padding(Constants.formPadding)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

                // Change PIN Button (if PIN is enabled)
                if securityManager.currentSecurityType == .pinCode {
                    Button(action: {
                        showPINSetup = true
                    }) {
                        HStack {
                            Image(systemName: "key")
                                .foregroundStyle(.secondary)
                            Text(localization.changePIN)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Constants.formPadding)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .liquidGlassForm()
                }
            }
        }
        .sheet(isPresented: $showPINSetup) {
            PINSetupView(securityManager: securityManager, language: language, targetSecurityType: selectedSecurityType)
        }
        .onChange(of: selectedSecurityType) { _, newType in
            handleSecurityTypeChange(newType)
        }
    }

    private func securityOptionButton(
        type: SecurityType,
        title: String,
        icon: String,
        isSelected: Bool
    ) -> some View {
        Button(action: {
            selectedSecurityType = type
        }) {
            HStack {
                // Only show icon for biometric option
                if type == .biometric {
                    Image(systemName: icon)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                        .frame(width: 24, height: 24)
                }

                Text(title)
                    .foregroundStyle(.primary)
                    .fontWeight(isSelected ? .medium : .regular)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var canUseBiometrics: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    private var biometricTitle: String {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            switch context.biometryType {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            default:
                return localization.biometricSecurityType
            }
        }
        return localization.biometricSecurityType
    }

    private var biometricIcon: String {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            switch context.biometryType {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            default:
                return "person.crop.circle"
            }
        }
        return "person.crop.circle"
    }

    private func handleSecurityTypeChange(_ newType: SecurityType) {
        switch newType {
        case .none:
            if securityManager.currentSecurityType != .none {
                // Verify current security before disabling
                isVerifyingToDisable = true
                securityManager.authenticateWithBiometric { success in
                    DispatchQueue.main.async {
                        if success {
                            securityManager.disableAllSecurity()
                        } else {
                            selectedSecurityType = securityManager.currentSecurityType
                        }
                        isVerifyingToDisable = false
                    }
                }
            }

        case .pinCode:
            if securityManager.currentSecurityType == .none {
                showPINSetup = true
            } else {
                securityManager.setSecurityType(.pinCode)
            }

        case .biometric:
            if canUseBiometrics {
                // For biometric, we need to set up PIN first as fallback
                if securityManager.currentSecurityType == .none {
                    showPINSetup = true
                } else {
                    // If we already have PIN, just enable biometric
                    securityManager.setSecurityType(.biometric)
                }
            }

        case .both:
            // This would require both PIN and biometric setup
            // For now, treat as biometric
            if canUseBiometrics {
                if securityManager.currentSecurityType == .none {
                    showPINSetup = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        securityManager.setSecurityType(.both)
                    }
                } else {
                    securityManager.setSecurityType(.both)
                }
            }
        }
    }
}

// MARK: - PIN Setup View

struct PINSetupView: View {
    @ObservedObject var securityManager: SecurityManager
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isSettingPin = true
    @State private var showError = false
    @State private var errorMessage = ""

    let language: String
    private let localization: SettingsLocalization

    let targetSecurityType: SecurityType
    
    init(securityManager: SecurityManager, language: String, targetSecurityType: SecurityType = .pinCode) {
        self.securityManager = securityManager
        self.language = language
        self.targetSecurityType = targetSecurityType
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text(isSettingPin ? "Enter PIN" : "Confirm PIN")
                    .font(.title2)
                    .fontWeight(.semibold)

                // PIN Input Display
                HStack(spacing: 15) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < currentPin.count ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }
                }

                // Number Pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        numberButton(number: "\(number)")
                    }

                    Button(action: clearPin) {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .frame(width: 80, height: 80)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())

                    numberButton(number: "0")

                    Button(action: submitPin) {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                    .frame(width: 80, height: 80)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .disabled(currentPin.count != 4)
                }
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("Security Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.cancelButton) {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var currentPin: String {
        isSettingPin ? pin : confirmPin
    }

    private func numberButton(number: String) -> some View {
        Button(action: {
            addNumber(number)
        }) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(width: 80, height: 80)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }

    private func addNumber(_ number: String) {
        if currentPin.count < 4 {
            if isSettingPin {
                pin += number
            } else {
                confirmPin += number
            }

            if currentPin.count == 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    submitPin()
                }
            }
        }
    }

    private func clearPin() {
        if isSettingPin {
            if !pin.isEmpty {
                pin.removeLast()
            }
        } else {
            if !confirmPin.isEmpty {
                confirmPin.removeLast()
            }
        }
    }

    private func submitPin() {
        if isSettingPin && pin.count == 4 {
            isSettingPin = false
        } else if !isSettingPin && confirmPin.count == 4 {
            if pin == confirmPin {
                if securityManager.setPINCode(pin) {
                    // Set the target security type (PIN or biometric)
                    securityManager.setSecurityType(targetSecurityType)
                    dismiss()
                } else {
                    errorMessage = "Failed to set PIN. Please try again."
                    showError = true
                    pin = ""
                    confirmPin = ""
                    isSettingPin = true
                }
            } else {
                errorMessage = "PINs don't match. Please try again."
                showError = true
                pin = ""
                confirmPin = ""
                isSettingPin = true
            }
        }
    }
}