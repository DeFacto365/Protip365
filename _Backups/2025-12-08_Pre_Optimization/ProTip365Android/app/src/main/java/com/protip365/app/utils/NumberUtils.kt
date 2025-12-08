package com.protip365.app.utils

import java.text.NumberFormat
import java.text.ParseException
import java.util.Locale

/**
 * Converts a string to Double with locale-aware decimal separator handling
 * Accepts both "." (English) and "," (French, Spanish) as decimal separators
 *
 * Examples:
 * - "10.50" → 10.5
 * - "10,50" → 10.5
 * - "10" → 10.0
 * - "invalid" → null
 */
fun String.toLocaleDouble(): Double? {
    if (this.isBlank()) return null

    // First, try direct conversion (works for English "10.50")
    this.toDoubleOrNull()?.let { return it }

    // If that fails, try replacing comma with period (French/Spanish "10,50")
    val normalizedString = this.replace(',', '.')
    normalizedString.toDoubleOrNull()?.let { return it }

    // As a fallback, try using NumberFormat with current locale
    return try {
        val format = NumberFormat.getInstance(Locale.getDefault())
        format.parse(this)?.toDouble()
    } catch (e: ParseException) {
        null
    }
}

/**
 * Converts a string to Double with locale-aware parsing, returns default value if parsing fails
 *
 * @param defaultValue The value to return if parsing fails (default: 0.0)
 */
fun String.toLocaleDoubleOrDefault(defaultValue: Double = 0.0): Double {
    return this.toLocaleDouble() ?: defaultValue
}

/**
 * Formats a Double to string with locale-aware decimal separator
 *
 * @param decimals Number of decimal places (default: 2)
 * @param useLocale Whether to use locale-specific separator (default: true)
 */
fun Double.toLocaleString(decimals: Int = 2, useLocale: Boolean = true): String {
    return if (useLocale) {
        val format = NumberFormat.getInstance(Locale.getDefault()).apply {
            minimumFractionDigits = decimals
            maximumFractionDigits = decimals
        }
        format.format(this)
    } else {
        String.format(Locale.US, "%.${decimals}f", this)
    }
}
