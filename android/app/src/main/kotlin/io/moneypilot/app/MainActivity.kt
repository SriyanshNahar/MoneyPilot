package io.moneypilot.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth
// for the native biometric prompt (Face ID / fingerprint) to attach correctly.
class MainActivity : FlutterFragmentActivity()
