import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/categories.dart';
import '../../core/offline/connectivity_provider.dart';
import '../../core/offline/offline_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/grouped_dropdown.dart';
import '../../core/widgets/premium_dropdown.dart';
import '../../data/repositories/expenses_repository.dart';
import '../auth/auth_controller.dart';

/// Direct port of src/routes/_app.expenses.new.tsx.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.forceType});
  final String? forceType; // "event" | "expense" | null

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  late String _category = widget.forceType == 'event' ? 'evt_birthday' : 'grocery';
  String _subCategory = '';
  final _name = TextEditingController();
  final _amount = TextEditingController();
  late DateTime _date = DateTime.now();
  final _remindBefore = TextEditingController();
  String _method = 'upi';
  final _upiId = TextEditingController();
  final _cardName = TextEditingController();
  final _cardLast4 = TextEditingController();
  final _bankName = TextEditingController();
  bool _busy = false;
  bool _success = false;

  bool get _isEvent => _category.startsWith('evt_');
  bool get _showRemind => _isEvent || categorySupportsReminder(_category);

  List<String> get _visibleGroups {
    if (widget.forceType == 'event') return const ['Events'];
    if (widget.forceType == 'expense') return categoryGroups.where((g) => g != 'Events').toList();
    return categoryGroups;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/khata');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onSubmit() async {
    if (!_isEvent) {
      final amt = double.tryParse(_amount.text);
      if (amt == null || amt <= 0) {
        _toast('Enter a valid amount');
        return;
      }
    }
    if (_name.text.trim().isEmpty) {
      _toast('Please enter a name');
      return;
    }
    if (_method == 'card' && _cardName.text.trim().isEmpty) {
      _toast('Enter the card name');
      return;
    }
    if (_method == 'netbanking' && _bankName.text.trim().isEmpty) {
      _toast('Enter the bank name');
      return;
    }
    if (_method == 'upi' && _upiId.text.isNotEmpty && !RegExp(r'^[\w.\-]{2,}@[\w.\-]{2,}$').hasMatch(_upiId.text)) {
      _toast('Enter a valid UPI ID');
      return;
    }
    if (_cardLast4.text.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(_cardLast4.text)) {
      _toast('Card details must be last 4 digits');
      return;
    }

    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    setState(() => _busy = true);
    final dateIso = '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    final String table;
    final Map<String, dynamic> payload;
    if (_isEvent) {
      final parentLabel = getCategory(_category).label;
      final evtType = _subCategory.isNotEmpty ? '$parentLabel · $_subCategory' : parentLabel;
      table = 'personal_events';
      payload = {
        'user_id': uid,
        'person_name': _name.text,
        'event_type': evtType,
        'event_date': dateIso,
        'alert_config': _remindBefore.text.isNotEmpty ? {'remind_before_days': int.parse(_remindBefore.text)} : null,
      };
    } else {
      final cat = getCategory(_category);
      table = 'expenses';
      payload = {
        'user_id': uid,
        'amount': double.parse(_amount.text),
        'category': _category,
        'sub_category': _subCategory.isNotEmpty ? _subCategory : null,
        'category_icon': cat.icon,
        'expense_date': dateIso,
        'note': _name.text,
        'payment_method': _method,
        'upi_id': _method == 'upi' ? (_upiId.text.isNotEmpty ? _upiId.text : null) : null,
        'card_name': _method == 'card' ? (_cardName.text.isNotEmpty ? _cardName.text : null) : null,
        'card_last4': _method == 'card' ? (_cardLast4.text.isNotEmpty ? _cardLast4.text : null) : null,
        'bank_name': _method == 'netbanking' ? (_bankName.text.isNotEmpty ? _bankName.text : null) : null,
        'remind_before_days': _remindBefore.text.isNotEmpty ? int.parse(_remindBefore.text) : null,
        'status': 'balance',
      };
    }

    try {
      if (table == 'personal_events') {
        await const EventsRepository().insert(payload);
      } else {
        await const ExpensesRepository().insert(payload);
      }
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) _goBack();
    } catch (e) {
      // Offline (or a transient network blip) — don't block the user from
      // logging an expense just because they have no signal. Queue it and
      // sync automatically once ConnectivityNotifier sees them come back
      // online (see core/offline/connectivity_provider.dart).
      final online = ref.read(connectivityProvider).online;
      if (!online) {
        await OfflineCache.instance.enqueueWrite(
          PendingWrite(id: '${DateTime.now().microsecondsSinceEpoch}', table: table, payload: payload),
        );
        ref.read(connectivityProvider.notifier).refreshPendingCount();
        if (mounted) {
          _toast(_isEvent ? "Saved offline — event will sync automatically." : 'Saved offline — expense will sync automatically.');
        }
        setState(() => _success = true);
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) _goBack();
        return;
      }
      _toast('Failed to save: $e');
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _remindBefore.dispose();
    _upiId.dispose();
    _cardName.dispose();
    _cardLast4.dispose();
    _bankName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subs = subCategories[_category] ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add expense'),
        leading: IconButton(icon: const Icon(Icons.chevron_left), tooltip: 'Back', onPressed: _goBack),
        actions: [TextButton(onPressed: _goBack, child: const Text('Cancel'))],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldGroup(
                    label: 'Category',
                    child: _CategoryDropdown(
                      value: _category,
                      groups: _visibleGroups,
                      onChanged: (v) => setState(() {
                        _category = v;
                        _subCategory = '';
                      }),
                    ),
                  ),
                  if (subs.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _FieldGroup(
                      label: 'Sub-category',
                      child: _Dropdown(
                        value: _subCategory.isEmpty ? null : _subCategory,
                        hint: 'Select…',
                        items: subs,
                        onChanged: (v) => setState(() => _subCategory = v ?? ''),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _FieldGroup(
                    label: _isEvent ? 'Person name' : 'Name',
                    child: TextField(
                      controller: _name,
                      decoration: InputDecoration(hintText: _isEvent ? 'e.g. Mom, Dad, Priya' : 'e.g. Netflix, HDFC EMI'),
                    ),
                  ),
                  if (!_isEvent) ...[
                    const SizedBox(height: 14),
                    _FieldGroup(
                      label: 'Amount',
                      child: TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _FieldGroup(
                          label: 'Date',
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2015),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setState(() => _date = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(),
                              child: Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
                            ),
                          ),
                        ),
                      ),
                      if (_showRemind) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FieldGroup(
                            label: 'Remind before (days)',
                            child: TextField(
                              controller: _remindBefore,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'e.g. 3'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!_isEvent) ...[
                    const SizedBox(height: 14),
                    _FieldGroup(
                      label: 'Payment method',
                      child: _Dropdown(
                        value: _method,
                        items: paymentMethods.map((p) => p.key).toList(),
                        labels: {for (final p in paymentMethods) p.key: p.label},
                        onChanged: (v) => setState(() => _method = v ?? 'upi'),
                      ),
                    ),
                    if (_method == 'upi') ...[
                      const SizedBox(height: 14),
                      _FieldGroup(label: 'UPI ID', child: TextField(controller: _upiId, decoration: const InputDecoration(hintText: 'yourname@bank'))),
                    ],
                    if (_method == 'card') ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _FieldGroup(label: 'Card name', child: TextField(controller: _cardName, decoration: const InputDecoration(hintText: 'HDFC Regalia')))),
                        const SizedBox(width: 12),
                        Expanded(child: _FieldGroup(label: 'Last 4 digits', child: TextField(controller: _cardLast4, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(hintText: '1234')))),
                      ]),
                    ],
                    if (_method == 'netbanking') ...[
                      const SizedBox(height: 14),
                      _FieldGroup(label: 'Bank name', child: TextField(controller: _bankName, decoration: const InputDecoration(hintText: 'e.g. HDFC Bank'))),
                    ],
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _busy ? null : _onSubmit,
                      child: _busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isEvent ? 'Save event' : 'Save expense'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_success)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [colors.gradientStart, colors.gradientEnd]),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 16),
                    Text(_isEvent ? 'Event saved' : 'Expense added', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('See it now in your Activity page.', style: TextStyle(color: colors.mutedForeground)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.groups, required this.onChanged});
  final String value;
  final List<String> groups;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final dropdownGroups = <DropdownGroupData>[];
    for (final group in groups) {
      final catsInGroup = expenseCategories.where((c) => c.group == group).toList();
      if (catsInGroup.isEmpty) continue;
      dropdownGroups.add(DropdownGroupData(group, [for (final c in catsInGroup) DropdownItemData(c.key, c.label)]));
    }
    return GroupedDropdownField(groups: dropdownGroups, value: value, onChanged: onChanged);
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.value, required this.items, required this.onChanged, this.hint, this.labels});
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final Map<String, String>? labels;

  @override
  Widget build(BuildContext context) {
    return PremiumDropdownField<String>(
      value: value,
      items: items,
      hint: hint,
      labelOf: (i) => labels?[i] ?? i,
      onChanged: onChanged,
    );
  }
}
