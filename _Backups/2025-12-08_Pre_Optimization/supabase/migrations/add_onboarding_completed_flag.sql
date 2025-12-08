-- Add onboarding_completed flag to users_profile table
-- This provides a clear, explicit indicator of onboarding completion

ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;

-- Add comment to explain the field
COMMENT ON COLUMN users_profile.onboarding_completed IS 'Indicates whether the user has completed the initial onboarding flow';

-- Backfill existing users: Mark as completed if they have tip targets set
UPDATE users_profile
SET onboarding_completed = true
WHERE tip_target_percentage IS NOT NULL
  AND tip_target_percentage > 0
  AND target_sales_daily IS NOT NULL
  AND target_hours_daily IS NOT NULL;

-- Log the backfill results
DO $$
DECLARE
    completed_count INTEGER;
    incomplete_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO completed_count FROM users_profile WHERE onboarding_completed = true;
    SELECT COUNT(*) INTO incomplete_count FROM users_profile WHERE onboarding_completed = false;

    RAISE NOTICE 'Onboarding completion backfill complete:';
    RAISE NOTICE '  - Users marked as completed: %', completed_count;
    RAISE NOTICE '  - Users marked as incomplete: %', incomplete_count;
END $$;
