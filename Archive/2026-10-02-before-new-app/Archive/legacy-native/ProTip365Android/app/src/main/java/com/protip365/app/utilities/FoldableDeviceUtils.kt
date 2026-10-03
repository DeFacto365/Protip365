package com.protip365.app.utilities

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.window.layout.FoldingFeature
import androidx.window.layout.WindowInfoTracker
import androidx.window.layout.WindowLayoutInfo
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * Data class representing foldable device state
 * Used for adaptive layouts on foldable devices
 */
data class FoldableDeviceState(
    val isFolded: Boolean,
    val foldOrientation: FoldOrientation?,
    val foldState: FoldState,
    val hingeWidth: Dp,
    val isDualPaneSupported: Boolean
)

/**
 * Fold orientation - horizontal (landscape) or vertical (portrait)
 */
enum class FoldOrientation {
    HORIZONTAL, // Fold splits screen horizontally (landscape)
    VERTICAL    // Fold splits screen vertically (portrait)
}

/**
 * Fold state - flat (unfolded) or half-opened
 */
enum class FoldState {
    FLAT,           // Device is fully unfolded
    HALF_OPENED     // Device is half-opened (tabletop mode)
}

/**
 * Composable function to detect foldable device state
 * 
 * This function uses WindowInfoTracker to detect:
 * - Whether device is folded or unfolded
 * - Fold orientation (horizontal/vertical)
 * - Fold state (flat/half-opened)
 * - Hinge width
 * - Whether dual-pane layout is supported
 * 
 * Requires androidx.window:window dependency
 * 
 * Usage:
 * ```kotlin
 * val foldableState = rememberFoldableDeviceState()
 * if (foldableState.isDualPaneSupported && !foldableState.isFolded) {
 *     // Show dual-pane layout
 * } else {
 *     // Show single-pane layout
 * }
 * ```
 */
@Composable
fun rememberFoldableDeviceState(): FoldableDeviceState {
    val context = LocalContext.current
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()
    
    var windowLayoutInfo by remember { mutableStateOf<WindowLayoutInfo?>(null) }
    
    // Use WindowInfoTracker to track window layout changes
    DisposableEffect(Unit) {
        val windowInfoTracker = WindowInfoTracker.getOrCreate(context)
        val job = scope.launch {
            windowInfoTracker.windowLayoutInfo(context).collect { layoutInfo ->
                windowLayoutInfo = layoutInfo
            }
        }
        onDispose {
            job.cancel()
        }
    }
    
    val foldingFeature = windowLayoutInfo?.displayFeatures
        ?.filterIsInstance<FoldingFeature>()
        ?.firstOrNull()
    
    val foldOrientation = when {
        foldingFeature?.orientation == FoldingFeature.Orientation.HORIZONTAL -> FoldOrientation.HORIZONTAL
        foldingFeature?.orientation == FoldingFeature.Orientation.VERTICAL -> FoldOrientation.VERTICAL
        else -> null
    }
    
    val foldState = when (foldingFeature?.state) {
        FoldingFeature.State.FLAT -> FoldState.FLAT
        FoldingFeature.State.HALF_OPENED -> FoldState.HALF_OPENED
        else -> FoldState.FLAT
    }
    
    val hingeWidth = with(density) {
        foldingFeature?.bounds?.width()?.toDp() ?: 0.dp
    }
    
    // Dual-pane is supported when:
    // 1. Device has a folding feature
    // 2. Device is unfolded (flat)
    // 3. Fold is separating (two screens)
    val isDualPaneSupported = foldingFeature != null &&
                               foldingFeature.isSeparating &&
                               foldingFeature.state == FoldingFeature.State.FLAT
    
    // Device is folded when:
    // - No folding feature exists (regular device)
    // - OR folding feature exists but is not flat (half-opened) or not separating
    val isFolded = foldingFeature == null || 
                   (foldingFeature.state != FoldingFeature.State.FLAT || !foldingFeature.isSeparating)
    
    return FoldableDeviceState(
        isFolded = isFolded,
        foldOrientation = foldOrientation,
        foldState = foldState,
        hingeWidth = hingeWidth,
        isDualPaneSupported = isDualPaneSupported
    )
}

/**
 * Check if device is a foldable device
 * Returns true if device has any folding feature
 */
@Composable
fun isFoldableDevice(): Boolean {
    val foldableState = rememberFoldableDeviceState()
    return foldableState.foldOrientation != null
}

/**
 * Check if device is currently unfolded and supports dual-pane layout
 */
@Composable
fun isUnfoldedForDualPane(): Boolean {
    val foldableState = rememberFoldableDeviceState()
    return foldableState.isDualPaneSupported && !foldableState.isFolded
}

