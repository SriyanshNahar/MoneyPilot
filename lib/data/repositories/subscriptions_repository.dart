import '../../core/supabase/supabase_config.dart';
import '../models/subscription.dart';

class SubscriptionsRepository {
  const SubscriptionsRepository();

  Future<List<Subscription>> fetchAll(String uid) async {
    final rows = await supabase.from('subscriptions').select().eq('user_id', uid).order('created_at', ascending: false);
    return (rows as List).map((r) => Subscription.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> insert(Subscription sub, String uid) async {
    await supabase.from('subscriptions').insert(sub.toInsertJson(uid));
  }

  Future<void> update(Subscription sub, String uid) async {
    await supabase.from('subscriptions').update(sub.toInsertJson(uid)..remove('user_id')).eq('id', sub.id);
  }

  Future<void> delete(String id) async {
    await supabase.from('subscriptions').delete().eq('id', id);
  }
}
