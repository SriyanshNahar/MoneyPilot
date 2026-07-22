import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/loading_quote.dart';
import 'auth_controller.dart';

/// App launch screen: Logo → app name/tagline/attribution → loading
/// indicator → rotating finance quote → Home. Minimal white background, no
/// glow behind the logo (removed per v2.1 — was reading as a colored badge
/// rather than a clean mark). Shows immediately at process start so there is
/// never a blank white frame while the session/auth check resolves.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
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
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 28),
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
            const Spacer(flex: 2),
            const FullLoadingQuote(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
