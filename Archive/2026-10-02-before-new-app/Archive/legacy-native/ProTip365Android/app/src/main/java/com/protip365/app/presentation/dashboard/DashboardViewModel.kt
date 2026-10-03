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
    private val userRepository: UserRepository,
    // AlertManager and AchievementManager (iOS DashboardView.swift line 28-29)
    private val alertManager: com.protip365.app.presentation.alerts.AlertManager,
    private val achievementManager: com.protip365.app.presentation.achievements.AchievementManager
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

    // MARK: - Data Caching (iOS DashboardCharts.swift lines 9-20)
    // Matches iOS 5-minute cache validity for performance optimization
    private var cachedData: Pair<List<CompletedShift>, Long>? = null
    private val CACHE_VALIDITY_MS = 5 * 60 * 1000L // 5 minutes

    private fun isCacheValid(): Boolean {
        val cache = cachedData ?: return false
        return System.currentTimeMillis() - cache.second < CACHE_VALIDITY_MS
    }

    fun invalidateCache() {
        println("📊 Dashboard - Cache invalidated")
        cachedData = null
    }

    // MARK: - Loading Timeout Safeguards (iOS pattern)
    // Prevents infinite loading states
    private var loadingStartTime: Long = 0
    private val LOADING_TIMEOUT_MS = 30_000L // 30 seconds

    private fun startLoadingTimeout() {
        loadingStartTime = System.currentTimeMillis()
        viewModelScope.launch {
            kotlinx.coroutines.delay(LOADING_TIMEOUT_MS)
            if (_isLoading.value) {
                val elapsed = System.currentTimeMillis() - loadingStartTime
                if (elapsed >= LOADING_TIMEOUT_MS) {
                    println("⏰ Dashboard - Loading timeout after ${elapsed}ms")
                    _isLoading.value = false
                    _dashboardState.value = _dashboardState.value.copy(
                        error = "Loading took too long. Please try again."
                    )
                }
            }
        }
    }

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

    /**
     * Force refresh data - invalidates cache and reloads
     * Matches iOS performRefresh() (DashboardView.swift lines 142-170)
     */
    fun refreshData() {
        println("📊 Dashboard - Force refresh requested")
        invalidateCache()
        loadDashboardData(forceRefresh = true)
    }

    /**
     * Refresh data only if cache is stale
     * Matches iOS background refresh pattern (lines 209-215)
     */
    fun refreshDataIfStale() {
        if (!isCacheValid()) {
            println("📊 Dashboard - Cache stale, refreshing...")
            loadDashboardData(forceRefresh = false)
        } else {
            println("📊 Dashboard - Cache still valid, skipping refresh")
        }
    }

    /**
     * Load dashboard data with intelligent caching
     * Matches iOS loadAllStats with cache (DashboardCharts.swift lines 135-260)
     */
    private fun loadDashboardData(forceRefresh: Boolean = false) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                startLoadingTimeout()

                // Get current user for dashboard data
                val currentUser = userRepository.getCurrentUser().first()
                val userId = currentUser?.userId ?: return@launch

                // PERFORMANCE OPTIMIZATION: Use cache if valid and not forcing refresh
                val allShifts: List<CompletedShift>
                if (!forceRefresh && isCacheValid()) {
                    println("📊 Dashboard - Using cached data")
                    allShifts = cachedData!!.first
                } else {
                    println("📊 Dashboard - Loading year data from database...")
                    // Fetch year of data (matching iOS single query optimization)
                    val yearStart = Clock.System.now()
                        .toLocalDateTime(TimeZone.currentSystemDefault())
                        .date.let { LocalDate(it.year, 1, 1) }
                    val today = Clock.System.now()
                        .toLocalDateTime(TimeZone.currentSystemDefault()).date
                    
                    // Single query for entire year like iOS
                    val shifts = completedShiftRepository.getCompletedShifts(
                        userId = userId,
                        startDate = yearStart,
                        endDate = today,
                        includeUnworked = true
                    )
                    
                    // Cache the data
                    cachedData = Pair(shifts, System.currentTimeMillis())
                    allShifts = shifts
                    println("📊 Dashboard - Cached ${allShifts.size} shifts")
                }

                // Calculate stats for each period from the single dataset (memory filtering)
                calculatePeriodStats(DashboardPeriod.TODAY, allShifts, _todayStats)
                calculatePeriodStats(DashboardPeriod.WEEK, allShifts, _weekStats)
                calculatePeriodStats(DashboardPeriod.MONTH, allShifts, _monthStats)
                calculatePeriodStats(DashboardPeriod.YEAR, allShifts, _yearStats)
                calculatePeriodStats(DashboardPeriod.FOUR_WEEKS, allShifts, _fourWeeksStats)

                // Update dashboard state for current period
                updateDashboardStateForPeriod()

                _isLoading.value = false

                // Log refresh status
                if (forceRefresh) {
                    println("📊 Dashboard - Data refreshed successfully")
                    val currentStats = getCurrentStatsForPeriod()
                    println("  Today: ${_todayStats.value.completedShifts.size} shifts")
                    println("  Week: ${_weekStats.value.completedShifts.size} shifts")
                    println("  Month: ${_monthStats.value.completedShifts.size} shifts")
                }

                // Check for achievements and alerts (iOS DashboardView.swift lines 184-198)
                checkAchievementsAndAlerts(getCurrentStatsForPeriod(), allShifts, forceRefresh)
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

        println("📊 Dashboard - Calculating ${period.name} stats for ${periodShifts.size} shifts (${periodShifts.count { it.hasEarnings }} with earnings)")

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
            shifts = currentStats.completedShifts,
            recentShifts = currentStats.completedShifts.take(5), // Show 5 most recent
            allShifts = currentStats.completedShifts, // All shifts for effective sales target calculation
            hasData = currentStats.completedShifts.isNotEmpty()
        )

        println("📊 Dashboard State Updated - Revenue: ${_dashboardState.value.totalRevenue}, Has Data: ${_dashboardState.value.hasData}")
        }
    }

    /**
     * Get current stats based on selected period
     */
    private fun getCurrentStatsForPeriod(): DashboardMetrics.Stats {
        return when (_selectedPeriod.value) {
            DashboardPeriod.TODAY -> _todayStats.value
            DashboardPeriod.WEEK -> _weekStats.value
            DashboardPeriod.MONTH -> {
                if (_monthViewType.value == MonthViewType.FOUR_WEEKS) {
                    _fourWeeksStats.value
                } else {
                    _monthStats.value
                }
            }
            DashboardPeriod.YEAR -> _yearStats.value
            DashboardPeriod.FOUR_WEEKS -> _fourWeeksStats.value
            DashboardPeriod.CUSTOM -> _monthStats.value
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

    /**
     * Check for achievements and alerts after data load
     * Matches iOS performInitialLoad and performRefresh (DashboardView.swift lines 184-198)
     */
    private fun checkAchievementsAndAlerts(
        currentStats: DashboardMetrics.Stats,
        allShifts: List<CompletedShift>,
        isRefresh: Boolean
    ) {
        viewModelScope.launch {
            try {
                // Check for missing shift entries from yesterday (iOS lines 191-198)
                val yesterday = Clock.System.now()
                    .toLocalDateTime(TimeZone.currentSystemDefault())
                    .date.minus(1, DateTimeUnit.DAY)
                val today = Clock.System.now()
                    .toLocalDateTime(TimeZone.currentSystemDefault()).date

                val recentShifts = allShifts.filter { shift ->
                    val shiftDate = LocalDate.parse(shift.shiftDate)
                    shiftDate >= yesterday && shiftDate <= today
                }

                if (recentShifts.isNotEmpty()) {
                    alertManager.checkForMissingShiftEntries(recentShifts)
                }

                // TODO: Check for achievements (needs data structure compatibility)
                // achievementManager.checkForAchievements(
                //     shifts = currentStats.completedShifts,
                //     currentStats = currentStats,
                //     targets = _userTargets.value
                // )

                // TODO: Check for target achievements (needs AlertManager API)
                // alertManager.checkForTargetAchievements(
                //     currentStats, 
                //     _userTargets.value, 
                //     _selectedPeriod.value
                // )

                // TODO: Check for missing shifts (needs AlertManager API)
                // alertManager.checkForMissingShifts(
                //     currentStats.completedShifts,
                //     _userTargets.value
                // )

                println("📊 Dashboard - Achievements and alerts checked (refresh=$isRefresh)")
            } catch (e: Exception) {
                println("⚠️ Dashboard - Error checking achievements/alerts: ${e.message}")
            }
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
    val shifts: List<CompletedShift> = emptyList(),
    val recentShifts: List<CompletedShift> = emptyList(),
    val allShifts: List<CompletedShift> = emptyList(), // All shifts for period (for effective sales targets)
    val hasData: Boolean = false
)

// Use the data classes from DashboardMetrics to avoid duplication