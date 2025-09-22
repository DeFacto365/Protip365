package com.protip365.app.presentation.alerts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Alert
import com.protip365.app.domain.repository.AlertRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AlertsViewModel @Inject constructor(
    private val alertRepository: AlertRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AlertsUiState())
    val uiState: StateFlow<AlertsUiState> = _uiState.asStateFlow()

    val alerts = alertRepository.getAlerts()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    private val _unreadCount = MutableStateFlow(0)
    val unreadCount: StateFlow<Int> = _unreadCount.asStateFlow()

    init {
        loadAlerts()
        checkDailyAlerts()
        updateUnreadCount()
    }

    private fun loadAlerts() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            alerts.collect { alertList ->
                _uiState.update {
                    it.copy(
                        alerts = alertList,
                        isLoading = false
                    )
                }
            }
        }
    }

    private fun updateUnreadCount() {
        viewModelScope.launch {
            alerts.collect { alertList ->
                val count = alertList.count { !it.isRead }
                _unreadCount.value = count
            }
        }
    }

    fun markAsRead(alertId: String) {
        viewModelScope.launch {
            try {
                alertRepository.markAsRead(alertId)
                updateUnreadCount()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = e.message)
                }
            }
        }
    }

    fun markAllAsRead() {
        viewModelScope.launch {
            try {
                alertRepository.markAllAsRead()
                _unreadCount.value = 0
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = e.message)
                }
            }
        }
    }

    fun deleteAlert(alertId: String) {
        viewModelScope.launch {
            try {
                alertRepository.deleteAlert(alertId)
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = e.message)
                }
            }
        }
    }

    fun checkDailyAlerts() {
        viewModelScope.launch {
            try {
                alertRepository.checkAndCreateDailyAlerts()
            } catch (e: Exception) {
                // Silently fail - this is a background operation
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class AlertsUiState(
    val alerts: List<Alert> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)