part of 'package:grupli/main.dart';

class TournamentEngineV2 {
  static const int version = 20;
  static const String architectureKey = 'tournaments_final_architecture_v1';

  static const List<TournamentSportSpec> sportSpecs = [
    TournamentSportSpec(
      key: 'football',
      label: appIsEnglish ? 'Football' : 'Fútbol',
      emoji: '⚽',
      resultMode: 'score',
      resultLabel: 'Goles',
      participantLabel: 'Equipos',
      freeStats: ['PJ', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'PTS'],
      premiumStats: ['Rachas', 'Historial', 'Rendimiento por rival'],
    ),
    TournamentSportSpec(
      key: 'basketball',
      label: 'Baloncesto',
      emoji: '🏀',
      resultMode: 'score',
      resultLabel: 'Puntos',
      participantLabel: 'Equipos',
      freeStats: ['PJ', 'G', 'P', 'PF', 'PC', 'DIF', 'PTS'],
      premiumStats: ['Rachas', 'Evolución', 'Comparativas'],
    ),
    TournamentSportSpec(
      key: 'tennis_padel',
      label: appIsEnglish ? 'Tennis / Padel' : 'Tenis / Pádel',
      emoji: '🎾',
      resultMode: 'sets_games',
      resultLabel: 'Sets y juegos',
      participantLabel: 'Jugadores o parejas',
      freeStats: ['PJ', 'V', 'P', 'SF', 'SC', 'DS', 'JF', 'JC', 'DJ', 'PTS'],
      premiumStats: ['Mejor pareja', 'Rachas', 'Ranking histórico'],
    ),
    TournamentSportSpec(
      key: 'volleyball',
      label: 'Voleibol',
      emoji: '🏐',
      resultMode: 'sets_points',
      resultLabel: 'Sets y puntos de set',
      participantLabel: 'Equipos',
      freeStats: ['PJ', 'G', 'P', 'SF', 'SC', 'PF', 'PC', 'PTS'],
      premiumStats: ['Rachas', 'Historial', 'Comparativas'],
    ),
    TournamentSportSpec(
      key: 'ping_pong',
      label: 'Ping pong',
      emoji: '🏓',
      resultMode: 'sets_points',
      resultLabel: 'Sets y puntos',
      participantLabel: 'Jugadores o parejas',
      freeStats: ['PJ', 'G', 'P', 'SF', 'SC', 'PF', 'PC', 'PTS'],
      premiumStats: ['Rachas', 'Ranking histórico', 'Rendimiento por rival'],
    ),
    TournamentSportSpec(
      key: 'cards_mus',
      label: 'Cartas / Mus',
      emoji: '🃏',
      resultMode: 'score',
      resultLabel: 'Partidas o tantos',
      participantLabel: 'Jugadores o parejas',
      freeStats: ['PJ', 'G', 'P', 'Puntos', 'DIF'],
      premiumStats: ['Historial', 'Rachas', 'Ranking del grupo'],
    ),
    TournamentSportSpec(
      key: 'darts',
      label: 'Dardos',
      emoji: '🎯',
      resultMode: 'score',
      resultLabel: 'Puntos o legs',
      participantLabel: 'Jugadores o equipos',
      freeStats: ['PJ', 'G', 'P', 'PF', 'PC', 'DIF'],
      premiumStats: ['Historial', 'Rachas', 'Comparativas'],
    ),
    TournamentSportSpec(
      key: 'billiards',
      label: 'Billar',
      emoji: '🎱',
      resultMode: 'score',
      resultLabel: 'Partidas',
      participantLabel: 'Jugadores o equipos',
      freeStats: ['PJ', 'G', 'P', 'Puntos', 'DIF'],
      premiumStats: ['Historial', 'Rachas', 'Ranking del grupo'],
    ),
    TournamentSportSpec(
      key: 'esports',
      label: 'Esports',
      emoji: '🎮',
      resultMode: 'score',
      resultLabel: 'Mapas o rondas',
      participantLabel: 'Equipos',
      freeStats: ['PJ', 'G', 'P', 'PF', 'PC', 'DIF'],
      premiumStats: ['Mapas favoritos', 'Rachas', 'Historial'],
    ),
    TournamentSportSpec(
      key: 'custom',
      label: 'Libre',
      emoji: '⭐',
      resultMode: 'score',
      resultLabel: 'Marcador simple',
      participantLabel: 'Participantes',
      freeStats: ['PJ', 'G', 'P', 'Puntos'],
      premiumStats: ['Historial', 'Rachas', 'Ranking del grupo'],
    ),
    TournamentSportSpec(
      key: 'general',
      label: 'General',
      emoji: '🏆',
      resultMode: 'score',
      resultLabel: 'Marcador simple',
      participantLabel: 'Participantes',
      freeStats: ['PJ', 'G', 'P', 'Puntos'],
      premiumStats: ['Historial', 'Rachas', 'Ranking del grupo'],
    ),
  ];

