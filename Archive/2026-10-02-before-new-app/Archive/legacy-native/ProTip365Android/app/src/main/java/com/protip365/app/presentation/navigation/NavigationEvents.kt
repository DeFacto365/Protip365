package com.protip365.app.presentation.navigation

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.datetime.LocalDate
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Navigation Event System for Deep Linking
 * 
 * Enables navigation from:
 * - Notifications → Calendar with specific date
 * - Notifications → Shift editor with shiftId
 * - Alerts → Relevant screens
 * 
 * Uses SharedFlow to handle one-time navigation events
 * across the app without tight coupling.
 */
@Singleton
class NavigationEventManager @Inject constructor() {

    private val _navigationEvents = MutableSharedFlow<NavigationEvent>(
        extraBufferCapacity = 1
    )
    val navigationEvents: SharedFlow<NavigationEvent> = _navigationEvents.asSharedFlow()

    /**
     * Navigate to calendar with specific date selected
     * Used by: Notification taps, alert actions, deep links
     */
    suspend fun navigateToCalendar(date: LocalDate) {
        println("📍 Navigation Event: Navigate to Calendar (date=$date)")
        _navigationEvents.emit(NavigationEvent.NavigateToCalendar(date))
    }

    /**
     * Navigate to shift editor for specific shift
     * Uses 300ms delay to allow UI to settle (iOS pattern)
     * Used by: Notification taps, alert actions
     */
    suspend fun navigateToShift(shiftId: String, delayMs: Long = 300) {
        println("📍 Navigation Event: Navigate to Shift (id=$shiftId, delay=${delayMs}ms)")
        kotlinx.coroutines.delay(delayMs)
        _navigationEvents.emit(NavigationEvent.NavigateToShift(shiftId))
    }

    /**
     * Navigate to add entry for specific date
     */
    suspend fun navigateToAddEntry(date: LocalDate) {
        println("📍 Navigation Event: Navigate to Add Entry (date=$date)")
        _navigationEvents.emit(NavigationEvent.NavigateToAddEntry(date))
    }

    /**
     * Navigate to specific shift entry for editing
     */
    suspend fun navigateToEditEntry(entryId: String) {
        println("📍 Navigation Event: Navigate to Edit Entry (id=$entryId)")
        _navigationEvents.emit(NavigationEvent.NavigateToEditEntry(entryId))
    }

    /**
     * Navigate to dashboard tab
     */
    suspend fun navigateToDashboard() {
        println("📍 Navigation Event: Navigate to Dashboard")
        _navigationEvents.emit(NavigationEvent.NavigateToDashboard)
    }

    /**
     * Navigate to a specific tab in MainScreen
     */
    suspend fun navigateToTab(tabId: String) {
        println("📍 Navigation Event: Navigate to Tab (id=$tabId)")
        _navigationEvents.emit(NavigationEvent.NavigateToTab(tabId))
    }
}

/**
 * Navigation Events
 * Sealed class ensures type-safe navigation
 */
sealed class NavigationEvent {
    data class NavigateToCalendar(val date: LocalDate) : NavigationEvent()
    data class NavigateToShift(val shiftId: String) : NavigationEvent()
    data class NavigateToAddEntry(val date: LocalDate) : NavigationEvent()
    data class NavigateToEditEntry(val entryId: String) : NavigationEvent()
    object NavigateToDashboard : NavigationEvent()
    data class NavigateToTab(val tabId: String) : NavigationEvent()
}
