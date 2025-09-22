package com.protip365.app.presentation.alerts

import androidx.compose.runtime.Composable
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton
import java.time.LocalDate
import java.time.temporal.ChronoUnit

@Singleton
class AlertManager @Inject constructor() {
    
    private val _currentAlert = MutableStateFlow<AppAlert?>(null)
    val currentAlert: StateFlow<AppAlert?> = _currentAlert.asStateFlow()
    
    private val _showAlert = MutableStateFlow(false)
    val showAlert: StateFlow<Boolean> = _showAlert.asStateFlow()
    
    private val _alerts = MutableStateFlow<List<AppAlert>>(emptyList())
    val alerts: StateFlow<List<AppAlert>> = _alerts.asStateFlow()
    
    fun checkForMissingShifts(
        shifts: List<com.protip365.app.data.models.Shift>,
        targets: UserTargets
    ) {
        val today = LocalDate.now()
        val alertsList = mutableListOf<AppAlert>()
        
        // Check for missing shifts in the last 7 days
        for (i in 1..7) {
            val checkDate = today.minusDays(i.toLong())
            val hasShiftOnDate = shifts.any { 
                java.time.LocalDate.parse(it.shiftDate) == checkDate 
            }
            
            if (!hasShiftOnDate && shouldHaveShiftOnDate(checkDate, targets)) {
                alertsList.add(
                    AppAlert(
                        id = "missing_shift_${checkDate}",
                        type = AlertType.MISSING_SHIFT,
                        title = "Missing Shift",
                        message = "You haven't logged a shift for ${checkDate}",
                        action = "Add Shift",
                        date = checkDate,
                        isRead = false,
                        createdAt = System.currentTimeMillis()
                    )
                )
            }
        }
        
        // Check for incomplete shifts (shifts without proper data)
        shifts.forEach { shift ->
            if (isIncompleteShift(shift)) {
                alertsList.add(
                    AppAlert(
                        id = "incomplete_shift_${shift.id}",
                        type = AlertType.INCOMPLETE_SHIFT,
                        title = "Incomplete Shift",
                        message = "Your shift on ${java.time.LocalDate.parse(shift.shiftDate)} is missing some information",
                        action = "Complete Shift",
                        date = java.time.LocalDate.parse(shift.shiftDate),
                        isRead = false,
                        createdAt = System.currentTimeMillis()
                    )
                )
            }
        }
        
        _alerts.value = alertsList
    }
    
    fun checkForTargetAchievements(
        currentStats: DashboardStats,
        targets: UserTargets,
        period: Int
    ) {
        val alertsList = _alerts.value.toMutableList()
        
        // Check for tip target achievement
        if (currentStats.totalTips >= targets.tipTargetDaily) {
            alertsList.add(
                AppAlert(
                    id = "tip_target_achieved_${System.currentTimeMillis()}",
                    type = AlertType.TARGET_ACHIEVED,
                    title = "Tip Target Achieved!",
                    message = "Congratulations! You've reached your daily tip target of $${String.format("%.2f", targets.tipTargetDaily)}",
                    action = "View Details",
                    date = LocalDate.now(),
                    isRead = false,
                    createdAt = System.currentTimeMillis()
                )
            )
        }
        
        // Check for sales target achievement
        if (currentStats.totalSales >= targets.salesTargetDaily) {
            alertsList.add(
                AppAlert(
                    id = "sales_target_achieved_${System.currentTimeMillis()}",
                    type = AlertType.TARGET_ACHIEVED,
                    title = "Sales Target Achieved!",
                    message = "Great job! You've reached your daily sales target of $${String.format("%.2f", targets.salesTargetDaily)}",
                    action = "View Details",
                    date = LocalDate.now(),
                    isRead = false,
                    createdAt = System.currentTimeMillis()
                )
            )
        }
        
        // Check for personal best
        if (isPersonalBest(currentStats, period)) {
            alertsList.add(
                AppAlert(
                    id = "personal_best_${System.currentTimeMillis()}",
                    type = AlertType.PERSONAL_BEST,
                    title = "Personal Best!",
                    message = "You've achieved a new personal best for this period!",
                    action = "Celebrate",
                    date = LocalDate.now(),
                    isRead = false,
                    createdAt = System.currentTimeMillis()
                )
            )
        }
        
        _alerts.value = alertsList
    }
    
