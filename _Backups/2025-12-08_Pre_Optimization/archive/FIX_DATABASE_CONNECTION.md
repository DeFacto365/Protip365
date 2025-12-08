# Fix Database Connection Issue for ProTip365

## Problem Identified
The app is failing to create users because of an invalid Supabase API key configuration. The current key format `sb_publishable_6lBH6DSnvQ9hTY_3k5Gsfg_RdGVc95c` is not a valid Supabase anon key.

## Solution Steps

### 1. Get Your Supabase Anon Key

1. Go to your Supabase project dashboard:
   https://supabase.com/dashboard/project/wnuzxoehqqaeeycelvzm/settings/api

2. Look for the **anon public** key (it should start with `eyJ...`)

3. Copy this key

### 2. Update Configuration Files

I've already updated the Supabase URL to match your `.env` file (`https://wnuzxoehqqaeeycelvzm.supabase.co`), but you need to add the correct anon key.

Update these files with your actual anon key:

#### a. Info.plist
Replace `YOUR_SUPABASE_ANON_KEY_HERE` with your actual key at line 124:
```xml
<key>SUPABASE_ANON_KEY</key>
<string>YOUR_ACTUAL_ANON_KEY_HERE</string>
```

#### b. ConfigManager.swift
Replace `YOUR_SUPABASE_ANON_KEY_HERE` with your actual key at lines 36 and 38:
```swift
#if DEBUG
return "YOUR_ACTUAL_ANON_KEY_HERE"
#else
return "YOUR_ACTUAL_ANON_KEY_HERE"
#endif
```

#### c. .env file (optional, for reference)
Update the `.env` file with the correct key:
```
SUPABASE_ANON_KEY=YOUR_ACTUAL_ANON_KEY_HERE
```

### 3. Verify Your Supabase Project Settings

1. Make sure your Supabase project has:
   - Authentication enabled
   - Email authentication allowed
   - The `users_profile` table created with proper RLS policies

2. Check that the database schema includes:
   - A `users_profile` table with columns: `user_id`, `name`, `default_hourly_rate`, `language`
   - Proper RLS policies allowing users to insert their own profile

### 4. Test the Fix

After updating the configuration:

1. Clean the build folder in Xcode (Shift+Cmd+K)
2. Rebuild the project
3. Try creating a new user account

## Alternative: Use a Different Supabase Project

If you don't have access to the project `wnuzxoehqqaeeycelvzm`, you can:

1. Create a new Supabase project at https://supabase.com
2. Run the database migrations from the `supabase/migrations` folder
3. Update both the URL and anon key in the configuration files

## Files Modified

- `/Users/jacquesbolduc/Github/ProTip365/ProTip365/Info.plist` - Updated Supabase URL
- `/Users/jacquesbolduc/Github/ProTip365/ProTip365/Managers/ConfigManager.swift` - Updated Supabase URL

## Next Steps

1. Get your correct Supabase anon key
2. Update the placeholder `YOUR_SUPABASE_ANON_KEY_HERE` in both files
3. Rebuild and test the app

## Note
The anon key should look like this format:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...
```

It's a JWT token that starts with `eyJ` and is typically 200+ characters long.