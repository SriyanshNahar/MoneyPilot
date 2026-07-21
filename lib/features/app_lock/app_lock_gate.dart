import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_service.dart';
import 'lock_screen.dart';

/// Direct port of AppLockGate.tsx: wraps the authenticated app and shows a
/// lock screen until the user verifies PIN/pattern/biometric — but only if
/// a lock has actually been configured in Settings.
class AppLockGate extends ConsumerWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(appLockConfiguredProvider);
    final unlocked = ref.watch(appUnlockedProvider);

    return configured.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => child,
      data: (isConfigured) {
        if (!isConfigured || unlocked) return child;
        return LockScreen(
          onUnlock: () => ref.read(appUnlockedProvider.notifier).state = true,
        );
      },
    );
  }
}
