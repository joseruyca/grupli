import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class CalendarRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> events(String groupId) async {
    final rows = await _db
        .from('events')
        .select('id,group_id,title,starts_at,location,notes,min_people,status,created_by,created_at,updated_at')
        .eq('group_id', groupId)
        .order('starts_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> event(String eventId) async {
    final row = await _db
        .from('events')
        .select('id,group_id,title,starts_at,location,notes,min_people,status,created_by,created_at,updated_at')
        .eq('id', eventId)
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> createEvent({
    required String groupId,
    required String title,
    required DateTime startsAt,
    String? location,
    String? notes,
    int minPeople = 2,
  }) async {
    await _db.from('events').insert({
      'group_id': groupId,
      'title': title.trim(),
      'starts_at': startsAt.toIso8601String(),
      'location': _emptyToNull(location),
      'notes': _emptyToNull(notes),
      'min_people': minPeople < 1 ? 1 : minPeople,
      'created_by': _userId,
    });
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    String? location,
    String? notes,
    int minPeople = 2,
  }) async {
    await _db.from('events').update({
      'title': title.trim(),
      'starts_at': startsAt.toIso8601String(),
      'location': _emptyToNull(location),
      'notes': _emptyToNull(notes),
      'min_people': minPeople < 1 ? 1 : minPeople,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId);
  }

  Future<void> cancelEvent(String eventId) async {
    await _db.from('events').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId);
  }

  Future<void> reactivateEvent(String eventId) async {
    await _db.from('events').update({
      'status': 'active',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.from('events').delete().eq('id', eventId);
  }

  Future<List<Map<String, dynamic>>> attendance(String eventId) async {
    final eventRow = await event(eventId);
    final groupId = eventRow['group_id'].toString();

    final membersRows = await _db
        .from('group_members')
        .select('user_id,role,profiles(full_name,email,avatar_url)')
        .eq('group_id', groupId)
        .order('created_at');

    final attendanceRows = await _db
        .from('event_attendance')
        .select('user_id,status,updated_at')
        .eq('event_id', eventId);

    final attendanceByUser = <String, Map<String, dynamic>>{};
    for (final row in List<Map<String, dynamic>>.from(attendanceRows as List)) {
      attendanceByUser[row['user_id'].toString()] = row;
    }

    return List<Map<String, dynamic>>.from(membersRows as List).map((member) {
      final userId = member['user_id'].toString();
      final attendance = attendanceByUser[userId];
      return {
        ...member,
        'status': attendance?['status'] ?? 'pending',
        'attendance_updated_at': attendance?['updated_at'],
        'is_me': userId == _userId,
      };
    }).toList();
  }

  Future<void> setAttendance(String eventId, String status) async {
    await _db.from('event_attendance').upsert({
      'event_id': eventId,
      'user_id': _userId,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'event_id,user_id');
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
