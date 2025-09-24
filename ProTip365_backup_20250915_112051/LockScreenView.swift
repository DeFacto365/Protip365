import SwiftUI

struct LockScreenView: View {
    @ObservedObject var biometricAuth: BiometricAuthManager
    @AppStorage("language") private var language = "en"
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon
            Image(systemName: "percent")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 100, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .shadow(radius: 10)
            
            Text("ProTip365")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(lockedMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                biometricAuth.authenticate()
            }) {
                HStack {
                    Image(systemName: "faceid")
                        .font(.title2)
                    Text(unlockButton)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    var lockedMessage: String {
        switch language {
        case "fr": return "Vos données sont protégées"
        case "es": return "Sus datos están protegidos"
        default: return "Your data is protected"
        }
    }
    
    var unlockButton: String {
        switch language {
        case "fr": return "Déverrouiller"
        case "es": return "Desbloquear"
        default: return "Unlock"
        }
    }
}
