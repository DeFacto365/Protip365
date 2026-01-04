package com.protip365.app.presentation.components

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.platform.LocalAccessibilityManager
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.TextStyle

/**
 * Animation utilities for Android 16 with Material 3 motion guidelines
 * Includes support for reduced motion accessibility settings
 */

/**
 * Check if animations should be reduced based on accessibility settings
 */
@Composable
fun rememberIsReducedMotionEnabled(): Boolean {
    val accessibilityManager = LocalAccessibilityManager.current
    // Check if reduced motion is enabled (Android 11+)
    return accessibilityManager?.isEnabled == true &&
            (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R)
}

/**
 * Get animation duration based on reduced motion preference
 * Material 3 recommends: 300ms for standard, 0ms for reduced motion
 */
@Composable
fun rememberAnimationDuration(
    standardDuration: Int = 300,
    reducedDuration: Int = 0
): Int {
    val isReducedMotion = rememberIsReducedMotionEnabled()
    return if (isReducedMotion) reducedDuration else standardDuration
}

/**
 * Material 3 motion easing functions
 * Standard easing: EaseInOut for most transitions
 */
object MotionEasing {
    val Standard = EaseInOut
    val Emphasized = EaseInOut
    val Decelerated = EaseOut
    val Accelerated = EaseIn
}

/**
 * Fade transition with Material 3 motion guidelines
 * Uses standard 300ms duration with reduced motion support
 */
