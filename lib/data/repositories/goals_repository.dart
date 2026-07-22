import '../../core/supabase/supabase_config.dart';
import '../models/goal.dart';

class GoalsRepository {
  const GoalsRepository();

  Future<List<Goal>> fetchAll(String uid) async {
    final rows = await supabase.from('goals').select().eq('user_id', uid).order('created_at', ascending: false);
    return (rows as List).map((r) => Goal.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> insert(Goal goal, String uid) async {
    await supabase.from('goals').insert(goal.toInsertJson(uid));
  }

  Future<void> update(Goal goal) async {
    await supabase.from('goals').update(goal.toJson()..remove('id')).eq('id', goal.id);
  }

  Future<void> delete(String id) async {
    await supabase.from('goals').delete().eq('id', id);
  }
}
