# Android Implementation Guide: Onboarding Completion Flag

## Overview
This guide documents the fix for the onboarding detection bug where existing users were being shown the onboarding guide after app updates. The solution adds an explicit `onboarding_completed` flag instead of inferring completion from other fields.

## Changes Summary

### 1. Database Migration
### 2. Android Model Updates
### 3. ContentView/Main Activity Logic Updates
### 4. **CRITICAL: Subscription View Fix** ⚠️
### 5. Add Entry Calculation Fix

---

## 1. Database Migration

### File: `supabase/migrations/add_onboarding_completed_flag.sql`

**Status**: ✅ Already executed by user

```sql
-- Add onboarding_completed flag to users_profile table
ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;

-- Add comment to explain the field
COMMENT ON COLUMN users_profile.onboarding_completed IS 'Indicates whether the user has completed the initial onboarding flow';

-- Backfill existing users: Mark as completed if they have tip targets set
UPDATE users_profile
SET onboarding_completed = true
WHERE tip_target_percentage IS NOT NULL
  AND tip_target_percentage > 0
  AND target_sales_daily IS NOT NULL
  AND target_hours_daily IS NOT NULL;
```

**Why this change?**
- Previously, app inferred onboarding completion from `tip_target_percentage`, `target_sales_daily`, and `target_hours_daily`
- Bug: If user legitimately set tip target to 0%, the check `tip_target_percentage == 0` would incorrectly trigger onboarding
- Solution: Explicit boolean flag provides single source of truth

---

## 2. Android Model Updates

### 2.1. Update UserProfile Model

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/data/models/UserProfile.kt`

**Current Code**:
```kotlin
data class UserProfile(
    val user_id: String,
    val default_hourly_rate: Double,
    val week_start: Int,
    val tip_target_percentage: Double?,
    val name: String?,
    val default_employer_id: String?,
    val default_alert_minutes: Int?
)
```

**Add this field**:
```kotlin
data class UserProfile(
    val user_id: String,
    val default_hourly_rate: Double,
    val week_start: Int,
    val tip_target_percentage: Double?,
    val name: String?,
    val default_employer_id: String?,
    val default_alert_minutes: Int?,
    val onboarding_completed: Boolean? = false  // NEW FIELD
)
```

### 2.2. Update OnboardingProfileUpdate Model

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/presentation/onboarding/OnboardingModels.kt` (or wherever your update model is defined)

**Add to OnboardingProfileUpdate data class**:
```kotlin
data class OnboardingProfileUpdate(
    val preferred_language: String,
    val name: String?,
    val use_multiple_employers: Boolean,
    val week_start: Int,
    val has_variable_schedule: Boolean,
    val tip_target_percentage: Double,
    val target_sales_daily: Double,
    val target_sales_weekly: Double,
    val target_sales_monthly: Double,
    val target_hours_daily: Double,
    val target_hours_weekly: Double,
    val target_hours_monthly: Double,
    val average_deduction_percentage: Double,
    val default_employer_id: String?,
    val onboarding_completed: Boolean = true  // NEW FIELD - always true when finishing onboarding
)
```

---

## 3. Main Activity / Auth Check Updates

### 3.1. Update Onboarding Check Logic

**File**: Wherever you check if user needs onboarding (likely in `MainActivity.kt` or `AuthViewModel.kt`)

**OLD LOGIC (REMOVE THIS)**:
```kotlin
// ❌ OLD - Inference based (buggy)
suspend fun checkIfOnboardingNeeded(userId: String): Boolean {
    val profile = supabaseClient
        .from("users_profile")
        .select {
            filter {
                eq("user_id", userId)
            }
        }
        .decodeSingle<UserProfile>()

    // Bug: This will show onboarding if tip_target is 0%
    val needsOnboarding = profile.tip_target_percentage == null ||
                         profile.tip_target_percentage == 0.0 ||
                         profile.target_sales_daily == null ||
                         profile.target_hours_daily == null

    return needsOnboarding
}
```

**NEW LOGIC (USE THIS)**:
```kotlin
// ✅ NEW - Explicit flag
suspend fun checkIfOnboardingNeeded(userId: String): Boolean {
    val response = supabaseClient
        .from("users_profile")
        .select(columns = Columns.list("onboarding_completed")) {
            filter {
                eq("user_id", userId)
            }
        }
        .decodeSingle<OnboardingCheck>()

    return !(response.onboarding_completed ?: false)
}

// Add this data class
data class OnboardingCheck(
    val onboarding_completed: Boolean? = false
)
```

