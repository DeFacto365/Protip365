import SwiftUI

struct PINEntryView: View {
    @ObservedObject var securityManager: SecurityManager
    @State private var pin = ""
    @State private var showError = false
    @State private var attempts = 0
    @AppStorage("language") private var language = "en"

    let isSettingPIN: Bool // true when setting new PIN, false when verifying
    var onSuccess: (() -> Void)?
    var onCancel: (() -> Void)?

    private let maxPINLength = 6
    private let maxAttempts = 3

    // Localization
    private var titleText: String {
        if isSettingPIN {
            switch language {
            case "fr": return "Créer un code PIN"
            case "es": return "Crear código PIN"
            default: return "Create PIN Code"
            }
        } else {
            switch language {
            case "fr": return "Entrer le code PIN"
            case "es": return "Ingrese el código PIN"
            default: return "Enter PIN Code"
            }
        }
    }

    private var subtitleText: String {
        if isSettingPIN {
            switch language {
            case "fr": return "Choisissez un code à 6 chiffres"
            case "es": return "Elija un código de 6 dígitos"
            default: return "Choose a 6-digit code"
            }
        } else {
            switch language {
            case "fr": return "Entrez votre code PIN pour accéder"
            case "es": return "Ingrese su PIN para acceder"
            default: return "Enter your PIN to access"
            }
        }
    }

    private var errorText: String {
        switch language {
        case "fr": return "Code PIN incorrect"
        case "es": return "PIN incorrecto"
        default: return "Incorrect PIN"
        }
    }

    private var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            // Logo
            Image("Logo2")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Title
            VStack(spacing: 8) {
                Text(titleText)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // PIN Display
            HStack(spacing: 15) {
                ForEach(0..<maxPINLength, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            .padding(.vertical)

            // Error message
            if showError {
                Text(errorText)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.scale.combined(with: .opacity))
            }

            // Number Pad
            VStack(spacing: 20) {
                ForEach(0..<3) { row in
                    HStack(spacing: 30) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            NumberButton(number: "\(number)") {
                                addDigit("\(number)")
                            }
                        }
                    }
                }

                // Bottom row with 0
                HStack(spacing: 30) {
                    // Cancel button (only when not setting PIN initially)
                    if !isSettingPIN {
                        Button(action: {
                            onCancel?()
                        }) {
                            Text(cancelText)
                                .font(.body)
                                .frame(width: 75, height: 75)
                                .foregroundColor(.red)
                        }
                    } else {
                        Color.clear
                            .frame(width: 75, height: 75)
                    }

                    NumberButton(number: "0") {
                        addDigit("0")
                    }

                    // Delete button
                    Button(action: deleteDigit) {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .frame(width: 75, height: 75)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            pin = ""
            showError = false
        }
    }

    private func addDigit(_ digit: String) {
        guard pin.count < maxPINLength else { return }

        withAnimation(.easeInOut(duration: 0.1)) {
            pin += digit
            showError = false
        }

        // Check if PIN is complete (6 digits)
        if pin.count == maxPINLength {
            if isSettingPIN {
                // Setting new PIN - require exactly 6 digits
                completeEntry()
            } else {
                // Verifying PIN - check when 6 digits entered
                verifyPIN()
            }
        }
    }

    private func deleteDigit() {
        guard !pin.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.1)) {
            pin.removeLast()
            showError = false
        }
    }

    private func completeEntry() {
        if isSettingPIN {
            // Save the new PIN
            if securityManager.setPINCode(pin) {
                HapticFeedback.success()
                onSuccess?()
            } else {
                showError = true
                HapticFeedback.error()
            }
        } else {
            verifyPIN()
        }
    }

    private func verifyPIN() {
        if securityManager.verifyPINCode(pin) {
            HapticFeedback.success()
            onSuccess?()
        } else {
            withAnimation(.default) {
                showError = true
            }
            HapticFeedback.error()

            attempts += 1
            if attempts >= maxAttempts {
                // Too many attempts - could implement additional security here
                // For now, just reset
                attempts = 0
            }

            // Clear PIN after error
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pin = ""
            }
        }
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .frame(width: 75, height: 75)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())
        }
    }
}

#Preview {
    PINEntryView(
        securityManager: SecurityManager(),
        isSettingPIN: false
    )
}