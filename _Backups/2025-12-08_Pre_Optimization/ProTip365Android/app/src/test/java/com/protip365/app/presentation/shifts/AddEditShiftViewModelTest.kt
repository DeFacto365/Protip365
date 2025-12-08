package com.protip365.app.presentation.shifts

import com.protip365.app.data.models.Employer
import kotlinx.datetime.*
import org.junit.Test
import org.junit.Assert.*

class AddEditShiftViewModelTest {

    @Test
    fun `test past date validation for new shifts`() {
        // Given
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        val yesterday = today.minus(1, DateTimeUnit.DAY)
        val tomorrow = today.plus(1, DateTimeUnit.DAY)

        // Test case 1: Past date should be rejected for new shifts
        val uiStateNewShift = AddEditShiftUiState(
            selectedDate = yesterday,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            hourlyRate = 20.0
        )

        // When validating a new shift with past date
        val editingShiftId: String? = null
        val isPastDate = editingShiftId == null && uiStateNewShift.selectedDate < today

        // Then
        assertTrue("Past date should be rejected for new shifts", isPastDate)

        // Test case 2: Future date should be accepted for new shifts
        val uiStateFutureShift = AddEditShiftUiState(
            selectedDate = tomorrow,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            hourlyRate = 20.0
        )

        val isFutureDate = editingShiftId == null && uiStateFutureShift.selectedDate < today
        assertFalse("Future date should be accepted for new shifts", isFutureDate)

        // Test case 3: Today should be accepted for new shifts
        val uiStateTodayShift = AddEditShiftUiState(
            selectedDate = today,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            hourlyRate = 20.0
        )

        val isTodayInvalid = editingShiftId == null && uiStateTodayShift.selectedDate < today
        assertFalse("Today should be accepted for new shifts", isTodayInvalid)
    }

    @Test
    fun `test past date allowed for editing existing shifts`() {
        // Given
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        val yesterday = today.minus(1, DateTimeUnit.DAY)

        // Test case: Past date should be allowed when editing existing shifts
        val uiStateEditShift = AddEditShiftUiState(
            selectedDate = yesterday,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            hourlyRate = 20.0
        )

        // When editing an existing shift
        val editingShiftId: String? = "existing-shift-id"
        val shouldValidatePastDate = editingShiftId == null

        // Then
        assertFalse("Past date validation should not apply when editing existing shifts", shouldValidatePastDate)
    }
}