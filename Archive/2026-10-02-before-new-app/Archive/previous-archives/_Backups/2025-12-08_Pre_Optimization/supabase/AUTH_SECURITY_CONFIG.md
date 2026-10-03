# ProTip365 Auth Security Configuration

## Manual Configuration Required in Supabase Dashboard

These settings must be configured directly in the Supabase dashboard as they require admin access to auth.config.

### 1. OTP Expiry Time
**Current Issue**: OTP expiry is set to 86400 seconds (24 hours)
**Recommended**: 3600 seconds (1 hour)

**How to fix**:
1. Go to Supabase Dashboard → Authentication → Settings
2. Find "OTP Expiry Duration"
3. Change from 86400 to 3600
4. Save changes

### 2. Leaked Password Protection
**Current Issue**: Leaked password protection is disabled
**Recommended**: Enable HaveIBeenPwned (HIBP) integration

**How to fix**:
1. Go to Supabase Dashboard → Authentication → Settings
2. Enable "Check passwords against known breaches"
3. Set minimum password length to 8 characters
4. Enable password complexity requirements
5. Save changes

### 3. Password Policy Settings
**Recommended configuration**:
- Minimum length: 8 characters
- Require uppercase letter: Yes
- Require lowercase letter: Yes
- Require number: Yes
- Require special character: Yes
- Check against common passwords: Yes
- Check against HIBP database: Yes

### 4. Session Management
**Recommended configuration**:
- JWT expiry: 3600 seconds (1 hour)
- Refresh token expiry: 604800 seconds (7 days)
- Refresh token reuse interval: 60 seconds
- Enable refresh token rotation: Yes

### 5. Rate Limiting
**Recommended configuration**:
- Sign up: 5 requests per hour per IP
- Sign in: 10 requests per hour per IP
- Password reset: 3 requests per hour per email
- OTP requests: 5 requests per hour per phone/email

## SQL Commands (if direct database access is available)

If you have direct database access, you can run these commands:

```sql
-- Update OTP expiry
UPDATE auth.config 
SET value = '3600'
WHERE key = 'OTP_EXPIRY';

-- Enable HIBP password checking
UPDATE auth.config 
SET value = 'true'
WHERE key = 'SECURITY_CHECK_HIBP';

-- Set minimum password length
UPDATE auth.config 
SET value = '8'
WHERE key = 'PASSWORD_MIN_LENGTH';

-- Enable password complexity
UPDATE auth.config 
SET value = 'true'
WHERE key = 'PASSWORD_REQUIRE_UPPERCASE';

UPDATE auth.config 
SET value = 'true'
WHERE key = 'PASSWORD_REQUIRE_LOWERCASE';

UPDATE auth.config 
SET value = 'true'
WHERE key = 'PASSWORD_REQUIRE_NUMBERS';

UPDATE auth.config 
SET value = 'true'
WHERE key = 'PASSWORD_REQUIRE_SPECIAL';
```

## Verification

After applying these changes, verify the configuration:

1. Test OTP expiry by requesting an OTP and checking if it expires after 1 hour
2. Test password validation by trying to create an account with:
   - A common password (should be rejected)
   - A short password (should be rejected)
   - A password without complexity (should be rejected)
3. Monitor the security_audit_log table for any suspicious activity

## Additional Security Measures Implemented

The `fix_security_warnings.sql` script has already implemented:

1. **Function Security**: All functions now have explicit `search_path` settings
2. **Password Validation**: Added functions to check password strength
3. **Audit Logging**: Created security_audit_log table for tracking security events
4. **Row Level Security**: Ensured RLS is enabled on all tables

## Next Steps

1. Apply the manual configuration changes in Supabase dashboard
2. Run the `fix_security_warnings.sql` script
3. Upgrade PostgreSQL to the latest version for security patches
4. Set up monitoring for the security_audit_log table
5. Configure alerts for suspicious activity patterns
