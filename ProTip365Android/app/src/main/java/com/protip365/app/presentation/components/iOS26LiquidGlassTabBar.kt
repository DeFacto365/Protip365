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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.protip365.app.presentation.design.IconMapping
import com.protip365.app.presentation.localization.rememberNavigationLocalization

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
                elevation = if (colorScheme.surface == Color.Black) 0.dp else 8.dp,
                shape = RoundedCornerShape(0.dp),
                ambientColor = Color.Black.copy(alpha = 0.1f),
                spotColor = Color.Black.copy(alpha = 0.1f)
            )
    ) {
        // Top separator line (light mode only)
        if (colorScheme.surface != Color.Black) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(0.5.dp)
                    .background(Color.Gray.copy(alpha = 0.2f))
                    .align(Alignment.TopCenter)
            )
        }

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
                        hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
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
                        .alpha(alpha),
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
                style = MaterialTheme.typography.labelSmall.copy(
                    fontSize = if (isLargeDevice) 11.sp else 9.sp,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium
                ),
                color = if (isSelected) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                },
                textAlign = TextAlign.Center,
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