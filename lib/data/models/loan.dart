/// Full-fidelity mirror of the `loans` table for the CRUD module.
/// (The narrower `LoanRow` in `money.dart` stays as-is for dashboard reminders.)
class Loan {
  const Loan({
    required this.id,
    required this.lender,
    required this.loanType,
    required this.principal,
    required this.outstanding,
    required this.interestRate,
    required this.emi,
    required this.tenureMonths,
    this.emiType = 'monthly',
    this.principalPaid = 0,
    this.interestPaid = 0,
    this.dueDay,
    this.startDate,
    this.nextDueDate,
  });

  final String id;
  final String lender;
  final String loanType; // Home | Car | Personal | Education | Other
  final double principal;
  final double outstanding;
  final double interestRate;
  final double emi;
  final int tenureMonths;
  final String emiType;
  final double principalPaid;
  final double interestPaid;
  final int? dueDay;
  final DateTime? startDate;
  final DateTime? nextDueDate;

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as String,
        lender: j['lender'] as String,
        loanType: j['loan_type'] as String,
        principal: (j['principal'] as num).toDouble(),
        outstanding: (j['outstanding'] as num).toDouble(),
        interestRate: (j['interest_rate'] as num).toDouble(),
        emi: (j['emi'] as num).toDouble(),
        tenureMonths: (j['tenure_months'] as num).toInt(),
        emiType: (j['emi_type'] as String?) ?? 'monthly',
        principalPaid: (j['principal_paid'] as num?)?.toDouble() ?? 0,
        interestPaid: (j['interest_paid'] as num?)?.toDouble() ?? 0,
        dueDay: (j['due_day'] as num?)?.toInt(),
        startDate: j['start_date'] != null ? DateTime.parse(j['start_date'] as String) : null,
        nextDueDate: j['next_due_date'] != null ? DateTime.parse(j['next_due_date'] as String) : null,
      );

  Map<String, dynamic> toInsertJson(String uid) => {
        'user_id': uid,
        'lender': lender,
        'loan_type': loanType,
        'principal': principal,
        'outstanding': outstanding,
        'interest_rate': interestRate,
        'emi': emi,
        'tenure_months': tenureMonths,
        'emi_type': emiType,
        'principal_paid': principalPaid,
        'interest_paid': interestPaid,
        'due_day': dueDay,
        'start_date': startDate?.toIso8601String().split('T').first,
        'next_due_date': nextDueDate?.toIso8601String().split('T').first,
      };
}
