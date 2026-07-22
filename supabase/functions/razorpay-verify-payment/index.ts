// Verifies a Razorpay payment signature server-side (HMAC-SHA256 with the
// key secret) — ports src/lib/razorpay.functions.ts's verifyRazorpayPayment.
//
// v2.1: verification alone used to be a dead end — nothing persisted "Pro"
// anywhere except the client's local SharedPreferences cache. Now, once the
// signature checks out, this activates Pro server-side: profiles.plan +
// plan_expires_at, and marks the plan_subscriptions row active. The
// razorpay-webhook function does the same thing independently (Razorpay
// calling us directly), so Pro activation doesn't depend solely on the
// client staying online long enough to call this endpoint.
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { requireUserWithClient } from "../_shared/auth.ts";

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

  try {
    const { user, supabase } = await requireUserWithClient(req);

    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = await req.json();
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return jsonResponse({ error: "Missing payment fields" }, 400);
    }

    const secret = Deno.env.get("RAZORPAY_KEY_SECRET");
    if (!secret) return jsonResponse({ error: "Razorpay secret not configured" }, 500);

    const expected = await hmacSha256Hex(secret, `${razorpay_order_id}|${razorpay_payment_id}`);
    if (!timingSafeEqual(expected, razorpay_signature)) {
      return jsonResponse({ error: "Signature verification failed" }, 400);
    }

    const now = new Date();
    const expiresAt = new Date(now);
    expiresAt.setFullYear(expiresAt.getFullYear() + 1); // ₹49/year plan

    const { data: sub } = await supabase
      .from("plan_subscriptions")
      .select("plan")
      .eq("razorpay_order_id", razorpay_order_id)
      .eq("user_id", user.id)
      .maybeSingle();
    const plan = sub?.plan ?? "pro";

    const [{ error: subError }, { error: profileError }] = await Promise.all([
      supabase
        .from("plan_subscriptions")
        .update({
          razorpay_payment_id,
          status: "active",
          started_at: now.toISOString(),
          expires_at: expiresAt.toISOString(),
        })
        .eq("razorpay_order_id", razorpay_order_id)
        .eq("user_id", user.id),
      supabase
        .from("profiles")
        .update({ plan, plan_expires_at: expiresAt.toISOString() })
        .eq("id", user.id),
    ]);

    if (subError) console.error("plan_subscriptions update failed", subError);
    if (profileError) console.error("profiles.plan update failed", profileError);

    return jsonResponse({
      verified: true,
      payment_id: razorpay_payment_id,
      plan,
      plan_expires_at: expiresAt.toISOString(),
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Verification failed";
    const status = message === "Unauthorized" || message === "Missing Authorization header" ? 401 : 500;
    return jsonResponse({ error: message }, status);
  }
});
