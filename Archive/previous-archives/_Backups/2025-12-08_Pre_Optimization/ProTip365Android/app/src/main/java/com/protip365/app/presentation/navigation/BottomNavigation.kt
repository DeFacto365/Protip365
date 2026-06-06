package com.protip365.app.presentation.navigation

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.currentBackStackEntryAsState

sealed class BottomNavItem(
    val route: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val label: String,
    val badge: Int? = null
) {
    object Dashboard : BottomNavItem(
        route = "dashboard",
        selectedIcon = Icons.Filled.Home,
        unselectedIcon = Icons.Outlined.Home,
        label = "Dashboard"
    )

    object Calendar : BottomNavItem(
        route = "calendar",
        selectedIcon = Icons.Filled.CalendarMonth,
        unselectedIcon = Icons.Outlined.CalendarMonth,
        label = "Calendar"
    )

    object Employers : BottomNavItem(
        route = "employers",
        selectedIcon = Icons.Filled.Business,
        unselectedIcon = Icons.Outlined.Business,
        label = "Employers"
    )

    object Calculator : BottomNavItem(
        route = "calculator",
        selectedIcon = Icons.Filled.Calculate,
        unselectedIcon = Icons.Outlined.Calculate,
        label = "Calculator"
    )

    object Settings : BottomNavItem(
        route = "settings",
        selectedIcon = Icons.Filled.Settings,
        unselectedIcon = Icons.Outlined.Settings,
        label = "Settings"
    )
}

@Composable
fun BottomNavigationBar(
    navController: NavController,
    useMultipleEmployers: Boolean = false,
    currentLanguage: String = "en",
    modifier: Modifier = Modifier
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    // Define navigation items based on settings
    val navigationItems = remember(useMultipleEmployers) {
        if (useMultipleEmployers) {
            listOf(
                BottomNavItem.Dashboard,
                BottomNavItem.Calendar,
                BottomNavItem.Employers,
                BottomNavItem.Calculator,
                BottomNavItem.Settings
            )
        } else {
            listOf(
                BottomNavItem.Dashboard,
                BottomNavItem.Calendar,
                BottomNavItem.Calculator,
                BottomNavItem.Settings
            )
        }
    }

    NavigationBar(
        modifier = modifier,
        containerColor = MaterialTheme.colorScheme.surface,
        contentColor = MaterialTheme.colorScheme.onSurface,
        tonalElevation = 0.dp
    ) {
        navigationItems.forEach { item ->
            val selected = currentDestination?.hierarchy?.any { it.route == item.route } == true

            NavigationBarItem(
                selected = selected,
                onClick = {
                    navController.navigate(item.route) {
                        // Pop up to the start destination of the graph to
                        // avoid building up a large stack of destinations
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        // Avoid multiple copies of the same destination
                        launchSingleTop = true
                        // Restore state when reselecting a previously selected item
                        restoreState = true
                    }
                },
                icon = {
                    NavigationIcon(
                        selected = selected,
                        selectedIcon = item.selectedIcon,
                        unselectedIcon = item.unselectedIcon,
                        badge = item.badge
                    )
                },
                label = {
                    Text(
                        text = getLocalizedNavLabel(item.label, currentLanguage),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal
                    )
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = MaterialTheme.colorScheme.primary,
                    selectedTextColor = MaterialTheme.colorScheme.primary,
                    indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                    unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
                )
            )
        }
    }
}