### 3.2. Update Onboarding Completion

**File**: `OnboardingViewModel.kt` or `OnboardingScreen.kt` (wherever you finish onboarding)

**Find the function that saves onboarding data** (probably called `finishOnboarding()` or similar)

**Add `onboarding_completed = true` to the update**:
```kotlin
suspend fun finishOnboarding() {
    isLoading = true

    try {
        val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return

        // Save single employer if not using multiple employers
        if (!useMultipleEmployers && singleEmployerName.isNotBlank()) {
            // ... employer creation code ...
        }

        val updates = OnboardingProfileUpdate(
            preferred_language = selectedLanguage,
            name = null, // Keep the name from signup
            use_multiple_employers = useMultipleEmployers,
            week_start = weekStartDay,
            has_variable_schedule = hasVariableSchedule,
            tip_target_percentage = tipTargetPercentage.toDoubleOrNull() ?: 15.0,
            target_sales_daily = targetSalesDaily.toDoubleOrNull() ?: 0.0,
            target_sales_weekly = if (hasVariableSchedule) 0.0 else (targetSalesWeekly.toDoubleOrNull() ?: 0.0),
            target_sales_monthly = if (hasVariableSchedule) 0.0 else (targetSalesMonthly.toDoubleOrNull() ?: 0.0),
            target_hours_daily = targetHoursDaily.toDoubleOrNull() ?: 0.0,
            target_hours_weekly = if (hasVariableSchedule) 0.0 else (targetHoursWeekly.toDoubleOrNull() ?: 0.0),
            target_hours_monthly = if (hasVariableSchedule) 0.0 else (targetHoursMonthly.toDoubleOrNull() ?: 0.0),
            average_deduction_percentage = averageDeductionPercentage.toDoubleOrNull() ?: 30.0,
            default_employer_id = defaultEmployerId?.toString(),
            onboarding_completed = true  // ⭐ NEW FIELD - Mark onboarding as complete
        )

        supabaseClient
            .from("users_profile")
            .update(updates) {
                filter {
                    eq("user_id", userId)
                }
            }

        // Set security type if not none
        if (selectedSecurityType != SecurityType.NONE) {
            securityManager.setSecurityType(selectedSecurityType)
        }

        // Update preferences
        preferencesManager.setUseMultipleEmployers(useMultipleEmployers)
        preferencesManager.setHasVariableSchedule(hasVariableSchedule)

        showOnboarding = false
        isLoading = false

    } catch (e: Exception) {
        errorMessage = e.localizedMessage ?: "Failed to save onboarding"
        showError = true
        isLoading = false
    }
}
```

---

## 4. CRITICAL: Subscription View Fix ⚠️

### **THE ROOT CAUSE BUG**
This was the actual bug causing existing users to see onboarding! The SubscriptionView was **unconditionally setting `showOnboarding = true`** after successful subscription, completely ignoring the `onboarding_completed` flag.

### iOS Bug Location

**File**: `ProTip365/Subscription/SubscriptionView.swift`

**Lines 68-76 (BEFORE - BUGGY)**:
```swift
await subscriptionManager.purchase(productId: "com.protip365.premium.monthly")
await MainActor.run {
    isLoading = false
    // Show onboarding after successful subscription
    if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
        showOnboarding = true  // ❌ BUG: Always shows onboarding, ignoring completed status
    }
}
```

**Lines 68-99 (AFTER - FIXED)**:
```swift
await subscriptionManager.purchase(productId: "com.protip365.premium.monthly")
await MainActor.run {
    isLoading = false
    // Show onboarding after successful subscription ONLY if not already completed
    if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
        // Check if user has completed onboarding
        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                let response = try await SupabaseManager.shared.client
                    .from("users_profile")
                    .select("onboarding_completed")
                    .eq("user_id", value: userId)
                    .single()
                    .execute()

                let decoder = JSONDecoder()
                if let profileData = try? decoder.decode(OnboardingCheck.self, from: response.data) {
                    await MainActor.run {
                        showOnboarding = !(profileData.onboarding_completed ?? false)  // ✅ Respect flag
                    }
                }
            } catch {
                await MainActor.run {
                    showOnboarding = true  // Safe default for new users
                }
            }
        }
    }
}
```

### Android Implementation - Subscription Screen

**File to Update**: `SubscriptionScreen.kt` or wherever you handle subscription purchases

