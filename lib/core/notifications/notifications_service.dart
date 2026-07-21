import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import '../../data/repositories/device_tokens_repository.dart';
import '../../firebase_options.dart';
import 'local_notifications.dart';

/// Push notifications (Firebase Cloud Messaging), registered against the
/// same `device_tokens` table send-reminders.ts already expects.
///
/// Entirely best-effort: MoneyPilot's core money-tracking features must
/// keep working even if Firebase isn't configured (placeholder
/// firebase_options.dart), the user denies permission, or there's no
/// network at startup — none of that should ever crash app boot.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate; must re-initialize Firebase itself.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    return;
  }
  debugPrint('MoneyPilot: background push received: ${message.messageId}');
}

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  bool _firebaseReady = false;
  String? _lastToken;

  Future<void> init() async {
    await LocalNotifications.instance.init();

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _firebaseReady = true;
    } catch (e) {
      debugPrint('MoneyPilot: Firebase not configured yet, push disabled ($e)');
      return;
    }

    try {
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        LocalNotifications.instance.showNow(
          id: message.hashCode,
          title: notification.title ?? 'MoneyPilot',
          body: notification.body ?? '',
        );
      });
    } catch (e) {
      debugPrint('MoneyPilot: FCM listener setup failed ($e)');
    }
  }

  /// Call once a user is signed in (see app.dart) to register/refresh this
  /// device's push token against their account.
  Future<void> registerForUser(String uid) async {
    if (!_firebaseReady || kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    const repo = DeviceTokensRepository();
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token != _lastToken) {
        _lastToken = token;
        await repo.upsert(uid: uid, token: token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _lastToken = newToken;
        repo.upsert(uid: uid, token: newToken);
      });
    } catch (e) {
      debugPrint('MoneyPilot: could not register device token ($e)');
    }
  }
}
