package com.protip365.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.protip365.app.R
import java.text.NumberFormat
import java.util.Locale

/**
 * Implementation of App Widget functionality.
 */
class ShiftWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    // Construct the RemoteViews object
    val views = RemoteViews(context.packageName, R.layout.widget_shift_summary)
    
    // MOCK DATA for now (Real data would pull from DataStore/Room)
    // To make this dynamic, we'd need to inject a use case or read shared prefs
    val earnings = 450.0 // Placeholder
    val format = NumberFormat.getCurrencyInstance(Locale.US)
    val formattedEarnings = format.format(earnings)
    
    views.setTextViewText(R.id.appwidget_text, formattedEarnings)
    views.setTextViewText(R.id.appwidget_subtitle, "This Week")

    // Instruct the widget manager to update the widget
    appWidgetManager.updateAppWidget(appWidgetId, views)
}
