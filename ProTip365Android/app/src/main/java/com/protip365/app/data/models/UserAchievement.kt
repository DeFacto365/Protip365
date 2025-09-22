package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class UserAchievement(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("user_id")
    val userId: String,

    @SerialName("achievement_id")
    val achievementId: String,

    @SerialName("progress")
    val progress: Int = 0,

    @SerialName("unlocked_at")
    val unlockedAt: String? = null,

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("updated_at")
    val updatedAt: String? = null
)


