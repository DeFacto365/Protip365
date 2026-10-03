DELETE FROM user_subscriptions WHERE user_id = (SELECT id::text FROM auth.users WHERE email = 'jack_77_77@hotmail.com' LIMIT 1);
