import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/format.dart';
import 'calc_widgets.dart';

/// Direct port of src/components/Calculators.tsx — 21 calculators, identical
/// formulas to the React originals.

class SipCalculator extends StatefulWidget {
  const SipCalculator({super.key});
  @override
  State<SipCalculator> createState() => _SipCalculatorState();
}

class _SipCalculatorState extends State<SipCalculator> {
  double monthly = 5000, years = 10, rate = 12;
  @override
  Widget build(BuildContext context) {
    final n = years * 12, r = rate / 100 / 12;
    final future = monthly * (((math.pow(1 + r, n) - 1) / r) * (1 + r));
    final invested = monthly * n;
    final gain = future - invested;
    return CalcShell(icon: Icons.trending_up, title: 'SIP Calculator', subtitle: 'Project mutual fund SIP growth', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Monthly', value: monthly, suffix: '₹', min: 500, max: 500000, onChanged: (v) => setState(() => monthly = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 40, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Returns', value: rate, suffix: '%', min: 1, max: 30, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(columns: 3, children: [
        CalcResult(label: 'Invested', value: formatINRCompact(invested), primary: false),
        CalcResult(label: 'Gain', value: formatINRCompact(gain), primary: false),
        CalcResult(label: 'Future', value: formatINRCompact(future)),
      ]),
    ]);
  }
}

class StepUpSipCalculator extends StatefulWidget {
  const StepUpSipCalculator({super.key});
  @override
  State<StepUpSipCalculator> createState() => _StepUpSipCalculatorState();
}

class _StepUpSipCalculatorState extends State<StepUpSipCalculator> {
  double monthly = 5000, stepUp = 10, years = 15, rate = 12;
  @override
  Widget build(BuildContext context) {
    double fv = 0, inv = 0, m = monthly;
    final r = rate / 100 / 12;
    for (var y = 0; y < years; y++) {
      for (var mo = 0; mo < 12; mo++) {
        fv = (fv + m) * (1 + r);
        inv += m;
      }
      m *= 1 + stepUp / 100;
    }
    return CalcShell(icon: Icons.trending_up, title: 'Step-up SIP', subtitle: 'SIP with yearly contribution increase', children: [
      CalcGrid(children: [
        NumField(label: 'Start ₹/mo', value: monthly, suffix: '₹', min: 500, max: 500000, onChanged: (v) => setState(() => monthly = v)),
        NumField(label: 'Step-up', value: stepUp, suffix: '%', min: 0, max: 50, onChanged: (v) => setState(() => stepUp = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 40, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Returns', value: rate, suffix: '%', min: 1, max: 30, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Invested', value: formatINRCompact(inv), primary: false),
        CalcResult(label: 'Future', value: formatINRCompact(fv)),
      ]),
    ]);
  }
}

class SwpCalculator extends StatefulWidget {
  const SwpCalculator({super.key});
  @override
  State<SwpCalculator> createState() => _SwpCalculatorState();
}

class _SwpCalculatorState extends State<SwpCalculator> {
  double corpus = 2500000, withdraw = 20000, rate = 8, years = 15;
  @override
  Widget build(BuildContext context) {
    var bal = corpus;
    final r = rate / 100 / 12;
    for (var i = 0; i < years * 12 && bal > 0; i++) {
      bal = bal * (1 + r) - withdraw;
    }
    final remaining = math.max(0, bal);
    return CalcShell(icon: Icons.account_balance_wallet_outlined, title: 'SWP Calculator', subtitle: 'Systematic withdrawal plan', children: [
      CalcGrid(children: [
        NumField(label: 'Corpus', value: corpus, suffix: '₹', min: 10000, max: 100000000, onChanged: (v) => setState(() => corpus = v)),
        NumField(label: 'Withdraw/mo', value: withdraw, suffix: '₹', min: 500, max: 1000000, onChanged: (v) => setState(() => withdraw = v)),
        NumField(label: 'Returns', value: rate, suffix: '%', min: 1, max: 20, onChanged: (v) => setState(() => rate = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 40, onChanged: (v) => setState(() => years = v)),
      ]),
      const SizedBox(height: 10),
      CalcResult(label: 'Corpus after period', value: formatINRCompact(remaining)),
    ]);
  }
}

class CagrCalculator extends StatefulWidget {
  const CagrCalculator({super.key});
  @override
  State<CagrCalculator> createState() => _CagrCalculatorState();
}

class _CagrCalculatorState extends State<CagrCalculator> {
  double start = 100000, end = 250000, years = 5;
  @override
  Widget build(BuildContext context) {
    final cagr = (start <= 0 || years <= 0) ? 0.0 : (math.pow(end / start, 1 / years) - 1) * 100;
    return CalcShell(icon: Icons.show_chart, title: 'CAGR', subtitle: 'Compound Annual Growth Rate', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Initial', value: start, suffix: '₹', min: 1000, max: 100000000, onChanged: (v) => setState(() => start = v)),
        NumField(label: 'Final', value: end, suffix: '₹', min: 1000, max: 100000000, onChanged: (v) => setState(() => end = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 50, onChanged: (v) => setState(() => years = v)),
      ]),
      const SizedBox(height: 10),
      CalcResult(label: 'CAGR', value: '${cagr.toStringAsFixed(2)}%'),
    ]);
  }
}

