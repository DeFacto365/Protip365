# Per-Shift Sales Target - Android Implementation Guide

## Overview

This feature allows users to set custom sales targets for individual shifts that override the default sales target from settings. This is useful for special occasions like office parties, holidays, or other events where sales are expected to be higher than usual.

**iOS Source Files:**
- `/supabase/migrations/add_sales_target_to_expected_shifts.sql`
- `/ProTip365/Managers/Models.swift` (ExpectedShift model)
- `/ProTip365/AddShift/AddShiftLocalization.swift`
- `/ProTip365/AddShift/AddShiftDataManager.swift`
- `/ProTip365/AddShift/ShiftDetailsSection.swift`
- `/ProTip365/AddShift/AddShiftView.swift`

---

## 1. Database Migration

### SQL Migration

**File:** Create `/app/src/main/assets/migrations/add_sales_target_to_expected_shifts.sql`

```sql
-- Add sales_target column to expected_shifts table
-- This allows users to set custom sales targets for individual shifts
-- Defaults to NULL, which means use the default target from user settings

ALTER TABLE expected_shifts
ADD COLUMN IF NOT EXISTS sales_target DECIMAL(10,2) DEFAULT NULL;

COMMENT ON COLUMN expected_shifts.sales_target IS 'Custom sales target for this specific shift. NULL means use default target from user settings.';
```

**Execute via Supabase:**
```kotlin
// Run this migration through Supabase dashboard or via Kotlin:
suspend fun migrateSalesTarget() {
    val sql = """
        ALTER TABLE expected_shifts
        ADD COLUMN IF NOT EXISTS sales_target DECIMAL(10,2) DEFAULT NULL
    """.trimIndent()

    supabase.postgrest.rpc("execute_sql", parameters = buildJsonObject {
        put("query", sql)
    })
}
```

---

## 2. Data Model Updates

### ExpectedShift.kt

Add the `salesTarget` field to the ExpectedShift data class:

```kotlin
data class ExpectedShift(
    val id: UUID,
    val userId: UUID,
    val employerId: UUID?,

    // Scheduling information
    val shiftDate: String,  // yyyy-MM-dd format
    val startTime: String,  // HH:mm:ss format
    val endTime: String,    // HH:mm:ss format
    val expectedHours: Double,
    val hourlyRate: Double,

    // Break time
    val lunchBreakMinutes: Int,

    // Custom sales target (NEW)
    @SerializedName("sales_target")
    val salesTarget: Double? = null,  // NULL means use default from settings

    // Status and metadata
    val status: String,  // "planned", "completed", "missed"
    val alertMinutes: Int?,
    val notes: String?,

    val createdAt: Date,
    val updatedAt: Date
)
```

**Key Points:**
- `salesTarget` is nullable (`Double?`)
- `null` means use the default sales target from user settings
- Use `@SerializedName("sales_target")` for Supabase column mapping

---

## 3. Localization Strings

### AddShiftLocalization.kt

Add the following strings after the employer section:

```kotlin
fun salesTargetText(): String {
    return when (language) {
        "fr" -> "Objectif de ventes"
        "es" -> "Objetivo de ventas"
        else -> "Sales Target"
    }
}

fun useDefaultTargetText(): String {
    return when (language) {
        "fr" -> "Utiliser l'objectif par défaut"
        "es" -> "Usar objetivo predeterminado"
        else -> "Use Default Target"
    }
}

fun customTargetText(): String {
    return when (language) {
        "fr" -> "Objectif personnalisé"
        "es" -> "Objetivo personalizado"
        else -> "Custom Target"
    }
}
```

---

## 4. ViewModel Updates

### AddShiftViewModel.kt

Add state for sales target:

```kotlin
@Composable
fun AddShiftViewModel(
    editingShift: ShiftWithEntry? = null,
    initialDate: Date? = null
): AddShiftState {
    // Existing state...
    var selectedEmployer by remember { mutableStateOf<Employer?>(null) }
    var comments by remember { mutableStateOf("") }

    // NEW: Sales target state
    var salesTarget by remember { mutableStateOf("") }  // Empty string means use default

    // Get default sales target from settings
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE) }
    val defaultDailySalesTarget by remember {
        mutableStateOf(prefs.getFloat("dailySales", 0f).toDouble())
    }

    // Initialize from editing shift
    LaunchedEffect(editingShift) {
        editingShift?.let { shift ->
            selectedEmployer = getEmployerById(shift.employerId)
            comments = shift.expectedShift.notes ?: ""

            // Initialize sales target (custom or empty for default)
            salesTarget = shift.expectedShift.salesTarget?.let {
                String.format("%.0f", it)
            } ?: ""
        }
    }

    // ... rest of ViewModel
}
```

---

## 5. UI Component

### ShiftDetailsSection.kt

Add the sales target field after the employer picker:

