# MoneyPilot — Authentication Verification Report (Backend Phase 2)

Date: 2026-07-23. Scope: verify every item on the Phase 2 Implement/Verify
list against actual code and the live Supabase project
(`rfrddfjtmrtfhqlvvqzf`). Every claim below states exactly how it was
checked — static code read, live API call, or live emulator test — so
nothing here is asserted without evidence.

---

## Implement

| Item | Status | Evidence |
|---|---|---|
| Google Login | ⚠️ Client correct, **Dashboard config missing** | Client: `signInWithOAuth(OAuthProvider.google, redirectTo: oauthRedirectUrl, authScreenLaunchMode: externalApplication)` in `auth_screen.dart:108`. Live: `GET /auth/v1/authorize?provider=google` → `400 "Unsupported provider: missing OAuth secret"` (unchanged since Phase 1). Fix is Dashboard-only — see `AUTH_DASHBOARD_CONFIG_GUIDE.md` §1. |
| Apple Login | ✅ Implemented, **appears already configured** | Client: nonce-hashed `signInWithIdToken(provider: OAuthProvider.apple, idToken, nonce)` in `apple_sign_in.dart`. Live: `POST /auth/v1/token?grant_type=id_token` with a fake token → `400 "Unable to detect issuer in ID token for Apple provider"` — a token-parsing error, not a missing-provider error (contrast with Google's rejection above). This is a correction to earlier reporting; see "Correction" section below. |
| Email Login verification | ✅ Implemented and live-tested | `signInWithPassword` / `signUp` in `auth_screen.dart`. Live emulator test: created a real throwaway account, confirmed server-side via direct API call, and confirmed the app correctly blocks sign-in with `"Email not confirmed"` pre-confirmation. Full detail in `LOGIN_TEST_REPORT.md`. |
| Password Reset verification | ✅ Implemented (code-verified, not live-tested) | `forgot_password_flow.dart`: `resetPasswordForEmail` → `verifyOTP(type: recovery)` → `updateUser(password: ...)`. Not live-tested this pass (would require receiving a real OTP email — no test mailbox available in this environment); this exact flow was previously implemented in Backend Phase 1 and is unchanged. |
| Session Restore | ✅ Implemented (code-verified) | `AuthController._init()` reads `supabase.auth.currentSession` synchronously right after `Supabase.initialize()` and seeds `AuthState` with it (`auth_controller.dart`). This is `supabase_flutter`'s built-in persisted-session behavior (secure storage-backed), not custom code — nothing in this app can accidentally skip or break it since there's no manual session-loading logic to get wrong. Not independently live-tested this pass (the only account available for a full logged-in-session test was the unconfirmed throwaway account, which never reaches a signed-in state — see Login Test Report for why). |
| Refresh Token handling | ✅ Implemented (SDK-level, code-verified) | Automatic background refresh is internal to `supabase_flutter` under PKCE flow (`authFlowType: AuthFlowType.pkce` in `supabase_config.dart`) — no custom refresh-token code exists in this codebase to audit beyond confirming the flow type is set correctly, which it is. |

## Verify

| Item | Status | Evidence |
|---|---|---|
| Android Login | ✅ Live-tested | Full signup flow run to completion on the Android emulator (Pixel_7, API level per AVD default): typed a fresh Name/Email/Password, tapped Create Account, confirmed the request reached Supabase and the correct post-signup state (unconfirmed) was reflected back in the UI. See Login Test Report. |
| iOS Login | ❌ Not tested — categorically impossible from this environment | This is a Windows machine with no macOS host, no Xcode, and no iOS Simulator available. There is no way to launch or interact with an iOS build here. This is a hard environment limitation, not a skipped step. |
| Existing Session | ⚠️ Not live-tested this pass | The emulator's only session was the real user's, which was logged out in an earlier session (disclosed previously in `FINAL_DEPLOYMENT_REPORT.md`) — I did not sign back in as the real user to test this, per standing instructions never to touch real user credentials. Code-level guarantee (SDK-managed persisted session, see Session Restore row above) stands, but there is no fresh live confirmation of "kill app, relaunch, still signed in" in this pass. |
| Logout | ✅ Implemented (code-verified, not live-tested this pass) | `SettingsScreen._signOut()` calls `authControllerProvider.notifier.signOut()` → `supabase.auth.signOut()` (`settings_screen.dart:87-89`, wired to the "Logout Account" row at line 242). Not live-tested this pass for the same reason as Existing Session — no signed-in test session was available (the throwaway account never confirmed, and the real account wasn't signed back into). |
| Profile Sync | ⚠️ Not live-tested this pass | `profile_repository.dart` reads/writes `profiles` via `fetchName`, `fetchFull`, `updateNames`, etc., scoped by RLS (`20260723000003_backend_phase1_rls_hardening.sql`) to `auth.uid() = id`. Requires an authenticated session to exercise, which wasn't available this pass for the reason above. |

---

## Correction to earlier reporting

Backend Phase 1's deployment guide states Apple "needs the equivalent" fix
to Google (Services ID + Team ID + Key ID + `.p8` key) alongside Google's
OAuth secret gap, phrased as if both were in the same broken state. That
conclusion was based on testing `GET /auth/v1/authorize?provider=apple` —
the **OAuth-redirect** endpoint — which returned the same "missing OAuth
secret" error as Google.

This app never calls that endpoint for Apple. `apple_sign_in.dart` uses
`signInWithIdToken`, which hits `POST /auth/v1/token?grant_type=id_token`
instead — a different code path in Supabase's auth server with different
configuration requirements. Testing that actual endpoint this pass with
three escalating levels of dummy token:

1. Plain garbage string → same generic parsing failure.
2. Structurally invalid JWT-shaped string → same.
3. Well-formed (correct header/payload/signature-shape), fake-signed JWT →
   `"Unable to detect issuer in ID token for Apple provider"` — a
   content-level validation error, meaning Supabase got far enough to parse
   the JWT and inspect its claims before rejecting it.

A provider with **no** configuration at all fails immediately and generically
(exactly like Google's `"missing OAuth secret"`), before ever looking at
token content. Apple's behavior here is inconsistent with "unconfigured" —
it strongly suggests Apple already has *some* provider config in the
Supabase Dashboard. The Dashboard Config Guide still walks through
confirming every Apple value (Services ID / Team ID / Key ID / key
contents) rather than assuming it's fully correct, since a stale or
mismatched identifier could produce this same error — but the prior
blanket "same fix needed as Google" claim was incorrect and is retracted
here.

---

## What was not verified, and why

- **iOS anything**: no macOS/Xcode/Simulator access from this Windows
  environment — a hard blocker, not a time-saving skip.
- **Existing Session / Logout / Profile Sync live tests**: required a
  signed-in session. The only account this pass could safely create
  (`moneypilot.qa.phase2@example.com`) never reached a signed-in state
  because Supabase requires email confirmation
  (`mailer_autoconfirm: false`) and that address uses the reserved
  `@example.com` domain, which cannot receive real mail. Using the real
  user's account instead was ruled out per standing instructions never to
  sign in as the real user. This is a genuine gap, not a fabricated pass —
  flagged explicitly rather than claiming these were tested.
- **Password Reset OTP flow end-to-end**: same reasoning — would need a
  real receivable mailbox to receive the OTP code.
