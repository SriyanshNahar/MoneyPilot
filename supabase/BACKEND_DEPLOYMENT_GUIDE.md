# MoneyPilot — Backend Phase 1 Deployment Guide

Architecture: **Supabase is the entire backend** (auth, database, storage,
edge functions). **Firebase is used only for Cloud Messaging** (push
notification delivery) — nothing else. This document is the single
reference for taking the backend from "code committed" to "live on the
project" (`rfrddfjtmrtfhqlvvqzf`).

Nothing in this phase touches the Flutter UI — it is code/config that ships
to Supabase, not to the app binary.

---

## 1. Authentication

| Method | Status | Notes |
|---|---|---|
| Email + Password | ✅ Implemented | `auth_screen.dart`, `signInWithPassword` / `signUp` |
| Google | ⚠️ Client done, **Dashboard config missing** | See §1.1 below — this is the one open item in all of Authentication |
| Apple | ✅ Implemented | `sign_in_with_apple` + nonce-based `signInWithIdToken`, entitlements + Xcode capability already wired |
| Password Reset | ✅ Implemented | `forgot_password_flow.dart` — email → OTP → new password, using Supabase's native `resetPasswordForEmail`/`verifyOTP`/`updateUser` |
| Session Management | ✅ Handled by Supabase | PKCE flow (`AuthFlowType.pkce`), auto-refresh, persisted session — this is `supabase_flutter`'s built-in behavior, nothing custom to deploy |
| User Profile | ✅ Implemented | `profiles` table (pre-existing) + `profile_repository.dart`; RLS hardened in migration `20260723000003` |

### 1.1 The one real gap: Google OAuth

Confirmed live (not assumed) by calling the endpoint directly:

```
GET https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/authorize?provider=google
→ 400 {"code":400,"error_code":"validation_failed","msg":"Unsupported provider: missing OAuth secret"}
```

The Google provider toggle is on in the Supabase Dashboard, but no real
Client ID/Secret has been entered. Fix (Dashboard only, no code/deploy step):

1. **Google Cloud Console** → APIs & Services → Credentials → Create
   Credentials → OAuth client ID → Application type **Web application**.
2. Authorized redirect URI: `https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/callback`
3. **Supabase Dashboard** → Authentication → Providers → Google → paste the
   Client ID + Client Secret → Save.

Apple's provider needs the equivalent (Services ID + Team ID + Key ID + a
`.p8` private key from your Apple Developer account) under Authentication →
Providers → Apple, if it isn't already filled in there too — the client-side
Apple Sign-In code is ready either way.

---

## 2. Database

### 2.1 Table map

The table names below are what actually exists (confirmed against the
Supabase-generated `types.ts` used by the original React app, which reflects
the live schema) or newly added this phase:

| Requested | Actual table | Status |
|---|---|---|
| Users | `profiles` (+ Supabase-managed `auth.users`) | Pre-existing |
| Expenses | `expenses` | Pre-existing |
| Income | `income` | **New — migration `20260723000000`** |
| Investments | `investments` | Pre-existing |
| Loans | `loans` | Pre-existing |
| EMIs | `emi_payments` | Pre-existing (per-payment ledger, FK → `loans`) |
| SIPs | `investments` (`inv_type = 'SIP'`, `sip_day`) | Pre-existing — no separate table in the original design |
| Subscriptions | `subscriptions` | Pre-existing |
| Personal Events | `personal_events` | Pre-existing |
| Reminder Logs | `reminder_log` | Pre-existing |
| Notification Logs | `notification_logs` | **New — migration `20260723000001`** (distinct from `reminder_log`: this is a per-channel delivery record, not a dedup log) |
| AI Chat History | `ai_chat_messages` | Added in an earlier pass (migration `20260722000000`), not yet deployed |
| Premium Purchases | `plan_subscriptions` | Added in an earlier pass (migration `20260722000001`), not yet deployed |

Also pre-existing but not in the requested list, RLS-hardened anyway for
completeness: `alert_prefs`, `budgets`, `device_tokens`, `networth_items`,
`networth_snapshots`, `security_settings`. Also present from an earlier
(non-Phase-1) pass: `goals` (backs the Flutter Goals CRUD screen — not part
of the original React app, kept as-is since the UI already depends on it).

### 2.2 Row Level Security

Every table above has owner-scoped RLS (a user can only read/write their own
`user_id` — or `id` for `profiles`, which uses the auth uid directly as its
primary key). Two tables are intentionally **not** full CRUD for the client:

