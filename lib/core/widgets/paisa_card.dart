import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Direct port of the `.paisa-card` utility class in styles.css:
/// card background, 1px border, xl radius, soft shadow.
class PaisaCard extends StatelessWidget {
  const PaisaCard({super.key, required this.child, this.padding, this.margin, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: content),
    );
  }
}

/// Divider-separated list variant of PaisaCard (matches `divide-y divide-border`).
class PaisaCardDivided extends StatelessWidget {
  const PaisaCardDivided({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}
