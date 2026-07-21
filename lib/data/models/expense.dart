/// Mirrors the `expenses` table (see supabase/types.ts → Database.public.Tables.expenses).
class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.subCategory,
    required this.expenseDate,
    this.note,
    required this.paymentMethod,
    this.cardName,
    this.cardLast4,
    this.bankName,
    this.upiId,
    this.status,
    this.isRecurring = false,
    this.dueDay,
    this.remindBeforeDays,
    this.categoryIcon,
  });

  final String id;
  final double amount;
  final String category;
  final String? subCategory;
  final String expenseDate;
  final String? note;
  final String paymentMethod;
  final String? cardName;
  final String? cardLast4;
  final String? bankName;
  final String? upiId;
  final String? status;
  final bool isRecurring;
  final int? dueDay;
  final int? remindBeforeDays;
  final String? categoryIcon;

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        subCategory: j['sub_category'] as String?,
        expenseDate: j['expense_date'] as String,
        note: j['note'] as String?,
        paymentMethod: (j['payment_method'] as String?) ?? 'upi',
        cardName: j['card_name'] as String?,
        cardLast4: j['card_last4'] as String?,
        bankName: j['bank_name'] as String?,
        upiId: j['upi_id'] as String?,
        status: j['status'] as String?,
        isRecurring: (j['is_recurring'] as bool?) ?? false,
        dueDay: (j['due_day'] as num?)?.toInt(),
        remindBeforeDays: (j['remind_before_days'] as num?)?.toInt(),
        categoryIcon: j['category_icon'] as String?,
      );

  /// Round-trips through OfflineCache — field names match fromJson exactly.
  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'sub_category': subCategory,
        'expense_date': expenseDate,
        'note': note,
        'payment_method': paymentMethod,
        'card_name': cardName,
        'card_last4': cardLast4,
        'bank_name': bankName,
        'upi_id': upiId,
        'status': status,
        'is_recurring': isRecurring,
        'due_day': dueDay,
        'remind_before_days': remindBeforeDays,
        'category_icon': categoryIcon,
      };

  /// Human label for the payment method row (mirrors modeLabel() in dashboard.tsx).
  String get modeLabel {
    switch (paymentMethod) {
      case 'card':
        return cardName != null ? 'Card · $cardName' : 'Card';
      case 'netbanking':
        return bankName != null ? 'Net Banking · $bankName' : 'Net Banking';
      case 'upi':
        return upiId != null ? 'UPI · $upiId' : 'UPI';
      case 'cash':
        return 'Cash';
      default:
        return paymentMethod.toUpperCase();
    }
  }
}

class PersonalEvent {
  const PersonalEvent({
    required this.id,
    required this.personName,
    required this.eventType,
    this.eventDate,
  });

  final String id;
  final String personName;
  final String eventType;
  final String? eventDate;

  factory PersonalEvent.fromJson(Map<String, dynamic> j) => PersonalEvent(
        id: j['id'] as String,
        personName: j['person_name'] as String,
        eventType: (j['event_type'] as String?) ?? '',
        eventDate: j['event_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'person_name': personName,
        'event_type': eventType,
        'event_date': eventDate,
      };
}