@Composable
private fun NavigationIcon(
    selected: Boolean,
    selectedIcon: ImageVector,
    unselectedIcon: ImageVector,
    badge: Int? = null
) {
    Box {
        // Animated icon transition
        Crossfade(
            targetState = selected,
            animationSpec = tween(200)
        ) { isSelected ->
            Icon(
                imageVector = if (isSelected) selectedIcon else unselectedIcon,
                contentDescription = null,
                modifier = Modifier.size(24.dp)
            )
        }

        // Badge indicator
        badge?.let { count ->
            if (count > 0) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .offset(x = 4.dp, y = (-4).dp)
                        .size(if (count > 9) 20.dp else 16.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.error),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (count > 99) "99+" else count.toString(),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onError,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
fun AnimatedBottomNavigation(
    navController: NavController,
    useMultipleEmployers: Boolean = false,
    currentLanguage: String = "en",
    modifier: Modifier = Modifier
) {
    var isVisible by remember { mutableStateOf(true) }

    AnimatedVisibility(
        visible = isVisible,
        enter = slideInVertically(
            initialOffsetY = { it },
            animationSpec = tween(300)
        ) + fadeIn(animationSpec = tween(300)),
        exit = slideOutVertically(
            targetOffsetY = { it },
            animationSpec = tween(300)
        ) + fadeOut(animationSpec = tween(300)),
        modifier = modifier
    ) {
        BottomNavigationBar(
            navController = navController,
            useMultipleEmployers = useMultipleEmployers,
            currentLanguage = currentLanguage
        )
    }
}

// Material 3 style with custom indicators
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EnhancedBottomNavigation(
    navController: NavController,
    useMultipleEmployers: Boolean = false,
    currentLanguage: String = "en",
    modifier: Modifier = Modifier
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val navigationItems = remember(useMultipleEmployers) {
        if (useMultipleEmployers) {
            listOf(
                BottomNavItem.Dashboard,
                BottomNavItem.Calendar,
                BottomNavItem.Employers,
                BottomNavItem.Calculator,
                BottomNavItem.Settings
            )
        } else {
            listOf(
                BottomNavItem.Dashboard,
                BottomNavItem.Calendar,
                BottomNavItem.Calculator,
                BottomNavItem.Settings
            )
        }
    }

    Surface(
        modifier = modifier,
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 3.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            navigationItems.forEach { item ->
                val selected = currentDestination?.hierarchy?.any { it.route == item.route } == true

                EnhancedNavigationItem(
                    selected = selected,
                    onClick = {
                        navController.navigate(item.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    icon = item.selectedIcon,
                    unselectedIcon = item.unselectedIcon,
                    label = getLocalizedNavLabel(item.label, currentLanguage),
                    badge = item.badge
                )
            }
        }
    }
}

@Composable
private fun EnhancedNavigationItem(
    selected: Boolean,
    onClick: () -> Unit,
    icon: ImageVector,
    unselectedIcon: ImageVector,
    label: String,
    badge: Int? = null
) {
    val animatedScale by animateFloatAsState(
        targetValue = if (selected) 1.1f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        )
    )

    Column(
        modifier = Modifier
            .clip(MaterialTheme.shapes.medium)
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box {
            Icon(
                imageVector = if (selected) icon else unselectedIcon,
                contentDescription = label,
                modifier = Modifier
                    .size(24.dp)
                    .graphicsLayer(
                        scaleX = animatedScale,
                        scaleY = animatedScale
                    ),
                tint = if (selected)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurfaceVariant
            )

            // Badge
            badge?.let { count ->
                if (count > 0) {
                    Badge(
                        modifier = Modifier.align(Alignment.TopEnd),
                        containerColor = MaterialTheme.colorScheme.error,
                        contentColor = MaterialTheme.colorScheme.onError
                    ) {
                        Text(
                            text = if (count > 99) "99+" else count.toString(),
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                }
            }
        }

        AnimatedVisibility(
            visible = selected,
            enter = fadeIn() + expandVertically(),
            exit = fadeOut() + shrinkVertically()
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold
            )
        }

        // Selection indicator dot
        AnimatedVisibility(
            visible = selected,
            enter = scaleIn() + fadeIn(),
            exit = scaleOut() + fadeOut()
        ) {
            Box(
                modifier = Modifier
                    .size(4.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary)
            )
        }
    }
}

private fun getLocalizedNavLabel(label: String, language: String): String {
    return when (language) {
        "fr" -> when (label) {
            "Dashboard" -> "Tableau"
            "Calendar" -> "Calendrier"
            "Employers" -> "Employeurs"
            "Calculator" -> "Calculateur"
            "Settings" -> "Paramètres"
            else -> label
        }
        "es" -> when (label) {
            "Dashboard" -> "Panel"
            "Calendar" -> "Calendario"
            "Employers" -> "Empleadores"
            "Calculator" -> "Calculadora"
            "Settings" -> "Ajustes"
            else -> label
        }
        else -> label
    }
}