import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_quote.dart';
import '../../core/widgets/paisa_card.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/loans_repository.dart';
import '../auth/auth_controller.dart';

const _repo = LoansRepository();
const _loanTypes = ['Home', 'Car', 'Personal', 'Education', 'Gold', 'Other'];

final _loansProvider = FutureProvider.autoDispose<List<Loan>>((ref) async {
  final uid = ref.watch(authControllerProvider).user?.id;
  if (uid == null) return const [];
  return _repo.fetchAll(uid);
});

/// New in v2.1 — full CRUD module backed by the pre-existing `loans` table
/// (previously only read narrowly, for dashboard reminders).
class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  String? _busyId;

  void _goBack() => context.canPop() ? context.pop() : context.go('/dashboard');

  Future<void> _openForm({Loan? existing}) async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
      builder: (ctx) => _LoanFormSheet(uid: uid, existing: existing),
    );
    if (saved == true) ref.invalidate(_loansProvider);
  }

  Future<void> _confirmDelete(Loan loan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Symbols.warning_rounded, color: Theme.of(ctx).colorScheme.error, size: 36),
        title: const Text('Delete this loan?', textAlign: TextAlign.center),
        content: Text('"${loan.lender}" will be removed permanently.', textAlign: TextAlign.center),
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
    setState(() => _busyId = loan.id);
    try {
      await _repo.delete(loan.id);
      ref.invalidate(_loansProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(_loansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
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
                    icon: Symbols.account_balance_rounded,
                    tint: colors.destructiveTint,
                    tintFg: Theme.of(context).colorScheme.error,
                    title: 'No loans yet',
                    description: 'Track EMIs, interest and outstanding balances for home, car or personal loans.',
                    actionLabel: 'Add Loan',
                    onAction: () => _openForm(),
                  ),
                ],
              );
            }
            final totalOutstanding = items.fold<double>(0, (s, l) => s + l.outstanding);
            final totalEmi = items.fold<double>(0, (s, l) => s + l.emi);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PaisaCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OUTSTANDING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
                            Text(formatINRCompact(totalOutstanding), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MONTHLY EMI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
                            Text(formatINRCompact(totalEmi), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final loan in items) ...[
                  _LoanCard(loan: loan, busy: _busyId == loan.id, onEdit: () => _openForm(existing: loan), onDelete: () => _confirmDelete(loan)),
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
        label: const Text('Add Loan'),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.busy, required this.onEdit, required this.onDelete});
  final Loan loan;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = loan.principal <= 0 ? 0.0 : (loan.principalPaid / loan.principal).clamp(0.0, 1.0);
    return PaisaCard(
      padding: const EdgeInsets.all(14),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.lender, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text('${loan.loanType} · ${loan.interestRate.toStringAsFixed(1)}% p.a.', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                  ],
                ),
              ),
              Text('${formatINR(loan.emi)}/mo', style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: busy ? null : onDelete,
                icon: const Icon(Symbols.delete_rounded, size: 20),
                tooltip: 'Delete',
                color: colors.mutedForeground,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest),
          ),
          const SizedBox(height: 8),
          Text('${formatINRCompact(loan.outstanding)} outstanding of ${formatINRCompact(loan.principal)}', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
        ],
      ),
    );
  }
}

class _LoanFormSheet extends StatefulWidget {
  const _LoanFormSheet({required this.uid, this.existing});
  final String uid;
  final Loan? existing;

  @override
  State<_LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends State<_LoanFormSheet> {
  late final _lender = TextEditingController(text: widget.existing?.lender ?? '');
  late final _principal = TextEditingController(text: widget.existing?.principal.toStringAsFixed(0) ?? '');
  late final _outstanding = TextEditingController(text: widget.existing?.outstanding.toStringAsFixed(0) ?? '');
  late final _interestRate = TextEditingController(text: widget.existing?.interestRate.toStringAsFixed(2) ?? '');
  late final _emi = TextEditingController(text: widget.existing?.emi.toStringAsFixed(0) ?? '');
  late final _tenure = TextEditingController(text: widget.existing?.tenureMonths.toString() ?? '');
  late final _dueDay = TextEditingController(text: widget.existing?.dueDay?.toString() ?? '');
  late String _loanType = widget.existing?.loanType ?? _loanTypes.first;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _lender.dispose();
    _principal.dispose();
    _outstanding.dispose();
    _interestRate.dispose();
    _emi.dispose();
    _tenure.dispose();
    _dueDay.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lender = _lender.text.trim();
    final principal = double.tryParse(_principal.text);
    final outstanding = double.tryParse(_outstanding.text);
    final rate = double.tryParse(_interestRate.text);
    final emi = double.tryParse(_emi.text);
    final tenure = int.tryParse(_tenure.text);
    if (lender.isEmpty) {
      setState(() => _error = 'Enter the lender name.');
      return;
    }
    if (principal == null || principal <= 0) {
      setState(() => _error = 'Enter a valid loan (principal) amount.');
      return;
    }
    if (outstanding == null || outstanding < 0) {
      setState(() => _error = 'Enter a valid outstanding balance.');
      return;
    }
    if (rate == null || rate < 0) {
      setState(() => _error = 'Enter a valid interest rate.');
      return;
    }
    if (emi == null || emi <= 0) {
      setState(() => _error = 'Enter a valid EMI amount.');
      return;
    }
    if (tenure == null || tenure <= 0) {
      setState(() => _error = 'Enter a valid tenure in months.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final loan = Loan(
        id: widget.existing?.id ?? '',
        lender: lender,
        loanType: _loanType,
        principal: principal,
        outstanding: outstanding,
        interestRate: rate,
        emi: emi,
        tenureMonths: tenure,
        principalPaid: widget.existing?.principalPaid ?? 0,
        interestPaid: widget.existing?.interestPaid ?? 0,
        dueDay: int.tryParse(_dueDay.text),
        startDate: widget.existing?.startDate,
        nextDueDate: widget.existing?.nextDueDate,
      );
      if (widget.existing == null) {
        await _repo.insert(loan, widget.uid);
      } else {
        await _repo.update(loan, widget.uid);
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
            Text(isEdit ? 'Edit Loan' : 'New Loan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _lender, decoration: const InputDecoration(labelText: 'Lender', hintText: 'e.g. HDFC Bank')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _loanType,
              decoration: const InputDecoration(labelText: 'Loan type'),
              items: _loanTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _loanType = v ?? _loanTypes.first),
            ),
            const SizedBox(height: 12),
            TextField(controller: _principal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Loan amount / principal (₹)')),
            const SizedBox(height: 12),
            TextField(controller: _outstanding, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Outstanding balance (₹)')),
            const SizedBox(height: 12),
            TextField(controller: _interestRate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Interest rate (% p.a.)')),
            const SizedBox(height: 12),
            TextField(controller: _emi, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly EMI (₹)')),
            const SizedBox(height: 12),
            TextField(controller: _tenure, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tenure (months)')),
            const SizedBox(height: 12),
            TextField(controller: _dueDay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'EMI due day of month (optional)')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Save Changes' : 'Add Loan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
