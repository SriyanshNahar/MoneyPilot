import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/notifications/reminder_scheduler.dart';
import '../../core/offline/offline_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/loading_quote.dart';
import '../../core/widgets/paisa_card.dart';
import '../../data/models/expense.dart';
import '../../data/models/money.dart';
import '../../data/repositories/expenses_repository.dart';
import '../../data/repositories/money_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../auth/auth_controller.dart';
import '../shell/app_shell.dart';

class _Reminder {
  const _Reminder({required this.id, required this.name, required this.amount, required this.dueDate, required this.mode, required this.status});
  final String id;
  final String name;
  final double? amount;
  final String dueDate;
  final String mode;
  final String status; // Paid | Balance | Event
}

class _DashboardData {
  const _DashboardData({
    required this.firstName,
    required this.expenses,
    required this.subs,
    required this.loans,
    required this.sips,
    required this.events,
  });
  final String? firstName;
  final List<Expense> expenses;
  final List<SubscriptionRow> subs;
  final List<LoanRow> loans;
  final List<InvestmentRow> sips;
  final List<PersonalEvent> events;
}

const _dashboardCacheKey = 'dashboard';

final _dashboardProvider = FutureProvider.autoDispose<_DashboardData>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final uid = auth.user?.id;
  if (uid == null) {
    return const _DashboardData(firstName: null, expenses: [], subs: [], loans: [], sips: [], events: []);
  }
  const expensesRepo = ExpensesRepository();
  const eventsRepo = EventsRepository();
  const moneyRepo = MoneyRepository();
  const profileRepo = ProfileRepository();
  final cacheKey = '$_dashboardCacheKey:$uid';

  try {
    final results = await Future.wait([
      profileRepo.fetchName(uid),
      expensesRepo.fetchHome(uid),
      moneyRepo.fetchActiveSubscriptions(uid),
      moneyRepo.fetchLoans(uid),
      moneyRepo.fetchInvestments(uid),
      eventsRepo.fetchHome(uid),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final email = ref.read(authControllerProvider).user?.email;
    final metadata = ref.read(authControllerProvider).user?.userMetadata;
    String? firstName = profile?['first_name'] as String?;
    firstName ??= (profile?['display_name'] as String?)?.split(' ').firstOrNull;
    firstName ??= metadata?['given_name'] as String?;
    firstName ??= (metadata?['full_name'] as String?)?.split(' ').firstOrNull;
    firstName ??= email?.split('@').firstOrNull;

    final expenses = results[1] as List<Expense>;
    final subs = results[2] as List<SubscriptionRow>;
    final loans = results[3] as List<LoanRow>;
    final sips = results[4] as List<InvestmentRow>;
    final events = results[5] as List<PersonalEvent>;

    unawaited(OfflineCache.instance.put(cacheKey, {
      'firstName': firstName,
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'subs': subs.map((e) => e.toJson()).toList(),
      'loans': loans.map((e) => e.toJson()).toList(),
      'sips': sips.map((e) => e.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
    }));

    return _DashboardData(firstName: firstName, expenses: expenses, subs: subs, loans: loans, sips: sips, events: events);
  } catch (e) {
    final cached = OfflineCache.instance.get(cacheKey);
    if (cached == null) rethrow; // no offline fallback available — surface the real error
    final v = cached.value;
    return _DashboardData(
      firstName: v['firstName'] as String?,
      expenses: (v['expenses'] as List).map((r) => Expense.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
      subs: (v['subs'] as List).map((r) => SubscriptionRow.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
      loans: (v['loans'] as List).map((r) => LoanRow.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
      sips: (v['sips'] as List).map((r) => InvestmentRow.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
      events: (v['events'] as List).map((r) => PersonalEvent.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
    );
  }
});

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Direct port of src/routes/_app.dashboard.tsx.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _windowDays = 7;

  List<_Reminder> _buildReminders(_DashboardData d, String today) {
    final out = <_Reminder>[];
    for (final e in d.expenses) {
      final due = (e.isRecurring && e.dueDay != null) ? nextDueForDay(e.dueDay!, today) : e.expenseDate;
      out.add(_Reminder(
        id: 'exp-${e.id}',
        name: (e.subCategory?.isNotEmpty ?? false) ? e.subCategory! : (e.note?.isNotEmpty ?? false) ? e.note! : e.category,
        amount: e.amount,
        dueDate: due,
        mode: e.modeLabel,
        status: e.status == 'paid' ? 'Paid' : 'Balance',
      ));
    }
    for (final s in d.subs) {
      if (s.nextBillingDate == null) continue;
      out.add(_Reminder(id: 'sub-${s.id}', name: s.name, amount: s.amount, dueDate: s.nextBillingDate!, mode: s.billingCycle, status: 'Balance'));
    }
    for (final l in d.loans) {
      final due = l.nextDueDate ?? (l.dueDay != null ? nextDueForDay(l.dueDay!, today) : null);
      if (due == null) continue;
      out.add(_Reminder(id: 'loan-${l.id}', name: 'EMI · ${l.lender}', amount: l.emi, dueDate: due, mode: 'Loan', status: 'Balance'));
    }
    for (final s in d.sips) {
      if (s.sipDay == null) continue;
      out.add(_Reminder(id: 'sip-${s.id}', name: '${s.invType} · ${s.name}', amount: s.amount, dueDate: nextDueForDay(s.sipDay!, today), mode: 'SIP', status: 'Balance'));
    }
    return out;
  }

  /// Schedules local notifications (see core/notifications/reminder_scheduler.dart)
  /// for everything due in the next 30 days — independent of the on-screen
  /// "Next N days" picker, since a notification should fire whether or not
  /// the app is open. Runs entirely offline; no backend cron required.
  Future<void> _scheduleLocalReminders(_DashboardData d, String today) async {
    final all = _buildReminders(d, today);
    final end = addDaysIso(today, 30);
    final inputs = <ReminderInput>[
      for (final r in all)
        if (r.dueDate.compareTo(today) >= 0 && r.dueDate.compareTo(end) <= 0)
          ReminderInput(
            id: r.id,
            title: r.name,
            body: r.amount != null ? '${formatINR(r.amount)} · ${r.mode} · due ${formatDateIN(r.dueDate)}' : '${r.mode} · ${formatDateIN(r.dueDate)}',
            dueDate: DateTime.parse(r.dueDate),
          ),
      for (final e in d.events)
        if (e.eventDate != null && e.eventDate!.compareTo(today) >= 0 && e.eventDate!.compareTo(end) <= 0)
          ReminderInput(
            id: 'evt-${e.id}',
            title: '${e.personName} · ${e.eventType}',
            body: 'Personal event · ${formatDateIN(e.eventDate)}',
            dueDate: DateTime.parse(e.eventDate!),
          ),
    ];
    await ReminderScheduler.scheduleAll(inputs);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_dashboardProvider);
    final today = todayIsoIST();

    ref.listen(_dashboardProvider, (prev, next) {
      final data = next.valueOrNull;
      if (data != null) _scheduleLocalReminders(data, today);
    });

    return AppShell(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_dashboardProvider),
        child: async.when(
          loading: () => const Padding(padding: EdgeInsets.only(top: 60), child: FullLoadingQuote()),
          error: (e, st) => ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text('Failed to load: $e'))]),
          data: (d) => _buildContent(context, d, today),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, _DashboardData d, String today) {
    final colors = context.colors;
    final allReminders = _buildReminders(d, today);
    final todayItems = allReminders.where((r) => r.dueDate == today).toList()..sort((a, b) => a.name.compareTo(b.name));
    final todayEvents = d.events.where((e) => e.eventDate == today).toList();
    final end = addDaysIso(today, _windowDays);
    final upcoming = allReminders.where((r) => r.dueDate.compareTo(today) >= 0 && r.dueDate.compareTo(end) <= 0).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final buckets = <String, List<PersonalEvent>>{
      'Birthday': [], 'Anniversary': [], 'Wedding': [], 'Festival': [], 'Funeral / Punya': [], 'Religious': [],
    };
    for (final e in d.events) {
      if (e.eventDate == null) continue;
      if (e.eventDate!.compareTo(today) < 0 || e.eventDate!.compareTo(end) > 0) continue;
      final t = e.eventType.toLowerCase();
      var key = 'Religious';
      if (t.contains('birthday')) {
        key = 'Birthday';
      } else if (t.contains('wedding') && t.contains('anniv')) {
        key = 'Anniversary';
      } else if (t.contains('anniv')) {
        key = 'Anniversary';
      } else if (t.contains('wedding') || t.contains('engage')) {
        key = 'Wedding';
      } else if (t.contains('festival')) {
        key = 'Festival';
      } else if (t.contains('funeral') || t.contains('punya') || t.contains('death')) {
        key = 'Funeral / Punya';
      } else if (t.contains('religious') || t.contains('puja') || t.contains('temple')) {
        key = 'Religious';
      }
      buckets[key]!.add(e);
    }

    final firstName = d.firstName ?? 'there';

    return ListView(
      children: [
        Text(greetingForNow().toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: colors.mutedForeground)),
        const SizedBox(height: 2),
        Text('$firstName 👋', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),

        _SectionHeader(icon: Icons.watch_later_outlined, tint: context.colors.destructiveTint, tintFg: Theme.of(context).colorScheme.error, title: "Today's reminders", subtitle: 'Everything due today'),
        _ReminderList(
          rows: [
            ...todayItems,
            ...todayEvents.map((e) => _Reminder(id: 'evt-${e.id}', name: '${e.personName} · ${e.eventType}', amount: null, dueDate: e.eventDate ?? today, mode: 'Personal event', status: 'Event')),
          ],
          emptyText: 'Nothing due today. Enjoy the calm.',
          addType: 'expense',
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SectionHeader(icon: Icons.calendar_month_outlined, tint: colors.primaryTint, tintFg: Theme.of(context).colorScheme.primary, title: 'Upcoming expenses', subtitle: 'Bills, EMIs and SIPs due soon'),
            ),
            _WindowPicker(value: _windowDays, onChanged: (v) => setState(() => _windowDays = v)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
          child: Text('Filter applies to expenses & personal events below.', style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
        ),
        _ReminderList(rows: upcoming, emptyText: 'No expenses due in the next $_windowDays days.', addType: 'expense'),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => context.push('/expenses/new?type=expense'),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Expense'),
        ),
        const SizedBox(height: 24),

        _SectionHeader(icon: Icons.cake_outlined, tint: colors.accentTint, tintFg: const Color(0xFFF59E0B), title: 'Personal events', subtitle: 'Birthdays, anniversaries & more', trailing: _AddEventLink()),
        if (buckets.entries.where((e) => e.value.isNotEmpty).isEmpty)
          const _PersonalEventsEmptyState()
        else
          PaisaCardDivided(
            children: [
              for (final entry in buckets.entries)
                if (entry.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.mutedForeground, letterSpacing: 0.4)),
                        const SizedBox(height: 6),
                        for (final e in entry.value)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(e.personName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                Text(e.eventDate != null ? formatDateIN(e.eventDate) : 'Date not set', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
            ],
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.tint, required this.tintFg, required this.title, required this.subtitle, this.trailing});
  final IconData icon;
  final Color tint;
  final Color tintFg;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 16, color: tintFg)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Apple-style popup: solid white surface, black text, generous padding,
/// soft rounded corners and a real drop shadow — independent of app theme
/// (including dark mode), matching an iOS context-menu/action-sheet feel
/// rather than a stock Material dropdown.
class _WindowPicker extends StatelessWidget {
  const _WindowPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  static const _options = [2, 7, 10, 30];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<int>(
      initialValue: value,
      onSelected: onChanged,
      offset: const Offset(0, 40),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      constraints: const BoxConstraints(minWidth: 176),
      itemBuilder: (context) => [
        for (final d in _options)
          PopupMenuItem<int>(
            value: d,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next $d days',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: d == value ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (d == value) const Icon(Icons.check, size: 18, color: Colors.black),
              ],
            ),
          ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: colors.card, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Next $value days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _AddEventLink extends StatelessWidget {
  const _AddEventLink();
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.push('/expenses/new?type=event'),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Add event', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 28),
      ),
    );
  }
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({required this.rows, required this.emptyText, required this.addType});
  final List<_Reminder> rows;
  final String emptyText;
  final String addType;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return _EmptyRow(text: emptyText, addType: addType);
    return PaisaCardDivided(
      children: rows.map((r) {
        final colors = context.colors;
        Color badgeBg;
        Color badgeFg;
        if (r.status == 'Paid') {
          badgeBg = const Color(0xFFD1FAE5);
          badgeFg = const Color(0xFF047857);
        } else if (r.status == 'Event') {
          badgeBg = const Color(0xFFFCE7F3);
          badgeFg = const Color(0xFFBE185D);
        } else {
          badgeBg = const Color(0xFFFEF3C7);
          badgeFg = const Color(0xFFB45309);
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${formatDateIN(r.dueDate)} · ${r.mode}', style: TextStyle(fontSize: 13, color: colors.mutedForeground), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(r.amount == null ? '' : formatINR(r.amount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(r.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeFg, letterSpacing: 0.4)),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Redesigned Personal Events empty state: single card (was previously
/// double-nested inside PaisaCardDivided, which doubled the border/shadow
/// and produced the oversized whitespace), everything centered, natural
/// height, subtle tinted-blob illustration behind the icon, and "Add Event"
/// promoted to a primary filled CTA instead of a text link.
class _PersonalEventsEmptyState extends StatelessWidget {
  const _PersonalEventsEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PaisaCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [colors.accentTint, colors.accentTint.withValues(alpha: 0)]),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: colors.accentTint, shape: BoxShape.circle),
                  child: const Icon(Symbols.calendar_month_rounded, size: 26, color: Color(0xFFF59E0B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('No personal events yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'Keep track of birthdays, anniversaries\nand important dates.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.mutedForeground, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push('/expenses/new?type=event'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Event'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20)),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text, required this.addType});
  final String text;
  final String addType;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PaisaCard(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(text, style: TextStyle(color: colors.mutedForeground, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push('/expenses/new?type=$addType'),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add ${addType == 'event' ? 'event' : 'expense'}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