  static const List<TournamentPremiumFeature> premiumFeatures = [
    TournamentPremiumFeature('unlimited_active_tournaments', appIsEnglish ? 'Unlimited active tournaments' : 'Torneos activos ilimitados', appIsEnglish ? 'For groups that run several competitions at the same time.' : 'Para grupos que organizan varias competiciones a la vez.'),
    TournamentPremiumFeature('advanced_americano', appIsEnglish ? 'Advanced Americano' : 'Americano avanzado', appIsEnglish ? 'Smart rotations, balanced breaks and fewer repeats.' : 'Rotaciones inteligentes, descansos equilibrados y menos repeticiones.'),
    TournamentPremiumFeature('smart_multi_courts', appIsEnglish ? 'Smart multiple courts' : 'Múltiples pistas inteligentes', appIsEnglish ? 'Distribute matches across courts or tables automatically.' : 'Reparte partidos por pista o mesa de forma automática.'),
    TournamentPremiumFeature('advanced_calendar', appIsEnglish ? 'Advanced automatic calendar' : 'Calendario automático avanzado', appIsEnglish ? 'Reorder dates, detect conflicts and prepare rounds.' : 'Reorganiza fechas, detecta conflictos y prepara jornadas.'),
    TournamentPremiumFeature('move_matchdays', appIsEnglish ? 'Move full matchdays' : 'Mover jornadas completas', appIsEnglish ? 'Move a full round without editing match by match.' : 'Cambia una jornada entera sin editar partido por partido.'),
    TournamentPremiumFeature('advanced_stats', appIsEnglish ? 'Advanced stats' : 'Estadísticas avanzadas', appIsEnglish ? 'Streaks, evolution, comparisons and history.' : 'Rachas, evolución, comparativas e historial.'),
    TournamentPremiumFeature('custom_tiebreakers', appIsEnglish ? 'Custom tiebreakers' : 'Desempates configurables', appIsEnglish ? 'Change the tiebreak order for the group.' : 'Cambia el orden de desempates según el grupo.'),
    TournamentPremiumFeature('exports', appIsEnglish ? 'Export standings' : 'Exportar clasificación', appIsEnglish ? 'Create a PDF, image or file to share.' : 'Crea PDF, imagen o archivo para compartir.'),
    TournamentPremiumFeature('beautiful_share', appIsEnglish ? 'Beautiful sharing' : 'Compartir resumen bonito', appIsEnglish ? 'Visual summary for WhatsApp or social networks.' : 'Resumen visual para WhatsApp o redes.'),
    TournamentPremiumFeature('duplicate_tournaments', appIsEnglish ? 'Duplicate tournament' : 'Duplicar torneo', appIsEnglish ? 'Repeat a league or tournament with the same structure.' : 'Repite una liga o torneo con la misma estructura.'),
    TournamentPremiumFeature('saved_templates', appIsEnglish ? 'Saved templates' : 'Plantillas guardadas', appIsEnglish ? 'Save the group’s usual formats.' : 'Guarda formatos habituales del grupo.'),
    TournamentPremiumFeature('seeding', appIsEnglish ? 'Seeding' : 'Cabezas de serie', appIsEnglish ? 'Order favorites or use ranking for the bracket.' : 'Ordena favoritos o usa ranking para el cuadro.'),
    TournamentPremiumFeature('historical_group_ranking', appIsEnglish ? 'Historical group ranking' : 'Ranking histórico del grupo', appIsEnglish ? 'Accumulated ranking across tournaments and seasons.' : 'Ranking acumulado entre torneos y temporadas.'),
  ];

  static TournamentSportSpec sportSpec(String sport) {
    return sportSpecs.firstWhere((spec) => spec.key == sport, orElse: () => sportSpecs.last);
  }

  static Map<String, dynamic> defaultPermissionsConfig(String sport, String format) => {
    'version': version,
    'architecture': architectureKey,
    'billing_enabled': false,
    'premium_scope': 'group',
    'large_groups_free': true,
    'participants_limited': false,
    'third_place_free': true,
    'free_active_tournament_limit': GrupliPremium.freeActiveTournamentsPerGroup,
    'free_features': [
      'large_groups',
      'basic_league',
      'basic_elimination',
      'basic_manual',
      'basic_americano',
      'basic_standings',
      'sport_results',
      'basic_agenda_link',
      'third_place',
      'simple_share',
    ],
    'premium_features': GrupliPremium.features.map((feature) => feature.key).toList(),
    'current_sport': sport,
    'current_format': format,
  };

