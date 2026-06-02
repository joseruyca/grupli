import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class TournamentsRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> tournaments(String groupId) async {
    final rows = await _db
        .from('tournaments')
        .select('id,group_id,name,format,team_type,points_win,points_draw,status,created_by,created_at,updated_at')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> tournament(String tournamentId) async {
    final row = await _db
        .from('tournaments')
        .select('id,group_id,name,format,team_type,points_win,points_draw,status,created_by,created_at,updated_at')
        .eq('id', tournamentId)
        .single();
    return Map<String, dynamic>.from(row);
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

  Future<void> setTournamentStatus(String tournamentId, String status) async {
    await _db.from('tournaments').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tournamentId);
  }

  Future<void> deleteTournament(String tournamentId) async {
    await _db.from('tournaments').delete().eq('id', tournamentId);
  }

  Future<List<Map<String, dynamic>>> teams(String tournamentId) async {
    final rows = await _db
        .from('tournament_teams')
        .select('id,tournament_id,name,created_at')
        .eq('tournament_id', tournamentId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> createTeam(String tournamentId, String name) async {
    await _db.from('tournament_teams').insert({
      'tournament_id': tournamentId,
      'name': name.trim(),
    });
  }

  Future<void> deleteTeam(String teamId) async {
    await _db.from('tournament_teams').delete().eq('id', teamId);
  }

  Future<List<Map<String, dynamic>>> matches(String tournamentId) async {
    final rows = await _db
        .from('matches')
        .select('id,tournament_id,team_a,team_b,score_a,score_b,round,status,played_at,created_at,updated_at')
        .eq('tournament_id', tournamentId)
        .order('round')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> createMatches(List<Map<String, dynamic>> matches) async {
    if (matches.isEmpty) return;
    await _db.from('matches').insert(matches);
  }

  Future<void> updateMatchResult({
    required String matchId,
    required int scoreA,
    required int scoreB,
  }) async {
    await _db.from('matches').update({
      'score_a': scoreA,
      'score_b': scoreB,
      'status': 'played',
      'played_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  Future<void> clearMatchResult(String matchId) async {
    await _db.from('matches').update({
      'score_a': null,
      'score_b': null,
      'status': 'pending',
      'played_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  Future<void> deleteMatch(String matchId) async {
    await _db.from('matches').delete().eq('id', matchId);
  }
}
