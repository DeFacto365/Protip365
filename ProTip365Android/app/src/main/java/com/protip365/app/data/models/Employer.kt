package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class Employer(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("user_id")
    val userId: String,

    @SerialName("name")
    val name: String,

    @SerialName("hourly_rate")
    val hourlyRate: Double = 15.00,

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("active")
    val active: Boolean = true, // Note: field is 'active' not 'is_active'
    
    @SerialName("default_hourly_rate")
    val defaultHourlyRate: Double? = null,
    
    @SerialName("total_earnings")
    val totalEarnings: Double = 0.0
)