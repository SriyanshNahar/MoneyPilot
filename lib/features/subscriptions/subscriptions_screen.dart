import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_quote.dart';
import '../../core/widgets/paisa_card.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/subscriptions_repository.dart';
import '../auth/auth_controller.dart';

const _repo = SubscriptionsRepository();
const _cycles = ['monthly', 'yearly', 'weekly'];

final _subscriptionsProvider = FutureProvider.autoDispose<List<Subscription>>((ref) async {
  final uid = ref.watch(authControllerProvider).user?.id;
  if (uid == null) return const [];
  return _repo.fetchAll(uid);
});

/// New in v2.1 — full CRUD module backed by the pre-existing `subscriptions`
/// table (previously only read narrowly, for dashboard reminders).
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  String? _busyId;

  void _goBack() => context.canPop() ? context.pop() : context.go('/dashboard');

  Future<void> _openForm({Subscription? existing}) async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
      builder: (ctx) => _SubscriptionFormSheet(uid: uid, existing: existing),
    );
    if (saved == true) ref.invalidate(_subscriptionsProvider);
  }

  Future<void> _confirmDelete(Subscription sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Symbols.warning_rounded, color: Theme.of(ctx).colorScheme.error, size: 36),
        title: const Text('Delete this subscription?', textAlign: TextAlign.center),
        content: Text('"${sub.name}" will be removed permanently.', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
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
    setState(() => _busyId = sub.id);
    try {
      await _repo.delete(sub.id);
      ref.invalidate(_subscriptionsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _toggleActive(Subscription sub) async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    setState(() => _busyId = sub.id);
    try {
      await _repo.update(
        Subscription(
          id: sub.id,
          name: sub.name,
          amount: sub.amount,
          billingCycle: sub.billingCycle,
          billingDay: sub.billingDay,
          isActive: !sub.isActive,
          startDate: sub.startDate,
          nextBillingDate: sub.nextBillingDate,
          logo: sub.logo,
        ),
        uid,
      );
      ref.invalidate(_subscriptionsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(_subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        leading: IconButton(icon: const Icon(Symbols.chevron_left_rounded), tooltip: 'Back', onPressed: _goBack),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Padding(padding: EdgeInsets.only(top: 60), child: FullLoadingQuote()),
          error: (e, st) => Center(child: Text('Failed to load: $e')),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  EmptyState(
                    icon: Symbols.subscriptions_rounded,
                    tint: colors.accentTint,
                    tintFg: const Color(0xFFF59E0B),
                    title: 'No subscriptions yet',
                    description: 'Keep tabs on OTT, SaaS and membership renewals so nothing surprises you.',
                    actionLabel: 'Add Subscription',
                    onAction: () => _openForm(),
                  ),
                ],
              );
            }
            final activeMonthly = items.where((s) => s.isActive).fold<double>(0, (s, sub) {
              final monthly = switch (sub.billingCycle) {
                'yearly' => sub.amount / 12,
                'weekly' => sub.amount * 4.33,
                _ => sub.amount,
              };
              return s + monthly;
            });
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PaisaCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('~MONTHLY SPEND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
                      Text(formatINRCompact(activeMonthly), style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final sub in items) ...[
                  _SubscriptionCard(sub: sub, busy: _busyId == sub.id, onEdit: () => _openForm(existing: sub), onDelete: () => _confirmDelete(sub), onToggle: () => _toggleActive(sub)),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 60),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Symbols.add_rounded),
        label: const Text('Add Subscription'),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.sub, required this.busy, required this.onEdit, required this.onDelete, required this.onToggle});
  final Subscription sub;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PaisaCard(
      padding: const EdgeInsets.all(14),
      onTap: onEdit,
      child: Opacity(
        opacity: sub.isActive ? 1 : 0.55,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  Text('${sub.billingCycle[0].toUpperCase()}${sub.billingCycle.substring(1)}${sub.nextBillingDate != null ? ' · next ${formatDateIN(sub.nextBillingDate!.toIso8601String())}' : ''}', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                ],
              ),
            ),
            Text(formatINR(sub.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Semantics(
              label: sub.isActive ? '${sub.name} is active, tap to deactivate' : '${sub.name} is inactive, tap to activate',
              child: Switch(value: sub.isActive, onChanged: busy ? null : (_) => onToggle()),
            ),
            IconButton(
              onPressed: busy ? null : onDelete,
              icon: const Icon(Symbols.delete_rounded, size: 20),
              tooltip: 'Delete',
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionFormSheet extends StatefulWidget {
  const _SubscriptionFormSheet({required this.uid, this.existing});
  final String uid;
  final Subscription? existing;

  @override
  State<_SubscriptionFormSheet> createState() => _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState extends State<_SubscriptionFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _amount = TextEditingController(text: widget.existing?.amount.toStringAsFixed(0) ?? '');
  late final _billingDay = TextEditingController(text: widget.existing?.billingDay?.toString() ?? '');
  late String _cycle = widget.existing?.billingCycle ?? _cycles.first;
  late bool _isActive = widget.existing?.isActive ?? true;
  DateTime? _nextBillingDate;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nextBillingDate = widget.existing?.nextBillingDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _billingDay.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _nextBillingDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2100));
    if (picked != null) setState(() => _nextBillingDate = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final amount = double.tryParse(_amount.text);
    if (name.isEmpty) {
      setState(() => _error = 'Enter the subscription name.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final sub = Subscription(
        id: widget.existing?.id ?? '',
        name: name,
        amount: amount,
        billingCycle: _cycle,
        billingDay: int.tryParse(_billingDay.text),
        isActive: _isActive,
        startDate: widget.existing?.startDate,
        nextBillingDate: _nextBillingDate,
        logo: widget.existing?.logo,
      );
      if (widget.existing == null) {
        await _repo.insert(sub, widget.uid);
      } else {
        await _repo.update(sub, widget.uid);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Subscription' : 'New Subscription', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Netflix')),
            const SizedBox(height: 12),
            TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _cycle,
              decoration: const InputDecoration(labelText: 'Billing cycle'),
              items: _cycles.map((c) => DropdownMenuItem(value: c, child: Text('${c[0].toUpperCase()}${c.substring(1)}'))).toList(),
              onChanged: (v) => setState(() => _cycle = v ?? _cycles.first),
            ),
            const SizedBox(height: 12),
            TextField(controller: _billingDay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Billing day of month (optional)')),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Next billing date (optional)'),
                child: Text(_nextBillingDate != null ? formatDateIN(_nextBillingDate!.toIso8601String()) : 'No date set'),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Save Changes' : 'Add Subscription'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
