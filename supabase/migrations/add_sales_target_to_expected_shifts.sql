-- Add sales_target column to expected_shifts table
-- This allows users to set custom sales targets for individual shifts
-- Defaults to NULL, which means use the default target from user settings

ALTER TABLE expected_shifts
ADD COLUMN IF NOT EXISTS sales_target DECIMAL(10,2) DEFAULT NULL;

COMMENT ON COLUMN expected_shifts.sales_target IS 'Custom sales target for this specific shift. NULL means use default target from user settings.';
