/*
ProTip365 Constants
Inspired by Apple's Landmarks sample app Liquid Glass implementation
*/

import SwiftUI

/// Constant values that the app defines for consistent Liquid Glass implementation.
struct Constants {
    // MARK: - App-wide constants
    
    static let cornerRadius: CGFloat = 15.0  // Apple's exact value
    static let buttonCornerRadius: CGFloat = 12.0
    static let formCornerRadius: CGFloat = 8.0  // Apple's exact value
    static let leadingContentInset: CGFloat = 26.0  // Apple's exact value
    static let standardPadding: CGFloat = 14.0  // Apple's exact value
    static let safeAreaPadding: CGFloat = 30.0  // Apple's exact value
    
    // MARK: - Dashboard constants
    
    static let dashboardCardSpacing: CGFloat = 16.0
    static let dashboardSectionSpacing: CGFloat = 24.0
    static let quickActionButtonSpacing: CGFloat = 12.0
    static let quickActionButtonHeight: CGFloat = 50.0
    
    // MARK: - Stats card constants
    
    static let statsCardMinHeight: CGFloat = 120.0
    static let statsCardMaxHeight: CGFloat = 140.0
    static let statsCardPadding: CGFloat = 16.0
    static let statsCardIconSize: CGFloat = 24.0
    
    // MARK: - Form constants
    
    static let formFieldHeight: CGFloat = 44.0
    static let formFieldSpacing: CGFloat = 12.0
    static let formSectionSpacing: CGFloat = 20.0
    static let formPadding: CGFloat = 16.0
    
    // MARK: - Calculator constants
    
    static let calculatorButtonSize: CGFloat = 60.0
    static let calculatorButtonSpacing: CGFloat = 12.0
    static let calculatorDisplayHeight: CGFloat = 80.0
    static let calculatorSectionSpacing: CGFloat = 20.0
    
    // MARK: - Calendar constants
    
    static let calendarDaySize: CGFloat = 40.0
    static let calendarDaySpacing: CGFloat = 8.0
    static let calendarHeaderHeight: CGFloat = 50.0
    static let calendarActionButtonHeight: CGFloat = 50.0
    
    // MARK: - Tab bar constants
    
    static let tabBarHeight: CGFloat = 80.0
    static let tabBarPadding: CGFloat = 20.0
    static let tabBarItemSpacing: CGFloat = 8.0
    static let tabBarCornerRadius: CGFloat = 20.0
    
    // MARK: - Glass effect constants
    
    static let glassEffectSpacing: CGFloat = 16.0
    static let glassEffectShadowRadius: CGFloat = 10.0
    static let glassEffectShadowOpacity: Double = 0.1
    static let glassEffectBorderWidth: CGFloat = 0.5
    
    // MARK: - Animation constants
    
    static let standardAnimationDuration: Double = 0.3
    static let springResponse: Double = 0.4
    static let springDampingFraction: Double = 0.8
    
    // MARK: - Responsive layout constants
    
    @MainActor static var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    @MainActor static var screenWidth: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.width
        #else
        return 375.0
        #endif
    }
    
    @MainActor static var screenHeight: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.height
        #else
        return 667.0
        #endif
    }
    
    // MARK: - Dynamic sizing
    
    @MainActor static var dynamicCardWidth: CGFloat {
        if isIPad {
            return min(screenWidth * 0.4, 300.0)
        } else {
            return screenWidth - (leadingContentInset * 2)
        }
    }
    
    @MainActor static var dynamicButtonWidth: CGFloat {
        if isIPad {
            return 200.0
        } else {
            return screenWidth - (leadingContentInset * 2)
        }
    }
}
