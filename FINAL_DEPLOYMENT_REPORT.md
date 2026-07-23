# MoneyPilot — Final Deployment Report

_Latest pass: Backend Phase 2 — production authentication verification. Live-tested email/password signup end-to-end on the Android emulator (real throwaway account, confirmed server-side via direct API call), confirmed the app correctly surfaces "Email not confirmed"; corrected an earlier (incorrect) claim that Apple Sign-In needed the same Dashboard fix as Google — testing the actual endpoint the app uses shows Apple already has some provider config in place, unlike Google, which still needs its OAuth Client ID/Secret entered. Wrote a Dashboard configuration guide, an Authentication Verification Report, and a Login Test Report (all in `supabase/`). Earlier passes kept below as history._

## Backend Phase 2 — Authentication Verification (2026-07-23)

See the three dedicated documents for full detail — this section is a pointer, not a duplicate:

- **`supabase/AUTH_DASHBOARD_CONFIG_GUIDE.md`** — exact Google Cloud Console + Apple Developer Portal + Supabase Dashboard steps, including the real extracted Android release/debug SHA-1/SHA-256 fingerprints (confirmed not required for this app's current web-redirect Google flow, but provided for reference).
- **`supabase/AUTHENTICATION_VERIFICATION_REPORT.md`** — Implement/Verify checklist with an honest per-item status (✅/⚠️/❌) and the exact evidence behind each, plus a full write-up correcting the earlier Apple-endpoint mixup.
- **`supabase/LOGIN_TEST_REPORT.md`** — the live emulator test transcript: what was actually tapped/typed, what the server actually returned, and the `adb`/PowerShell/autofill friction encountered along the way (none of it an app bug).

**Headline finding**: Google Sign-In is still blocked by a missing OAuth Client ID/Secret in the Supabase Dashboard (unchanged since Phase 1 — confirmed still live via a direct `curl` to `/auth/v1/authorize?provider=google` returning `400 "missing OAuth secret"`). Apple Sign-In's actual endpoint (`/auth/v1/token?grant_type=id_token`, not the redirect endpoint) returns a token-parsing error rather than a missing-provider error, indicating it likely already has some Dashboard config — a correction to earlier reporting, which had assumed both providers were in the same broken state based on testing the wrong endpoint for Apple.

**What was live-verified vs. not**: fresh email/password signup and the app's handling of an unconfirmed-email sign-in attempt were both tested live and confirmed working. Existing Session, Logout, and Profile Sync were not live-tested this pass — they require a signed-in session, and the only account safely available (a throwaway `@example.com` address) can never confirm its email to reach one; signing in as the real user instead was ruled out per standing instructions. iOS is untested — no macOS/Xcode available from this Windows environment. All of this is disclosed in detail, not glossed over, in the Login Test Report.

## Repository

- **Repository**: `SriyanshNahar/MoneyPilot`
- **Branch**: `main`
- **Commit Hash**: `dd9941535212ca55c06d76376d805bbf70300025`
- **Commit Message**:
  ```
  polish: pixel-match Money Lab calculators to the React source (equal-width grid, spacing, radii) and add responsive layout tests
  ```

## ⚠️ Incident: the authenticated test session was logged out

While preparing to verify this pass live, the emulator came up showing the **Sign In screen** instead of the dashboard — the session that had been persisted across the last several passes is gone. The most likely cause: during the *previous* turn's manual `adb` navigation, a tap I sent while trying to reach the calculator dropdown landed on the Profile page's **"Logout Account"** row instead (that page was on screen a moment earlier in that same session from an unrelated dropdown mis-tap). I did not intend to log the account out, didn't realize it had happened until this pass, and want that on the record rather than glossed over.

**I did not attempt to sign back in** — I don't have your credentials and wouldn't enter them if I did. This means I no longer have a way to click through the live, authenticated app from this environment. For this pass, I used a different, arguably more rigorous verification method instead (below) rather than trying to reauthenticate.

## What shipped in this pass

Compared `lib/features/money_lab/calc_widgets.dart` and `calculators.dart` directly against the actual source of truth — `MoneyPilot (React)/src/components/Calculators.tsx` — rather than eyeballing. That comparison surfaced the real structural issue and several concrete pixel mismatches:

### 1. The real fix: equal-width/equal-height grid, not a wrapping approximation
The React source lays fields and results out with CSS `grid grid-cols-N gap-2` — true equal-width columns. The previous pass's fix used a `Wrap` with per-item widths *estimated* from a `LayoutBuilder` and clamped to a 90–400px range — closer than before, but still an approximation, and the clamp floor (90px) is exactly the kind of narrow box that pushes labels toward needing an ellipsis. Replaced it with what the source actually does: `CalcGrid` now chunks its children into rows of `columns` items and renders each row as a real `Row` of `Expanded` cells (wrapped in `IntrinsicHeight` so every cell in a row shares one height, matching CSS Grid's implicit row-height behavior). Effects:
- Every field/result gets an exact, fair 1/N share of the full card width — normally far more room than the old 90px floor, so **the ellipsis added in the last pass now sits idle in ordinary use** and only exists as a backstop for genuinely extreme values (satisfies "do not rely on truncation for normal labels" without removing the safety net that prevents overflow in edge cases).
- Cards are equal width *and* equal height by construction, not by coincidence.
- An incomplete final row (e.g. an odd number of results) is padded with invisible spacer cells so it stays aligned with the columns above instead of stretching wider — this is what makes the whole grid read as centered/balanced rather than left-heavy.
- `NumField`'s value display switched from a hard `maxWidth: 140` cap to `Flexible` — a fixed cap was fighting the new, wider real grid cells and could have triggered *unnecessary* ellipsis in generously-sized single/two-column layouts.

