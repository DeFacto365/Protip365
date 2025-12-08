# 🛡️ ProTip365 Migration Safety Checklist

**Migration:** Database Structure Simplification
**Date:** September 2024
**Risk Level:** HIGH (Structural changes)

---

## ✅ Pre-Migration Checklist

### **🔍 Environment Verification**
- [ ] **Production database URL confirmed**
- [ ] **Backup storage location verified**
- [ ] **Database connection stable**
- [ ] **Sufficient disk space for backup (at least 2x current DB size)**
- [ ] **Migration scheduled during low-traffic window**

### **👥 Team Coordination**
- [ ] **iOS team ready for migration execution**
- [ ] **Android team notified of timeline**
- [ ] **All team members available during migration window**
- [ ] **Rollback plan communicated to all stakeholders**

### **📋 Documentation Ready**
- [ ] **Migration scripts reviewed and tested**
- [ ] **Backup scripts validated**
- [ ] **Rollback scripts prepared**
- [ ] **Android team has DATABASE_SIMPLIFICATION_GUIDE.md**

---

## 🗄️ Backup Strategy

### **Primary Backup**
```bash
# 1. Execute backup script
psql [connection_string] -f backup_before_migration.sql

# 2. Verify backup completion
# Check that backup_20240924 schema exists and has data
```

### **Secondary Backup (Recommended)**
```bash
# Full database dump as additional safety
pg_dump [connection_string] > protip365_full_backup_20240924.sql
```

### **Backup Verification**
- [ ] **backup_20240924 schema exists**
- [ ] **All tables backed up with correct record counts:**
  - [ ] `shifts` table: \_\_\_\_ records
  - [ ] `shift_income` table: \_\_\_\_ records
  - [ ] `employers` table: \_\_\_\_ records
  - [ ] `entries` table (if exists): \_\_\_\_ records
- [ ] **RLS policies backed up**
- [ ] **Indexes and constraints backed up**
- [ ] **Views and functions backed up**

---

## 🚀 Migration Execution Order

### **Step 1: Create Backup** ⏱️ Est: 5-10 minutes
```sql
-- Execute: backup_before_migration.sql
```
**Verification:** ✅ Backup schema created with all data

### **Step 2: Run Migration** ⏱️ Est: 10-15 minutes
```sql
-- Execute: 20240924_simplify_database_structure.sql
```
**Verification:** ✅ New tables created, data migrated, old tables intact

### **Step 3: Application Updates** ⏱️ Est: 5 minutes
- [ ] **Deploy iOS app updates**
- [ ] **Verify app connects to new tables**
- [ ] **Run basic functionality tests**

### **Step 4: Final Cleanup** ⏱️ Est: 2 minutes
```sql
-- Execute final cleanup section of migration script
-- (Only after thorough verification)
```

---

## 🧪 Testing Protocol

### **Immediate Post-Migration Tests**
1. **Data Integrity**
   - [ ] Record counts match between old and new tables
   - [ ] No orphaned records
   - [ ] All relationships intact

2. **Basic Functionality**
   - [ ] User can log in
   - [ ] Calendar displays shifts correctly
   - [ ] Can create new shift
   - [ ] Can add entry to existing shift
   - [ ] Can edit shift and entry
   - [ ] Financial calculations correct

3. **Performance Check**
   - [ ] Query response times acceptable
   - [ ] No significant performance degradation

### **Critical User Journeys**
- [ ] **Create planned shift for tomorrow**
- [ ] **Add entry for yesterday's shift**
- [ ] **View calendar with mixed shifts/entries**
- [ ] **Edit existing entry times and amounts**
- [ ] **Delete a shift (should work)**

---

## 🚨 Rollback Triggers

**Execute rollback immediately if:**
- ❌ Data loss detected (record counts don't match)
- ❌ Application crashes or won't start
- ❌ Users cannot access their data
- ❌ Financial calculations are incorrect
- ❌ Database performance severely degraded
- ❌ Any critical functionality broken

### **Rollback Execution**
```sql
-- Execute immediately: rollback_migration.sql
-- Expected completion time: 5-10 minutes
```

---

## 📊 Success Metrics

### **Technical Metrics**
- ✅ **Zero data loss** (backup vs restored counts match)
- ✅ **All tests pass** (100% of testing checklist)
- ✅ **Performance maintained** (query times < 2x baseline)
- ✅ **No user-reported issues** (first 24 hours)

### **Business Metrics**
- ✅ **All users can access their shifts**
- ✅ **Financial data accuracy maintained**
- ✅ **App functionality unchanged from user perspective**

---

## 🔧 Emergency Contacts

| **Role** | **Name** | **Contact** | **Timezone** |
|----------|----------|-------------|--------------|
| iOS Lead | \_\_\_\_ | \_\_\_\_ | \_\_\_\_ |
| Database Admin | \_\_\_\_ | \_\_\_\_ | \_\_\_\_ |
| Android Lead | \_\_\_\_ | \_\_\_\_ | \_\_\_\_ |

---

## 📝 Migration Log

### **Pre-Migration**
- **Date:** \_\_\_\_\_\_\_\_
- **Time Started:** \_\_\_\_\_\_\_\_
- **Backup Completed:** \_\_\_\_\_\_\_\_
- **Backup Verified:** \_\_\_\_\_\_\_\_

### **Migration Execution**
- **Migration Started:** \_\_\_\_\_\_\_\_
- **New Tables Created:** \_\_\_\_\_\_\_\_
- **Data Migrated:** \_\_\_\_\_\_\_\_
- **Verification Passed:** \_\_\_\_\_\_\_\_

### **Post-Migration**
- **App Deployed:** \_\_\_\_\_\_\_\_
- **Tests Passed:** \_\_\_\_\_\_\_\_
- **Cleanup Completed:** \_\_\_\_\_\_\_\_
- **Migration Complete:** \_\_\_\_\_\_\_\_

### **Issues Encountered**
```
[Record any issues, their resolution, or if rollback was needed]
```

---

## ✅ Final Sign-off

- [ ] **iOS Developer:** Migration completed successfully \_\_\_\_\_\_\_\_
- [ ] **Database Admin:** Data integrity verified \_\_\_\_\_\_\_\_
- [ ] **Product Owner:** Functionality confirmed \_\_\_\_\_\_\_\_
- [ ] **Android Team:** Notified of completion \_\_\_\_\_\_\_\_

---

**🎯 Remember:** It's better to rollback and try again than to leave the database in a broken state!

*Last updated: September 2024*