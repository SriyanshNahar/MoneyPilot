import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../quotes/finance_quotes.dart';
import '../theme/app_colors.dart';

/// Compact inline loading indicator (spinner + quote in a row) — used where
/// space is tight, e.g. the "Paisa Mitra is thinking" bubble in AI Coach chat.
/// Draws from the full 177-quote bank (lib/core/quotes/finance_quotes.dart).
class LoadingQuote extends StatefulWidget {
  const LoadingQuote({super.key, this.label});
  final String? label;

  @override
  State<LoadingQuote> createState() => _LoadingQuoteState();
}

class _LoadingQuoteState extends State<LoadingQuote> {
  late int _idx = Random().nextInt(financeQuotes.length);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    // 5-8s, randomized per cycle so a row of these doesn't visibly lock-step.
    final ms = 5000 + Random().nextInt(3000);
    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      setState(() => _idx = (_idx + 1) % financeQuotes.length);
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = financeQuotes[_idx];
    final colors = context.colors;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Column(
                key: ValueKey(_idx),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.label != null)
                    Text(
                      widget.label!.toUpperCase(),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary, letterSpacing: 0.4),
                    ),
                  Text('"${q.text}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15, height: 1.4)),
                  const SizedBox(height: 2),
                  Text('— ${q.author}', style: TextStyle(fontSize: 13, color: colors.mutedForeground, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-page loading experience: Circular Progress Indicator → 24dp spacing
/// → Finance Quote → Author, crossfading with a fade+slide every 5-8s.
/// Used wherever the app would otherwise show a bare spinner (dashboard,
/// activity, splash) — "Myntra-style" loading, entirely offline/local.
class FullLoadingQuote extends StatefulWidget {
  const FullLoadingQuote({super.key, this.spinnerColor});
  final Color? spinnerColor;

  @override
  State<FullLoadingQuote> createState() => _FullLoadingQuoteState();
}

class _FullLoadingQuoteState extends State<FullLoadingQuote> {
  late int _idx = Random().nextInt(financeQuotes.length);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    final ms = 5000 + Random().nextInt(3000);
    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      setState(() => _idx = (_idx + 1) % financeQuotes.length);
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = financeQuotes[_idx];
    final colors = context.colors;
    final primary = widget.spinnerColor ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: primary)),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(_idx),
                children: [
                  Text(
                    '"${q.text}"',
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text('— ${q.author}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.mutedForeground)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
