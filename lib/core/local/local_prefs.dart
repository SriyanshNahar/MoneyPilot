import 'package:shared_preferences/shared_preferences.dart';

/// Device-local settings that mirror the localStorage keys used across
/// settings.tsx / AppShell.tsx: plan cache, alert phone number, and the
/// settings-only local avatar. Real profile data lives in Supabase —
/// these are purely device-local UI conveniences, same as the React app.
class LocalPrefs {
  const LocalPrefs._();

  static const _planKey = 'mp_plan';
  static const _phoneKey = 'mp_phone';
  static const _recoveryKey = 'mp_recovery_v1';

  static Future<String> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_planKey) == 'pro' ? 'pro' : 'free';
  }

  static Future<void> setPlan(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, plan);
  }

  static Future<String> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey) ?? '';
  }

  static Future<void> setPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
  }

  static String _localAvatarKey(String uid) => 'mp_settings_avatar_$uid';

  static Future<String?> getLocalAvatarPath(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localAvatarKey(uid));
  }

  static Future<void> setLocalAvatarPath(String uid, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localAvatarKey(uid), path);
  }

  static Future<void> clearLocalAvatar(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localAvatarKey(uid));
  }

  static Future<Map<String, String?>> getRecovery() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'recoveryEmail': prefs.getString('${_recoveryKey}_email'),
      'recoveryPhone': prefs.getString('${_recoveryKey}_phone'),
      'passphraseHash': prefs.getString('${_recoveryKey}_hash'),
    };
  }

  static Future<void> setRecovery({String? email, String? phone, String? passphraseHash}) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null) await prefs.setString('${_recoveryKey}_email', email);
    if (phone != null) await prefs.setString('${_recoveryKey}_phone', phone);
    if (passphraseHash != null) await prefs.setString('${_recoveryKey}_hash', passphraseHash);
  }
}
