# Supabase Auth 500 Error - Diagnosis and Fix

## Problem
Getting HTTP 500 error when trying to sign up from Android app:
- Error code: `unexpected_failure`
- Endpoint: `/auth/v1/signup`
- Status: 500 Internal Server Error

## Diagnosis Steps

### 1. Check Supabase Dashboard Settings

Go to your Supabase Dashboard (https://supabase.com/dashboard/project/ztzpjsbfzcccvbacgskc) and check:

1. **Authentication > Providers**:
   - Ensure "Email" provider is enabled
   - Check if "Confirm email" is enabled (this might cause issues)
   - Check if "Secure email change" is enabled

2. **Authentication > URL Configuration**:
   - Site URL should be configured
   - Redirect URLs should include your app's deep links

3. **Authentication > Email Templates**:
   - Ensure email templates are properly configured if email confirmation is required

### 2. Temporary Fix - Disable Email Confirmation

In Supabase Dashboard:
1. Go to **Authentication > Providers > Email**
2. **DISABLE** "Confirm email" (uncheck the box)
3. Save changes

This will allow users to sign up without email verification.

### 3. Check Rate Limiting

The error might be due to rate limiting. In Supabase Dashboard:
1. Go to **Settings > API**
2. Check if there are any rate limit configurations
3. Consider increasing limits if needed

### 4. Database Setup - Run This SQL in Supabase SQL Editor

```sql
-- Ensure auth schema and users table are properly set up
SELECT COUNT(*) FROM auth.users;

-- Check if there are any database triggers that might be failing
SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'auth';

-- Ensure users_profile table exists with proper structure
CREATE TABLE IF NOT EXISTS public.users_profile (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    preferred_language TEXT DEFAULT 'en',
    daily_target DECIMAL DEFAULT 250,
    weekly_target DECIMAL DEFAULT 1500,
    monthly_target DECIMAL DEFAULT 6000,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;

-- Create policies for users_profile
DROP POLICY IF EXISTS "Users can create their own profile" ON public.users_profile;
CREATE POLICY "Users can create their own profile"
ON public.users_profile
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own profile" ON public.users_profile;
CREATE POLICY "Users can view their own profile"
ON public.users_profile
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users_profile;
CREATE POLICY "Users can update their own profile"
ON public.users_profile
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON public.users_profile TO authenticated;
GRANT ALL ON public.users_profile TO service_role;

-- Create function to auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.users_profile (user_id, name)
    VALUES (new.id, COALESCE(new.raw_user_meta_data->>'name', ''))
    ON CONFLICT (user_id) DO NOTHING;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for auto profile creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
```

### 5. Android Code Update - Better Error Handling

Update `AuthRepositoryImpl.kt` to provide better error messages:

```kotlin
override suspend fun signUp(email: String, password: String): Result<UserProfile> {
    return try {
        // Add logging
        println("Attempting signup for email: $email")

        val response = supabaseClient.auth.signUpWith(Email) {
            this.email = email
            this.password = password
        }

        println("Signup response: ${response.user?.id}")

        // Check if user was actually created
        val userId = response.user?.id ?: throw Exception("User ID not returned from signup")

        // Create profile with better error handling
        val userProfile = UserProfile(
            userId = userId,
            name = null
        )

        try {
            supabaseClient.from("users_profile").upsert(userProfile)
        } catch (profileError: Exception) {
            println("Profile creation error (non-fatal): ${profileError.message}")
            // Continue even if profile creation fails
        }

        dataStore.edit { preferences ->
            preferences[IS_LOGGED_IN_KEY] = true
        }

        // Return a basic profile even if database profile creation failed
        Result.success(userProfile)

    } catch (e: Exception) {
        println("Signup error: ${e.message}")
        println("Full error: $e")

        // Better error messages
        val errorMessage = when {
            e.message?.contains("connection", ignoreCase = true) == true ->
                "Network error. Please check your connection."
            e.message?.contains("already registered") == true ->
                "This email is already registered."
            e.message?.contains("weak password") == true ->
                "Password is too weak. Please use at least 6 characters."
            e.message?.contains("invalid email") == true ->
                "Please enter a valid email address."
            else -> "Signup failed: ${e.message ?: "Unknown error"}"
        }

        Result.failure(Exception(errorMessage))
    }
}
```

## Immediate Actions

1. **First**: Check Supabase Dashboard and disable email confirmation
2. **Second**: Run the SQL script above in Supabase SQL Editor
3. **Third**: Test signup again from the Android app
4. **If still failing**: Check Supabase logs for more details about the 500 error

## Testing

After making these changes, try signing up with:
- Email: test@example.com
- Password: Test123456

Monitor the Supabase logs for any additional error details.
