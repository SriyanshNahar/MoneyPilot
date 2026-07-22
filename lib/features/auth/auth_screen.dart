import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import 'apple_sign_in.dart' as apple;
import 'auth_controller.dart';

enum _Mode { signin, signup }

/// Direct port of src/routes/auth.tsx.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _Mode _mode = _Mode.signin;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _showPw = false;
  bool _busy = false;
  String? _emailError;
  String? _passwordError;
  String? _nameError;

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _nameRe = RegExp(r"^[A-Za-z\s'.-]+$");

  bool _validate() {
    _emailError = null;
    _passwordError = null;
    _nameError = null;

    final email = _email.text.trim();
    if (email.isEmpty || email.length > 255 || !_emailRe.hasMatch(email)) {
      _emailError = 'Enter a valid email address';
    }
    final pw = _password.text;
    if (pw.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
    } else if (pw.length > 72) {
      _passwordError = 'Password is too long';
    } else if (!RegExp(r'[A-Za-z]').hasMatch(pw)) {
      _passwordError = 'Include at least one letter';
    } else if (!RegExp(r'[0-9]').hasMatch(pw)) {
      _passwordError = 'Include at least one number';
    }
    if (_mode == _Mode.signup) {
      final name = _name.text.trim();
      if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
      } else if (name.length > 60) {
        _nameError = 'Name is too long';
      } else if (!_nameRe.hasMatch(name)) {
        _nameError = "Name can only contain letters, spaces, . ' -";
      }
    }
    setState(() {});
    return _emailError == null && _passwordError == null && _nameError == null;
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<void> _onEmailSubmit() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    try {
      if (_mode == _Mode.signup) {
        await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim().isNotEmpty ? _name.text.trim() : _email.text.split('@').first},
        );
        _toast('Account created! Check your email if confirmation is required.');
      } else {
        await supabase.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
        _toast('Welcome back!');
        if (mounted) context.go('/dashboard');
      }
    } on AuthException catch (e) {
      _toast(e.message, error: true);
    } catch (e) {
      _toast('Authentication failed', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onGoogle() async {
    setState(() => _busy = true);
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: oauthRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _toast('Google sign-in failed', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _appleAvailable => !kIsWeb && Platform.isIOS;

  Future<void> _onApple() async {
    setState(() => _busy = true);
    try {
      await apple.signInWithApple();
      _toast('Welcome back!');
      if (mounted) context.go('/dashboard');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        _toast('Apple sign-in failed', error: true);
      }
    } catch (e) {
      _toast('Apple sign-in failed', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (!next.loading && next.user != null) context.go('/dashboard');
    });
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colors.gradientStart, colors.gradientEnd]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MoneyPilot', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            Text('Smart money, simply managed.', style: TextStyle(color: Colors.white70, fontSize: 15)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.card,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(children: [
                            Expanded(child: _ModeTab(label: 'Sign in', active: _mode == _Mode.signin, onTap: () => setState(() => _mode = _Mode.signin))),
                            Expanded(child: _ModeTab(label: 'Sign up', active: _mode == _Mode.signup, onTap: () => setState(() => _mode = _Mode.signup))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        if (_mode == _Mode.signup) ...[
                          _Field(label: 'Name', controller: _name, hint: 'Your name', error: _nameError),
                          const SizedBox(height: 12),
                        ],
                        _Field(label: 'Email', controller: _email, hint: 'you@example.com', error: _emailError, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _Field(
                          label: 'Password',
                          controller: _password,
                          hint: '••••••••',
                          error: _passwordError,
                          obscure: !_showPw,
                          helper: _mode == _Mode.signup && _passwordError == null ? 'At least 8 characters, with a letter and a number.' : null,
                          suffix: IconButton(
                            icon: Icon(_showPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22),
                            tooltip: _showPw ? 'Hide password' : 'Show password',
                            onPressed: () => setState(() => _showPw = !_showPw),
                          ),
                        ),
                        if (_mode == _Mode.signin) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy ? null : () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(44, 36)),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _busy ? null : _onEmailSubmit,
                            child: _busy
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(_mode == _Mode.signin ? 'Sign in' : 'Create account'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: Divider(color: colors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('OR', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                          ),
                          Expanded(child: Divider(color: colors.border)),
                        ]),
                        const SizedBox(height: 16),
                        if (_appleAvailable) ...[
                          SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _onApple,
                              style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                              icon: const Icon(Icons.apple, size: 24),
                              label: const Text('Continue with Apple'),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _onGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Continue with Google'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'By continuing, you agree to manage your data privately on your device + cloud.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? colors.card : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: active ? null : colors.mutedForeground)),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.error,
    this.helper,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? error;
  final String? helper;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.mutedForeground)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix, errorText: null),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14))),
        if (error == null && helper != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(helper!, style: TextStyle(color: colors.mutedForeground, fontSize: 14))),
      ],
    );
  }
}
