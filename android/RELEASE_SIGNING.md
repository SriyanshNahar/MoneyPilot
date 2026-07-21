# Android release signing

A real upload keystore has already been generated for this project:

- `android/keystore/moneypilot-upload.jks`
- `android/key.properties` (points Gradle at the keystore + credentials)
- `android/keystore/CREDENTIALS.txt` (the actual passwords + fingerprints)

**All three files are gitignored** (`android/.gitignore`) — they will never be
committed. Back up `moneypilot-upload.jks` and `CREDENTIALS.txt` somewhere
durable (password manager, secure vault) before you do anything else. If you
lose this keystore and haven't enrolled in Play App Signing, you will not be
able to publish updates to the same Play Store listing ever again.

`android/app/build.gradle.kts` reads `key.properties` automatically and signs
`release` builds with it. If `key.properties` doesn't exist (e.g. a fresh
clone without the keystore), it safely falls back to debug signing so
`flutter run --release` and CI still work — it just won't produce a
Play-Store-uploadable artifact.

## Build a release artifact

```bash
flutter build appbundle --release   # .aab for Play Store (preferred)
flutter build apk --release         # .apk, for sideloading/testing only
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

## First upload to Play Console

1. Play Console → your app → Release → Production (or a testing track) →
   Create new release.
2. Enroll in **Play App Signing** when prompted (Google's recommendation and
   effectively the default now) — you upload with this keystore (the
   "upload key"), Google re-signs with a separate "app signing key" it holds.
   This means if you ever lose the upload key, Google support can help you
   reset it; you are not permanently locked out the way you would be under
   the old model.
3. Upload `app-release.aab`.

## Rotating the keystore later

If this keystore is ever compromised or lost *before* your first Play
Console upload, just delete `android/keystore/moneypilot-upload.jks` and
`android/key.properties` and regenerate:

```bash
keytool -genkeypair -v \
  -keystore android/keystore/moneypilot-upload.jks \
  -alias moneypilot \
  -keyalg RSA -keysize 2048 -validity 10000
```

Then recreate `android/key.properties` with the new store/key
passwords and alias. After your first upload, do this only via Play
Console's "Request upload key reset" flow instead — don't generate a new
keystore and try to upload with it directly; Play Console will reject an
app-signing mismatch.
