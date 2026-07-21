import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/notifications/notifications_service.dart';
import 'core/offline/offline_cache.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await OfflineCache.instance.init();
  await initSupabase();
  // Best-effort — never blocks app startup (see NotificationsService).
  unawaited(NotificationsService.instance.init());
  runApp(const ProviderScope(child: MoneyPilotApp()));
}
