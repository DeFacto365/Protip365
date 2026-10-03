package com.protip365.app.presentation.notifications

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.protip365.app.MainActivity
import com.protip365.app.R
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.LocalTime
import kotlinx.datetime.toInstant
import kotlinx.datetime.TimeZone
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ShiftAlertNotificationManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val CHANNEL_ID = "shift_alerts"
        private const val CHANNEL_NAME = "Shift Alerts"
        private const val CHANNEL_DESCRIPTION = "Notifications for upcoming shifts"
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableLights(true)
                enableVibration(true)
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun scheduleShiftAlert(
        shiftId: String,
        shiftDate: LocalDate,
        startTime: LocalTime,
        employerName: String,
        alertMinutes: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Calculate alert time
        val shiftDateTime = LocalDateTime(shiftDate, startTime)
        val alertInstant = shiftDateTime.toInstant(TimeZone.currentSystemDefault())
        val duration = kotlin.time.Duration.parse("${alertMinutes}m")
        val alertTime = alertInstant.minus(duration)
        val alertMillis = alertTime.toEpochMilliseconds()

        // Don't schedule if in the past
        if (alertMillis <= System.currentTimeMillis()) {
            return
        }

        // Create intent for notification
        val intent = Intent(context, ShiftAlertReceiver::class.java).apply {
            putExtra("shift_id", shiftId)
            putExtra("employer_name", employerName)
            putExtra("start_time", startTime.toString())
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            shiftId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Schedule exact alarm
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                alertMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                alertMillis,
                pendingIntent
            )
        }
    }

    fun cancelShiftAlert(shiftId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ShiftAlertReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            shiftId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    fun areNotificationsEnabled(): Boolean {
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }
}

class ShiftAlertReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val shiftId = intent.getStringExtra("shift_id") ?: return
        val employerName = intent.getStringExtra("employer_name") ?: ""
        val startTime = intent.getStringExtra("start_time") ?: ""

        showNotification(context, shiftId, employerName, startTime)
    }

    private fun showNotification(
        context: Context,
        shiftId: String,
        employerName: String,
        startTime: String
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val notification = NotificationCompat.Builder(context, "shift_alerts")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(context.getString(R.string.notification_title))
            .setContentText(
                context.getString(
                    R.string.notification_body,
                    employerName,
                    startTime
                )
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(shiftId.hashCode(), notification)
    }
}



