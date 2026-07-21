// Smoke test for the Indian currency formatting helpers used throughout
// the app (dashboard, activity, calculators) — pure-Dart, no platform
// channels required, so it doesn't need Supabase/plugin bootstrapping.

import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/core/utils/format.dart';

void main() {
  test('formatINR formats whole rupees with the ₹ symbol', () {
    expect(formatINR(1000), '₹1,000');
  });

  test('formatINRCompact abbreviates lakh and crore', () {
    expect(formatINRCompact(150000), '₹1.5 Lakh');
    expect(formatINRCompact(12500000), '₹1.25 Crore');
  });

  test('formatDateIN renders DD/MM/YYYY', () {
    expect(formatDateIN('2026-03-05'), '05/03/2026');
  });
}
