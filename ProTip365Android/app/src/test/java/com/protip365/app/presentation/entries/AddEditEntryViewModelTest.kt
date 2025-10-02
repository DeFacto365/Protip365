package com.protip365.app.presentation.entries

import com.protip365.app.data.models.Employer
import kotlinx.datetime.*
import org.junit.Test
import org.junit.Assert.*

class AddEditEntryViewModelTest {

    @Test
    fun `test future date validation for entries`() {
        // Given
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        val yesterday = today.minus(1, DateTimeUnit.DAY)
        val tomorrow = today.plus(1, DateTimeUnit.DAY)

        // Test case 1: Future date should be rejected for entries
        val uiStateFutureEntry = AddEditEntryUiState(
            selectedDate = tomorrow,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            didntWork = false
        )

        // When validating a new entry with future date
        val isFutureDate = uiStateFutureEntry.selectedDate > today

        // Then
        assertTrue("Future date should be rejected for entries", isFutureDate)

        // Test case 2: Past date should be accepted for entries
        val uiStatePastEntry = AddEditEntryUiState(
            selectedDate = yesterday,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            didntWork = false
        )

        val isPastDateInvalid = uiStatePastEntry.selectedDate > today
        assertFalse("Past date should be accepted for entries", isPastDateInvalid)

        // Test case 3: Today should be accepted for entries
        val uiStateTodayEntry = AddEditEntryUiState(
            selectedDate = today,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            didntWork = false
        )

        val isTodayInvalid = uiStateTodayEntry.selectedDate > today
        assertFalse("Today should be accepted for entries", isTodayInvalid)
    }

    @Test
    fun `test future end date validation for overnight entries`() {
        // Given
        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
        val tomorrow = today.plus(1, DateTimeUnit.DAY)

        // Test case: Future end date should be rejected for entries
        val uiStateOvernightEntry = AddEditEntryUiState(
            selectedDate = today,
            endDate = tomorrow,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            didntWork = false
        )

        // When validating an overnight entry with future end date
        val isFutureEndDate = uiStateOvernightEntry.endDate != null && uiStateOvernightEntry.endDate > today

        // Then
        assertTrue("Future end date should be rejected for entries", isFutureEndDate)

        // Test case 2: End date of today should be accepted
        val uiStateValidOvernightEntry = AddEditEntryUiState(
            selectedDate = today.minus(1, DateTimeUnit.DAY),
            endDate = today,
            selectedEmployer = Employer(id = "1", userId = "1", name = "Test Employer"),
            didntWork = false
        )

        val isValidEndDate = uiStateValidOvernightEntry.endDate != null && uiStateValidOvernightEntry.endDate > today
        assertFalse("End date of today should be accepted for overnight entries", isValidEndDate)
    }
}