package com.protip365.app.presentation.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalHapticFeedback
import com.protip365.app.utils.HapticFeedbackUtils
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.protip365.app.presentation.design.IconMapping
import com.protip365.app.presentation.localization.rememberNavigationLocalization
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.windowInsetsPadding

data class TabItem(
    val id: String,
    val icon: ImageVector,
    val label: String,
    val activeIcon: ImageVector,
    val badgeCount: Int? = null
)

@Composable
fun iOS26LiquidGlassTabBar(
    selectedTabId: String,
    onTabSelected: (String) -> Unit,
    tabItems: List<TabItem>,
    modifier: Modifier = Modifier
) {
    val configuration = LocalConfiguration.current
    val isLargeDevice = configuration.screenHeightDp >= 926 && configuration.screenWidthDp >= 932
    val hapticFeedback = LocalHapticFeedback.current
    val colorScheme = MaterialTheme.colorScheme

    // Glass morphism background
    Box(
        modifier = modifier
            .fillMaxWidth()
            .shadow(
                elevation = if (colorScheme.surface == Color.Black) 0.dp else 8.dp,  // Slightly increased
                shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp),  // Added radius
                ambientColor = Color.Black.copy(alpha = 0.12f),
                spotColor = Color.Black.copy(alpha = 0.12f)
            )
    ) {
        // Subtle gradient overlay for depth
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            Color.Transparent,
                            MaterialTheme.colorScheme.outline.copy(alpha = 0.1f),
                            Color.Transparent
                        )
                    )
                )
                .align(Alignment.TopCenter)
        )

        // Main tab content
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    if (colorScheme.surface == Color.Black) {
                        Color.Transparent
                    } else {
                        colorScheme.surface
                    }
                )
                .padding(
                    horizontal = if (isLargeDevice) 20.dp else 12.dp,
                    vertical = if (isLargeDevice) 16.dp else 12.dp
                )
                .padding(bottom = if (isLargeDevice) 0.dp else 4.dp)
                .selectableGroup(),
            horizontalArrangement = if (isLargeDevice) Arrangement.spacedBy(20.dp) else Arrangement.SpaceEvenly
        ) {
            tabItems.forEach { item ->
                TabBarItem(
                    item = item,
                    isSelected = selectedTabId == item.id,
                    isLargeDevice = isLargeDevice,
                    onClick = {
                        // Light haptic for navigation (Android 16 Enhanced Haptic Feedback)
                        HapticFeedbackUtils.performNavigationHaptic(hapticFeedback)
                        onTabSelected(item.id)
                    },
                    modifier = if (isLargeDevice) Modifier else Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun TabBarItem(
    item: TabItem,
    isSelected: Boolean,
    isLargeDevice: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val scale by animateFloatAsState(
        targetValue = if (isSelected) 1.15f else 1.0f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 400f),
        label = "scale"
    )

    val alpha by animateFloatAsState(
        targetValue = if (isSelected) 1.0f else 0.6f,
        animationSpec = spring(dampingRatio = 0.8f),
        label = "alpha"
    )

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            .padding(
                vertical = if (isLargeDevice) 8.dp else 4.dp,
                horizontal = if (isLargeDevice) 12.dp else 8.dp
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Icon with badge
            Box {
                Icon(
                    imageVector = if (isSelected) item.activeIcon else item.icon,
                    contentDescription = item.label,
                    modifier = Modifier
                        .size(if (isLargeDevice) 24.dp else 20.dp)
                        .alpha(alpha)
                        .graphicsLayer(
                            scaleX = scale,  // iOS-conformant: 1.15x scale when selected
                            scaleY = scale
                        ),
                    tint = if (isSelected) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )

                // Badge
                item.badgeCount?.let { count ->
                    if (count > 0) {
                        Badge(
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .offset(x = 4.dp, y = (-4).dp)
                        ) {
                            Text(
                                text = if (count > 99) "99+" else count.toString(),
                                fontSize = 10.sp
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(2.dp))

            // Label
            Text(
                text = item.label,
                style = MaterialTheme.typography.labelMedium.copy(
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium
                ),
                color = if (isSelected) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                },
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.alpha(alpha)
            )
        }
    }
}

// Predefined tab items matching iOS
@Composable
fun getTabItems(useMultipleEmployers: Boolean): List<TabItem> {
    val localization = rememberNavigationLocalization()

    return buildList {
        add(
            TabItem(
                id = "dashboard",
                icon = IconMapping.Navigation.dashboard,
                label = localization.dashboardTab,
                activeIcon = IconMapping.Navigation.dashboardFill
            )
        )
        add(
            TabItem(
                id = "calendar",
                icon = IconMapping.Navigation.calendar,
                label = localization.calendarTab,
                activeIcon = IconMapping.Navigation.calendarFill
            )
        )

        // Only add employers if enabled
        if (useMultipleEmployers) {
            add(
                TabItem(
                    id = "employers",
                    icon = IconMapping.Navigation.employers,
                    label = localization.employersTab,
                    activeIcon = IconMapping.Navigation.employersFill
                )
            )
        }

        add(
            TabItem(
                id = "calculator",
                icon = IconMapping.Navigation.calculator,
                label = localization.calculatorTab,
                activeIcon = IconMapping.Navigation.calculatorFill
            )
        )
        add(
            TabItem(
                id = "settings",
                icon = IconMapping.Navigation.settings,
                label = localization.settingsTab,
                activeIcon = IconMapping.Navigation.settingsFill
            )
        )
    }
}

/**
 * Adaptive Navigation Rail for tablets (Android 16)
 * Uses Material 3 NavigationRail component with iOS-style theming
 */
@Composable
fun AdaptiveNavigationRail(
    selectedTabId: String,
    onTabSelected: (String) -> Unit,
    tabItems: List<TabItem>,
    modifier: Modifier = Modifier
) {
    val hapticFeedback = LocalHapticFeedback.current
    val colorScheme = MaterialTheme.colorScheme

    NavigationRail(
        modifier = modifier
            .fillMaxHeight()
            .windowInsetsPadding(
                WindowInsets.systemBars.only(WindowInsetsSides.Vertical)
            ),
        containerColor = colorScheme.surface,
        contentColor = colorScheme.onSurface
    ) {
        // Add top padding for better spacing
        Spacer(modifier = Modifier.height(16.dp))
        
        tabItems.forEach { item ->
            val isSelected = selectedTabId == item.id
            
            NavigationRailItem(
                selected = isSelected,
                onClick = {
                    // Light haptic for navigation (Android 16 Enhanced Haptic Feedback)
                    HapticFeedbackUtils.performNavigationHaptic(hapticFeedback)
                    onTabSelected(item.id)
                },
                icon = {
                    Box {
                        Icon(
                            imageVector = if (isSelected) item.activeIcon else item.icon,
                            contentDescription = item.label,
                            modifier = Modifier.size(24.dp),
                            tint = if (isSelected) {
                                colorScheme.primary
                            } else {
                                colorScheme.onSurfaceVariant
                            }
                        )
                        
                        // Badge
                        item.badgeCount?.let { count ->
                            if (count > 0) {
                                Badge(
                                    modifier = Modifier
                                        .align(Alignment.TopEnd)
                                        .offset(x = 4.dp, y = (-4).dp)
                                ) {
                                    Text(
                                        text = if (count > 99) "99+" else count.toString(),
                                        fontSize = 10.sp
                                    )
                                }
                            }
                        }
                    }
                },
                label = {
                    Text(
                        text = item.label,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                        color = if (isSelected) {
                            colorScheme.primary
                        } else {
                            colorScheme.onSurfaceVariant
                        },
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                colors = NavigationRailItemDefaults.colors(
                    selectedIconColor = colorScheme.primary,
                    selectedTextColor = colorScheme.primary,
                    indicatorColor = colorScheme.primaryContainer,
                    unselectedIconColor = colorScheme.onSurfaceVariant,
                    unselectedTextColor = colorScheme.onSurfaceVariant
                )
            )
        }
    }
}