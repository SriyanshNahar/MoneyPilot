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
supabase functions deploy send-alert
```

## Required secrets

```bash
supabase secrets set GEMINI_API_KEY=...          # https://aistudio.google.com/apikey
supabase secrets set RAZORPAY_KEY_ID=...
supabase secrets set RAZORPAY_KEY_SECRET=...
supabase secrets set RESEND_API_KEY=...          # optional — email alerts only
```

`SUPABASE_URL` / `SUPABASE_ANON_KEY` are injected automatically by the
Supabase platform at runtime — no need to set them manually.

## Storage bucket

Avatar uploads (Settings → profile photo) use a public-read, owner-write
`avatars` storage bucket, same as the React app. If it doesn't already exist
on the project:

```bash
supabase storage buckets create avatars --public
```
