import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/paisa_card.dart';
import '../shell/app_shell.dart';
import 'ai_coach_chat.dart';
import 'calculators.dart';

class _CalcItem {
  const _CalcItem(this.key, this.label, this.builder);
  final String key;
  final String label;
  final WidgetBuilder builder;
}

class _CalcGroup {
  const _CalcGroup(this.title, this.items);
  final String title;
  final List<_CalcItem> items;
}

final _calcGroups = <_CalcGroup>[
  _CalcGroup('Investments', [
    _CalcItem('sip', 'SIP', (_) => const SipCalculator()),
    _CalcItem('stepup', 'Step-up SIP', (_) => const StepUpSipCalculator()),
    _CalcItem('swp', 'SWP', (_) => const SwpCalculator()),
    _CalcItem('cagr', 'CAGR', (_) => const CagrCalculator()),
    _CalcItem('elss', 'ELSS', (_) => const ElssCalculator()),
    _CalcItem('retire', 'Retirement', (_) => const RetirementCalculator()),
  ]),
  _CalcGroup('Savings', [
    _CalcItem('ppf', 'PPF', (_) => const PpfCalculator()),
    _CalcItem('nsc', 'NSC', (_) => const NscCalculator()),
    _CalcItem('epf', 'EPF', (_) => const EpfCalculator()),
    _CalcItem('nps', 'NPS', (_) => const NpsCalculator()),
    _CalcItem('apy', 'APY', (_) => const ApyCalculator()),
    _CalcItem('gratuity', 'Gratuity', (_) => const GratuityCalculator()),
    _CalcItem('fd', 'Fixed Deposit', (_) => const FdCalculator()),
    _CalcItem('rd', 'Recurring', (_) => const RdCalculator()),
    _CalcItem('ci', 'Compound', (_) => const CompoundCalculator()),
    _CalcItem('si', 'Simple Int.', (_) => const SimpleInterestCalculator()),
    _CalcItem('ssy', 'SSY', (_) => const SsyCalculator()),
  ]),
  _CalcGroup('Loans & Tax', [
    _CalcItem('emi', 'EMI', (_) => const EmiCalculator()),
    _CalcItem('tax', 'Income Tax', (_) => const IncomeTaxCalculator()),
    _CalcItem('infl', 'Inflation', (_) => const InflationCalculator()),
    _CalcItem('hra', 'HRA', (_) => const HraCalculator()),
  ]),
];

/// Direct port of src/routes/_app.insights.tsx.
class MoneyLabScreen extends StatefulWidget {
  const MoneyLabScreen({super.key});
  @override
  State<MoneyLabScreen> createState() => _MoneyLabScreenState();
}

class _MoneyLabScreenState extends State<MoneyLabScreen> {
  String _activeCalc = 'sip';
  bool _expertOpen = false;

  WidgetBuilder get _activeBuilder {
    for (final g in _calcGroups) {
      for (final c in g.items) {
        if (c.key == _activeCalc) return c.builder;
      }
    }
    return (_) => const SipCalculator();
  }

  int get _totalCalcCount => _calcGroups.fold(0, (s, g) => s + g.items.length);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return AppShell(
      child: ListView(
        children: [
          Text('Money Lab', style: Theme.of(context).textTheme.headlineMedium),
          Text('Calculators, AI coach and expert guidance in one place.', style: TextStyle(fontSize: 15, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.gradientStart, colors.gradientEnd]), borderRadius: BorderRadius.circular(22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Featured', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
                const SizedBox(height: 10),
                const Text('What makes your money grow?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Pick a calculator below or chat with the AI Coach for personalised tips.', style: TextStyle(fontSize: 15, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Icon(Icons.calculate_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 6),
            Text('Calculators · $_totalCalcCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          PaisaCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final g in _calcGroups)
                    ExpansionTile(
                      initiallyExpanded: g.items.any((c) => c.key == _activeCalc),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: EdgeInsets.zero,
                      title: Text(
                        g.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      children: [
                        for (final c in g.items)
                          ListTile(
                            selected: c.key == _activeCalc,
                            selectedTileColor: colors.primaryTint.withValues(alpha: 0.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                            visualDensity: const VisualDensity(vertical: 1),
                            title: Text(
                              c.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: c.key == _activeCalc ? scheme.primary : null,
                              ),
                            ),
                            trailing: c.key == _activeCalc ? Icon(Icons.check_circle, size: 20, color: scheme.primary) : null,
                            onTap: () => setState(() => _activeCalc = c.key),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Builder(builder: _activeBuilder),
          const SizedBox(height: 16),
          PaisaCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: colors.primaryTint, child: Icon(Icons.smart_toy_outlined, size: 18, color: scheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MoneyPilot Coach · AI', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                        Text('Save more, spend smarter. Educational tips only.', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                const AiCoachChat(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PaisaCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Icons.school_outlined, size: 22, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Text('Ask an Expert', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text('Tap to reveal a verified expert recommendation from the MoneyPilot team.', style: TextStyle(fontSize: 15, color: colors.mutedForeground)),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: !_expertOpen
                      ? SizedBox(
                          key: const ValueKey('cta'),
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.gradientStart, colors.gradientEnd]), borderRadius: BorderRadius.circular(18)),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => setState(() => _expertOpen = true),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Show expert recommendation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                          SizedBox(height: 2),
                                          Text('Verified Chartered Accountant + CFA', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                                      child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          key: const ValueKey('card'),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.primary.withValues(alpha: 0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primaryTint, colors.accentTint])),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('FIRM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary, letterSpacing: 0.4)),
                                    const Text('7Sapience Financial Advisory', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const _ExpertRow(name: 'CA Varsha Nahar', credentials: 'Chartered Accountant (CA)'),
                                    const SizedBox(height: 10),
                                    const _ExpertRow(name: 'Jitendra Nahar, CFA', credentials: 'Chartered Financial Analyst (CFA)'),
                                    const SizedBox(height: 10),
                                    Text('SPECIALIZATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.mutedForeground, letterSpacing: 0.4)),
                                    const Text('Personal Finance · Investments · Tax Planning', style: TextStyle(fontSize: 15)),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                                      child: const Row(children: [
                                        Icon(Icons.info_outline, size: 18, color: Color(0xFF92400E)),
                                        SizedBox(width: 8),
                                        Expanded(child: Text('Search "7Sapience" on LinkedIn or Google to connect.', style: TextStyle(fontSize: 14, color: Color(0xFF92400E)))),
                                      ]),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                      onPressed: () => _showReachOutSheet(context),
                                      child: const Text('How to reach out'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showReachOutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final colors = ctx.colors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How to reach out', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              Text('Verified search guidance', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.primaryTint.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14)),
                child: const Text('Search "7Sapience" on LinkedIn or Google to connect.', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpertRow extends StatelessWidget {
  const _ExpertRow({required this.name, required this.credentials});
  final String name;
  final String credentials;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      CircleAvatar(radius: 20, backgroundColor: colors.primaryTint, child: Text(name[0], style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary))),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              Icon(Icons.verified, size: 16, color: scheme.primary),
            ]),
            Text(credentials, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
          ],
        ),
      ),
    ]);
  }
}
