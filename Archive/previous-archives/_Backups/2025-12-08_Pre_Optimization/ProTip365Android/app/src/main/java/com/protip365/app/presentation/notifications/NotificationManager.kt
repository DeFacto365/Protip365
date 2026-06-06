package com.protip365.app.presentation.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.protip365.app.MainActivity
import com.protip365.app.R
import com.protip365.app.data.models.AlertType
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProTipNotificationManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        const val CHANNEL_ID = "protip365_alerts"
        const val CHANNEL_NAME = "ProTip365 Alerts"
        const val CHANNEL_DESCRIPTION = "Notifications for shift reminders, achievements, and targets"

        const val NOTIFICATION_ID_MISSING_SHIFT = 1001
        const val NOTIFICATION_ID_TARGET_ACHIEVED = 1002
        const val NOTIFICATION_ID_ACHIEVEMENT = 1003
        const val NOTIFICATION_ID_SUBSCRIPTION_LIMIT = 1004
        const val NOTIFICATION_ID_WEEKLY_SUMMARY = 1005
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = CHANNEL_DESCRIPTION
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showNotification(
        alertType: AlertType,
        title: String,
        message: String,
        data: Map<String, Any>? = null
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("alert_type", alertType.value)
            data?.forEach { (key, value) ->
                when (value) {
                    is String -> putExtra(key, value)
                    is Int -> putExtra(key, value)
                    is Boolean -> putExtra(key, value)
                    is Float -> putExtra(key, value)
                    is Double -> putExtra(key, value)
                    is Long -> putExtra(key, value)
                }
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            getNotificationId(alertType),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .apply {
                when (alertType) {
                    AlertType.ACHIEVEMENT_UNLOCKED -> {
                        setCategory(NotificationCompat.CATEGORY_SOCIAL)
                        setPriority(NotificationCompat.PRIORITY_HIGH)
                    }
                    AlertType.TARGET_ACHIEVED -> {
                        setCategory(NotificationCompat.CATEGORY_SOCIAL)
                    }
                    AlertType.SUBSCRIPTION_LIMIT -> {
                        setPriority(NotificationCompat.PRIORITY_HIGH)
                    }
                    AlertType.MISSING_SHIFT -> {
                        setCategory(NotificationCompat.CATEGORY_REMINDER)
                    }
                    AlertType.WEEKLY_SUMMARY -> {
                        setCategory(NotificationCompat.CATEGORY_STATUS)
                        setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    }
                    else -> {}
                }
            }
            .build()

        with(NotificationManagerCompat.from(context)) {
            try {
                notify(getNotificationId(alertType), notification)
            } catch (e: SecurityException) {
                // Handle missing notification permission
                e.printStackTrace()
            }
        }
    }

    fun cancelNotification(alertType: AlertType) {
        with(NotificationManagerCompat.from(context)) {
            cancel(getNotificationId(alertType))
        }
    }

    fun cancelAllNotifications() {
        with(NotificationManagerCompat.from(context)) {
            cancelAll()
        }
    }

    private fun getNotificationId(alertType: AlertType): Int {
        return when (alertType) {
            AlertType.MISSING_SHIFT -> NOTIFICATION_ID_MISSING_SHIFT
            AlertType.TARGET_ACHIEVED -> NOTIFICATION_ID_TARGET_ACHIEVED
            AlertType.ACHIEVEMENT_UNLOCKED -> NOTIFICATION_ID_ACHIEVEMENT
            AlertType.SUBSCRIPTION_LIMIT -> NOTIFICATION_ID_SUBSCRIPTION_LIMIT
            AlertType.WEEKLY_SUMMARY -> NOTIFICATION_ID_WEEKLY_SUMMARY
            AlertType.PERSONAL_BEST -> NOTIFICATION_ID_TARGET_ACHIEVED
            AlertType.SHIFT_REMINDER -> NOTIFICATION_ID_WEEKLY_SUMMARY
            AlertType.INCOMPLETE_SHIFT -> NOTIFICATION_ID_MISSING_SHIFT
            AlertType.REMINDER -> NOTIFICATION_ID_WEEKLY_SUMMARY
        }
    }

    fun areNotificationsEnabled(): Boolean {
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }
}