  static String sportStatsSummary(String sport, {bool premium = false}) {
    final spec = sportSpec(sport);
    final items = premium ? spec.premiumStats : spec.freeStats;
    return items.join(' · ');
  }


  static const Map<String, List<String>> _formatsBySport = {
    'football': ['liga', 'eliminatoria', 'manual'],
    'tennis_padel': ['liga', 'eliminatoria', 'americano', 'manual'],
    'basketball': ['liga', 'eliminatoria', 'manual'],
    'volleyball': ['liga', 'eliminatoria', 'manual'],
    'ping_pong': ['liga', 'eliminatoria', 'americano', 'manual'],
    'cards_mus': ['liga', 'eliminatoria', 'americano', 'manual'],
    'darts': ['liga', 'eliminatoria', 'manual'],
    'billiards': ['liga', 'eliminatoria', 'manual'],
    'esports': ['liga', 'eliminatoria', 'manual'],
    'custom': ['liga', 'eliminatoria', 'americano', 'manual'],
    'general': ['liga', 'eliminatoria', 'manual'],
  };

  static const Map<String, String> _defaultFormatBySport = {
    'football': 'liga',
    'tennis_padel': 'liga',
    'basketball': 'liga',
    'volleyball': 'liga',
    'ping_pong': 'liga',
    'cards_mus': 'liga',
    'darts': 'liga',
    'billiards': 'liga',
    'esports': 'liga',
    'custom': 'liga',
    'general': 'liga',
  };

  static const Map<String, String> formatToTemplate = {
    'liga': 'league',
    'americano': 'americano_padel',
    'eliminatoria': 'quick_cup',
    'manual': 'manual_day',
  };

  static const Map<String, String> templateToFormat = {
    'league': 'liga',
    'americano_padel': 'americano',
    'quick_cup': 'eliminatoria',
    'manual_day': 'manual',
  };

  static List<String> allowedFormats(String sport) {
    return List<String>.from(_formatsBySport[sport] ?? _formatsBySport['general']!);
  }

  static bool supportsFormat(String sport, String format) => allowedFormats(sport).contains(format);

  static bool supportsAmericano(String sport) => supportsFormat(sport, 'americano');

  static String defaultFormat(String sport) => _defaultFormatBySport[sport] ?? 'liga';

  static String normalizeFormat(String sport, String current) {
    final allowed = allowedFormats(sport);
    if (allowed.contains(current)) return current;
    return defaultFormat(sport);
  }

  static String templateForFormat(String format) => formatToTemplate[format] ?? 'league';

  static String formatForTemplate(String template) => templateToFormat[template] ?? 'liga';

  static List<String> allowedTemplateValues(String sport) {
    return allowedFormats(sport).map(templateForFormat).toList();
  }

  static List<TournamentChoice> participantChoices(String sport, String format) {
    if (format == 'americano') {
      return const [TournamentChoice('individual', 'Jugadores', 'Ranking individual', Icons.person_rounded)];
    }
    if (format == 'manual') {
      return const [
        TournamentChoice('individual', 'Jugadores', 'Uno contra uno', Icons.person_rounded),
        TournamentChoice('pareja', 'Parejas', 'Ana / Javi', Icons.people_rounded),
        TournamentChoice('equipo', 'Equipos', 'Nombres libres', Icons.groups_rounded),
      ];
    }
    if (sport == 'tennis_padel') {
      return const [
        TournamentChoice('pareja', appIsEnglish ? 'Pairs' : 'Parejas', appIsEnglish ? 'Padel doubles' : 'Pádel dobles', Icons.people_rounded),
        TournamentChoice('individual', 'Individual', 'Uno contra uno', Icons.person_rounded),
      ];
    }
    if (sport == 'football' || sport == 'basketball' || sport == 'volleyball' || sport == 'esports') {
      return const [TournamentChoice('equipo', 'Equipos', 'Clubes o equipos', Icons.groups_rounded)];
    }
    if (sport == 'ping_pong' || sport == 'cards_mus') {
      return const [
        TournamentChoice('individual', 'Jugadores', 'Ranking por jugador', Icons.person_rounded),
        TournamentChoice('pareja', 'Parejas', 'Dos por equipo', Icons.people_rounded),
      ];
    }
    if (sport == 'darts' || sport == 'billiards') {
      return const [
        TournamentChoice('individual', 'Jugadores', 'Uno contra uno', Icons.person_rounded),
        TournamentChoice('equipo', 'Equipos', 'Equipos libres', Icons.groups_rounded),
      ];
    }
    return const [
      TournamentChoice('equipo', 'Equipos', 'Nombres libres', Icons.groups_rounded),
      TournamentChoice('individual', 'Jugadores', 'Uno contra uno', Icons.person_rounded),
      TournamentChoice('pareja', 'Parejas', 'Ana / Javi', Icons.people_rounded),
    ];
  }

