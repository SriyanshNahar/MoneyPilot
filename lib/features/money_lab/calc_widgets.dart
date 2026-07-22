import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/paisa_card.dart';

/// Shared shell + input/result widgets for the Money Lab calculators —
/// direct port of the CalcShell/Field/Result helpers in Calculators.tsx.
class CalcShell extends StatelessWidget {
  const CalcShell({super.key, required this.icon, required this.title, required this.subtitle, required this.children});
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PaisaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: colors.primaryTint, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// A responsive row of fields/results (mirrors the `grid grid-cols-N` wrappers).
class CalcGrid extends StatelessWidget {
  const CalcGrid({super.key, required this.children, this.columns = 2});
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children.map((c) {
        final width = (MediaQuery.of(context).size.width - 32 - 32 - (columns - 1) * 8) / columns;
        return SizedBox(width: width.clamp(90, 400), child: c);
      }).toList(),
    );
  }
}

class NumField extends StatefulWidget {
  const NumField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix = '',
    this.min = 0,
    this.max = 1e9,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String suffix; // '₹' | '%' | 'y' | ''
  final double min;
  final double max;

  @override
  State<NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<NumField> {
  late final TextEditingController _controller = TextEditingController(text: _fmtRaw(widget.value));

  static String _fmtRaw(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _display(double n) {
    if (widget.suffix == '₹') return formatINR(n);
    return '${_fmtRaw(n)}${widget.suffix}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: const TextStyle(fontSize: 14)),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final n = double.tryParse(value.text) ?? 0;
                return Text(_display(n), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary));
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            onChanged: (v) => widget.onChanged(double.tryParse(v) ?? 0),
          ),
        ),
      ],
    );
  }
}

class CalcResult extends StatelessWidget {
  const CalcResult({super.key, required this.label, required this.value, this.primary = true});
  final String label;
  final String value;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primary ? colors.primaryTint : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primary ? scheme.primary : null)),
        ],
      ),
    );
  }
}
