package com.protip365.app

import io.mockk.clearAllMocks
import org.junit.After
import org.junit.Before

/**
 * Base test configuration for all unit tests
 */
abstract class TestConfiguration {
    
    @Before
    fun setup() {
        // Setup common test configuration
        // This can be extended by individual test classes
    }
    
    @After
    fun tearDown() {
        // Clean up mocks after each test
        clearAllMocks()
    }
}

/**
 * Test data factory for creating mock objects
 */
object TestDataFactory {
    
    fun createMockUserProfile(
        userId: String = "user123",
        name: String = "Test User",
        defaultHourlyRate: Double = 15.0,
        weekStart: Int = 0,
        useMultipleEmployers: Boolean = false,
        preferredLanguage: String = "en"
    ) = com.protip365.app.data.models.UserProfile(
        userId = userId,
        name = name,
        defaultHourlyRate = defaultHourlyRate,
        weekStart = weekStart,
        useMultipleEmployers = useMultipleEmployers,
        preferredLanguage = preferredLanguage
    )
    
    fun createMockEmployer(
        id: String = "employer123",
        userId: String = "user123",
        name: String = "Test Restaurant",
        hourlyRate: Double = 15.0,
        active: Boolean = true
    ) = com.protip365.app.data.models.Employer(
        id = id,
        userId = userId,
        name = name,
        hourlyRate = hourlyRate,
        active = active
    )
    
    fun createMockExpectedShift(
        id: String = "shift123",
        userId: String = "user123",
        shiftDate: String = "2024-01-01",
        startTime: String = "09:00",
        endTime: String = "17:00",
        expectedHours: Double = 8.0,
        hourlyRate: Double = 15.0,
        employerId: String? = null
    ) = com.protip365.app.data.models.ExpectedShift(
        id = id,
        userId = userId,
        shiftDate = shiftDate,
        startTime = startTime,
        endTime = endTime,
        expectedHours = expectedHours,
        hourlyRate = hourlyRate,
        employerId = employerId
    )
    
    fun createMockShiftEntry(
        id: String = "entry123",
        userId: String = "user123",
        shiftId: String = "shift123",
        actualStartTime: String = "09:00",
        actualEndTime: String = "17:00",
        actualHours: Double = 8.0,
        sales: Double = 1000.0,
        tips: Double = 150.0,
        cashOut: Double = 20.0,
        other: Double = 0.0,
        notes: String = "Test entry"
    ) = com.protip365.app.data.models.ShiftEntry(
        id = id,
        userId = userId,
        shiftId = shiftId,
        actualStartTime = actualStartTime,
        actualEndTime = actualEndTime,
        actualHours = actualHours,
        sales = sales,
        tips = tips,
        cashOut = cashOut,
        other = other,
        notes = notes
    )
}




