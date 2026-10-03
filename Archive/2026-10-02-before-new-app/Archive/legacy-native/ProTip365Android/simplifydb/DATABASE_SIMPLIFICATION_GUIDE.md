# ProTip365 Database Simplification Guide

**Date:** September 2024
**Target:** Android Development Team
**Purpose:** Comprehensive guide for database structure changes

---

## 🚨 Breaking Changes Overview

We are **simplifying the overly complex database structure** from 4 interrelated tables/views down to **2 clean, logical tables**.

### What's Changing

| **Before (Complex)** | **After (Simplified)** |
|---------------------|------------------------|
| `shifts` table | `expected_shifts` table |
| `shift_income` table | `shift_entries` table |
| `entries` table | ❌ **REMOVED** |
| `v_shift_income` view | ❌ **REMOVED** |

---

## 📋 Current Problems Being Fixed

### 1. **Data Duplication**
- `shift_date` stored in both `shifts` AND `shift_income`
- `employer_id` stored in both tables
- `hourly_rate` stored in both tables

### 2. **Redundant Fields**
- ❌ `lunch_break_hours` (unused - only `lunch_break_minutes` is used)
- ❌ `entry_notes` (field exists but never used)

### 3. **Complex Queries**
- Requires JOINs across 3+ tables for basic operations
- View `v_shift_income` tries to patch complexity but adds more confusion

### 4. **Unclear Separation**
- Mixed "planning" data with "actual" data in same queries
- Financial data scattered across multiple places

---

## 🎯 New Simplified Structure

### **Table 1: `expected_shifts`** (Planning/Scheduling)

```sql
CREATE TABLE expected_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    employer_id UUID REFERENCES employers(id),

    -- When they're supposed to work
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    expected_hours DECIMAL(5,2) NOT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL,

    -- Break time (ONLY minutes, no hours field)
    lunch_break_minutes INTEGER DEFAULT 0,

    -- Status and metadata
    status TEXT DEFAULT 'planned', -- 'planned', 'completed', 'missed'
    alert_minutes INTEGER, -- For notifications
    notes TEXT, -- Planning notes

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

**Purpose:** Store planned/expected shift information only. No financial data.

### **Table 2: `shift_entries`** (Actual Work + Earnings)

```sql
CREATE TABLE shift_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES expected_shifts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),

    -- What actually happened
    actual_start_time TIME NOT NULL,
    actual_end_time TIME NOT NULL,
    actual_hours DECIMAL(5,2) NOT NULL,

    -- Financial data (ONLY here, nowhere else)
    sales DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,
    cash_out DECIMAL(10,2) DEFAULT 0,
    other DECIMAL(10,2) DEFAULT 0,

    -- Entry notes
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    UNIQUE(shift_id) -- One entry per shift max
);
```

**Purpose:** Store actual work performed and earnings. Links to expected shift via `shift_id`.

---

## 📱 Android Code Changes Required

### 1. **Update Data Models**

#### **Before:**
```kotlin
data class Shift(...)
data class ShiftIncome(...)
```

#### **After:**
```kotlin
data class ExpectedShift(
    val id: String,
    val userId: String,
    val employerId: String?,
    val shiftDate: String, // yyyy-MM-dd
    val startTime: String, // HH:mm:ss
    val endTime: String,   // HH:mm:ss
    val expectedHours: Double,
    val hourlyRate: Double,
    val lunchBreakMinutes: Int, // ONLY minutes field
    val status: String, // "planned", "completed", "missed"
    val alertMinutes: Int?,
    val notes: String?,
    val createdAt: String,
    val updatedAt: String
)

data class ShiftEntry(
    val id: String,
    val shiftId: String, // Links to ExpectedShift.id
    val userId: String,
    val actualStartTime: String, // HH:mm:ss
    val actualEndTime: String,   // HH:mm:ss
    val actualHours: Double,
    val sales: Double,
    val tips: Double,
    val cashOut: Double,
    val other: Double,
    val notes: String?,
    val createdAt: String,
    val updatedAt: String
)
```

### 2. **Update Repository Methods**

#### **Before:**
```kotlin
// Complex joins required
suspend fun getShiftWithIncome(shiftId: String): ShiftIncome
```

#### **After:**
```kotlin
// Simple, clean queries
suspend fun getExpectedShifts(userId: String): List<ExpectedShift>
suspend fun getShiftEntry(shiftId: String): ShiftEntry?
suspend fun getShiftWithEntry(shiftId: String): Pair<ExpectedShift, ShiftEntry?>
```

### 3. **Update API Endpoints**

| **Old Endpoint** | **New Endpoint** | **Purpose** |
|-----------------|------------------|-------------|
| `/shifts` | `/expected-shifts` | Get planned shifts |
| `/shift-income` | `/shift-entries` | Get actual entries |
| `/v_shift_income` | ❌ **Remove** | No longer needed |

### 4. **Database Queries**

#### **Get All Shifts with Entries:**
```sql
-- OLD (complex)
SELECT * FROM v_shift_income WHERE user_id = ?

