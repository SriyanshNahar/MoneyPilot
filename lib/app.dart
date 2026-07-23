import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notifications_service.dart';
import 'core/offline/connectivity_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/auth_controller.dart';

class MoneyPilotApp extends ConsumerStatefulWidget {
  const MoneyPilotApp({super.key});

  @override
  ConsumerState<MoneyPilotApp> createState() => _MoneyPilotAppState();
}

class _MoneyPilotAppState extends ConsumerState<MoneyPilotApp> {
  String? _registeredForUid;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeControllerProvider);

    // Keep the connectivity + offline-write-queue listeners alive app-wide.
    ref.watch(connectivityProvider);

    ref.listen(authControllerProvider, (prev, next) {
      final uid = next.user?.id;
      if (uid != null && uid != _registeredForUid) {
        _registeredForUid = uid;
        NotificationsService.instance.registerForUser(uid);
      }
    });

    return MaterialApp.router(
      title: 'MoneyPilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeState.themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Transparent system status/navigation bars — otherwise Android
        // paints its own opaque bar behind the floating bottom nav, which
        // reads as a stray extra white layer beneath it.
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            // Android 10+ still enforces its own contrast scrim on a
            // "transparent" system nav bar unless this is explicitly turned
            // off — without it, that scrim reads as a leftover translucent
            // layer behind the floating nav bar even though the color is
            // nominally transparent.
            systemStatusBarContrastEnforced: false,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child!,
        );
      },
    );
  }
}
