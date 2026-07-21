import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/quotes/finance_quotes.dart';
import '../../core/quotes/quote_picker.dart';
import 'auth_controller.dart';

/// Direct port of src/components/SplashScreen.tsx + routes/index.tsx's
/// IndexRedirect: show the splash for at least 1400ms, then route to
/// /dashboard or /auth once the session has resolved.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  bool _minTimeElapsed = false;
  FinanceQuote? _quote;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _minTimeElapsed = true);
      _maybeNavigate();
    });
    // Bundled locally (lib/core/quotes/finance_quotes.dart) — always
    // available even with zero connectivity, so there's nothing to
    // actually "fall back" from; local is the only source, on purpose.
    pickSplashQuote().then((q) {
      if (mounted) setState(() => _quote = q);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFFF4F6F2),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = (_controller.value * 2 - 1).abs();
                      return Container(
                        width: 160 + 20 * (1 - t),
                        height: 160 + 20 * (1 - t),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withValues(alpha: 0.45 + 0.25 * (1 - t)),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      );
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(38),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'MoneyPilot',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
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
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _quote == null
                  ? const SizedBox(height: 54)
                  : Padding(
                      key: ValueKey(_quote!.text),
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        children: [
                          Text(
                            '“${_quote!.text}”',
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '— ${_quote!.author}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 96,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  color: const Color(0xFFD1FAE5),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Align(
                        alignment: Alignment(-1 + _controller.value * 4, 0),
                        child: FractionallySizedBox(
                          widthFactor: 1 / 3,
                          child: Container(height: 4, color: const Color(0xFF059669)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
