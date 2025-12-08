package com.protip365.app.domain.repository

import com.protip365.app.data.models.Alert
import kotlinx.coroutines.flow.Flow

interface AlertRepository {
    fun getAlerts(): Flow<List<Alert>>
    fun getUnreadAlerts(): Flow<List<Alert>>
    suspend fun getUnreadCount(): Int
    suspend fun markAsRead(alertId: String)
    suspend fun markAllAsRead()
    suspend fun createAlert(alert: Alert)
    suspend fun deleteAlert(alertId: String)
    suspend fun deleteOldAlerts(daysOld: Int = 30)
    suspend fun checkAndCreateDailyAlerts()
}