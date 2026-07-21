import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';

/// Direct port of the theme picker Sheet in settings.tsx.
class ThemeSheet extends ConsumerWidget {
  const ThemeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final current = ref.watch(themeControllerProvider).pref;

    final options = <(ThemePref, String, IconData)>[
      (ThemePref.light, 'Light', Icons.wb_sunny_outlined),
      (ThemePref.dark, 'Dark', Icons.dark_mode_outlined),
      (ThemePref.auto, 'Auto', Icons.smartphone_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose theme', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          Text('Auto follows the app default (light).', style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          Row(
            children: options.map((o) {
              final (pref, label, icon) = o;
              final active = current == pref;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      ref.read(themeControllerProvider.notifier).setTheme(pref);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: active ? colors.primaryTint : colors.card,
                        border: Border.all(color: active ? Theme.of(context).colorScheme.primary : colors.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: active ? Colors.white : null),
                        ),
                        const SizedBox(height: 8),
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.palette_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Instagram-inspired gradient palette. Your choice is saved on this device.', style: TextStyle(fontSize: 11, color: colors.mutedForeground))),
            ]),
          ),
        ],
      ),
    );
  }
}
