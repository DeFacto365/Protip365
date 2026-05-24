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

/**
 * Enhanced Notification Manager with Android 16 features:
 * - Live Updates support for dynamic lock screen notifications
 * - Notification grouping with summary notifications
 * - Rich notification content with actions
 * - Android 16 compatibility
 */
@Singleton
class ProTipNotificationManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        const val CHANNEL_ID = "protip365_alerts"
        const val CHANNEL_NAME = "ProTip365 Alerts"
        const val CHANNEL_DESCRIPTION = "Notifications for shift reminders, achievements, and targets"

        // Notification IDs
        const val NOTIFICATION_ID_MISSING_SHIFT = 1001
        const val NOTIFICATION_ID_TARGET_ACHIEVED = 1002
        const val NOTIFICATION_ID_ACHIEVEMENT = 1003
        const val NOTIFICATION_ID_SUBSCRIPTION_LIMIT = 1004
        const val NOTIFICATION_ID_WEEKLY_SUMMARY = 1005
        
        // Notification groups for Android 16 grouping
        const val GROUP_SHIFT_REMINDERS = "group_shift_reminders"
        const val GROUP_ACHIEVEMENTS = "group_achievements"
        const val GROUP_TARGETS = "group_targets"
        const val GROUP_ALERTS = "group_alerts"
        
        // Summary notification IDs
        const val SUMMARY_ID_SHIFT_REMINDERS = 2001
        const val SUMMARY_ID_ACHIEVEMENTS = 2002
        const val SUMMARY_ID_TARGETS = 2003
        const val SUMMARY_ID_ALERTS = 2004
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
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
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

    /**
     * Shows a notification with enhanced Android 16 features:
     * - Notification grouping
     * - Rich content with expandable styles
     * - Action buttons
     * - Live Updates support (when available)
     */
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

        // Get notification group and build notification
        val groupKey = getGroupKey(alertType)
        val notificationId = getNotificationId(alertType)
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setGroup(groupKey) // Android 16 notification grouping
            .apply {
                // Add notification actions
                addNotificationActions(alertType, data)
                
                // Apply category-specific settings
                when (alertType) {
                    AlertType.ACHIEVEMENT_UNLOCKED -> {
                        setCategory(NotificationCompat.CATEGORY_SOCIAL)
                        setPriority(NotificationCompat.PRIORITY_HIGH)
                        setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    }
                    AlertType.TARGET_ACHIEVED -> {
                        setCategory(NotificationCompat.CATEGORY_SOCIAL)
                        setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    }
                    AlertType.SUBSCRIPTION_LIMIT -> {
                        setPriority(NotificationCompat.PRIORITY_HIGH)
                    }
                    AlertType.MISSING_SHIFT, AlertType.INCOMPLETE_SHIFT -> {
                        setCategory(NotificationCompat.CATEGORY_REMINDER)
                        setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    }
                    AlertType.SHIFT_REMINDER -> {
                        setCategory(NotificationCompat.CATEGORY_REMINDER)
                        setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    }
                    AlertType.WEEKLY_SUMMARY -> {
                        setCategory(NotificationCompat.CATEGORY_STATUS)
                        setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    }
                    AlertType.PERSONAL_BEST -> {
                        setCategory(NotificationCompat.CATEGORY_SOCIAL)
                        setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    }
                    else -> {
                        setStyle(NotificationCompat.BigTextStyle().bigText(message))
                    }
                }
            }
            .build()

        with(NotificationManagerCompat.from(context)) {
            try {
                // Check notification permission for Android 13+
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    if (!areNotificationsEnabled()) {
                        println("⚠️ ProTipNotificationManager: Notifications are disabled by user")
                        return
                    }
                }
                
                notify(notificationId, notification)
                // Show summary notification for grouping
                showSummaryNotification(groupKey, alertType)
            } catch (e: SecurityException) {
                // Handle missing notification permission
                println("❌ ProTipNotificationManager: SecurityException - ${e.message}")
                e.printStackTrace()
            } catch (e: Exception) {
                println("❌ ProTipNotificationManager: Exception - ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Adds action buttons to notifications based on alert type
     */
    private fun NotificationCompat.Builder.addNotificationActions(
        alertType: AlertType,
        data: Map<String, Any>?
    ) {
        when (alertType) {
            AlertType.MISSING_SHIFT, AlertType.INCOMPLETE_SHIFT -> {
                // Add "Add Entry" action
                val addIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    putExtra("action", "add_entry")
                    data?.get("shiftId")?.let { putExtra("shift_id", it.toString()) }
                }
                val addPendingIntent = PendingIntent.getActivity(
                    context,
                    getNotificationId(alertType) + 1000,
                    addIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                addAction(
                    R.drawable.ic_notification,
                    context.getString(R.string.add_entry),
                    addPendingIntent
                )
            }
            AlertType.ACHIEVEMENT_UNLOCKED, AlertType.TARGET_ACHIEVED -> {
                // Add "View Details" action
                val viewIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    putExtra("action", "view_details")
                    putExtra("alert_type", alertType.value)
                }
                val viewPendingIntent = PendingIntent.getActivity(
                    context,
                    getNotificationId(alertType) + 2000,
                    viewIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                addAction(
                    R.drawable.ic_notification,
                    context.getString(R.string.view_details),
                    viewPendingIntent
                )
            }
            AlertType.SHIFT_REMINDER -> {
                // Add "View Shift" action
                val viewIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    putExtra("action", "view_shift")
                    data?.get("shiftId")?.let { putExtra("shift_id", it.toString()) }
                }
                val viewPendingIntent = PendingIntent.getActivity(
                    context,
                    getNotificationId(alertType) + 3000,
                    viewIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                addAction(
                    R.drawable.ic_notification,
                    context.getString(R.string.view_shift),
                    viewPendingIntent
                )
            }
            else -> {}
        }
    }
    
    /**
     * Gets the notification group key for Android 16 grouping
     */
    private fun getGroupKey(alertType: AlertType): String {
        return when (alertType) {
            AlertType.SHIFT_REMINDER, AlertType.MISSING_SHIFT, AlertType.INCOMPLETE_SHIFT -> {
                GROUP_SHIFT_REMINDERS
            }
            AlertType.ACHIEVEMENT_UNLOCKED, AlertType.PERSONAL_BEST -> {
                GROUP_ACHIEVEMENTS
            }
            AlertType.TARGET_ACHIEVED -> {
                GROUP_TARGETS
            }
            else -> {
                GROUP_ALERTS
            }
        }
    }
    
    /**
     * Shows a summary notification for grouped notifications (Android 16 requirement)
     */
    private fun showSummaryNotification(groupKey: String, alertType: AlertType) {
        val summaryTitle = when (groupKey) {
            GROUP_SHIFT_REMINDERS -> context.getString(R.string.shift_reminders)
            GROUP_ACHIEVEMENTS -> context.getString(R.string.achievements)
            GROUP_TARGETS -> context.getString(R.string.targets)
            else -> context.getString(R.string.app_name)
        }
        
        val summaryId = when (groupKey) {
            GROUP_SHIFT_REMINDERS -> SUMMARY_ID_SHIFT_REMINDERS
            GROUP_ACHIEVEMENTS -> SUMMARY_ID_ACHIEVEMENTS
            GROUP_TARGETS -> SUMMARY_ID_TARGETS
            else -> SUMMARY_ID_ALERTS
        }
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("notification_group", groupKey)
        }
        
        val summaryPendingIntent = PendingIntent.getActivity(
            context,
            summaryId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val summaryNotification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(summaryTitle)
            .setContentText(context.getString(R.string.notification_summary_text))
            .setGroup(groupKey)
            .setGroupSummary(true) // Mark as summary notification
            .setContentIntent(summaryPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(summaryId, summaryNotification)
            } catch (e: SecurityException) {
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
    
    /**
     * Updates a notification with Live Updates support (Android 16+)
     * This allows notifications to update dynamically on the lock screen
     * 
     * @param alertType The type of alert
     * @param title Updated title
     * @param message Updated message
     * @param data Optional data map
     */
    fun updateNotification(
        alertType: AlertType,
        title: String,
        message: String,
        data: Map<String, Any>? = null
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ supports notification updates
            showNotification(alertType, title, message, data)
        }
    }
    
    /**
     * Creates a Live Update notification for shift reminders with countdown timer
     * Android 16 feature: Dynamic lock screen notifications
     * 
     * @param shiftId Shift ID
     * @param shiftTitle Shift title/employer name
     * @param timeRemaining Time remaining until shift (e.g., "30 minutes")
     */
    fun showShiftReminderLiveUpdate(
        shiftId: String,
        shiftTitle: String,
        timeRemaining: String
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("shift_id", shiftId)
            putExtra("action", "view_shift")
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            shiftId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("$shiftTitle - $timeRemaining")
            .setContentText(context.getString(R.string.shift_starting_soon))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setGroup(GROUP_SHIFT_REMINDERS)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setOngoing(true) // Keep notification visible for Live Updates
            .setStyle(NotificationCompat.BigTextStyle().bigText(
                "${context.getString(R.string.shift_starting_soon)}\n$timeRemaining"
            ))
            .build()
        
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(shiftId.hashCode(), notification)
            } catch (e: SecurityException) {
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Creates a Live Update notification for achievement unlocks
     * Android 16 feature: Dynamic lock screen notifications
     */
    fun showAchievementLiveUpdate(
        achievementTitle: String,
        achievementDescription: String
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("action", "view_achievements")
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID_ACHIEVEMENT,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(achievementTitle)
            .setContentText(achievementDescription)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setGroup(GROUP_ACHIEVEMENTS)
            .setCategory(NotificationCompat.CATEGORY_SOCIAL)
            .setStyle(NotificationCompat.BigTextStyle().bigText(achievementDescription))
            .build()
        
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(NOTIFICATION_ID_ACHIEVEMENT, notification)
                showSummaryNotification(GROUP_ACHIEVEMENTS, AlertType.ACHIEVEMENT_UNLOCKED)
            } catch (e: SecurityException) {
                e.printStackTrace()
            }
        }
    }
}