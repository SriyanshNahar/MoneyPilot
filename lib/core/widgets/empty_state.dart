import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import 'paisa_card.dart';

/// Shared empty-state pattern used across list screens: icon in a soft
/// radial-gradient circle, heading, description, and a primary CTA button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.tint,
    required this.tintFg,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color tint;
  final Color tintFg;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return PaisaCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [tint, tint.withValues(alpha: 0)])),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, size: 28, color: tintFg),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.colors.mutedForeground, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Symbols.add_rounded, size: 20),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
