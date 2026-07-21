// Verifies a Razorpay payment signature server-side (HMAC-SHA256 with the
// key secret) — ports src/lib/razorpay.functions.ts's verifyRazorpayPayment.
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";

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
    await requireUser(req);

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

    return jsonResponse({ verified: true, payment_id: razorpay_payment_id });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Verification failed";
    const status = message === "Unauthorized" || message === "Missing Authorization header" ? 401 : 500;
    return jsonResponse({ error: message }, status);
  }
});
