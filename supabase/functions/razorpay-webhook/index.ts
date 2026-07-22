// Razorpay webhook — called directly by Razorpay's servers on payment
// events, independent of the Flutter app. This is the defense-in-depth
// half of "live payments": even if the client crashes or loses connectivity
// right after paying (so it never calls razorpay-verify-payment), Pro still
// activates because Razorpay hits this endpoint regardless.
//
// No user JWT is available here (Razorpay isn't "logged in" as anyone), so
// this uses the service_role key — the one function in this project that
// legitimately bypasses RLS, scoped tightly to only ever touch the specific
// user_id embedded in the order's notes at creation time (see
// razorpay-create-order), never a client-supplied value.
//
// Setup (Razorpay Dashboard → Settings → Webhooks → Add New Webhook):
//   URL: https://rfrddfjtmrtfhqlvvqzf.supabase.co/functions/v1/razorpay-webhook
//   Active events: payment.captured
//   Secret: generate one, then `supabase secrets set RAZORPAY_WEBHOOK_SECRET=...`
//           with the SAME value you put in the Razorpay dashboard.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET");
  if (!webhookSecret) {
    console.error("RAZORPAY_WEBHOOK_SECRET not configured");
    return new Response(JSON.stringify({ error: "Webhook not configured" }), { status: 500 });
  }

  // Signature is computed over the raw body — must read as text before
  // any JSON parsing.
  const rawBody = await req.text();
  const signature = req.headers.get("x-razorpay-signature");
  if (!signature) return new Response(JSON.stringify({ error: "Missing signature" }), { status: 400 });

  const expected = await hmacSha256Hex(webhookSecret, rawBody);
  if (!timingSafeEqual(expected, signature)) {
    return new Response(JSON.stringify({ error: "Invalid signature" }), { status: 400 });
  }

  let payload: {
    event?: string;
    payload?: { payment?: { entity?: { id?: string; order_id?: string; notes?: Record<string, string> } } };
  };
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400 });
  }

  if (payload.event !== "payment.captured") {
    // Ack anything else so Razorpay doesn't retry — we just don't act on it.
    return new Response(JSON.stringify({ ok: true, ignored: payload.event }), { status: 200 });
  }

  const entity = payload.payload?.payment?.entity;
  const orderId = entity?.order_id;
  const paymentId = entity?.id;
  const userId = entity?.notes?.user_id;
  const plan = entity?.notes?.plan ?? "pro";

  if (!orderId || !paymentId || !userId) {
    console.error("payment.captured missing order_id/payment_id/notes.user_id", entity);
    return new Response(JSON.stringify({ ok: true, warning: "missing identifiers, skipped" }), { status: 200 });
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const now = new Date();
  const expiresAt = new Date(now);
  expiresAt.setFullYear(expiresAt.getFullYear() + 1);

  await Promise.all([
    supabaseAdmin
      .from("plan_subscriptions")
      .update({
        razorpay_payment_id: paymentId,
        status: "active",
        started_at: now.toISOString(),
        expires_at: expiresAt.toISOString(),
      })
      .eq("razorpay_order_id", orderId)
      .eq("user_id", userId),
    supabaseAdmin
      .from("profiles")
      .update({ plan, plan_expires_at: expiresAt.toISOString() })
      .eq("id", userId),
  ]);

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
