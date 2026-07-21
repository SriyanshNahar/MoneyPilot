import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project connection. These are publishable (anon) values —
/// safe to ship in a mobile client because every table is protected by
/// row-level security. Matches VITE_SUPABASE_URL / VITE_SUPABASE_PUBLISHABLE_KEY
/// baked into the React app's build.
///
/// Override at build/run time with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://rfrddfjtmrtfhqlvvqzf.supabase.co',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcmRkZmp0bXJ0ZmhxbHZ2cXpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MjAyMTcsImV4cCI6MjA5NzE5NjIxN30.'
      'cqyBk_YU581wAXl_VEWaBW_m0HWxC-11irABc2jThWk',
);

/// Deep-link redirect target registered on both platforms for OAuth
/// (Google / Apple) sign-in callbacks. See android/app/src/main/AndroidManifest.xml
/// and ios/Runner/Info.plist for the matching URL scheme registration.
const String oauthRedirectUrl = 'io.moneypilot.app://login-callback';

SupabaseClient get supabase => Supabase.instance.client;

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}
