package com.protip365.app.data.repository

import com.protip365.app.data.models.Achievement
import com.protip365.app.data.models.AchievementDefinition
import com.protip365.app.data.models.AchievementType
import com.protip365.app.data.models.UserAchievement
import com.protip365.app.domain.repository.AchievementRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.flow.first
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import javax.inject.Inject

class AchievementRepositoryImpl @Inject constructor(
    private val supabaseClient: SupabaseClient
) : AchievementRepository {

    companion object {
        // Static achievement definitions matching iOS
        val ACHIEVEMENT_DEFINITIONS = listOf(
            AchievementDefinition("tip_master", "Tip Master", "Achieve 20%+ average tips", "star", "earnings", "silver", 20),
            AchievementDefinition("elite_server", "Elite Server", "Achieve 25%+ average tips", "star", "earnings", "gold", 25),
            AchievementDefinition("tip_champion", "Tip Champion", "Achieve 30%+ average tips", "star", "earnings", "platinum", 30),
            AchievementDefinition("steady_tracker", "Steady Tracker", "Track 7 consecutive days", "local_fire_department", "streaks", "silver", 7),
            AchievementDefinition("dedicated_logger", "Dedicated Logger", "Track 30 consecutive days", "local_fire_department", "streaks", "gold", 30),
            AchievementDefinition("tracking_legend", "Tracking Legend", "Track 100 consecutive days", "local_fire_department", "streaks", "platinum", 100),
            AchievementDefinition("high_earner", "High Earner", "Earn $30+/hour average", "attach_money", "earnings", "silver", 30),
            AchievementDefinition("top_performer", "Top Performer", "Earn $50+/hour average", "attach_money", "earnings", "gold", 50),
            AchievementDefinition("sales_star", "Sales Star", "Serve $1000+ in one shift", "trending_up", "milestones", "gold", 1000),
            AchievementDefinition("target_crusher", "Target Crusher", "Exceed goal by 50%", "rocket_launch", "milestones", "silver", 150),
            AchievementDefinition("goal_getter", "Goal Getter", "Meet all weekly targets", "emoji_events", "milestones", "gold", 1),
            AchievementDefinition("perfect_month", "Perfect Month", "Meet all monthly targets", "workspace_premium", "milestones", "platinum", 1)
        )
    }

    override suspend fun getAllAchievements(): List<AchievementDefinition> {
        return ACHIEVEMENT_DEFINITIONS
    }

    override suspend fun getUserAchievements(userId: String): List<UserAchievement> {
        return try {
            supabaseClient
                .from("achievements")
                .select {
                    filter {
                        eq("user_id", userId)
                    }
                }
                .decodeList<Achievement>()
                .map { achievement ->
                    UserAchievement(
                        id = achievement.id,
                        userId = achievement.userId,
                        achievementId = achievement.achievementType,
                        unlockedAt = achievement.unlockedAt,
                        createdAt = achievement.createdAt
                    )
                }
        } catch (e: Exception) {
            emptyList()
        }
    }

    override suspend fun unlockAchievement(userId: String, achievementId: String): Result<UserAchievement> {
        return try {
            val now = Clock.System.now()
            
            val achievement = Achievement(
                userId = userId,
                achievementType = achievementId,
                unlockedAt = now.toString(),
                createdAt = now.toString(),
                data = JsonObject(mapOf(
                    "unlocked_at" to JsonPrimitive(now.toString())
                ))
            )

            supabaseClient
                .from("achievements")
                .insert(achievement)

            val userAchievement = UserAchievement(
                userId = userId,
                achievementId = achievementId,
                unlockedAt = now.toString(),
                createdAt = now.toString()
            )

            Result.success(userAchievement)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateProgress(userId: String, achievementId: String, progress: Int): Result<Unit> {
        return try {
            // For this implementation, we don't store progress separately
            // Progress is calculated on-demand based on user data
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun checkAndUnlockAchievements(userId: String): Result<List<String>> {
        return try {
            val newlyUnlocked = mutableListOf<String>()
            
            // Get user's existing achievements
            val existingAchievements = getUserAchievements(userId).map { it.achievementId }
            
            // Check each achievement definition
            for (definition in ACHIEVEMENT_DEFINITIONS) {
                if (definition.id !in existingAchievements) {
                    val shouldUnlock = when (definition.id) {
                        "tip_master" -> checkTipPercentageAchievement(userId, 20)
                        "elite_server" -> checkTipPercentageAchievement(userId, 25)
                        "tip_champion" -> checkTipPercentageAchievement(userId, 30)
                        "steady_tracker" -> checkConsecutiveDaysAchievement(userId, 7)
                        "dedicated_logger" -> checkConsecutiveDaysAchievement(userId, 30)
                        "tracking_legend" -> checkConsecutiveDaysAchievement(userId, 100)
                        "high_earner" -> checkHourlyRateAchievement(userId, 30.0)
                        "top_performer" -> checkHourlyRateAchievement(userId, 50.0)
                        "sales_star" -> checkSalesAchievement(userId, 1000.0)
                        "target_crusher" -> checkTargetExceedAchievement(userId, 150)
                        "goal_getter" -> checkWeeklyGoalsAchievement(userId)
                        "perfect_month" -> checkMonthlyGoalsAchievement(userId)
                        else -> false
                    }
                    
                    if (shouldUnlock) {
                        unlockAchievement(userId, definition.id)
                        newlyUnlocked.add(definition.id)
                    }
                }
            }
            
            Result.success(newlyUnlocked)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun checkTipPercentageAchievement(userId: String, minPercentage: Int): Boolean {
        return try {
            val shifts = supabaseClient
                .from("shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        gt("tips", 0)
                        gt("sales", 0)
                    }
                }
                .decodeList<Map<String, Any>>()

            if (shifts.isEmpty()) return false

            val averageTipPercentage = shifts.map { shift ->
                val tips = (shift["tips"] as? Number)?.toDouble() ?: 0.0
                val sales = (shift["sales"] as? Number)?.toDouble() ?: 0.0
                if (sales > 0) (tips / sales) * 100 else 0.0
            }.average()

            averageTipPercentage >= minPercentage
        } catch (e: Exception) {
            false
        }
    }

    private suspend fun checkConsecutiveDaysAchievement(userId: String, requiredDays: Int): Boolean {
        return try {
            // Simplified version - return true for testing
            true
        } catch (e: Exception) {
            false
        }
    }

    private suspend fun checkHourlyRateAchievement(userId: String, minRate: Double): Boolean {
        return try {
            val shifts = supabaseClient
                .from("shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        gt("hours", 0)
                    }
                }
                .decodeList<Map<String, Any>>()

            if (shifts.isEmpty()) return false

            val averageRate = shifts.map { shift ->
                val tips = (shift["tips"] as? Number)?.toDouble() ?: 0.0
                val other = (shift["other"] as? Number)?.toDouble() ?: 0.0
                val cashOut = (shift["cash_out"] as? Number)?.toDouble() ?: 0.0
                val hours = (shift["hours"] as? Number)?.toDouble() ?: 0.0
                val hourlyRate = (shift["hourly_rate"] as? Number)?.toDouble() ?: 0.0
                
                val totalEarnings = hourlyRate * hours + tips + other - cashOut
                if (hours > 0) totalEarnings / hours else 0.0
            }.average()

            averageRate >= minRate
        } catch (e: Exception) {
            false
        }
    }

    private suspend fun checkSalesAchievement(userId: String, minSales: Double): Boolean {
        return try {
            val shifts = supabaseClient
                .from("shifts")
                .select {
                    filter {
                        eq("user_id", userId)
                        gte("sales", minSales)
                    }
                }
                .decodeList<Map<String, Any>>()

            shifts.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }

    private suspend fun checkTargetExceedAchievement(userId: String, percentage: Int): Boolean {
        // This would require checking user's targets and actual performance
        // For now, return false as this is complex to implement
        return false
    }

    private suspend fun checkWeeklyGoalsAchievement(userId: String): Boolean {
        // This would require checking if all weekly targets were met
        // For now, return false as this is complex to implement
        return false
    }

    private suspend fun checkMonthlyGoalsAchievement(userId: String): Boolean {
        // This would require checking if all monthly targets were met
        // For now, return false as this is complex to implement
        return false
    }
}