```kotlin
@Composable
fun ShiftDetailsSection(
    selectedEmployer: Employer?,
    onEmployerChange: (Employer?) -> Unit,
    comments: String,
    onCommentsChange: (String) -> Unit,
    salesTarget: String,  // NEW
    onSalesTargetChange: (String) -> Unit,  // NEW
    defaultSalesTarget: Double,  // NEW
    localization: AddShiftLocalization,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Employer Picker (existing)
        EmployerPickerRow(
            selectedEmployer = selectedEmployer,
            onEmployerChange = onEmployerChange,
            localization = localization
        )

        Divider()

        // Sales Target Row (NEW)
        Column(
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = localization.salesTargetText(),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            OutlinedTextField(
                value = salesTarget,
                onValueChange = onSalesTargetChange,
                modifier = Modifier.fillMaxWidth(),
                placeholder = {
                    Text(
                        text = if (defaultSalesTarget > 0) {
                            String.format("%.0f", defaultSalesTarget)
                        } else {
                            "0"
                        }
                    )
                },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal
                ),
                singleLine = true
            )

            // Helper text
            if (salesTarget.isEmpty() && defaultSalesTarget > 0) {
                Text(
                    text = String.format(
                        "%s: $%.0f",
                        localization.useDefaultTargetText(),
                        defaultSalesTarget
                    ),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else if (salesTarget.isEmpty()) {
                Text(
                    text = localization.useDefaultTargetText(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Divider()

        // Comments Field (existing)
        CommentsField(
            comments = comments,
            onCommentsChange = onCommentsChange,
            localization = localization
        )
    }
}
```

---

## 6. Save Logic

### AddShiftViewModel.kt - Save Function

Update the save function to include `salesTarget`:

```kotlin
suspend fun saveShift(
    selectedEmployer: Employer?,
    selectedDate: Date,
    startTime: Date,
    endTime: Date,
    lunchBreakMinutes: Int,
    salesTarget: String,  // NEW
    comments: String,
    alertMinutes: Int?,
    editingShift: ShiftWithEntry? = null
): Result<Unit> {
    try {
        val userId = supabase.auth.currentUserOrNull()?.id ?: return Result.failure(
            Exception("User not authenticated")
        )

        // Parse custom sales target (empty string means use default)
        val customSalesTarget = if (salesTarget.isEmpty()) {
            null
        } else {
            salesTarget.toDoubleOrNull()
        }

        val dateFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val timeFormatter = SimpleDateFormat("HH:mm:ss", Locale.US)

        if (editingShift != null) {
            // Update existing shift
            val updatedShift = ExpectedShift(
                id = editingShift.id,
                userId = userId,
                employerId = selectedEmployer?.id,
                shiftDate = dateFormatter.format(selectedDate),
                startTime = timeFormatter.format(startTime),
                endTime = timeFormatter.format(endTime),
                expectedHours = calculateExpectedHours(startTime, endTime, lunchBreakMinutes),
                hourlyRate = selectedEmployer?.hourlyRate ?: 0.0,
                lunchBreakMinutes = lunchBreakMinutes,
                salesTarget = customSalesTarget,  // NEW
                status = editingShift.expectedShift.status,
                alertMinutes = alertMinutes,
                notes = if (comments.isEmpty()) null else comments,
                createdAt = editingShift.expectedShift.createdAt,
                updatedAt = Date()
            )

            supabase.postgrest["expected_shifts"]
                .update(updatedShift)
                .eq("id", editingShift.id)
                .execute()

        } else {
            // Create new shift
            val shiftStatus = if (selectedDate >= Date()) "planned" else "completed"

            val newShift = ExpectedShift(
                id = UUID.randomUUID(),
                userId = userId,
                employerId = selectedEmployer?.id,
                shiftDate = dateFormatter.format(selectedDate),
                startTime = timeFormatter.format(startTime),
                endTime = timeFormatter.format(endTime),
                expectedHours = calculateExpectedHours(startTime, endTime, lunchBreakMinutes),
                hourlyRate = selectedEmployer?.hourlyRate ?: 0.0,
                lunchBreakMinutes = lunchBreakMinutes,
                salesTarget = customSalesTarget,  // NEW
                status = shiftStatus,
                alertMinutes = alertMinutes,
                notes = if (comments.isEmpty()) null else comments,
                createdAt = Date(),
                updatedAt = Date()
            )

            supabase.postgrest["expected_shifts"]
                .insert(newShift)
                .execute()
        }

        return Result.success(Unit)
    } catch (e: Exception) {
        return Result.failure(e)
    }
}
```

---

## 7. Performance Calculation Updates

### DashboardViewModel.kt

Update performance calculation to use shift-specific targets:

