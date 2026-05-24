package com.protip365.app.utils

import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType

/**
 * Context-aware haptic feedback utility for Android 16 Enhanced Haptic Feedback
 * 
 * Provides different haptic patterns for different contexts:
 * - Light tap for navigation
 * - Medium tap for selections
 * - Strong tap for confirmations
 * - Error feedback for errors
 */
object HapticFeedbackUtils {
    
    /**
     * Light haptic feedback for navigation actions
     * Use for: Tab changes, navigation buttons, breadcrumbs
     */
    fun performNavigationHaptic(hapticFeedback: HapticFeedback) {
        hapticFeedback.performHapticFeedback(HapticFeedbackType.TextHandleMove)
    }
    
    /**
     * Medium haptic feedback for selections
     * Use for: Picker selections, dropdowns, toggle switches, checkbox selections
     */
    fun performSelectionHaptic(hapticFeedback: HapticFeedback) {
        hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
    }
    
    /**
     * Strong haptic feedback for confirmations
     * Use for: Primary button presses, save actions, delete confirmations, important actions
     */
    fun performConfirmationHaptic(hapticFeedback: HapticFeedback) {
        hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
    }
    
    /**
     * Haptic feedback for successful actions
     * Use for: Successful saves, updates, achievements unlocked
     */
    fun performSuccessHaptic(hapticFeedback: HapticFeedback) {
        hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
    }
    
    /**
     * Haptic feedback for error states
     * Use for: Validation errors, failed operations, warnings
     */
    fun performErrorHaptic(hapticFeedback: HapticFeedback) {
        hapticFeedback.performHapticFeedback(HapticFeedbackType.TextHandleMove)
    }
    
    /**
     * Light haptic feedback for form interactions
     * Use for: Date/time picker opens, field focus changes, minor interactions
     */
    fun performFormInteractionHaptic(hapticFeedback: HapticFeedback) {
        hapticFeedback.performHapticFeedback(HapticFeedbackType.TextHandleMove)
    }
}


