// Sends a test alert over email/SMS/WhatsApp — ports
// src/lib/alerts.functions.ts's sendAlert. Email goes out via Resend
// directly (the React version proxied it through Lovable's connector
// gateway, which isn't available outside Lovable Cloud). SMS/WhatsApp are
// intentionally left as an informative stub until a provider (e.g. Twilio)
// is connected, matching the original app's behaviour.
//   supabase secrets set RESEND_API_KEY=...
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";

type Channel = "email" | "sms" | "whatsapp";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const user = await requireUser(req);

    const { channels, phone, email, message } = await req.json();
    if (!Array.isArray(channels) || channels.length === 0) {
      return jsonResponse({ error: "At least one channel is required" }, 400);
    }
    if (typeof message !== "string" || message.length === 0 || message.length > 500) {
      return jsonResponse({ error: "Invalid message" }, 400);
    }

    const results: Record<string, { ok: boolean; info: string }> = {};

    if ((channels as Channel[]).includes("email")) {
      const to = email ?? user.email;
      const resendKey = Deno.env.get("RESEND_API_KEY");
      if (resendKey && to) {
        try {
          const r = await fetch("https://api.resend.com/emails", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${resendKey}`,
            },
            body: JSON.stringify({
              from: "MoneyPilot <onboarding@resend.dev>",
              to: [to],
              subject: "MoneyPilot Alert",
              html: `<p>${message}</p>`,
            }),
          });
          results.email = { ok: r.ok, info: r.ok ? `Sent to ${to}` : `Failed (${r.status})` };
        } catch (e) {
          results.email = { ok: false, info: e instanceof Error ? e.message : "Error" };
        }
      } else {
        results.email = { ok: false, info: "Connect Resend to enable email" };
      }
    }

    if ((channels as Channel[]).includes("sms")) {
      results.sms = { ok: false, info: phone ? "Connect Twilio to enable SMS" : "Add a phone number first" };
    }
    if ((channels as Channel[]).includes("whatsapp")) {
      results.whatsapp = { ok: false, info: phone ? "Connect WhatsApp Business API to enable" : "Add a phone number first" };
    }

    return jsonResponse({ results });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Failed to send alert";
    const status = message === "Unauthorized" || message === "Missing Authorization header" ? 401 : 500;
    return jsonResponse({ error: message }, status);
  }
});
