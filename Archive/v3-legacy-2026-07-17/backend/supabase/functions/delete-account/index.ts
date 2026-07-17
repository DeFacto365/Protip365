import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const jsonResponse = (body: Record<string, unknown>, status: number) =>
  new Response(
    JSON.stringify(body),
    {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    },
  );

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Create a Supabase client with the service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    );

    // Get the authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'No authorization header' }, 401);
    }

    // Verify the JWT token and get the user
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    );

    if (authError || !user) {
      return jsonResponse({ error: 'Invalid or expired token' }, 401);
    }

    const userId = user.id;

    // Cleanup is transactional in Postgres and covers both current and legacy
    // user-owned tables. Do not remove the auth user unless this succeeds.
    const { error: cleanupError } = await supabaseClient.rpc('delete_user_owned_data', {
      target_user_id: userId,
    });

    if (cleanupError) {
      console.error('Error deleting user-owned data:', cleanupError);
      return jsonResponse({ error: 'Failed to delete user data' }, 500);
    }

    const { error: deleteError } = await supabaseClient.auth.admin.deleteUser(userId);

    if (deleteError) {
      console.error('Error deleting user:', deleteError);
      return jsonResponse({ error: 'Failed to delete user account' }, 500);
    }

    return jsonResponse({ success: true, message: 'Account deleted successfully' }, 200);

  } catch (error) {
    console.error('Error in delete-account function:', error);
    return jsonResponse({ error: 'Internal server error' }, 500);
  }
});
