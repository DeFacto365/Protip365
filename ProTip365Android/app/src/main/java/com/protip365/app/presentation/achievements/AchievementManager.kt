package com.protip365.app.presentation.achievements

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AchievementManager @Inject constructor() {
    
    private val _achievements = MutableStateFlow<List<Achievement>>(emptyList())
    val achievements: StateFlow<List<Achievement>> = _achievements.asStateFlow()
    
    private val _newAchievements = MutableStateFlow<List<Achievement>>(emptyList())
    val newAchievements: StateFlow<List<Achievement>> = _newAchievements.asStateFlow()
    
    fun checkForAchievements(
        shifts: List<com.protip365.app.data.models.Shift>,
        currentStats: DashboardStats,
        targets: UserTargets
    ) {
        val newAchievementsList = mutableListOf<Achievement>()
        
        // First shift achievement
        if (shifts.size == 1 && !hasAchievement(AchievementType.FIRST_SHIFT)) {
            newAchievementsList.add(
                Achievement(
                    id = "first_shift",
                    type = AchievementType.FIRST_SHIFT,
                    title = "First Shift",
                    description = "Congratulations on logging your first shift!",
                    icon = "🎉",
                    unlockedAt = System.currentTimeMillis(),
                    isUnlocked = true
                )
            )
        }
        
        // 10 shifts achievement
        if (shifts.size >= 10 && !hasAchievement(AchievementType.TEN_SHIFTS)) {
            newAchievementsList.add(
                Achievement(
                    id = "ten_shifts",
                    type = AchievementType.TEN_SHIFTS,
                    title = "Consistent Worker",
                    description = "You've logged 10 shifts!",
                    icon = "💪",
                    unlockedAt = System.currentTimeMillis(),
                    isUnlocked = true
                )
            )
        }
        
        // 50 shifts achievement
        if (shifts.size >= 50 && !hasAchievement(AchievementType.FIFTY_SHIFTS)) {
            newAchievementsList.add(
                Achievement(
                    id = "fifty_shifts",
                    type = AchievementType.FIFTY_SHIFTS,
                    title = "Shift Master",
                    description = "You've logged 50 shifts!",
                    icon = "🏆",
                    unlockedAt = System.currentTimeMillis(),
                    isUnlocked = true
                )
            )
        }
        
        // 100 shifts achievement
        if (shifts.size >= 100 && !hasAchievement(AchievementType.HUNDRED_SHIFTS)) {
            newAchievementsList.add(
                Achievement(
                    id = "hundred_shifts",
                    type = AchievementType.HUNDRED_SHIFTS,
                    title = "Century Club",
                    description = "You've logged 100 shifts!",
                    icon = "💯",
                    unlockedAt = System.currentTimeMillis(),
                    isUnlocked = true
                )
            )
        }
        
        // Tip target achievement
        if (currentStats.totalTips >= targets.tipTargetDaily && !hasAchievement(AchievementType.DAILY_TIP_TARGET)) {
            newAchievementsList.add(
                Achievement(
                    id = "daily_tip_target",
                    type = AchievementType.DAILY_TIP_TARGET,
                    title = "Daily Tip Target",
                    description = "You've reached your daily tip target!",
                    icon = "💰",
                    unlockedAt = System.currentTimeMillis(),
                    isUnlocked = true
                )
            )
        }
        
        // Sales target achievement
        if (currentStats.totalSales >= targets.salesTargetDaily && !hasAchievement(AchievementType.DAILY_SALES_TARGET)) {
            newAchievementsList.add(
                Achievement(
                    id = "daily_sales_target",
                    type = AchievementType.DAILY_SALES_TARGET,
                    title = "Daily Sales Target",
                    description = "You've reached your daily sales target!",
                    icon = "📈",
                    unlockedAt = System.currentTimeMillis(),
                    isUnlocked = true
                )
            )
        }
        
        // High tip percentage achievement
        if (currentStats.averageTipPercentage >= 20.0 && !hasAchievement(AchievementType.HIGH_TIP_PERCENTAGE)) {
            newAchievementsList.add(
                Achievement(
                    id = "high_tip_percentage",
                    type = AchievementType.HIGH_TIP_PERCENTAGE,
                    title = "Tip Master",
                    description = "You've achieved 20%+ tip percentage!",
                    icon = "⭐",
                    unlockedAt = System.currentTimeMillis(),
                    isUnlocked = true
                )
            )
        }
        
        // Perfect week achievement (7 consecutive days with shifts)
        if (hasPerfectWeek(shifts) && !hasAchievement(AchievementType.PERFECT_WEEK)) {
            newAchievementsList.add(
                Achievement(
                    id = "perfect_week",
                    type = AchievementType.PERFECT_WEEK,
                    title = "Perfect Week",
                    description = "You've worked 7 consecutive days!",
                    icon = "🔥",
                    unlockedAt = System.currentTimeMillis(),
                    isUnlocked = true
                )
            )
        }
        
        // Add new achievements to the list
        if (newAchievementsList.isNotEmpty()) {
            val currentAchievements = _achievements.value.toMutableList()
            currentAchievements.addAll(newAchievementsList)
            _achievements.value = currentAchievements
            _newAchievements.value = newAchievementsList
        }
    }
    
    private fun hasAchievement(type: AchievementType): Boolean {
        return _achievements.value.any { it.type == type }
    }
    
    private fun hasPerfectWeek(shifts: List<com.protip365.app.data.models.Shift>): Boolean {
        // Check if there are 7 consecutive days with shifts
        val shiftDates = shifts.map { java.time.LocalDate.parse(it.shiftDate) }.distinct().sorted()
        
        if (shiftDates.size < 7) return false
        
        // Check for consecutive days
        for (i in 0..shiftDates.size - 7) {
            val weekDates = shiftDates.subList(i, i + 7)
            if (isConsecutiveDays(weekDates)) {
                return true
            }
        }
        
        return false
    }
    
    private fun isConsecutiveDays(dates: List<java.time.LocalDate>): Boolean {
        for (i in 1 until dates.size) {
            if (dates[i] != dates[i - 1].plusDays(1)) {
                return false
            }
        }
        return true
    }
    
    fun clearNewAchievements() {
        _newAchievements.value = emptyList()
    }
    
    fun getAllAchievements(): List<Achievement> {
        return _achievements.value
    }
    
    fun getUnlockedAchievements(): List<Achievement> {
        return _achievements.value.filter { it.isUnlocked }
    }
    
    fun getLockedAchievements(): List<Achievement> {
        return _achievements.value.filter { !it.isUnlocked }
    }
}

