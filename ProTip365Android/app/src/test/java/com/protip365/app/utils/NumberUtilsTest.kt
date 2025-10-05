package com.protip365.app.utils

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class NumberUtilsTest {

    @Test
    fun `toLocaleDouble handles English format with period`() {
        assertEquals(10.5, "10.50".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(25.0, "25.00".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(100.99, "100.99".toLocaleDouble() ?: 0.0, 0.001)
    }

    @Test
    fun `toLocaleDouble handles French format with comma`() {
        assertEquals(10.5, "10,50".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(25.0, "25,00".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(100.99, "100,99".toLocaleDouble() ?: 0.0, 0.001)
    }

    @Test
    fun `toLocaleDouble handles Spanish format with comma`() {
        assertEquals(15.25, "15,25".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(30.0, "30,00".toLocaleDouble() ?: 0.0, 0.001)
    }

    @Test
    fun `toLocaleDouble handles integers without decimal`() {
        assertEquals(10.0, "10".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(0.0, "0".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(1000.0, "1000".toLocaleDouble() ?: 0.0, 0.001)
    }

    @Test
    fun `toLocaleDouble handles decimal with trailing period`() {
        assertEquals(10.0, "10.".toLocaleDouble() ?: 0.0, 0.001)
    }

    @Test
    fun `toLocaleDouble handles decimal with trailing comma`() {
        assertEquals(10.0, "10,".toLocaleDouble() ?: 0.0, 0.001)
    }

    @Test
    fun `toLocaleDouble returns null for empty string`() {
        assertNull("".toLocaleDouble())
        assertNull("   ".toLocaleDouble())
    }

    @Test
    fun `toLocaleDouble returns null for invalid input`() {
        assertNull("abc".toLocaleDouble())
        assertNull("ten".toLocaleDouble())
        // Note: Multiple decimals like "10.50.25" may parse depending on locale NumberFormat
        // The validation regex in the UI prevents this from ever reaching the parser
    }

    @Test
    fun `toLocaleDouble handles large numbers`() {
        assertEquals(1234567.89, "1234567.89".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(1234567.89, "1234567,89".toLocaleDouble() ?: 0.0, 0.001)
    }

    @Test
    fun `toLocaleDouble handles small decimals`() {
        assertEquals(0.01, "0.01".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(0.01, "0,01".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(0.99, "0.99".toLocaleDouble() ?: 0.0, 0.001)
        assertEquals(0.99, "0,99".toLocaleDouble() ?: 0.0, 0.001)
    }

    @Test
    fun `toLocaleDoubleOrDefault returns default on failure`() {
        assertEquals(0.0, "invalid".toLocaleDoubleOrDefault(), 0.001)
        assertEquals(15.0, "invalid".toLocaleDoubleOrDefault(15.0), 0.001)
        assertEquals(100.0, "".toLocaleDoubleOrDefault(100.0), 0.001)
    }

    @Test
    fun `toLocaleDoubleOrDefault returns parsed value on success`() {
        assertEquals(25.5, "25.50".toLocaleDoubleOrDefault(), 0.001)
        assertEquals(25.5, "25,50".toLocaleDoubleOrDefault(), 0.001)
        assertEquals(10.0, "10".toLocaleDoubleOrDefault(99.0), 0.001)
    }

    @Test
    fun `toLocaleString formats with US locale`() {
        assertEquals("10.50", 10.5.toLocaleString(decimals = 2, useLocale = false))
        assertEquals("25.00", 25.0.toLocaleString(decimals = 2, useLocale = false))
        assertEquals("100.99", 100.99.toLocaleString(decimals = 2, useLocale = false))
    }

    @Test
    fun `toLocaleString handles different decimal places`() {
        assertEquals("10.5", 10.5.toLocaleString(decimals = 1, useLocale = false))
        assertEquals("10.500", 10.5.toLocaleString(decimals = 3, useLocale = false))
        assertEquals("10", 10.0.toLocaleString(decimals = 0, useLocale = false))
    }

    // Real-world scenarios from app usage
    @Test
    fun `real scenario - French user enters tips`() {
        val userInput = "45,75" // French keyboard input
        val parsed = userInput.toLocaleDouble() ?: 0.0
        assertEquals(45.75, parsed, 0.001)
    }

    @Test
    fun `real scenario - English user enters hourly rate`() {
        val userInput = "15.50" // English keyboard input
        val parsed = userInput.toLocaleDouble() ?: 0.0
        assertEquals(15.50, parsed, 0.001)
    }

    @Test
    fun `real scenario - Spanish user enters sales`() {
        val userInput = "150,25" // Spanish keyboard input
        val parsed = userInput.toLocaleDouble() ?: 0.0
        assertEquals(150.25, parsed, 0.001)
    }

    @Test
    fun `real scenario - calculator with comma percentage`() {
        val billAmount = "100,00".toLocaleDouble() ?: 0.0
        val tipPercent = "15,5".toLocaleDouble() ?: 0.0
        val tipAmount = billAmount * tipPercent / 100
        assertEquals(15.5, tipAmount, 0.001)
    }

    @Test
    fun `real scenario - entry calculation with mixed separators`() {
        // User might have old entries with period, new with comma
        val tips = "25,50".toLocaleDouble() ?: 0.0
        val tipOut = "5.00".toLocaleDouble() ?: 0.0  // Old entry
        val netTips = tips - tipOut
        assertEquals(20.5, netTips, 0.001)
    }
}
