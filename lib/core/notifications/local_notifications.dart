import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local (on-device, no backend required) notifications — covers bill/EMI/
/// SIP/event reminders even before Firebase Cloud Messaging is configured.
/// This is what "Daily reminders run at 9:00 AM IST" (see the copy in
/// AlertsSheet) actually fires locally today; FCM push is the *remote*
/// complement once send-reminders is deployed server-side.
class LocalNotifications {
  LocalNotifications._();
  static final LocalNotifications instance = LocalNotifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _reminderChannel = AndroidNotificationChannel(
    'mp_reminders',
    'Bill & event reminders',
    description: 'Upcoming bills, EMIs, SIPs and personal events',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      tz_data.initializeTimeZones();
      // Best-effort local timezone; falls back to UTC offset scheduling if
      // the platform can't report an IANA name (scheduling still works,
      // just less DST-aware).
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Keep tz.local at its default (UTC) — MoneyPilot targets IST users,
        // but this must never crash startup.
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false, // requested explicitly below
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(_reminderChannel);
        await androidPlugin?.requestNotificationsPermission();
      } else if (!kIsWeb && Platform.isIOS) {
        await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
      _ready = true;
    } catch (_) {
      // Never let notification setup crash the app — reminders are a nice-
      // to-have, not a hard dependency for MoneyPilot's core money tracking.
    }
  }

  Future<void> showNow({required int id, required String title, required String body}) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannel.id,
            _reminderChannel.name,
            channelDescription: _reminderChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // best-effort
    }
  }

  /// Schedules a one-off local notification for [dateTime] (device-local
  /// time). If [dateTime] has already passed, does nothing.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!_ready) return;
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannel.id,
            _reminderChannel.name,
            channelDescription: _reminderChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Inexact on purpose — no SCHEDULE_EXACT_ALARM/USE_EXACT_ALARM
        // permission requested (see AndroidManifest.xml comment); a bill
        // reminder firing within the same hour is fine.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // best-effort — some OEM Android builds restrict exact alarms; the
      // in-app dashboard reminder list remains the source of truth either way.
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAllReminders() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
