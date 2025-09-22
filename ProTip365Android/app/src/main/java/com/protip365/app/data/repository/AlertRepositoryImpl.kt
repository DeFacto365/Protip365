package com.protip365.app.data.repository

import com.protip365.app.data.models.Alert
import com.protip365.app.data.models.AlertType
import com.protip365.app.data.remote.SupabaseClient
import com.protip365.app.domain.repository.AlertRepository
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.realtime.postgresListDataFlow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.datetime.*
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AlertRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : AlertRepository {

    override fun getAlerts(): Flow<List<Alert>> {
        return flow {
            emit(emptyList())
        }
    }

    override suspend fun getUnreadCount(): Int {
        val userId = supabase.getCurrentUserId() ?: return 0

        return supabase.client.postgrest["alerts"]
            .select(columns = Columns.list("id")) {
                filter {
                    eq("user_id", userId)
                    eq("is_read", false)
                }
            }
            .decodeList<Alert>()
            .size
    }

    override suspend fun markAsRead(alertId: String) {
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())

        supabase.client.postgrest["alerts"]
            .update({
                set("is_read", true)
                set("read_at", now.toString())
            }) {
                filter {
                    eq("id", alertId)
                    eq("user_id", supabase.getCurrentUserId() ?: "")
                }
            }
    }

    override suspend fun markAllAsRead() {
        val userId = supabase.getCurrentUserId() ?: return
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())

        supabase.client.postgrest["alerts"]
            .update({
                set("is_read", true)
                set("read_at", now.toString())
            }) {
                filter {
                    eq("user_id", userId)
                    eq("is_read", false)
                }
            }
    }

    override suspend fun createAlert(alert: Alert) {
        val userId = supabase.getCurrentUserId() ?: return

        val newAlert = alert.copy(
            userId = userId,
            createdAt = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).toString()
        )

        supabase.client.postgrest["alerts"]
            .insert(newAlert)
    }

    override suspend fun deleteAlert(alertId: String) {
        supabase.client.postgrest["alerts"]
            .delete {
                filter {
                    eq("id", alertId)
                    eq("user_id", supabase.getCurrentUserId() ?: "")
                }
            }
    }

    override suspend fun deleteOldAlerts(daysOld: Int) {
        val userId = supabase.getCurrentUserId() ?: return
        val cutoffDate = Clock.System.now()
            .minus(DateTimePeriod(days = daysOld), TimeZone.currentSystemDefault())
            .toLocalDateTime(TimeZone.currentSystemDefault())

        supabase.client.postgrest["alerts"]
            .delete {
                filter {
                    eq("user_id", userId)
                    lt("created_at", cutoffDate.toString())
                }
            }
    }

    override suspend fun checkAndCreateDailyAlerts() {
        val userId = supabase.getCurrentUserId() ?: return

        // Check for missing shift from yesterday
        val yesterday = Clock.System.now()
            .minus(DateTimePeriod(days = 1), TimeZone.currentSystemDefault())
            .toLocalDateTime(TimeZone.currentSystemDefault())
            .date

        // Check if there's a shift for yesterday
        val shiftsYesterday = supabase.client.postgrest["shifts"]
            .select {
                filter {
                    eq("user_id", userId)
                    eq("shift_date", yesterday.toString())
                }
            }
            .decodeList<Map<String, Any>>()

        if (shiftsYesterday.isEmpty()) {
            // Check if we already sent this alert today
            val existingAlert = supabase.client.postgrest["alerts"]
                .select {
                    filter {
                        eq("user_id", userId)
                        eq("alert_type", AlertType.MISSING_SHIFT.value)
                        gte("created_at", yesterday.toString())
                    }
                }
                .decodeList<Alert>()

            if (existingAlert.isEmpty()) {
                createAlert(
                    Alert(
                        userId = userId,
                        alertType = AlertType.MISSING_SHIFT.value,
                        title = "Missing Shift Entry",
                        message = "You didn't log any shifts yesterday. Don't forget to track your earnings!",
                        data = JsonObject(mapOf(
                            "date" to JsonPrimitive(yesterday.toString())
                        ))
                    )
                )
            }
        }

        // Clean up old alerts (older than 30 days)
        deleteOldAlerts(30)
    }
}