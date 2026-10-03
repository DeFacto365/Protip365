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
        
        // Use same grouping as ProTipNotificationManager for consistency
        private const val GROUP_SHIFT_REMINDERS = "group_shift_reminders"
        private const val SUMMARY_ID_SHIFT_REMINDERS = 2001
    }

    init {
        createNotificationChannel()
    }

    /**
     * Creates notification channel with Android 16 optimized settings
     * Enhanced for proper categorization and grouping
     */
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
                // Android 16: Better support for grouping and Live Updates
                setShowBadge(true)
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

    fun updateShiftAlert(
        shiftId: String,
        shiftDate: LocalDate,
        startTime: LocalTime,
        employerName: String,
        alertMinutes: Int
    ) {
        // iOS-conformant: Update is same as schedule with FLAG_UPDATE_CURRENT
        // This will replace the existing alert with the same shiftId
        scheduleShiftAlert(shiftId, shiftDate, startTime, employerName, alertMinutes)
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
    companion object {
        private const val CHANNEL_ID = "shift_alerts"
        // Use same grouping as ProTipNotificationManager for consistency
        private const val GROUP_SHIFT_REMINDERS = "group_shift_reminders"
        private const val SUMMARY_ID_SHIFT_REMINDERS = 2001
    }

    override fun onReceive(context: Context, intent: Intent) {
        val shiftId = intent.getStringExtra("shift_id") ?: return
        val employerName = intent.getStringExtra("employer_name") ?: ""
        val startTime = intent.getStringExtra("start_time") ?: ""

        showNotification(context, shiftId, employerName, startTime)
    }

    /**
     * Shows a notification with enhanced Android 16 features:
     * - Notification grouping
     * - Rich content with expandable styles
     * - Action buttons
     * - Live Updates support (when available)
     */
    private fun showNotification(
        context: Context,
        shiftId: String,
        employerName: String,
        startTime: String
    ) {
        val notificationManager = NotificationManagerCompat.from(context)
        
        // Check notification permission for Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (!notificationManager.areNotificationsEnabled()) {
                return
            }
        }

        // Create intent to navigate to shift when notification is tapped (iOS-conformant)
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("navigate_to_shift", shiftId)
            putExtra("action", "view_shift")
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            shiftId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create "View Shift" action intent
        val viewShiftIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("navigate_to_shift", shiftId)
            putExtra("action", "view_shift")
        }
        
        val viewShiftPendingIntent = PendingIntent.getActivity(
            context,
            shiftId.hashCode() + 3000,
            viewShiftIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notificationText = context.getString(
            R.string.notification_body,
            employerName,
            startTime
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(context.getString(R.string.notification_title))
            .setContentText(notificationText)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent) // iOS-conformant: Navigate to shift on tap
            .setGroup(GROUP_SHIFT_REMINDERS) // Android 16 notification grouping
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setStyle(NotificationCompat.BigTextStyle().bigText(notificationText)) // Rich content
            .addAction(
                R.drawable.ic_notification,
                context.getString(R.string.view_shift),
                viewShiftPendingIntent
            ) // Notification action
            .build()

        try {
            notificationManager.notify(shiftId.hashCode(), notification)
            // Show summary notification for grouping
            showSummaryNotification(context)
        } catch (e: SecurityException) {
            e.printStackTrace()
        }
    }
    
    /**
     * Shows a summary notification for grouped shift reminders (Android 16 requirement)
     */
    private fun showSummaryNotification(context: Context) {
        val notificationManager = NotificationManagerCompat.from(context)
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("notification_group", GROUP_SHIFT_REMINDERS)
        }
        
        val summaryPendingIntent = PendingIntent.getActivity(
            context,
            SUMMARY_ID_SHIFT_REMINDERS,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val summaryNotification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(context.getString(R.string.shift_reminders))
            .setContentText(context.getString(R.string.notification_summary_text))
            .setGroup(GROUP_SHIFT_REMINDERS)
            .setGroupSummary(true) // Mark as summary notification
            .setContentIntent(summaryPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        
        try {
            notificationManager.notify(SUMMARY_ID_SHIFT_REMINDERS, summaryNotification)
        } catch (e: SecurityException) {
            e.printStackTrace()
        }
    }
}



