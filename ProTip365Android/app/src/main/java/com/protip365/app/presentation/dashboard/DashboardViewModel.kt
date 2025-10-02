package com.protip365.app.presentation.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.CompletedShift
import com.protip365.app.domain.repository.CompletedShiftRepository
import com.protip365.app.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.datetime.*
import javax.inject.Inject

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val completedShiftRepository: CompletedShiftRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _dashboardState = MutableStateFlow(DashboardState())
    val dashboardState: StateFlow<DashboardState> = _dashboardState.asStateFlow()

    private val _selectedPeriod = MutableStateFlow(DashboardPeriod.WEEK)
    val selectedPeriod: StateFlow<DashboardPeriod> = _selectedPeriod.asStateFlow()

    private val _monthViewType = MutableStateFlow(MonthViewType.CALENDAR_MONTH)
    val monthViewType: StateFlow<MonthViewType> = _monthViewType.asStateFlow()

    private val _userTargets = MutableStateFlow(DashboardMetrics.UserTargets())
    val userTargets: StateFlow<DashboardMetrics.UserTargets> = _userTargets.asStateFlow()

    private val _currentLanguage = MutableStateFlow("en")
    val currentLanguage: StateFlow<String> = _currentLanguage.asStateFlow()

    private val _hasVariableSchedule = MutableStateFlow(false)
    val hasVariableSchedule: StateFlow<Boolean> = _hasVariableSchedule.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Store stats for all periods to enable quick switching
    private val _todayStats = MutableStateFlow(DashboardMetrics.Stats())
    private val _weekStats = MutableStateFlow(DashboardMetrics.Stats())
    private val _monthStats = MutableStateFlow(DashboardMetrics.Stats())
    private val _yearStats = MutableStateFlow(DashboardMetrics.Stats())
    private val _fourWeeksStats = MutableStateFlow(DashboardMetrics.Stats())

    private var averageDeductionPercentage: Double = 30.0
    private var defaultHourlyRate: Double = 15.0
    private var weekStartDay: Int = 0  // 0=Sunday, 1=Monday, etc.

    init {
        loadUserPreferences()
        loadDashboardData()
    }

    private fun loadUserPreferences() {
        viewModelScope.launch {
            userRepository.getCurrentUser().collect { userProfile ->
                userProfile?.let { profile ->
                    defaultHourlyRate = profile.defaultHourlyRate ?: 15.0
                    averageDeductionPercentage = profile.averageDeductionPercentage
                    weekStartDay = profile.weekStart ?: 0

                    _userTargets.value = DashboardMetrics.UserTargets(
                        tipTargetPercentage = profile.tipTargetPercentage ?: 20.0,
                        dailySales = profile.targetSalesDaily ?: 0.0,
                        weeklySales = profile.targetSalesWeekly ?: 0.0,
                        monthlySales = profile.targetSalesMonthly ?: 0.0,
                        dailyHours = profile.targetHoursDaily ?: 8.0,
                        weeklyHours = profile.targetHoursWeekly ?: 40.0,
                        monthlyHours = profile.targetHoursMonthly ?: 160.0,
                        dailyIncome = 0.0, // Calculate from hours * rate
                        weeklyIncome = 0.0,
                        monthlyIncome = 0.0
                    )

                    _currentLanguage.value = profile.preferredLanguage
                    _hasVariableSchedule.value = profile.hasVariableSchedule
                }
            }
        }
    }

    fun selectPeriod(period: DashboardPeriod) {
        _selectedPeriod.value = period
        updateDashboardStateForPeriod()
    }

    fun setMonthViewType(type: MonthViewType) {
        _monthViewType.value = type
        if (_selectedPeriod.value == DashboardPeriod.MONTH) {
            // Just update the state with the right stats
            updateDashboardStateForPeriod()
        }
    }

    fun refreshData() {
        loadDashboardData()
    }

    private fun loadDashboardData() {
        viewModelScope.launch {
            try {
                _isLoading.value = true

                // Get current user for dashboard data
                val currentUser = userRepository.getCurrentUser().first()
                val userId = currentUser?.userId ?: return@launch

                // Load completed shifts data (combines expected + actual data)
                completedShiftRepository.observeCompletedShifts(userId).collect { allShifts ->
                    println("📊 Dashboard - Loading data for ${allShifts.size} shifts")

                    // Calculate stats for each period
                    calculatePeriodStats(DashboardPeriod.TODAY, allShifts, _todayStats)
                    calculatePeriodStats(DashboardPeriod.WEEK, allShifts, _weekStats)
                    calculatePeriodStats(DashboardPeriod.MONTH, allShifts, _monthStats)
                    calculatePeriodStats(DashboardPeriod.YEAR, allShifts, _yearStats)
                    calculatePeriodStats(DashboardPeriod.FOUR_WEEKS, allShifts, _fourWeeksStats)

                    // Update dashboard state for current period
                    updateDashboardStateForPeriod()

                    _isLoading.value = false

                    // Log current stats for debugging
                    val currentStats = when (_selectedPeriod.value) {
                        DashboardPeriod.TODAY -> _todayStats.value
                        DashboardPeriod.WEEK -> _weekStats.value
                        DashboardPeriod.MONTH -> _monthStats.value
                        DashboardPeriod.YEAR -> _yearStats.value
                        DashboardPeriod.FOUR_WEEKS -> _fourWeeksStats.value
                        DashboardPeriod.CUSTOM -> _monthStats.value
                    }
                    println("📊 Dashboard - ${_selectedPeriod.value} stats: Revenue=$${currentStats.totalRevenue}, Hours=${currentStats.hours}, Tips=$${currentStats.tips}")
                }
            } catch (e: Exception) {
                println("❌ Dashboard - Error loading data: ${e.message}")
                e.printStackTrace()
                _isLoading.value = false
                _dashboardState.value = DashboardState(
                    isLoading = false,
                    error = e.message
                )
            }
        }
    }

    private fun calculatePeriodStats(
        period: DashboardPeriod,
        allShifts: List<com.protip365.app.data.models.CompletedShift>,
        statsFlow: MutableStateFlow<DashboardMetrics.Stats>
    ) {
        val (startDate, endDate) = DashboardMetrics.getDateRangeForPeriod(period, weekStartDay)

        // Filter shifts for this period - include all shifts in range
        val periodShifts = allShifts.filter { shift ->
            val shiftDate = LocalDate.parse(shift.shiftDate)
            shiftDate in startDate..endDate
        }

        println("📊 Dashboard - Calculating ${period.name} stats for ${periodShifts.size} shifts (${periodShifts.count { it.isWorked }} worked)")

        // Calculate stats from CompletedShift data
        val stats = DashboardMetrics.calculateStatsFromCompletedShifts(
            shifts = periodShifts,
            averageDeductionPercentage = averageDeductionPercentage,
            defaultHourlyRate = defaultHourlyRate
        )

        println("📊 Dashboard - ${period.name} calculated: Revenue=$${stats.totalRevenue}, Hours=${stats.hours}")

        statsFlow.value = stats
    }

    private fun updateDashboardStateForPeriod() {
        viewModelScope.launch {
            val currentStats = when (_selectedPeriod.value) {
                DashboardPeriod.TODAY -> _todayStats.value
                DashboardPeriod.WEEK -> _weekStats.value
                DashboardPeriod.MONTH -> {
                    // Check month view type
                    if (_monthViewType.value == MonthViewType.FOUR_WEEKS) {
                        _fourWeeksStats.value
                    } else {
                        _monthStats.value
                    }
                }
                DashboardPeriod.YEAR -> _yearStats.value
                DashboardPeriod.FOUR_WEEKS -> _fourWeeksStats.value
                DashboardPeriod.CUSTOM -> _monthStats.value // Default to month for custom
            }

            // Calculate previous period for comparison
            val prevStats = calculatePreviousPeriodStats()

        _dashboardState.value = DashboardState(
            isLoading = false,
            error = null,

            // Current period values
            totalRevenue = currentStats.totalRevenue,
            totalWages = currentStats.income,
            totalTips = currentStats.tips,
            totalSales = currentStats.sales,
            totalHours = currentStats.hours,
            totalTipOut = currentStats.tipOut,
            otherIncome = currentStats.other,
            averageTipPercentage = currentStats.tipPercentage,
            hourlyRate = if (currentStats.hours > 0) {
                currentStats.totalRevenue / currentStats.hours
            } else defaultHourlyRate,

            // Change percentages
            revenueChange = DashboardMetrics.calculateChangePercentage(
                currentStats.totalRevenue,
                prevStats.totalRevenue
            ),
            wagesChange = DashboardMetrics.calculateChangePercentage(
                currentStats.income,
                prevStats.income
            ),
            tipsChange = DashboardMetrics.calculateChangePercentage(
                currentStats.tips,
                prevStats.tips
            ),
            hoursChange = DashboardMetrics.calculateChangePercentage(
                currentStats.hours,
                prevStats.hours
            ),
            salesChange = DashboardMetrics.calculateChangePercentage(
                currentStats.sales,
                prevStats.sales
            ),
            tipOutChange = DashboardMetrics.calculateChangePercentage(
                currentStats.tipOut,
                prevStats.tipOut
            ),
            otherChange = DashboardMetrics.calculateChangePercentage(
                currentStats.other,
                prevStats.other
            ),

            // Additional data
            recentShifts = currentStats.completedShifts.take(5), // Show 5 most recent
            hasData = currentStats.completedShifts.isNotEmpty()
        )

        println("📊 Dashboard State Updated - Revenue: ${_dashboardState.value.totalRevenue}, Has Data: ${_dashboardState.value.hasData}")
        }
    }

    private suspend fun calculatePreviousPeriodStats(): DashboardMetrics.Stats {
        return try {
            val (prevStart, prevEnd) = DashboardMetrics.getPreviousDateRange(_selectedPeriod.value, weekStartDay)

            // Get current user for dashboard data
            val currentUser = userRepository.getCurrentUser().first()
            val userId = currentUser?.userId ?: return DashboardMetrics.Stats()

            // Fetch previous period shifts
            val previousPeriodShifts = completedShiftRepository.getCompletedShifts(userId, prevStart, prevEnd, false)

            // Calculate stats for previous period
            DashboardMetrics.calculateStatsFromCompletedShifts(
                shifts = previousPeriodShifts,
                averageDeductionPercentage = averageDeductionPercentage,
                defaultHourlyRate = defaultHourlyRate
            )
        } catch (e: Exception) {
            DashboardMetrics.Stats()
        }
    }
}

data class DashboardState(
    val isLoading: Boolean = false,
    val error: String? = null,

    // Main metrics
    val totalRevenue: Double = 0.0,
    val totalWages: Double = 0.0,
    val totalTips: Double = 0.0,
    val totalSales: Double = 0.0,
    val totalHours: Double = 0.0,
    val totalTipOut: Double = 0.0,
    val otherIncome: Double = 0.0,
    val averageTipPercentage: Double = 0.0,
    val hourlyRate: Double = 0.0,

    // Change indicators (percentage change from previous period)
    val revenueChange: Double = 0.0,
    val wagesChange: Double = 0.0,
    val tipsChange: Double = 0.0,
    val hoursChange: Double = 0.0,
    val salesChange: Double = 0.0,
    val tipOutChange: Double = 0.0,
    val otherChange: Double = 0.0,

    // Additional data
    val recentShifts: List<CompletedShift> = emptyList(),
    val hasData: Boolean = false
)

// Use the data classes from DashboardMetrics to avoid duplication