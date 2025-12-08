package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
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
) {
    // Helper function to extract shift ID from data
    fun getShiftId(): String? {
        return try {
            data?.let {
                if (it is JsonObject) {
                    it["shiftId"]?.let { shiftId ->
                        if (shiftId is JsonPrimitive) {
                            shiftId.content
                        } else null
                    }
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }

    // Helper function to get data as map
    fun getDataMap(): Map<String, Any>? {
        return try {
            data?.let {
                if (it is JsonObject) {
                    it.entries.associate { (key, value) ->
                        key to when (value) {
                            is JsonPrimitive -> {
                                when {
                                    value.isString -> value.content
                                    value.booleanOrNull != null -> value.booleanOrNull!!
                                    value.doubleOrNull != null -> value.doubleOrNull!!
                                    else -> value.content
                                }
                            }
                            else -> value.toString()
                        }
                    }
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }
}

enum class AlertType(val value: String) {
    SHIFT_REMINDER("shiftReminder"),
    MISSING_SHIFT("missingShift"),
    INCOMPLETE_SHIFT("incompleteShift"),
    TARGET_ACHIEVED("targetAchieved"),
    PERSONAL_BEST("personalBest"),
    REMINDER("reminder"),
    SUBSCRIPTION_LIMIT("subscription_limit"),
    WEEKLY_SUMMARY("weekly_summary"),
    ACHIEVEMENT_UNLOCKED("achievement_unlocked");

    companion object {
        fun fromValue(value: String): AlertType? = values().find { it.value == value }
    }
}