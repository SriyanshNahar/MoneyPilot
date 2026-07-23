import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/local/local_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/paisa_card.dart';
import '../../data/repositories/profile_repository.dart';
import '../auth/auth_controller.dart';
import '../shell/app_shell.dart';
import 'about_sheet.dart';
import 'account_settings_sheet.dart';
import 'alerts_sheet.dart';
import 'app_lock_setup_sheet.dart';
import 'backup_sheet.dart';
import 'plans_sheet.dart';
import 'privacy_sheet.dart';
import 'support_sheet.dart';
import 'theme_sheet.dart';

/// Direct port of src/routes/_app.settings.tsx, restructured for v2.1 with a
/// proper page header and grouped sections: Account, Subscription,
/// Notifications, Security, Privacy, Backup, About, Support, Logout.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _plan = 'free';
  String? _displayName;
  String? _avatarUrl;
  bool _uploadingAvatar = false;
  bool _loaded = false;

  String get _uid => ref.read(authControllerProvider).user!.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await LocalPrefs.getPlan();
    final profile = await const ProfileRepository().fetchFull(_uid);
    String? url;
    if (profile?.avatarUrl != null) {
      url = await const ProfileRepository().signedAvatarUrl(profile!.avatarUrl!, expiresInSeconds: 60 * 60 * 24 * 7);
    }
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _displayName = profile?.fullNameFromParts.isNotEmpty == true ? profile!.fullNameFromParts : profile?.displayName;
      _avatarUrl = url;
      _loaded = true;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024);
    if (file == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await File(file.path).readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) throw Exception('Image must be under 5 MB');
      final ext = file.path.split('.').last.toLowerCase();
      final repo = const ProfileRepository();
      final path = await repo.uploadAvatar(_uid, bytes, ext, 'image/$ext');
      await repo.updateAvatarPath(_uid, path);
      final url = await repo.signedAvatarUrl(path, expiresInSeconds: 60 * 60 * 24 * 7);
      if (mounted) setState(() => _avatarUrl = url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/auth');
  }

  void _openSheet(Widget child) {
    // Full-screen presentation (v2.1): every settings sheet now expands to
    // the full viewport height instead of a partial-height modal, still
    // using Material's native bottom-sheet slide-up transition. A close
    // button replaces "swipe down" as the primary dismiss affordance since
    // there's no visible scrim area left to tap once it's full height.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authControllerProvider).user;
    final theme = ref.watch(themeControllerProvider).pref;
    final isPro = _plan == 'pro';
    final displayName = _displayName ?? user?.email?.split('@').first ?? 'You';

    if (!_loaded) {
      return const AppShell(child: Center(child: CircularProgressIndicator()));
    }

    return AppShell(
      child: ListView(
        children: [
          // Page header (v2.1) — Settings didn't have a title at all before.
          const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Manage your account, subscription and preferences.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
          const SizedBox(height: 16),

          PaisaCard(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: colors.mutedForeground), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: isPro ? LinearGradient(colors: [colors.gradientStart, colors.gradientEnd]) : null,
                        color: isPro ? null : colors.mutedForeground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(isPro ? 'PRO' : 'FREE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAvatar,
                child: Stack(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.card,
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null ? Text(displayName[0].toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.primary)) : null,
                  ),
                  if (_uploadingAvatar)
                    const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle), child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle, border: Border.all(color: colors.card, width: 2)),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          _SectionGroup(title: 'Account', children: [
            _row(Icons.person_outline, 'Account', 'Name', scheme.primary, () => _openSheet(AccountSettingsSheet(onSaved: () {
                  Navigator.pop(context);
                  _load();
                }))),
          ]),
          _SectionGroup(title: 'Subscription', children: [
            _row(Icons.verified_user_outlined, 'Subscription', isPro ? 'MoneyPilot Pro' : 'Free plan', scheme.primary, () => _openSheet(PlansSheet(currentPlan: _plan, onPicked: (p) {
                  setState(() => _plan = p);
                  if (mounted) Navigator.pop(context);
                }))),
          ]),
          _SectionGroup(title: 'Notifications', children: [
            _row(Icons.notifications_outlined, 'Notifications', 'Email, SMS & WhatsApp alerts', const Color(0xFF059669), () {
              if (_plan == 'free') {
                _openSheet(PlansSheet(currentPlan: _plan, onPicked: (p) {
                  setState(() => _plan = p);
                  if (mounted) Navigator.pop(context);
                }));
              } else {
                _openSheet(AlertsSheet(defaultPhone: '', defaultEmail: user?.email ?? ''));
              }
            }),
          ]),
          _SectionGroup(title: 'Security', children: [
            _row(Icons.lock_outline, 'Security', 'App Lock — PIN, pattern, biometric', scheme.primary, () => _openSheet(const AppLockSetupSheet())),
          ]),
          _SectionGroup(title: 'Appearance', children: [
            _row(theme == ThemePref.dark ? Icons.dark_mode_outlined : theme == ThemePref.light ? Icons.wb_sunny_outlined : Icons.smartphone_outlined, 'Theme', 'Light, dark or auto', const Color(0xFF059669), () => _openSheet(const ThemeSheet())),
          ]),
          _SectionGroup(title: 'Privacy', children: [
            _row(Icons.shield_outlined, 'Privacy', 'Recovery info, export, delete', colors.mutedForeground, () => _openSheet(PrivacySheet(userId: user?.id, email: user?.email ?? ''))),
          ]),
          _SectionGroup(title: 'Backup', children: [
            _row(Icons.cloud_outlined, 'Backup', 'Cloud sync status & export', colors.mutedForeground, () => _openSheet(BackupSheet(userId: user?.id, email: user?.email ?? ''))),
          ]),
          _SectionGroup(title: 'About', children: [
            _row(Icons.info_outline, 'About', 'Version, credits', colors.mutedForeground, () => _openSheet(const AboutSheet())),
          ]),
          _SectionGroup(title: 'Support', children: [
            _row(Icons.help_outline, 'Support', 'Get help with MoneyPilot', colors.mutedForeground, () => _openSheet(const SupportSheet())),
          ]),

          const SizedBox(height: 8),
          PaisaCard(
            child: _row(Icons.logout, 'Logout Account', null, scheme.error, _signOut, danger: true),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String? sublabel, Color color, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), shape: BoxShape.circle), child: Icon(icon, size: 19, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: danger ? Theme.of(context).colorScheme.error : null)),
                if (sublabel != null) Text(sublabel, style: TextStyle(fontSize: 13, color: context.colors.mutedForeground)),
              ],
            ),
          ),
          if (!danger) Icon(Icons.chevron_right, size: 20, color: context.colors.mutedForeground),
        ]),
      ),
    );
  }
}

class _SectionGroup extends StatelessWidget {
  const _SectionGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.mutedForeground, letterSpacing: 0.5)),
          ),
          PaisaCard(child: Column(children: children)),
        ],
      ),
    );
  }
}
