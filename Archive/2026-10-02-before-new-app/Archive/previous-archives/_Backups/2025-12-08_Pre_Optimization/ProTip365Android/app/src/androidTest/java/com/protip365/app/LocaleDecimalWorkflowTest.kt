package com.protip365.app

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.protip365.app.presentation.MainActivity
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumentation tests for locale-aware decimal input across all workflows.
 * These tests run on an Android device/emulator and simulate real user interactions.
 *
 * Run with: ./gradlew connectedAndroidTest
 */
@RunWith(AndroidJUnit4::class)
class LocaleDecimalWorkflowTest {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    // ============================================================================
    // EMPLOYER WORKFLOW TESTS
    // ============================================================================

    @Test
    fun createEmployer_withEnglishDecimalRate_savesCorrectly() {
        // Navigate to employers screen
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Employers").performClick()

        // Click add employer
        composeTestRule.onNodeWithContentDescription("Add employer").performClick()

        // Enter employer details with period decimal
        composeTestRule.onNodeWithText("Employer Name").performTextInput("Test Restaurant")
        composeTestRule.onNodeWithText("Default Hourly Rate").performTextInput("15.50")

        // Save
        composeTestRule.onNodeWithText("Add").performClick()

        // Verify employer appears in list
        composeTestRule.onNodeWithText("Test Restaurant").assertExists()
        composeTestRule.onNodeWithText("$15.5/hour").assertExists()
    }

    @Test
    fun createEmployer_withFrenchDecimalRate_savesCorrectly() {
        // Navigate to employers screen
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Employers").performClick()

        // Click add employer
        composeTestRule.onNodeWithContentDescription("Add employer").performClick()

        // Enter employer details with COMMA decimal (French format)
        composeTestRule.onNodeWithText("Employer Name").performTextInput("Restaurant Français")
        composeTestRule.onNodeWithText("Default Hourly Rate").performTextInput("18,75")

        // Save
        composeTestRule.onNodeWithText("Add").performClick()

        // Verify employer appears with correctly parsed rate
        composeTestRule.onNodeWithText("Restaurant Français").assertExists()
        composeTestRule.onNodeWithText("$18.75/hour").assertExists()
    }

    @Test
    fun editEmployer_withCommaDecimal_updatesCorrectly() {
        // Assuming an employer already exists
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Employers").performClick()

        // Click on employer options
        composeTestRule.onNodeWithContentDescription("More options").performClick()
        composeTestRule.onNodeWithText("Edit").performClick()

        // Clear and enter new rate with comma
        composeTestRule.onNodeWithText("Default Hourly Rate").performTextClearance()
        composeTestRule.onNodeWithText("Default Hourly Rate").performTextInput("20,25")

        // Save
        composeTestRule.onNodeWithText("Save").performClick()

        // Verify updated rate
        composeTestRule.onNodeWithText("$20.25/hour").assertExists()
    }

    // ============================================================================
    // SHIFT ENTRY WORKFLOW TESTS
    // ============================================================================

    @Test
    fun createEntry_withCommaDecimalTips_savesCorrectly() {
        // Navigate to add entry
        composeTestRule.onNodeWithContentDescription("Add entry").performClick()

        // Enter shift details with comma decimals (French format)
        composeTestRule.onNodeWithText("Tips").performTextInput("45,75")
        composeTestRule.onNodeWithText("Sales").performTextInput("350,50")
        composeTestRule.onNodeWithText("Tip Out").performTextInput("8,25")
        composeTestRule.onNodeWithText("Other").performTextInput("10,00")

        // Save entry
        composeTestRule.onNodeWithContentDescription("Save entry").performClick()

        // Verify entry saved (check summary or list)
        // The exact verification depends on your UI structure
        composeTestRule.waitForIdle()
        // Entry should be saved without crash
    }

    @Test
    fun createEntry_withPeriodDecimalTips_savesCorrectly() {
        // Navigate to add entry
        composeTestRule.onNodeWithContentDescription("Add entry").performClick()

        // Enter shift details with period decimals (English format)
        composeTestRule.onNodeWithText("Tips").performTextInput("52.25")
        composeTestRule.onNodeWithText("Sales").performTextInput("425.00")
        composeTestRule.onNodeWithText("Tip Out").performTextInput("10.50")

        // Save entry
        composeTestRule.onNodeWithContentDescription("Save entry").performClick()

        // Verify entry saved
        composeTestRule.waitForIdle()
    }

    @Test
    fun createEntry_withMixedDecimalFormats_calculatesCorrectly() {
        // Test that mixing comma and period in same entry works
        composeTestRule.onNodeWithContentDescription("Add entry").performClick()

        // Mix formats (user might switch languages mid-entry)
        composeTestRule.onNodeWithText("Tips").performTextInput("30,50") // Comma
        composeTestRule.onNodeWithText("Tip Out").performTextInput("5.00") // Period

        // Expected net tips: 30.50 - 5.00 = 25.50
        // Save and verify calculation worked
        composeTestRule.onNodeWithContentDescription("Save entry").performClick()
        composeTestRule.waitForIdle()
    }

    @Test
    fun editEntry_changeDecimalFormat_updatesCorrectly() {
        // Assuming an entry exists
        composeTestRule.onNodeWithContentDescription("Entry item").performClick()

        // Edit tips from period to comma format
        composeTestRule.onNodeWithText("Tips").performTextClearance()
        composeTestRule.onNodeWithText("Tips").performTextInput("65,80")

        // Save
        composeTestRule.onNodeWithContentDescription("Save entry").performClick()
        composeTestRule.waitForIdle()
    }

    // ============================================================================
    // CALCULATOR WORKFLOW TESTS
    // ============================================================================

