import '../../core/supabase/supabase_config.dart';
import '../models/investment.dart';

class InvestmentsRepository {
  const InvestmentsRepository();

  Future<List<Investment>> fetchAll(String uid) async {
    final rows = await supabase.from('investments').select().eq('user_id', uid).order('created_at', ascending: false);
    return (rows as List).map((r) => Investment.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> insert(Investment inv, String uid) async {
    await supabase.from('investments').insert(inv.toInsertJson(uid));
  }

  Future<void> update(Investment inv, String uid) async {
    await supabase.from('investments').update(inv.toInsertJson(uid)..remove('user_id')).eq('id', inv.id);
  }

  Future<void> delete(String id) async {
    await supabase.from('investments').delete().eq('id', id);
  }
}
