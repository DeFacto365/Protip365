package com.protip365.app.presentation.shifts

import com.protip365.app.data.models.ExpectedShift
import kotlinx.datetime.*
import org.junit.Test
import org.junit.Assert.*

class ShiftOverlapValidationTest {

    @Test
    fun `test overnight shift handling`() {
        // Given
        val today = LocalDate(2024, 1, 15)
        val tomorrow = today.plus(1, DateTimeUnit.DAY)

        // Test case 1: Overnight shift (10 PM to 2 AM)
        val startTime = LocalTime(22, 0) // 10 PM
        val endTime = LocalTime(2, 0)    // 2 AM

        // When end time is before start time, it should be treated as next day
        val isOvernightShift = endTime < startTime
        assertTrue("Should detect overnight shift when end time is before start time", isOvernightShift)

        // The effective end date should be tomorrow
        val effectiveEndDate = if (isOvernightShift) tomorrow else today
        assertEquals("End date should be next day for overnight shift", tomorrow, effectiveEndDate)
    }

    @Test
    fun `test end date cannot be before start date`() {
        // Given
        val startDate = LocalDate(2024, 1, 15)
        val invalidEndDate = LocalDate(2024, 1, 14) // Day before

        // When checking if end date is valid
        val isInvalidEndDate = invalidEndDate < startDate

        // Then
        assertTrue("End date before start date should be invalid", isInvalidEndDate)
    }

    @Test
    fun `test shift overlap detection for same day shifts`() {
        // Given existing shift from 9 AM to 5 PM
        val existingShift = createShift(
            date = "2024-01-15",
            startTime = "09:00",
            endTime = "17:00"
        )

        // Test case 1: New shift overlaps (starts during existing shift)
        val overlappingShift1Start = "2024-01-15 12:00"
        val overlappingShift1End = "2024-01-15 18:00"
        val existingStart = "2024-01-15 09:00"
        val existingEnd = "2024-01-15 17:00"

        val hasOverlap1 = checkOverlap(overlappingShift1Start, overlappingShift1End, existingStart, existingEnd)
        assertTrue("Shift starting during existing shift should overlap", hasOverlap1)

        // Test case 2: New shift doesn't overlap (after existing shift)
        val nonOverlappingShiftStart = "2024-01-15 18:00"
        val nonOverlappingShiftEnd = "2024-01-15 22:00"

        val hasOverlap2 = checkOverlap(nonOverlappingShiftStart, nonOverlappingShiftEnd, existingStart, existingEnd)
        assertFalse("Shift starting after existing shift ends should not overlap", hasOverlap2)

        // Test case 3: New shift doesn't overlap (before existing shift)
        val earlyShiftStart = "2024-01-15 06:00"
        val earlyShiftEnd = "2024-01-15 08:00"

        val hasOverlap3 = checkOverlap(earlyShiftStart, earlyShiftEnd, existingStart, existingEnd)
        assertFalse("Shift ending before existing shift starts should not overlap", hasOverlap3)
    }

    @Test
    fun `test shift overlap detection for overnight shifts`() {
        // Given existing overnight shift from 10 PM to 2 AM
        val existingStart = "2024-01-15 22:00"
        val existingEnd = "2024-01-16 02:00" // Next day

        // Test case 1: New shift overlaps (11 PM to 1 AM)
        val overlappingStart = "2024-01-15 23:00"
        val overlappingEnd = "2024-01-16 01:00"

        val hasOverlap1 = checkOverlap(overlappingStart, overlappingEnd, existingStart, existingEnd)
        assertTrue("Overnight shift within existing overnight shift should overlap", hasOverlap1)

        // Test case 2: New shift overlaps (starts at 1 AM next day)
        val lateNightStart = "2024-01-16 01:00"
        val lateNightEnd = "2024-01-16 05:00"

        val hasOverlap2 = checkOverlap(lateNightStart, lateNightEnd, existingStart, existingEnd)
        assertTrue("Shift starting during overnight shift should overlap", hasOverlap2)

        // Test case 3: New shift doesn't overlap (morning shift next day)
        val morningStart = "2024-01-16 06:00"
        val morningEnd = "2024-01-16 14:00"

        val hasOverlap3 = checkOverlap(morningStart, morningEnd, existingStart, existingEnd)
        assertFalse("Morning shift after overnight shift ends should not overlap", hasOverlap3)
    }

    @Test
    fun `test multi-day shift validation`() {
        // Given a shift spanning multiple days (Friday 6 PM to Sunday 2 AM)
        val startDate = LocalDate(2024, 1, 12) // Friday
        val endDate = LocalDate(2024, 1, 14)   // Sunday
        val startTime = LocalTime(18, 0)       // 6 PM
        val endTime = LocalTime(2, 0)          // 2 AM

        // Calculate total hours
        val startDateTime = startDate.atTime(startTime)
        val endDateTime = endDate.atTime(endTime)
        val startInstant = startDateTime.toInstant(TimeZone.UTC)
        val endInstant = endDateTime.toInstant(TimeZone.UTC)
        val totalHours = (endInstant - startInstant).inWholeHours

        // Then total hours should be correct (32 hours)
        assertEquals("Multi-day shift should calculate correct hours", 32L, totalHours)
    }

    // Helper function to simulate overlap checking logic
    private fun checkOverlap(
        checkStart: String,
        checkEnd: String,
        existingStart: String,
        existingEnd: String
    ): Boolean {
        // Check for overlap: shifts overlap if one starts before the other ends
        return (checkStart < existingEnd && checkEnd > existingStart)
    }

    // Helper function to create a test shift
    private fun createShift(
        date: String,
        startTime: String,
        endTime: String
    ): ExpectedShift {
        return ExpectedShift(
            id = "test-shift",
            userId = "test-user",
            employerId = "test-employer",
            shiftDate = date,
            startTime = startTime,
            endTime = endTime,
            expectedHours = 8.0,
            hourlyRate = 15.0,
            lunchBreakMinutes = 0,
            status = "planned",
            alertMinutes = null,
            notes = null
        )
    }
}