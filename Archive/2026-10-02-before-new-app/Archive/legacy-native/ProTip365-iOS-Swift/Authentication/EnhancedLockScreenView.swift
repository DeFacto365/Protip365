import SwiftUI

struct EnhancedLockScreenView: View {
    @ObservedObject var securityManager: SecurityManager
    @AppStorage("language") private var language = "en"
    @State private var showPINSetup = false

    var body: some View {
        ZStack {
            if securityManager.showPINEntry {
                // Show PIN entry screen
                PINEntryView(
                    securityManager: securityManager,
                    isSettingPIN: false,
                    onSuccess: {
                        // PIN verified successfully
                    },
                    onCancel: {
                        // User cancelled - could exit app or show options
                    }
                )
            } else {
                // Show Face ID unlock screen
                VStack(spacing: 40) {
                    Spacer()

                    // App Logo
                    Image("Logo2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)

                    Text("ProTip365")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(lockedMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Unlock options based on security type
                    VStack(spacing: 16) {
                        if securityManager.currentSecurityType == .biometric ||
                           securityManager.currentSecurityType == .both {
                            Button(action: {
                                securityManager.authenticate()
                            }) {
                                HStack {
                                    Image(systemName: "faceid")
                                        .font(.title2)
                                    Text(unlockWithFaceIDText)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }

                        if securityManager.currentSecurityType == .pinCode ||
                           securityManager.currentSecurityType == .both {
                            Button(action: {
                                securityManager.showPINEntry = true
                            }) {
                                HStack {
                                    Image(systemName: "number.square")
                                        .font(.title2)
                                    Text(unlockWithPINText)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .onAppear {
            // Auto-authenticate if biometric is enabled
            if securityManager.currentSecurityType == .biometric ||
               securityManager.currentSecurityType == .both {
                securityManager.authenticate()
            }
        }
    }

    // Localization
    var lockedMessage: String {
        switch language {
        case "fr": return "Vos données sont protégées"
        case "es": return "Sus datos están protegidos"
        default: return "Your data is protected"
        }
    }

    var unlockWithFaceIDText: String {
        switch language {
        case "fr": return "Déverrouiller avec Face ID"
        case "es": return "Desbloquear con Face ID"
        default: return "Unlock with Face ID"
        }
    }

    var unlockWithPINText: String {
        switch language {
        case "fr": return "Utiliser le code PIN"
        case "es": return "Usar código PIN"
        default: return "Use PIN Code"
        }
    }
}

#Preview {
    EnhancedLockScreenView(securityManager: SecurityManager())
}