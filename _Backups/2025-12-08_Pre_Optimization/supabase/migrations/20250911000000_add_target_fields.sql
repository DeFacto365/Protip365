-- Add missing target fields to users_profile table
ALTER TABLE users_profile ADD COLUMN IF NOT EXISTS target_sales_daily DECIMAL(10,2) DEFAULT 0;
ALTER TABLE users_profile ADD COLUMN IF NOT EXISTS target_sales_weekly DECIMAL(10,2) DEFAULT 0;
ALTER TABLE users_profile ADD COLUMN IF NOT EXISTS target_sales_monthly DECIMAL(10,2) DEFAULT 0;

ALTER TABLE users_profile ADD COLUMN IF NOT EXISTS target_hours_daily DECIMAL(10,2) DEFAULT 0;
ALTER TABLE users_profile ADD COLUMN IF NOT EXISTS target_hours_weekly DECIMAL(10,2) DEFAULT 0;
ALTER TABLE users_profile ADD COLUMN IF NOT EXISTS target_hours_monthly DECIMAL(10,2) DEFAULT 0;

-- Add comments for the new fields
COMMENT ON COLUMN users_profile.target_sales_daily IS 'Daily sales target for the user';
COMMENT ON COLUMN users_profile.target_sales_weekly IS 'Weekly sales target for the user';
COMMENT ON COLUMN users_profile.target_sales_monthly IS 'Monthly sales target for the user';

COMMENT ON COLUMN users_profile.target_hours_daily IS 'Daily hours target for the user';
COMMENT ON COLUMN users_profile.target_hours_weekly IS 'Weekly hours target for the user';
COMMENT ON COLUMN users_profile.target_hours_monthly IS 'Monthly hours target for the user';