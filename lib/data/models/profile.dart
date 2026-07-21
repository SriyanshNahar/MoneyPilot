/// Mirrors the `profiles` table.
class Profile {
  const Profile({
    required this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    this.displayName,
    this.avatarUrl,
    this.plan = 'free',
  });

  final String id;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? displayName;
  final String? avatarUrl;
  final String plan;

  String get fullNameFromParts =>
      [firstName, middleName, lastName].where((s) => s != null && s.trim().isNotEmpty).join(' ').trim();

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        firstName: j['first_name'] as String?,
        middleName: j['middle_name'] as String?,
        lastName: j['last_name'] as String?,
        displayName: j['display_name'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        plan: (j['plan'] as String?) ?? 'free',
      );
}

/// Mirrors the `alert_prefs` table.
class AlertPrefs {
  const AlertPrefs({
    this.email,
    this.emailEnabled = false,
    this.phone,
    this.smsEnabled = false,
    this.whatsapp,
    this.whatsappEnabled = false,
  });

  final String? email;
  final bool emailEnabled;
  final String? phone;
  final bool smsEnabled;
  final String? whatsapp;
  final bool whatsappEnabled;

  factory AlertPrefs.fromJson(Map<String, dynamic> j) => AlertPrefs(
        email: j['email'] as String?,
        emailEnabled: (j['email_enabled'] as bool?) ?? false,
        phone: j['phone'] as String?,
        smsEnabled: (j['sms_enabled'] as bool?) ?? false,
        whatsapp: j['whatsapp'] as String?,
        whatsappEnabled: (j['whatsapp_enabled'] as bool?) ?? false,
      );
}
