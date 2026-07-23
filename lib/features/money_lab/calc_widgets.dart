import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/paisa_card.dart';

/// Shared shell + input/result widgets for the Money Lab calculators —
/// direct port of the CalcShell/Field/Result helpers in Calculators.tsx.
/// Spacing/radius values below are matched against that source file's
/// Tailwind classes (this project's `--radius` custom property is 18px, so
/// `rounded-lg` = 18px and `rounded-xl` = 22px — not the Tailwind defaults).
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
              decoration: BoxDecoration(color: colors.primaryTint, borderRadius: BorderRadius.circular(18)),
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

/// A true equal-width, equal-height grid row (mirrors the source's CSS
/// `grid grid-cols-N gap-2` exactly, rather than approximating it with a
/// wrapping list of clamped-width boxes). Children are chunked into rows of
/// [columns]; every cell in a row gets exactly 1/[columns] of the available
/// width via `Expanded`, so cells can never overflow regardless of screen
/// size, and every row's cells share one height via `IntrinsicHeight`. An
/// incomplete final row is padded with invisible spacer cells so its filled
/// columns stay aligned with the rows above instead of stretching wider.
class CalcGrid extends StatelessWidget {
  const CalcGrid({super.key, required this.children, this.columns = 2});
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final rowItems = children.skip(i).take(columns).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: 8),
                Expanded(child: j < rowItems.length ? rowItems[j] : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
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
          children: [
            // A true grid cell (see CalcGrid) already gives this its own
            // proportional share of the row — plenty of room for a normal
            // label in normal use. The ellipsis stays only as a backstop
            // for pathological cases (e.g. very large formatted numbers
            // near the calculator's own max bound), never the primary fit.
            Expanded(
              child: Text(widget.label, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  final n = double.tryParse(value.text) ?? 0;
                  return Text(
                    _display(n),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary ? colors.primaryTint : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.3),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primary ? scheme.primary : null),
          ),
        ],
      ),
    );
  }
}
