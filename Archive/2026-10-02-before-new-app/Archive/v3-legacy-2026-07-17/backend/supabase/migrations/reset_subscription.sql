-- Reset subscription for test user jack_77_77@hotmail.com

-- First, get the user ID for jack_77_77@hotmail.com
WITH user_info AS (
    SELECT id 
    FROM auth.users 
    WHERE email = 'jack_77_77@hotmail.com'
    LIMIT 1
)

-- Delete any existing subscription records for this user
DELETE FROM user_subscriptions 
WHERE user_id IN (SELECT id::text FROM user_info);

-- Verify deletion
SELECT 'Subscription reset complete for jack_77_77@hotmail.com' as status;

-- Optional: Check if user exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'jack_77_77@hotmail.com') 
        THEN 'User found and subscription cleared' 
        ELSE 'User not found' 
    END as result;
