# Income Snapshot Fields - Implementation Guide

## Problem
When hourly rates or deduction percentages change in user settings, historical shift entries would display incorrect financial data because they were recalculating values using current rates instead of the rates at the time of entry.

## Solution
Add snapshot fields to `shift_entries` table to preserve the exact financial state at the time of entry creation.

## Database Changes ✅ COMPLETED

### New Fields in `shift_entries` table:
- `hourly_rate` DECIMAL(10,2) - Snapshot of hourly rate at time of entry
- `gross_income` DECIMAL(10,2) - Calculated: actual_hours × hourly_rate
- `total_income` DECIMAL(10,2) - Calculated: gross_income + tips + other - cash_out
- `net_income` DECIMAL(10,2) - Calculated: total_income × (1 - deduction_percentage/100)
- `deduction_percentage` DECIMAL(5,2) - Snapshot of tax/deduction percentage

## iOS Implementation ✅ COMPLETED

### Files Modified:
1. **Models.swift** - Added 5 optional fields to `ShiftEntry` struct
2. **AddEntryModels.swift** - Added fields to `IncomeInsert` and `IncomeUpdate`
3. **AddEntryView.swift** - Calculates and saves snapshot values when creating/updating entries

### Calculation Logic:
```swift
let hourlyRate = employer?.hourly_rate ?? defaultRate
let grossIncome = actual_hours × hourlyRate
let totalIncome = grossIncome + tips + other - cash_out
let deductionPct = UserDefaults.standard.double(forKey: "averageDeductionPercentage")
let netIncome = totalIncome × (1 - deductionPct/100)
```

## Android Implementation 🔴 TODO

### Files to Modify:

#### 1. Data Models
**File:** `ProTip365Android/app/src/main/java/com/protip365/app/data/models/ShiftEntry.kt`

```kotlin
data class ShiftEntry(
    val id: String,
    val shift_id: String,
    val user_id: String,
    val actual_start_time: String,
    val actual_end_time: String,
    val actual_hours: Double,
    val sales: Double,
    val tips: Double,
    val cash_out: Double,
    val other: Double,

    // ADD THESE SNAPSHOT FIELDS:
    val hourly_rate: Double? = null,
    val gross_income: Double? = null,
    val total_income: Double? = null,
    val net_income: Double? = null,
    val deduction_percentage: Double? = null,

    val notes: String? = null,
    val created_at: String,
    val updated_at: String
)
```

#### 2. Repository Implementation
**File:** `ProTip365Android/app/src/main/java/com/protip365/app/data/repository/ShiftEntryRepositoryImpl.kt`

When creating or updating shift entries, calculate snapshot values:

```kotlin
suspend fun createShiftEntry(
    shiftId: String,
    actualHours: Double,
    sales: Double,
    tips: Double,
    cashOut: Double,
    other: Double,
    hourlyRate: Double,
    deductionPercentage: Double,
    notes: String? = null
): Result<ShiftEntry> {
    return try {
        // Calculate snapshot values
        val grossIncome = actualHours * hourlyRate
        val totalIncome = grossIncome + tips + other - cashOut
        val netIncome = totalIncome * (1.0 - deductionPercentage / 100.0)

        val entry = mapOf(
            "shift_id" to shiftId,
            "user_id" to auth.currentUserOrNull()?.id,
            "actual_start_time" to actualStartTime,
            "actual_end_time" to actualEndTime,
            "actual_hours" to actualHours,
            "sales" to sales,
            "tips" to tips,
            "cash_out" to cashOut,
            "other" to other,

            // Save snapshots
            "hourly_rate" to hourlyRate,
            "gross_income" to grossIncome,
            "total_income" to totalIncome,
            "net_income" to netIncome,
            "deduction_percentage" to deductionPercentage,

            "notes" to notes
        )

        val result = supabase.postgrest["shift_entries"]
            .insert(entry)
            .decodeSingle<ShiftEntry>()

        Result.success(result)
    } catch (e: Exception) {
        Result.failure(e)
    }
}
```

#### 3. ViewModel Updates
**File:** `ProTip365Android/app/src/main/java/com/protip365/app/presentation/shifts/AddEditShiftViewModel.kt`

When saving entry, get current values:
```kotlin
fun saveShiftEntry() {
    viewModelScope.launch {
        // Get current hourly rate from selected employer
        val hourlyRate = selectedEmployer.value?.hourlyRate ?: defaultHourlyRate

        // Get current deduction percentage from preferences
        val deductionPct = preferencesManager.getAverageDeductionPercentage() ?: 30.0

        shiftEntryRepository.createShiftEntry(
            shiftId = shiftId,
            actualHours = actualHours,
            sales = sales,
            tips = tips,
            cashOut = cashOut,
            other = other,
            hourlyRate = hourlyRate,  // Pass snapshot value
            deductionPercentage = deductionPct,  // Pass snapshot value
            notes = notes
        )
    }
}
```

#### 4. Display Updates
When displaying historical entries, use snapshot values if available, otherwise recalculate:

```kotlin
// In UI composables or ViewModels
fun getGrossIncome(entry: ShiftEntry, employer: Employer?): Double {
    // Prefer snapshot value (preserves historical accuracy)
    return entry.gross_income ?: run {
        // Fallback to calculation for old entries without snapshots
        val rate = employer?.hourly_rate ?: 15.0
        entry.actual_hours * rate
    }
}

fun getNetIncome(entry: ShiftEntry): Double {
    // Prefer snapshot value
    return entry.net_income ?: run {
        // Fallback calculation for old entries
        val total = getTotalIncome(entry)
        total * 0.7 // Assume 30% deduction
    }
}
```

## Testing Checklist

### iOS ✅
- [x] Database migration ran successfully
- [x] New entries save all 5 snapshot fields
- [x] Existing entries backfilled with calculated values
- [x] Changing hourly rate doesn't affect historical entries
- [x] Changing deduction % doesn't affect historical entries

### Android 🔴
- [ ] Update ShiftEntry data model with 5 new optional fields
- [ ] Update repository to calculate and save snapshot values
- [ ] Update ViewModel to pass hourly rate and deduction % when saving
- [ ] Test: Create entry with $10/hr and 50% deduction
- [ ] Test: Change employer rate to $15/hr
- [ ] Test: Verify old entry still shows $10/hr gross income
- [ ] Test: Change deduction to 40%
- [ ] Test: Verify old entry still shows net based on 50%
- [ ] Test: New entries use current rates

## Migration Notes

- All new fields are **nullable/optional** for backward compatibility
- Existing entries were backfilled assuming 30% deduction
- iOS reads from UserDefaults `averageDeductionPercentage` key
- Android should read from PreferencesManager
- Snapshot values are calculated ONCE when entry is created/updated
- Display logic should prefer snapshot values over recalculation
