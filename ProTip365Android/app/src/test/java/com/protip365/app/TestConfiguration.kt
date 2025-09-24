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
    
    fun createMockUser(
        userId: String = "user123",
        email: String = "test@example.com",
        name: String = "Test User",
        phone: String? = null,
        createdAt: String = "2024-01-01T00:00:00Z",
        useMultipleEmployers: Boolean = false
    ) = com.protip365.app.data.models.User(
        userId = userId,
        email = email,
        name = name,
        phone = phone,
        createdAt = createdAt,
        useMultipleEmployers = useMultipleEmployers
    )
    
    fun createMockShift(
        id: String = "shift123",
        userId: String = "user123",
        shiftDate: String = "2024-01-01",
        startTime: String = "09:00",
        endTime: String = "17:00",
        hours: Double = 8.0,
        sales: Double = 1000.0,
        tips: Double = 150.0,
        hourlyRate: Double = 15.0,
        cashOut: Double = 20.0,
        other: Double = 0.0,
        notes: String = "Test shift",
        employerId: String? = null
    ) = com.protip365.app.data.models.Shift(
        id = id,
        userId = userId,
        shiftDate = shiftDate,
        startTime = startTime,
        endTime = endTime,
        hours = hours,
        sales = sales,
        tips = tips,
        hourlyRate = hourlyRate,
        cashOut = cashOut,
        other = other,
        notes = notes,
        employerId = employerId
    )
    
    fun createMockEntry(
        id: String = "entry123",
        userId: String = "user123",
        entryDate: String = "2024-01-01",
        sales: Double = 500.0,
        tips: Double = 75.0,
        cashOut: Double = 10.0,
        other: Double = 0.0,
        notes: String = "Test entry",
        employerId: String? = null
    ) = com.protip365.app.data.models.Entry(
        id = id,
        userId = userId,
        entryDate = entryDate,
        sales = sales,
        tips = tips,
        cashOut = cashOut,
        other = other,
        notes = notes,
        employerId = employerId
    )
    
    fun createMockEmployer(
        id: String = "employer123",
        userId: String = "user123",
        name: String = "Test Restaurant",
        address: String = "123 Test St",
        phone: String = "555-0123",
        email: String = "test@restaurant.com"
    ) = com.protip365.app.data.models.Employer(
        id = id,
        userId = userId,
        name = name,
        address = address,
        phone = phone,
        email = email
    )
}



