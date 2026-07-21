import '../../core/supabase/supabase_config.dart';
import '../models/expense.dart';

class ExpensesRepository {
  const ExpensesRepository();

  static const _homeColumns =
      'id, amount, category, sub_category, expense_date, note, payment_method, '
      'card_name, bank_name, upi_id, status, is_recurring, due_day, remind_before_days';

  Future<List<Expense>> fetchHome(String uid) async {
    final rows = await supabase
        .from('expenses')
        .select(_homeColumns)
        .eq('user_id', uid)
        .order('expense_date', ascending: false)
        .limit(500);
    return (rows as List).map((r) => Expense.fromJson(r as Map<String, dynamic>)).toList();
  }

  static const _khataColumns = 'id, amount, category, sub_category, expense_date, note, payment_method, status';

  Future<List<Expense>> fetchAll(String uid) async {
    final rows = await supabase
        .from('expenses')
        .select(_khataColumns)
        .eq('user_id', uid)
        .order('expense_date', ascending: false)
        .limit(500);
    return (rows as List).map((r) => Expense.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> insert(Map<String, dynamic> data) async {
    await supabase.from('expenses').insert(data);
  }

  Future<void> delete(String id) async {
    await supabase.from('expenses').delete().eq('id', id);
  }

  Future<List<dynamic>> exportAll(String uid) async {
    return await supabase.from('expenses').select().eq('user_id', uid);
  }

  Future<void> deleteAllForUser(String uid) async {
    await supabase.from('expenses').delete().eq('user_id', uid);
  }
}

class EventsRepository {
  const EventsRepository();

  Future<List<PersonalEvent>> fetchHome(String uid) async {
    final rows = await supabase
        .from('personal_events')
        .select('id, person_name, event_type, event_date')
        .eq('user_id', uid);
    return (rows as List).map((r) => PersonalEvent.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<PersonalEvent>> fetchAll(String uid) async {
    final rows = await supabase
        .from('personal_events')
        .select('id, person_name, event_type, event_date')
        .eq('user_id', uid)
        .order('event_date', ascending: false)
        .limit(200);
    return (rows as List).map((r) => PersonalEvent.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> insert(Map<String, dynamic> data) async {
    await supabase.from('personal_events').insert(data);
  }

  Future<void> delete(String id) async {
    await supabase.from('personal_events').delete().eq('id', id);
  }

  Future<List<dynamic>> exportAll(String uid) async {
    return await supabase.from('personal_events').select().eq('user_id', uid);
  }

  Future<void> deleteAllForUser(String uid) async {
    await supabase.from('personal_events').delete().eq('user_id', uid);
  }
}
