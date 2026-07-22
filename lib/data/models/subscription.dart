/// Full-fidelity mirror of the `subscriptions` table for the CRUD module.
/// (The narrower `SubscriptionRow` in `money.dart` stays as-is for dashboard reminders.)
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    this.billingDay,
    this.isActive = true,
    this.startDate,
    this.nextBillingDate,
    this.logo,
  });

  final String id;
  final String name;
  final double amount;
  final String billingCycle; // monthly | yearly | weekly
  final int? billingDay;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? nextBillingDate;
  final String? logo;

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        billingCycle: j['billing_cycle'] as String,
        billingDay: (j['billing_day'] as num?)?.toInt(),
        isActive: (j['is_active'] as bool?) ?? true,
        startDate: j['start_date'] != null ? DateTime.parse(j['start_date'] as String) : null,
        nextBillingDate: j['next_billing_date'] != null ? DateTime.parse(j['next_billing_date'] as String) : null,
        logo: j['logo'] as String?,
      );

  Map<String, dynamic> toInsertJson(String uid) => {
        'user_id': uid,
        'name': name,
        'amount': amount,
        'billing_cycle': billingCycle,
        'billing_day': billingDay,
        'is_active': isActive,
        'start_date': startDate?.toIso8601String().split('T').first,
        'next_billing_date': nextBillingDate?.toIso8601String().split('T').first,
        'logo': logo,
      };
}
