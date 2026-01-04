package com.protip365.app.presentation.alerts

import android.content.Context
import android.content.Intent
import dagger.hilt.android.qualifiers.ApplicationContext
import com.protip365.app.MainActivity
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.data.models.Alert
import com.protip365.app.data.models.AlertType
import com.protip365.app.data.models.CompletedShift
import com.protip365.app.data.models.ExpectedShift
import com.protip365.app.domain.repository.AlertRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.datetime.*
import kotlinx.datetime.TimeZone
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import java.text.NumberFormat
import java.util.*
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AlertManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val alertRepository: AlertRepository,
    private val preferencesManager: PreferencesManager,
    private val navigationEventManager: com.protip365.app.presentation.navigation.NavigationEventManager,
    private val notificationManager: com.protip365.app.presentation.notifications.ProTipNotificationManager
) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private val _alerts = MutableStateFlow<List<Alert>>(emptyList())
    val alerts: StateFlow<List<Alert>> = _alerts.asStateFlow()

    private val _hasUnreadAlerts = MutableStateFlow(false)
    val hasUnreadAlerts: StateFlow<Boolean> = _hasUnreadAlerts.asStateFlow()

    private val _unreadCount = MutableStateFlow(0)
    val unreadCount: StateFlow<Int> = _unreadCount.asStateFlow()

    private val _showAlert = MutableStateFlow(false)
    val showAlert: StateFlow<Boolean> = _showAlert.asStateFlow()

    private val _currentAlert = MutableStateFlow<Alert?>(null)
    val currentAlert: StateFlow<Alert?> = _currentAlert.asStateFlow()

    init {
        loadAlertsFromDatabase()
    }

    fun loadAlertsFromDatabase() {
        scope.launch {
            alertRepository.getUnreadAlerts().collect { fetchedAlerts ->
                _alerts.value = fetchedAlerts
                updateUnreadStatus()
            }
        }
    }

    private fun updateUnreadStatus() {
        val unreadAlerts = _alerts.value.filter { !it.isRead }
        _hasUnreadAlerts.value = unreadAlerts.isNotEmpty()
        _unreadCount.value = unreadAlerts.size
    }

    fun checkForMissingShiftEntries(shifts: List<CompletedShift>) {
        scope.launch {
            val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
            val yesterday = today.minus(DatePeriod(days = 1))

            val yesterdayPlannedShifts = shifts.filter { shift ->
                shift.shiftDate == yesterday.toString() &&
                shift.expectedShift.status == "planned" &&
                !shift.isWorked
            }

            if (yesterdayPlannedShifts.isNotEmpty()) {
                for (shift in yesterdayPlannedShifts) {
                    val shiftData = JsonObject(mapOf(
                        "shiftId" to JsonPrimitive(shift.expectedShift.id)
                    ))

                    createAlert(
                        alertType = AlertType.INCOMPLETE_SHIFT.value,
                        title = getLocalizedString("incompleteShiftTitle"),
                        message = getLocalizedString("incompleteShiftMessage"),
                        action = getLocalizedString("addEntry"),
                        data = shiftData
                    )

                    // Show enhanced notification with Android 16 features
                    val alertType = AlertType.fromValue(AlertType.INCOMPLETE_SHIFT.value) ?: AlertType.INCOMPLETE_SHIFT
                    notificationManager.showNotification(
                        alertType = alertType,
                        title = getLocalizedString("incompleteShiftTitle"),
                        message = getLocalizedString("incompleteShiftMessage"),
                        data = mapOf("shiftId" to shift.expectedShift.id, "date" to shift.shiftDate)
                    )
                }
            }
        }
    }

    fun checkForMissingShifts(shifts: List<CompletedShift>) {
        scope.launch {
            val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
            val yesterday = today.minus(DatePeriod(days = 1))

            val yesterdayShifts = shifts.filter { it.shiftDate == yesterday.toString() }

            if (yesterdayShifts.isEmpty()) {
                createAlert(
                    alertType = AlertType.MISSING_SHIFT.value,
                    title = getLocalizedString("missingShiftTitle"),
                    message = getLocalizedString("missingShiftMessage"),
                    action = getLocalizedString("enterData")
                )
                
                // Show enhanced notification
                notificationManager.showNotification(
                    alertType = AlertType.MISSING_SHIFT,
                    title = getLocalizedString("missingShiftTitle"),
                    message = getLocalizedString("missingShiftMessage"),
                    data = null
                )
            }
        }
    }

    fun addShiftReminderAlert(shiftId: UUID, employerName: String, startTime: Instant) {
        scope.launch {
            val localDateTime = startTime.toLocalDateTime(TimeZone.currentSystemDefault())
            val timeString = String.format("%02d:%02d", localDateTime.hour, localDateTime.minute)

            val title = getLocalizedString("upcomingShiftTitle")
            val message = String.format(
                getLocalizedString("upcomingShiftMessage"),
                employerName,
                timeString
            )

            val alertData = JsonObject(mapOf(
                "shiftId" to JsonPrimitive(shiftId.toString()),
                "employerName" to JsonPrimitive(employerName),
                "startTime" to JsonPrimitive(startTime.toEpochMilliseconds())
            ))

            createAlert(
                alertType = AlertType.SHIFT_REMINDER.value,
                title = title,
                message = message,
                action = getLocalizedString("viewShift"),
                data = alertData
            )
            
            // Show enhanced notification with Live Updates support
            notificationManager.showNotification(
                alertType = AlertType.SHIFT_REMINDER,
                title = title,
                message = message,
                data = mapOf(
                    "shiftId" to shiftId.toString(),
                    "employerName" to employerName,
                    "startTime" to startTime.toEpochMilliseconds()
                )
            )
        }
    }

    fun checkForTargetAchievements(
        tips: Double,
        sales: Double,
        tipTargetPercentage: Double
    ) {
        scope.launch {
            if (tipTargetPercentage > 0 && sales > 0) {
                val tipTarget = sales * (tipTargetPercentage / 100.0)
                if (tips >= tipTarget) {
                    val message = "${getLocalizedString("tipTargetAchievedMessage")} ${formatCurrency(tipTarget)}"
                    createAlert(
                        alertType = AlertType.TARGET_ACHIEVED.value,
                        title = getLocalizedString("tipTargetAchievedTitle"),
                        message = message,
                        action = getLocalizedString("viewDetails")
                    )
                    
                    // Show enhanced notification
                    notificationManager.showNotification(
                        alertType = AlertType.TARGET_ACHIEVED,
                        title = getLocalizedString("tipTargetAchievedTitle"),
                        message = message,
                        data = null
                    )
                }
            }
        }
    }

    suspend fun clearAlert(alert: Alert) {
        alertRepository.deleteAlert(alert.id)
        loadAlertsFromDatabase()
    }

    suspend fun clearAllAlerts() {
        _alerts.value.forEach { alert ->
            alertRepository.deleteAlert(alert.id)
        }
        loadAlertsFromDatabase()
    }

    private suspend fun createAlert(
        alertType: String,
        title: String,
        message: String,
        action: String? = null,
        data: JsonObject? = null
    ) {
        val userId = preferencesManager.getUserId() ?: return

        val alert = Alert(
            userId = userId,
            alertType = alertType,
            title = title,
            message = message,
            action = action,
            data = data,
            createdAt = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).toString()
        )

        alertRepository.createAlert(alert)
        loadAlertsFromDatabase()

        // Show the newest alert
        _currentAlert.value = alert
        _showAlert.value = true
        
        // Show enhanced notification for newly created alerts (if not already shown above)
        // Only show notification if it's a type that should trigger a notification
        val alertTypeEnum = AlertType.fromValue(alertType)
        if (alertTypeEnum != null && shouldShowNotification(alertTypeEnum)) {
            notificationManager.showNotification(
                alertType = alertTypeEnum,
                title = title,
                message = message,
                data = data?.let { jsonObject ->
                    jsonObject.entries.associate { (key, value) ->
                        key to when (value) {
                            is JsonPrimitive -> {
                                when {
                                    value.isString -> value.content
                                    value.booleanOrNull != null -> value.booleanOrNull!!
                                    value.doubleOrNull != null -> value.doubleOrNull!!
                                    else -> value.content
                                }
                            }
                            else -> value.toString()
                        }
                    }
                }
            )
        }
    }
    
    /**
     * Determines if an alert type should trigger a notification
     */
    private fun shouldShowNotification(alertType: AlertType): Boolean {
        return when (alertType) {
            AlertType.MISSING_SHIFT,
            AlertType.INCOMPLETE_SHIFT,
            AlertType.SHIFT_REMINDER,
            AlertType.TARGET_ACHIEVED,
            AlertType.ACHIEVEMENT_UNLOCKED,
            AlertType.PERSONAL_BEST -> true
            else -> false
        }
    }

    fun refreshAlerts() {
        loadAlertsFromDatabase()
    }

    // Test Alert Methods (for debugging)
    fun addTestAlert() {
        scope.launch {
            createAlert(
                alertType = AlertType.REMINDER.value,
                title = "Test Alert",
                message = "This is a test alert to verify the bell icon is working.",
                action = "Dismiss"
            )
        }
    }

    fun addTestShiftAlert() {
        val testShiftId = UUID.randomUUID()
        val testStartTime = Clock.System.now().plus(30, DateTimeUnit.MINUTE, TimeZone.currentSystemDefault())

        scope.launch {
            val alertData = JsonObject(mapOf(
                "shiftId" to JsonPrimitive(testShiftId.toString()),
                "employerName" to JsonPrimitive("Test Restaurant"),
                "startTime" to JsonPrimitive(testStartTime.toEpochMilliseconds())
            ))

            createAlert(
                alertType = AlertType.SHIFT_REMINDER.value,
                title = getLocalizedString("upcomingShiftTitle"),
                message = String.format(
                    getLocalizedString("upcomingShiftMessage"),
                    "Test Restaurant",
                    "2:30 PM"
                ),
                action = getLocalizedString("viewShift"),
                data = alertData
            )
        }
    }

    // Shift alert scheduling methods for new database structure
    fun scheduleShiftAlert(
        shiftId: UUID,
        shiftDate: LocalDate,
        startTime: LocalTime,
        employerName: String,
        alertMinutes: Int
    ) {
        scope.launch {
            val shiftDateTime = shiftDate.atTime(startTime)
            val alertDateTime = shiftDateTime.toInstant(TimeZone.currentSystemDefault())
                .minus(alertMinutes, DateTimeUnit.MINUTE, TimeZone.currentSystemDefault())

            // Only schedule if alert time is in the future
            if (alertDateTime > Clock.System.now()) {
                val timeString = String.format("%02d:%02d", startTime.hour, startTime.minute)

                val alertData = JsonObject(mapOf(
                    "shiftId" to JsonPrimitive(shiftId.toString()),
                    "employerName" to JsonPrimitive(employerName),
                    "startTime" to JsonPrimitive(alertDateTime.toEpochMilliseconds())
                ))

                val title = getLocalizedString("upcomingShiftTitle")
                val message = String.format(
                    getLocalizedString("upcomingShiftMessage"),
                    employerName,
                    timeString
                )
                
                createAlert(
                    alertType = AlertType.SHIFT_REMINDER.value,
                    title = title,
                    message = message,
                    action = getLocalizedString("viewShift"),
                    data = alertData
                )
                
                // Show enhanced notification with Live Updates support
                notificationManager.showNotification(
                    alertType = AlertType.SHIFT_REMINDER,
                    title = title,
                    message = message,
                    data = mapOf(
                        "shiftId" to shiftId.toString(),
                        "employerName" to employerName,
                        "startTime" to alertDateTime.toEpochMilliseconds()
                    )
                )
            }
        }
    }

    fun updateShiftAlert(
        shiftId: UUID,
        shiftDate: LocalDate,
        startTime: LocalTime,
        employerName: String,
        alertMinutes: Int
    ) {
        scope.launch {
            // Cancel existing alert first
            cancelShiftAlert(shiftId)
            // Schedule new alert
            scheduleShiftAlert(shiftId, shiftDate, startTime, employerName, alertMinutes)
        }
    }

    fun cancelShiftAlert(shiftId: UUID) {
        scope.launch {
            // Remove any existing alerts for this shift
            _alerts.value
                .filter { alert ->
                    alert.alertType == AlertType.SHIFT_REMINDER.value &&
                    alert.getShiftId() == shiftId.toString()
                }
                .forEach { alert ->
                    alertRepository.deleteAlert(alert.id)
                }
            loadAlertsFromDatabase()
        }
    }

    fun checkYesterdayShifts(shifts: List<CompletedShift>) {
        scope.launch {
            checkForMissingShiftEntries(shifts)
        }
    }


    private fun formatCurrency(amount: Double): String {
        val formatter = NumberFormat.getCurrencyInstance(Locale.getDefault())
        return formatter.format(amount)
    }

    private fun getLocalizedString(key: String): String {
        val language = preferencesManager.getLanguage()
        return when (language) {
            "fr" -> getLocalizedStringFR(key)
            "es" -> getLocalizedStringES(key)
            else -> getLocalizedStringEN(key)
        }
    }

    private fun getLocalizedStringEN(key: String): String {
        return when (key) {
            "missingShiftTitle" -> "Complete Yesterday's Shift"
            "missingShiftMessage" -> "Add earnings data to track your progress"
            "incompleteShiftTitle" -> "Update Shift Data"
            "incompleteShiftMessage" -> "Complete yesterday's shift information"
            "enterData" -> "Add Now"
            "addEntry" -> "Complete"
            "tipTargetAchievedTitle" -> "Target Reached! 🎉"
            "tipTargetAchievedMessage" -> "Congratulations on reaching your goal!"
            "viewDetails" -> "View Details"
            "upcomingShiftTitle" -> "Shift Starting Soon"
            "upcomingShiftMessage" -> "%s shift begins at %s"
            "viewShift" -> "View Shift"
            else -> key
        }
    }

    private fun getLocalizedStringFR(key: String): String {
        return when (key) {
            "missingShiftTitle" -> "Données manquantes"
            "missingShiftMessage" -> "Vous aviez un quart hier."
            "incompleteShiftTitle" -> "Ajouter l'entrée d'hier"
            "incompleteShiftMessage" -> "N'oubliez pas d'ajouter votre entrée au quart d'hier"
            "enterData" -> "Saisir"
            "addEntry" -> "Ajouter"
            "tipTargetAchievedTitle" -> "🎉 Objectif atteint!"
            "tipTargetAchievedMessage" -> "Objectif de pourboire atteint!"
            "viewDetails" -> "Détails"
            "upcomingShiftTitle" -> "Quart à venir"
            "upcomingShiftMessage" -> "Votre quart chez %s commence à %s"
            "viewShift" -> "Voir le quart"
            else -> key
        }
    }

    private fun getLocalizedStringES(key: String): String {
        return when (key) {
            "missingShiftTitle" -> "Datos faltantes"
            "missingShiftMessage" -> "Tuviste un turno ayer."
            "incompleteShiftTitle" -> "Agregar entrada de ayer"
            "incompleteShiftMessage" -> "No olvides agregar tu entrada al turno de ayer"
            "enterData" -> "Ingresar"
            "addEntry" -> "Agregar"
            "tipTargetAchievedTitle" -> "🎉 ¡Objetivo alcanzado!"
            "tipTargetAchievedMessage" -> "¡Objetivo de propinas alcanzado!"
            "viewDetails" -> "Detalles"
            "upcomingShiftTitle" -> "Turno próximo"
            "upcomingShiftMessage" -> "Su turno en %s comienza a las %s"
            "viewShift" -> "Ver turno"
            else -> key
        }
    }

    /**
     * Handle notification tap for deep linking
     * Extracts shiftId from intent extras and triggers navigation event
     * Matches iOS notification handling pattern
     */
    fun handleNotificationTap(intent: Intent?) {
        scope.launch {
            try {
                val shiftId = intent?.getStringExtra("shiftId")
                val dateString = intent?.getStringExtra("date")

                when {
                    shiftId != null -> {
                        // Navigate to shift editor (with iOS 300ms delay)
                        println("📱 Notification tapped: navigating to shift $shiftId")
                        navigationEventManager.navigateToShift(shiftId, delayMs = 300)
                    }
                    dateString != null -> {
                        // Navigate to calendar with date
                        val date = LocalDate.parse(dateString)
                        println("📱 Notification tapped: navigating to calendar $date")
                        navigationEventManager.navigateToCalendar(date)
                    }
                    else -> {
                        println("⚠️ Notification tapped but no navigation data found")
                    }
                }
            } catch (e: Exception) {
                println("❌ Error handling notification tap: ${e.message}")
                e.printStackTrace()
            }
        }
    }
}

