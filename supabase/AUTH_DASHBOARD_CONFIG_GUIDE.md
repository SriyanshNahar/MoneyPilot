# MoneyPilot — Auth Dashboard Configuration Guide (Backend Phase 2)

Two dashboard-only configuration gaps block full third-party sign-in. Neither
requires a code change or app rebuild — both are settings entered into the
**Google Cloud Console** and the **Supabase Dashboard** (project
`rfrddfjtmrtfhqlvvqzf`) by whoever holds those logins. Confirmed live against
the project on 2026-07-23 (see `AUTHENTICATION_VERIFICATION_REPORT.md` for
the raw evidence).

---

## 1. Google Sign-In

**Current state (confirmed live):**
```
GET https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/authorize?provider=google
→ 400 {"code":400,"error_code":"validation_failed","msg":"Unsupported provider: missing OAuth secret"}
```
The Google provider toggle is on, but no Client ID/Secret has been entered.
The app calls `signInWithOAuth(OAuthProvider.google, ...)`
(`lib/features/auth/auth_screen.dart:108`) — Supabase's **browser-redirect**
flow, not Google's native Android SDK. That means the OAuth client Google
needs is a **Web application** client, not an Android client.

### Steps

1. **Google Cloud Console** → [console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
   (select/create the project you want to back this app).
2. **Create Credentials → OAuth client ID**.
   - Application type: **Web application** (not Android — see note above).
   - Name: anything recognizable, e.g. "MoneyPilot Supabase Auth".
   - Authorized redirect URIs → add exactly:
     ```
     https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/callback
     ```
   - Save. Copy the **Client ID** and **Client Secret** shown.
3. **Supabase Dashboard** → your project → **Authentication → Providers →
   Google**.
   - Toggle **Enabled** (already on).
   - Paste **Client ID** and **Client Secret** from step 2.
   - Save.
4. Re-run the check below — a real config returns a `302` redirect to
   Google's consent screen, not a `400`:
   ```bash
   curl -i "https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/authorize?provider=google"
   ```

### On the Android SHA-1 / SHA-256 fingerprints

**Not required for this fix.** The app never calls Google's native Android
Sign-In SDK — it opens Google's consent page in an external browser tab and
comes back via the `io.moneypilot.app://login-callback` deep link (already
registered in `AndroidManifest.xml`). Google only checks SHA fingerprints
against an **Android-type** OAuth client, which this flow doesn't use.

Extracted anyway, in case you later want a defensive Android-type client (or
switch to the native Google Sign-In SDK) — from the actual project keystores:

| Keystore | SHA-1 | SHA-256 |
|---|---|---|
| Release (`android/keystore/moneypilot-upload.jks`) | `BF:92:C1:21:DA:81:FC:D2:AF:33:70:59:A3:DA:93:C3:7F:2F:E9:F6` | `06:BF:69:8C:DD:D3:16:24:47:EB:C0:B1:B9:94:16:73:AE:A7:8D:2F:5E:B8:5A:C1:FA:CF:D0:DB:D2:27:32:BC` |
| Debug (`~/.android/debug.keystore`) | `38:C2:A9:F3:AE:6A:34:BD:D9:27:27:F8:73:88:6A:39:77:ED:E0:43` | `8B:C0:12:1C:E3:75:F0:6A:0A:9E:27:4A:36:0A:11:CF:39:14:B5:21:84:6F:9B:65:C8:57:E8:84:85:0F:6C:B0` |

Package/bundle ID for reference: `io.moneypilot.app` (confirmed in
`android/app/build.gradle.kts` and `ios/Runner.xcodeproj/project.pbxproj`).

---

## 2. Apple Sign-In

**Current state (confirmed live)** — testing the endpoint the app actually
uses (`signInWithIdToken`, not the redirect flow):
```
POST https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/token?grant_type=id_token
body: {"provider":"apple","id_token":"garbage"}
→ 400 {"code":400,"error_code":"validation_failed","msg":"Unable to detect issuer in ID token for Apple provider"}
```
This is a **token-parsing error**, materially different from Google's
"missing OAuth secret" rejection — it means Supabase already has an Apple
provider configuration in place that gets far enough to attempt reading the
token's issuer before failing. This is a correction to earlier Phase 1
reporting, which had assumed Apple needed the identical fix as Google based
on testing the wrong endpoint (the redirect-based `/authorize?provider=apple`
endpoint, which this app never calls for Apple). See the Verification Report
for the full before/after evidence.

Practically: **verify** the existing config rather than assume it needs to
be built from scratch. Still walking through the full steps below so every
value is confirmed correct, since a stale or mismatched value (e.g. wrong
Bundle/Client ID) can produce this same error.

### Steps

1. **Apple Developer Portal** → [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers)
   - Confirm **Bundle ID** `io.moneypilot.app` exists under **Identifiers**
     and has the **Sign in with Apple** capability checked (App ID
     configuration, not a Services ID — the client uses the native
     `sign_in_with_apple` flow with this Bundle ID as-is, no web relay
     needed since there's no Android Apple flow in this app).
   - Under **Identifiers → Services IDs**, confirm (or create) a Services ID
     — this is the **Client ID** Supabase needs for its Apple provider. It
     does not have to match the Bundle ID exactly, but Supabase's Apple
     provider config expects whichever identifier value was used to
     generate the key below.
   - Under **Keys**, confirm there's a key with the **Sign in with Apple**
     capability enabled. Note its **Key ID**. If it doesn't exist, create
     one and download the `.p8` file immediately (Apple only lets you
     download it once).
   - Note your **Team ID** (top-right of the Developer Portal, or
     **Membership** page).
2. **Supabase Dashboard** → **Authentication → Providers → Apple**.
   - Confirm/enter:
     - **Client ID(s)**: the Services ID (or Bundle ID, per Supabase's
       Apple provider docs — whichever was used when the key was issued)
     - **Team ID**
     - **Key ID**
     - **Private Key**: paste the full contents of the `.p8` file
   - Save.
3. Re-run the check below — once correctly configured, a **well-formed but
   fake** JWT (correct structure, invalid signature) should return `"Bad ID
   token"` rather than an issuer-detection failure; a real device-issued
   token will return a real session:
   ```bash
   curl -X POST "https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/token?grant_type=id_token" \
     -H "apikey: <anon key>" -H "Content-Type: application/json" \
     -d '{"provider":"apple","id_token":"<token from an iOS device>"}'
   ```

### Client-side confirmation (already correct, no action needed)

- `ios/Runner/Runner.entitlements`: `com.apple.developer.applesignin =
  [Default]` ✅
- Xcode capability: present (entitlements file wired into the build) ✅
- `lib/features/auth/apple_sign_in.dart`: nonce-hashed
  `signInWithIdToken(provider: OAuthProvider.apple, ...)` ✅
- iOS-only by design (Android has no Apple button) — this satisfies Apple's
  App Store Review Guideline 4.8, which only requires an Apple option exist
  somewhere the app offers third-party sign-in, not on every platform.
  Extending to Android would need a Services ID + web redirect relay, which
  needs Apple Developer credentials this project doesn't have configured
  for that purpose — not pursued here as it's out of scope for what's being
  verified.
