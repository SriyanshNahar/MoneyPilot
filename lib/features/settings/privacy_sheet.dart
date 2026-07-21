import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/local/local_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/expenses_repository.dart';
import '../../data/repositories/profile_repository.dart';

/// Direct port of the DataPrivacyBlock component in settings.tsx.
class PrivacySheet extends StatefulWidget {
  const PrivacySheet({super.key, required this.userId, required this.email});
  final String? userId;
  final String email;

  @override
  State<PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends State<PrivacySheet> {
  final _recoveryEmail = TextEditingController();
  final _recoveryPhone = TextEditingController();
  final _pass = TextEditingController();
  String? _passphraseHash;
  bool _saving = false;
  bool _exporting = false;
  bool _wiping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await LocalPrefs.getRecovery();
    if (!mounted) return;
    setState(() {
      _recoveryEmail.text = r['recoveryEmail'] ?? '';
      _recoveryPhone.text = r['recoveryPhone'] ?? '';
      _passphraseHash = r['passphraseHash'];
    });
  }

  Future<void> _saveRecovery() async {
    setState(() => _saving = true);
    try {
      String? hash = _passphraseHash;
      if (_pass.text.trim().isNotEmpty) {
        if (_pass.text.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recovery passphrase must be at least 6 characters')));
          setState(() => _saving = false);
          return;
        }
        hash = sha256.convert(utf8.encode(_pass.text)).toString();
      }
      await LocalPrefs.setRecovery(email: _recoveryEmail.text, phone: _recoveryPhone.text, passphraseHash: hash);
      setState(() {
        _passphraseHash = hash;
        _pass.clear();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings saved securely on this device')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportData() async {
    if (widget.userId == null) return;
    setState(() => _exporting = true);
    try {
      final expenses = await const ExpensesRepository().exportAll(widget.userId!);
      final events = await const EventsRepository().exportAll(widget.userId!);
      final profile = await const ProfileRepository().exportProfile(widget.userId!);
      final payload = {
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'email': widget.email,
        'profile': profile,
        'expenses': expenses,
        'events': events,
      };
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/moneypilot-export-${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
      await Share.shareXFiles([XFile(file.path)], text: 'MoneyPilot data export');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data exported')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAllData() async {
    if (widget.userId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ALL your data?'),
        content: const Text('This deletes all expenses and events. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _wiping = true);
    try {
      await const ExpensesRepository().deleteAllForUser(widget.userId!);
      await const EventsRepository().deleteAllForUser(widget.userId!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All records deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _wiping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data & Privacy', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          Text('Your data stays yours. Manage security, exports and deletion here.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.primaryTint.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.shield_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('End-to-end secure', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'Your data is stored on our encrypted backend and protected by row-level security — only you can read it. Recovery details below are hashed on this device before being saved.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recovery information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Text('RECOVERY EMAIL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
          const SizedBox(height: 6),
          TextField(controller: _recoveryEmail, decoration: const InputDecoration(hintText: 'backup@email.com')),
          const SizedBox(height: 10),
          Text('RECOVERY PHONE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
          const SizedBox(height: 6),
          TextField(controller: _recoveryPhone, decoration: const InputDecoration(hintText: '+91 98••• •••••')),
          const SizedBox(height: 10),
          Text(_passphraseHash != null ? 'RECOVERY PASSPHRASE · SET' : 'RECOVERY PASSPHRASE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
          const SizedBox(height: 6),
          TextField(controller: _pass, obscureText: true, decoration: InputDecoration(hintText: _passphraseHash != null ? 'Enter to replace' : 'Min. 6 characters')),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Hashed with SHA-256 on your device. We never see the raw value.', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(onPressed: _saving ? null : _saveRecovery, child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save privacy settings')),
          ),
          const SizedBox(height: 20),
          const Text('Your data', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          InkWell(
            onTap: _exporting ? null : _exportData,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Export my data', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text("Download a JSON copy of everything you've saved.", style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                    ],
                  ),
                ),
                _exporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _wiping ? null : _deleteAllData,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colors.destructiveTint.withValues(alpha: 0.5), border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delete all my records', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.error)),
                      Text('Erases expenses and personal events. Cannot be undone.', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                _wiping ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.error)) : Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.error),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text('MoneyPilot never sells your data. Read our privacy commitment in the app footer.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
        ],
      ),
    );
  }
}
