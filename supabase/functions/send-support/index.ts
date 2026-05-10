import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('ResendProtip365')

function escapeHtml(value: unknown): string {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

function normalizeText(value: unknown, maxLength: number): string {
  return String(value ?? '').trim().slice(0, maxLength)
}

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
    const safeSubject = normalizeText(subject, 200) || 'Support request'
    const safeMessage = normalizeText(message, 5000)
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
        subject: `ProTip365 Support - ${safeSubject}`,
        html: `
          <h2>New Support Request from ProTip365</h2>
          <p><strong>From:</strong> ${escapeHtml(userEmail)}</p>
          <p><strong>Date:</strong> ${new Date().toISOString()}</p>
          <p><strong>Subject:</strong> ${escapeHtml(safeSubject)}</p>
          <hr>
          <p><strong>Message:</strong></p>
          <p>${escapeHtml(safeMessage).replace(/\n/g, '<br>')}</p>
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
    const message = error instanceof Error ? error.message : 'Internal server error'
    return new Response(JSON.stringify({ error: message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})




