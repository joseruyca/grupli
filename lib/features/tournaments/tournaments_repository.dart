import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class TournamentsRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> tournaments(String groupId) async {
    final rows = await _db.from('tournaments').select().eq('group_id', groupId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<String> createTournament({
    required String groupId,
    required String name,
    required String format,
    required String teamType,
    int pointsWin = 3,
    int pointsDraw = 1,
  }) async {
    final row = await _db.from('tournaments').insert({
      'group_id': groupId,
      'name': name.trim(),
      'format': format,
      'team_type': teamType,
      'points_win': pointsWin,
      'points_draw': pointsDraw,
      'created_by': _userId,
    }).select().single();
    return row['id'].toString();
  }

  Future<List<Map<String, dynamic>>> teams(String tournamentId) async {
    final rows = await _db.from('tournament_teams').select().eq('tournament_id', tournamentId).order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> createTeam(String tournamentId, String name) async {
    await _db.from('tournament_teams').insert({'tournament_id': tournamentId, 'name': name.trim()});
  }

  Future<List<Map<String, dynamic>>> matches(String tournamentId) async {
    final rows = await _db.from('matches').select().eq('tournament_id', tournamentId).order('round');
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
