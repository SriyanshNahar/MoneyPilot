import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/profile_repository.dart';
import '../auth/auth_controller.dart';

/// Direct port of the NameEditForm in settings.tsx: first/middle/last name.
/// Profile photo editing lives only on the Profile page itself (real,
/// Supabase-Storage-backed upload) — this sheet no longer has its own
/// separate, device-local photo control, so there is exactly one place to
/// change the profile picture.
class AccountSettingsSheet extends ConsumerStatefulWidget {
  const AccountSettingsSheet({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<AccountSettingsSheet> createState() => _AccountSettingsSheetState();
}

class _AccountSettingsSheetState extends ConsumerState<AccountSettingsSheet> {
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  String get _uid => ref.read(authControllerProvider).user!.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await const ProfileRepository().fetchFull(_uid);
    if (!mounted) return;
    setState(() {
      if (profile != null) {
        _first.text = profile.firstName ?? '';
        _middle.text = profile.middleName ?? '';
        _last.text = profile.lastName ?? '';
        if ((profile.firstName == null || profile.firstName!.isEmpty) && profile.displayName != null) {
          final parts = profile.displayName!.split(' ').where((s) => s.isNotEmpty).toList();
          if (parts.isNotEmpty) _first.text = parts.first;
          if (parts.length > 1) _last.text = parts.last;
          if (parts.length > 2) _middle.text = parts.sublist(1, parts.length - 1).join(' ');
        }
      }
      _loading = false;
    });
  }

  String get _fullName => [_first.text, _middle.text, _last.text].map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');

  Future<void> _save() async {
    if (_first.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await const ProfileRepository().updateNames(
        _uid,
        firstName: _first.text.trim(),
        middleName: _middle.text.trim().isEmpty ? null : _middle.text.trim(),
        lastName: _last.text.trim().isEmpty ? null : _last.text.trim(),
        displayName: _fullName.isEmpty ? null : _fullName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account settings updated')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Settings', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          Text('Update your name.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          Text('FIRST NAME', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          TextField(controller: _first, decoration: const InputDecoration(hintText: 'e.g. Shriyansh')),
          const SizedBox(height: 12),
          Text('MIDDLE NAME (OPTIONAL)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          TextField(controller: _middle, decoration: const InputDecoration(hintText: 'e.g. Kumar')),
          const SizedBox(height: 12),
          Text('LAST NAME', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          TextField(controller: _last, decoration: const InputDecoration(hintText: 'e.g. Nahar'), onChanged: (_) => setState(() {})),
          if (_fullName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: colors.primaryTint.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
              child: Text.rich(TextSpan(text: 'Full name: ', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14), children: [
                TextSpan(text: _fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
              ])),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}