**Find code similar to this (BUGGY)**:
```kotlin
// ❌ WRONG - Always shows onboarding after subscription
lifecycleScope.launch {
    subscriptionManager.purchase(productId = "com.protip365.premium.monthly")

    withContext(Dispatchers.Main) {
        isLoading = false
        if (subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod) {
            showOnboarding = true  // BUG: Ignoring onboarding_completed flag
        }
    }
}
```

**Replace with (FIXED)**:
```kotlin
// ✅ CORRECT - Check onboarding_completed before showing onboarding
lifecycleScope.launch {
    subscriptionManager.purchase(productId = "com.protip365.premium.monthly")

    withContext(Dispatchers.Main) {
        isLoading = false
        if (subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod) {
            // Check if user has completed onboarding
            try {
                val userId = supabaseClient.auth.currentUserOrNull()?.id ?: return@withContext
                val response = supabaseClient
                    .from("users_profile")
                    .select(columns = Columns.list("onboarding_completed")) {
                        filter {
                            eq("user_id", userId)
                        }
                    }
                    .decodeSingle<OnboardingCheck>()

                showOnboarding = !(response.onboarding_completed ?: false)
            } catch (e: Exception) {
                // On error, show onboarding (safer default for new users)
                showOnboarding = true
            }
        }
    }
}
```

**Also add the OnboardingCheck data class**:
```kotlin
data class OnboardingCheck(
    val onboarding_completed: Boolean? = false
)
```

### Key Points for Android

1. **This is the CRITICAL fix** - Without this, existing users will ALWAYS see onboarding after any subscription flow
2. Check for this pattern in:
   - After successful purchase
   - After restoring purchases
   - Any "skip subscription" or test buttons in DEBUG builds
3. **Always** check `onboarding_completed` flag before setting `showOnboarding = true`
4. Only show onboarding if `onboarding_completed` is `false` or `null`

---

## 5. Add Entry Calculation Fix

### Issue
The "Avg Net" and "Gross" values shown under "Total Hours" were incorrectly including tips in the calculation. They should only show the hourly pay (hours × rate), not including tips, tip-out, or other income.

### File to Update
`ProTip365Android/app/src/main/java/com/protip365/app/presentation/shifts/AddEditShiftScreen.kt`
(or wherever you display the WorkInfoSection equivalent)

### iOS Reference (Fixed)

**File**: `ProTip365/AddEntry/WorkInfoSection.swift`

**Before (WRONG)**:
```swift
private var grossPay: Double {
    calculatedHours * (selectedEmployer?.hourly_rate ?? defaultHourlyRate)
}

private var expectedNetSalary: Double {
    let deductionMultiplier = 1.0 - (averageDeductionPercentage / 100.0)
    return totalEarnings * deductionMultiplier  // ❌ Using totalEarnings (includes tips)
}

// Display
Text("Avg Net $\(String(format: "%.0f", expectedNetSalary)) / Gross $\(String(format: "%.0f", totalEarnings))")
```

**After (CORRECT)**:
```swift
private var grossPay: Double {
    calculatedHours * (selectedEmployer?.hourly_rate ?? defaultHourlyRate)
}

private var netPay: Double {
    let deductionMultiplier = 1.0 - (averageDeductionPercentage / 100.0)
    return grossPay * deductionMultiplier  // ✅ Using only grossPay (hours × rate)
}

// Display
Text("Avg Net $\(String(format: "%.0f", netPay)) / Gross $\(String(format: "%.0f", grossPay))")
```

### Android Implementation

**Find the section that displays Total Hours with Avg Net / Gross**

**Current (probably wrong)**:
```kotlin
// ❌ WRONG - Including tips in calculation
val totalEarnings = (calculatedHours * hourlyRate) + tips + other - cashOut
val netEarnings = totalEarnings * (1.0 - (averageDeductionPercentage / 100.0))

Text(
    text = "Avg Net $${netEarnings.toInt()} / Gross $${totalEarnings.toInt()}",
    style = MaterialTheme.typography.bodySmall,
    color = MaterialTheme.colorScheme.onSurfaceVariant
)
```

**Should be**:
```kotlin
// ✅ CORRECT - Only hourly pay, no tips
val grossPay = calculatedHours * hourlyRate
val netPay = grossPay * (1.0 - (averageDeductionPercentage / 100.0))

Text(
    text = "Avg Net $${netPay.toInt()} / Gross $${grossPay.toInt()}",
    style = MaterialTheme.typography.bodySmall,
    color = MaterialTheme.colorScheme.onSurfaceVariant
)
```

