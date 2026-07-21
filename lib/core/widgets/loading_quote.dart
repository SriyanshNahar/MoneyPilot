import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class _Quote {
  const _Quote(this.text, this.author);
  final String text;
  final String author;
}

const _quotes = <_Quote>[
  _Quote('Do not save what is left after spending; spend what is left after saving.', 'Warren Buffett'),
  _Quote('An investment in knowledge pays the best interest.', 'Benjamin Franklin'),
  _Quote('The individual investor should act consistently as an investor and not as a speculator.', 'Ben Graham'),
  _Quote("It's not how much money you make, but how much you keep.", 'Robert Kiyosaki'),
  _Quote('Beware of little expenses. A small leak will sink a great ship.', 'Benjamin Franklin'),
  _Quote('The best time to plant a tree was 20 years ago. The second best time is now.', 'Chinese Proverb'),
  _Quote('Compound interest is the eighth wonder of the world.', 'Albert Einstein'),
  _Quote("Risk comes from not knowing what you're doing.", 'Warren Buffett'),
  _Quote('Wealth consists not in having great possessions, but in having few wants.', 'Epictetus'),
  _Quote('Never depend on a single income. Make investments to create a second source.', 'Warren Buffett'),
  _Quote('A budget is telling your money where to go instead of wondering where it went.', 'Dave Ramsey'),
  _Quote('Financial freedom is available to those who learn about it and work for it.', 'Robert Kiyosaki'),
  _Quote('Bahut se log paise ke peeche bhaagte hain — smart log paise se kaam karvate hain.', 'MoneyPilot'),
];

/// Direct port of src/components/LoadingQuote.tsx.
class LoadingQuote extends StatefulWidget {
  const LoadingQuote({super.key, this.label});
  final String? label;

  @override
  State<LoadingQuote> createState() => _LoadingQuoteState();
}

class _LoadingQuoteState extends State<LoadingQuote> {
  late int _idx = Random().nextInt(_quotes.length);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (mounted) setState(() => _idx = (_idx + 1) % _quotes.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _quotes[_idx];
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
            child: Column(
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
        ],
      ),
    );
  }
}
