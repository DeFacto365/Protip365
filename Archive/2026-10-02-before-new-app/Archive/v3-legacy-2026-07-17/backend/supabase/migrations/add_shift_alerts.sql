-- Add shift alert notification fields to the database
-- This migration adds alert_minutes field to shifts table and default_alert_minutes to users_profile table

-- Add alert_minutes column to shifts table
ALTER TABLE shifts
ADD COLUMN IF NOT EXISTS alert_minutes INTEGER DEFAULT NULL;

-- Add comment for documentation
COMMENT ON COLUMN shifts.alert_minutes IS 'Number of minutes before shift start time to send alert notification. NULL means no alert. Possible values: 15, 30, 60, 1440 (1 day)';

-- Add default_alert_minutes column to users_profile table
ALTER TABLE users_profile
ADD COLUMN IF NOT EXISTS default_alert_minutes INTEGER DEFAULT 60;

-- Add comment for documentation
COMMENT ON COLUMN users_profile.default_alert_minutes IS 'Default alert setting for new shifts in minutes. User can override per shift. Default is 60 minutes (1 hour before)';

-- Create index for efficient querying of upcoming alerts
CREATE INDEX IF NOT EXISTS idx_shifts_alert_lookup
ON shifts (user_id, shift_date, start_time, alert_minutes)
WHERE alert_minutes IS NOT NULL AND status = 'planned';

-- Add check constraint to ensure valid alert values
ALTER TABLE shifts
ADD CONSTRAINT check_alert_minutes
CHECK (alert_minutes IS NULL OR alert_minutes IN (15, 30, 60, 1440));

ALTER TABLE users_profile
ADD CONSTRAINT check_default_alert_minutes
CHECK (default_alert_minutes IS NULL OR default_alert_minutes IN (15, 30, 60, 1440));

-- Create a view to help query upcoming shift alerts
CREATE OR REPLACE VIEW v_upcoming_shift_alerts AS
SELECT
    s.id,
    s.user_id,
    s.employer_id,
    e.name as employer_name,
    s.shift_date,
    s.start_time,
    s.alert_minutes,
    -- Calculate the exact timestamp when alert should be sent
    (s.shift_date || ' ' || s.start_time)::timestamp - (s.alert_minutes || ' minutes')::interval AS alert_time,
    s.status
FROM shifts s
LEFT JOIN employers e ON s.employer_id = e.id
WHERE s.alert_minutes IS NOT NULL
  AND s.status = 'planned'
  AND (s.shift_date || ' ' || s.start_time)::timestamp > NOW();

-- Grant appropriate permissions
GRANT SELECT ON v_upcoming_shift_alerts TO authenticated;

-- Enable RLS on the view (inherits from base tables)
ALTER VIEW v_upcoming_shift_alerts SET (security_invoker = on);

-- Update any existing user profiles to have default alert of 60 minutes
UPDATE users_profile
SET default_alert_minutes = 60
WHERE default_alert_minutes IS NULL;