class EmiCalculator extends StatefulWidget {
  const EmiCalculator({super.key});
  @override
  State<EmiCalculator> createState() => _EmiCalculatorState();
}

class _EmiCalculatorState extends State<EmiCalculator> {
  double principal = 500000, years = 5, rate = 10;
  @override
  Widget build(BuildContext context) {
    final n = years * 12, r = rate / 100 / 12;
    final emi = (principal * r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
    final total = emi * n;
    final interest = total - principal;
    return CalcShell(icon: Icons.account_balance_outlined, title: 'EMI Calculator', subtitle: 'Loan EMI and total interest', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Loan', value: principal, suffix: '₹', min: 10000, max: 50000000, onChanged: (v) => setState(() => principal = v)),
        NumField(label: 'Tenure', value: years, suffix: 'y', min: 1, max: 30, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Rate', value: rate, suffix: '%', min: 1, max: 30, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(columns: 3, children: [
        CalcResult(label: 'EMI', value: formatINRCompact(emi)),
        CalcResult(label: 'Interest', value: formatINRCompact(interest), primary: false),
        CalcResult(label: 'Total', value: formatINRCompact(total), primary: false),
      ]),
    ]);
  }
}

class CompoundCalculator extends StatefulWidget {
  const CompoundCalculator({super.key});
  @override
  State<CompoundCalculator> createState() => _CompoundCalculatorState();
}

class _CompoundCalculatorState extends State<CompoundCalculator> {
  double principal = 100000, years = 10, rate = 8;
  @override
  Widget build(BuildContext context) {
    final future = principal * math.pow(1 + rate / 100, years);
    final gain = future - principal;
    return CalcShell(icon: Icons.savings_outlined, title: 'Compound Interest', subtitle: 'See your lump sum grow', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Principal', value: principal, suffix: '₹', min: 1000, max: 50000000, onChanged: (v) => setState(() => principal = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 40, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Rate', value: rate, suffix: '%', min: 1, max: 30, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Gain', value: formatINRCompact(gain), primary: false),
        CalcResult(label: 'Maturity', value: formatINRCompact(future)),
      ]),
    ]);
  }
}

class SimpleInterestCalculator extends StatefulWidget {
  const SimpleInterestCalculator({super.key});
  @override
  State<SimpleInterestCalculator> createState() => _SimpleInterestCalculatorState();
}

class _SimpleInterestCalculatorState extends State<SimpleInterestCalculator> {
  double principal = 100000, years = 5, rate = 7;
  @override
  Widget build(BuildContext context) {
    final interest = (principal * rate * years) / 100;
    return CalcShell(icon: Icons.monetization_on_outlined, title: 'Simple Interest', subtitle: 'P × R × T / 100', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Principal', value: principal, suffix: '₹', min: 1000, max: 50000000, onChanged: (v) => setState(() => principal = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 40, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Rate', value: rate, suffix: '%', min: 1, max: 30, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Interest', value: formatINRCompact(interest), primary: false),
        CalcResult(label: 'Total', value: formatINRCompact(principal + interest)),
      ]),
    ]);
  }
}

class FdCalculator extends StatefulWidget {
  const FdCalculator({super.key});
  @override
  State<FdCalculator> createState() => _FdCalculatorState();
}

