/// Mirrors the `goals` table (new in v2.1 — no React-app equivalent).
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    this.icon,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? icon;

  double get progress => targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);
  bool get isComplete => currentAmount >= targetAmount && targetAmount > 0;

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] as String,
        name: j['name'] as String,
        targetAmount: (j['target_amount'] as num).toDouble(),
        currentAmount: (j['current_amount'] as num).toDouble(),
        targetDate: j['target_date'] != null ? DateTime.parse(j['target_date'] as String) : null,
        icon: j['icon'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate?.toIso8601String().split('T').first,
        'icon': icon,
      };

  Map<String, dynamic> toInsertJson(String uid) => {
        'user_id': uid,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate?.toIso8601String().split('T').first,
        'icon': icon,
      };
}