    fun showAlert(alert: AppAlert) {
        _currentAlert.value = alert
        _showAlert.value = true
    }
    
    fun clearAlert(alert: AppAlert) {
        _currentAlert.value = null
        _showAlert.value = false
        
        // Mark alert as read
        val updatedAlerts = _alerts.value.map { 
            if (it.id == alert.id) it.copy(isRead = true) else it 
        }
        _alerts.value = updatedAlerts
    }
    
    fun dismissAlert() {
        _currentAlert.value = null
        _showAlert.value = false
    }
    
    fun markAlertAsRead(alertId: String) {
        val updatedAlerts = _alerts.value.map { 
            if (it.id == alertId) it.copy(isRead = true) else it 
        }
        _alerts.value = updatedAlerts
    }
    
    fun markAllAlertsAsRead() {
        val updatedAlerts = _alerts.value.map { it.copy(isRead = true) }
        _alerts.value = updatedAlerts
    }
    
    fun deleteAlert(alertId: String) {
        val updatedAlerts = _alerts.value.filter { it.id != alertId }
        _alerts.value = updatedAlerts
    }
    
    fun getUnreadAlertsCount(): Int {
        return _alerts.value.count { !it.isRead }
    }
    
    fun getAlertsByType(type: AlertType): List<AppAlert> {
        return _alerts.value.filter { it.type == type }
    }
    
    fun getRecentAlerts(limit: Int = 10): List<AppAlert> {
        return _alerts.value.sortedByDescending { it.createdAt }.take(limit)
    }
    
    private fun shouldHaveShiftOnDate(date: LocalDate, targets: UserTargets): Boolean {
        // Simple logic: if user has targets set, they should be working regularly
        return targets.tipTargetDaily > 0 || targets.salesTargetDaily > 0 || targets.hoursTargetDaily > 0
    }
    
    private fun isIncompleteShift(shift: com.protip365.app.data.models.Shift): Boolean {
        // Check if shift is missing critical information
        return shift.startTime == null || 
               shift.endTime == null || 
               shift.hours <= 0 ||
               (shift.tips == 0.0 && shift.sales == 0.0)
    }
    
    private fun isPersonalBest(currentStats: DashboardStats, period: Int): Boolean {
        // This would need to compare with historical data
        // For now, return false as we don't have historical data storage
        return false
    }
}

enum class AlertType {
    MISSING_SHIFT,
    INCOMPLETE_SHIFT,
    TARGET_ACHIEVED,
    PERSONAL_BEST,
    REMINDER,
    GENERAL
}

data class AppAlert(
    val id: String,
    val type: AlertType,
    val title: String,
    val message: String,
    val action: String = "",
    val date: LocalDate,
    val isRead: Boolean = false,
    val createdAt: Long
)

data class UserTargets(
    val tipTargetDaily: Double = 0.0,
    val salesTargetDaily: Double = 0.0,
    val hoursTargetDaily: Double = 0.0
)

data class DashboardStats(
    val totalRevenue: Double = 0.0,
    val totalWages: Double = 0.0,
    val totalTips: Double = 0.0,
    val totalSales: Double = 0.0,
    val totalHours: Double = 0.0,
    val totalTipOut: Double = 0.0,
    val otherIncome: Double = 0.0,
    val averageTipPercentage: Double = 0.0,
    val hourlyRate: Double = 0.0,
    val revenueChange: Double = 0.0,
    val wagesChange: Double = 0.0,
    val tipsChange: Double = 0.0,
    val hoursChange: Double = 0.0,
    val salesChange: Double = 0.0,
    val tipOutChange: Double = 0.0,
    val otherChange: Double = 0.0
)