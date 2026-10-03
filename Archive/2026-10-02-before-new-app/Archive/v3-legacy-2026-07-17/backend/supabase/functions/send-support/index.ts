import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('ResendProtip365')
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status,
  })

const escapeHtml = (value: string) =>
  value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')

const getTextField = (body: Record<string, unknown>, key: string, maxLength: number) => {
  const value = body[key]
  if (typeof value !== 'string') {
    throw new Error(`Invalid ${key}`)
  }

  const trimmed = value.trim()
  if (trimmed.length === 0 || trimmed.length > maxLength) {
    throw new Error(`Invalid ${key}`)
  }

  return trimmed
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405)
    }

    if (!RESEND_API_KEY) {
      console.error('Missing Resend API key')
      return jsonResponse({ error: 'Support service unavailable' }, 500)
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }
    
    // Verify the user is authenticated
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    const body = await req.json() as Record<string, unknown>
    const subject = getTextField(body, 'subject', 120)
    const message = getTextField(body, 'message', 4000)
    const userEmail = user.email ?? 'Unknown'
    const safeSubject = escapeHtml(subject)
    const safeMessage = escapeHtml(message).replace(/\n/g, '<br>')
    const safeUserEmail = escapeHtml(userEmail)
    
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
          <p><strong>From:</strong> ${safeUserEmail}</p>
          <p><strong>Date:</strong> ${new Date().toISOString()}</p>
          <p><strong>Subject:</strong> ${safeSubject}</p>
          <hr>
          <p><strong>Message:</strong></p>
          <p>${safeMessage}</p>
        `
      }),
    })
    
    const data = await res.json()
    
    if (!res.ok) {
      throw new Error(data.message || 'Failed to send email')
    }
    
    return jsonResponse({ success: true })
  } catch (error) {
    console.error('send-support error:', error)
    return jsonResponse({ error: 'Unable to send support request' }, 500)
  }
})





