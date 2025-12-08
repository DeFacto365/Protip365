# Android Locale-Aware Decimal Input Implementation

## Overview

This guide implements the same locale-aware decimal parsing for Android that was implemented for iOS in v1.1.36. The issue affects French and Spanish users who have keyboards with comma (,) as the decimal separator, but the app only accepts period (.) for decimal input.

---

## The Problem

### Current Issue

**French/Spanish users cannot enter decimal values:**
- Android keyboard shows **comma (,)** as decimal separator for French/Spanish locales
- Kotlin's `String.toDoubleOrNull()` only accepts **period (.)** as decimal separator
- When user types "10,50" → parsing fails → defaults to 0 or error
- Affects all money/earnings input fields

### Impact

Users in France, Spain, Quebec, and other French/Spanish regions:
- ❌ Cannot enter tips with decimals
- ❌ Cannot enter sales amounts properly
- ❌ Cannot enter hourly rates with cents
- ❌ Calculator doesn't work with comma input

---

## Solution Overview

Create a **locale-aware decimal parser** extension function that:
1. Accepts both "." (English) and "," (French/Spanish) as valid decimal separators
2. Normalizes input before parsing
3. Falls back to NumberFormat for edge cases
4. Works seamlessly across all locales

---

## Implementation Steps

### Step 1: Create String Extension Utility

**File:** `/app/src/main/java/com/protip365/app/utils/NumberUtils.kt`

Create this new file:

```kotlin
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
```

---

### Step 2: Update Entry Input Fields

**File:** `/app/src/main/java/com/protip365/app/presentation/entries/AddEditEntryViewModel.kt`

Find all instances of `String.toDoubleOrNull()` or `String.toDouble()` and replace with `String.toLocaleDouble()`.

**Example - Before:**
```kotlin
val sales = salesText.toDoubleOrNull() ?: 0.0
val tips = tipsText.toDoubleOrNull() ?: 0.0
val tipOut = tipOutText.toDoubleOrNull() ?: 0.0
val other = otherText.toDoubleOrNull() ?: 0.0
```

**Example - After:**
```kotlin
import com.protip365.app.utils.toLocaleDouble

val sales = salesText.toLocaleDouble() ?: 0.0
val tips = tipsText.toLocaleDouble() ?: 0.0
val tipOut = tipOutText.toLocaleDouble() ?: 0.0
val other = otherText.toLocaleDouble() ?: 0.0
```

---

### Step 3: Update Entry Screen UI

**File:** `/app/src/main/java/com/protip365/app/presentation/entries/AddEditEntryScreen.kt`

Update TextField configuration to allow comma input:

**Before:**
```kotlin
TextField(
    value = sales,
    onValueChange = { viewModel.updateSales(it) },
    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
)
```

**After:**
```kotlin
TextField(
    value = sales,
    onValueChange = { viewModel.updateSales(it) },
    keyboardOptions = KeyboardOptions(
        keyboardType = KeyboardType.Decimal,
        imeAction = ImeAction.Next
    ),
    // Allow both comma and period
    visualTransformation = VisualTransformation.None
)
```

---

### Step 4: Update All Affected Files

Apply the same changes to these files:

#### 1. Shift Entry ViewModel
**File:** `/app/src/main/java/com/protip365/app/presentation/entries/AddEditEntryViewModel.kt`

```kotlin
import com.protip365.app.utils.toLocaleDouble

// Replace all occurrences:
// Before: value.toDoubleOrNull()
// After: value.toLocaleDouble()
```

#### 2. Work Defaults (Hourly Rate)
**File:** `/app/src/main/java/com/protip365/app/presentation/settings/WorkDefaultsSection.kt`

```kotlin
import com.protip365.app.utils.toLocaleDouble

// Hourly rate input
val hourlyRate = hourlyRateText.toLocaleDouble() ?: 15.0
```

#### 3. Tip Calculator
**File:** `/app/src/main/java/com/protip365/app/presentation/calculator/TipCalculatorScreen.kt`

```kotlin
import com.protip365.app.utils.toLocaleDouble

// Bill amount, tip percentage calculations
val billAmount = billText.toLocaleDouble() ?: 0.0
val tipPercent = tipPercentText.toLocaleDouble() ?: 0.0
```

#### 4. Employer Setup (Hourly Rate)
**File:** `/app/src/main/java/com/protip365/app/presentation/employers/EmployersScreen.kt`

```kotlin
import com.protip365.app.utils.toLocaleDouble

val hourlyRate = hourlyRateText.toLocaleDouble() ?: 15.0
```

#### 5. Targets Settings
**File:** `/app/src/main/java/com/protip365/app/presentation/settings/TargetsScreen.kt`