@Composable
fun FadeTransition(
    isVisible: Boolean,
    modifier: Modifier = Modifier,
    duration: Int = 300,
    content: @Composable AnimatedVisibilityScope.() -> Unit
) {
    val animationDuration = rememberAnimationDuration(duration, 0)
    
    AnimatedVisibility(
        visible = isVisible,
        enter = fadeIn(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        exit = fadeOut(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        modifier = modifier,
        content = content
    )
}

/**
 * Slide transition with Material 3 motion guidelines
 * Horizontal slide for page transitions
 */
@Composable
fun SlideTransition(
    isVisible: Boolean,
    modifier: Modifier = Modifier,
    duration: Int = 300,
    content: @Composable AnimatedVisibilityScope.() -> Unit
) {
    val animationDuration = rememberAnimationDuration(duration, 0)
    
    AnimatedVisibility(
        visible = isVisible,
        enter = slideInHorizontally(
            initialOffsetX = { it },
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Decelerated
            )
        ) + fadeIn(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        exit = slideOutHorizontally(
            targetOffsetX = { -it },
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Accelerated
            )
        ) + fadeOut(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        modifier = modifier,
        content = content
    )
}

/**
 * Scale transition with Material 3 motion guidelines
 * Used for dialogs and cards
 */
@Composable
fun ScaleTransition(
    isVisible: Boolean,
    modifier: Modifier = Modifier,
    duration: Int = 300,
    content: @Composable AnimatedVisibilityScope.() -> Unit
) {
    val animationDuration = rememberAnimationDuration(duration, 0)
    
    AnimatedVisibility(
        visible = isVisible,
        enter = scaleIn(
            initialScale = 0.8f,
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Decelerated
            )
        ) + fadeIn(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        exit = scaleOut(
            targetScale = 0.8f,
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Accelerated
            )
        ) + fadeOut(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        modifier = modifier,
        content = content
    )
}

/**
 * Animated card with Material 3 motion guidelines
 * Staggered animation for lists with reduced motion support
 */
@Composable
fun AnimatedCard(
    isVisible: Boolean,
    delay: Int = 0,
    modifier: Modifier = Modifier,
    content: @Composable AnimatedVisibilityScope.() -> Unit
) {
    val animationDuration = rememberAnimationDuration(400, 0)
    val isReducedMotion = rememberIsReducedMotionEnabled()
    val actualDelay = if (isReducedMotion) 0 else delay
    
    AnimatedVisibility(
        visible = isVisible,
        enter = slideInVertically(
            initialOffsetY = { it },
            animationSpec = tween(
                durationMillis = animationDuration,
                delayMillis = actualDelay,
                easing = MotionEasing.Decelerated
            )
        ) + fadeIn(
            animationSpec = tween(
                durationMillis = animationDuration,
                delayMillis = actualDelay,
                easing = MotionEasing.Standard
            )
        ),
        exit = slideOutVertically(
            targetOffsetY = { -it },
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Accelerated
            )
        ) + fadeOut(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        modifier = modifier,
        content = content
    )
}

/**
 * Number counter animation with reduced motion support
 * Material 3 compliant counter animation
 */
@Composable
fun AnimatedCounter(
    targetValue: Int,
    modifier: Modifier = Modifier,
    style: TextStyle = MaterialTheme.typography.bodyLarge
) {
    var currentValue by remember { mutableIntStateOf(0) }
    val animationDuration = rememberAnimationDuration(1000, 0)
    
    LaunchedEffect(targetValue) {
        if (animationDuration > 0) {
            val animator = Animatable(currentValue.toFloat())
            animator.animateTo(
                targetValue.toFloat(),
                animationSpec = tween(
                    durationMillis = animationDuration,
                    easing = MotionEasing.Decelerated
                )
            )
            currentValue = animator.value.toInt()
        } else {
            currentValue = targetValue
        }
    }
    
    Text(
        text = currentValue.toString(),
        style = style,
        modifier = modifier
    )
}

/**
 * Currency counter animation with reduced motion support
 * Material 3 compliant currency animation
 */
@Composable
fun AnimatedCurrency(
    targetValue: Double,
    modifier: Modifier = Modifier,
    style: TextStyle = MaterialTheme.typography.bodyLarge
) {
    var currentValue by remember { mutableStateOf(0.0) }
    val animationDuration = rememberAnimationDuration(1000, 0)
    
    LaunchedEffect(targetValue) {
        if (animationDuration > 0) {
            val animator = Animatable(currentValue)
            animator.animateTo(
                targetValue,
                animationSpec = tween(
                    durationMillis = animationDuration,
                    easing = MotionEasing.Decelerated
                )
            )
            currentValue = animator.value
        } else {
            currentValue = targetValue
        }
    }
    
    Text(
        text = "$${String.format("%.2f", currentValue)}",
        style = style,
        modifier = modifier
    )
}

/**
 * Progress bar animation with reduced motion support
 * Material 3 compliant progress animation
 */
@Composable
fun AnimatedProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    color: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.primary
) {
    var animatedProgress by remember { mutableStateOf(0f) }
    val animationDuration = rememberAnimationDuration(800, 0)
    
    LaunchedEffect(progress) {
        if (animationDuration > 0) {
            val animator = Animatable(animatedProgress)
            animator.animateTo(
                progress,
                animationSpec = tween(
                    durationMillis = animationDuration,
                    easing = MotionEasing.Decelerated
                )
            )
            animatedProgress = animator.value
        } else {
            animatedProgress = progress
        }
    }
    
    LinearProgressIndicator(
        progress = animatedProgress,
        modifier = modifier,
        color = color
    )
}

/**
 * Refresh indicator animation with reduced motion support
 * Material 3 compliant refresh animation
 */
@Composable
fun AnimatedRefreshIndicator(
    isRefreshing: Boolean,
    modifier: Modifier = Modifier
) {
    val animationDuration = rememberAnimationDuration(300, 0)
    
    AnimatedVisibility(
        visible = isRefreshing,
        enter = slideInVertically(
            initialOffsetY = { -it },
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ) + fadeIn(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        exit = slideOutVertically(
            targetOffsetY = { -it },
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ) + fadeOut(
            animationSpec = tween(
                durationMillis = animationDuration,
                easing = MotionEasing.Standard
            )
        ),
        modifier = modifier
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text("Refreshing...")
            }
        }
    }
}