- `profiles`: select + update only. Nothing in the Flutter app inserts a
  profile row directly, meaning that row is created server-side (a trigger
  on `auth.users`, or handled by Supabase's dashboard-managed defaults) —
  granting client insert would widen privileges for no reason.
- `reminder_log`: select only for the user; insert/update happens via a
  server-side reminders cron running as `service_role`, which bypasses RLS
  entirely regardless of the policies below.

All policies are written idempotently (`drop policy if exists` before
`create policy`), so `supabase db push` is always safe to re-run.

### 2.3 Migration order

Run in this order (`supabase db push` applies them in filename/timestamp
order automatically, so this is just for reference):

```
20260721000000_create_avatars_bucket.sql
20260722000000_create_ai_chat_messages.sql
20260722000001_create_plan_subscriptions.sql
20260722000002_create_goals.sql
20260722000003_investments_loans_subscriptions_crud_rls.sql
20260723000000_create_income.sql                      ← new this phase
20260723000001_create_notification_logs.sql            ← new this phase
20260723000002_create_receipts_bucket.sql               ← new this phase
20260723000003_backend_phase1_rls_hardening.sql         ← new this phase
```

---

## 3. Storage

| Bucket | Access | Status |
|---|---|---|
| `avatars` | Private, owner folder (`<uid>/...`), signed URLs only | Migration exists, **not yet deployed** |
| `receipts` | Private, owner folder, signed URLs only | **New this phase** — backs the pre-existing (unused) `expenses.receipt_url` column |

Both are created via `insert into storage.buckets (...)` inside their
migration files — `supabase db push` creates them, no separate
`supabase storage buckets create` command needed.

---

## 4. Edge Functions

| Function | Purpose | Status |
|---|---|---|
| `ai-chat` | AI Coach — Claude (`claude-sonnet-5`), streaming, grounded in the caller's own last-30-day spending | ✅ Fully implemented |
| `razorpay-create-order` | Create a Razorpay order for a plan purchase | ✅ Fully implemented |
| `razorpay-verify-payment` | HMAC-verify payment + activate the plan | ✅ Fully implemented |
| `razorpay-webhook` | Server-side (service_role) fallback plan activation on `payment.captured` | ✅ Fully implemented |
| `send-alert` | Email (via Resend, working today), SMS + WhatsApp (intentionally stubbed — returns "Connect Twilio/WhatsApp Business API to enable") | ✅ Email works; SMS/WhatsApp **prepared, not implemented**, exactly as requested |

**On "prepare infrastructure for AI Coach / Razorpay / Email / SMS /
WhatsApp, don't implement yet"**: AI Coach and Razorpay are already fully
implemented from earlier phases, not merely scaffolded — flagging that
explicitly rather than re-scaffolding working code. Email is also already
live (Resend). SMS and WhatsApp are the two pieces that are genuinely only
"prepared" — `send-alert` already has the shape (channel dispatch, shared
auth/CORS, `notification_logs`-ready) for them, returning an explicit
"not connected yet" result rather than a fake success. I did not create
separate empty `send-sms`/`send-whatsapp` placeholder files, since that
would just duplicate the dispatch logic `send-alert` already has — activate
them by filling in the Twilio (SMS + WhatsApp Business API) calls inside
that same function once you have an account, rather than standing up new
infra.

---

## 5. Deployment sequence

```bash
# 1. Authenticate + link (one-time)
supabase login
supabase link --project-ref rfrddfjtmrtfhqlvvqzf

# 2. Push every migration (creates tables, RLS, storage buckets)
supabase db push

# 3. Set secrets (fill scripts/secrets.env from scripts/secrets_template.env first)
supabase secrets set --env-file scripts/secrets.env

# 4. Deploy edge functions
supabase functions deploy ai-chat
supabase functions deploy razorpay-create-order
supabase functions deploy razorpay-verify-payment
supabase functions deploy razorpay-webhook
supabase functions deploy send-alert

# 5. Dashboard-only steps (no CLI):
#    - Authentication → Providers → Google: Client ID + Secret (see §1.1)
#    - Authentication → Providers → Apple: Services ID / Team ID / Key ID / .p8 key, if not already set
#    - Razorpay Dashboard → Webhooks → point at
#      https://rfrddfjtmrtfhqlvvqzf.supabase.co/functions/v1/razorpay-webhook
```

## 6. Verifying it worked

```bash
# Tables exist and RLS is on (expect an empty array or a permission error,
# never "relation does not exist"):
curl "$SUPABASE_URL/rest/v1/income?select=id&limit=1" -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY"
curl "$SUPABASE_URL/rest/v1/notification_logs?select=id&limit=1" -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY"

# Buckets exist:
curl "$SUPABASE_URL/storage/v1/bucket" -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY"

# Functions are reachable (expect 401 "Missing Authorization header", never 404):
curl -i "$SUPABASE_URL/functions/v1/ai-chat"
```

None of the above has been run against the live project from this
environment — I don't have a Supabase CLI session or dashboard access here.
Everything in this guide is prepared and ready to run; actually running it
is a step for whoever holds the Supabase login for this project.
