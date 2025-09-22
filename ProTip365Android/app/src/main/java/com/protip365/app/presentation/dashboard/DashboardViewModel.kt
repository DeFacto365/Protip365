package com.protip365.app.presentation.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.domain.repository.ShiftRepository
import com.protip365.app.domain.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.*
import javax.inject.Inject

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val shiftRepository: ShiftRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _dashboardState = MutableStateFlow(DashboardState())
    val dashboardState: StateFlow<DashboardState> = _dashboardState.asStateFlow()

    private val _selectedPeriod = MutableStateFlow(DashboardPeriod.TODAY)
    val selectedPeriod: StateFlow<DashboardPeriod> = _selectedPeriod.asStateFlow()

    private val _monthViewType = MutableStateFlow("grid")
    val monthViewType: StateFlow<String> = _monthViewType.asStateFlow()

    private val _userTargets = MutableStateFlow(UserTargets())
    val userTargets: StateFlow<UserTargets> = _userTargets.asStateFlow()

    private val _currentLanguage = MutableStateFlow("en")
    val currentLanguage: StateFlow<String> = _currentLanguage.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    init {
        loadDashboardData()
    }

    fun selectPeriod(period: DashboardPeriod) {
        _selectedPeriod.value = period
        loadDashboardData()
    }

    fun refreshData() {
        loadDashboardData()
    }

    private fun loadDashboardData() {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                val user = authRepository.getCurrentUser()
                if (user == null) {
                    _isLoading.value = false
                    _dashboardState.value = DashboardState(
                        isLoading = false,
                        error = "Not authenticated"
                    )
                    return@launch
                }
                val userId = user.userId

            val (startDate, endDate) = getDateRangeForPeriod(_selectedPeriod.value)

            // Load shifts and entries for the period
            val shifts = shiftRepository.getShifts(userId, startDate, endDate)
            val entries = shiftRepository.getEntries(userId, startDate, endDate)

            // Calculate totals
            val totalWages = shifts.sumOf { (it.hourlyRate ?: 0.0) * it.hours }
            val totalTips = shifts.sumOf { it.tips } + entries.sumOf { it.tips }
            val totalSales = shifts.sumOf { it.sales } + entries.sumOf { it.sales }
            val totalHours = shifts.sumOf { it.hours }
            val totalTipOut = shifts.sumOf { it.cashOut } + entries.sumOf { it.cashOut }
            val otherIncome = shifts.sumOf { it.other } + entries.sumOf { it.other }
            val totalRevenue = totalWages + totalTips + otherIncome - totalTipOut

            val averageTipPercentage = if (totalSales > 0) {
                (totalTips / totalSales * 100)
            } else 0.0

            val hourlyRate = if (totalHours > 0) {
                totalRevenue / totalHours
            } else 0.0

            // Calculate previous period for comparison
            val (prevStartDate, prevEndDate) = getPreviousDateRange(_selectedPeriod.value)
            val prevShifts = shiftRepository.getShifts(userId, prevStartDate, prevEndDate)
            val prevEntries = shiftRepository.getEntries(userId, prevStartDate, prevEndDate)

            val prevRevenue = prevShifts.sumOf {
                (it.hourlyRate ?: 0.0) * it.hours + it.tips + it.other - it.cashOut
            } + prevEntries.sumOf {
                it.tips + it.other - it.cashOut
            }

            val revenueChange = if (prevRevenue > 0) {
                ((totalRevenue - prevRevenue) / prevRevenue * 100)
            } else 0.0

            _dashboardState.value = DashboardState(
                totalRevenue = totalRevenue,
                totalWages = totalWages,
                totalTips = totalTips,
                totalSales = totalSales,
                totalHours = totalHours,
                totalTipOut = totalTipOut,
                otherIncome = otherIncome,
                averageTipPercentage = averageTipPercentage,
                hourlyRate = hourlyRate,
                revenueChange = revenueChange,
                isLoading = false
            )
            _isLoading.value = false
            } catch (e: Exception) {
                _isLoading.value = false
                _dashboardState.value = DashboardState(
                    isLoading = false,
                    error = e.message ?: "Failed to load data"
                )
            }
        }
    }

    private fun getDateRangeForPeriod(period: DashboardPeriod): Pair<LocalDate, LocalDate> {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        return when (period) {
            DashboardPeriod.TODAY -> today to today
            DashboardPeriod.WEEK -> {
                val startOfWeek = today.minus(today.dayOfWeek.ordinal, DateTimeUnit.DAY)
                startOfWeek to today
            }
            DashboardPeriod.MONTH -> {
                val startOfMonth = LocalDate(today.year, today.month, 1)
                startOfMonth to today
            }
            DashboardPeriod.YEAR -> {
                val startOfYear = LocalDate(today.year, Month.JANUARY, 1)
                startOfYear to today
            }
        }
    }

    private fun getPreviousDateRange(period: DashboardPeriod): Pair<LocalDate, LocalDate> {
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        return when (period) {
            DashboardPeriod.TODAY -> {
                val yesterday = today.minus(1, DateTimeUnit.DAY)
                yesterday to yesterday
            }
            DashboardPeriod.WEEK -> {
                val lastWeek = today.minus(7, DateTimeUnit.DAY)
                val startOfLastWeek = lastWeek.minus(lastWeek.dayOfWeek.ordinal, DateTimeUnit.DAY)
                val endOfLastWeek = startOfLastWeek.plus(6, DateTimeUnit.DAY)
                startOfLastWeek to endOfLastWeek
            }
            DashboardPeriod.MONTH -> {
                val lastMonth = today.minus(1, DateTimeUnit.MONTH)
                val startOfLastMonth = LocalDate(lastMonth.year, lastMonth.month, 1)
                val endOfLastMonth = startOfLastMonth.plus(1, DateTimeUnit.MONTH).minus(1, DateTimeUnit.DAY)
                startOfLastMonth to endOfLastMonth
            }
            DashboardPeriod.YEAR -> {
                val lastYear = today.minus(1, DateTimeUnit.YEAR)
                val startOfLastYear = LocalDate(lastYear.year, Month.JANUARY, 1)
                val endOfLastYear = LocalDate(lastYear.year, Month.DECEMBER, 31)
                startOfLastYear to endOfLastYear
            }
        }
    }
}

data class DashboardState(
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
    val salesChange: Double = 0.0,
    val hoursChange: Double = 0.0,
    val tipOutChange: Double = 0.0,
    val otherChange: Double = 0.0,
    val isLoading: Boolean = true,
    val error: String? = null
)

enum class DashboardPeriod(val label: String) {
    TODAY("Today"),
    WEEK("Week"),
    MONTH("Month"),
    YEAR("Year")
}

