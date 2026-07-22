import '../../core/supabase/supabase_config.dart';
import '../models/loan.dart';

class LoansRepository {
  const LoansRepository();

  Future<List<Loan>> fetchAll(String uid) async {
    final rows = await supabase.from('loans').select().eq('user_id', uid).order('created_at', ascending: false);
    return (rows as List).map((r) => Loan.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> insert(Loan loan, String uid) async {
    await supabase.from('loans').insert(loan.toInsertJson(uid));
  }

  Future<void> update(Loan loan, String uid) async {
    await supabase.from('loans').update(loan.toInsertJson(uid)..remove('user_id')).eq('id', loan.id);
  }

  Future<void> delete(String id) async {
    await supabase.from('loans').delete().eq('id', id);
  }
}
