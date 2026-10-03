-- Fix onboarding_completed backfill to include users with 0% tip target
-- Original migration incorrectly excluded users who set tip target to 0%

-- Mark users as completed if they have ANY targets set (even 0%)
UPDATE users_profile
SET onboarding_completed = true
WHERE onboarding_completed = false  -- Only update those not already marked
  AND tip_target_percentage IS NOT NULL  -- Has tip target (even if 0)
  AND target_sales_daily IS NOT NULL
  AND target_hours_daily IS NOT NULL;

-- Log the results
DO $$
DECLARE
    completed_count INTEGER;
    incomplete_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO completed_count FROM users_profile WHERE onboarding_completed = true;
    SELECT COUNT(*) INTO incomplete_count FROM users_profile WHERE onboarding_completed = false;

    RAISE NOTICE 'Fixed onboarding completion backfill:';
    RAISE NOTICE '  - Users marked as completed: %', completed_count;
    RAISE NOTICE '  - Users marked as incomplete: %', incomplete_count;
END $$;
