package com.protip365.app.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.data.models.UserProfile
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.ShiftRepository
import com.protip365.app.domain.repository.SubscriptionRepository
import com.protip365.app.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository,
    private val shiftRepository: ShiftRepository,
    private val subscriptionRepository: SubscriptionRepository,
    private val preferencesManager: PreferencesManager
) : ViewModel() {

    private val _state = MutableStateFlow(SettingsState())
    val state: StateFlow<SettingsState> = _state.asStateFlow()

    private val _user = MutableStateFlow<UserProfile?>(null)
    val user: StateFlow<UserProfile?> = _user.asStateFlow()

    // Track original values to detect changes
    private var originalState: SettingsState? = null

    init {
        loadUserSettings()
        observeConnectivity()
    }

    private fun observeConnectivity() {
        // In a real app, observe network connectivity
        // and sync settings when connection is restored
    }

    private fun loadUserSettings() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true)

            try {
                // Load from local cache first for immediate UI update
                loadFromCache()

                // Then sync with server
                syncWithServer()

            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = "Failed to load settings: ${e.message}"
                )
            }
        }
    }

    private suspend fun loadFromCache() {
        val cachedSettings = preferencesManager.getSettings()
        cachedSettings?.let { settings ->
            _state.value = settings.copy(isLoading = true)
            originalState = settings
        }
    }

    private suspend fun syncWithServer() {
        val currentUser = authRepository.getCurrentUser()
        currentUser?.let { user ->
            _user.value = user

            // Load subscription info
            val subscription = subscriptionRepository.getCurrentSubscription(user.userId)

            val serverState = SettingsState(
                // Targets
                dailyTarget = user.metadata?.get("daily_target") as? Double ?: 200.0,
                weeklyTarget = user.metadata?.get("weekly_target") as? Double ?: 1400.0,
                monthlyTarget = user.metadata?.get("monthly_target") as? Double ?: 6000.0,
                yearlyTarget = user.metadata?.get("yearly_target") as? Double ?: 72000.0,

                // Work defaults
                defaultHourlyRate = user.defaultHourlyRate ?: 15.0,
                useMultipleEmployers = user.useMultipleEmployers,
                weekStartsMonday = user.metadata?.get("week_starts_monday") as? Boolean ?: false,
                defaultTipPercentage = user.metadata?.get("default_tip_percentage") as? Double ?: 20.0,

                // Features
                trackCashOut = user.metadata?.get("track_cash_out") as? Boolean ?: true,
                trackOtherIncome = user.metadata?.get("track_other_income") as? Boolean ?: false,
                enableNotifications = user.metadata?.get("enable_notifications") as? Boolean ?: true,
                reminderTime = user.metadata?.get("reminder_time") as? String ?: "20:00",

                // Security
                biometricEnabled = preferencesManager.isBiometricEnabled(),
                pinEnabled = preferencesManager.isPinEnabled(),
                autoLockMinutes = preferencesManager.getAutoLockMinutes(),

                // Display
                language = user.preferredLanguage ?: "en",
                currency = user.metadata?.get("currency") as? String ?: "USD",
                dateFormat = user.metadata?.get("date_format") as? String ?: "MM/dd/yyyy",
                darkMode = preferencesManager.isDarkMode(),

                // Subscription
                subscriptionTier = subscription?.productId?.let {
                    when {
                        it.contains("parttime") -> "parttime"
                        it.contains("full") -> "full"
                        else -> "free"
                    }
                } ?: "free",
                subscriptionActive = subscription?.status == "active",

                isLoading = false
            )

            _state.value = serverState
            originalState = serverState

            // Cache the settings locally
            preferencesManager.saveSettings(serverState)
        }
    }

    fun updateDailyTarget(target: Double) {
        updateField { it.copy(dailyTarget = target) }
    }

    fun updateWeeklyTarget(target: Double) {
        updateField { it.copy(weeklyTarget = target) }
    }

    fun updateMonthlyTarget(target: Double) {
        updateField { it.copy(monthlyTarget = target) }
    }

    fun updateYearlyTarget(target: Double) {
        updateField { it.copy(yearlyTarget = target) }
    }

    fun updateDefaultHourlyRate(rate: Double) {
        updateField { it.copy(defaultHourlyRate = rate) }
    }

    fun updateAverageDeductionPercentage(percentage: Double) {
        updateField { it.copy(averageDeductionPercentage = percentage) }
    }

    fun updateDefaultTipPercentage(percentage: Double) {
        updateField { it.copy(defaultTipPercentage = percentage) }
    }

    fun updateUseMultipleEmployers(useMultiple: Boolean) {
        updateField { it.copy(useMultipleEmployers = useMultiple) }
    }

    fun updateHasVariableSchedule(hasVariable: Boolean) {
        updateField { it.copy(hasVariableSchedule = hasVariable) }
    }

    fun updateWeekStartDay(weekStart: Int) {
        updateField { it.copy(weekStartDay = weekStart) }
    }

    fun toggleMultipleEmployers() {
        updateField { it.copy(useMultipleEmployers = !it.useMultipleEmployers) }
    }

    fun toggleWeekStartsMonday() {
        updateField { it.copy(weekStartsMonday = !it.weekStartsMonday) }
    }

    fun toggleCashOutTracking() {
        updateField { it.copy(trackCashOut = !it.trackCashOut) }
    }

    fun toggleOtherIncomeTracking() {
        updateField { it.copy(trackOtherIncome = !it.trackOtherIncome) }
    }

    fun toggleNotifications() {
        updateField { it.copy(enableNotifications = !it.enableNotifications) }
    }

    fun updateReminderTime(time: String) {
        updateField { it.copy(reminderTime = time) }
    }

    fun toggleBiometric() {
        updateField { it.copy(biometricEnabled = !it.biometricEnabled) }
    }

    fun togglePin() {
        updateField { it.copy(pinEnabled = !it.pinEnabled) }
    }

    fun updateAutoLockMinutes(minutes: Int) {
        updateField { it.copy(autoLockMinutes = minutes) }
    }

    fun updateLanguage(language: String) {
        updateField { it.copy(language = language) }
        preferencesManager.setLanguage(language)
    }

    fun updateCurrency(currency: String) {
        updateField { it.copy(currency = currency) }
    }

    fun updateDateFormat(format: String) {
        updateField { it.copy(dateFormat = format) }
    }

    fun toggleDarkMode() {
        updateField { it.copy(darkMode = !it.darkMode) }
        preferencesManager.setDarkMode(!_state.value.darkMode)
    }

    private fun updateField(update: (SettingsState) -> SettingsState) {
        _state.value = update(_state.value).copy(hasChanges = true)
    }

    fun hasChanges(): Boolean {
        return originalState?.let { original ->
            _state.value != original
        } ?: false
    }

    fun saveSettings() {
        if (!hasChanges()) return

        viewModelScope.launch {
            _state.value = _state.value.copy(
                isSaving = true,
                error = null
            )

            try {
                // Show confirmation dialog for critical changes
                if (shouldShowConfirmation()) {
                    _state.value = _state.value.copy(
                        showConfirmDialog = true,
                        confirmDialogMessage = getConfirmationMessage()
                    )
                    return@launch
                }

                performSave()

            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isSaving = false,
                    error = "Failed to save settings: ${e.message}"
                )
            }
        }
    }

    fun confirmSave() {
        viewModelScope.launch {
            _state.value = _state.value.copy(showConfirmDialog = false)
            performSave()
        }
    }

    fun cancelSave() {
        _state.value = _state.value.copy(showConfirmDialog = false)
    }

    private suspend fun performSave() {
        val currentState = _state.value

        // Save to local cache immediately
        preferencesManager.saveSettings(currentState)

        // Update user profile in database
        _user.value?.let { user ->
            val updates = mutableMapOf<String, Any?>()

            // Basic settings
            updates["default_hourly_rate"] = currentState.defaultHourlyRate
            updates["use_multiple_employers"] = currentState.useMultipleEmployers
            updates["preferred_language"] = currentState.language

            // Metadata updates
            val metadata = mutableMapOf<String, Any?>()
            metadata["daily_target"] = currentState.dailyTarget
            metadata["weekly_target"] = currentState.weeklyTarget
            metadata["monthly_target"] = currentState.monthlyTarget
            metadata["yearly_target"] = currentState.yearlyTarget
            metadata["week_starts_monday"] = currentState.weekStartsMonday
            metadata["default_tip_percentage"] = currentState.defaultTipPercentage
            metadata["track_cash_out"] = currentState.trackCashOut
            metadata["track_other_income"] = currentState.trackOtherIncome
            metadata["enable_notifications"] = currentState.enableNotifications
            metadata["reminder_time"] = currentState.reminderTime
            metadata["currency"] = currentState.currency
            metadata["date_format"] = currentState.dateFormat

            userRepository.updateUserProfile(updates)
            userRepository.updateUserMetadata(metadata)

            // Save security settings locally
            if (currentState.biometricEnabled != originalState?.biometricEnabled) {
                if (currentState.biometricEnabled) {
                    preferencesManager.enableBiometric()
                } else {
                    preferencesManager.disableBiometric()
                }
            }

            if (currentState.autoLockMinutes != originalState?.autoLockMinutes) {
                preferencesManager.setAutoLockMinutes(currentState.autoLockMinutes)
            }

            // Update original state after successful save
            originalState = currentState

            // Show success feedback
            _state.value = _state.value.copy(
                isSaving = false,
                hasChanges = false,
                saveSuccess = true
            )

            // Clear success message after delay
            delay(2000)
            _state.value = _state.value.copy(saveSuccess = false)
        }
    }

    fun cancelChanges() {
        originalState?.let { original ->
            _state.value = original.copy(hasChanges = false)
        }
    }

    private fun shouldShowConfirmation(): Boolean {
        val original = originalState ?: return false
        val current = _state.value

        // Show confirmation for critical changes
        return current.useMultipleEmployers != original.useMultipleEmployers ||
               current.weekStartsMonday != original.weekStartsMonday ||
               current.language != original.language
    }

    private fun getConfirmationMessage(): String {
        val changes = mutableListOf<String>()
        val original = originalState ?: return "Save changes?"
        val current = _state.value

        if (current.useMultipleEmployers != original.useMultipleEmployers) {
            changes.add(if (current.useMultipleEmployers)
                "Enable multiple employers" else "Disable multiple employers")
        }
        if (current.weekStartsMonday != original.weekStartsMonday) {
            changes.add("Change week start day")
        }
        if (current.language != original.language) {
            changes.add("Change language to ${current.language.uppercase()}")
        }

        return "The following changes will be applied:\n${changes.joinToString("\n")}"
    }

    fun exportData(format: ExportFormat = ExportFormat.CSV) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isExporting = true)

            val user = _user.value ?: return@launch

            try {
                // Get all data
                val shifts = shiftRepository.getShifts(user.userId)
                val entries = shiftRepository.getEntries(user.userId)

                val content = when (format) {
                    ExportFormat.CSV -> generateCSV(shifts, entries)
                    ExportFormat.PDF -> generatePDF(shifts, entries)
                    ExportFormat.JSON -> generateJSON(shifts, entries)
                }

                val dateFormat = SimpleDateFormat("yyyy-MM-dd-HHmmss", Locale.US)
                val fileName = "protip365_export_${dateFormat.format(Date())}.${format.extension}"

                // In a real app, use proper file storage and sharing
                _state.value = _state.value.copy(
                    isExporting = false,
                    exportSuccess = true,
                    exportedFileName = fileName
                )

                // Clear success message after delay
                delay(3000)
                _state.value = _state.value.copy(
                    exportSuccess = false,
                    exportedFileName = null
                )

            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isExporting = false,
                    error = "Export failed: ${e.message}"
                )
            }
        }
    }

    private fun generateCSV(shifts: List<Any>, entries: List<Any>): String {
        // Implementation for CSV generation
        val csv = StringBuilder()
        csv.append("Date,Type,Hours,Sales,Tips,Total\n")
        // Add data rows...
        return csv.toString()
    }

    private fun generatePDF(shifts: List<Any>, entries: List<Any>): ByteArray {
        // Implementation for PDF generation
        return ByteArray(0)
    }

    private fun generateJSON(shifts: List<Any>, entries: List<Any>): String {
        // Implementation for JSON generation
        return "{}"
    }

    fun signOut() {
        viewModelScope.launch {
            _state.value = _state.value.copy(showSignOutDialog = true)
        }
    }

    fun confirmSignOut() {
        viewModelScope.launch {
            _state.value = _state.value.copy(showSignOutDialog = false)
            authRepository.signOut()
            preferencesManager.clearAll()
        }
    }

    fun cancelSignOut() {
        _state.value = _state.value.copy(showSignOutDialog = false)
    }

    fun deleteAccount() {
        _state.value = _state.value.copy(showDeleteAccountDialog = true)
    }

    fun confirmDeleteAccount(confirmationText: String) {
        if (confirmationText != "DELETE") {
            _state.value = _state.value.copy(
                deleteAccountError = "Please type DELETE to confirm"
            )
            return
        }

        viewModelScope.launch {
            _state.value = _state.value.copy(
                isDeleting = true,
                showDeleteAccountDialog = false
            )

            try {
                authRepository.deleteAccount()
                preferencesManager.clearAll()
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isDeleting = false,
                    error = "Failed to delete account: ${e.message}"
                )
            }
        }
    }

    fun cancelDeleteAccount() {
        _state.value = _state.value.copy(
            showDeleteAccountDialog = false,
            deleteAccountError = null
        )
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}

