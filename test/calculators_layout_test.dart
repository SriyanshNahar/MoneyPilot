// Verifies every Money Lab calculator lays out without a RenderFlex
// overflow (or any other layout exception) across a spread of screen
// widths — small phone, medium phone, and tablet — standing in for the
// "Responsive Validation" pass from the v2.3 UI polish request. Pure
// widget-tree rendering, no Supabase/platform channels involved, so it
// runs everywhere flutter test does.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/core/theme/app_theme.dart';
import 'package:moneypilot/features/money_lab/calculators.dart';

const _widthsToCheck = <String, double>{
  'small phone (320w)': 320,
  'medium phone (400w)': 400,
  'tablet (900w)': 900,
};

final _calculators = <String, WidgetBuilder>{
  'SIP': (_) => const SipCalculator(),
  'Step-up SIP': (_) => const StepUpSipCalculator(),
  'SWP': (_) => const SwpCalculator(),
  'CAGR': (_) => const CagrCalculator(),
  'EMI': (_) => const EmiCalculator(),
  'Compound Interest': (_) => const CompoundCalculator(),
  'Simple Interest': (_) => const SimpleInterestCalculator(),
  'FD': (_) => const FdCalculator(),
  'RD': (_) => const RdCalculator(),
  'PPF': (_) => const PpfCalculator(),
  'NSC': (_) => const NscCalculator(),
  'EPF': (_) => const EpfCalculator(),
  'NPS': (_) => const NpsCalculator(),
  'APY': (_) => const ApyCalculator(),
  'Gratuity': (_) => const GratuityCalculator(),
  'SSY': (_) => const SsyCalculator(),
  'ELSS': (_) => const ElssCalculator(),
  'Retirement': (_) => const RetirementCalculator(),
  'Income Tax': (_) => const IncomeTaxCalculator(),
  'Inflation': (_) => const InflationCalculator(),
  'HRA': (_) => const HraCalculator(),
};

void main() {
  for (final calcEntry in _calculators.entries) {
    for (final widthEntry in _widthsToCheck.entries) {
      testWidgets('${calcEntry.key} calculator has no layout overflow at ${widthEntry.key}', (tester) async {
        tester.view.physicalSize = Size(widthEntry.value, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Builder(builder: calcEntry.value),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: '${calcEntry.key} overflowed at ${widthEntry.key}');
      });
    }
  }
}
