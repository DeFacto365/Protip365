import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('ResendProtip365')

serve(async (req) => {
  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')!
    
    // Verify the user is authenticated
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      throw new Error('Unauthorized')
    }
    
    const { subject, message } = await req.json()
    const userEmail = user.email || 'Unknown'
    
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'ProTip365 <web@florabump.com>',
        to: ['web@florabump.com'],
        subject: `ProTip365 Support - ${subject}`,
        html: `
          <h2>New Support Request from ProTip365</h2>
          <p><strong>From:</strong> ${userEmail}</p>
          <p><strong>Date:</strong> ${new Date().toISOString()}</p>
          <p><strong>Subject:</strong> ${subject}</p>
          <hr>
          <p><strong>Message:</strong></p>
          <p>${message.replace(/\n/g, '<br>')}</p>
        `
      }),
    })
    
    const data = await res.json()
    
    if (!res.ok) {
      throw new Error(data.message || 'Failed to send email')
    }
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})



