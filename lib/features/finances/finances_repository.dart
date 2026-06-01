import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class FinancesRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> expenses(String groupId) async {
    final rows = await _db
        .from('expenses')
        .select('*,expense_participants(id,user_id,share_amount,paid)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> groupMembers(String groupId) async {
    final rows = await _db
        .from('group_members')
        .select('user_id,role,profiles(full_name,email,avatar_url)')
        .eq('group_id', groupId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> settlements(String groupId) async {
    final rows = await _db
        .from('settlements')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> createExpense({
    required String groupId,
    required String concept,
    required double amount,
    required String paidBy,
    required Map<String, double> shares,
    String? note,
  }) async {
    final cleanedShares = Map<String, double>.fromEntries(
      shares.entries.where((entry) => entry.value > 0),
    );

    if (cleanedShares.isEmpty) {
      throw Exception('Selecciona al menos un participante.');
    }

    final totalShares = cleanedShares.values.fold<double>(0, (sum, value) => sum + value);
    if ((totalShares - amount).abs() > 0.03) {
      throw Exception('La suma de participantes debe coincidir con el total.');
    }

    final expense = await _db.from('expenses').insert({
      'group_id': groupId,
      'concept': concept.trim(),
      'amount': amount,
      'paid_by': paidBy,
      'created_by': _userId,
      'note': note,
      'status': 'pending',
    }).select().single();

    final expenseId = expense['id'].toString();

    await _db.from('expense_participants').insert(cleanedShares.entries.map((entry) => {
      'expense_id': expenseId,
      'user_id': entry.key,
      'share_amount': entry.value,
      'paid': false,
    }).toList());
  }

  Future<void> markExpensePaid(String expenseId) async {
    await _db.from('expenses').update({
      'status': 'paid',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', expenseId);
  }

  Future<void> reopenExpense(String expenseId) async {
    await _db.from('expenses').update({
      'status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', expenseId);
  }

  Future<void> cancelExpense(String expenseId) async {
    await _db.from('expenses').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', expenseId);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db.from('expenses').delete().eq('id', expenseId);
  }

  Future<void> createSettlement({
    required String groupId,
    required String fromUser,
    required String toUser,
    required double amount,
    String status = 'paid',
  }) async {
    if (fromUser == toUser) throw Exception('El pagador y receptor no pueden ser la misma persona.');
    if (amount <= 0) throw Exception('El importe debe ser mayor que 0.');

    await _db.from('settlements').insert({
      'group_id': groupId,
      'from_user': fromUser,
      'to_user': toUser,
      'amount': amount,
      'status': status,
      'created_by': _userId,
    });
  }

  Future<void> markSettlementPaid(String settlementId) async {
    await _db.from('settlements').update({
      'status': 'paid',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', settlementId);
  }

  Future<void> cancelSettlement(String settlementId) async {
    await _db.from('settlements').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', settlementId);
  }
}
