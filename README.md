# MoneyPilot (Flutter)

Native Android/iOS port of the MoneyPilot React web app — personal finance
for India: expenses, EMIs, SIPs, subscriptions and bill reminders in ₹.

This is a from-scratch Flutter rebuild of `MoneyPilot (React)`, sharing the
same Supabase backend (project `rfrddfjtmrtfhqlvvqzf`) and database schema.
The React app is the source of truth for behavior; this app was migrated
screen-for-screen against it and is not itself modified by that project.

## Stack

- **State/routing:** flutter_riverpod + go_router
- **Backend:** supabase_flutter (Postgres + Auth + Storage + Edge Functions)
- **Local-only data:** shared_preferences (theme, plan cache) + flutter_secure_storage (App Lock PIN/pattern/biometric flag)
- **Payments:** razorpay_flutter (native checkout) + server-side order creation/verification
- **Biometrics:** local_auth (Face ID / fingerprint)

## Run locally

```bash
flutter pub get
flutter run
```

Supabase URL/anon key are baked in as defaults (same publishable values the
React app ships) but can be overridden:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Backend edge functions

The AI Coach, Razorpay payments, and alert sending need small server-side
functions (secrets can't live in a mobile binary) — see
[`supabase/functions/README.md`](supabase/functions/README.md) for deployment
and required secrets.

## Windows build note

Building with Flutter plugins on Windows requires Developer Mode (for
symlink support): run `start ms-settings:developers` and enable it, or
`flutter build` will fail with a symlink error. `flutter analyze` and
`flutter test` do not require this.

## Platform notes

- **Android:** package id `io.moneypilot.app`, minSdk 23 (required by
  `local_auth`). `MainActivity` extends `FlutterFragmentActivity` (required
  for the biometric prompt).
- **iOS:** bundle id `io.moneypilot.app`. Building/signing requires macOS +
  Xcode — not possible from Windows regardless of this project's setup.
- **Google Sign-In:** uses Supabase's OAuth browser flow with redirect
  `io.moneypilot.app://login-callback` (already registered in both native
  manifests). Add that same URL to the Supabase Auth → URL Configuration →
  Redirect URLs list, and confirm the Google provider is enabled there (the
  React app already has it configured on the same project).
