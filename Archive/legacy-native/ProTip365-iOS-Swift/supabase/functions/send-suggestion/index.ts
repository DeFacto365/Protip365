import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("ResendProtip365");
const MAX_SUGGESTION_LENGTH = 5000;

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

serve(async (req) => {
  try {
    // Get the authorization header
    const authHeader = req.headers.get("Authorization")!;

    // Verify the user is authenticated
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: userError } = await supabaseClient.auth
      .getUser();
    if (userError || !user) {
      throw new Error("Unauthorized");
    }

    const { suggestion } = await req.json();
    if (typeof suggestion !== "string" || suggestion.trim().length === 0) {
      throw new Error("Suggestion is required");
    }
    if (suggestion.length > MAX_SUGGESTION_LENGTH) {
      throw new Error("Suggestion is too long");
    }

    const safeSuggestion = escapeHtml(suggestion.trim()).replace(/\n/g, "<br>");
    const safeUserEmail = escapeHtml(user.email || "Unknown");

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "ProTip365 <web@florabump.com>",
        to: ["web@florabump.com"],
        subject: "ProTip365 - New Suggestion",
        html: `
          <h2>New Suggestion from ProTip365</h2>
          <p><strong>From:</strong> ${safeUserEmail}</p>
          <p><strong>Date:</strong> ${new Date().toISOString()}</p>
          <hr>
          <p><strong>Suggestion:</strong></p>
          <p>${safeSuggestion}</p>
        `,
      }),
    });

    const data = await res.json();

    if (!res.ok) {
      throw new Error(data.message || "Failed to send email");
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
