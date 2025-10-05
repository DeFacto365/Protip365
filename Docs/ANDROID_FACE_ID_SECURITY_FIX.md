# Android Implementation Guide - Face ID/Biometric Security Per-User Fix

## Critical Security Issue Fixed

**Problem**: Security settings (Face ID/Biometric, PIN) were stored per-device instead of per-user, allowing any user on the same device to bypass another user's security.

**Impact**: User A enables Face ID → App reinstalled → User B logs in → User B is authenticated with Face ID meant for User A!

**Fix**: Store security settings **per user** in database, not on device.

## iOS Changes (v1.1.34)

### 1. Database Migration

**File**: `supabase/migrations/add_user_security_settings.sql`

Added three columns to `users_profile` table:
```sql
ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS security_type TEXT DEFAULT 'none'
    CHECK (security_type IN ('none', 'biometric', 'pin', 'both')),
ADD COLUMN IF NOT EXISTS pin_code_hash TEXT,
ADD COLUMN IF NOT EXISTS biometric_enabled BOOLEAN DEFAULT false;
```

### 2. Updated UserProfile Model

**File**: `ProTip365/Managers/Models.swift`

```swift
struct UserProfile: Codable {
    let user_id: UUID
    // ... other fields ...
    let security_type: String? // 'none', 'biometric', 'pin', 'both'
    let pin_code_hash: String?
    let biometric_enabled: Bool?
}
```

### 3. SecurityManager Changes

**File**: `ProTip365/Authentication/SecurityManager.swift`

**Key Changes**:
- ❌ Removed `@AppStorage` for security settings (device-level)
- ✅ Added `loadSecuritySettings(for userId:)` - loads from database
- ✅ Added `saveSecuritySettings()` - saves to database
- ✅ Added `clearSecuritySettings()` - clears on sign out
- ✅ Added `currentUserId` tracking

**Critical Methods**:
```swift
// Load security settings when user logs in
func loadSecuritySettings(for userId: UUID) async {
    // Fetch from users_profile table
    // Update local state
}

// Save security settings when changed
private func saveSecuritySettings() async {
    // Update users_profile table
}

// Clear security settings when user signs out
func clearSecuritySettings() {
    securityType = "none"
    pinCodeHash = ""
    biometricEnabled = false
    currentUserId = nil
    isUnlocked = false
}
```

### 4. ContentView Integration

**File**: `ProTip365/ContentView.swift`

**When user logs in**:
```swift
// After successful authentication
await securityManager.loadSecuritySettings(for: session.user.id)
```

**When user logs out**:
```swift
.onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
    // Clear security settings
    securityManager.clearSecuritySettings()
}
```

## Android Implementation

### 1. Database Migration

**File**: `ProTip365Android/app/src/main/sqldelight/migrations/add_user_security_settings.sql` (or run via Supabase)

```sql
ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS security_type TEXT DEFAULT 'none'
    CHECK (security_type IN ('none', 'biometric', 'pin', 'both')),
ADD COLUMN IF NOT EXISTS pin_code_hash TEXT,
ADD COLUMN IF NOT EXISTS biometric_enabled BOOLEAN DEFAULT false;
```

### 2. Update UserProfile Model

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/data/models/UserProfile.kt`

```kotlin
data class UserProfile(
    val user_id: String,
    val default_hourly_rate: Double,
    val week_start: Int,
    val tip_target_percentage: Double?,
    val name: String?,
    val default_employer_id: String?,
    val default_alert_minutes: Int?,
    val security_type: String? = "none", // NEW
    val pin_code_hash: String? = null,   // NEW
    val biometric_enabled: Boolean? = false // NEW
)
```

### 3. Create SecurityManager

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/presentation/security/SecurityManager.kt`

```kotlin
class SecurityManager(
    private val supabaseClient: SupabaseClient,
    private val preferencesManager: PreferencesManager
) {
    private var currentUserId: String? = null
    private var securityType: String = "none"
    private var pinCodeHash: String? = null
    private var biometricEnabled: Boolean = false

    /**
     * CRITICAL: Load security settings from database for current user
     * Call this after user successfully logs in
     */
    suspend fun loadSecuritySettings(userId: String) {
        Log.d("SecurityManager", "Loading security settings for user: $userId")
        currentUserId = userId

        try {
            val profile = supabaseClient.from("users_profile")
                .select() {
                    filter {
                        eq("user_id", userId)
                    }
                }
                .decodeSingle<UserProfile>()

            securityType = profile.security_type ?: "none"
            pinCodeHash = profile.pin_code_hash
            biometricEnabled = profile.biometric_enabled ?: false

            Log.d("SecurityManager", "Security settings loaded: $securityType")
        } catch (e: Exception) {
            Log.e("SecurityManager", "Failed to load security settings", e)
            // Default to no security on error
            securityType = "none"
            pinCodeHash = null
            biometricEnabled = false
        }
    }

    /**
     * Save security settings to database
     * Call this whenever security settings change
     */
    private suspend fun saveSecuritySettings() {
        val userId = currentUserId ?: run {
            Log.e("SecurityManager", "Cannot save - no user ID")
            return
        }

        Log.d("SecurityManager", "Saving security settings for user: $userId")

        try {
            supabaseClient.from("users_profile")
                .update({
                    set("security_type", securityType)
                    set("pin_code_hash", pinCodeHash)
                    set("biometric_enabled", biometricEnabled)
                }) {
                    filter {
                        eq("user_id", userId)
                    }
                }

            Log.d("SecurityManager", "Security settings saved")
        } catch (e: Exception) {
            Log.e("SecurityManager", "Failed to save security settings", e)
        }
    }

    /**
     * CRITICAL: Clear security settings when user signs out
     * This prevents security settings from carrying over to different users
     */
    fun clearSecuritySettings() {
        Log.d("SecurityManager", "Clearing security settings")
        securityType = "none"
        pinCodeHash = null
        biometricEnabled = false
        currentUserId = null
    }

    /**
     * Set security type and save to database
     */
    suspend fun setSecurityType(type: String) {
        securityType = type
        biometricEnabled = (type == "biometric" || type == "both")

        if (type == "none") {
            pinCodeHash = null
        }

        saveSecuritySettings()
    }

    /**
     * Set PIN code (hashed) and save to database
     */
    suspend fun setPinCode(pin: String): Boolean {
        if (pin.length !in 4..8) return false

        // Hash the PIN using SHA-256
        pinCodeHash = MessageDigest.getInstance("SHA-256")
            .digest(pin.toByteArray())
            .joinToString("") { "%02x".format(it) }

        saveSecuritySettings()
        return true
    }

    /**
     * Verify PIN code
     */
    fun verifyPinCode(pin: String): Boolean {
        val hash = pinCodeHash ?: return false

        val inputHash = MessageDigest.getInstance("SHA-256")
            .digest(pin.toByteArray())
            .joinToString("") { "%02x".format(it) }

        return inputHash == hash
    }

    fun getCurrentSecurityType(): String = securityType
    fun isBiometricEnabled(): Boolean = biometricEnabled
}
```

