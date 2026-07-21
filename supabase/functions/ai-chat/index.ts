// AI money-coach chat, deployed as a Supabase Edge Function.
//
// Ports src/lib/ai.functions.ts (chatWithPaisaMitra) from the React app's
// TanStack server function to a standalone edge function the Flutter app
// can call via supabase.functions.invoke('ai-chat'). The React version used
// Lovable's proprietary AI gateway; this calls Google's Gemini API directly
// (the same underlying model — google/gemini-2.5-flash) so it works outside
// the Lovable platform. Configure with:
//   supabase secrets set GEMINI_API_KEY=...
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";

const SYSTEM_PROMPT = `You are MoneyPilot Coach, a friendly AI money coach inside the MoneyPilot app for Indian users.

Your mission: help the user save more, spend smarter, and grow their money without wasting it.

Coverage:
- Budgeting (50/30/20 rule, zero-based budgeting)
- Cutting wasted spending: subscriptions, food delivery, impulse buys, high-fee products
- Building an emergency fund (3-6 months of expenses)
- Investing basics: SIPs, mutual funds, index funds, PPF, NPS, ELSS, FDs
- EMI and debt management (avalanche vs snowball, prepayment)
- Tax saving under 80C / 80D / new vs old regime
- Side income ideas suited to Indian context
- Compound interest and long-term wealth building

Style rules:
- Reply in clear, professional English. Short paragraphs and bullet points.
- All amounts in Indian Rupees (₹). Use lakh and crore where natural.
- Stay educational and general. Never name specific stocks/funds or promise returns.
- Always give 1-3 concrete, actionable next steps.
- For complex decisions, suggest a SEBI-registered advisor.
- Keep replies under 180 words unless the user asks for more detail.
- Never share phone numbers, emails, or direct contact links.`;

type Msg = { role: "user" | "assistant"; content: string };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    await requireUser(req);

    const body = await req.json();
    const messages = body?.messages as Msg[] | undefined;
    if (!Array.isArray(messages) || messages.length === 0 || messages.length > 20) {
      return jsonResponse({ error: "Invalid messages payload" }, 400);
    }
    for (const m of messages) {
      if (typeof m.content !== "string" || m.content.length === 0 || m.content.length > 2000) {
        return jsonResponse({ error: "Invalid message content" }, 400);
      }
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) return jsonResponse({ error: "AI is not configured. Missing GEMINI_API_KEY." }, 500);

    const contents = messages.map((m) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: m.content }],
    }));

    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents,
          systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
          generationConfig: { maxOutputTokens: 512, temperature: 0.7 },
        }),
      },
    );

    if (!res.ok) {
      const status = res.status;
      if (status === 429) return jsonResponse({ error: "Too many requests. Please wait a moment and try again." }, 429);
      const text = await res.text();
      return jsonResponse({ error: `AI request failed: ${status} ${text}` }, 502);
    }

    const data = await res.json();
    const reply = data?.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text ?? "").join("") ?? "";
    if (!reply) return jsonResponse({ error: "AI returned an empty response" }, 502);

    return jsonResponse({ reply });
  } catch (err) {
    const message = err instanceof Error ? err.message : "AI request failed";
    const status = message === "Unauthorized" || message === "Missing Authorization header" ? 401 : 500;
    return jsonResponse({ error: message }, status);
  }
});
