import UIKit
import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedbackLight = UIImpactFeedbackGenerator(style: .light)
    private let impactFeedbackMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactFeedbackHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // Prepare generators to reduce latency
    init() {
        selectionFeedback.prepare()
        impactFeedbackLight.prepare()
        impactFeedbackMedium.prepare()
        impactFeedbackHeavy.prepare()
        notificationFeedback.prepare()
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactFeedbackLight.impactOccurred()
        case .medium:
            impactFeedbackMedium.impactOccurred()
        case .heavy:
            impactFeedbackHeavy.impactOccurred()
        default:
            impactFeedbackMedium.impactOccurred()
        }
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedback.notificationOccurred(type)
    }
}
