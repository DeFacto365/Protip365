-- Add average_deduction_percentage field to users_profile table
-- This field stores the expected average deduction percentage for calculating net salary from gross salary

-- Add the column to users_profile table
ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS average_deduction_percentage DECIMAL(5,2) DEFAULT 30.00;

-- Add a check constraint to ensure the value is between 0 and 100
ALTER TABLE users_profile
ADD CONSTRAINT check_average_deduction_percentage
CHECK (average_deduction_percentage >= 0 AND average_deduction_percentage <= 100);

-- Add a comment for documentation
COMMENT ON COLUMN users_profile.average_deduction_percentage IS 'Expected average deduction percentage (0-100) for taxes and other deductions from gross salary. Used to calculate estimated net salary.';

-- Update any existing rows to have the default value if NULL
UPDATE users_profile
SET average_deduction_percentage = 30.00
WHERE average_deduction_percentage IS NULL;