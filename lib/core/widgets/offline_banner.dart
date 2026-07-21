import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/connectivity_provider.dart';
import '../theme/app_colors.dart';

/// Shown at the top of AppShell whenever the device has no connectivity,
/// or there are still offline writes waiting to sync.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectivityProvider);
    if (state.online && state.pendingWrites == 0) return const SizedBox.shrink();

    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final offline = !state.online;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: offline ? colors.destructiveTint : colors.accentTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            offline ? Icons.cloud_off_outlined : Icons.sync,
            size: 16,
            color: offline ? scheme.error : const Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              offline
                  ? (state.pendingWrites > 0
                      ? "You're offline — ${state.pendingWrites} entr${state.pendingWrites == 1 ? 'y' : 'ies'} will sync automatically once you're back online."
                      : "You're offline — showing your last saved data.")
                  : 'Syncing ${state.pendingWrites} offline entr${state.pendingWrites == 1 ? 'y' : 'ies'}…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: offline ? scheme.error : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
