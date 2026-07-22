// Creates a Razorpay order server-side — the key secret must never reach
// the mobile client. Ports src/lib/razorpay.functions.ts's
// createRazorpayOrder. v2.1: also records a 'created' row in
// plan_subscriptions and stamps the order's notes with user_id, so both the
// client's verify call AND the (independent) razorpay-webhook can attribute
// the payment to the right account.
// Configure with:
//   supabase secrets set RAZORPAY_KEY_ID=... RAZORPAY_KEY_SECRET=...
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { requireUserWithClient } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const { user, supabase } = await requireUserWithClient(req);

    const { amount, currency = "INR", plan } = await req.json();
    if (typeof amount !== "number" || !Number.isInteger(amount) || amount < 100) {
      return jsonResponse({ error: "Invalid amount (paise, integer, min 100)" }, 400);
    }
    if (typeof plan !== "string" || plan.length === 0) {
      return jsonResponse({ error: "Missing plan" }, 400);
    }

    const keyId = Deno.env.get("RAZORPAY_KEY_ID");
    const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET");
    if (!keyId || !keySecret) return jsonResponse({ error: "Razorpay keys not configured" }, 500);

    const auth = btoa(`${keyId}:${keySecret}`);
    const res = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${auth}`,
      },
      body: JSON.stringify({
        amount,
        currency,
        receipt: `rcpt_${Date.now()}`,
        notes: { plan, user_id: user.id },
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      return jsonResponse({ error: `Razorpay order failed: ${res.status} ${text}` }, 502);
    }

    const order = await res.json();

    const { error: insertError } = await supabase.from("plan_subscriptions").insert({
      user_id: user.id,
      plan,
      amount_paise: amount,
      razorpay_order_id: order.id,
      status: "created",
    });
    if (insertError) {
      // Non-fatal — the webhook/verify step can still complete the payment;
      // this row is bookkeeping, not the source of truth for whether Razorpay
      // charged the customer.
      console.error("plan_subscriptions insert failed", insertError);
    }

    return jsonResponse({
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
      key_id: keyId,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Could not start payment";
    const status = message === "Unauthorized" || message === "Missing Authorization header" ? 401 : 500;
    return jsonResponse({ error: message }, status);
  }
});
