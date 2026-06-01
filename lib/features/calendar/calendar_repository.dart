import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class CalendarRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> events(String groupId) async {
    final rows = await _db.from('events').select().eq('group_id', groupId).order('starts_at');
    return List<Map<String, dynamic>>.from(rows as List);
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
      'location': location,
      'notes': notes,
      'min_people': minPeople,
      'created_by': _userId,
    });
  }

  Future<List<Map<String, dynamic>>> attendance(String eventId) async {
    final rows = await _db
        .from('event_attendance')
        .select('id,status,user_id,profiles(full_name,email,avatar_url)')
        .eq('event_id', eventId);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> setAttendance(String eventId, String status) async {
    await _db.from('event_attendance').upsert({
      'event_id': eventId,
      'user_id': _userId,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.from('events').delete().eq('id', eventId);
  }
}
