# ProTip365 Database Simplification Scripts

This folder contains all scripts needed to simplify the ProTip365 database structure.

## 📁 Files Overview

| File | Purpose | When to Run |
|------|---------|-------------|
| `backup_before_migration.sql` | Create complete backup before changes | **FIRST** - before any migration |
| `20240924_simplify_database_structure.sql` | Main migration script | **SECOND** - after backup is verified |
| `rollback_migration.sql` | Emergency rollback to pre-migration state | **ONLY IF** migration fails |

## 🚀 Execution Order

### 1. **Create Backup** (MANDATORY)
```sql
-- Run this first - creates backup_20240924 schema
psql [connection_string] -f backup_before_migration.sql
```

### 2. **Verify Backup**
```sql
-- Check that backup was successful
SELECT * FROM backup_20240924.backup_metadata;
```

### 3. **Run Migration**
```sql
-- Execute main migration (only after backup verified)
psql [connection_string] -f 20240924_simplify_database_structure.sql
```

### 4. **Emergency Rollback** (if needed)
```sql
-- Only if something goes wrong
psql [connection_string] -f rollback_migration.sql
```

## ⚠️ Important Notes

- **NEVER skip the backup step**
- **Test on development environment first**
- **Coordinate with Android team** (see DATABASE_SIMPLIFICATION_GUIDE.md in root)
- **Keep rollback script ready during migration**

## 🎯 What This Migration Does

**Before (Complex):**
- `shifts` table
- `shift_income` table
- `entries` table
- `v_shift_income` view

**After (Simplified):**
- `expected_shifts` table (planning data)
- `shift_entries` table (actual work + earnings)

## 📞 Support

Questions? Check the documentation files in this folder:
- `DATABASE_SIMPLIFICATION_GUIDE.md` - Complete guide for Android team
- `MIGRATION_SAFETY_CHECKLIST.md` - Step-by-step safety procedures