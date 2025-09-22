package com.protip365.app.presentation.calendar

import androidx.compose.ui.graphics.Color
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.data.models.Entry
import com.protip365.app.data.models.Shift
import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.ShiftRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.*
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class CalendarViewModel @Inject constructor(
    private val shiftRepository: ShiftRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _state = MutableStateFlow(CalendarState())
    val state: StateFlow<CalendarState> = _state.asStateFlow()

    private val _selectedDate = MutableStateFlow<LocalDate?>(LocalDate.now())
    val selectedDate: StateFlow<LocalDate?> = _selectedDate.asStateFlow()

    private val _currentLanguage = MutableStateFlow("en")
    val currentLanguage: StateFlow<String> = _currentLanguage.asStateFlow()

    private val _subscriptionTier = MutableStateFlow("free")
    val subscriptionTier: StateFlow<String> = _subscriptionTier.asStateFlow()

    private val _weeklyLimits = MutableStateFlow(WeeklyLimits())
    val weeklyLimits: StateFlow<WeeklyLimits> = _weeklyLimits.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    init {
        loadMonthData()
    }

    fun selectDate(date: LocalDate) {
        _selectedDate.value = date
        loadDateData(date)
    }

    fun isPastDateOrToday(date: LocalDate): Boolean {
        val today = LocalDate.now()
        return date <= today
    }

    fun isFutureDate(date: LocalDate): Boolean {
        val today = LocalDate.now()
        return date > today
    }

    fun getRecommendedAction(date: LocalDate): String {
        return if (isPastDateOrToday(date)) {
            "entry" // Recommend entry for past/today dates
        } else {
            "shift" // Recommend shift for future dates
        }
    }

    private fun loadMonthData() {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                val user = authRepository.getCurrentUser()
                if (user == null) {
                    _isLoading.value = false
                    return@launch
                }
            val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
            val startOfMonth = kotlinx.datetime.LocalDate(now.year, now.month, 1)
            val endOfMonth = startOfMonth.plus(1, DateTimeUnit.MONTH).minus(1, DateTimeUnit.DAY)

            val shifts = shiftRepository.getShifts(user.userId, startOfMonth, endOfMonth)
            val entries = shiftRepository.getEntries(user.userId, startOfMonth, endOfMonth)

            val datesWithShifts = mutableSetOf<LocalDate>()
            val earningsByDate = mutableMapOf<LocalDate, Double>()

            shifts.forEach { shift ->
                val date = LocalDate.parse(shift.shiftDate)
                datesWithShifts.add(date)
                earningsByDate[date] = (earningsByDate[date] ?: 0.0) + shift.totalEarnings
            }

            entries.forEach { entry ->
                val date = LocalDate.parse(entry.entryDate)
                datesWithShifts.add(date)
                earningsByDate[date] = (earningsByDate[date] ?: 0.0) + entry.totalEarnings
            }

            val monthlyTotal = earningsByDate.values.sum()

            _state.value = _state.value.copy(
                datesWithShifts = datesWithShifts,
                earningsByDate = earningsByDate,
                monthlyTotal = monthlyTotal
            )
            _isLoading.value = false

            // Load selected date data
            _selectedDate.value?.let { loadDateData(it) }
            } catch (e: Exception) {
                _isLoading.value = false
                // Log error or update state with error message
            }
        }
    }

    private fun loadDateData(date: LocalDate) {
        viewModelScope.launch {
            val user = authRepository.getCurrentUser() ?: return@launch

            // Convert java.time.LocalDate to kotlinx.datetime.LocalDate
            val kotlinDate = kotlinx.datetime.LocalDate(date.year, date.monthValue, date.dayOfMonth)

            val shifts = shiftRepository.getShifts(user.userId, kotlinDate, kotlinDate)
            val entries = shiftRepository.getEntries(user.userId, kotlinDate, kotlinDate)

            val totalEarnings = shifts.sumOf { it.totalEarnings } + entries.sumOf { it.totalEarnings }

            _state.value = _state.value.copy(
                selectedDateShifts = shifts,
                selectedDateEntries = entries,
                selectedDateEarnings = totalEarnings
            )
        }
    }

    fun refreshData() {
        loadMonthData()
        // loadWeeklyLimits() // TODO: Implement when subscription logic is ready
    }

    private fun loadWeeklyLimits() {
        // TODO: Load weekly limits from subscription repository
    }

    fun deleteShift(shift: Shift) {
        viewModelScope.launch {
            shiftRepository.deleteShift(shift.id)
            refreshData()
        }
    }

    fun deleteEntry(entry: Entry) {
        viewModelScope.launch {
            shiftRepository.deleteEntry(entry.id)
            refreshData()
        }
    }

    private fun getEmployerColor(employerId: String?): Color? {
        return employerId?.let {
            // Generate a consistent color based on employer ID
            val hash = it.hashCode()
            val hue = (hash % 360).toFloat()
            Color.hsl(hue, 0.7f, 0.8f)
        }
    }
}

data class ShiftData(
    val shifts: List<Shift> = emptyList(),
    val entries: List<Entry> = emptyList(),
    val totalEarnings: Double = 0.0,
    val totalHours: Double = 0.0
)

data class CalendarState(
    val shiftsDataMap: Map<LocalDate, ShiftData> = emptyMap(),
    val datesWithShifts: Set<LocalDate> = emptySet(),
    val earningsByDate: Map<LocalDate, Double> = emptyMap(),
    val monthlyTotal: Double = 0.0,
    val selectedDateShifts: List<Shift> = emptyList(),
    val selectedDateEntries: List<Entry> = emptyList(),
    val selectedDateEarnings: Double = 0.0
)

data class WeeklyLimits(
    val shiftsUsed: Int = 0,
    val entriesUsed: Int = 0
)