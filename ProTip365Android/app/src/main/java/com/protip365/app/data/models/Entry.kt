package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class Entry(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("user_id")
    val userId: String,

    @SerialName("employer_id")
    val employerId: String? = null,

    @SerialName("entry_date")
    val entryDate: String, // Date as string in ISO format

    @SerialName("sales")
    val sales: Double = 0.0,

    @SerialName("tips")
    val tips: Double = 0.0,

    @SerialName("hourly_rate")
    val hourlyRate: Double? = 0.0,

    @SerialName("cash_out")
    val cashOut: Double = 0.0,

    @SerialName("other")
    val other: Double = 0.0,

    @SerialName("notes")
    val notes: String? = null,

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    val totalEarnings: Double
        get() = tips + other - cashOut

    val tipPercentage: Double
        get() = if (sales > 0) (tips / sales) * 100 else 0.0
}