package com.protip365.app.utilities

import android.content.Context
import android.os.Build
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

object DeviceUtils {

    /**
     * Check if device supports Adaptive Refresh Rate (ARR)
     * ARR is available on Android 12+ (API 31+)
     */
    fun isAdaptiveRefreshRateSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S // Android 12+
    }

    /**
     * Get optimal animation duration based on ARR support
     * ARR-capable devices can handle shorter animations for better battery life
     */
    fun getOptimalAnimationDuration(baseDuration: Duration = 400.milliseconds): Duration {
        return if (isAdaptiveRefreshRateSupported()) {
            (baseDuration.inWholeMilliseconds * 0.75).toLong().milliseconds // 25% faster
        } else {
            baseDuration
        }
    }

    /**
     * Check if device supports biometric authentication
     */
    fun supportsBiometricAuthentication(context: Context): Boolean {
        // Implementation for biometric check
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
    }
}