  static String defaultParticipantType(String sport, String format) {
    if (format == 'americano') return 'individual';
    if (sport == 'tennis_padel') return 'pareja';
    if (sport == 'ping_pong' || sport == 'cards_mus' || sport == 'darts' || sport == 'billiards') return 'individual';
    return 'equipo';
  }

  static String normalizeParticipantType(String sport, String format, String current) {
    final allowed = participantChoices(sport, format).map((item) => item.value).toSet();
    if (allowed.contains(current)) return current;
    final recommended = defaultParticipantType(sport, format);
    return allowed.contains(recommended) ? recommended : allowed.first;
  }

  static String participantTitle(String sport, String format, String mode) {
    if (format == 'americano') return 'Jugadores del americano';
    if (mode == 'pareja') return 'Parejas participantes';
    if (mode == 'individual') return 'Jugadores participantes';
    return 'Equipos participantes';
  }

  static String participantHint(String sport, String format, String mode) {
    if (format == 'americano') return 'Ana\nJavi\nMarta\nLuis\nCarlos\nLucía\nPablo\nNerea';
    if (mode == 'pareja') return 'Ana / Javi\nMarta / Luis\nCris / Pablo\nNerea / Hugo';
    if (mode == 'individual') return 'Ana\nJavi\nMarta\nLuis\nCarlos\nLucía';
    if (sport == 'football') return 'Los Pingüinos FC\nEquipo Azul\nLa Banda del Domingo\nRojos FC';
    if (sport == 'basketball') return 'Rookies\nTriple Doble\nEquipo Negro\nLos Rebotes';
    if (sport == 'volleyball') return 'Las Redes\nEquipo Playa\nSaque Directo\nBloqueo Alto';
    if (sport == 'esports') return 'Squad Azul\nTeam Pixel\nLos Randoms\nClan Norte';
    return 'Equipo Azul\nLos Invencibles\nGrupo del Viernes\nEquipo Rojo';
  }

  static String participantHelp(String sport, String format, String mode) {
    if (format == 'americano') return 'Solo jugadores individuales. Grupli forma parejas rotativas en cada ronda y la clasificación es individual.';
    if (sport == 'tennis_padel') {
      if (mode == 'pareja') return 'Una pareja por línea. Escribe Ana / Javi para que todo quede claro.';
      if (mode == 'individual') return 'Un jugador por línea. La clasificación sigue siendo individual y los cruces se organizan según el formato.';
      return 'En tenis y pádel, lo normal es organizar parejas. Escribe una pareja por línea o cambia a individual si jugáis uno contra uno.';
    }
    if (sport == 'ping_pong') {
      if (mode == 'pareja') return 'Una pareja por línea. Usa el formato Ana / Javi si jugáis dobles.';
      if (mode == 'individual') return 'Un jugador por línea. La tabla se calculará de forma individual.';
      return 'Un jugador por línea. Si jugáis dobles, cambia a parejas para evitar confusiones.';
    }
    if (mode == 'pareja') return 'Una pareja por línea. Usa el formato Ana / Javi para evitar confusiones.';
    if (mode == 'individual') return 'Un jugador por línea. La tabla y los cruces se calculan de forma individual.';
    if (sport == 'football') return 'Un equipo por línea. El resultado será por goles, con GF, GC y diferencia.';
    if (sport == 'basketball') return 'Un equipo por línea. El resultado será por puntos, con PF, PC y diferencia.';
    if (sport == 'volleyball') return 'Un equipo por línea. El resultado se calcula por sets y puntos de set.';
    return 'Un equipo por línea. No añadas jugadores sueltos si esta competición se organiza por equipos.';
  }