**Key Points**:
- Gross Pay = Hours worked × Hourly rate
- Net Pay = Gross Pay × (1 - deduction%)
- DO NOT include tips, tip-out, or other income in these calculations
- These numbers represent only the hourly wage portion

---

## Testing Checklist

### Database Migration
- [ ] Migration has been executed (user confirmed: "I ran the script")
- [ ] Verify column exists: `SELECT onboarding_completed FROM users_profile LIMIT 1;`
- [ ] Verify existing users backfilled correctly

### Onboarding Flow - New Users
- [ ] Create new account
- [ ] Complete onboarding with all steps
- [ ] Verify `onboarding_completed = true` saved to database
- [ ] Close and reopen app
- [ ] Verify onboarding does NOT show again

### Onboarding Flow - Existing Users
- [ ] Log in with existing account that completed onboarding
- [ ] Verify onboarding does NOT show
- [ ] Check database shows `onboarding_completed = true`

### **CRITICAL: Subscription Flow Test** ⚠️
- [ ] Log in with existing user (onboarding already completed)
- [ ] Go through subscription purchase flow
- [ ] After successful subscription, verify onboarding does NOT show
- [ ] This tests the Section 4 fix - the root cause of the bug

### Edge Cases
- [ ] User sets tip target to 0% during onboarding
- [ ] Verify they still marked as completed (old bug fix)
- [ ] User cancels onboarding mid-way
- [ ] Verify `onboarding_completed` stays false
- [ ] User signs out and back in
- [ ] Verify onboarding state persists

### Add Entry Calculations
- [ ] Create entry: 4.5 hours at $10/hour
- [ ] Under "Total Hours", verify shows:
  - Avg Net: $31.50 (if 30% deduction) or $22.50 (if 50% deduction)
  - Gross: $45.00
- [ ] Add $20 in tips
- [ ] Verify Avg Net and Gross DO NOT change (still $31.50/$45 or $22.50/$45)
- [ ] Only the final "Expected net salary" at bottom should include tips

---

## Files Changed Summary

### iOS (Already Done ✅)
1. `supabase/migrations/add_onboarding_completed_flag.sql` - Database migration
2. `supabase/migrations/fix_onboarding_backfill.sql` - Fix backfill for 0% tip targets
3. `ProTip365/Onboarding/OnboardingModels.swift` - Added `onboarding_completed` field
4. `ProTip365/Onboarding/OnboardingView.swift` - Set `onboarding_completed = true` on finish
5. `ProTip365/ContentView.swift` - Check `onboarding_completed` flag instead of inferring
6. **`ProTip365/Subscription/SubscriptionView.swift`** - **CRITICAL: Check flag before showing onboarding** ⚠️
7. `ProTip365/AddEntry/WorkInfoSection.swift` - Fixed Avg Net/Gross calculation

### Android (To Do)
1. `app/src/main/java/com/protip365/app/data/models/UserProfile.kt` - Add field
2. `app/src/main/java/com/protip365/app/presentation/onboarding/OnboardingModels.kt` - Add field
3. `MainActivity.kt` or `AuthViewModel.kt` - Update onboarding check logic
4. `OnboardingViewModel.kt` or `OnboardingScreen.kt` - Set flag on completion
5. **`SubscriptionScreen.kt` or `SubscriptionViewModel.kt`** - **CRITICAL: Check flag after purchase** ⚠️
6. `AddEditShiftScreen.kt` - Fix Avg Net/Gross calculation

---

## Priority Order

1. **🔴 CRITICAL - ROOT CAUSE**: Fix Subscription View (Section 4)
   - **THIS WAS THE ACTUAL BUG** - Subscription flow was ignoring onboarding_completed flag
   - Without this fix, existing users will ALWAYS see onboarding after subscription
   - Must be fixed first!

2. **CRITICAL**: Update onboarding check logic (Section 3.1)
   - Fixes detection at login time

3. **CRITICAL**: Update onboarding completion (Section 3.2)
   - Ensures new users won't see onboarding again

4. **HIGH**: Update models (Section 2)
   - Required for the above changes to compile

5. **MEDIUM**: Fix Add Entry calculations (Section 5)
   - UX improvement, not a breaking bug

---

## Questions?

If you encounter any issues:
1. Verify the database migration ran successfully
2. Check that field name is exactly `onboarding_completed` (snake_case, not camelCase)
3. Ensure the Supabase client is properly deserializing the boolean field
4. Add logging to see what value is being returned from database

**iOS Build Status**: ✅ BUILD SUCCEEDED
**Database Migration**: ✅ Executed by user
