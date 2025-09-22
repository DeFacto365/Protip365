package com.protip365.app.domain.repository

import com.protip365.app.data.models.Achievement
import com.protip365.app.data.models.UserAchievement

interface AchievementRepository {
    suspend fun getAllAchievements(): List<com.protip365.app.data.models.AchievementDefinition>
    suspend fun getUserAchievements(userId: String): List<UserAchievement>
    suspend fun unlockAchievement(userId: String, achievementId: String): Result<UserAchievement>
    suspend fun updateProgress(userId: String, achievementId: String, progress: Int): Result<Unit>
    suspend fun checkAndUnlockAchievements(userId: String): Result<List<String>> // Returns newly unlocked achievement IDs
}