  static String formatHelp(String sport, String format) {
    if (format == 'americano') return 'Jugadores individuales, parejas rotativas, descansos equilibrados y ranking acumulado.';
    if (format == 'eliminatoria') return 'Cuadro directo. Cada partido decide quién avanza.';
    if (format == 'manual') return 'Tú eliges los partidos uno a uno con selector visual o importando cruces.';
    if (sport == 'football') return 'Liga con puntos por victoria y empate, goles a favor, goles en contra y diferencia.';
    if (sport == 'tennis_padel') return 'Liga por sets: la tabla usa victorias, sets, juegos y desempates.';
    if (sport == 'basketball') return 'Liga por puntos: victorias, puntos a favor/en contra y diferencia.';
    if (sport == 'volleyball' || sport == 'ping_pong') return 'Liga por parciales: sets ganados y puntos por set para desempatar.';
    return 'Liga todos contra todos con clasificación automática adaptada al deporte.';
  }

  static String resultContractText(String sport, String format) {
    if (format == 'americano') {
      if (sport == 'tennis_padel') return 'Registra el marcador de cada set. El ranking individual suma los juegos reales conseguidos por cada jugador.';
      if (sport == 'ping_pong') return 'Registra los parciales de cada set. El ranking individual suma los puntos reales de cada jugador.';
      return 'Registra el marcador real del partido. Cada jugador suma lo conseguido aunque cambie de pareja.';
    }
    if (format == 'eliminatoria') return 'El marcador decide quién avanza. La tabla global no es la referencia principal en una eliminatoria.';
    if (sport == 'football') return 'Marcador por goles. La tabla calcula PJ, G, E, P, GF, GC, diferencia y puntos.';
    if (sport == 'tennis_padel') return 'Marcador por sets. La tabla calcula PJ, V, P, sets a favor/en contra, juegos y puntos.';
    if (sport == 'volleyball' || sport == 'ping_pong') return 'Marcador por sets y puntos de set. La tabla usa sets y puntos acumulados para desempatar.';
    if (sport == 'basketball') return 'Marcador por puntos. La tabla calcula PJ, V, P, PF, PC, diferencia y puntos.';
    return 'Marcador editable según el deporte, con la clasificación y los desempates ya preparados.';
  }

  static List<String> defaultTieBreakers(String sport, String format) {
    if (format == 'americano') return const ['points', 'wins', 'difference', 'for', 'no_shows'];
    if (format == 'eliminatoria') return const ['points', 'wins', 'direct', 'difference', 'for'];
    final model = scoringResultModel(sport, scoringConfigForType(sport));
    if (model == 'sets_games' || model == 'sets_points') return const ['points', 'wins', 'direct', 'set_difference', 'game_difference', 'games_for', 'no_shows'];
    if (sport == 'football' || sport == 'basketball' || sport == 'esports') return const ['points', 'wins', 'direct', 'difference', 'for', 'no_shows'];
    return const ['points', 'wins', 'direct', 'difference', 'for', 'no_shows'];
  }

  static String? setupError({required String sport, required String format, required String participantType, required int participantCount, required int manualMatchesCount}) {
    if (!supportsFormat(sport, format)) return appIsEnglish ? '${tournamentFormatLabel(format)} is not available for ${scoringTypeLabel(sport)}.' : '${tournamentFormatLabel(format)} no está disponible para ${scoringTypeLabel(sport)}.';
    final allowedModes = participantChoices(sport, format).map((item) => item.value).toSet();
    if (!allowedModes.contains(participantType)) return 'Ese tipo de participantes no encaja con este deporte y formato.';
    if (format == 'americano') {
      if (participantType != 'individual') return appIsEnglish ? 'Americano only allows individual players.' : 'El Americano solo admite jugadores individuales.';
      if (participantCount < 4) return appIsEnglish ? 'Americano needs at least 4 players.' : 'El Americano necesita al menos 4 jugadores.';
    } else if (participantCount < 2) {
      return appIsEnglish ? 'Add at least 2 participants.' : 'Añade al menos 2 participantes.';
    }
    if (format == 'manual' && manualMatchesCount <= 0) return appIsEnglish ? 'Add at least one manual match.' : 'Añade al menos un partido manual.';
    return null;
  }
}

class TournamentSportSpec {
  final String key;
  final String label;
  final String emoji;
  final String resultMode;
  final String resultLabel;
  final String participantLabel;
  final List<String> freeStats;
  final List<String> premiumStats;

  const TournamentSportSpec({
    required this.key,
    required this.label,
    required this.emoji,
    required this.resultMode,
    required this.resultLabel,
    required this.participantLabel,
    required this.freeStats,
    required this.premiumStats,
  });
}

class TournamentPremiumFeature {
  final String key;
  final String title;
  final String description;

  const TournamentPremiumFeature(this.key, this.title, this.description);
}
