package com.protip365.app.presentation.calendar

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
class CalendarViewModel @Inject constructor(
    private val completedShiftRepository: CompletedShiftRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CalendarUiState())
    val uiState: StateFlow<CalendarUiState> = _uiState.asStateFlow()

    private val _shifts = MutableStateFlow<List<CompletedShift>>(emptyList())
    val shifts: StateFlow<List<CompletedShift>> = _shifts.asStateFlow()

    init {
        _uiState.update { it.copy(isLoading = true) }
        loadShifts()
    }

    private fun loadShifts() {
        viewModelScope.launch {
            try {
                val currentUser = userRepository.getCurrentUser().first()
                val userId = currentUser?.userId ?: return@launch

                completedShiftRepository.observeCompletedShifts(userId).collect { shiftList ->
                    _shifts.value = shiftList
                    _uiState.update { it.copy(isLoading = false, error = null) }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message, isLoading = false) }
            }
        }
    }


    fun selectDate(date: LocalDate) {
        _uiState.update { it.copy(selectedDate = date) }
    }

    fun getShiftsForDate(date: LocalDate): List<CompletedShift> {
        return _shifts.value.filter { shift ->
            try {
                val shiftDate = LocalDate.parse(shift.shiftDate)
                shiftDate == date
            } catch (e: Exception) {
                false
            }
        }
    }

    fun getShiftsForMonth(year: Int, month: Int): List<CompletedShift> {
        return _shifts.value.filter { shift ->
            try {
                val shiftDate = LocalDate.parse(shift.shiftDate)
                shiftDate.year == year && shiftDate.monthNumber == month
            } catch (e: Exception) {
                false
            }
        }
    }

    fun navigateToPreviousMonth() {
        _uiState.update { state ->
            val newMonth = if (state.currentMonth == 1) 12 else state.currentMonth - 1
            val newYear = if (state.currentMonth == 1) state.currentYear - 1 else state.currentYear
            state.copy(
                currentMonth = newMonth,
                currentYear = newYear
            )
        }
    }

    fun navigateToNextMonth() {
        _uiState.update { state ->
            val newMonth = if (state.currentMonth == 12) 1 else state.currentMonth + 1
            val newYear = if (state.currentMonth == 12) state.currentYear + 1 else state.currentYear
            state.copy(
                currentMonth = newMonth,
                currentYear = newYear
            )
        }
    }
}

data class CalendarUiState(
    val selectedDate: LocalDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date,
    val currentMonth: Int = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).monthNumber,
    val currentYear: Int = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).year,
    val isLoading: Boolean = false,
    val error: String? = null
)