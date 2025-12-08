-- Add security settings to users_profile table
-- These settings are per-user, not per-device

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS security_type TEXT DEFAULT 'none' CHECK (security_type IN ('none', 'biometric', 'pin', 'both')),
ADD COLUMN IF NOT EXISTS pin_code_hash TEXT,
ADD COLUMN IF NOT EXISTS biometric_enabled BOOLEAN DEFAULT false;

-- Add comment to clarify the purpose
COMMENT ON COLUMN users_profile.security_type IS 'User-specific security setting: none, biometric (Face ID/Touch ID), pin, or both';
COMMENT ON COLUMN users_profile.pin_code_hash IS 'SHA256 hash of user PIN code for secure storage';
COMMENT ON COLUMN users_profile.biometric_enabled IS 'Whether biometric authentication is enabled for this user';

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_profile_security ON users_profile(user_id, security_type);
