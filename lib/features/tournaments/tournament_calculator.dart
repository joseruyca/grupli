class TournamentStanding {
  final String teamId;
  final String teamName;
  int played = 0;
  int won = 0;
  int draw = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;

  TournamentStanding({required this.teamId, required this.teamName});

  int get goalDifference => goalsFor - goalsAgainst;
}

class TournamentCalculator {
  static List<TournamentStanding> standings({
    required List<Map<String, dynamic>> teams,
    required List<Map<String, dynamic>> matches,
    int pointsWin = 3,
    int pointsDraw = 1,
  }) {
    final table = <String, TournamentStanding>{};

    for (final team in teams) {
      final id = team['id']?.toString();
      if (id == null || id.isEmpty) continue;
      table[id] = TournamentStanding(
        teamId: id,
        teamName: (team['name'] ?? 'Equipo').toString(),
      );
    }

    for (final match in matches) {
      if ((match['status'] ?? 'pending').toString() != 'played') continue;
      final teamA = match['team_a']?.toString();
      final teamB = match['team_b']?.toString();
      final scoreA = _toIntOrNull(match['score_a']);
      final scoreB = _toIntOrNull(match['score_b']);

      if (teamA == null || teamB == null || scoreA == null || scoreB == null) continue;
      if (!table.containsKey(teamA) || !table.containsKey(teamB)) continue;

      final a = table[teamA]!;
      final b = table[teamB]!;

      a.played++;
      b.played++;
      a.goalsFor += scoreA;
      a.goalsAgainst += scoreB;
      b.goalsFor += scoreB;
      b.goalsAgainst += scoreA;

      if (scoreA > scoreB) {
        a.won++;
        b.lost++;
        a.points += pointsWin;
      } else if (scoreA < scoreB) {
        b.won++;
        a.lost++;
        b.points += pointsWin;
      } else {
        a.draw++;
        b.draw++;
        a.points += pointsDraw;
        b.points += pointsDraw;
      }
    }

    final rows = table.values.toList();
    rows.sort((a, b) {
      final pointsCompare = b.points.compareTo(a.points);
      if (pointsCompare != 0) return pointsCompare;
      final gdCompare = b.goalDifference.compareTo(a.goalDifference);
      if (gdCompare != 0) return gdCompare;
      final gfCompare = b.goalsFor.compareTo(a.goalsFor);
      if (gfCompare != 0) return gfCompare;
      return a.teamName.compareTo(b.teamName);
    });
    return rows;
  }

  static List<Map<String, dynamic>> roundRobinPairs({
    required String tournamentId,
    required List<Map<String, dynamic>> teams,
    required List<Map<String, dynamic>> existingMatches,
  }) {
    final cleanTeams = teams
        .where((team) => (team['id'] ?? '').toString().isNotEmpty)
        .toList();

    final existing = <String>{};
    for (final match in existingMatches) {
      final a = match['team_a']?.toString();
      final b = match['team_b']?.toString();
      if (a == null || b == null) continue;
      existing.add(_pairKey(a, b));
    }

    final pairs = <Map<String, dynamic>>[];
    var round = 1;

    for (var i = 0; i < cleanTeams.length; i++) {
      for (var j = i + 1; j < cleanTeams.length; j++) {
        final a = cleanTeams[i]['id'].toString();
        final b = cleanTeams[j]['id'].toString();
        if (existing.contains(_pairKey(a, b))) continue;

        pairs.add({
          'tournament_id': tournamentId,
          'team_a': a,
          'team_b': b,
          'round': round,
          'status': 'pending',
        });
        round++;
      }
    }

    return pairs;
  }

  static String teamName(List<Map<String, dynamic>> teams, Object? teamId) {
    final id = teamId?.toString();
    if (id == null) return 'Equipo';
    for (final team in teams) {
      if (team['id']?.toString() == id) return (team['name'] ?? 'Equipo').toString();
    }
    return 'Equipo';
  }

  static String _pairKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  static int? _toIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
