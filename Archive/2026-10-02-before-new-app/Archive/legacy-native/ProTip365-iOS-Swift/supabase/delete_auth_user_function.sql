-- Create a function that actually deletes the auth user
-- This requires using Supabase's admin API through an Edge Function

-- First, let's update the delete_account function to mark user for deletion
DROP FUNCTION IF EXISTS public.delete_account();

CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_user_id uuid;
    result json;
BEGIN
    -- Get the current user's ID from the auth context
    current_user_id := auth.uid();

    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Delete all user data in the correct order
    DELETE FROM public.achievements WHERE user_id = current_user_id;
    DELETE FROM public.alerts WHERE user_id = current_user_id;
    DELETE FROM public.entries WHERE user_id = current_user_id;
    DELETE FROM public.shifts WHERE user_id = current_user_id;
    DELETE FROM public.employers WHERE user_id = current_user_id;
    DELETE FROM public.user_subscriptions WHERE user_id = current_user_id;
    DELETE FROM public.users_profile WHERE user_id = current_user_id;

    -- Now delete the auth user using Supabase's admin capabilities
    -- This requires special handling

    -- Option 1: Use auth.admin (if available in your Supabase version)
    -- This might work depending on your Supabase setup
    BEGIN
        DELETE FROM auth.users WHERE id = current_user_id;
        result := json_build_object('success', true, 'message', 'User completely deleted');
    EXCEPTION
        WHEN OTHERS THEN
            -- If direct deletion fails, we need to use Edge Function
            result := json_build_object(
                'success', false,
                'message', 'User data deleted but auth record remains. Use Edge Function for complete deletion.',
                'user_id', current_user_id
            );
    END;

    RETURN result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;

-- Create an Edge Function (deploy this as a Supabase Edge Function)
-- Save this as delete-user.ts in supabase/functions/delete-user/

/*
// supabase/functions/delete-user/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Create a Supabase client with the service role key (admin access)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    )

    // Create a Supabase client with the user's token to verify they're authenticated
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Get the user from the token
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid user token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Delete all user data first (this calls our SQL function)
    const { error: deleteDataError } = await supabaseClient
      .rpc('delete_account')

    if (deleteDataError) {
      console.error('Error deleting user data:', deleteDataError)
    }

    // Now use admin client to delete the auth user
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(
      user.id
    )

    if (deleteAuthError) {
      return new Response(
        JSON.stringify({ error: 'Failed to delete auth user', details: deleteAuthError }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    return new Response(
      JSON.stringify({ success: true, message: 'User completely deleted' }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
*/