import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class FinancesRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> expenses(String groupId) async {
    final rows = await _db.from('expenses').select().eq('group_id', groupId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> groupMembers(String groupId) async {
    final rows = await _db.from('group_members').select('user_id,profiles(full_name,email)').eq('group_id', groupId).order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> balances(String groupId) async {
    final rows = await _db.rpc('get_group_balances', params: {'target_group_id': groupId});
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> createExpense({
    required String groupId,
    required String concept,
    required double amount,
    required String paidBy,
    required List<String> participants,
    String? note,
  }) async {
    final expense = await _db.from('expenses').insert({
      'group_id': groupId,
      'concept': concept.trim(),
      'amount': amount,
      'paid_by': paidBy,
      'created_by': _userId,
      'note': note,
    }).select().single();
    final expenseId = expense['id'].toString();
    final share = amount / participants.length;
    await _db.from('expense_participants').insert(participants.map((userId) => {
      'expense_id': expenseId,
      'user_id': userId,
      'share_amount': share,
    }).toList());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db.from('expenses').delete().eq('id', expenseId);
  }
}
