# MoneyPilot — Final Deployment Report

_Latest pass: app-wide premium dropdown redesign, transparent system nav bar, Profile rename, Codemagic single-APK workflow. Earlier passes kept below as history._

## Repository

- **Repository**: `SriyanshNahar/MoneyPilot`
- **Branch**: `main`
- **Commit Hash**: `1b0d12f01434449987a056a14863f9c2b5406249`
- **Commit Message**:
  ```
  feat: premium dropdown redesign, transparent system nav bar, Profile rename, Codemagic single-APK workflow
  ```

## What shipped in this pass

### 1. Dropdown redesign (every dropdown in the app)
New shared widgets in `lib/core/widgets/`:
- **`premium_dropdown.dart`** (`PremiumDropdownField<T>`) — flat dropdown: forced white background/black text regardless of light/dark theme, rounded 16px corners, soft shadow on the closed field, white popup menu with the same radius/elevation. Used for: sub-category and payment method in the Add Expense/Event form, and the Type/Loan type/Billing cycle fields in the Investments/Loans/Subscriptions forms.
- **`grouped_dropdown.dart`** (`GroupedDropdownField`, pre-existing, restyled) — same white/black/rounded/shadow treatment, plus section headings are now larger and bold black (was small grey uppercase) with normal-weight black items underneath, matching your exact example (`INVESTMENTS` / `SIP, Step-Up SIP, ...`). Also gained a `leadingItems` option for rows that sit above any group (used for "All categories"). Used for: Money Lab's calculator picker, the Expense/Event category picker, and — newly converted from a flat ungrouped dropdown — the **Activity page's category filter**, now grouped the same way as the Add Expense category picker (by category group, e.g. Daily/Utilities/...), with "All categories" as a leading option.
- The Home page day-filter dropdown (`_WindowPicker`) already used this exact white/black/rounded/shadow style from an earlier pass — it was the reference implementation, so no change was needed there.
- No dropdown's functionality changed — same values, same `onChanged` callbacks, same navigation.

