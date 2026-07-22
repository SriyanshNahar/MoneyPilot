/// Full-fidelity mirror of the `investments` table for the CRUD module.
/// (The narrower `InvestmentRow` in `money.dart` stays as-is — it backs the
/// dashboard's reminder/offline-cache logic and only needs a few columns.)
class Investment {
  const Investment({
    required this.id,
    required this.name,
    required this.invType,
    required this.amount,
    this.currentValue,
    this.amc,
    this.sipDay,
    this.startDate,
  });

  final String id;
  final String name;
  final String invType; // SIP | Lumpsum | FD | RD | Stocks | Other
  final double amount;
  final double? currentValue;
  final String? amc;
  final int? sipDay;
  final DateTime? startDate;

  factory Investment.fromJson(Map<String, dynamic> j) => Investment(
        id: j['id'] as String,
        name: j['name'] as String,
        invType: j['inv_type'] as String,
        amount: (j['amount'] as num).toDouble(),
        currentValue: (j['current_value'] as num?)?.toDouble(),
        amc: j['amc'] as String?,
        sipDay: (j['sip_day'] as num?)?.toInt(),
        startDate: j['start_date'] != null ? DateTime.parse(j['start_date'] as String) : null,
      );

  Map<String, dynamic> toInsertJson(String uid) => {
        'user_id': uid,
        'name': name,
        'inv_type': invType,
        'amount': amount,
        'current_value': currentValue,
        'amc': amc,
        'sip_day': sipDay,
        'start_date': startDate?.toIso8601String().split('T').first,
      };
}
