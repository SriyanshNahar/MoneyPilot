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
import 'account_settings_sheet.dart';
import 'alerts_sheet.dart';
import 'app_lock_setup_sheet.dart';
import 'plans_sheet.dart';
import 'privacy_sheet.dart';
import 'theme_sheet.dart';

/// Direct port of src/routes/_app.settings.tsx.
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      builder: (ctx) => child,
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
          PaisaCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SIGNED IN AS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.mutedForeground, letterSpacing: 0.6)),
                        const SizedBox(height: 4),
                        Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                        Text(user?.email ?? '', style: TextStyle(fontSize: 15, color: colors.mutedForeground), overflow: TextOverflow.ellipsis),
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
                        child: _avatarUrl == null ? Text(displayName[0].toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: scheme.primary)) : null,
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ACCOUNT PLAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.mutedForeground, letterSpacing: 0.6)),
                          Text(isPro ? 'MoneyPilot Pro' : 'Free plan', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isPro ? LinearGradient(colors: [colors.gradientStart, colors.gradientEnd]) : null,
                        color: isPro ? null : colors.mutedForeground.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(isPro ? 'PRO' : 'FREE', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                _row(Icons.verified_user_outlined, 'My Plan Benefits', scheme.primary, () => _openSheet(PlansSheet(currentPlan: _plan, onPicked: (p) async {
                      setState(() => _plan = p);
                      if (mounted) Navigator.pop(context);
                    }))),
                _row(Icons.settings_outlined, 'Account Settings', colors.mutedForeground, () => _openSheet(AccountSettingsSheet(onSaved: () {
                      Navigator.pop(context);
                      _load();
                    }))),
                _row(Icons.lock_outline, 'App Lock', scheme.primary, () => _openSheet(const AppLockSetupSheet())),
                _row(Icons.notifications_outlined, 'Alert Channels', const Color(0xFF059669), () {
                  if (_plan == 'free') {
                    _openSheet(PlansSheet(currentPlan: _plan, onPicked: (p) {
                      setState(() => _plan = p);
                      if (mounted) Navigator.pop(context);
                    }));
                  } else {
                    _openSheet(AlertsSheet(defaultPhone: '', defaultEmail: user?.email ?? ''));
                  }
                }),
                _row(theme == ThemePref.dark ? Icons.dark_mode_outlined : theme == ThemePref.light ? Icons.wb_sunny_outlined : Icons.smartphone_outlined, 'Appearance & Theme', const Color(0xFF059669), () => _openSheet(const ThemeSheet())),
                _row(Icons.shield_outlined, 'Data & Privacy', colors.mutedForeground, () => _openSheet(PrivacySheet(userId: user?.id, email: user?.email ?? ''))),
                _row(Icons.logout, 'Logout Account', scheme.error, _signOut, danger: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('MoneyPilot · v0.4 · A smart money app by Seven Sapience.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, Color color, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), shape: BoxShape.circle), child: Icon(icon, size: 19, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: danger ? Theme.of(context).colorScheme.error : null))),
          if (!danger) Icon(Icons.chevron_right, size: 20, color: context.colors.mutedForeground),
        ]),
      ),
    );
  }
}
