-- Update user_subscriptions table to match SubscriptionManager expectations
-- This ensures compatibility with the simplified subscription model

-- Add missing columns that SubscriptionManager expects
ALTER TABLE public.user_subscriptions 
ADD COLUMN IF NOT EXISTS environment TEXT DEFAULT 'production';

-- Update the table to ensure all required fields exist
-- The SubscriptionManager expects these fields for SubscriptionRecord:
-- user_id, product_id, status, expires_at, transaction_id, purchase_date, environment

-- Ensure the table structure matches what the app expects
DO $$
BEGIN
    -- Check if environment column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_subscriptions' 
        AND column_name = 'environment'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_subscriptions ADD COLUMN environment TEXT DEFAULT 'production';
    END IF;
END $$;

-- Update existing records to have environment set
UPDATE public.user_subscriptions 
SET environment = 'production' 
WHERE environment IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN public.user_subscriptions.environment IS 'Environment where subscription was purchased (production/sandbox/fallback)';

-- Verify the table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_subscriptions' 
AND table_schema = 'public'
ORDER BY ordinal_position;




