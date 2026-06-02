import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class GroupsRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> myGroups() async {
    final rows = await _db.rpc('get_my_groups');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> getGroup(String groupId) async {
    final group = await _db.from('groups').select().eq('id', groupId).single();
    final members = await _db.from('group_members').select('role').eq('group_id', groupId).eq('user_id', _userId).maybeSingle();

    final data = Map<String, dynamic>.from(group);
    data['my_role'] = members == null ? 'member' : (members['role'] ?? 'member').toString();

    final countRows = await _db.from('group_members').select('id').eq('group_id', groupId);
    data['members_count'] = (countRows as List).length;
    return data;
  }

  Future<String> createGroup({
    required String name,
    String type = 'otro',
    String privacy = 'privado',
    String? defaultDays,
    String? defaultTime,
    String? defaultLocation,
    int minPeople = 1,
  }) async {
    final result = await _db.rpc('create_group_atomic', params: {
      'p_name': name.trim(),
      'p_type': type,
      'p_privacy': 'privado',
      'p_default_days': null,
      'p_default_time': null,
      'p_default_location': null,
      'p_min_people': 1,
    });

    final groupId = result?.toString() ?? '';
    if (groupId.isEmpty) {
      throw Exception('No se pudo crear el grupo.');
    }
    return groupId;
  }

  Future<String> joinByCode(String code) async {
    final result = await _db.rpc('join_group_with_code', params: {'code': code.trim().toUpperCase()});
    return result.toString();
  }

  Future<void> updateGroup(String groupId, Map<String, dynamic> values) async {
    await _db.from('groups').update({
      ...values,
      'privacy': 'privado',
      'default_days': null,
      'default_time': null,
      'default_location': null,
      'min_people': 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', groupId);
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.from('groups').delete().eq('id', groupId);
  }

  Future<String> regenerateCode(String groupId) async {
    final result = await _db.rpc('regenerate_group_invite_code', params: {'target_group_id': groupId});
    return result.toString();
  }

  Future<List<Map<String, dynamic>>> members(String groupId) async {
    final rows = await _db
        .from('group_members')
        .select('id,user_id,role,created_at,profiles(full_name,email,avatar_url)')
        .eq('group_id', groupId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> setMemberRole(String groupId, String userId, String role) async {
    await _db.from('group_members').update({'role': role}).eq('group_id', groupId).eq('user_id', userId);
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _db.from('group_members').delete().eq('group_id', groupId).eq('user_id', userId);
  }

  Future<void> leaveGroup(String groupId) async {
    await removeMember(groupId, _userId);
  }
}