```kotlin
import com.protip365.app.utils.toLocaleDouble

// Daily, weekly, monthly targets
val dailyTarget = dailyTargetText.toLocaleDouble() ?: 0.0
val weeklyTarget = weeklyTargetText.toLocaleDouble() ?: 0.0
val monthlyTarget = monthlyTargetText.toLocaleDouble() ?: 0.0
```

---

### Step 5: Update TextField Input Validation

For all money input fields, ensure proper validation:

**Example TextField Composable:**

```kotlin
@Composable
fun CurrencyTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorMessage: String? = null
) {
    OutlinedTextField(
        value = value,
        onValueChange = { newValue ->
            // Only allow numbers, comma, and period
            if (newValue.matches(Regex("^[0-9]*[.,]?[0-9]*$"))) {
                onValueChange(newValue)
            }
        },
        label = { Text(label) },
        leadingIcon = { Text("$") },
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Decimal,
            imeAction = ImeAction.Next
        ),
        singleLine = true,
        isError = isError,
        supportingText = if (isError && errorMessage != null) {
            { Text(errorMessage) }
        } else null,
        modifier = modifier
    )
}
```

**Usage:**
```kotlin
CurrencyTextField(
    value = tipsText,
    onValueChange = { viewModel.updateTips(it) },
    label = stringResource(R.string.tips),
    modifier = Modifier.fillMaxWidth()
)
```

---

### Step 6: Update Display Formatting

For displaying currency values, ensure they use locale formatting:

**File:** Anywhere displaying currency

**Before:**
```kotlin
Text("$%.2f".format(amount))
```

**After:**
```kotlin
import com.protip365.app.utils.toLocaleString

Text("$${amount.toLocaleString(decimals = 2, useLocale = false)}")
// useLocale = false keeps period for display consistency
// useLocale = true would show comma for French users
```

---

## Testing Checklist

### Test on Different Locales

#### English Locale (en-US)
- [ ] Input "10.50" → Displays 10.50 ✅
- [ ] Input "25.00" → Displays 25.00 ✅
- [ ] Calculator works with period ✅

#### French Locale (fr-FR)
- [ ] Keyboard shows comma ✅
- [ ] Input "10,50" → Parses to 10.50 ✅
- [ ] Input "25,75" → Parses to 25.75 ✅
- [ ] Can also input "10.50" (works both ways) ✅

#### Spanish Locale (es-ES)
- [ ] Keyboard shows comma ✅
- [ ] Input "15,25" → Parses to 15.25 ✅
- [ ] Input "30,00" → Parses to 30.00 ✅

### Test All Input Fields

- [ ] Tips input
- [ ] Sales input
- [ ] Tip Out input
- [ ] Other earnings input
- [ ] Hourly rate input (Work Defaults)
- [ ] Hourly rate input (Employer setup)
- [ ] Tip calculator
- [ ] Target amounts (Daily/Weekly/Monthly)

### Edge Cases

- [ ] Empty string → 0.0
- [ ] "0" → 0.0
- [ ] "0.00" → 0.0
- [ ] "0,00" → 0.0
- [ ] "." alone → null (handled)
- [ ] "," alone → null (handled)
- [ ] "10." → 10.0
- [ ] "10," → 10.0
- [ ] Multiple decimals "10.50.25" → null (rejected by validation)
- [ ] Letters "abc" → null

---

## File Summary

### Files to Create
1. `/app/src/main/java/com/protip365/app/utils/NumberUtils.kt` ✅ NEW

### Files to Modify
1. `/app/src/main/java/com/protip365/app/presentation/entries/AddEditEntryViewModel.kt`
2. `/app/src/main/java/com/protip365/app/presentation/entries/AddEditEntryScreen.kt`
3. `/app/src/main/java/com/protip365/app/presentation/settings/WorkDefaultsSection.kt`
4. `/app/src/main/java/com/protip365/app/presentation/calculator/TipCalculatorScreen.kt`
5. `/app/src/main/java/com/protip365/app/presentation/calculator/CalculatorScreen.kt`
6. `/app/src/main/java/com/protip365/app/presentation/employers/EmployersScreen.kt`
7. `/app/src/main/java/com/protip365/app/presentation/settings/TargetsScreen.kt`

---

## Search and Replace Guide

To implement quickly, use Android Studio's "Replace in Path":

### Find:
```kotlin
\.toDoubleOrNull\(\)
```

### Replace with:
```kotlin
.toLocaleDouble()
```

### Settings:
- ✅ Regex enabled
- Scope: Project Files
- File mask: `*.kt`

**Then manually:**
1. Add import: `import com.protip365.app.utils.toLocaleDouble` to each file
2. Review each replacement to ensure context is correct

---

## Unit Tests

Create unit tests for the extension function:

