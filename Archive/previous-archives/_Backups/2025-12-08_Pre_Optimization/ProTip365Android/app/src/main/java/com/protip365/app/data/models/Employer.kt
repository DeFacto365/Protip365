package com.protip365.app.data.models

import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName
import kotlinx.datetime.Instant
import java.util.UUID

@Serializable
data class Employer(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    val name: String,
    @SerialName("hourly_rate")
    val hourlyRate: Double,
    val active: Boolean = true,
    val color: String? = null,
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    val uuid: UUID
        get() = UUID.fromString(id)
}