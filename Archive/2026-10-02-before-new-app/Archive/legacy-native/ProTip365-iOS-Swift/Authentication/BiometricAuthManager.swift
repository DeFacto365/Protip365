import LocalAuthentication
import SwiftUI

class BiometricAuthManager: ObservableObject {
    @Published var isUnlocked = false
    @AppStorage("biometricEnabled") var biometricEnabled = false
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock ProTip365 to view your data"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    }
                }
            }
        } else {
            // No biometrics available
            isUnlocked = true
        }
    }
    
    func enableBiometric() {
        biometricEnabled = true
    }
    
    func disableBiometric() {
        biometricEnabled = false
        isUnlocked = true
    }
}
