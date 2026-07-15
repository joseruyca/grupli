import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  test('football classification uses goals and direct order', () {
    final title = tournamentClassificationTitle('liga', 'football', scoringConfigForType('football'));
    final summary = tournamentClassificationSummary('liga', 'football', scoringConfig: scoringConfigForType('football'));

    expect(title, 'Clasificacion por goles');
    expect(summary, contains('diferencia de goles'));
    expect(summary, contains('goles a favor'));
  });

  test('set sports explain sets and games or points', () {
    final tennisSummary = tournamentClassificationSummary('liga', 'tennis_padel', scoringConfig: scoringConfigForType('tennis_padel'));
    final volleySummary = tournamentClassificationSummary('liga', 'volleyball', scoringConfig: scoringConfigForType('volleyball'));

    expect(tennisSummary, contains('diferencia de sets'));
    expect(tennisSummary, contains('juegos a favor'));
    expect(volleySummary, contains('puntos de set'));
  });

  test('americano gets a dedicated ranking title', () {
    final title = tournamentClassificationTitle('americano', 'tennis_padel', scoringConfigForType('tennis_padel'));
    final summary = tournamentClassificationSummary('americano', 'tennis_padel', scoringConfig: scoringConfigForType('tennis_padel'));

    expect(title, 'Ranking individual');
    expect(summary, contains('Ranking individual'));
    expect(summary, contains('pareja'));
  });

  test('result help explains how to enter scores naturally', () {
    final match = {'result_details': <String, dynamic>{}, 'team_a': 'a', 'team_b': 'b', 'status': 'pending'};

    final footballHelp = tournamentResultHelpForMatch(match, 'football', scoringConfigForType('football'));
    final tennisHelp = tournamentResultHelpForMatch(match, 'tennis_padel', scoringConfigForType('tennis_padel'));

    expect(footballHelp, contains('marcador final'));
    expect(tennisHelp, contains('sets, juegos y desempates'));
  });
}