enum class AchievementType {
    FIRST_SHIFT,
    TEN_SHIFTS,
    FIFTY_SHIFTS,
    HUNDRED_SHIFTS,
    DAILY_TIP_TARGET,
    DAILY_SALES_TARGET,
    HIGH_TIP_PERCENTAGE,
    PERFECT_WEEK
}

data class Achievement(
    val id: String,
    val type: AchievementType,
    val title: String,
    val description: String,
    val icon: String,
    val unlockedAt: Long,
    val isUnlocked: Boolean
)

data class DashboardStats(
    val totalRevenue: Double = 0.0,
    val totalWages: Double = 0.0,
    val totalTips: Double = 0.0,
    val totalSales: Double = 0.0,
    val totalHours: Double = 0.0,
    val totalTipOut: Double = 0.0,
    val otherIncome: Double = 0.0,
    val averageTipPercentage: Double = 0.0,
    val hourlyRate: Double = 0.0,
    val revenueChange: Double = 0.0,
    val wagesChange: Double = 0.0,
    val tipsChange: Double = 0.0,
    val hoursChange: Double = 0.0,
    val salesChange: Double = 0.0,
    val tipOutChange: Double = 0.0,
    val otherChange: Double = 0.0
)

data class UserTargets(
    val tipTargetDaily: Double = 0.0,
    val salesTargetDaily: Double = 0.0,
    val hoursTargetDaily: Double = 0.0
)
