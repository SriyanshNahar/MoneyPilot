import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_quote.dart';
import '../../core/widgets/paisa_card.dart';
import '../../data/models/goal.dart';
import '../../data/repositories/goals_repository.dart';
import '../auth/auth_controller.dart';

const _repo = GoalsRepository();

final _goalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) async {
  final uid = ref.watch(authControllerProvider).user?.id;
  if (uid == null) return const [];
  return _repo.fetchAll(uid);
});

/// New in v2.1 — full CRUD module with no equivalent in the source React app.
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String? _busyId;

  void _goBack() => context.canPop() ? context.pop() : context.go('/dashboard');

  Future<void> _openForm({Goal? existing}) async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
      builder: (ctx) => _GoalFormSheet(uid: uid, existing: existing),
    );
    if (saved == true) ref.invalidate(_goalsProvider);
  }

  Future<void> _confirmDelete(Goal g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Symbols.warning_rounded, color: Theme.of(ctx).colorScheme.error, size: 36),
        title: const Text('Delete this goal?', textAlign: TextAlign.center),
        content: Text('"${g.name}" will be removed permanently.', textAlign: TextAlign.center),
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
    setState(() => _busyId = g.id);
    try {
      await _repo.delete(g.id);
      ref.invalidate(_goalsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(_goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        leading: IconButton(icon: const Icon(Symbols.chevron_left_rounded), tooltip: 'Back', onPressed: _goBack),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Padding(padding: EdgeInsets.only(top: 60), child: FullLoadingQuote()),
          error: (e, st) => Center(child: Text('Failed to load: $e')),
          data: (goals) {
            if (goals.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  EmptyState(
                    icon: Symbols.flag_rounded,
                    tint: colors.primaryTint,
                    tintFg: Theme.of(context).colorScheme.primary,
                    title: 'No goals yet',
                    description: 'Set a savings target — a trip, an emergency fund, a new gadget — and track your progress here.',
                    actionLabel: 'Add Goal',
                    onAction: () => _openForm(),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final g in goals) ...[
                  _GoalCard(goal: g, busy: _busyId == g.id, onEdit: () => _openForm(existing: g), onDelete: () => _confirmDelete(g)),
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
        label: const Text('Add Goal'),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.busy, required this.onEdit, required this.onDelete});
  final Goal goal;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PaisaCard(
      padding: const EdgeInsets.all(16),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(goal.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
              if (goal.isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: colors.successTint, borderRadius: BorderRadius.circular(999)),
                  child: Text('DONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.successForeground)),
                ),
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
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(goal.isComplete ? colors.success : Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${formatINRCompact(goal.currentAmount)} of ${formatINRCompact(goal.targetAmount)}', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
              if (goal.targetDate != null)
                Text('by ${formatDateIN(goal.targetDate!.toIso8601String())}', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({required this.uid, this.existing});
  final String uid;
  final Goal? existing;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _target = TextEditingController(text: widget.existing?.targetAmount.toStringAsFixed(0) ?? '');
  late final _current = TextEditingController(text: widget.existing?.currentAmount.toStringAsFixed(0) ?? '0');
  DateTime? _targetDate;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _targetDate = widget.existing?.targetDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _current.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final target = double.tryParse(_target.text);
    final current = double.tryParse(_current.text) ?? 0;
    if (name.isEmpty) {
      setState(() => _error = 'Give your goal a name.');
      return;
    }
    if (target == null || target <= 0) {
      setState(() => _error = 'Enter a valid target amount.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      if (widget.existing == null) {
        await _repo.insert(
          Goal(id: '', name: name, targetAmount: target, currentAmount: current, targetDate: _targetDate),
          widget.uid,
        );
      } else {
        await _repo.update(
          Goal(id: widget.existing!.id, name: name, targetAmount: target, currentAmount: current, targetDate: _targetDate, icon: widget.existing!.icon),
        );
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
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999))),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Goal' : 'New Goal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Goal name', hintText: 'e.g. Emergency fund')),
            const SizedBox(height: 12),
            TextField(controller: _target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target amount (₹)')),
            const SizedBox(height: 12),
            TextField(controller: _current, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Already saved (₹)')),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Target date (optional)'),
                child: Text(_targetDate != null ? formatDateIN(_targetDate!.toIso8601String()) : 'No date set'),
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
                child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Save Changes' : 'Add Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
