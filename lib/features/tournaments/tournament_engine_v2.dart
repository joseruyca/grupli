part of grupli_app;

class TournamentEngineV2 {
  static const int version = 18;

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
        TournamentChoice('pareja', 'Parejas', 'Pádel dobles', Icons.people_rounded),
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
    if (format == 'americano') return 'Solo jugadores individuales. Grupli crea parejas rotativas en cada ronda y la clasificación es individual.';
    if (mode == 'pareja') return 'Una pareja por línea. Usa el formato Ana / Javi para evitar confusiones.';
    if (mode == 'individual') return 'Un jugador por línea. La tabla y los cruces se calculan de forma individual.';
    if (sport == 'football') return 'Un equipo por línea. El resultado será por goles, con tabla de GF, GC y DG.';
    if (sport == 'basketball') return 'Un equipo por línea. El resultado será por puntos totales, con PF, PC y DP.';
    if (sport == 'volleyball') return 'Un equipo por línea. El resultado será por sets y puntos de set.';
    return 'Un equipo por línea. No añadas jugadores sueltos si esta competición se organiza por equipos.';
  }

  static String formatHelp(String sport, String format) {
    if (format == 'americano') return 'Jugadores individuales, parejas distintas por ronda, descansos equilibrados y ranking acumulado.';
    if (format == 'eliminatoria') return 'Cuadro directo. El resultado solo decide quién avanza a la siguiente ronda.';
    if (format == 'manual') return 'Tú decides los partidos uno a uno con selector visual o importación de cruces.';
    if (sport == 'football') return 'Liga con puntos por victoria/empate, goles a favor, goles en contra y diferencia.';
    if (sport == 'tennis_padel') return 'Liga por sets: la tabla usa victorias, sets, juegos y desempates.';
    if (sport == 'basketball') return 'Liga por puntos totales: victorias, puntos a favor/en contra y diferencia.';
    if (sport == 'volleyball' || sport == 'ping_pong') return 'Liga por parciales: sets ganados y puntos de set para desempatar.';
    return 'Liga todos contra todos con clasificación automática adaptada al deporte.';
  }

  static String resultContractText(String sport, String format) {
    if (format == 'americano') {
      if (sport == 'tennis_padel') return 'Registra el marcador de cada set. El ranking individual suma los juegos reales conseguidos por cada jugador.';
      if (sport == 'ping_pong') return 'Registra parciales por set. El ranking individual suma los puntos reales de cada jugador.';
      return 'Registra el marcador real del partido. Cada jugador suma lo conseguido aunque cambie de pareja.';
    }
    if (format == 'eliminatoria') return 'El marcador sirve para decidir ganador y avance. La tabla global no es el foco de una eliminatoria.';
    if (sport == 'football') return 'Marcador por goles. Tabla: PJ, G, E, P, GF, GC, DG y PTS.';
    if (sport == 'tennis_padel') return 'Marcador por sets. Tabla: PJ, V, P, SF, SC, DS, JF, JC, DJ y PTS.';
    if (sport == 'volleyball' || sport == 'ping_pong') return 'Marcador por sets y puntos de set. La tabla desempata con sets y puntos acumulados.';
    if (sport == 'basketball') return 'Marcador por puntos totales. Tabla: PJ, G, P, PF, PC, DP y PTS.';
    return 'Marcador editable según el deporte, con puntos y desempates configurados.';
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
    if (!supportsFormat(sport, format)) return '${tournamentFormatLabel(format)} no está disponible para ${scoringTypeLabel(sport)}.';
    final allowedModes = participantChoices(sport, format).map((item) => item.value).toSet();
    if (!allowedModes.contains(participantType)) return 'El tipo de participante no encaja con este deporte/formato.';
    if (format == 'americano') {
      if (participantType != 'individual') return 'El Americano solo admite jugadores individuales.';
      if (participantCount < 4) return 'El Americano necesita al menos 4 jugadores.';
    } else if (participantCount < 2) {
      return 'Añade al menos 2 participantes.';
    }
    if (format == 'manual' && manualMatchesCount <= 0) return 'Añade al menos un partido manual.';
    return null;
  }
}