-- NEW (simple)
SELECT
    es.*,
    se.actual_start_time,
    se.actual_end_time,
    se.actual_hours,
    se.sales,
    se.tips,
    se.cash_out,
    se.other,
    se.notes as entry_notes
FROM expected_shifts es
LEFT JOIN shift_entries se ON es.id = se.shift_id
WHERE es.user_id = ?
```

#### **Create New Entry:**
```sql
-- OLD (insert into multiple tables)
INSERT INTO shifts (...);
INSERT INTO shift_income (...);

-- NEW (clean separation)
-- 1. Create expected shift (if planning ahead)
INSERT INTO expected_shifts (...);

-- 2. Create actual entry (when work is done)
INSERT INTO shift_entries (shift_id, user_id, actual_start_time, ...);
```

---

## 🔄 Migration Timeline

### **Phase 1: Preparation** (Before Migration)
- ✅ Review this document
- ✅ Update Android models to match new structure
- ✅ Create new repository methods
- ⚠️ **DO NOT** deploy yet - wait for migration

### **Phase 2: Database Migration** (Coordinated)
- 🔄 **iOS team runs migration scripts**
- 🔄 **Data moved from old tables to new tables**
- 🔄 **Verification that data is intact**

### **Phase 3: Code Deployment** (After Migration)
- ✅ Deploy Android app with new models
- ✅ Update API calls to use new table names
- ✅ Test thoroughly

### **Phase 4: Cleanup** (After Verification)
- 🧹 Drop old tables (`shifts`, `shift_income`, `entries`, `v_shift_income`)

---

## 🧪 Testing Checklist

### Before Migration:
- [ ] Backup current database
- [ ] Test new models with sample data
- [ ] Verify all queries work with new structure

### After Migration:
- [ ] Data count matches (old vs new tables)
- [ ] All shifts have correct expected data
- [ ] All entries link properly to shifts
- [ ] No orphaned records
- [ ] App functionality unchanged from user perspective

### Critical Tests:
- [ ] Create new planned shift
- [ ] Add entry to existing shift
- [ ] Edit shift times
- [ ] Edit entry financial data
- [ ] Delete shift (should cascade to entry)
- [ ] View calendar with shifts and entries

---

## 🚨 Breaking Changes Summary

### **Removed Fields:**
- ❌ `lunch_break_hours` - Use `lunch_break_minutes` only
- ❌ `entry_notes` - Use `notes` in `shift_entries` table
- ❌ Duplicate fields in multiple tables

### **Renamed Tables:**
- `shifts` → `expected_shifts`
- `shift_income` → `shift_entries`

### **New Relationships:**
- `shift_entries.shift_id` → `expected_shifts.id` (1:1 relationship)
- Clear separation: planning vs actual work

### **Status Values:**
- `"scheduled"` → `"planned"`
- `"in_progress"` → `"planned"` (simplified)

---

## ❓ FAQ for Android Team

### Q: Why are we making this change?
**A:** The current structure is over-engineered for a simple tip tracking app. We have 4 tables doing the job of 2, with data duplication and confusing relationships.

### Q: Will user data be lost?
**A:** No. The migration preserves all data, just reorganizes it logically.

### Q: Do we need to update the UI?
**A:** No UI changes needed. The functionality remains the same, just the data structure is cleaner.

### Q: What about existing API endpoints?
**A:** Table names change, but you can alias in queries during transition period if needed.

### Q: How do we handle the transition period?
**A:** Coordinate with iOS team. Migration will be done during low-traffic time with rollback plan ready.

---

## 📞 Support

**Questions?** Contact iOS development team or create issue in project repository.

**Migration Status:** 🔄 In preparation phase

---

*This guide will be updated as migration progresses. Last updated: September 2024*