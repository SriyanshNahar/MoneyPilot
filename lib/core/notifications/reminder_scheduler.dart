import 'local_notifications.dart';

/// A single bill/EMI/SIP/event reminder to schedule as a local notification.
class ReminderInput {
  const ReminderInput({required this.id, required this.title, required this.body, required this.dueDate});

  /// Stable across rebuilds (e.g. "exp-" + the expense's uuid) — reused as
  /// the notification id so rescheduling the same reminder overwrites it
  /// instead of stacking duplicates.
  final String id;
  final String title;
  final String body;

  /// yyyy-mm-dd, device-local calendar date.
  final DateTime dueDate;
}

/// Schedules local notifications for upcoming reminders at 9:00 AM local
/// time on the due date — matching the "Daily reminders run at 9:00 AM IST"
/// copy already shown in Settings → Alert channels. This is the fully
/// offline, no-backend-dependency complement to the (currently un-deployed)
/// server-side reminder cron — see FIREBASE_SETUP.md.
class ReminderScheduler {
  ReminderScheduler._();

  static const _reminderHour = 9;
  static const _maxScheduled = 60; // keep this generous but bounded

  static Future<void> scheduleAll(List<ReminderInput> reminders) async {
    final capped = reminders.take(_maxScheduled).toList();
    for (final r in capped) {
      final at = DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day, _reminderHour);
      await LocalNotifications.instance.scheduleAt(
        id: _stableId(r.id),
        title: r.title,
        body: r.body,
        dateTime: at,
      );
    }
  }

  /// Deterministic 31-bit id from a reminder's stable string id — Android's
  /// notification id is a 32-bit int, so this needs to fit comfortably.
  static int _stableId(String id) => id.hashCode & 0x7fffffff;
}