### 4. Update AuthViewModel

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/presentation/auth/AuthViewModel.kt`

```kotlin
class AuthViewModel(
    private val authRepository: AuthRepository,
    private val securityManager: SecurityManager
) : ViewModel() {

    suspend fun signIn(email: String, password: String): Result<Unit> {
        return try {
            val session = authRepository.signIn(email, password)

            // CRITICAL: Load security settings for this user
            securityManager.loadSecuritySettings(session.user.id)

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun signOut() {
        authRepository.signOut()

        // CRITICAL: Clear security settings on sign out
        securityManager.clearSecuritySettings()
    }
}
```

### 5. Update Main Activity / App Entry Point

**File**: `ProTip365Android/app/src/main/java/com/protip365/app/presentation/main/MainViewModel.kt`

```kotlin
init {
    viewModelScope.launch {
        // Listen for auth state changes
        supabaseClient.auth.sessionStatus.collect { status ->
            when (status) {
                is SessionStatus.Authenticated -> {
                    val userId = status.session.user?.id
                    if (userId != null) {
                        // CRITICAL: Load security settings when user is authenticated
                        securityManager.loadSecuritySettings(userId)
                    }
                }
                is SessionStatus.NotAuthenticated -> {
                    // CRITICAL: Clear security settings when not authenticated
                    securityManager.clearSecuritySettings()
                }
                else -> { /* Loading state */ }
            }
        }
    }
}
```

### 6. Remove Shared Preferences for Security

**CRITICAL**: If you were using SharedPreferences or DataStore for security settings, **REMOVE THEM**!

**Before (INSECURE)**:
```kotlin
// ❌ WRONG - This is per-device, not per-user!
val preferences = context.getSharedPreferences("security", Context.MODE_PRIVATE)
val securityType = preferences.getString("security_type", "none")
```

**After (SECURE)**:
```kotlin
// ✅ CORRECT - Load from database per user
securityManager.loadSecuritySettings(userId)
val securityType = securityManager.getCurrentSecurityType()
```

## Testing Checklist

### Test Scenario 1: Single User
- [ ] User A enables Face ID
- [ ] Close app, reopen
- [ ] Face ID still enabled for User A ✅
- [ ] Face ID settings saved in database

### Test Scenario 2: Sign Out
- [ ] User A enables Face ID
- [ ] User A signs out
- [ ] Security settings cleared ✅
- [ ] No Face ID prompt on next login

### Test Scenario 3: Multiple Users (CRITICAL)
- [ ] User A enables Face ID
- [ ] User A signs out
- [ ] User B logs in (different account)
- [ ] User B should NOT have Face ID enabled ✅
- [ ] User B must explicitly enable Face ID themselves
- [ ] User A's Face ID settings stored separately in database

### Test Scenario 4: Delete and Reinstall
- [ ] User A enables Face ID
- [ ] Delete app, reinstall
- [ ] User A logs in
- [ ] Face ID settings restored from database ✅
- [ ] User B logs in
- [ ] User B does NOT have Face ID enabled ✅

## Migration Plan for Existing Users

Since existing users may have security settings in AppStorage/SharedPreferences:

1. Run database migration to add columns
2. For existing users with local security settings:
   - On first launch after update, migrate local settings to database
   - Clear local storage after migration
3. For new users, always use database

## Security Best Practices

1. ✅ **Never** store security settings in device-level storage (AppStorage, SharedPreferences)
2. ✅ **Always** store per-user in database
3. ✅ **Always** clear security settings on sign out
4. ✅ **Always** load security settings on sign in
5. ✅ Hash PIN codes using SHA-256 before storing
6. ✅ Never store plain-text PINs

## Summary

| Aspect | Before (INSECURE) | After (SECURE) |
|--------|-------------------|----------------|
| Storage Location | Device (AppStorage) | Database (per-user) |
| Scope | Per-device | Per-user account |
| Sign Out | Settings persist | Settings cleared |
| Multiple Users | Shared settings | Isolated settings |
| App Reinstall | Settings lost | Settings restored |

This fix ensures that Face ID/biometric authentication is **per user account**, not per device, preventing unauthorized access.
