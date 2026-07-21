import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/categories.dart';
import '../../core/offline/offline_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/paisa_card.dart';
import '../../data/repositories/expenses_repository.dart';
import '../auth/auth_controller.dart';
import '../shell/app_shell.dart';

class _Row {
  const _Row({
    required this.id,
    required this.amount,
    required this.category,
    this.subCategory,
    required this.expenseDate,
    this.note,
    required this.paymentMethod,
    this.status,
  });
  final String id;
  final double amount;
  final String category;
  final String? subCategory;
  final String expenseDate;
  final String? note;
  final String paymentMethod;
  final String? status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'subCategory': subCategory,
        'expenseDate': expenseDate,
        'note': note,
        'paymentMethod': paymentMethod,
        'status': status,
      };

  factory _Row.fromJson(Map<String, dynamic> j) => _Row(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        subCategory: j['subCategory'] as String?,
        expenseDate: j['expenseDate'] as String,
        note: j['note'] as String?,
        paymentMethod: j['paymentMethod'] as String,
        status: j['status'] as String?,
      );
}

const _khataCacheKey = 'khata';

final _khataProvider = FutureProvider.autoDispose<List<_Row>>((ref) async {
  final uid = ref.watch(authControllerProvider).user?.id;
  if (uid == null) return const [];
  final cacheKey = '$_khataCacheKey:$uid';
  const expensesRepo = ExpensesRepository();
  const eventsRepo = EventsRepository();

  try {
    final expenses = await expensesRepo.fetchAll(uid);
    final events = await eventsRepo.fetchAll(uid);

    final rows = <_Row>[
      for (final e in expenses)
        _Row(
          id: e.id,
          amount: e.amount,
          category: e.category,
          subCategory: e.subCategory,
          expenseDate: e.expenseDate,
          note: e.note,
          paymentMethod: e.paymentMethod,
          status: e.status,
        ),
      for (final e in events)
        if (e.eventDate != null)
          _Row(
            id: 'evt-${e.id}',
            amount: 0,
            category: _eventCategoryKey(e.eventType),
            subCategory: e.eventType,
            expenseDate: e.eventDate!,
            note: e.personName,
            paymentMethod: 'event',
            status: 'event',
          ),
    ];
    rows.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    unawaited(OfflineCache.instance.put(cacheKey, {'rows': rows.map((r) => r.toJson()).toList()}));
    return rows;
  } catch (e) {
    final cached = OfflineCache.instance.get(cacheKey);
    if (cached == null) rethrow;
    return (cached.value['rows'] as List).map((r) => _Row.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }
});

String _eventCategoryKey(String eventType) {
  final label = eventType.toLowerCase();
  if (label.contains('wedding')) return 'evt_wedding';
  if (label.contains('anniv')) return 'evt_anniv';
  if (label.contains('festival') || label.contains('diwali') || label.contains('holi')) return 'evt_festival';
  if (label.contains('funeral') || label.contains('punya')) return 'evt_funeral';
  if (label.contains('religious') || label.contains('puja')) return 'evt_religious';
  return 'evt_birthday';
}

/// Direct port of src/routes/_app.khata.tsx.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String _query = '';
  String _cat = 'all';
  String? _deletingId;

  Future<void> _confirmAndDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Theme.of(ctx).colorScheme.error, size: 36),
        title: const Text('Delete this entry?', textAlign: TextAlign.center),
        content: const Text(
          'This cannot be undone. The entry will be removed from your Activity permanently.',
          textAlign: TextAlign.center,
        ),
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
    if (ok == true) await _performDelete(id);
  }

  Future<void> _performDelete(String id) async {
    setState(() => _deletingId = id);
    try {
      if (id.startsWith('evt-')) {
        await const EventsRepository().delete(id.substring(4));
      } else {
        await const ExpensesRepository().delete(id);
      }
      ref.invalidate(_khataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_khataProvider);
    final colors = context.colors;

    return AppShell(
      child: async.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.only(top: 80), child: CircularProgressIndicator())),
        error: (e, st) => Center(child: Text('Failed to load: $e')),
        data: (rows) {
          final filtered = rows.where((r) {
            if (_cat != 'all' && r.category != _cat) return false;
            if (_query.isNotEmpty) {
              final hay = '${r.note ?? ''} ${r.subCategory ?? ''}'.toLowerCase();
              if (!hay.contains(_query.toLowerCase())) return false;
            }
            return true;
          }).toList();
          final total = filtered.fold<double>(0, (s, r) => s + r.amount);

          final groupMap = <String, List<_Row>>{};
          for (final r in filtered) {
            final bucket = getActivityBucket(r.category);
            groupMap.putIfAbsent(bucket, () => []).add(r);
          }
          final groups = activityBuckets.where((b) => (groupMap[b]?.isNotEmpty ?? false)).toList();

          return ListView(
            children: [
              Text('Activity', style: Theme.of(context).textTheme.headlineMedium),
              Text('Your full ledger, grouped by category.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/expenses/new?type=expense'),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add expense'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFD946EF)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton.icon(
                        onPressed: () => context.push('/expenses/new?type=event'),
                        icon: const Icon(Icons.add, size: 20, color: Colors.white),
                        label: const Text('Add event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(hintText: 'Search name or sub-category…', prefixIcon: Icon(Icons.search, size: 22)),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _cat,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All categories')),
                  ...expenseCategories.map((c) => DropdownMenuItem(value: c.key, child: Text(c.label))),
                ],
                onChanged: (v) => setState(() => _cat = v ?? 'all'),
              ),
              const SizedBox(height: 12),
              PaisaCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL SHOWN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
                    Text(formatINRCompact(total), style: Theme.of(context).textTheme.headlineMedium),
                    Text('${formatINR(total)} · ${filtered.length} entries', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (groups.isEmpty)
                PaisaCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(children: [
                    Text('No expenses yet.', style: TextStyle(color: colors.mutedForeground)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/expenses/new'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add your first expense', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                )
              else
                for (final bucket in groups) ...[
                  _buildGroup(context, bucket, groupMap[bucket]!),
                  const SizedBox(height: 18),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroup(BuildContext context, String bucket, List<_Row> rows) {
    final colors = context.colors;
    final meta = bucketMeta[bucket]!;
    final sum = rows.fold<double>(0, (s, r) => s + r.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: meta.bg, borderRadius: BorderRadius.circular(13)), child: Icon(lucideIcon(meta.icon), size: 18, color: meta.color)),
          const SizedBox(width: 8),
          Text(bucket, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const Spacer(),
          Text('${rows.length} · ${formatINRCompact(sum)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground)),
        ]),
        const SizedBox(height: 8),
        for (final r in rows) ...[_buildRow(context, r), const SizedBox(height: 8)],
      ],
    );
  }

  Widget _buildRow(BuildContext context, _Row r) {
    final colors = context.colors;
    final isEvent = r.status == 'event';
    final paid = r.status == 'paid';

    return PaisaCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.note ?? r.subCategory ?? 'Expense', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17), overflow: TextOverflow.ellipsis),
                if (r.subCategory != null && r.note != null)
                  Text(r.subCategory!, style: TextStyle(fontSize: 14, color: colors.mutedForeground), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(formatDateIN(r.expenseDate), style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                    if (!isEvent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
                        child: Text(r.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    if (isEvent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFCE7F3), borderRadius: BorderRadius.circular(999)),
                        child: const Text('EVENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFBE185D))),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: paid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(999)),
                        child: Text(paid ? 'PAID' : 'BALANCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: paid ? const Color(0xFF047857) : const Color(0xFFB45309))),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isEvent) Text(formatINR(r.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              IconButton(
                onPressed: _deletingId == r.id ? null : () => _confirmAndDelete(r.id),
                icon: const Icon(Icons.delete_outline, size: 22),
                visualDensity: VisualDensity.compact,
                color: colors.mutedForeground,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
