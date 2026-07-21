import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/supabase/supabase_config.dart';

/// Mirrors the `device_tokens` table — the same one send-reminders.ts
/// (the un-ported reminder cron) would read from to push via FCM.
/// Registering here means that once that cron exists server-side, it
/// already has real tokens to send to.
class DeviceTokensRepository {
  const DeviceTokensRepository();

  Future<void> upsert({required String uid, required String token}) async {
    final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
    String? appVersion;
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      appVersion = null;
    }

    await supabase.from('device_tokens').upsert(
      {
        'user_id': uid,
        'token': token,
        'platform': platform,
        'app_version': appVersion,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,token',
    );
  }

  Future<void> remove(String token) async {
    await supabase.from('device_tokens').delete().eq('token', token);
  }
}
