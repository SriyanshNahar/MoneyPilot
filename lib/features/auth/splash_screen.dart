import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

/// App launch screen only — logo, app name, tagline, attribution, nothing
/// else. Finance quotes/spinners belong to `FullLoadingQuote` (see
/// core/widgets/loading_quote.dart), which is a separate, deliberately
/// distinct experience shown for in-app loading states (AI replies,
/// dashboard sync, etc.), never here. This screen exists purely to carry the
/// brand for ~1.2s while the session check resolves, then hands off — it
/// never blocks on network activity itself.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minTimeElapsed = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _minTimeElapsed = true);
      _maybeNavigate();
    });
  }

  void _maybeNavigate() {
    final auth = ref.read(authControllerProvider);
    if (!_minTimeElapsed || auth.loading) return;
    final target = auth.user != null ? '/dashboard' : '/auth';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) => _maybeNavigate());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/app_icon.png', width: 112, height: 112, fit: BoxFit.contain),
              const SizedBox(height: 24),
              const Text(
                'MoneyPilot',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Smart money, simply managed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 4),
              const Text.rich(
                TextSpan(
                  text: 'A smart money app by ',
                  style: TextStyle(fontSize: 16, color: Color(0xFF475569)),
                  children: [
                    TextSpan(
                      text: 'Seven Sapience.',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
