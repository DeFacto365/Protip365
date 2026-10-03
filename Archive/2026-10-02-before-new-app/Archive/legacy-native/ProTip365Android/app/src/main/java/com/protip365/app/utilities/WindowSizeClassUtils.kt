package com.protip365.app.utilities

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp

/**
 * WindowSizeClass data class for adaptive layouts
 * Based on Material 3 WindowSizeClass breakpoints
 * 
 * Breakpoints:
 * - Compact: < 600dp width (phones in portrait)
 * - Medium: 600dp - 840dp width (tablets in portrait, phones in landscape)
 * - Expanded: > 840dp width (tablets in landscape, foldables unfolded)
 */
data class WindowSizeClass(
    val widthSizeClass: WindowWidthSizeClass,
    val heightSizeClass: WindowHeightSizeClass
)

enum class WindowWidthSizeClass {
    COMPACT,    // < 600dp
    MEDIUM,     // 600dp - 840dp
    EXPANDED    // > 840dp
}

enum class WindowHeightSizeClass {
    COMPACT,    // < 480dp
    MEDIUM,     // 480dp - 900dp
    EXPANDED    // > 900dp
}

/**
 * WindowSizeClass utility for adaptive layouts
 * Provides Material 3 WindowSizeClass detection for adaptive UI
 * 
 * This composable function calculates the window size class based on
 * the current screen configuration, enabling adaptive layouts for
 * phones, tablets, and foldables.
 * 
 * Usage:
 * ```kotlin
 * val windowSizeClass = rememberWindowSizeClass()
 * when (windowSizeClass.widthSizeClass) {
 *     WindowWidthSizeClass.COMPACT -> { /* Phone layout */ }
 *     WindowWidthSizeClass.MEDIUM -> { /* Tablet portrait layout */ }
 *     WindowWidthSizeClass.EXPANDED -> { /* Tablet landscape layout */ }
 * }
 * ```
 */
@Composable
fun rememberWindowSizeClass(): WindowSizeClass {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    val screenHeight = configuration.screenHeightDp.dp
    
    val widthSizeClass = when {
        screenWidth < 600.dp -> WindowWidthSizeClass.COMPACT
        screenWidth < 840.dp -> WindowWidthSizeClass.MEDIUM
        else -> WindowWidthSizeClass.EXPANDED
    }
    
    val heightSizeClass = when {
        screenHeight < 480.dp -> WindowHeightSizeClass.COMPACT
        screenHeight < 900.dp -> WindowHeightSizeClass.MEDIUM
        else -> WindowHeightSizeClass.EXPANDED
    }
    
    return WindowSizeClass(widthSizeClass, heightSizeClass)
}

/**
 * Calculate WindowSizeClass from DpSize
 * Used for programmatic size class calculation
 */
fun calculateWindowSizeClass(size: DpSize): WindowSizeClass {
    val widthSizeClass = when {
        size.width < 600.dp -> WindowWidthSizeClass.COMPACT
        size.width < 840.dp -> WindowWidthSizeClass.MEDIUM
        else -> WindowWidthSizeClass.EXPANDED
    }
    
    val heightSizeClass = when {
        size.height < 480.dp -> WindowHeightSizeClass.COMPACT
        size.height < 900.dp -> WindowHeightSizeClass.MEDIUM
        else -> WindowHeightSizeClass.EXPANDED
    }
    
    return WindowSizeClass(widthSizeClass, heightSizeClass)
}

/**
 * Extension function to check if current size class is tablet-sized
 * Returns true if width is Medium or Expanded
 */
@Composable
fun isTabletSize(): Boolean {
    val windowSizeClass = rememberWindowSizeClass()
    return windowSizeClass.widthSizeClass == WindowWidthSizeClass.EXPANDED ||
           windowSizeClass.widthSizeClass == WindowWidthSizeClass.MEDIUM
}

/**
 * Extension function to check if current size class is phone-sized
 * Returns true if width is Compact
 */
@Composable
fun isPhoneSize(): Boolean {
    val windowSizeClass = rememberWindowSizeClass()
    return windowSizeClass.widthSizeClass == WindowWidthSizeClass.COMPACT
}

/**
 * Detect if device is in landscape orientation
 * Returns true when width > height
 */
@Composable
fun isLandscape(): Boolean {
    val configuration = LocalConfiguration.current
    return configuration.screenWidthDp > configuration.screenHeightDp
}

/**
 * Detect if device is in portrait orientation
 * Returns true when height >= width
 */
@Composable
fun isPortrait(): Boolean {
    val configuration = LocalConfiguration.current
    return configuration.screenHeightDp >= configuration.screenWidthDp
}