**File:** `/app/src/test/java/com/protip365/app/utils/NumberUtilsTest.kt`

```kotlin
package com.protip365.app.utils

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Locale

class NumberUtilsTest {

    @Test
    fun `toLocaleDouble handles English format`() {
        assertEquals(10.5, "10.50".toLocaleDouble())
        assertEquals(25.0, "25.00".toLocaleDouble())
        assertEquals(100.99, "100.99".toLocaleDouble())
    }

    @Test
    fun `toLocaleDouble handles French format`() {
        assertEquals(10.5, "10,50".toLocaleDouble())
        assertEquals(25.0, "25,00".toLocaleDouble())
        assertEquals(100.99, "100,99".toLocaleDouble())
    }

    @Test
    fun `toLocaleDouble handles integers`() {
        assertEquals(10.0, "10".toLocaleDouble())
        assertEquals(0.0, "0".toLocaleDouble())
    }

    @Test
    fun `toLocaleDouble handles edge cases`() {
        assertEquals(10.0, "10.".toLocaleDouble())
        assertEquals(10.0, "10,".toLocaleDouble())
        assertNull("".toLocaleDouble())
        assertNull("abc".toLocaleDouble())
        assertNull("10.50.25".toLocaleDouble())
    }

    @Test
    fun `toLocaleDoubleOrDefault returns default on failure`() {
        assertEquals(0.0, "invalid".toLocaleDoubleOrDefault(), 0.001)
        assertEquals(15.0, "invalid".toLocaleDoubleOrDefault(15.0), 0.001)
    }

    @Test
    fun `toLocaleString formats correctly`() {
        assertEquals("10.50", 10.5.toLocaleString(decimals = 2, useLocale = false))
        assertEquals("25.00", 25.0.toLocaleString(decimals = 2, useLocale = false))
    }
}
```

---

## iOS vs Android Comparison

| Aspect | iOS (Swift) | Android (Kotlin) |
|--------|-------------|------------------|
| **Extension Function** | `String.toLocaleDouble()` | `String.toLocaleDouble()` |
| **Location** | `Constants.swift` | `NumberUtils.kt` |
| **Native Parser** | `Double(String)` | `String.toDoubleOrNull()` |
| **Fallback** | `NumberFormatter` | `NumberFormat.getInstance()` |
| **Implementation** | v1.1.36 ✅ | This guide |

---

## Benefits

### User Experience
- ✅ French users can enter decimals naturally with comma
- ✅ Spanish users can enter decimals naturally with comma
- ✅ English users continue to use period
- ✅ No error messages or confusion
- ✅ Consistent behavior across iOS and Android

### Technical
- ✅ Simple, reusable extension function
- ✅ No UI changes required (TextField already shows correct keyboard)
- ✅ Backward compatible (period still works everywhere)
- ✅ Easy to test
- ✅ Minimal code changes

---

## Troubleshooting

### Issue: Keyboard still shows only period

**Solution:** This is device-specific. The keyboard is determined by:
1. Android system locale
2. Device keyboard app settings
3. Input method (Gboard, SwiftKey, etc.)

User must set device language to French/Spanish for comma keyboard.

### Issue: NumberFormat.getInstance() throws exception

**Solution:** Wrap in try-catch (already included in implementation).

### Issue: Still not parsing comma

**Debug steps:**
1. Check import: `import com.protip365.app.utils.toLocaleDouble`
2. Verify function is being called: Add log statement
3. Check input validation isn't blocking comma
4. Test with unit tests

---

## Deployment Notes

### Version
- **Android version:** TBD (next release after iOS v1.1.36)
- **Priority:** High (affects French/Spanish users)

### Rollout Strategy
1. Implement all changes
2. Test on French/Spanish locale devices
3. Deploy to internal testing
4. Deploy to Google Play Beta
5. Monitor for issues
6. Promote to production

### Release Notes (French)
```
Version X.X.X:
• Correction : Support de la virgule pour la saisie des montants décimaux
• Les utilisateurs français peuvent maintenant saisir "10,50" au lieu de "10.50"
```

### Release Notes (Spanish)
```
Versión X.X.X:
• Corrección: Soporte de coma para entrada de cantidades decimales
• Los usuarios españoles ahora pueden ingresar "10,50" en lugar de "10.50"
```

---

## Summary

**Implementation Time:** ~2-3 hours

**Files to Change:** 8 files
- 1 new utility file
- 7 existing files to update

**Testing Time:** ~1 hour

**Total Effort:** ~4 hours

**Impact:** High - fixes critical issue for French/Spanish users

---

**Status:** Ready for implementation
**iOS Version:** v1.1.36 (completed)
**Android Version:** Pending implementation
**Last Updated:** 2025-10-02
