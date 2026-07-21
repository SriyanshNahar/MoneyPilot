// Creates a Razorpay order server-side — the key secret must never reach
// the mobile client. Ports src/lib/razorpay.functions.ts's
// createRazorpayOrder. Configure with:
//   supabase secrets set RAZORPAY_KEY_ID=... RAZORPAY_KEY_SECRET=...
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    await requireUser(req);

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
        notes: { plan },
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      return jsonResponse({ error: `Razorpay order failed: ${res.status} ${text}` }, 502);
    }

    const order = await res.json();
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