```kotlin
private fun calculateDailyPerformance(
    shifts: List<ShiftIncome>,
    userTargets: UserTargets
): PerformanceMetrics {
    val totalSales = shifts.sumOf { it.sales ?: 0.0 }

    // Calculate target: use shift-specific targets if set, otherwise use default
    val salesTarget = shifts
        .mapNotNull { it.salesTarget }  // Get custom targets
        .sum()
        .let { customTargetSum ->
            if (customTargetSum > 0) {
                customTargetSum
            } else {
                // No custom targets set, use default for number of shifts
                userTargets.dailySales * shifts.size
            }
        }

    val salesPerformance = if (salesTarget > 0) {
        (totalSales / salesTarget) * 100
    } else {
        0.0
    }

    return PerformanceMetrics(
        sales = totalSales,
        salesTarget = salesTarget,
        salesPerformance = salesPerformance
        // ... other metrics
    )
}
```

**Important:** This logic should be applied to:
- Daily performance calculation
- Weekly performance calculation
- Monthly performance calculation
- Dashboard Performance Card

**Formula:**
1. If ANY shift has a custom `sales_target` set, sum all custom targets
2. For shifts without a custom target, use `0` (or proportional default)
3. If NO shifts have custom targets, use `default_target * number_of_shifts`

---

## 8. Testing Checklist

### UI Tests
- [ ] Sales target field appears after employer picker
- [ ] Placeholder shows default target value
- [ ] Empty field uses default target (indicated by helper text)
- [ ] Custom value overrides default
- [ ] Field accepts decimal input
- [ ] Field value persists when editing shift

### Data Tests
- [ ] NULL sales_target saves correctly (uses default)
- [ ] Custom sales_target saves correctly
- [ ] Editing preserves existing sales_target
- [ ] Database migration runs without errors
- [ ] Existing shifts have NULL sales_target (default behavior)

### Performance Tests
- [ ] Performance card uses custom target when set
- [ ] Performance card uses default target when NULL
- [ ] Mixed shifts (some custom, some default) calculate correctly
- [ ] Weekly/monthly aggregation works correctly

### Localization Tests
- [ ] "Sales Target" translates (EN/FR/ES)
- [ ] "Use Default Target" translates
- [ ] Helper text displays correctly in all languages

---

## 9. Use Case Examples

### Example 1: Regular Shift (Use Default)
```
User Settings:
- Daily Sales Target: $500

Add Shift:
- Employer: Restaurant ABC
- Date: Oct 10, 2025
- Sales Target: [empty] <- Uses default $500
```

**Database:**
```sql
INSERT INTO expected_shifts (..., sales_target) VALUES (..., NULL);
```

**Performance Calculation:**
```kotlin
val target = shift.salesTarget ?: userTargets.dailySales  // $500
```

### Example 2: Special Event (Custom Target)
```
User Settings:
- Daily Sales Target: $500

Add Shift:
- Employer: Restaurant ABC
- Date: Oct 10, 2025 (Office Party!)
- Sales Target: 1500 <- Custom target
```

**Database:**
```sql
INSERT INTO expected_shifts (..., sales_target) VALUES (..., 1500.00);
```

**Performance Calculation:**
```kotlin
val target = shift.salesTarget ?: userTargets.dailySales  // $1500
```

### Example 3: Weekly View with Mixed Targets
```
Monday: Regular shift, no custom target -> use default $500
Tuesday: Regular shift, no custom target -> use default $500
Wednesday: Office party, custom target $1500
Thursday: Regular shift, no custom target -> use default $500
Friday: Happy hour event, custom target $800

Weekly Sales Target = $500 + $500 + $1500 + $500 + $800 = $3800
```

---

## 10. Migration Path for Existing Data

All existing shifts will have `sales_target = NULL`, which automatically means "use default target from settings". No data migration required.

**Verification Query:**
```sql
-- Check existing shifts (should all be NULL initially)
SELECT COUNT(*)
FROM expected_shifts
WHERE sales_target IS NOT NULL;  -- Should return 0 initially

-- Check custom targets after feature rollout
SELECT shift_date, sales_target, sales
FROM expected_shifts
WHERE sales_target IS NOT NULL
ORDER BY shift_date DESC;
```

---

## Summary

✅ **Feature Implementation:**
- Database field added to `expected_shifts` table
- UI field added to Add/Edit Shift screen
- Localization support for EN/FR/ES
- Save/load logic implemented
- Performance calculation updated

✅ **User Experience:**
- Default behavior: Empty field = use default target
- Custom behavior: Enter value = override for this shift only
- Clear visual feedback with helper text
- Seamless integration with existing workflow

✅ **Data Integrity:**
- NULL-safe implementation
- Backward compatible with existing shifts
- No breaking changes to existing functionality

**Critical Success Factor:** The feature gracefully handles NULL values (default behavior) and custom values (override behavior) without breaking existing functionality.
