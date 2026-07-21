# Firebase Cloud Messaging setup

All the Dart/Android/iOS wiring for push notifications is in place:

- `lib/core/notifications/notifications_service.dart` — FCM init, foreground
  message handling (shown via local notifications), background handler,
  token registration.
- `lib/data/repositories/device_tokens_repository.dart` — writes to the
  same `device_tokens` table the (currently un-deployed) `send-reminders`
  cron already expects.
- `android/app/build.gradle.kts` — conditionally applies the Google Services
  Gradle plugin only if `google-services.json` exists, so the build never
  breaks without it.
- `ios/Runner/Runner.entitlements` — `aps-environment` entitlement added.
- `ios/Runner/Info.plist` — `UIBackgroundModes: remote-notification`.

What's still a placeholder: **`lib/firebase_options.dart`** — hand-written
with fake values so the app compiles, but it doesn't point at a real
Firebase project. `NotificationsService.init()` catches the resulting
failure and no-ops, so nothing crashes — push notifications are just
silently disabled until you do this:

## 1. Create the Firebase project

https://console.firebase.google.com → Add project. Any name/region works;
it doesn't need to match the Supabase project name.

## 2. Generate real config

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

Select Android + iOS when prompted. This overwrites
`lib/firebase_options.dart` with real values and creates:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Both are gitignored (`.gitignore`) — that's intentional, they're
per-environment credentials.

## 3. iOS: APNs key

Firebase Console → Project Settings → Cloud Messaging → Apple app
configuration → upload an APNs Auth Key (`.p8`) from your Apple Developer
account (Certificates, IDs & Profiles → Keys). Without this, iOS push
silently never arrives even with everything else configured correctly.

## 4. Rebuild

```bash
flutter clean && flutter pub get
flutter run
```

You should see a real FCM token logged and a row appear in the
`device_tokens` Supabase table after signing in.

## Note on the reminder cron

Registering tokens here is necessary but not sufficient — the actual
"send a push 3 days before this bill is due" logic lives in
`src/routes/api/public/hooks/send-reminders.ts` in the React project,
which is **not yet ported** to run against these tokens (it currently only
sends Email/SMS/WhatsApp, not FCM push, and isn't deployed as a Supabase
Edge Function either). Wiring FCM sends into that cron — or rebuilding it
as a Supabase Edge Function + `pg_cron` schedule — is a separate follow-up.
