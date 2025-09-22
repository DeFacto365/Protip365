package com.protip365.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class Shift(
    @SerialName("id")
    val id: String = UUID.randomUUID().toString(),

    @SerialName("user_id")
    val userId: String,

    @SerialName("shift_date")
    val shiftDate: String, // Date as string in ISO format

    @SerialName("hours")
    val hours: Double,

    @SerialName("hourly_rate")
    val hourlyRate: Double? = null,

    @SerialName("sales")
    val sales: Double = 0.0,

    @SerialName("tips")
    val tips: Double = 0.0,

    @SerialName("notes")
    val notes: String? = null,

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("employer_id")
    val employerId: String? = null,

    @SerialName("cash_out")
    val cashOut: Double = 0.0,

    @SerialName("cash_out_note")
    val cashOutNote: String? = null,

    @SerialName("start_time")
    val startTime: String? = null, // Time as string

    @SerialName("end_time")
    val endTime: String? = null, // Time as string

    @SerialName("other")
    val other: Double = 0.0, // Note: This is DOUBLE not NUMERIC in database

    @SerialName("expected_hours")
    val expectedHours: Double? = null,

    @SerialName("lunch_break_hours")
    val lunchBreakHours: Double = 0.0,

    @SerialName("status")
    val status: String = "completed",

    @SerialName("lunch_break_minutes")
    val lunchBreakMinutes: Int = 0,

    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    val totalEarnings: Double
        get() = (hourlyRate ?: 0.0) * hours + tips + other - cashOut

    val tipPercentage: Double
        get() = if (sales > 0) (tips / sales) * 100 else 0.0

    val effectiveHourlyRate: Double
        get() = if (hours > 0) totalEarnings / hours else 0.0
}