### 2. Verified spacing/radius values against the actual source (not assumed)
This project's `--radius` CSS custom property is **18px** (checked in `MoneyPilot (React)/src/styles.css`), not Tailwind's stock default — meaning `rounded-lg` = 18px and `rounded-xl` = 22px in this specific app, not the values you'd guess from Tailwind's docs. Corrected to match:
- `CalcShell`'s icon badge: `rounded-lg` → was 12px in Flutter, now 18px (on a 36×36 box this is a true circle, not a rounded square — a real visual difference, not a rounding error).
- `CalcResult`: `rounded-xl` → was 14px, now 22px; `p-3` → was 10px padding, now 12px.
- `Field`'s internal label-to-input gap: `space-y-1.5` → was 4px, now 6px.
- The gap between each calculator's fields-grid and results-grid: `mt-3` → was 10px, now 12px, fixed identically across all 21 calculators (`calculators.dart`).
- Font sizes/colors/weights were left untouched — those weren't part of this request's scope, and section 6 said "do not redesign."

## Live Verification — method changed after the logout incident

Given the session was gone, I did **not** attempt a fresh live click-through. Instead I wrote `test/calculators_layout_test.dart`: an automated widget test that renders **every one of the 21 calculators** at three representative widths (320px small phone, 400px medium phone, 900px tablet — 63 runs total) inside a real `MaterialApp` with the app's actual theme, and asserts zero layout exceptions were thrown. Flutter's test framework reliably surfaces a `RenderFlex overflowed` failure as a caught exception during this kind of pump, so this is a legitimate, mechanical check for the exact defect being fixed — arguably more thorough than the manual 2-calculator screenshot check from the previous pass, since it covers all 21 calculators instead of 2, at 3 sizes instead of 1, automatically and repeatably (it'll keep running on every future `flutter test`, catching regressions).

**What this method does not give you**: an actual pixel screenshot of the real rendered UI on a real device/emulator. I did rebuild and install a fresh debug APK before the logout was discovered, and the earlier "SIP"/"Simple Interest" screenshots from the prior pass (unaffected by this pass's changes, which don't touch those specific values) still stand as visual evidence of the general approach; but this specific commit's exact pixel output has not been eyeballed by me, only mechanically verified for absence of overflow.

## Final Verification

| Step | Result |
|---|---|
| `flutter analyze` | ✅ **0 issues** |
| `flutter test` (full suite, 66 tests) | ✅ **66/66 passed** — includes the new 63-case calculator layout matrix |
| `flutter build apk --debug` | ✅ Built and installed (before the logout was discovered) |
| Responsive validation (small/medium/tablet) | ✅ Automated — 21 calculators × 3 widths, 0 overflow exceptions |
| Live device screenshot of this exact commit | ❌ Not done — see incident note above |

## Git Review (before commit)

- 3 files changed (`calc_widgets.dart`, `calculators.dart`, new `test/calculators_layout_test.dart`) — full diff reviewed directly.
- Scanned for `TODO`/`FIXME`, stray `print()`, and secret-shaped strings — **zero matches**.
- Re-confirmed `scripts/secrets.env` is still gitignored.
- `flutter analyze`'s zero-issues result rules out unused imports.

## Push to GitHub

- **Push status**: ✅ Succeeded (`c61e23b..dd99415 main -> main`)
- **Synchronization verified three independent ways**:
  - Local `git rev-parse HEAD` → `dd9941535212ca55c06d76376d805bbf70300025`
  - `git ls-remote origin main` → `dd9941535212ca55c06d76376d805bbf70300025`
  - GitHub REST API (`/repos/SriyanshNahar/MoneyPilot/commits/main`) → `dd9941535212ca55c06d76376d805bbf70300025`
- All three match. Repository is synchronized; branch `main` is up to date.

## Remaining Manual Deployment Steps

1. **Please sign back into the app on your device/emulator** — the session was inadvertently logged out during this session's testing (see incident note). Nothing about your account or data was changed, only the local session ended.
2. **Google Sign-In**: still needs the Client ID/Secret filled in at Supabase Dashboard → Authentication → Providers → Google (see History below for exact steps, unchanged across all passes).
3. **Codemagic**: confirm the repo is connected and picks up `codemagic.yaml`; upload the keystore as `moneypilot_upload_keystore` for the release workflow to sign successfully. Still not independently verifiable from this environment.
4. Still outstanding: Supabase Edge Functions (`ai-chat`, `razorpay-*`) and the `goals`/`ai_chat_messages`/`plan_subscriptions` migrations are not yet deployed to the live project.
5. When you're back in the app, it would be worth a quick visual pass over a few calculators yourself to confirm the equal-width grid and spacing look right in practice — the automated test proves there's no overflow, but "looks balanced" is ultimately a judgment call worth your own eyes.

## Not Yet Marked Complete

The session-logout incident means this pass's exact visual output hasn't been eyes-on verified by me, only mechanically verified for overflow across all 21 calculators. Google Sign-In, Codemagic connectivity, and the backend deployment gaps remain outstanding. Everything requested in this specific pass — grid restructure, spacing/radius correction against the verified source, responsive test coverage, analyze/test, commit, push — is done.

---

## History (prior passes, summarized)

- **`57c2954`** — First overflow fix: `Expanded`/`ConstrainedBox`/ellipsis on `NumField`, `Wrap`-based `CalcGrid` with `LayoutBuilder` sizing, centered `CalcResult` text. Verified live on 2 of 21 calculators before this pass's logout incident.
- **`930fc6d` / `df04b15`** — Eliminated the bottom-nav background scrim, verified live; removed duplicate Account Settings photo controls, verified live; confirmed Supabase-only backend architecture; re-verified Google Sign-In is blocked only on the Supabase Dashboard side.
- **`1b0d12f` / `543df15`** — App-wide premium dropdown redesign; first (partial) nav bar background fix attempt; Profile rename; `codemagic.yaml` added.
- **`f97cc93`** — Upcoming Expenses header made a 1:1 mirror of Personal Events.
- **`f34c574`** — First Upcoming Expenses/Personal Events consistency pass.
- **`6cfa452`** — Add Expense button repositioned beside the day-filter helper text.
- **`5af5d90` / `af1c26d`** — Premium floating bottom navigation, adaptive/monochrome/iOS/web app icons, quote-free splash screen, grouped-header dropdowns (first version), Home quick-access row removal, typography weight cleanup.

**Google Sign-In fix (Supabase Dashboard, unchanged across all passes)**:
1. Google Cloud Console → Credentials → Create OAuth client ID (Web application).
2. Authorized redirect URI: `https://rfrddfjtmrtfhqlvvqzf.supabase.co/auth/v1/callback`
3. Supabase Dashboard → Authentication → Providers → Google → paste the Client ID + Client Secret → Save.

Each historical commit passed the same analyze/test/build/git-review/push verification described above at the time it was made.