data class SettingsState(
    // Loading states
    val isLoading: Boolean = true,
    val isSaving: Boolean = false,
    val isExporting: Boolean = false,
    val isDeleting: Boolean = false,

    // Change tracking
    val hasChanges: Boolean = false,
    val saveSuccess: Boolean = false,

    // Targets
    val dailyTarget: Double = 200.0,
    val weeklyTarget: Double = 1400.0,
    val monthlyTarget: Double = 6000.0,
    val yearlyTarget: Double = 72000.0,

    // Work defaults
    val defaultHourlyRate: Double = 15.0,
    val averageDeductionPercentage: Double = 30.0,
    val defaultTipPercentage: Double = 20.0,
    val useMultipleEmployers: Boolean = false,
    val hasVariableSchedule: Boolean = false,
    val weekStartDay: Int = 1, // 0 = Sunday, 1 = Monday, etc.
    val weekStartsMonday: Boolean = false,

    // Features
    val trackCashOut: Boolean = true,
    val trackOtherIncome: Boolean = false,
    val enableNotifications: Boolean = true,
    val reminderTime: String = "20:00",

    // Security
    val biometricEnabled: Boolean = false,
    val pinEnabled: Boolean = false,
    val autoLockMinutes: Int = 5,

    // Display
    val language: String = "en",
    val currency: String = "USD",
    val dateFormat: String = "MM/dd/yyyy",
    val darkMode: Boolean = false,

    // Subscription
    val subscriptionTier: String = "free",
    val subscriptionActive: Boolean = false,

    // Export
    val exportSuccess: Boolean = false,
    val exportedFileName: String? = null,

    // Dialogs
    val showConfirmDialog: Boolean = false,
    val confirmDialogMessage: String = "",
    val showSignOutDialog: Boolean = false,
    val showDeleteAccountDialog: Boolean = false,
    val deleteAccountError: String? = null,

    // Errors
    val error: String? = null
)

enum class ExportFormat(val extension: String) {
    CSV("csv"),
    PDF("pdf"),
    JSON("json")
}