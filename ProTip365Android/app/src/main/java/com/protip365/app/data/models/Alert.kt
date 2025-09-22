package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import java.util.UUID

@Serializable
data class Alert(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("user_id")
    val userId: String,

    @SerialName("alert_type")
    val alertType: String,

    @SerialName("title")
    val title: String,

    @SerialName("message")
    val message: String,

    @SerialName("is_read")
    val isRead: Boolean = false,

    @SerialName("action")
    val action: String? = null,

    @SerialName("data")
    val data: JsonElement? = null,

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("read_at")
    val readAt: String? = null
)

enum class AlertType(val value: String) {
    MISSING_SHIFT("missing_shift"),
    TARGET_ACHIEVED("target_achieved"),
    NEW_PERSONAL_BEST("new_personal_best"),
    SUBSCRIPTION_LIMIT("subscription_limit"),
    WEEKLY_SUMMARY("weekly_summary"),
    ACHIEVEMENT_UNLOCKED("achievement_unlocked");

    companion object {
        fun fromValue(value: String): AlertType? = values().find { it.value == value }
    }
}