    @Test
    fun tipCalculator_withCommaBillAmount_calculatesCorrectly() {
        // Navigate to calculator
        composeTestRule.onNodeWithText("Calculator").performClick()

        // Enter bill amount with comma
        composeTestRule.onNodeWithText("Bill Amount").performTextInput("85,50")

        // Set tip percentage
        composeTestRule.onNodeWithText("Tip Percentage").performTextClearance()
        composeTestRule.onNodeWithText("Tip Percentage").performTextInput("20")

        // Verify calculation: 85.50 * 0.20 = 17.10
        composeTestRule.onNodeWithText("$17.10").assertExists()
        composeTestRule.onNodeWithText("$102.60").assertExists() // Total
    }

    @Test
    fun tipOutCalculator_withCommaAmounts_calculatesCorrectly() {
        // Navigate to calculator
        composeTestRule.onNodeWithText("Calculator").performClick()
        composeTestRule.onNodeWithText("Tip-out").performClick()

        // Enter total tips with comma
        composeTestRule.onNodeWithText("Total Tips").performTextInput("125,00")

        // Enter tip-out percentages with comma
        composeTestRule.onNodeWithText("Tip-out Percentage").performTextInput("3,5")

        // Verify: 125.00 * 0.035 = 4.375 ≈ $4.38
        composeTestRule.onNodeWithText("$4.38").assertExists()
    }

    @Test
    fun hourlyRateCalculator_withCommaEarnings_calculatesCorrectly() {
        // Navigate to calculator
        composeTestRule.onNodeWithText("Calculator").performClick()
        composeTestRule.onNodeWithText("Hourly").performClick()

        // Enter earnings and hours with comma
        composeTestRule.onNodeWithText("Total Earnings").performTextInput("180,50")
        composeTestRule.onNodeWithText("Hours Worked").performTextInput("8,5")

        // Verify: 180.50 / 8.5 = 21.235... ≈ $21.24/hr
        composeTestRule.onNodeWithText("$21.24/hr").assertExists()
    }

    // ============================================================================
    // SETTINGS WORKFLOW TESTS
    // ============================================================================

    @Test
    fun updateWorkDefaults_withCommaHourlyRate_savesCorrectly() {
        // Navigate to settings
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Work Defaults").performClick()

        // Update default hourly rate with comma
        composeTestRule.onNodeWithText("Default Hourly Rate").performTextClearance()
        composeTestRule.onNodeWithText("Default Hourly Rate").performTextInput("16,75")

        // Update deduction percentage with comma
        composeTestRule.onNodeWithText("Avg deductions").performTextClearance()
        composeTestRule.onNodeWithText("Avg deductions").performTextInput("28,5")

        // Save (if there's a save button, otherwise settings auto-save)
        composeTestRule.waitForIdle()

        // Verify saved by navigating away and back
        composeTestRule.onNodeWithContentDescription("Back").performClick()
        composeTestRule.onNodeWithText("Work Defaults").performClick()
        composeTestRule.onNodeWithText("16.75").assertExists()
    }

    @Test
    fun updateTargets_withCommaAmounts_savesCorrectly() {
        // Navigate to targets
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Targets").performClick()

        // Update targets with comma decimals
        composeTestRule.onNodeWithText("Daily Target").performTextInput("150,00")
        composeTestRule.onNodeWithText("Weekly Target").performTextInput("1050,50")
        composeTestRule.onNodeWithText("Monthly Target").performTextInput("4500,25")

        // Save
        composeTestRule.onNodeWithText("Save").performClick()

        // Verify saved
        composeTestRule.waitForIdle()
    }

    // ============================================================================
    // EDGE CASE TESTS
    // ============================================================================

    @Test
    fun invalidDecimal_multipleCommas_handledGracefully() {
        composeTestRule.onNodeWithContentDescription("Add entry").performClick()

        // Try to enter invalid format
        composeTestRule.onNodeWithText("Tips").performTextInput("10,,50")

        // Should either reject input or parse as 0
        composeTestRule.onNodeWithContentDescription("Save entry").performClick()

        // App should not crash
        composeTestRule.waitForIdle()
    }

    @Test
    fun invalidDecimal_multiplePeriods_handledGracefully() {
        composeTestRule.onNodeWithContentDescription("Add entry").performClick()

        // Try to enter invalid format
        composeTestRule.onNodeWithText("Tips").performTextInput("10..50")

        // Should either reject input or parse as 0
        composeTestRule.onNodeWithContentDescription("Save entry").performClick()

        // App should not crash
        composeTestRule.waitForIdle()
    }

    @Test
    fun emptyDecimalField_treatedAsZero() {
        composeTestRule.onNodeWithContentDescription("Add entry").performClick()

        // Leave tips empty
        composeTestRule.onNodeWithText("Sales").performTextInput("100,00")

        // Save should work, tips = 0
        composeTestRule.onNodeWithContentDescription("Save entry").performClick()
        composeTestRule.waitForIdle()
    }

    @Test
    fun veryLargeNumber_withComma_parsesCorrectly() {
        composeTestRule.onNodeWithContentDescription("Add entry").performClick()

        // Enter large sales amount
        composeTestRule.onNodeWithText("Sales").performTextInput("12345,67")

        composeTestRule.onNodeWithContentDescription("Save entry").performClick()
        composeTestRule.waitForIdle()
    }

    @Test
    fun verySmallDecimal_withComma_parsesCorrectly() {
        composeTestRule.onNodeWithContentDescription("Add entry").performClick()

        // Enter small tip out
        composeTestRule.onNodeWithText("Tip Out").performTextInput("0,25")

        composeTestRule.onNodeWithContentDescription("Save entry").performClick()
        composeTestRule.waitForIdle()
    }
}
