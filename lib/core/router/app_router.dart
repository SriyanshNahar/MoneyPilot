import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_lock/app_lock_gate.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/activity/activity_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/expenses/expense_form_screen.dart';
import '../../features/money_lab/money_lab_screen.dart';
import '../../features/settings/settings_screen.dart';

const _protectedPaths = {'/dashboard', '/khata', '/insights', '/settings', '/expenses/new'};

/// Direct port of the TanStack Router setup (router.tsx + routes/*): a
/// public splash + auth flow, and an authenticated area gated behind
/// _app.tsx's user-loaded check + AppLockGate.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final loggedIn = auth.user != null;

      if (path == '/') return null; // SplashScreen drives its own navigation
      if (path == '/auth') {
        if (!auth.loading && loggedIn) return '/dashboard';
        return null;
      }
      if (_protectedPaths.contains(path)) {
        if (!auth.loading && !loggedIn) return '/auth';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const _Protected(child: DashboardScreen()),
      ),
      GoRoute(
        path: '/khata',
        builder: (context, state) => const _Protected(child: ActivityScreen()),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const _Protected(child: MoneyLabScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const _Protected(child: SettingsScreen()),
      ),
      GoRoute(
        path: '/expenses/new',
        builder: (context, state) => _Protected(
          child: ExpenseFormScreen(forceType: state.uri.queryParameters['type']),
        ),
      ),
    ],
  );
});

/// Mirrors _app.tsx's AppLayout: block on the auth-loading spinner, then
/// require a session before rendering the AppLockGate + real screen.
class _Protected extends ConsumerWidget {
  const _Protected({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return AppLockGate(child: child);
  }
}