class _FdCalculatorState extends State<FdCalculator> {
  double principal = 100000, years = 5, rate = 7;
  @override
  Widget build(BuildContext context) {
    final future = principal * math.pow(1 + rate / 400, 4 * years);
    return CalcShell(icon: Icons.account_balance_outlined, title: 'Fixed Deposit', subtitle: 'Quarterly compounding (bank standard)', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Deposit', value: principal, suffix: '₹', min: 1000, max: 50000000, onChanged: (v) => setState(() => principal = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 20, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Rate', value: rate, suffix: '%', min: 1, max: 15, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Interest', value: formatINRCompact(future - principal), primary: false),
        CalcResult(label: 'Maturity', value: formatINRCompact(future)),
      ]),
    ]);
  }
}

class RdCalculator extends StatefulWidget {
  const RdCalculator({super.key});
  @override
  State<RdCalculator> createState() => _RdCalculatorState();
}

class _RdCalculatorState extends State<RdCalculator> {
  double monthly = 5000, years = 5, rate = 6.5;
  @override
  Widget build(BuildContext context) {
    final n = years * 12, i = rate / 400;
    final fv = monthly * (math.pow(1 + i, n / 3) - 1) / (1 - math.pow(1 + i, -1 / 3));
    final invested = monthly * n;
    return CalcShell(icon: Icons.repeat, title: 'Recurring Deposit', subtitle: 'Monthly RD maturity', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Monthly', value: monthly, suffix: '₹', min: 100, max: 500000, onChanged: (v) => setState(() => monthly = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 10, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Rate', value: rate, suffix: '%', min: 1, max: 15, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Invested', value: formatINRCompact(invested), primary: false),
        CalcResult(label: 'Maturity', value: formatINRCompact(fv)),
      ]),
    ]);
  }
}

class PpfCalculator extends StatefulWidget {
  const PpfCalculator({super.key});
  @override
  State<PpfCalculator> createState() => _PpfCalculatorState();
}

class _PpfCalculatorState extends State<PpfCalculator> {
  double yearly = 150000, years = 15;
  static const rate = 7.1;
  @override
  Widget build(BuildContext context) {
    var bal = 0.0;
    for (var i = 0; i < years; i++) {
      bal = (bal + yearly) * (1 + rate / 100);
    }
    return CalcShell(icon: Icons.verified_user_outlined, title: 'PPF', subtitle: 'Public Provident Fund · 7.1% p.a.', children: [
      CalcGrid(children: [
        NumField(label: 'Yearly', value: yearly, suffix: '₹', min: 500, max: 150000, onChanged: (v) => setState(() => yearly = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 15, max: 50, onChanged: (v) => setState(() => years = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Invested', value: formatINRCompact(yearly * years), primary: false),
        CalcResult(label: 'Maturity', value: formatINRCompact(bal)),
      ]),
    ]);
  }
}

class NscCalculator extends StatefulWidget {
  const NscCalculator({super.key});
  @override
  State<NscCalculator> createState() => _NscCalculatorState();
}

class _NscCalculatorState extends State<NscCalculator> {
  double principal = 100000;
  static const rate = 7.7, years = 5.0;
  @override
  Widget build(BuildContext context) {
    final future = principal * math.pow(1 + rate / 100, years);
    return CalcShell(icon: Icons.receipt_long_outlined, title: 'NSC', subtitle: 'National Savings Certificate · 7.7% · 5y', children: [
      NumField(label: 'Investment', value: principal, suffix: '₹', min: 1000, max: 5000000, onChanged: (v) => setState(() => principal = v)),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Interest', value: formatINRCompact(future - principal), primary: false),
        CalcResult(label: 'Maturity', value: formatINRCompact(future)),
      ]),
    ]);
  }
}

class EpfCalculator extends StatefulWidget {
  const EpfCalculator({super.key});
  @override
  State<EpfCalculator> createState() => _EpfCalculatorState();
}

class _EpfCalculatorState extends State<EpfCalculator> {
  double basic = 30000, years = 25, growth = 5;
  static const rate = 8.25;
  @override
  Widget build(BuildContext context) {
    var bal = 0.0, b = basic;
    final r = rate / 100 / 12;
    for (var y = 0; y < years; y++) {
      final monthlyContribution = b * 0.24;
      for (var m = 0; m < 12; m++) {
        bal = (bal + monthlyContribution) * (1 + r);
      }
      b *= 1 + growth / 100;
    }
    return CalcShell(icon: Icons.work_outline, title: 'EPF', subtitle: 'Employee Provident Fund · 8.25% p.a.', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Basic ₹/mo', value: basic, suffix: '₹', min: 5000, max: 500000, onChanged: (v) => setState(() => basic = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 40, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Salary ↑', value: growth, suffix: '%', min: 0, max: 20, onChanged: (v) => setState(() => growth = v)),
      ]),
      const SizedBox(height: 10),
      CalcResult(label: 'Retirement corpus', value: formatINRCompact(bal)),
    ]);
  }
}

