import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/offline/offline_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/expenses_repository.dart';
import '../../data/repositories/profile_repository.dart';

/// New in v2.1 — "Backup" section of the restructured Settings screen.
/// MoneyPilot doesn't have a separate manual backup step: every write goes
/// straight to Supabase (cloud sync is always-on, not a toggle), so this
/// sheet is mostly about making that visible + offering an on-device export,
/// reusing the same export shape as Data & Privacy.
class BackupSheet extends StatefulWidget {
  const BackupSheet({super.key, required this.userId, required this.email});
  final String? userId;
  final String email;

  @override
  State<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<BackupSheet> {
  bool _exporting = false;

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
      final file = File('${dir.path}/moneypilot-backup-${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
      await Share.shareXFiles([XFile(file.path)], text: 'MoneyPilot backup');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup exported')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pendingWrites = OfflineCache.instance.pendingWriteCount;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Backup', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          Text('Your data and how it stays safe.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: colors.successTint, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(Icons.cloud_done_outlined, color: colors.successForeground, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cloud sync is always on', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.successForeground)),
                    Text('Every expense, event and setting saves straight to your Supabase account — nothing to turn on.', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                  ],
                ),
              ),
            ]),
          ),
          if (pendingWrites > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.accentTint, borderRadius: BorderRadius.circular(14)),
              child: Text(
                '$pendingWrites ${pendingWrites == 1 ? 'entry' : 'entries'} saved offline, waiting to sync once you\'re back online.',
                style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Manual backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Download a point-in-time JSON copy of your expenses, events and profile.', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _exporting ? null : _exportData,
              icon: _exporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_outlined, size: 20),
              label: Text(_exporting ? 'Exporting…' : 'Export backup now'),
            ),
          ),
        ],
      ),
    );
  }
}
