-- Fix missing database columns for ProTip365
-- This script adds any missing columns that might be causing errors

-- Check and add tip_target_percentage column if it doesn't exist (for backward compatibility)
-- Note: This column is deprecated in favor of target_tip_daily/weekly/monthly
ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS tip_target_percentage DECIMAL(10,2) DEFAULT 0;

-- Ensure all required columns exist
ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_tip_daily DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_tip_weekly DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_tip_monthly DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_sales_daily DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_sales_weekly DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_sales_monthly DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_hours_daily DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_hours_weekly DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS target_hours_monthly DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS use_multiple_employers BOOLEAN DEFAULT false;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS default_employer_id UUID;

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS language VARCHAR(10) DEFAULT 'en';

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_users_profile_default_employer'
    ) THEN
        ALTER TABLE users_profile
        ADD CONSTRAINT fk_users_profile_default_employer
        FOREIGN KEY (default_employer_id) REFERENCES employers(id);
    END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN users_profile.tip_target_percentage IS 'DEPRECATED: Use target_tip_daily/weekly/monthly instead';
COMMENT ON COLUMN users_profile.target_tip_daily IS 'Daily tip target for the user';
COMMENT ON COLUMN users_profile.target_tip_weekly IS 'Weekly tip target for the user';
COMMENT ON COLUMN users_profile.target_tip_monthly IS 'Monthly tip target for the user';
COMMENT ON COLUMN users_profile.use_multiple_employers IS 'Whether the user wants to use multiple employers functionality';
COMMENT ON COLUMN users_profile.default_employer_id IS 'Default employer for quick shift entry';