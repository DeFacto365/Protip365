package com.protip365.app.presentation.detail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.model.ShiftIncome
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.CompletedShiftRepository
import com.protip365.app.presentation.dashboard.DashboardPeriod
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.*
import javax.inject.Inject

data class DetailUiState(
    val isLoading: Boolean = true,
    val shifts: List<ShiftIncome> = emptyList(),
    val periodStart: LocalDate? = null,
    val periodEnd: LocalDate? = null,
    val periodText: String = "",
    val statType: String = "total",
    val error: String? = null
)

@HiltViewModel
class DetailViewModel @Inject constructor(
    private val completedShiftRepository: CompletedShiftRepository,
    private val authRepository: AuthRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(DetailUiState())
    val uiState: StateFlow<DetailUiState> = _uiState.asStateFlow()
    
    fun loadShiftsForPeriod(period: DashboardPeriod, statType: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isLoading = true,
                error = null,
                statType = statType
            )
            
            try {
                val user = authRepository.getCurrentUser() ?: throw Exception("User not authenticated")
                val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
                val (startDate, endDate, periodText) = calculatePeriodDates(now, period)
                
                val completedShifts = completedShiftRepository.getWorkedShifts(
                    userId = user.userId,
                    startDate = startDate,
                    endDate = endDate
                )
                
                val shiftIncomes = ShiftIncome.fromList(completedShifts)
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    shifts = shiftIncomes,
                    periodStart = startDate,
                    periodEnd = endDate,
                    periodText = periodText,
                    error = null
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Unknown error"
                )
            }
        }
    }
    
    fun refreshData() {
        val currentPeriod = when (_uiState.value.periodText.lowercase()) {
            "today" -> DashboardPeriod.TODAY
            "week" -> DashboardPeriod.WEEK
            "month" -> DashboardPeriod.MONTH
            "year" -> DashboardPeriod.YEAR
            else -> DashboardPeriod.TODAY
        }
        loadShiftsForPeriod(currentPeriod, _uiState.value.statType)
    }
    
    private fun calculatePeriodDates(
        today: LocalDate,
        period: DashboardPeriod
    ): Triple<LocalDate, LocalDate, String> {
        return when (period) {
            DashboardPeriod.TODAY -> {
                Triple(today, today, "Today")
            }
            DashboardPeriod.WEEK -> {
                val startOfWeek = today.minus(today.dayOfWeek.ordinal, DateTimeUnit.DAY)
                val endOfWeek = startOfWeek.plus(6, DateTimeUnit.DAY)
                Triple(startOfWeek, endOfWeek, "Week")
            }
            DashboardPeriod.MONTH -> {
                val startOfMonth = LocalDate(today.year, today.month, 1)
                val lastDayOfMonth = today.month.length(today.year % 4 == 0 && (today.year % 100 != 0 || today.year % 400 == 0))
                val endOfMonth = LocalDate(today.year, today.month, lastDayOfMonth)
                Triple(startOfMonth, endOfMonth, "Month")
            }
            DashboardPeriod.YEAR -> {
                val startOfYear = LocalDate(today.year, Month.JANUARY, 1)
                val endOfYear = LocalDate(today.year, Month.DECEMBER, 31)
                Triple(startOfYear, endOfYear, "Year")
            }
            DashboardPeriod.FOUR_WEEKS -> {
                val startDate = today.minus(27, DateTimeUnit.DAY)
                Triple(startDate, today, "Four Weeks")
            }
            DashboardPeriod.CUSTOM -> {
                Triple(today, today, "Custom")
            }
        }
    }
}
