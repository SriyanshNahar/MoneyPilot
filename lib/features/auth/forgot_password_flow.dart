import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/offline/connectivity_provider.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/offline_banner.dart';
import 'widgets/otp_input.dart';
import 'widgets/password_strength_meter.dart';

enum _Step { email, otp, newPassword, success }

const _otpLength = 6;
const _maxOtpAttempts = 5;
const _resendCooldownSeconds = 30;

/// Full password recovery flow: email → OTP → new password → success.
/// Uses Supabase's native recovery mechanism end-to-end
/// (resetPasswordForEmail → verifyOTP(type: recovery) → updateUser) — no
/// custom backend needed. Deliberately never reveals whether an email is
/// registered: the email step always shows the same generic confirmation,
/// matching what resetPasswordForEmail itself does (no error for unknown
/// emails, by design, to prevent account enumeration).
class ForgotPasswordFlow extends ConsumerStatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  ConsumerState<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends ConsumerState<ForgotPasswordFlow> {
  _Step _step = _Step.email;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _email = '';
  String _otp = '';
  int _otpAttempts = 0;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  bool _busy = false;
  String? _error;
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  bool get _isOnline => ref.read(connectivityProvider).online;

  Future<void> _sendCode() async {
    if (!_isOnline) {
      setState(() => _error = "You're offline. Connect to the internet to request a code.");
      return;
    }
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await supabase.auth.resetPasswordForEmail(email, redirectTo: oauthRedirectUrl);
      _email = email;
      _otpAttempts = 0;
      _startResendCooldown();
      if (mounted) setState(() => _step = _Step.otp);
    } on AuthException catch (e) {
      // Still generic — never confirm/deny whether the account exists.
      setState(() => _error = e.message.contains('rate limit') ? 'Too many attempts. Please wait a moment and try again.' : 'Could not send the code. Please try again.');
    } catch (_) {
      setState(() => _error = 'Could not send the code. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != _otpLength) return;
    if (_otpAttempts >= _maxOtpAttempts) {
      setState(() => _error = 'Too many incorrect attempts. Request a new code.');
      return;
    }
    if (!_isOnline) {
      setState(() => _error = "You're offline. Connect to the internet to verify the code.");
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await supabase.auth.verifyOTP(email: _email, token: _otp, type: OtpType.recovery);
      if (mounted) setState(() => _step = _Step.newPassword);
    } on AuthException catch (e) {
      _otpAttempts++;
      final remaining = _maxOtpAttempts - _otpAttempts;
      setState(() {
        _error = remaining > 0
            ? '${e.message.contains('expired') ? 'This code has expired.' : 'Incorrect code.'} $remaining attempt${remaining == 1 ? '' : 's'} left.'
            : 'Too many incorrect attempts. Request a new code.';
      });
    } catch (_) {
      _otpAttempts++;
      setState(() => _error = 'Could not verify the code. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_isOnline) {
      setState(() => _error = "You're offline. Connect to the internet to reset your password.");
      return;
    }
    final pw = _passwordController.text;
    if (!PasswordRules.isValid(pw)) {
      setState(() => _error = 'Password does not meet all the requirements below.');
      return;
    }
    if (pw != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await supabase.auth.updateUser(UserAttributes(password: pw));
      if (mounted) setState(() => _step = _Step.success);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not update your password. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goToLogin() async {
    // The recovery OTP briefly signs the user in — sign out so they land
    // back on a normal login screen with their new password, matching the
    // rest of the app's auth flow.
    await supabase.auth.signOut();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OfflineBanner(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        _Step.email => _buildEmailStep(context),
                        _Step.otp => _buildOtpStep(context),
                        _Step.newPassword => _buildPasswordStep(context),
                        _Step.success => _buildSuccessStep(context),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Forgot Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Enter your registered email address to receive a verification code.', style: TextStyle(fontSize: 15, color: colors.mutedForeground)),
        const SizedBox(height: 24),
        Text('EMAIL ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.mutedForeground, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'you@example.com'),
          onSubmitted: (_) => _sendCode(),
        ),
        if (_error != null) _errorBanner(context),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _busy ? null : _sendCode,
            child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send Verification Code'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Verify OTP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Enter the 6-digit code sent to $_email.', style: TextStyle(fontSize: 15, color: colors.mutedForeground)),
        const SizedBox(height: 24),
        OtpInput(
          length: _otpLength,
          onChanged: (v) => setState(() => _otp = v),
          onCompleted: (v) {
            _otp = v;
            _verifyOtp();
          },
        ),
        if (_error != null) _errorBanner(context),
        const SizedBox(height: 16),
        Center(
          child: _resendSeconds > 0
              ? Text('Resend in ${_resendSeconds}s', style: TextStyle(fontSize: 14, color: colors.mutedForeground))
              : TextButton(onPressed: _busy ? null : _sendCode, child: const Text('Resend code')),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: (_busy || _otp.length != _otpLength) ? null : _verifyOtp,
            child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Create New Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Choose a strong password you haven\'t used before.', style: TextStyle(fontSize: 15, color: colors.mutedForeground)),
        const SizedBox(height: 24),
        Text('NEW PASSWORD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.mutedForeground, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              tooltip: _showPassword ? 'Hide password' : 'Show password',
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        PasswordStrengthMeter(password: _passwordController.text),
        const SizedBox(height: 16),
        Text('CONFIRM PASSWORD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.mutedForeground, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmController,
          obscureText: !_showConfirm,
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              tooltip: _showConfirm ? 'Hide password' : 'Show password',
              onPressed: () => setState(() => _showConfirm = !_showConfirm),
            ),
          ),
          onSubmitted: (_) => _resetPassword(),
        ),
        if (_error != null) _errorBanner(context),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _busy ? null : _resetPassword,
            child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Reset Password'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(color: colors.successTint, shape: BoxShape.circle),
          child: Icon(Icons.check_circle, size: 48, color: colors.successForeground),
        ),
        const SizedBox(height: 20),
        const Text('Password Reset Successfully', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Your password has been updated successfully.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: colors.mutedForeground)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(onPressed: _goToLogin, child: const Text('Go to Login')),
        ),
      ],
    );
  }

  Widget _errorBanner(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: colors.destructiveTint, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error))),
          ],
        ),
      ),
    );
  }
}