class NpsCalculator extends StatefulWidget {
  const NpsCalculator({super.key});
  @override
  State<NpsCalculator> createState() => _NpsCalculatorState();
}

class _NpsCalculatorState extends State<NpsCalculator> {
  double monthly = 5000, years = 25, rate = 10;
  @override
  Widget build(BuildContext context) {
    final n = years * 12, r = rate / 100 / 12;
    final corpus = monthly * (((math.pow(1 + r, n) - 1) / r) * (1 + r));
    final lumpsum = corpus * 0.6;
    final annuityCorpus = corpus * 0.4;
    final monthlyPension = (annuityCorpus * 0.06) / 12;
    return CalcShell(icon: Icons.business_outlined, title: 'NPS', subtitle: 'National Pension System', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Monthly', value: monthly, suffix: '₹', min: 500, max: 200000, onChanged: (v) => setState(() => monthly = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 40, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Returns', value: rate, suffix: '%', min: 4, max: 15, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(columns: 3, children: [
        CalcResult(label: 'Corpus', value: formatINRCompact(corpus)),
        CalcResult(label: '60% Lumpsum', value: formatINRCompact(lumpsum), primary: false),
        CalcResult(label: 'Pension/mo', value: formatINRCompact(monthlyPension), primary: false),
      ]),
    ]);
  }
}

class ApyCalculator extends StatefulWidget {
  const ApyCalculator({super.key});
  @override
  State<ApyCalculator> createState() => _ApyCalculatorState();
}

class _ApyCalculatorState extends State<ApyCalculator> {
  double pension = 5000, age = 25;
  static const table = {1000: 42.0, 2000: 84.0, 3000: 126.0, 4000: 168.0, 5000: 210.0};
  @override
  Widget build(BuildContext context) {
    final base = table[pension.toInt()] ?? 210.0;
    final factor = math.max(1, (40 - age) / 18);
    final contrib = base / factor;
    return CalcShell(icon: Icons.beach_access_outlined, title: 'APY', subtitle: 'Atal Pension Yojana', children: [
      CalcGrid(children: [
        NumField(label: 'Pension/mo', value: pension, suffix: '₹', min: 1000, max: 5000, onChanged: (v) => setState(() => pension = v)),
        NumField(label: 'Your age', value: age, suffix: 'y', min: 18, max: 39, onChanged: (v) => setState(() => age = v)),
      ]),
      const SizedBox(height: 10),
      CalcResult(label: 'Approx contribution / month', value: formatINRCompact(contrib)),
    ]);
  }
}

class GratuityCalculator extends StatefulWidget {
  const GratuityCalculator({super.key});
  @override
  State<GratuityCalculator> createState() => _GratuityCalculatorState();
}

class _GratuityCalculatorState extends State<GratuityCalculator> {
  double salary = 50000, years = 10;
  @override
  Widget build(BuildContext context) {
    final gratuity = (salary * 15 * years) / 26;
    return CalcShell(icon: Icons.percent, title: 'Gratuity', subtitle: '(Last basic × 15 × years) / 26', children: [
      CalcGrid(children: [
        NumField(label: 'Last basic', value: salary, suffix: '₹', min: 5000, max: 500000, onChanged: (v) => setState(() => salary = v)),
        NumField(label: 'Years served', value: years, suffix: 'y', min: 5, max: 40, onChanged: (v) => setState(() => years = v)),
      ]),
      const SizedBox(height: 10),
      CalcResult(label: 'Gratuity', value: formatINRCompact(gratuity)),
    ]);
  }
}

