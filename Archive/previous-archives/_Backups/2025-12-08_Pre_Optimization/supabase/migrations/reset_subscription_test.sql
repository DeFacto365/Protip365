-- Reset subscription for test user jack_77_77@hotmail.com

-- Delete any existing subscription records for this user
DELETE FROM user_subscriptions
WHERE user_id = (
    SELECT id
    FROM auth.users
    WHERE email = 'jack_77_77@hotmail.com'
    LIMIT 1
);

-- Verify the deletion was successful
SELECT
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM user_subscriptions
            WHERE user_id = (
                SELECT id
                FROM auth.users
                WHERE email = 'jack_77_77@hotmail.com'
            )
        )
        THEN 'Subscription successfully reset for jack_77_77@hotmail.com'
        ELSE 'Failed to reset subscription'
    END as status;

-- Optional: View current subscriptions for this user (should be empty)
SELECT * FROM user_subscriptions
WHERE user_id = (
    SELECT id
    FROM auth.users
    WHERE email = 'jack_77_77@hotmail.com'
);