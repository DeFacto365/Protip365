package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import java.util.UUID

@Serializable
data class Achievement(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("user_id")
    val userId: String,

    @SerialName("achievement_type")
    val achievementType: String,

    @SerialName("unlocked_at")
    val unlockedAt: String? = null,

    @SerialName("data")
    val data: JsonElement? = null,

    @SerialName("created_at")
    val createdAt: String? = null
)

// Static achievement definitions that match iOS
@Serializable
data class AchievementDefinition(
    @SerialName("id")
    val id: String,

    @SerialName("name")
    val name: String,

    @SerialName("description")
    val description: String,

    @SerialName("icon")
    val icon: String,

    @SerialName("category")
    val category: String,

    @SerialName("tier")
    val tier: String,

    @SerialName("requirement")
    val requirement: Int
)

// Achievement types matching iOS app
enum class AchievementType(val value: String, val displayName: String, val description: String) {
    // Tip Performance
    TIP_MASTER("tip_master", "Tip Master", "Achieve 20%+ average tips"),
    ELITE_SERVER("elite_server", "Elite Server", "Achieve 25%+ average tips"),
    TIP_CHAMPION("tip_champion", "Tip Champion", "Achieve 30%+ average tips"),

    // Consistency
    STEADY_TRACKER("steady_tracker", "Steady Tracker", "Track 7 consecutive days"),
    DEDICATED_LOGGER("dedicated_logger", "Dedicated Logger", "Track 30 consecutive days"),
    TRACKING_LEGEND("tracking_legend", "Tracking Legend", "Track 100 consecutive days"),

    // Earnings
    HIGH_EARNER("high_earner", "High Earner", "Earn $30+/hour average"),
    TOP_PERFORMER("top_performer", "Top Performer", "Earn $50+/hour average"),
    SALES_STAR("sales_star", "Sales Star", "Serve $1000+ in one shift"),

    // Goals
    TARGET_CRUSHER("target_crusher", "Target Crusher", "Exceed goal by 50%"),
    GOAL_GETTER("goal_getter", "Goal Getter", "Meet all weekly targets"),
    PERFECT_MONTH("perfect_month", "Perfect Month", "Meet all monthly targets");

    companion object {
        fun fromValue(value: String): AchievementType? = values().find { it.value == value }
    }
}