package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class UserSubscription(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("user_id")
    val userId: String,

    @SerialName("product_id")
    val productId: String? = null,

    @SerialName("status")
    val status: String? = null, // Must be: active, expired, cancelled

    @SerialName("expires_at")
    val expiresAt: String? = null,

    @SerialName("transaction_id")
    val transactionId: String? = null,

    @SerialName("purchase_date")
    val purchaseDate: String? = null,

    @SerialName("environment")
    val environment: String? = null, // Must be: sandbox, production

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    init {
        status?.let {
            require(it in listOf("active", "expired", "cancelled")) {
                "Status must be active, expired, or cancelled"
            }
        }
        environment?.let {
            require(it in listOf("sandbox", "production")) {
                "Environment must be sandbox or production"
            }
        }
    }
}

enum class SubscriptionStatus(val value: String) {
    ACTIVE("active"),
    EXPIRED("expired"),
    CANCELLED("cancelled");

    companion object {
        fun fromValue(value: String): SubscriptionStatus? = values().find { it.value == value }
    }
}

enum class SubscriptionEnvironment(val value: String) {
    SANDBOX("sandbox"),
    PRODUCTION("production");

    companion object {
        fun fromValue(value: String): SubscriptionEnvironment? = values().find { it.value == value }
    }
}

// Subscription tiers matching iOS
enum class SubscriptionTier(
    val id: String,
    val displayName: String,
    val price: Double,
    val priceAnnual: Double,
    val shiftsPerWeek: Int?,
    val entriesPerWeek: Int?
) {
    NONE("none", "Free", 0.0, 0.0, null, null),
    PART_TIME("parttime", "Part-Time", 2.99, 30.0, 3, 3),
    FULL_ACCESS("full", "Full Access", 4.99, 49.99, null, null);

    companion object {
        fun fromId(id: String): SubscriptionTier = values().find { it.id == id } ?: NONE
    }
}