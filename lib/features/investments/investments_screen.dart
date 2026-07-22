import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_quote.dart';
import '../../core/widgets/paisa_card.dart';
import '../../data/models/investment.dart';
import '../../data/repositories/investments_repository.dart';
import '../auth/auth_controller.dart';

const _repo = InvestmentsRepository();
const _invTypes = ['SIP', 'Lumpsum', 'FD', 'RD', 'Stocks', 'Other'];

final _investmentsProvider = FutureProvider.autoDispose<List<Investment>>((ref) async {
  final uid = ref.watch(authControllerProvider).user?.id;
  if (uid == null) return const [];
  return _repo.fetchAll(uid);
});

/// New in v2.1 — full CRUD module backed by the pre-existing `investments`
/// table (previously only read narrowly, for dashboard reminders).
class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  String? _busyId;

  void _goBack() => context.canPop() ? context.pop() : context.go('/dashboard');

  Future<void> _openForm({Investment? existing}) async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
      builder: (ctx) => _InvestmentFormSheet(uid: uid, existing: existing),
    );
    if (saved == true) ref.invalidate(_investmentsProvider);
  }

  Future<void> _confirmDelete(Investment inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Symbols.warning_rounded, color: Theme.of(ctx).colorScheme.error, size: 36),
        title: const Text('Delete this investment?', textAlign: TextAlign.center),
        content: Text('"${inv.name}" will be removed permanently.', textAlign: TextAlign.center),
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
    setState(() => _busyId = inv.id);
    try {
      await _repo.delete(inv.id);
      ref.invalidate(_investmentsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(_investmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments'),
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
                    icon: Symbols.trending_up_rounded,
                    tint: colors.secondaryTint,
                    tintFg: const Color(0xFF0F766E),
                    title: 'No investments yet',
                    description: 'Track your SIPs, mutual funds, FDs and stocks in one place.',
                    actionLabel: 'Add Investment',
                    onAction: () => _openForm(),
                  ),
                ],
              );
            }
            final total = items.fold<double>(0, (s, i) => s + (i.currentValue ?? i.amount));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PaisaCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL VALUE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
                      Text(formatINRCompact(total), style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final inv in items) ...[
                  _InvestmentCard(inv: inv, busy: _busyId == inv.id, onEdit: () => _openForm(existing: inv), onDelete: () => _confirmDelete(inv)),
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
        label: const Text('Add Investment'),
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  const _InvestmentCard({required this.inv, required this.busy, required this.onEdit, required this.onDelete});
  final Investment inv;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final gain = (inv.currentValue ?? inv.amount) - inv.amount;
    return PaisaCard(
      padding: const EdgeInsets.all(14),
      onTap: onEdit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                if (inv.amc != null) Text(inv.amc!, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: colors.secondaryTint, borderRadius: BorderRadius.circular(999)),
                  child: Text(inv.invType.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatINR(inv.currentValue ?? inv.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
              if (inv.currentValue != null && gain != 0)
                Text(
                  '${gain > 0 ? '+' : ''}${formatINR(gain)}',
                  style: TextStyle(fontSize: 12, color: gain > 0 ? colors.successForeground : Theme.of(context).colorScheme.error),
                ),
              IconButton(
                onPressed: busy ? null : onDelete,
                icon: const Icon(Symbols.delete_rounded, size: 20),
                tooltip: 'Delete',
                color: colors.mutedForeground,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvestmentFormSheet extends StatefulWidget {
  const _InvestmentFormSheet({required this.uid, this.existing});
  final String uid;
  final Investment? existing;

  @override
  State<_InvestmentFormSheet> createState() => _InvestmentFormSheetState();
}

class _InvestmentFormSheetState extends State<_InvestmentFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _amc = TextEditingController(text: widget.existing?.amc ?? '');
  late final _amount = TextEditingController(text: widget.existing?.amount.toStringAsFixed(0) ?? '');
  late final _currentValue = TextEditingController(text: widget.existing?.currentValue?.toStringAsFixed(0) ?? '');
  late final _sipDay = TextEditingController(text: widget.existing?.sipDay?.toString() ?? '');
  late String _invType = widget.existing?.invType ?? _invTypes.first;
  DateTime? _startDate;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDate = widget.existing?.startDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _amc.dispose();
    _amount.dispose();
    _currentValue.dispose();
    _sipDay.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final amount = double.tryParse(_amount.text);
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name for this investment.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid invested amount.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final inv = Investment(
        id: widget.existing?.id ?? '',
        name: name,
        invType: _invType,
        amount: amount,
        currentValue: double.tryParse(_currentValue.text),
        amc: _amc.text.trim().isEmpty ? null : _amc.text.trim(),
        sipDay: _invType == 'SIP' ? int.tryParse(_sipDay.text) : null,
        startDate: _startDate,
      );
      if (widget.existing == null) {
        await _repo.insert(inv, widget.uid);
      } else {
        await _repo.update(inv, widget.uid);
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
            Text(isEdit ? 'Edit Investment' : 'New Investment', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Axis Bluechip Fund')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _invType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _invTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _invType = v ?? _invTypes.first),
            ),
            const SizedBox(height: 12),
            TextField(controller: _amc, decoration: const InputDecoration(labelText: 'Fund house / broker (optional)')),
            const SizedBox(height: 12),
            TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Invested amount (₹)')),
            const SizedBox(height: 12),
            TextField(controller: _currentValue, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current value (₹, optional)')),
            if (_invType == 'SIP') ...[
              const SizedBox(height: 12),
              TextField(controller: _sipDay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'SIP day of month (1-28)')),
            ],
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Start date (optional)'),
                child: Text(_startDate != null ? formatDateIN(_startDate!.toIso8601String()) : 'No date set'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Save Changes' : 'Add Investment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
