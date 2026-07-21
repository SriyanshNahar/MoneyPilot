import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

/// Native "Sign in with Apple" wired to Supabase's `signInWithIdToken`.
/// Mirrors the official Supabase + Flutter Apple auth guide. The Supabase
/// project already has the Apple provider enabled (confirmed live on
/// `rfrddfjtmrtfhqlvvqzf`) — this was the missing client half.
///
/// iOS-only by design: Apple's requirement (App Store Review Guideline 4.8)
/// is that an Apple option exists somewhere the app offers third-party
/// sign-in, not that it exists on every platform. Supporting it on Android
/// would additionally require an Apple "Sign in with Apple" Service ID +
/// web redirect relay, which needs an Apple Developer account this project
/// doesn't have credentials for.
String _generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

String _sha256OfString(String input) {
  return sha256.convert(utf8.encode(input)).toString();
}

Future<AuthResponse> signInWithApple() async {
  final rawNonce = _generateNonce();
  final hashedNonce = _sha256OfString(rawNonce);

  final credential = await SignInWithApple.getAppleIDCredential(
    scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    nonce: hashedNonce,
  );

  final idToken = credential.identityToken;
  if (idToken == null) {
    throw const AuthException('Could not find ID Token from generated Apple credential.');
  }

  return supabase.auth.signInWithIdToken(
    provider: OAuthProvider.apple,
    idToken: idToken,
    nonce: rawNonce,
  );
}
