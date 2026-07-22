import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// New in v2.1 — "Support" section of the restructured Settings screen.
/// The source app never had a support contact channel configured, so this
/// deliberately doesn't invent an email/phone number that would silently
/// go nowhere — it points at what's actually available today (the AI
/// Coach for financial questions) and is honest about the rest.
class SupportSheet extends StatelessWidget {
  const SupportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Support', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          Text('Get help with MoneyPilot.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).pop();
              context.go('/insights');
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colors.primaryTint.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(Icons.smart_toy_outlined, color: scheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ask the AI Coach', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: scheme.primary)),
                      Text('Budgeting, EMIs, SIPs, tax and savings questions — answered instantly in Money Lab.', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.primary),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Common questions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          const _FaqItem(
            q: 'How do reminders work?',
            a: 'Set "Remind before N days" on any expense or event, and MoneyPilot schedules a local notification at 9:00 AM on the right day — no internet needed for that part.',
          ),
          const _FaqItem(
            q: "What happens if I'm offline?",
            a: "You can still add expenses and events. They're queued on your device and sync automatically the moment you're back online.",
          ),
          const _FaqItem(
            q: 'Is my data private?',
            a: 'Yes — every table is protected by row-level security, so only your signed-in account can ever read your data.',
          ),
          const SizedBox(height: 20),
          Text(
            'A dedicated support inbox isn\'t set up yet for this deployment — for account-specific issues, reach out to whoever manages your MoneyPilot workspace.',
            style: TextStyle(fontSize: 13, color: colors.mutedForeground, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          const SizedBox(height: 2),
          Text(a, style: TextStyle(fontSize: 13, color: colors.mutedForeground, height: 1.4)),
        ],
      ),
    );
  }
}