class SsyCalculator extends StatefulWidget {
  const SsyCalculator({super.key});
  @override
  State<SsyCalculator> createState() => _SsyCalculatorState();
}

class _SsyCalculatorState extends State<SsyCalculator> {
  double yearly = 50000;
  static const rate = 8.2;
  @override
  Widget build(BuildContext context) {
    var bal = 0.0;
    for (var i = 0; i < 15; i++) {
      bal = (bal + yearly) * (1 + rate / 100);
    }
    for (var i = 0; i < 6; i++) {
      bal *= 1 + rate / 100;
    }
    return CalcShell(icon: Icons.school_outlined, title: 'SSY', subtitle: 'Sukanya Samriddhi Yojana · 8.2%', children: [
      NumField(label: 'Yearly', value: yearly, suffix: '₹', min: 250, max: 150000, onChanged: (v) => setState(() => yearly = v)),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Invested', value: formatINRCompact(yearly * 15), primary: false),
        CalcResult(label: 'Maturity (21y)', value: formatINRCompact(bal)),
      ]),
    ]);
  }
}

class ElssCalculator extends StatefulWidget {
  const ElssCalculator({super.key});
  @override
  State<ElssCalculator> createState() => _ElssCalculatorState();
}

class _ElssCalculatorState extends State<ElssCalculator> {
  double monthly = 12500, years = 5, rate = 12;
  @override
  Widget build(BuildContext context) {
    final n = years * 12, r = rate / 100 / 12;
    final fv = monthly * (((math.pow(1 + r, n) - 1) / r) * (1 + r));
    final invested = monthly * n;
    final taxSaved = math.min(invested, 150000) * 0.3;
    return CalcShell(icon: Icons.calculate_outlined, title: 'ELSS', subtitle: 'Tax-saving mutual fund · 3-year lock-in', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Monthly', value: monthly, suffix: '₹', min: 500, max: 50000, onChanged: (v) => setState(() => monthly = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 3, max: 30, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Returns', value: rate, suffix: '%', min: 5, max: 25, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(columns: 3, children: [
        CalcResult(label: 'Future', value: formatINRCompact(fv)),
        CalcResult(label: 'Invested', value: formatINRCompact(invested), primary: false),
        CalcResult(label: 'Tax saved', value: formatINRCompact(taxSaved), primary: false),
      ]),
    ]);
  }
}

class RetirementCalculator extends StatefulWidget {
  const RetirementCalculator({super.key});
  @override
  State<RetirementCalculator> createState() => _RetirementCalculatorState();
}

class _RetirementCalculatorState extends State<RetirementCalculator> {
  double age = 30, retire = 60, expense = 40000, infl = 6, postReturn = 7;
  @override
  Widget build(BuildContext context) {
    final years = math.max(1, retire - age);
    final futureExpense = expense * math.pow(1 + infl / 100, years);
    final yearly = futureExpense * 12;
    final corpus = yearly *
        ((1 - math.pow(1 + infl / 100, 25) / math.pow(1 + postReturn / 100, 25)) / ((postReturn - infl) / 100));
    return CalcShell(icon: Icons.calendar_today_outlined, title: 'Retirement', subtitle: 'Corpus needed at retirement', children: [
      CalcGrid(columns: 3, children: [
        NumField(label: 'Current age', value: age, suffix: 'y', min: 18, max: 65, onChanged: (v) => setState(() => age = v)),
        NumField(label: 'Retire at', value: retire, suffix: 'y', min: 40, max: 75, onChanged: (v) => setState(() => retire = v)),
        NumField(label: 'Exp ₹/mo', value: expense, suffix: '₹', min: 5000, max: 1000000, onChanged: (v) => setState(() => expense = v)),
        NumField(label: 'Inflation', value: infl, suffix: '%', min: 2, max: 12, onChanged: (v) => setState(() => infl = v)),
        NumField(label: 'Post return', value: postReturn, suffix: '%', min: 3, max: 15, onChanged: (v) => setState(() => postReturn = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Future ₹/mo', value: formatINRCompact(futureExpense), primary: false),
        CalcResult(label: 'Corpus needed', value: formatINRCompact(math.max(0, corpus))),
      ]),
    ]);
  }
}

class IncomeTaxCalculator extends StatefulWidget {
  const IncomeTaxCalculator({super.key});
  @override
  State<IncomeTaxCalculator> createState() => _IncomeTaxCalculatorState();
}

class _IncomeTaxCalculatorState extends State<IncomeTaxCalculator> {
  double income = 1200000;
  @override
  Widget build(BuildContext context) {
    final slabs = <List<double>>[
      [300000, 0], [700000, 0.05], [1000000, 0.10], [1200000, 0.15], [1500000, 0.20], [double.infinity, 0.30],
    ];
    double t = 0, prev = 0;
    for (final slab in slabs) {
      final limit = slab[0], rate = slab[1];
      if (income > prev) t += (math.min(income, limit) - prev) * rate;
      prev = limit;
      if (income <= limit) break;
    }
    if (income <= 700000) t = 0;
    final tax = t * 1.04;
    return CalcShell(icon: Icons.receipt_long_outlined, title: 'Income Tax', subtitle: 'New regime FY 2024-25 (approx)', children: [
      NumField(label: 'Annual income', value: income, suffix: '₹', min: 100000, max: 50000000, onChanged: (v) => setState(() => income = v)),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Tax', value: formatINRCompact(tax)),
        CalcResult(label: 'Take-home', value: formatINRCompact(income - tax), primary: false),
      ]),
    ]);
  }
}

