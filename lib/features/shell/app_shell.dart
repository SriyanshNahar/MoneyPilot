import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/offline_banner.dart';

class _Tab {
  const _Tab(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

const _tabs = [
  _Tab('/dashboard', 'Home', Symbols.home_rounded),
  _Tab('/khata', 'Activity', Symbols.schedule_rounded),
  _Tab('/insights', 'Money Lab', Symbols.science_rounded),
  _Tab('/settings', 'Profile', Symbols.person_rounded),
];

/// Direct port of src/components/AppShell.tsx: scrollable content area plus
/// a floating "bump" bottom nav (v2.2) — the active tab's icon rises into a
/// circular button that overlaps the bar, everything else stays flat.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FloatingBottomNav(activePath: location),
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

const _navAnimDuration = Duration(milliseconds: 280);
const _navAnimCurve = Curves.easeOutCubic;
const _barHeight = 64.0;
const _circleSize = 56.0;
const _circleOverlap = 24.0; // how far the circle rises above the bar's top edge

/// Floating "bump" bottom nav: the active tab's icon rises into a circular
/// button that overlaps the bar while the rest stay flat with a dimmed icon
/// + label. Slide/scale/fade only — no elastic/bounce curves, per spec.
class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({required this.activePath});
  final String activePath;

  void _onTap(BuildContext context, int i, int activeIndex) {
    if (i == activeIndex) return;
    HapticFeedback.selectionClick();
    context.go(_tabs[i].path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = _tabs.indexWhere((t) => t.path == activePath);
    final activeIndex = index == -1 ? 0 : index;

    return SizedBox(
      height: _barHeight + _circleOverlap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / _tabs.length;
          final circleLeft = activeIndex * slotWidth + (slotWidth - _circleSize) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _FlatTabSlot(
                            tab: _tabs[i],
                            active: i == activeIndex,
                            onTap: () => _onTap(context, i, activeIndex),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: _navAnimDuration,
                curve: _navAnimCurve,
                left: circleLeft,
                top: 0,
                width: _circleSize,
                height: _circleSize,
                child: _FloatingActiveCircle(tab: _tabs[activeIndex]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlatTabSlot extends StatelessWidget {
  const _FlatTabSlot({required this.tab, required this.active, required this.onTap});
  final _Tab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          height: _barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The active tab's icon lives in the floating circle instead —
              // fade it out here rather than removing it, so the label below
              // never jumps position when switching tabs.
              AnimatedOpacity(
                duration: _navAnimDuration,
                curve: _navAnimCurve,
                opacity: active ? 0 : 1,
                child: Icon(tab.icon, size: 22, color: colors.mutedForeground),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: _navAnimDuration,
                curve: _navAnimCurve,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                  color: active ? scheme.primary : colors.mutedForeground,
                ),
                child: Text(tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised circular button that overlaps the bar above whichever tab is
/// currently active. Its content cross-fades/scales in when the selected
/// tab changes; the button itself slides horizontally via the parent's
/// AnimatedPositioned.
class _FloatingActiveCircle extends StatelessWidget {
  const _FloatingActiveCircle({required this.tab});
  final _Tab tab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      excludeSemantics: true, // already announced by the flat slot beneath it
      child: Container(
        width: _circleSize,
        height: _circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary,
          boxShadow: [
            BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: AnimatedSwitcher(
          duration: _navAnimDuration,
          switchInCurve: _navAnimCurve,
          switchOutCurve: _navAnimCurve,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(tab.icon, key: ValueKey(tab.path), size: 24, color: scheme.onPrimary),
        ),
      ),
    );
  }
}
