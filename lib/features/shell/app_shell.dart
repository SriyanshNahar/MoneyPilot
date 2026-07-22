import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/offline_banner.dart';

class _Tab {
  const _Tab(this.path, this.label, this.icon, this.activeIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

// Best-effort Material Symbols Rounded swap (v2.1): applied here first since
// the bottom nav is the single most-seen icon surface in the app.
const _tabs = [
  _Tab('/dashboard', 'Home', Symbols.home_rounded, Symbols.home_rounded),
  _Tab('/khata', 'Activity', Symbols.schedule_rounded, Symbols.schedule_rounded),
  _Tab('/insights', 'Money Lab', Symbols.science_rounded, Symbols.science_rounded),
  _Tab('/settings', 'Profile', Symbols.person_rounded, Symbols.person_rounded),
];

/// Direct port of src/components/AppShell.tsx: scrollable content area plus
/// a floating pill-shaped bottom nav bar with 4 tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final colors = context.colors;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    children: [
                      const OfflineBanner(),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.card.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border.withValues(alpha: 0.7)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _tabs.map((t) {
                      final active = location == t.path;
                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            if (!active) context.go(t.path);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: active ? colors.primaryTint : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    active ? t.activeIcon : t.icon,
                                    size: 22,
                                    color: active ? Theme.of(context).colorScheme.primary : colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
