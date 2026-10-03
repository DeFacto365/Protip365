package com.protip365.app.presentation.achievements

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector

fun getAchievementIcon(achievementId: String): ImageVector {
    return when (achievementId) {
        "first_shift" -> Icons.Default.Star
        "week_warrior" -> Icons.Default.CalendarToday
        "consistency_king", "steady_tracker", "dedicated_logger", "tracking_legend" -> Icons.Default.EmojiEvents
        "high_roller" -> Icons.Default.AttachMoney
        "perfect_week" -> Icons.Default.EmojiEvents
        "monthly_master" -> Icons.Default.DateRange
        "tip_titan" -> Icons.Default.MonetizationOn
        "efficiency_expert" -> Icons.Default.Speed
        "overtime_champion" -> Icons.Default.AccessTime
        "steady_earner" -> Icons.AutoMirrored.Filled.ShowChart
        "tip_master", "elite_server", "tip_champion" -> Icons.Default.Star
        "tip_target_crusher", "target_crusher" -> Icons.Default.GpsFixed
        "high_earner", "top_performer" -> Icons.Default.AttachMoney
        "sales_star" -> Icons.AutoMirrored.Filled.TrendingUp
        "goal_getter" -> Icons.Default.CheckCircle
        "perfect_month" -> Icons.Default.Verified
        else -> Icons.Default.Star
    }
}

fun getAchievementColor(achievementId: String): Color {
    return when (achievementId) {
        "first_shift" -> Color(0xFFFFD700)
        "week_warrior" -> Color(0xFF4CAF50)
        "consistency_king", "steady_tracker", "dedicated_logger", "tracking_legend" -> Color(0xFF8E24AA)
        "high_roller" -> Color(0xFF9C27B0)
        "perfect_week" -> Color(0xFFFF9800)
        "monthly_master" -> Color(0xFFE91E63)
        "tip_titan" -> Color(0xFF00BCD4)
        "efficiency_expert" -> Color(0xFF8BC34A)
        "overtime_champion" -> Color(0xFFFF5722)
        "steady_earner" -> Color(0xFF3F51B5)
        "tip_master", "elite_server", "tip_champion" -> Color(0xFFFDD835)
        "tip_target_crusher", "target_crusher" -> Color(0xFFFF6F00)
        "high_earner", "top_performer" -> Color(0xFF43A047)
        "sales_star" -> Color(0xFF1E88E5)
        "goal_getter" -> Color(0xFF00ACC1)
        "perfect_month" -> Color(0xFFD81B60)
        else -> Color(0xFFFFD700)
    }
}

