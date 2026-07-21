import '../../core/supabase/supabase_config.dart';
import '../models/money.dart';

class MoneyRepository {
  const MoneyRepository();

  Future<List<SubscriptionRow>> fetchActiveSubscriptions(String uid) async {
    final rows = await supabase
        .from('subscriptions')
        .select('id, name, amount, next_billing_date, billing_cycle')
        .eq('user_id', uid)
        .eq('is_active', true);
    return (rows as List).map((r) => SubscriptionRow.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<LoanRow>> fetchLoans(String uid) async {
    final rows = await supabase.from('loans').select('id, lender, emi, due_day, next_due_date').eq('user_id', uid);
    return (rows as List).map((r) => LoanRow.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<InvestmentRow>> fetchInvestments(String uid) async {
    final rows = await supabase.from('investments').select('id, name, inv_type, amount, sip_day').eq('user_id', uid);
    return (rows as List).map((r) => InvestmentRow.fromJson(r as Map<String, dynamic>)).toList();
  }
}