### 2. Bottom nav — extra white background behind the floating bar
Root cause: Android was drawing its own opaque system-navigation-bar background because the app never requested edge-to-edge / a transparent system bar (`windowDrawsSystemBarBackgrounds` was already `false`, but nothing told Android what color to use instead, so it fell back to its own default, showing as a plain layer behind the floating pill). Fixed with two changes, not a navbar redesign:
- `main.dart`: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` at startup.
- `app.dart`: `MaterialApp.router`'s `builder` now wraps content in `AnnotatedRegion<SystemUiOverlayStyle>` with `systemNavigationBarColor`/`statusBarColor` set to transparent, with icon brightness reactively following the current light/dark theme.
- The nav bar's own widget code (`app_shell.dart`) was **not touched** — same design, same spacing, same animation.

### 3. Profile rename
`settings_screen.dart`: the page header text changed from "Settings" to "Profile" — that's the only change. Route (`/settings`), class names (`SettingsScreen`), and all business logic are untouched, per your instruction. (The bottom-nav tab already said "Profile" from an earlier pass, so this makes the page's own header consistent with it.)

### 4–5. Google Sign-In / Supabase
Re-verified live against the Supabase project (not just recalled from memory): `GET /auth/v1/authorize?provider=google` on `rfrddfjtmrtfhqlvvqzf.supabase.co` still returns `400 — "Unsupported provider: missing OAuth secret"`. Also re-checked the Flutter client (`auth_screen.dart`'s `signInWithOAuth(OAuthProvider.google, redirectTo: oauthRedirectUrl, ...)`) and both platforms' deep-link registration (`AndroidManifest.xml`, `Info.plist`) — all correct and unchanged, confirming this is **100% a Supabase Dashboard configuration gap**, not a Flutter code issue. **No code was changed for this.** Exact steps to fix it, in the Supabase Dashboard (no migration, same Supabase project, same architecture):

1. **Google Cloud Console** (console.cloud.google.com) → APIs & Services → Credentials → Create Credentials → OAuth client ID → Application type **Web application**.
2. Under **Authorized redirect URIs**, add exactly: `https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/callback`
3. Copy the generated **Client ID** and **Client Secret**.
4. **Supabase Dashboard** → your project → Authentication → Providers → Google → paste the Client ID and Client Secret into those fields (the toggle is already ON, it's just missing these two values) → Save.
5. No database change, no new tables, nothing to migrate — this is purely filling in two text fields Supabase already has slots for.

Once step 4 is saved, the exact same `signInWithOAuth` call already in the app will work without any further code changes.

### 6. Codemagic — single APK per build
No `codemagic.yaml` existed before (the project was presumably building from Codemagic's UI-configured default Flutter workflow, which is why extra artifacts were showing up — Codemagic's default template glob picks up every APK under `build/`, including intermediate/plugin outputs). Added `codemagic.yaml` at the repo root with two explicit workflows:
- **`android-debug`** — triggers on every push to `main`, runs `flutter analyze` → `flutter test` → `flutter build apk --debug`, and publishes **only** `build/app/outputs/flutter-apk/app-debug.apk` as the artifact (an explicit path, not a wildcard).
- **`android-release`** — triggers on version tags (`v*.*.*`), same analyze/test gate, builds `flutter build apk --release`, publishes **only** `app-release.apk`. Signing is wired to Codemagic's managed "Code signing identities" feature (referenced as `moneypilot_upload_keystore`) with a script that reconstructs `android/key.properties` from the environment variables Codemagic exports for that identity — since the real keystore and `key.properties` are (correctly) gitignored and were never in the repo for Codemagic to check out.

**I could not verify this against the actual Codemagic dashboard/API** — I have no login or API access to Codemagic from this environment, so I cannot confirm the GitHub repo is connected to a Codemagic app, that a webhook fires on push, or that this file will be picked up. Manual steps you'll need to do on your end:
1. Confirm (or create) a Codemagic app connected to `SriyanshNahar/MoneyPilot` — Codemagic auto-detects `codemagic.yaml` at the repo root once connected and switches from UI-configured to config-as-code workflows.
2. For the release workflow to actually sign successfully: Codemagic → Team settings → Code signing identities → Android → upload `moneypilot-upload.jks` there, name the identity `moneypilot_upload_keystore` (or update the yaml if you name it differently), and supply the store/key passwords + alias when prompted.
3. Trigger a push (or a `v*.*.*` tag) and confirm in the Codemagic dashboard that exactly one APK artifact is produced.

## Final Verification

| Step | Result |
|---|---|
| `flutter analyze` | ✅ **0 issues** |
| `flutter test` | ✅ **3/3 passed** |
| `flutter build apk --debug` | ✅ Built `app-debug.apk` |

## Git Review (before commit)

- 9 modified files + 2 new files (`codemagic.yaml`, `lib/core/widgets/premium_dropdown.dart`) — full diff reviewed.
- Scanned for `TODO`/`FIXME`, stray `print()`, and secret-shaped strings (`sk-ant`, `rzp_live`, `rzp_test`, inline `api_key=`/`password=`) across the Dart diff **and** the new `codemagic.yaml` — **zero matches**.
- Re-confirmed `scripts/secrets.env`, `android/key.properties`, and the `.jks` keystore are all still gitignored (`git check-ignore`) and were not part of this commit.
- `flutter analyze`'s zero-issues result rules out unused imports.

## Push to GitHub

- **Push status**: ✅ Succeeded (`f97cc93..1b0d12f main -> main`)
- **Synchronization verified three independent ways**:
  - Local `git rev-parse HEAD` → `1b0d12f01434449987a056a14863f9c2b5406249`
  - `git ls-remote origin main` → `1b0d12f01434449987a056a14863f9c2b5406249`
  - GitHub REST API (`/repos/SriyanshNahar/MoneyPilot/commits/main`) → `1b0d12f01434449987a056a14863f9c2b5406249`
- All three match. Repository is synchronized; branch `main` is up to date.

## Codemagic Verification

**Not independently verifiable from this environment** — no Codemagic dashboard/API access here. See the manual steps under "Codemagic — single APK per build" above.

## Remaining Manual Deployment Steps

1. **Google Sign-In**: fill in the Client ID/Secret in Supabase Dashboard → Authentication → Providers → Google, per the exact steps above.
2. **Codemagic**: connect the repo (if not already), upload the keystore as `moneypilot_upload_keystore`, and confirm a build.
3. Still outstanding from earlier reports, unchanged by this UI-only pass: Supabase Edge Functions (`ai-chat`, `razorpay-*`) and the `goals`/`ai_chat_messages`/`plan_subscriptions` migrations are not yet deployed to the live project (`supabase db push` / `supabase functions deploy` / `supabase secrets set --env-file scripts/secrets.env`).
4. None of this pass's visual changes (dropdowns, nav bar transparency) have been eyes-on verified on a live device — all are behind login, and I have deliberately not re-authenticated as your real account this session.

## Not Yet Marked Complete

This project is **not** being marked "complete" — Codemagic connectivity/keystore upload can't be verified from here, Google Sign-In still needs the two Supabase fields filled in, the backend deployment gaps remain, and none of this pass's UI changes have been eyes-on verified live. Everything I could implement, verify, commit and push from this environment is done.

---

## History (prior passes, summarized)

- **`f97cc93`** — Upcoming Expenses header made a 1:1 mirror of Personal Events (shared `_HeaderActionChip` + `_SectionHeader(actionLabel, onAction)`).
- **`f34c574`** — First Upcoming Expenses/Personal Events consistency pass (day filter repositioned, empty state mirrored).
- **`6cfa452`** — Add Expense button repositioned beside the day-filter helper text.
- **`5af5d90` / `af1c26d`** — Premium floating bottom navigation (circular bump), adaptive/monochrome/iOS/web app icons, quote-free splash screen, grouped-header dropdowns (first version), Home quick-access row removal, typography weight cleanup.

Each historical commit passed the same analyze/test/build/git-review/push verification described above at the time it was made.
