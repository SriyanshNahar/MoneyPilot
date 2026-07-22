// AI money-coach chat, deployed as a Supabase Edge Function.
//
// v2.1: replaced Gemini with Anthropic Claude (latest stable model),
// streaming responses (Anthropic's native SSE format, passed straight
// through to the Flutter client), and automatic expense/budget grounding —
// this function fetches a compact summary of the caller's OWN data
// (RLS-scoped, via requireUserWithClient) so "analyze my expenses" /
// "help me budget" answers are based on their real numbers, not generic
// advice.
//
// Configure with:
//   supabase secrets set ANTHROPIC_API_KEY=...
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { requireUserWithClient } from "../_shared/auth.ts";

const MODEL = "claude-sonnet-5";

const SYSTEM_PROMPT = `You are MoneyPilot Coach, a friendly AI money coach inside the MoneyPilot app for Indian users.

Your mission: help the user save more, spend smarter, and grow their money without wasting it.

Capabilities:
- Expense analysis: read the "User's current financial snapshot" block below (if present) and reference real numbers back to the user
- Financial advice tailored to their situation
- Budget planning (50/30/20 rule, zero-based budgeting, category-level tightening)
- EMI suggestions: prepayment strategy, avalanche vs snowball, refinancing signals
- Investment suggestions: SIPs, mutual funds, index funds, PPF, NPS, ELSS, FDs (general/educational only)
- Savings tips: cutting subscriptions, food delivery, impulse buys, high-fee products; building a 3-6 month emergency fund
- Goal planning: help size a target corpus and monthly contribution for a stated goal (house, wedding, retirement, education)
- Tax saving under 80C / 80D / new vs old regime
- Compound interest and long-term wealth building

Style rules:
- Reply in clear, professional English. Short paragraphs and bullet points.
- All amounts in Indian Rupees (₹). Use lakh and crore where natural.
- Stay educational and general. Never name specific stocks/funds or promise returns.
- Always give 1-3 concrete, actionable next steps.
- For complex decisions, suggest a SEBI-registered advisor.
- Keep replies under 220 words unless the user asks for more detail.
- Never share phone numbers, emails, or direct contact links.`;

type Msg = { role: "user" | "assistant"; content: string };

async function buildFinancialSnapshot(supabase: SupabaseClient, uid: string): Promise<string> {
  try {
    const since = new Date();
    since.setDate(since.getDate() - 30);
    const sinceIso = since.toISOString().slice(0, 10);

    const [{ data: expenses }, { data: loans }, { data: subs }, { data: invs }] = await Promise.all([
      supabase.from("expenses").select("amount, category, expense_date").eq("user_id", uid).gte("expense_date", sinceIso).limit(500),
      supabase.from("loans").select("emi").eq("user_id", uid),
      supabase.from("subscriptions").select("amount, billing_cycle").eq("user_id", uid).eq("is_active", true),
      supabase.from("investments").select("amount").eq("user_id", uid),
    ]);

    const byCategory = new Map<string, number>();
    let total30d = 0;
    for (const e of expenses ?? []) {
      const amt = Number(e.amount) || 0;
      total30d += amt;
      byCategory.set(e.category, (byCategory.get(e.category) ?? 0) + amt);
    }
    const topCategories = [...byCategory.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([cat, amt]) => `${cat}: ₹${Math.round(amt).toLocaleString("en-IN")}`)
      .join(", ");

    const totalEmi = (loans ?? []).reduce((s, l) => s + (Number(l.emi) || 0), 0);
    const totalSip = (invs ?? []).reduce((s, i) => s + (Number(i.amount) || 0), 0);
    const totalSubs = (subs ?? []).reduce((s, sub) => {
      const amt = Number(sub.amount) || 0;
      return s + (sub.billing_cycle === "yearly" ? amt / 12 : amt);
    }, 0);

    if (total30d === 0 && totalEmi === 0 && totalSip === 0 && totalSubs === 0) {
      return "";
    }

    return `\n\nUser's current financial snapshot (last 30 days, all figures in ₹, use only if relevant to their question):
- Total spend (30d): ₹${Math.round(total30d).toLocaleString("en-IN")}
- Top categories: ${topCategories || "none recorded"}
- Monthly EMI commitments: ₹${Math.round(totalEmi).toLocaleString("en-IN")}
- Monthly SIP/investment commitments: ₹${Math.round(totalSip).toLocaleString("en-IN")}
- Approx. monthly subscription spend: ₹${Math.round(totalSubs).toLocaleString("en-IN")}`;
  } catch {
    // Snapshot is a nice-to-have; never block the chat if it fails.
    return "";
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const { user, supabase } = await requireUserWithClient(req);

    const body = await req.json();
    const messages = body?.messages as Msg[] | undefined;
    if (!Array.isArray(messages) || messages.length === 0 || messages.length > 40) {
      return new Response(JSON.stringify({ error: "Invalid messages payload" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    for (const m of messages) {
      if (typeof m.content !== "string" || m.content.length === 0 || m.content.length > 4000) {
        return new Response(JSON.stringify({ error: "Invalid message content" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "AI is not configured. Missing ANTHROPIC_API_KEY." }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const snapshot = await buildFinancialSnapshot(supabase, user.id);

    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 1024,
        system: SYSTEM_PROMPT + snapshot,
        messages: messages.map((m) => ({ role: m.role, content: m.content })),
        stream: true,
      }),
    });

    if (!anthropicRes.ok || !anthropicRes.body) {
      const status = anthropicRes.status;
      const text = await anthropicRes.text().catch(() => "");
      const message = status === 429 ? "Too many requests. Please wait a moment and try again." : `AI request failed: ${status} ${text}`;
      return new Response(JSON.stringify({ error: message }), {
        status: status === 429 ? 429 : 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Pass Anthropic's SSE stream straight through — the Flutter client
    // parses `content_block_delta` events itself (see ai_repository.dart).
    return new Response(anthropicRes.body, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "AI request failed";
    const status = message === "Unauthorized" || message === "Missing Authorization header" ? 401 : 500;
    return new Response(JSON.stringify({ error: message }), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
