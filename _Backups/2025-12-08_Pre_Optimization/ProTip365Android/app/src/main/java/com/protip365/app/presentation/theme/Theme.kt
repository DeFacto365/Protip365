package com.protip365.app.presentation.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFF6366F1), // Modern indigo
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFF4F46E5),
    onPrimaryContainer = Color(0xFFE0E7FF),
    secondary = Color(0xFF10B981), // Modern emerald
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFF059669),
    onSecondaryContainer = Color(0xFFD1FAE5),
    tertiary = Color(0xFFF59E0B), // Modern amber
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFD97706),
    onTertiaryContainer = Color(0xFFFEF3C7),
    error = Color(0xFFEF4444), // Modern red
    errorContainer = Color(0xFFDC2626),
    onError = Color(0xFFFFFFFF),
    onErrorContainer = Color(0xFFFEE2E2),
    background = Color(0xFF0F172A), // Modern dark slate
    onBackground = Color(0xFFF1F5F9),
    surface = Color(0xFF1E293B),
    onSurface = Color(0xFFF1F5F9),
    surfaceVariant = Color(0xFF334155),
    onSurfaceVariant = Color(0xFFCBD5E1),
    outline = Color(0xFF64748B),
    inverseOnSurface = Color(0xFF0F172A),
    inverseSurface = Color(0xFFF1F5F9),
    inversePrimary = Color(0xFF6366F1)
)

private val LightColorScheme = lightColorScheme(
    primary = Color(0xFF6366F1), // Modern indigo
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFE0E7FF),
    onPrimaryContainer = Color(0xFF3730A3),
    secondary = Color(0xFF10B981), // Modern emerald
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFD1FAE5),
    onSecondaryContainer = Color(0xFF065F46),
    tertiary = Color(0xFFF59E0B), // Modern amber
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFFEF3C7),
    onTertiaryContainer = Color(0xFF92400E),
    error = Color(0xFFEF4444), // Modern red
    errorContainer = Color(0xFFFEE2E2),
    onError = Color(0xFFFFFFFF),
    onErrorContainer = Color(0xFF991B1B),
    background = Color(0xFFFAFAFA), // Clean white
    onBackground = Color(0xFF0F172A),
    surface = Color(0xFFFFFFFF),
    onSurface = Color(0xFF0F172A),
    surfaceVariant = Color(0xFFF1F5F9),
    onSurfaceVariant = Color(0xFF475569),
    outline = Color(0xFF94A3B8),
    inverseOnSurface = Color(0xFFF1F5F9),
    inverseSurface = Color(0xFF0F172A),
    inversePrimary = Color(0xFF818CF8)
)

@Composable
fun ProTip365Theme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Color.Transparent.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}