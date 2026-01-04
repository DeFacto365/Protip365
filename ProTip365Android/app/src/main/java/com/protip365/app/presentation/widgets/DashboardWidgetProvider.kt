package com.protip365.app.presentation.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.protip365.app.R
import java.text.NumberFormat
import java.util.Locale

/**
 * Dashboard widget provider for ProTip365
 * Displays weekly earnings summary on home screen
 * 
 * Note: Widget updates are triggered by the app when dashboard data changes.
 * The widget reads cached data from SharedPreferences for performance.
 */
class DashboardWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "com.protip365.app.widget"
        private const val PREF_PREFIX_KEY = "widget_"
        private const val KEY_TOTAL_REVENUE = "total_revenue"
        private const val KEY_TIPS = "tips"
        private const val KEY_HOURS = "hours"
        private const val KEY_SALES = "sales"
        private const val KEY_PERIOD = "period"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
            if (appWidgetIds != null) {
                onUpdate(context, AppWidgetManager.getInstance(context), appWidgetIds)
            } else {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    android.content.ComponentName(context, DashboardWidgetProvider::class.java)
                )
                onUpdate(context, manager, ids)
            }
        }
    }

    override fun onEnabled(context: Context) {
        // Widget enabled
    }

    override fun onDisabled(context: Context) {
        // Widget disabled
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_dashboard)

        // Set click intent to open app
        val intent = Intent(context, com.protip365.app.presentation.MainActivity::class.java)
        intent.action = Intent.ACTION_VIEW
        intent.data = android.net.Uri.parse("protip365://dashboard")
        val pendingIntent = android.app.PendingIntent.getActivity(
            context,
            0,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

        // Load cached dashboard data from SharedPreferences
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val formatter = NumberFormat.getCurrencyInstance(Locale.getDefault())
        
        val totalRevenue = prefs.getFloat(KEY_TOTAL_REVENUE, 0f).toDouble()
        val tips = prefs.getFloat(KEY_TIPS, 0f).toDouble()
        val hours = prefs.getFloat(KEY_HOURS, 0f).toDouble()
        val sales = prefs.getFloat(KEY_SALES, 0f).toDouble()
        val period = prefs.getString(KEY_PERIOD, "This Week") ?: "This Week"

        views.setTextViewText(
            R.id.widget_total_revenue_value,
            formatter.format(totalRevenue)
        )
        views.setTextViewText(
            R.id.widget_tips_value,
            formatter.format(tips)
        )
        views.setTextViewText(
            R.id.widget_hours_value,
            String.format("%.1f", hours)
        )
        views.setTextViewText(
            R.id.widget_sales_value,
            formatter.format(sales)
        )
        views.setTextViewText(
            R.id.widget_period,
            period
        )
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * Helper method to update widget data from app
     * Called by DashboardViewModel when data changes
     */
    fun updateWidgetData(
        context: Context,
        totalRevenue: Double,
        tips: Double,
        hours: Double,
        sales: Double,
        period: String = "This Week"
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putFloat(KEY_TOTAL_REVENUE, totalRevenue.toFloat())
            .putFloat(KEY_TIPS, tips.toFloat())
            .putFloat(KEY_HOURS, hours.toFloat())
            .putFloat(KEY_SALES, sales.toFloat())
            .putString(KEY_PERIOD, period)
            .apply()

        // Trigger widget update
        val intent = Intent(context, DashboardWidgetProvider::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        val ids = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(android.content.ComponentName(context, DashboardWidgetProvider::class.java))
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        context.sendBroadcast(intent)
    }
}