class InflationCalculator extends StatefulWidget {
  const InflationCalculator({super.key});
  @override
  State<InflationCalculator> createState() => _InflationCalculatorState();
}

class _InflationCalculatorState extends State<InflationCalculator> {
  double amount = 100000, years = 10, rate = 6;
  @override
  Widget build(BuildContext context) {
    final future = amount * math.pow(1 + rate / 100, years);
    final purchasing = amount / math.pow(1 + rate / 100, years);
    return CalcShell(icon: Icons.trending_up, title: 'Inflation', subtitle: "Future cost & lost purchasing power", children: [
      CalcGrid(columns: 3, children: [
        NumField(label: "Today's ₹", value: amount, suffix: '₹', min: 1000, max: 50000000, onChanged: (v) => setState(() => amount = v)),
        NumField(label: 'Years', value: years, suffix: 'y', min: 1, max: 40, onChanged: (v) => setState(() => years = v)),
        NumField(label: 'Inflation', value: rate, suffix: '%', min: 1, max: 15, onChanged: (v) => setState(() => rate = v)),
      ]),
      const SizedBox(height: 10),
      CalcGrid(children: [
        CalcResult(label: 'Future cost', value: formatINRCompact(future)),
        CalcResult(label: "Today's value of ₹", value: formatINRCompact(purchasing), primary: false),
      ]),
    ]);
  }
}

class HraCalculator extends StatefulWidget {
  const HraCalculator({super.key});
  @override
  State<HraCalculator> createState() => _HraCalculatorState();
}

class _HraCalculatorState extends State<HraCalculator> {
  double basic = 40000, hra = 20000, rent = 18000, metro = 1;
  @override
  Widget build(BuildContext context) {
    final exempt = [hra, rent - basic * 0.1, basic * (metro != 0 ? 0.5 : 0.4)].reduce(math.min);
    return CalcShell(icon: Icons.home_outlined, title: 'HRA Exemption', subtitle: 'House Rent Allowance · monthly', children: [
      CalcGrid(children: [
        NumField(label: 'Basic', value: basic, suffix: '₹', min: 5000, max: 500000, onChanged: (v) => setState(() => basic = v)),
        NumField(label: 'HRA received', value: hra, suffix: '₹', min: 0, max: 500000, onChanged: (v) => setState(() => hra = v)),
        NumField(label: 'Rent paid', value: rent, suffix: '₹', min: 0, max: 500000, onChanged: (v) => setState(() => rent = v)),
        NumField(label: 'Metro (1/0)', value: metro, min: 0, max: 1, onChanged: (v) => setState(() => metro = v)),
      ]),
      const SizedBox(height: 10),
      CalcResult(label: 'Exempt HRA / month', value: formatINRCompact(math.max(0, exempt))),
    ]);
  }
}
