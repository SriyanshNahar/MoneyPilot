// Mirrors the `subscriptions`, `loans`, `investments` tables.

class SubscriptionRow {
  const SubscriptionRow({
    required this.id,
    required this.name,
    required this.amount,
    this.nextBillingDate,
    required this.billingCycle,
  });

  final String id;
  final String name;
  final double amount;
  final String? nextBillingDate;
  final String billingCycle;

  factory SubscriptionRow.fromJson(Map<String, dynamic> j) => SubscriptionRow(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        nextBillingDate: j['next_billing_date'] as String?,
        billingCycle: (j['billing_cycle'] as String?) ?? 'monthly',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'next_billing_date': nextBillingDate,
        'billing_cycle': billingCycle,
      };
}

class LoanRow {
  const LoanRow({
    required this.id,
    required this.lender,
    required this.emi,
    this.dueDay,
    this.nextDueDate,
  });

  final String id;
  final String lender;
  final double emi;
  final int? dueDay;
  final String? nextDueDate;

  factory LoanRow.fromJson(Map<String, dynamic> j) => LoanRow(
        id: j['id'] as String,
        lender: j['lender'] as String,
        emi: (j['emi'] as num).toDouble(),
        dueDay: (j['due_day'] as num?)?.toInt(),
        nextDueDate: j['next_due_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lender': lender,
        'emi': emi,
        'due_day': dueDay,
        'next_due_date': nextDueDate,
      };
}

class InvestmentRow {
  const InvestmentRow({
    required this.id,
    required this.name,
    required this.invType,
    required this.amount,
    this.sipDay,
  });

  final String id;
  final String name;
  final String invType;
  final double amount;
  final int? sipDay;

  factory InvestmentRow.fromJson(Map<String, dynamic> j) => InvestmentRow(
        id: j['id'] as String,
        name: j['name'] as String,
        invType: j['inv_type'] as String,
        amount: (j['amount'] as num).toDouble(),
        sipDay: (j['sip_day'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'inv_type': invType,
        'amount': amount,
        'sip_day': sipDay,
      };
}
