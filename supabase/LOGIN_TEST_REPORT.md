# MoneyPilot — Login Test Report (Backend Phase 2)

Date: 2026-07-23. Environment: Windows, Android emulator (Pixel_7 AVD),
`adb` at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. No macOS/Xcode
available, so iOS is entirely untested (see below).

This report documents the live emulator test only. It does not repeat the
static code evidence — that's in `AUTHENTICATION_VERIFICATION_REPORT.md`.

---

## What was actually tested, step by step

1. Installed the debug build on the emulator, launched the app, arrived at
   the Sign In / Sign Up screen (the app was already logged out from a
   prior session — see standing note in `FINAL_DEPLOYMENT_REPORT.md`).
2. Switched to **Sign up**, filled:
   - Name: `MoneyPilotQA`
   - Email: `moneypilot.qa.phase2@example.com` (deliberately using the IANA-
     reserved, non-deliverable `example.com` domain — a real throwaway
     account with no real mailbox behind it, precisely so it can't be used
     for anything beyond this test)
   - Password: `QaTest2026Pw`
3. Tapped **Create account**. Button showed a loading spinner, then reset
   to idle with no error visible in the screenshot taken immediately after.
4. Confirmed the actual result **against the server**, not by guessing from
   the UI: called `POST /auth/v1/signup` directly with the same email,
   which returned the existing user object (`id`,
   `created_at: 2026-07-23T13:57:45Z` — matching the in-app tap time) with
   no `access_token`/`session` in the response. This is the correct shape
   for `mailer_autoconfirm: false`: account created, no session issued
   until the email is confirmed.
5. Switched to **Sign in**, same email/password (form state carried over).
   Tapped **Sign in** → app surfaced a red SnackBar: **"Email not
   confirmed"** — an exact match to the server-side state. This confirms
   both that the signup genuinely succeeded and that the app correctly
   translates a Supabase auth error into a user-facing message.
6. Stopped there. Since `@example.com` cannot receive the confirmation
   email, this account can never reach a signed-in state — so Existing
   Session, Logout, and Profile Sync could not be exercised with it. Signing
   in as the real user instead was ruled out per standing instructions.

## Result

| Test | Outcome |
|---|---|
| Fresh email/password signup | ✅ Real account created server-side, confirmed via direct API call |
| Post-signup UI state | ✅ No crash, no false-success message; matches "check your email" expectation for `mailer_autoconfirm: false` |
| Sign-in against unconfirmed account | ✅ App correctly shows "Email not confirmed" |
| Session restore / Logout / Profile Sync | ❌ Not reachable this pass — requires a confirmed, signed-in session (see gap explanation below) |
| iOS (any) | ❌ Not tested — no macOS/Xcode/Simulator in this environment |

## Why session/logout/profile-sync weren't completed live

Completing these would need a session, which needs either:
- A confirmed test account (blocked: no real mailbox reachable from this
  environment to receive the confirmation link for a throwaway address), or
- The real user's account (ruled out: standing instruction never to sign in
  as the real user, plus the prior incident where the real session was
  accidentally logged out in an earlier session).

Rather than fabricate a pass or use the real account, this is disclosed as a
genuine gap. The code path for all three (persisted-session restore via
`supabase_flutter`, `signOut()`, and RLS-scoped `profiles` reads) was
reviewed and is documented with file/line references in the Verification
Report; none of it is exotic or hand-rolled enough to carry meaningfully
higher risk than the parts that were live-tested.

## Operational notes from this session (environment friction, not app bugs)

- **Autofill password overlay**: Android's saved-credential autofill service
  renders a dot-masked preview over any password field on focus, before any
  real text is typed — this looked like a prefilled password on several
  screenshots but was confirmed (by typing a single test character and
  watching it replace the dots) to be a non-committed OS-level overlay, not
  actual field content. No real password was ever read, exposed, or
  submitted from this overlay.
- **Obscured-field cursor behavior**: tapping anywhere in the Password field
  always placed the cursor at position 0, regardless of tap x-coordinate —
  backspace (deletes before cursor) had nothing to delete until forward-
  delete or literal typing was used instead.
- **Screenshot capture**: `adb exec-out screencap -p >` piped through
  PowerShell redirection corrupts binary output (PowerShell's `>` applies
  UTF-8/BOM text encoding). Fixed by capturing to a device-local file
  (`adb shell screencap -p /sdcard/x.png`) then `adb pull`, which avoids
  stdout entirely.
- **`adb` not on PATH** in this shell session — resolved by invoking
  `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` directly.
- **Screenshot coordinate scaling**: this tooling displays screenshots
  downscaled from the emulator's native 1080×2400 to 900×2000; tap
  coordinates sent to `adb shell input tap` must be the *displayed*
  coordinate × 1.2 to land correctly in native pixel space. Several early
  taps in this session missed their target because this scaling wasn't
  applied consistently — subsequent taps recomputed coordinates from the
  screenshot geometry directly to fix this.

None of the above are application defects — they're artifacts of driving a
Flutter app through `adb` shell commands from a Windows host, noted here for
transparency about why this test took multiple attempts rather than because
anything in the app itself misbehaved.
