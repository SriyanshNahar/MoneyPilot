import '../../core/supabase/supabase_config.dart';
import '../models/profile.dart';

class AlertsRepository {
  const AlertsRepository();

  Future<AlertPrefs?> fetch(String uid) async {
    final row = await supabase.from('alert_prefs').select().eq('user_id', uid).maybeSingle();
    if (row == null) return null;
    return AlertPrefs.fromJson(row);
  }

  Future<void> upsert({
    required String uid,
    required bool emailEnabled,
    required bool smsEnabled,
    required bool whatsappEnabled,
    String? email,
    String? phone,
    String? whatsapp,
  }) async {
    await supabase.from('alert_prefs').upsert({
      'user_id': uid,
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'whatsapp_enabled': whatsappEnabled,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Calls the `send-alert` edge function (see supabase/functions/send-alert).
  Future<Map<String, dynamic>> sendTestAlert({
    required List<String> channels,
    String? phone,
    String? email,
    required String message,
  }) async {
    final res = await supabase.functions.invoke('send-alert', body: {
      'channels': channels,
      'phone': phone,
      'email': email,
      'message': message,
    });
    if (res.status != 200) {
      throw Exception((res.data is Map ? res.data['error'] : null) ?? 'Failed to send alert');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }
}
