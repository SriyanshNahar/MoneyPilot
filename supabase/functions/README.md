# MoneyPilot Edge Functions

These Deno edge functions replace the TanStack Start server routes from the
React app (`src/lib/ai.functions.ts`, `razorpay.functions.ts`,
`alerts.functions.ts`, `src/routes/api/public/**`). A mobile app can't run a
Node/TanStack server, and secrets (AI key, Razorpay secret, Resend key) must
never ship inside the Flutter binary, so each one now runs server-side here
and is called from Dart via `supabase.functions.invoke('<name>')`.

They deploy to the **same** Supabase project the React app already uses
(`rfrddfjtmrtfhqlvvqzf`) — this folder does not need its own Supabase
project, just the CLI linked to the existing one.

## Deploy

```bash
supabase login
supabase link --project-ref rfrddfjtmrtfhqlvvqzf
supabase functions deploy ai-chat
supabase functions deploy razorpay-create-order
supabase functions deploy razorpay-verify-payment
supabase functions deploy razorpay-webhook
supabase functions deploy send-alert
```

See `../BACKEND_DEPLOYMENT_GUIDE.md` (repo root of this `supabase/` folder) for
the full Phase 1 deployment sequence — migrations, storage, secrets and
Supabase Dashboard steps in the order they need to run.

## Required secrets

```bash
supabase secrets set ANTHROPIC_API_KEY=...       # https://console.anthropic.com/settings/keys
supabase secrets set RAZORPAY_KEY_ID=...
supabase secrets set RAZORPAY_KEY_SECRET=...
supabase secrets set RAZORPAY_WEBHOOK_SECRET=... # Dashboard → Settings → Webhooks → your webhook's secret
supabase secrets set RESEND_API_KEY=...          # optional — email alerts only
```

`ai-chat` calls Anthropic's Claude API (`claude-sonnet-5`) with streaming
enabled, and automatically includes a summary of the caller's own last-30-day
spending (fetched RLS-scoped, using their own JWT — never bypasses row
security) so answers about "my expenses" or "my budget" are grounded in real
numbers, not generic advice.

`SUPABASE_URL` / `SUPABASE_ANON_KEY` are injected automatically by the
Supabase platform at runtime — no need to set them manually.

## Storage buckets

Both buckets are **private** — the app never reads via a public URL, only
via `storage.createSignedUrl()`, with objects scoped to a
`<auth.uid()>/...` folder per user:

- `avatars` — profile photo (Settings). Created by migration
  `20260721000000_create_avatars_bucket.sql`.
- `receipts` — expense receipt images/PDFs (the `expenses.receipt_url`
  column already exists in the schema; no client UI writes to it yet).
  Created by migration `20260723000002_create_receipts_bucket.sql`.

Both run automatically with `supabase db push` — no separate
`supabase storage buckets create` step needed.
