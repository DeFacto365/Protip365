-- Add use_multiple_employers column to users_profile table
ALTER TABLE users_profile ADD COLUMN IF NOT EXISTS use_multiple_employers BOOLEAN DEFAULT false;

-- Add comment for the new field
COMMENT ON COLUMN users_profile.use_multiple_employers IS 'Whether the user wants to use multiple employers functionality';