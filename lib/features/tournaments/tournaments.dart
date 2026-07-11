part of grupli_app;

class TournamentsTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const TournamentsTab({super.key, required this.group, required this.refreshSeed});

  @override
  State<TournamentsTab> createState() => _TournamentsTabState();
}

class _TournamentsTabState extends State<TournamentsTab> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> tournaments = [];

  String get groupId => widget.group['id'].toString();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant TournamentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed || oldWidget.group['id'] != widget.group['id']) {
      load(soft: true);
    }
  }

  Future<void> load({bool soft = false}) async {
    if (!mounted) return;
    if (!soft) setState(() { loading = true; error = null; });
    try {
      final data = await AppData.tournaments(groupId).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        tournaments = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = humanError(e);
      });
    }
  }

  Future<void> openCreate() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => TournamentCreateSimpleScreen(group: widget.group),
    ));
    if (created == true) await load(soft: true);
  }

  Future<void> openTournament(Map<String, dynamic> tournament) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TournamentDetailSimpleScreen(
        tournamentId: tournament['id'].toString(),
        group: widget.group,
      ),
    ));
    await load(soft: true);
  }

  List<TournamentDashboardMatch> _allMatches({bool played = false}) {
    final output = <TournamentDashboardMatch>[];
    for (final tournament in tournaments) {
      final teams = tournamentTeams(tournament);
      final names = teamNameMap(teams);
      for (final match in tournamentMatches(tournament)) {
        final isPlayed = AppData.text(match['status']) == 'played';
        if (played != isPlayed) continue;
        final a = tournamentMatchSideName(match, names, true);
        final b = tournamentMatchSideName(match, names, false);
        output.add(TournamentDashboardMatch(
          tournament: tournament,
          match: match,
          teamA: a,
          teamB: b,
          played: isPlayed,
        ));
      }
    }
    output.sort((a, b) {
      final dateA = AppData.text(a.match['scheduled_at']);
      final dateB = AppData.text(b.match['scheduled_at']);
      if (dateA.isNotEmpty || dateB.isNotEmpty) return dateA.compareTo(dateB);
      final round = AppData.intValue(a.match['round']).compareTo(AppData.intValue(b.match['round']));
      if (round != 0) return round;
      return AppData.text(a.match['created_at']).compareTo(AppData.text(b.match['created_at']));
    });
    return output;
  }

  @override
  Widget build(BuildContext context) {
    final active = tournaments.where((t) => !['finished', 'cancelled'].contains(AppData.text(t['status'], 'active'))).toList();
    final finished = tournaments.where((t) => ['finished', 'cancelled'].contains(AppData.text(t['status'], 'active'))).toList();
    final nextMatches = _allMatches(played: false).take(3).toList();
    final results = _allMatches(played: true).reversed.take(3).toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.red,
        onRefresh: () => load(soft: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
          children: [
            TournamentGroupHeader(
              subtitle: AppData.text(widget.group['name'], 'Grupo'),
            ),
            const SizedBox(height: 14),
            if (loading)
              const CenterLoader(label: 'Cargando torneos...')
            else if (error != null)
              ErrorBlock(message: error!, onRetry: () => load())
            else if (tournaments.isEmpty)
              TournamentCleanEmptyState(onCreate: openCreate)
            else ...[
              TournamentUxCommandCenter(
                activeCount: active.length,
                finishedCount: finished.length,
                nextCount: nextMatches.length,
                latestResults: results.length,
                onCreate: openCreate,
              ),
              if (active.isNotEmpty) ...[
                const SizedBox(height: 18),
                TournamentSectionHeader(title: active.length == 1 ? 'Competición activa' : 'Competiciones activas'),
                const SizedBox(height: 8),
                ...active.take(4).map((t) => TournamentActiveCard(tournament: t, onTap: () => openTournament(t))),
              ],
              if (nextMatches.isNotEmpty) ...[
                const SizedBox(height: 16),
                TournamentSectionHeader(title: nextMatches.length == 1 ? 'Próximo partido' : 'Próximos partidos'),
                const SizedBox(height: 8),
                ...nextMatches.map((m) => TournamentDashboardMatchCard(item: m, onTap: () => openTournament(m.tournament))),
              ],
              if (results.isNotEmpty) ...[
                const SizedBox(height: 16),
                const TournamentSectionHeader(title: 'Últimos resultados'),
                const SizedBox(height: 8),
                ...results.map((m) => TournamentDashboardMatchCard(item: m, onTap: () => openTournament(m.tournament))),
              ],
              if (finished.isNotEmpty) ...[
                const SizedBox(height: 16),
                const TournamentSectionHeader(title: 'Finalizados'),
                const SizedBox(height: 8),
                ...finished.take(3).map((t) => TournamentActiveCard(tournament: t, onTap: () => openTournament(t), compact: true)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class TournamentCreateSimpleScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const TournamentCreateSimpleScreen({super.key, required this.group});

  @override
  State<TournamentCreateSimpleScreen> createState() => _TournamentCreateSimpleScreenState();
}

class _TournamentCreateSimpleScreenState extends State<TournamentCreateSimpleScreen> {
  final name = TextEditingController();
  final participants = TextEditingController();
  final pairings = TextEditingController();
  final location = TextEditingController();
  final courtName = TextEditingController();
  String format = 'liga';
  String teamType = 'equipo';
  String scoringType = 'football';
  String creationTemplate = 'league';
  bool addToAgenda = true;
  bool scheduleMatches = true;
  bool randomizePairings = true;
  bool loading = false;
  int step = 0;
  int leagueLegs = 1;
  int leagueRoundsLimit = 0;
  int americanoRounds = 5;
  int courtsCount = 1;
  int winPoints = 3;
  int drawPoints = 1;
  int lossPoints = 0;
  int targetScore = 0;
  int bestOf = 3;
  int daysBetweenRounds = 7;
  int durationMinutes = 60;
  int intervalMinutes = 70;
  DateTime firstMatchDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay firstMatchTime = const TimeOfDay(hour: 20, minute: 0);
  final List<TournamentManualDraftRow> manualRows = [];

  @override
  void dispose() {
    name.dispose();
    participants.dispose();
    pairings.dispose();
    location.dispose();
    courtName.dispose();
    super.dispose();
  }

  bool get sportSupportsAmericano => TournamentEngineV2.supportsAmericano(scoringType);

  List<String> get allowedTemplateValues => TournamentEngineV2.allowedTemplateValues(scoringType);

  void applyScoringDefaults(String type) {
    final cfg = scoringConfigForType(type);
    scoringType = type;
    winPoints = AppData.intValue(cfg['win'], 3);
    drawPoints = AppData.intValue(cfg['draw'], 1);
    lossPoints = AppData.intValue(cfg['loss'], 0);
    bestOf = AppData.intValue(cfg['best_of'], 3);
    targetScore = AppData.intValue(cfg['target_score']);
    format = TournamentEngineV2.normalizeFormat(type, format);
    creationTemplate = TournamentEngineV2.templateForFormat(format);
    if (format != 'americano') americanoRounds = max(1, americanoRounds);
    syncTeamTypeForContext(force: true);
  }

  void applyQuickTemplate(String template) {
    final requestedFormat = TournamentEngineV2.formatForTemplate(template);
    format = TournamentEngineV2.normalizeFormat(scoringType, requestedFormat);
    creationTemplate = TournamentEngineV2.templateForFormat(format);
    pairings.clear();
    manualRows.clear();
    switch (creationTemplate) {
      case 'americano_padel':
        format = 'americano';
        randomizePairings = true;
        courtsCount = max(1, courtsCount);
        americanoRounds = max(5, americanoRounds);
        scheduleMatches = true;
        addToAgenda = true;
        name.text = name.text.trim().isEmpty ? 'Americano' : name.text;
        break;
      case 'quick_cup':
        format = 'eliminatoria';
        randomizePairings = true;
        scheduleMatches = true;
        addToAgenda = true;
        name.text = name.text.trim().isEmpty ? 'Eliminatoria' : name.text;
        break;
      case 'manual_day':
        format = 'manual';
        randomizePairings = false;
        scheduleMatches = true;
        addToAgenda = true;
        name.text = name.text.trim().isEmpty ? 'Manual' : name.text;
        break;
      default:
        format = 'liga';
        randomizePairings = true;
        leagueLegs = 1;
        leagueRoundsLimit = 0;
        scheduleMatches = true;
        addToAgenda = true;
        name.text = name.text.trim().isEmpty ? 'Liga' : name.text;
    }
    syncTeamTypeForContext(force: true);
  }

  List<TournamentChoice> participantTypeChoicesForContext() => TournamentEngineV2.participantChoices(scoringType, format);

  String recommendedTeamTypeForContext() => TournamentEngineV2.defaultParticipantType(scoringType, format);

  void syncTeamTypeForContext({bool force = false}) {
    final normalizedFormat = TournamentEngineV2.normalizeFormat(scoringType, format);
    if (normalizedFormat != format) {
      format = normalizedFormat;
      creationTemplate = TournamentEngineV2.templateForFormat(format);
    }
    final normalizedMode = TournamentEngineV2.normalizeParticipantType(scoringType, format, teamType);
    if (force || normalizedMode != teamType) teamType = normalizedMode;
  }

  String participantTypeTitle() => TournamentEngineV2.participantTitle(scoringType, format, teamType);

  String participantHintText() => TournamentEngineV2.participantHint(scoringType, format, teamType);

  String participantHelperText() => TournamentEngineV2.participantHelp(scoringType, format, teamType);

  Future<void> fillMembers() async {
    if (!(format == 'americano' || teamType == 'individual')) {
      await showToast(context, teamType == 'pareja'
          ? 'Para parejas, usa Crear pareja o añade una pareja invitada como Ana / Javi.'
          : 'Para equipos, usa Añadir equipo. Los miembros sueltos no siempre representan equipos.',
          danger: true);
      return;
    }
    try {
      final members = await AppData.members(widget.group['id'].toString());
      final names = members.map(memberDisplayName).where((n) => n.trim().length >= 2).toList();
      if (names.isEmpty) {
        if (mounted) await showToast(context, 'Todavía no hay miembros para cargar.', danger: true);
        return;
      }
      appendParticipantNames(names);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  void appendParticipantNames(List<String> values) {
    final current = parseTournamentParticipantNames(participants.text);
    final clean = mergeTournamentNames([...current, ...values]);
    setState(() => participants.text = clean.join('\n'));
  }

  void removeParticipantName(String value) {
    final key = value.trim().toLowerCase();
    final current = parseTournamentParticipantNames(participants.text).where((name) => name.trim().toLowerCase() != key).toList();
    setState(() => participants.text = current.join('\n'));
  }

  Future<List<Map<String, dynamic>>> loadGroupMembersForTournament() async {
    final members = await AppData.members(widget.group['id'].toString());
    members.sort((a, b) => memberDisplayName(a).toLowerCase().compareTo(memberDisplayName(b).toLowerCase()));
    return members;
  }

  Future<void> addMembersVisualToDraft() async {
    if (!(format == 'americano' || teamType == 'individual')) {
      await showToast(context, teamType == 'pareja'
          ? 'Esta competición usa parejas. Pulsa Crear pareja para elegir dos miembros.'
          : 'Esta competición usa equipos. Pulsa Añadir equipo para crear nombres de equipo.',
          danger: true);
      return;
    }
    try {
      final members = await loadGroupMembersForTournament();
      if (!mounted) return;
      final selected = await showTournamentMemberPickerDialog(context, members: members);
      if (selected == null || selected.isEmpty || !mounted) return;
      appendParticipantNames(selected.map(memberDisplayName).toList());
      if (mounted) await showToast(context, 'Participantes añadidos a la preparación.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> addPairVisualToDraft() async {
    if (teamType != 'pareja') {
      await showToast(context, 'Cambia el tipo de participantes a Parejas para crear parejas visuales.', danger: true);
      return;
    }
    try {
      final members = await loadGroupMembersForTournament();
      if (!mounted) return;
      final pair = await showTournamentPairCreatorDialog(context, members: members);
      if (pair == null || !mounted) return;
      final first = memberDisplayName(pair.first);
      final second = memberDisplayName(pair.second);
      final pairName = pair.name.trim().isNotEmpty ? pair.name.trim() : '$first / $second';
      appendParticipantNames([pairName]);
      if (mounted) await showToast(context, 'Pareja añadida a la preparación.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> addTeamVisualToDraft() async {
    final value = await showTournamentNamePromptDialog(
      context,
      title: 'Añadir equipo',
      label: 'Nombre del equipo',
      hint: 'Equipo Azul',
      helper: 'Luego podrás crear partidos y resultados para este equipo.',
    );
    final names = parseTournamentParticipantNames(value ?? '');
    if (names.isEmpty || !mounted) return;
    appendParticipantNames(names);
  }

  Future<void> addGuestVisualToDraft() async {
    final pairMode = teamType == 'pareja';
    final value = await showTournamentNamePromptDialog(
      context,
      title: pairMode ? 'Añadir pareja invitada' : 'Añadir invitado',
      label: pairMode ? 'Nombre de la pareja' : 'Nombre',
      hint: pairMode ? 'Ana / Javi' : 'Ana',
      helper: pairMode ? 'Escribe la pareja como aparecerá en los partidos.' : 'Útil para alguien que juega pero todavía no tiene cuenta.',
    );
    final names = parseTournamentParticipantNames(value ?? '');
    if (names.isEmpty || !mounted) return;
    appendParticipantNames(names);
  }

  List<String> get participantNames {
    final fromList = parseTournamentParticipantNames(participants.text);
    final fromPairs = tournamentNamesFromManualPairings(parseTournamentPairings(pairings.text));
    final fromVisual = manualRows.expand((row) => [row.teamAName, row.teamBName]).toList();
    return mergeTournamentNames([...fromList, ...fromPairs, ...fromVisual]);
  }

  List<String> get manualEditorParticipants {
    final fromList = parseTournamentParticipantNames(participants.text);
    final fromPairs = tournamentNamesFromManualPairings(parseTournamentPairings(pairings.text));
    return mergeTournamentNames([...fromList, ...fromPairs]);
  }

  int get effectiveRoundLimit {
    if (format == 'americano') return americanoRounds;
    if (format != 'liga') return 0;
    return leagueRoundsLimit;
  }

  int get effectiveLegs => format == 'liga' ? leagueLegs : 1;

  List<TournamentDraftMatch> get draftMatches {
    final visual = manualRows.map((row) => row.draftMatch).toList();
    if (format == 'manual' && visual.isNotEmpty) return visual;
    final manual = parseTournamentPairings(pairings.text);
    if (format == 'manual' || manual.isNotEmpty) return manual;
    return previewPairingsForFormat(format, participantNames, legs: effectiveLegs, maxRounds: effectiveRoundLimit, courts: courtsCount);
  }

  List<TournamentSchedulePreviewRow> get schedulePreviewRows {
    final counters = <int, int>{};
    if (format == 'manual' && manualRows.isNotEmpty) {
      return manualRows.map((row) {
        final round = max(1, row.round);
        final orderInsideRound = counters[round] ?? 0;
        counters[round] = orderInsideRound + 1;
        final fallback = tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound);
        final court = row.courtName.trim().isNotEmpty ? row.courtName.trim() : tournamentCourtNameForIndex(scheduleConfig, orderInsideRound);
        return TournamentSchedulePreviewRow(match: row.draftMatch, scheduledAt: row.scheduledAt ?? fallback, courtName: court);
      }).toList();
    }
    return draftMatches.map((match) {
      final round = max(1, match.round);
      final orderInsideRound = counters[round] ?? 0;
      counters[round] = orderInsideRound + 1;
      return TournamentSchedulePreviewRow(
        match: match,
        scheduledAt: tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound),
        courtName: tournamentCourtNameForIndex(scheduleConfig, orderInsideRound),
      );
    }).toList();
  }

  Map<String, dynamic> get formatConfig => {
    'version': TournamentEngineV2.version,
    'architecture': TournamentEngineV2.architectureKey,
    'engine': 'tournaments_core',
    'sport': scoringType,
    'participant_type': teamType,
    'legs': effectiveLegs,
    'max_rounds': effectiveRoundLimit,
    'americano_rounds': americanoRounds,
    'courts_count': courtsCount,
    'manual_pairings': format == 'manual' || pairings.text.trim().isNotEmpty,
    'randomize_pairings': randomizePairings,
  };

  Map<String, dynamic> get scoringConfig {
    final cfg = Map<String, dynamic>.from(scoringConfigForType(scoringType));
    cfg['win'] = winPoints;
    cfg['draw'] = scoringAllowDraw(scoringType, cfg) ? drawPoints : 0;
    cfg['loss'] = lossPoints;
    cfg['best_of'] = bestOf;
    if (targetScore > 0) cfg['target_score'] = targetScore;
    cfg['version'] = TournamentEngineV2.version;
    cfg['architecture'] = TournamentEngineV2.architectureKey;
    cfg['engine'] = 'tournaments_core';
    cfg['sport'] = scoringType;
    cfg['format'] = format;
    cfg['participant_type'] = teamType;
    return cfg;
  }

  Map<String, dynamic> get scheduleConfig {
    final first = DateTime(firstMatchDate.year, firstMatchDate.month, firstMatchDate.day, firstMatchTime.hour, firstMatchTime.minute);
    return {
      'version': TournamentEngineV2.version,
      'architecture': TournamentEngineV2.architectureKey,
      'engine': 'tournaments_core',
      'enabled': scheduleMatches,
      'add_to_agenda': addToAgenda,
      'first_start_at': first.toUtc().toIso8601String(),
      'days_between_rounds': daysBetweenRounds,
      'duration_minutes': durationMinutes,
      'interval_minutes': intervalMinutes,
      'matches_per_round': max(1, courtsCount),
      'courts_count': max(1, courtsCount),
      'location': location.text.trim(),
      'court_name': courtName.text.trim(),
    };
  }

  bool validateStep(int value) {
    if (value == 0) return true;
    if (value == 1) return true;
    if (value == 2) {
      final setupError = TournamentEngineV2.setupError(
        sport: scoringType,
        format: format,
        participantType: teamType,
        participantCount: participantNames.length,
        manualMatchesCount: manualRows.isNotEmpty ? manualRows.length : parseTournamentPairings(pairings.text).length,
      );
      if (setupError != null) {
        showToast(context, setupError, danger: true);
        return false;
      }
      if ((format == 'manual' || pairings.text.trim().isNotEmpty) && draftMatches.isEmpty) {
        showToast(context, 'Faltan emparejamientos válidos. Usa: Jornada 1: Equipo Azul vs Equipo Rojo', danger: true);
        return false;
      }
      return true;
    }
    if (value == 3) return true;
    if (value == 4) return true;
    return true;
  }

  Future<void> next() async {
    if (!validateStep(step)) return;
    if (step < 5) {
      setState(() => step++);
    } else {
      await create();
    }
  }

  Future<void> create() async {
    final title = name.text.trim().isEmpty ? defaultTournamentName(format) : name.text.trim();
    final names = participantNames;
    final matches = draftMatches;
    if (title.length < 2) {
      await showToast(context, 'Pon un nombre a la competición.', danger: true);
      return;
    }
    if (names.length < 2) {
      await showToast(context, 'Añade al menos 2 participantes/equipos.', danger: true);
      return;
    }
    final setupError = TournamentEngineV2.setupError(
      sport: scoringType,
      format: format,
      participantType: teamType,
      participantCount: names.length,
      manualMatchesCount: manualRows.isNotEmpty ? manualRows.length : parseTournamentPairings(pairings.text).length,
    );
    if (setupError != null) {
      await showToast(context, setupError, danger: true);
      return;
    }
    if ((format == 'manual' || pairings.text.trim().isNotEmpty) && matches.isEmpty) {
      await showToast(context, 'Faltan emparejamientos manuales válidos.', danger: true);
      return;
    }

    setState(() => loading = true);
    try {
      final firstStart = DateTime(firstMatchDate.year, firstMatchDate.month, firstMatchDate.day, firstMatchTime.hour, firstMatchTime.minute);
      final tournamentId = await AppData.createTournament(
        widget.group['id'].toString(),
        title,
        format: format,
        teamType: teamType,
        scoringType: scoringType,
        scoringConfig: scoringConfig,
        formatConfig: formatConfig,
        scheduleConfig: scheduleConfig,
        tieBreakers: TournamentEngineV2.defaultTieBreakers(scoringType, format),
        permissionsConfig: TournamentEngineV2.defaultPermissionsConfig(scoringType, format),
        status: scheduleMatches ? 'scheduled' : 'draft',
        startsAt: scheduleMatches ? firstStart : null,
      );
      await AppData.addTournamentTeams(tournamentId, names);
      final created = await AppData.tournament(tournamentId);
      final teams = tournamentTeams(created);
      if (format == 'manual' && manualRows.isNotEmpty) {
        await AppData.createManualMatchRows(tournamentId, teams, manualRows, scheduleConfig: scheduleConfig);
      } else if (format == 'manual' || pairings.text.trim().isNotEmpty) {
        await AppData.createManualMatches(tournamentId, teams, matches, scheduleConfig: scheduleConfig);
      } else {
        await AppData.generateMatches(tournamentId, format, teams, formatConfig: formatConfig, scheduleConfig: scheduleConfig);
      }
      if (addToAgenda && scheduleMatches) {
        await AppData.createAgendaEventsForTournament(widget.group['id'].toString(), tournamentId, title);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: firstMatchDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('es', 'ES'),
    );
    if (value != null) setState(() => firstMatchDate = value);
  }

  Future<void> pickTime() async {
    final value = await showTimePicker(context: context, initialTime: firstMatchTime);
    if (value != null) setState(() => firstMatchTime = value);
  }

  Future<void> addManualDraftRow() async {
    final available = manualEditorParticipants;
    if (available.length < 2) {
      await showToast(context, 'Añade al menos 2 participantes antes de crear partidos.', danger: true);
      return;
    }
    final row = await showTournamentManualDraftDialog(
      context,
      participants: available,
      defaultRound: manualRows.isEmpty ? 1 : manualRows.map((r) => r.round).reduce(max),
      defaultDuration: durationMinutes,
      defaultLocation: location.text,
      defaultCourtName: courtName.text,
      defaultDate: scheduleMatches ? DateTime(firstMatchDate.year, firstMatchDate.month, firstMatchDate.day, firstMatchTime.hour, firstMatchTime.minute) : null,
    );
    if (row != null) setState(() => manualRows.add(row));
  }

  Future<void> editManualDraftRow(int index) async {
    if (index < 0 || index >= manualRows.length) return;
    final row = await showTournamentManualDraftDialog(
      context,
      participants: manualEditorParticipants,
      initial: manualRows[index],
      defaultRound: manualRows[index].round,
      defaultDuration: manualRows[index].durationMinutes,
      defaultLocation: manualRows[index].location,
      defaultCourtName: manualRows[index].courtName,
      defaultDate: manualRows[index].scheduledAt,
    );
    if (row != null) setState(() => manualRows[index] = row);
  }

  void moveManualDraftRow(int index, int delta) {
    final target = index + delta;
    if (index < 0 || target < 0 || index >= manualRows.length || target >= manualRows.length) return;
    setState(() {
      final row = manualRows.removeAt(index);
      manualRows.insert(target, row);
    });
  }

  void duplicateManualDraftRound(int round) {
    final rows = manualRows.where((row) => row.round == round).toList();
    if (rows.isEmpty) return;
    final nextRound = manualRows.fold<int>(0, (value, row) => max(value, row.round)) + 1;
    setState(() {
      manualRows.addAll(rows.map((row) => row.copyWith(round: nextRound, clearScheduledAt: true)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Crear torneo', subtitle: stepSubtitle(step), leading: true),
      const SizedBox(height: 10),
      TournamentStepIndicator(step: step, total: 6),
      const SizedBox(height: 16),
      if (step == 0) _buildTypeStep()
      else if (step == 1) _buildFormatStep()
      else if (step == 2) _buildParticipantsStep()
      else if (step == 3) _buildScoringStep()
      else if (step == 4) _buildCalendarStep()
      else _buildReviewStep(),
      const SizedBox(height: 18),
      Row(children: [
        if (step > 0) ...[
          Expanded(child: SecondaryButton(label: 'Volver', icon: Icons.arrow_back_rounded, onTap: () => setState(() => step--))),
          const SizedBox(width: 10),
        ],
        Expanded(child: PrimaryButton(label: step == 5 ? 'Crear torneo' : 'Siguiente', icon: step == 5 ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded, loading: loading, onTap: next)),
      ]),
    ]));
  }

  Widget _buildTypeStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TournamentCreationHeroCard(),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FieldLabel('Nombre'),
        TextField(controller: name, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: defaultTournamentName(format))),
      ])),
      const SizedBox(height: 12),
      FieldLabel('Primero elige el deporte'),
      const SizedBox(height: 8),
      TournamentSportEmojiPicker(
        value: scoringType,
        onChanged: (value) => setState(() => applyScoringDefaults(value)),
      ),
      const SizedBox(height: 10),
      TournamentValidationCard(format: format, scoringType: scoringType, scoringConfig: scoringConfig),
      const SizedBox(height: 10),
      AppCard(
        color: AppColors.faint,
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(TournamentEngineV2.sportSpec(scoringType).resultLabel, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(TournamentEngineV2.resultContractText(scoringType, format), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
            const SizedBox(height: 8),
            Text('Estadísticas gratis: ${TournamentEngineV2.sportStatsSummary(scoringType)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
          ])),
        ]),
      ),
    ]);
  }

  Widget _buildParticipantsStep() {
    syncTeamTypeForContext();
    final choices = participantTypeChoicesForContext();
    final preview = draftMatches.take(8).toList();
    final isRestricted = choices.length == 1;
    final canAutoFillMembers = format == 'americano' || teamType == 'individual';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel('Quién participa'),
      const SizedBox(height: 8),
      AppCard(
        color: format == 'americano' ? AppColors.tealSoft : AppColors.faint,
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: Icon(format == 'americano' ? Icons.shuffle_rounded : Icons.groups_rounded, color: AppColors.teal, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(participantTypeTitle(), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(participantHelperText(), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
          ])),
        ]),
      ),
      const SizedBox(height: 12),
      if (choices.isNotEmpty) ...[
        FieldLabel(isRestricted ? 'Tipo fijado por el formato' : 'Tipo de participantes'),
        const SizedBox(height: 8),
        TournamentChoiceGrid(
          value: teamType,
          options: choices,
          onChanged: isRestricted ? (_) {} : (v) => setState(() => teamType = v),
        ),
        const SizedBox(height: 14),
      ],
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.teal, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(participantTypeTitle(), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(canAutoFillMembers
                ? 'Elige miembros del grupo tocando un botón. El cuadro de texto queda solo para pegar listas largas.'
                : teamType == 'pareja'
                    ? 'Crea parejas visuales con dos miembros o añade parejas invitadas.'
                    : 'Crea equipos con nombres claros. Después se podrán preparar los partidos.',
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (canAutoFillMembers)
            SizedBox(width: 156, child: SecondaryButton(label: 'Elegir miembros', icon: Icons.group_add_rounded, onTap: addMembersVisualToDraft)),
          if (teamType == 'pareja')
            SizedBox(width: 156, child: SecondaryButton(label: 'Crear pareja', icon: Icons.group_work_rounded, onTap: addPairVisualToDraft)),
          if (teamType == 'equipo')
            SizedBox(width: 156, child: SecondaryButton(label: 'Añadir equipo', icon: Icons.shield_rounded, onTap: addTeamVisualToDraft)),
          SizedBox(width: 156, child: SecondaryButton(label: teamType == 'pareja' ? 'Pareja invitada' : 'Añadir invitado', icon: Icons.person_add_rounded, onTap: addGuestVisualToDraft)),
        ]),
        const SizedBox(height: 12),
        if (participantNames.isEmpty)
          EmptySlim(icon: Icons.groups_rounded, title: 'Sin participantes todavía', body: canAutoFillMembers ? 'Pulsa Elegir miembros para añadir personas del grupo.' : teamType == 'pareja' ? 'Crea parejas o añade una pareja invitada.' : 'Añade equipos para preparar la competición.')
        else ...[
          Row(children: [
            Expanded(child: Text('Preparados', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${participantNames.length}'),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: participantNames.map((name) => TournamentParticipantDraftChip(label: name, onDelete: () => removeParticipantName(name))).toList(),
          ),
        ],
        const SizedBox(height: 10),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Pegar lista manual', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 13)),
            subtitle: const Text('Opción rápida para copiar muchos nombres', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
            children: [
              TextField(
                controller: participants,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: participantHintText(),
                  helperText: 'Un nombre por línea. Ejemplo: Ana / Javi para una pareja.',
                ),
              ),
            ],
          ),
        ),
      ])),
      if (format == 'manual') ...[
        const SizedBox(height: 12),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Selector visual de partidos', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${manualRows.length} partidos'),
          ]),
          const SizedBox(height: 8),
          const Text('Crea cada partido con selectores para evitar errores de texto. Puedes poner jornada, fecha, pista y notas.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'Añadir partido', icon: Icons.add_rounded, onTap: addManualDraftRow)),
            if (manualRows.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(child: SecondaryButton(label: 'Duplicar jornada', icon: Icons.copy_rounded, onTap: () => duplicateManualDraftRound(manualRows.map((r) => r.round).reduce(max)))),
            ],
          ]),
          const SizedBox(height: 12),
          if (manualRows.isEmpty)
            EmptySlim(icon: Icons.table_rows_rounded, title: 'Sin partidos manuales', body: 'Añade participantes y pulsa Añadir partido para crear los cruces.')
          else
            ...List.generate(manualRows.length, (index) => TournamentManualDraftRowCard(
              row: manualRows[index],
              index: index,
              onEdit: () => editManualDraftRow(index),
              onDelete: () => setState(() => manualRows.removeAt(index)),
              onMoveUp: index == 0 ? null : () => moveManualDraftRow(index, -1),
              onMoveDown: index == manualRows.length - 1 ? null : () => moveManualDraftRow(index, 1),
            )),
        ])),
        const SizedBox(height: 12),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Importar cruces desde texto', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${parseTournamentPairings(pairings.text).length} escritos'),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: pairings,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Jornada 1: Equipo Azul vs Los Invencibles\nJornada 1: Ana / Javi vs Marta / Luis',
              helperText: 'Solo se usará si no has añadido partidos con el selector visual.',
            ),
          ),
        ])),
      ] else if (format != 'americano') ...[
        const SizedBox(height: 12),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Cruces manuales opcionales', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${parseTournamentPairings(pairings.text).length} escritos'),
          ]),
          const SizedBox(height: 8),
          const Text('Normalmente la app sortea/genera los cruces. Usa esto solo si quieres controlar los emparejamientos desde el inicio.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 8),
          TextField(
            controller: pairings,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Jornada 1: Equipo Azul vs Los Invencibles\nJornada 1: Ana / Javi vs Marta / Luis',
              helperText: 'Si lo rellenas, la app usará estos cruces en vez del sorteo automático.',
            ),
          ),
        ])),
      ],
      const SizedBox(height: 14),
      SectionHeader(title: format == 'manual' ? 'Partidos preparados' : 'Vista previa'),
      const SizedBox(height: 8),
      if (preview.isEmpty)
        EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin cruces todavía', body: format == 'manual' ? 'Añade partidos con el selector visual o importa cruces.' : 'Añade participantes para ver los primeros cruces.')
      else
        ...preview.map((m) => TournamentDraftMatchTile(match: m)),
    ]);
  }


  Widget _buildFormatStep() {
    final fullRounds = max(0, participantNames.length.isOdd ? participantNames.length : participantNames.length - 1);
    final totalLeagueRounds = fullRounds * max(1, leagueLegs);
    final limitedLeagueRounds = leagueRoundsLimit <= 0 ? totalLeagueRounds : leagueRoundsLimit * max(1, leagueLegs);
    final hasParticipants = participantNames.length >= 2;
    final preview = hasParticipants ? draftMatches.take(8).toList() : <TournamentDraftMatch>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel('Formato de competición'),
      const SizedBox(height: 8),
      TournamentQuickTemplateGrid(
        selected: creationTemplate,
        allowedValues: allowedTemplateValues,
        onChanged: (value) => setState(() => applyQuickTemplate(value)),
      ),
      const SizedBox(height: 12),
      TournamentSimpleFormatSummary(format: format, scoringType: scoringType, teamType: teamType),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(14)), child: Icon(tournamentTemplateIcon(creationTemplate), color: AppColors.red, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tournamentFormatLabel(format), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 3),
            Text(TournamentEngineV2.formatHelp(scoringType, format), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          ])),
        ]),
        const SizedBox(height: 12),
        if (format == 'liga') ...[
          Wrap(spacing: 8, runSpacing: 8, children: [
            TournamentRuleChip(label: scoringTableContractChip(scoringType, scoringConfig)),
            TournamentRuleChip(label: 'Todos contra todos'),
            TournamentRuleChip(label: 'Sorteo automático'),
          ]),
          const SizedBox(height: 10),
          TournamentCounterRow(label: 'Vueltas', value: leagueLegs, min: 1, max: 4, onChanged: (v) => setState(() => leagueLegs = v), helper: leagueLegs == 1 ? 'Solo ida' : '$leagueLegs vueltas'),
          TournamentCounterRow(label: 'Jornadas por vuelta', value: leagueRoundsLimit, min: 0, max: max(1, fullRounds), zeroLabel: 'Todas', onChanged: (v) => setState(() => leagueRoundsLimit = v), helper: leagueRoundsLimit == 0 ? (hasParticipants ? 'Liga completa: $fullRounds por vuelta · $totalLeagueRounds en total' : 'Se calcula al añadir participantes') : '$leagueRoundsLimit por vuelta · $limitedLeagueRounds en total'),
        ] else if (format == 'americano') ...[
          Wrap(spacing: 8, runSpacing: 8, children: const [
            TournamentRuleChip(label: 'Solo jugadores'),
            TournamentRuleChip(label: 'Parejas rotativas'),
            TournamentRuleChip(label: 'Ranking individual'),
            TournamentRuleChip(label: 'Descansos equilibrados'),
          ]),
          const SizedBox(height: 10),
          TournamentCounterRow(label: 'Rondas', value: americanoRounds, min: 1, max: 40, onChanged: (v) => setState(() => americanoRounds = v), helper: hasParticipants ? 'Recomendado: ${recommendedAmericanoRounds(participantNames.length, courtsCount)} rondas' : 'Se recomienda al añadir jugadores'),
          TournamentCounterRow(label: 'Pistas / mesas', value: courtsCount, min: 1, max: 12, onChanged: (v) => setState(() => courtsCount = v), helper: '1 partido por pista y ronda'),
          const SizedBox(height: 8),
          Text(hasParticipants ? americanoRulesText(participantNames.length, courtsCount, americanoRounds) : 'En el siguiente paso añade jugadores individuales. La app intentará que cada ronda tenga parejas distintas antes de repetir.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          if (hasParticipants && participantNames.length >= 4 && americanoRounds != recommendedAmericanoRounds(participantNames.length, courtsCount)) ...[
            const SizedBox(height: 10),
            SecondaryButton(label: 'Usar ${recommendedAmericanoRounds(participantNames.length, courtsCount)} rondas recomendadas', icon: Icons.auto_awesome_rounded, onTap: () => setState(() => americanoRounds = recommendedAmericanoRounds(participantNames.length, courtsCount))),
          ],
        ] else if (format == 'eliminatoria') ...[
          Wrap(spacing: 8, runSpacing: 8, children: [
            TournamentRuleChip(label: randomizePairings ? 'Sorteo automático' : 'Orden como seed'),
            const TournamentRuleChip(label: 'Byes automáticos'),
            const TournamentRuleChip(label: 'Gana y avanza'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Expanded(child: Text('Sortear cruces al crear', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            Switch(value: randomizePairings, activeThumbColor: AppColors.red, onChanged: (v) => setState(() => randomizePairings = v)),
          ]),
          Text(randomizePairings ? 'Recomendado para grupos normales: evita que el orden de escritura favorezca a nadie.' : 'Usa el orden de participantes como cabeza de serie: #1 contra el último, #2 contra el penúltimo. Después podrás cambiar seeds desde Participantes.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
        ] else ...[
          Wrap(spacing: 8, runSpacing: 8, children: const [
            TournamentRuleChip(label: 'Todo editable'),
            TournamentRuleChip(label: 'Selector visual'),
            TournamentRuleChip(label: 'Fechas por partido'),
          ]),
          const SizedBox(height: 8),
          const Text('Manual sirve para torneos raros, eventos de un día o cruces que quieres decidir tú. En el siguiente paso crearás los partidos uno a uno.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
        ],
      ])),
      const SizedBox(height: 12),
      AppCard(
        color: AppColors.tealSoft,
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.group_add_rounded, color: AppColors.teal, size: 19)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(format == 'americano' ? 'Siguiente: jugadores individuales' : format == 'manual' ? 'Siguiente: participantes y selector de partidos' : 'Siguiente: participantes adecuados', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(format == 'americano'
                ? 'No se crean parejas fijas: Grupli las rota ronda a ronda.'
                : !sportSupportsAmericano
                    ? 'Para este deporte se prioriza Liga, Eliminatoria o Manual. Americano se reserva para juegos de parejas rotativas.'
                    : scoringType == 'tennis_padel'
                        ? 'Podrás elegir parejas o jugadores individuales según cómo juguéis.'
                        : format == 'eliminatoria'
                            ? 'Añade equipos/jugadores y Grupli sortea el cuadro.'
                            : 'Añade jugadores, parejas o equipos y prepara los cruces.',
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
          ])),
        ]),
      ),
      if (hasParticipants) ...[
        const SizedBox(height: 14),
        SectionHeader(title: 'Vista previa'),
        const SizedBox(height: 8),
        if (preview.isEmpty)
          EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin cruces todavía', body: 'Revisa participantes o crea los cruces manuales.')
        else
          ...preview.map((m) => TournamentDraftMatchTile(match: m)),
      ],
    ]);
  }


  Widget _buildScoringStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel('Sistema de resultado'),
      const SizedBox(height: 8),
      AppCard(color: AppColors.redSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(scoringEmoji(scoringType), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(child: Text('${scoringResultInputTitle(scoringType, scoringConfig)} · ${scoringTypeLabel(scoringType)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 8),
        Text(TournamentEngineV2.resultContractText(scoringType, format), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          TournamentRuleChip(label: scoringUsesSetMode(scoringType, scoringConfig) ? 'Registrar parciales' : scoringScoreLabel(scoringType, scoringConfig)),
          TournamentRuleChip(label: scoringAllowDraw(scoringType, scoringConfig) ? 'Permite empate' : 'Sin empate'),
          if (scoringUsesGameSetMode(scoringType, scoringConfig)) const TournamentRuleChip(label: 'Juegos para desempate'),
          if (scoringUsesPointSetMode(scoringType, scoringConfig)) const TournamentRuleChip(label: 'Puntos de set'),
        ]),
      ])),
      const SizedBox(height: 12),
      if (format == 'americano')
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ranking Americano', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            scoringUsesGameSetMode(scoringType, scoringConfig)
                ? 'Cada jugador suma los juegos reales que consigue en sus partidos, aunque vaya cambiando de pareja. Las victorias se muestran como apoyo, pero no sustituyen al ranking acumulado.'
                : scoringUsesPointSetMode(scoringType, scoringConfig)
                    ? 'Cada jugador suma los puntos reales de set que consigue en sus partidos. El ranking es individual y las parejas rotan.'
                    : 'Cada jugador suma el marcador real que consigue en sus partidos. El ranking es individual y las parejas rotan.',
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3),
          ),
          if (scoringUsesSetMode(scoringType, scoringConfig)) ...[
            const SizedBox(height: 10),
            TournamentCounterRow(label: 'Parciales por partido', value: bestOf, min: 1, max: 7, onChanged: (v) => setState(() => bestOf = v), helper: 'normal: 1 set/partida'),
          ],
        ]))
      else
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Clasificación', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(scoringConfigFullText(scoringType, scoringConfig), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 10),
          TournamentCounterRow(label: 'Victoria', value: winPoints, min: 0, max: 10, onChanged: (v) => setState(() => winPoints = v)),
          if (scoringAllowDraw(scoringType, scoringConfig)) TournamentCounterRow(label: 'Empate', value: drawPoints, min: 0, max: 10, onChanged: (v) => setState(() => drawPoints = v)),
          TournamentCounterRow(label: 'Derrota', value: lossPoints, min: -3, max: 5, onChanged: (v) => setState(() => lossPoints = v)),
          if (scoringUsesSetMode(scoringType, scoringConfig)) TournamentCounterRow(label: 'Mejor de', value: bestOf, min: 1, max: 7, onChanged: (v) => setState(() => bestOf = v.isEven ? v + 1 : v), helper: 'sets/rondas'),
          if (targetScore > 0 || scoringResultModel(scoringType, scoringConfig) == 'target_points')
            TournamentCounterRow(label: 'Objetivo orientativo', value: targetScore, min: 0, max: 999, zeroLabel: 'Libre', onChanged: (v) => setState(() => targetScore = v)),
        ])),
      const SizedBox(height: 12),
      AppCard(color: AppColors.faint, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Desempates', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(standingsOrderTextForScoring(TournamentEngineV2.defaultTieBreakers(scoringType, format), scoringType, scoringConfig), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
      ])),
    ]);
  }

  Widget _buildCalendarStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel('Calendario de partidos'),
      const SizedBox(height: 8),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Programar fechas', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
          Switch(value: scheduleMatches, activeThumbColor: AppColors.red, onChanged: (v) => setState(() => scheduleMatches = v)),
        ]),
        if (scheduleMatches) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(firstMatchDate), icon: Icons.calendar_today_rounded, onTap: pickDate)),
            const SizedBox(width: 10),
            Expanded(child: SecondaryButton(label: firstMatchTime.format(context), icon: Icons.schedule_rounded, onTap: pickTime)),
          ]),
          const SizedBox(height: 10),
          TournamentCounterRow(label: 'Días entre jornadas', value: daysBetweenRounds, min: 0, max: 30, onChanged: (v) => setState(() => daysBetweenRounds = v)),
          TournamentCounterRow(label: 'Pistas / mesas simultáneas', value: courtsCount, min: 1, max: 12, onChanged: (v) => setState(() => courtsCount = v), helper: courtsCount == 1 ? 'una a la vez' : 'partidos en paralelo'),
        ],
      ])),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Añadir a Agenda del grupo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
          Switch(value: addToAgenda, activeThumbColor: AppColors.red, onChanged: scheduleMatches ? (v) => setState(() => addToAgenda = v) : null),
        ]),
        const SizedBox(height: 8),
        TextField(controller: location, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación opcional', hintText: 'Polideportivo, bar, casa de Ana...')),
        const SizedBox(height: 8),
        TextField(controller: courtName, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: courtsCount <= 1 ? 'Pista / mesa / campo opcional' : 'Nombre base de pistas/mesas', hintText: courtsCount <= 1 ? 'Pista 2, Mesa 1...' : 'Pista, Mesa, Campo...')),
      ])),
      if (scheduleMatches) ...[
        const SizedBox(height: 12),
        SectionHeader(title: 'Vista previa de calendario'),
        const SizedBox(height: 8),
        if (schedulePreviewRows.isEmpty)
          EmptySlim(icon: Icons.calendar_month_rounded, title: 'Sin vista previa', body: 'Añade participantes o emparejamientos para ver fechas antes de crear.')
        else
          ...schedulePreviewRows.take(8).map((row) => TournamentSchedulePreviewTile(row: row)),
        if (schedulePreviewRows.length > 8)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('+ ${schedulePreviewRows.length - 8} partidos más', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
      ],
    ]);
  }

  Widget _buildReviewStep() {
    final title = name.text.trim().isEmpty ? defaultTournamentName(format) : name.text.trim();
    final names = participantNames;
    final matches = draftMatches;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(color: AppColors.faint, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TournamentReviewRow(label: 'Nombre', value: title),
        TournamentReviewRow(label: 'Formato', value: tournamentFormatLabel(format)),
        TournamentReviewRow(label: 'Participantes', value: '${names.length} · ${participantTypeTitle()}'),
        TournamentReviewRow(label: 'Partidos previstos', value: '${matches.length}'),
        TournamentReviewRow(label: 'Resultado', value: '${scoringTypeLabel(scoringType)} · ${scoringConfigShortText(scoringType, scoringConfig)}'),
        TournamentReviewRow(label: 'Estadísticas', value: TournamentEngineV2.sportStatsSummary(scoringType)),
        TournamentReviewRow(label: 'Calendario', value: scheduleMatches ? '${DateFormat('d MMM', 'es_ES').format(firstMatchDate)} · ${firstMatchTime.format(context)}' : 'Sin fechas'),
        TournamentReviewRow(label: 'Agenda', value: addToAgenda && scheduleMatches ? 'Sí' : 'No'),
      ])),
      const SizedBox(height: 12),
      SectionHeader(title: 'Primeros partidos'),
      const SizedBox(height: 8),
      if (matches.isEmpty)
        EmptySlim(icon: Icons.info_outline_rounded, title: 'Se generarán al crear', body: 'La app generará los cruces con los participantes añadidos.')
      else if (scheduleMatches)
        ...schedulePreviewRows.take(6).map((row) => TournamentSchedulePreviewTile(row: row))
      else
        ...matches.take(6).map((m) => TournamentDraftMatchTile(match: m)),
    ]);
  }
}

class TournamentDetailSimpleScreen extends StatefulWidget {
  final String tournamentId;
  final Map<String, dynamic> group;
  const TournamentDetailSimpleScreen({super.key, required this.tournamentId, required this.group});

  @override
  State<TournamentDetailSimpleScreen> createState() => _TournamentDetailSimpleScreenState();
}

class _TournamentDetailSimpleScreenState extends State<TournamentDetailSimpleScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? tournament;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool soft = false}) async {
    if (!mounted) return;
    if (!soft) setState(() { loading = true; error = null; });
    try {
      final data = await AppData.tournament(widget.tournamentId).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        tournament = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = humanError(e);
      });
    }
  }

  String get currentFormat => AppData.text(tournament?['format'], 'liga');
  String get currentTeamType => AppData.text(tournament?['team_type'], 'equipo');
  String get currentScoringType => AppData.text(tournament?['scoring_type'], 'general');

  bool get currentCanAddMembers => currentFormat == 'americano' || currentTeamType == 'individual';
  bool get currentCanCreatePairs => currentFormat != 'americano' && currentTeamType == 'pareja';

  String get currentParticipantAddTitle {
    if (currentFormat == 'americano') return 'Añadir jugadores';
    if (currentTeamType == 'pareja') return 'Añadir parejas';
    if (currentTeamType == 'individual') return 'Añadir jugadores';
    return 'Añadir equipos';
  }

  String get currentParticipantAddHint {
    if (currentFormat == 'americano') return 'Ana\nJavi\nMarta\nLuis';
    if (currentTeamType == 'pareja') return 'Ana / Javi\nMarta / Luis\nCris / Pablo';
    if (currentTeamType == 'individual') return 'Ana\nJavi\nMarta\nLuis';
    if (currentScoringType == 'football') return 'Los Pingüinos FC\nEquipo Azul\nLa Banda del Domingo';
    return 'Equipo Azul\nLos Invencibles\nGrupo del Viernes';
  }

  String get currentParticipantAddHelp {
    if (currentFormat == 'americano') return 'Un jugador por línea. En Americano Grupli crea parejas rotativas automáticamente.';
    if (currentTeamType == 'pareja') return 'Una pareja por línea. Usa el formato Ana / Javi para que se entienda bien.';
    if (currentTeamType == 'individual') return 'Un jugador por línea.';
    return 'Un equipo por línea. No añadas jugadores sueltos si esta competición es por equipos.';
  }

  Future<void> addParticipants() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentParticipantAddTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 10,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: currentParticipantAddHint,
              helperText: currentParticipantAddHelp,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Añadir')),
        ],
      ),
    );
    controller.dispose();
    final names = parseTournamentParticipantNames(value ?? '');
    if (names.isEmpty) return;
    try {
      await AppData.addTournamentTeams(widget.tournamentId, names);
      await load(soft: true);
      if (mounted) await showToast(context, 'Participantes añadidos. Regenera o añade partidos si lo necesitas.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> addGroupMembersVisual() async {
    if (!currentCanAddMembers) {
      await showToast(context, currentTeamType == 'pareja'
          ? 'Esta competición usa parejas. Crea las parejas desde el botón Pareja o escríbelas como Ana / Javi.'
          : 'Esta competición usa equipos. Añade nombres de equipos en vez de cargar miembros sueltos.',
          danger: true);
      return;
    }
    try {
      final members = await AppData.members(widget.group['id'].toString());
      if (!mounted) return;
      final selected = await showTournamentMemberPickerDialog(context, members: members);
      if (selected == null || selected.isEmpty) return;
      final added = await AppData.addTournamentTeamsFromMembers(widget.tournamentId, selected);
      await load(soft: true);
      if (mounted) {
        await showToast(
          context,
          added == 0 ? 'No se añadieron miembros nuevos: ya estaban en el torneo.' : '$added participante${added == 1 ? '' : 's'} añadidos.',
          danger: added == 0,
        );
      }
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> createPairVisual() async {
    if (!currentCanCreatePairs) {
      await showToast(context, currentFormat == 'americano'
          ? 'En Americano no se crean parejas fijas: Grupli las rota ronda a ronda.'
          : 'Esta competición no está configurada como parejas.',
          danger: true);
      return;
    }
    try {
      final members = await AppData.members(widget.group['id'].toString());
      if (!mounted) return;
      final pair = await showTournamentPairCreatorDialog(context, members: members);
      if (pair == null) return;
      await AppData.addTournamentPairFromMembers(widget.tournamentId, pair.first, pair.second, customName: pair.name);
      await load(soft: true);
      if (mounted) await showToast(context, 'Pareja creada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> editTournamentRules() async {
    final t = tournament;
    if (t == null) return;
    final matches = tournamentMatches(t);
    final hasResults = matches.any(matchCountsForStandings);
    final edited = await showTournamentEditorDialog(context, tournament: t, hasResults: hasResults);
    if (edited == null) return;

    if (hasResults && edited.rulesChanged) {
      await showToast(context, 'Hay resultados registrados. Para proteger la tabla solo se permite cambiar el nombre.', danger: true);
      return;
    }

    try {
      await AppData.updateTournamentEditor(
        widget.tournamentId,
        name: edited.name,
        scoringType: edited.scoringType,
        scoringConfig: edited.scoringConfig,
        formatConfig: edited.formatConfig,
        tieBreakers: edited.tieBreakers,
      );
      await load(soft: true);
      if (mounted) await showToast(context, 'Torneo actualizado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> showFullHistory() async {
    final t = tournament;
    if (t == null) return;
    await showTournamentHistoryDialog(context, tournament: t, matches: tournamentMatches(t), teams: tournamentTeams(t));
  }

  Future<void> addManualMatches() async {
    final t = tournament;
    if (t == null) return;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir partidos manuales'),
        content: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 10,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Jornada 2: Equipo Azul vs Equipo Rojo\nJornada 2: Ana / Javi vs Marta / Luis'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Añadir')),
        ],
      ),
    );
    controller.dispose();
    final pairs = parseTournamentPairings(value ?? '');
    if (pairs.isEmpty) return;
    try {
      await AppData.addManualMatches(widget.tournamentId, tournamentTeams(t), pairs, scheduleConfig: tournamentScheduleConfig(t));
      await load(soft: true);
      if (mounted) await showToast(context, 'Partidos añadidos.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> regenerate() async {
    final t = tournament;
    if (t == null) return;
    final format = AppData.text(t['format'], 'liga');
    if (format == 'manual') {
      await addManualMatches();
      return;
    }
    final teams = tournamentTeams(t);
    if (teams.length < 2) {
      await showToast(context, 'Añade al menos 2 participantes.', danger: true);
      return;
    }
    final matches = tournamentMatches(t);
    final results = matches.where(matchCountsForStandings).length;
    if (results > 0) {
      await showToast(context, 'No se puede regenerar una liga con resultados. Borra primero los resultados o crea otra competición.', danger: true);
      return;
    }
    if (matches.isNotEmpty) {
      final ok = await confirmAction(
        context,
        title: '¿Regenerar calendario?',
        body: 'Se borrarán los partidos pendientes actuales para crear un calendario nuevo. Los resultados ya registrados bloquean esta acción.',
        danger: true,
        confirmLabel: 'Regenerar',
      );
      if (ok != true) return;
    }
    try {
      await AppData.generateMatches(widget.tournamentId, format, teams, formatConfig: tournamentFormatConfig(t), scheduleConfig: tournamentScheduleConfig(t));
      await load(soft: true);
      if (mounted) await showToast(context, 'Calendario generado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> nextRound() async {
    final t = tournament;
    if (t == null) return;
    try {
      await AppData.generateNextEliminationRound(widget.tournamentId, tournamentMatches(t));
      await load(soft: true);
      if (mounted) await showToast(context, 'Siguiente ronda generada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> thirdPlace() async {
    final t = tournament;
    if (t == null) return;
    try {
      await AppData.generateThirdPlaceMatch(widget.tournamentId, tournamentMatches(t));
      await load(soft: true);
      if (mounted) await showToast(context, 'Partido por el tercer puesto creado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> reprogramTournamentCalendar() async {
    final t = tournament;
    if (t == null) return;
    await showTournamentBulkScheduleDialog(
      context,
      tournament: t,
      group: widget.group,
      teams: tournamentTeams(t),
      matches: tournamentMatches(t),
      onChanged: () => load(soft: true),
    );
  }

  Future<void> deleteTournament() async {
    final ok = await confirmAction(
      context,
      title: '¿Eliminar competición?',
      body: 'Se borrarán participantes, partidos y resultados. Esta acción no se puede deshacer.',
      danger: true,
      confirmLabel: 'Eliminar',
    );
    if (ok != true) return;
    try {
      await AppData.deleteTournament(widget.tournamentId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> setStatus(String status) async {
    try {
      await AppData.updateTournamentStatus(widget.tournamentId, status);
      await load(soft: true);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final teams = t == null ? <Map<String, dynamic>>[] : tournamentTeams(t);
    final matches = t == null ? <Map<String, dynamic>>[] : tournamentMatches(t);
    final scoringType = t == null ? 'general' : AppData.text(t['scoring_type'], 'general');
    final scoringConfig = t == null ? scoringConfigForType('general') : resolvedScoringConfig(scoringType, t['scoring_config']);
    final tieBreakers = t == null ? defaultTieBreakers(scoringType) : tournamentTieBreakers(t, scoringType);
    final standings = calculateStandings(teams, matches, scoringType: scoringType, scoringConfig: scoringConfig, tieBreakers: tieBreakers);
    final format = t == null ? 'liga' : AppData.text(t['format'], 'liga');
    final played = matches.where(matchCountsForStandings).length;
    final pending = matches.length - played;

    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: t == null ? 'Competición' : AppData.text(t['name'], 'Competición'), subtitle: t == null ? 'Cargando...' : '${tournamentFormatLabel(format)} · ${teamTypeLabel(AppData.text(t['team_type'], 'equipo'))} · Jornada ${currentTournamentRound(matches)}', leading: true),
      const SizedBox(height: 14),
      if (loading && t == null)
        const CenterLoader(label: 'Cargando competición...')
      else if (error != null && t == null)
        ErrorBlock(message: error!, onRetry: () => load())
      else ...[
        TournamentDetailHero(
          tournament: t ?? {},
          leader: standings.isEmpty ? null : standings.first,
          teams: teams.length,
          played: played,
          total: matches.length,
          pending: pending,
          onAdd: addParticipants,
          onGenerate: regenerate,
        ),
        const SizedBox(height: 12),
        TournamentDetailNextStepCard(
          matches: matches,
          teams: teams,
          standings: standings,
          format: format,
          onGenerate: regenerate,
          onAddParticipants: addParticipants,
          onBulkSchedule: reprogramTournamentCalendar,
        ),
        const SizedBox(height: 12),
        TournamentTabsBar(index: tab, format: format, onChanged: (i) => setState(() => tab = i)),
        const SizedBox(height: 14),
        if (tab == 0)
          TournamentOverviewPanel(
            tournament: t ?? {},
            teams: teams,
            matches: matches,
            standings: standings,
            onAddParticipants: addParticipants,
            onGenerate: regenerate,
            onManualMatches: addManualMatches,
            onBulkSchedule: reprogramTournamentCalendar,
            onNextRound: format == 'eliminatoria' ? nextRound : null,
            onChanged: () => load(soft: true),
          )
        else if (tab == 1)
          TournamentMatchesPanel(
            tournament: t ?? {},
            group: widget.group,
            matches: matches,
            teams: teams,
            scoringType: scoringType,
            scoringConfig: scoringConfig,
            onBulkSchedule: reprogramTournamentCalendar,
            onChanged: () => load(soft: true),
          )
        else if (tab == 2)
          format == 'eliminatoria'
          ? TournamentEliminationBracketPanel(
                  tournament: t ?? {},
                  group: widget.group,
                  matches: matches,
                  teams: teams,
                  scoringType: scoringType,
                  scoringConfig: scoringConfig,
                  onNextRound: nextRound,
                  onThirdPlace: thirdPlace,
                  onChanged: () => load(soft: true),
                )
              : TournamentStandingsPanel(standings: standings, matches: matches, tieBreakers: tieBreakers, format: format, scoringType: scoringType, scoringConfig: scoringConfig)
        else if (tab == 3)
          TournamentStatsPanel(standings: standings, matches: matches, teams: teams, format: format, scoringType: scoringType, scoringConfig: scoringConfig)
        else if (tab == 4)
          TournamentTeamsPanel(
            teams: teams,
            matches: matches,
            format: format,
            teamType: AppData.text(t?['team_type'], 'equipo'),
            scoringType: scoringType,
            showSeeds: format == 'eliminatoria',
            onChanged: () => load(soft: true),
            onAdd: addParticipants,
            onAddMembers: addGroupMembersVisual,
            onCreatePair: createPairVisual,
          )
        else
          TournamentSettingsPanel(
            tournament: t ?? {},
            matches: matches,
            onRegenerate: regenerate,
            onManualMatches: addManualMatches,
            onBulkSchedule: reprogramTournamentCalendar,
            onAddParticipants: addParticipants,
            onCheckIn: () => showTournamentCheckInDialog(context, teams: teams),
            onEditTournament: editTournamentRules,
            onHistory: showFullHistory,
            onSetStatus: setStatus,
            onDelete: deleteTournament,
          ),
        const SizedBox(height: 16),
      ],
    ]));
  }
}

class TournamentDashboardMatch {
  final Map<String, dynamic> tournament;
  final Map<String, dynamic> match;
  final String teamA;
  final String teamB;
  final bool played;
  const TournamentDashboardMatch({required this.tournament, required this.match, required this.teamA, required this.teamB, required this.played});
}

class TournamentDraftMatch {
  final int round;
  final String teamAName;
  final String teamBName;
  const TournamentDraftMatch({required this.round, required this.teamAName, required this.teamBName});
}

class TournamentManualDraftRow {
  final int round;
  final String teamAName;
  final String teamBName;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String location;
  final String courtName;
  final String notes;
  const TournamentManualDraftRow({
    required this.round,
    required this.teamAName,
    required this.teamBName,
    this.scheduledAt,
    this.durationMinutes = 60,
    this.location = '',
    this.courtName = '',
    this.notes = '',
  });

  TournamentDraftMatch get draftMatch => TournamentDraftMatch(round: round, teamAName: teamAName, teamBName: teamBName);

  TournamentManualDraftRow copyWith({
    int? round,
    String? teamAName,
    String? teamBName,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    int? durationMinutes,
    String? location,
    String? courtName,
    String? notes,
  }) => TournamentManualDraftRow(
    round: round ?? this.round,
    teamAName: teamAName ?? this.teamAName,
    teamBName: teamBName ?? this.teamBName,
    scheduledAt: clearScheduledAt ? null : scheduledAt ?? this.scheduledAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    location: location ?? this.location,
    courtName: courtName ?? this.courtName,
    notes: notes ?? this.notes,
  );
}

class TournamentSchedulePreviewRow {
  final TournamentDraftMatch match;
  final DateTime? scheduledAt;
  final String courtName;
  const TournamentSchedulePreviewRow({required this.match, this.scheduledAt, this.courtName = ''});
}

class TournamentGroupHeader extends StatelessWidget {
  final String subtitle;
  const TournamentGroupHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.navyDeep,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 25),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Torneos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -.6)),
        const SizedBox(height: 4),
        Text(
          'Competiciones de $subtitle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ])),
    ]),
  );
}

class TournamentSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  const TournamentSectionHeader({super.key, required this.title, this.action});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(99))),
    const SizedBox(width: 8),
    Expanded(child: Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16))),
    if (action != null) Text(action!, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800, fontSize: 12)),
  ]);
}


class TournamentUxCommandCenter extends StatelessWidget {
  final int activeCount;
  final int finishedCount;
  final int nextCount;
  final int latestResults;
  final VoidCallback onCreate;
  const TournamentUxCommandCenter({
    super.key,
    required this.activeCount,
    required this.finishedCount,
    required this.nextCount,
    required this.latestResults,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivity = activeCount > 0 || nextCount > 0 || latestResults > 0;
    final title = hasActivity ? 'Qué toca ahora' : 'Empieza una competición clara';
    final body = nextCount > 0
        ? '$nextCount ${nextCount == 1 ? 'partido pendiente' : 'partidos pendientes'} para revisar. Lo importante queda arriba, sin esconderlo entre tablas.'
        : activeCount > 0
            ? '$activeCount ${activeCount == 1 ? 'competición activa' : 'competiciones activas'} en marcha. Entra para registrar resultados o ajustar jornadas.'
            : 'Crea una liga, eliminatoria, americano o manual. Grupli ordena partidos, tabla y resultados sin hacerlo pesado.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        color: AppColors.surfaceWarm,
        accentColor: AppColors.navTournaments,
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: AppColors.humanRadius, border: Border.all(color: const Color(0x18C75B4C))),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.navTournaments, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17.5, height: 1.08, letterSpacing: -.2)),
              const SizedBox(height: 5),
              Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.32, fontSize: 13.2)),
            ])),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TournamentMiniMetric(label: 'Activas', value: '$activeCount', color: AppColors.navTournaments)),
            const SizedBox(width: 8),
            Expanded(child: TournamentMiniMetric(label: 'Pendientes', value: '$nextCount', color: AppColors.amber)),
            const SizedBox(width: 8),
            Expanded(child: TournamentMiniMetric(label: 'Finalizadas', value: '$finishedCount', color: AppColors.blue)),
          ]),
          const SizedBox(height: 14),
          PrimaryButton(label: 'Crear torneo o liga', icon: Icons.add_rounded, onTap: onCreate),
        ]),
      ),
    );
  }
}

class TournamentMiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const TournamentMiniMetric({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: AppColors.humanRadius, border: Border.all(color: color.withOpacity(.18))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
      const SizedBox(height: 3),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 10.5, fontWeight: FontWeight.w800)),
    ]),
  );
}

class TournamentDetailNextStepCard extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> teams;
  final List<TeamStanding> standings;
  final String format;
  final VoidCallback onGenerate;
  final VoidCallback onAddParticipants;
  final VoidCallback onBulkSchedule;
  const TournamentDetailNextStepCard({
    super.key,
    required this.matches,
    required this.teams,
    required this.standings,
    required this.format,
    required this.onGenerate,
    required this.onAddParticipants,
    required this.onBulkSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final played = matches.where(matchCountsForStandings).length;
    final pending = matches.length - played;
    final unscheduled = matches.where((m) => AppData.text(m['scheduled_at']).isEmpty).length;
    final needsTeams = teams.length < 2;
    final title = needsTeams
        ? 'Faltan participantes'
        : matches.isEmpty
            ? 'Falta crear el calendario'
            : unscheduled > 0
                ? 'Faltan fechas por poner'
                : pending > 0
                    ? 'Hay resultados pendientes'
                    : 'Competición lista para revisar';
    final body = needsTeams
        ? 'Añade al menos dos participantes para poder generar partidos sin confusión.'
        : matches.isEmpty
            ? 'Genera partidos cuando tengas equipos y reglas claras. Si es manual, podrás ajustarlos después.'
            : unscheduled > 0
                ? '$unscheduled ${unscheduled == 1 ? 'partido no tiene fecha' : 'partidos no tienen fecha'}. Mueve la jornada completa o ajusta fechas en bloque.'
                : pending > 0
                    ? '$pending ${pending == 1 ? 'partido espera resultado' : 'partidos esperan resultado'}. Entra en Partidos y registra solo lo necesario.'
                    : standings.isEmpty ? 'No hay tabla disponible todavía.' : 'El líder actual es ${standings.first.name}. Revisa tabla, stats o finaliza cuando esté todo claro.';
    final icon = needsTeams
        ? Icons.group_add_rounded
        : matches.isEmpty
            ? Icons.auto_awesome_motion_rounded
            : unscheduled > 0
                ? Icons.event_repeat_rounded
                : pending > 0
                    ? Icons.sports_score_rounded
                    : Icons.verified_rounded;
    final actionLabel = needsTeams
        ? 'Añadir participantes'
        : matches.isEmpty
            ? 'Generar partidos'
            : unscheduled > 0
                ? 'Programar fechas'
                : pending > 0
                    ? 'Ver partidos'
                    : 'Revisar tabla';
    final action = needsTeams
        ? onAddParticipants
        : matches.isEmpty
            ? onGenerate
            : unscheduled > 0
                ? onBulkSchedule
                : () {};
    return AppCard(
      color: AppColors.surfaceWarm,
      accentColor: AppColors.navTournaments,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: AppColors.humanRadius), child: Icon(icon, color: AppColors.navTournaments, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15.5, height: 1.1)),
          const SizedBox(height: 5),
          Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.32, fontSize: 12.8)),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            _TournamentSignalChip(label: '${teams.length} participantes', color: AppColors.blue),
            _TournamentSignalChip(label: '${matches.length} partidos', color: AppColors.navTournaments),
            _TournamentSignalChip(label: '$pending pendientes', color: AppColors.amber),
            _TournamentSignalChip(label: tournamentFormatLabel(format), color: AppColors.teal),
          ]),
        ])),
        const SizedBox(width: 8),
        if (!needsTeams && matches.isNotEmpty && unscheduled == 0)
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted)
        else
          TextButton(onPressed: action, child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
      ]),
    );
  }
}

class _TournamentSignalChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TournamentSignalChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(.14))),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10.5)),
  );
}

class TournamentActiveCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback onTap;
  final bool compact;
  const TournamentActiveCard({super.key, required this.tournament, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final teams = tournamentTeams(tournament);
    final matches = tournamentMatches(tournament);
    final played = matches.where(matchCountsForStandings).length;
    final status = AppData.text(tournament['status'], 'active');
    final progress = matches.isEmpty ? 0.0 : (played / matches.length).clamp(0.0, 1.0);
    final scoring = AppData.text(tournament['scoring_type'], 'general');
    final names = teamNameMap(teams);
    final pendingMatches = matches.where((m) => AppData.text(m['status'], 'pending') != 'played').toList()
      ..sort((a, b) {
        final dateA = AppData.text(a['scheduled_at']);
        final dateB = AppData.text(b['scheduled_at']);
        if (dateA.isNotEmpty || dateB.isNotEmpty) return dateA.compareTo(dateB);
        return AppData.intValue(a['round']).compareTo(AppData.intValue(b['round']));
      });
    final next = pendingMatches.isNotEmpty ? pendingMatches.first : null;
    final nextText = matches.isEmpty
        ? 'Sin partidos creados todavía'
        : next == null
            ? 'Todos los partidos jugados'
            : 'Próximo: ${tournamentMatchSideName(next, names, true)} vs ${tournamentMatchSideName(next, names, false)}';
    final progressText = matches.isEmpty ? '${teams.length} participantes' : '$played de ${matches.length} partidos jugados';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(13),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          TournamentIconBadge(scoringType: scoring, finished: status == 'finished'),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(tournament['name'], 'Competición'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15.5, height: 1.08)),
            const SizedBox(height: 6),
            Text(nextText, maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.22)),
            const SizedBox(height: 7),
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: tournamentStatusColor(status), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Expanded(child: Text(tournamentStatusLabel(status), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: tournamentStatusColor(status), fontWeight: FontWeight.w900, fontSize: 11.5))),
              Text(progressText, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11.5)),
            ]),
            if (!compact && matches.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 4, color: AppColors.green, backgroundColor: AppColors.lineSoft)),
            ],
          ])),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class TournamentDashboardMatchCard extends StatelessWidget {
  final TournamentDashboardMatch item;
  final VoidCallback onTap;
  const TournamentDashboardMatchCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = item.played ? '${AppData.intValue(item.match['score_a'])} - ${AppData.intValue(item.match['score_b'])}' : 'Pendiente';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(children: [
          SizedBox(width: 44, child: Text('J${AppData.intValue(item.match['round'], 1)}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 12))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(item.tournament['name'], 'Torneo'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 2),
            Text('${item.teamA}  vs  ${item.teamB}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 2),
            Text(tournamentMatchDateText(item.match), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 10)),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(color: item.played ? AppColors.greenSoft : AppColors.orangeSoft, borderRadius: BorderRadius.circular(999)),
            child: Text(score, style: TextStyle(color: item.played ? AppColors.green : AppColors.orange, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class TournamentIconBadge extends StatelessWidget {
  final String scoringType;
  final bool finished;
  const TournamentIconBadge({super.key, required this.scoringType, this.finished = false});
  @override
  Widget build(BuildContext context) {
    final icon = switch (scoringType) {
      'football' => Icons.sports_soccer_rounded,
      'tennis_padel' => Icons.sports_tennis_rounded,
      'basketball' => Icons.sports_basketball_rounded,
      'cards_mus' => Icons.style_rounded,
      _ => Icons.emoji_events_rounded,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: finished ? AppColors.faint : AppColors.navyDeep, borderRadius: BorderRadius.circular(15)),
      child: Icon(icon, color: finished ? AppColors.muted : Colors.white, size: 24),
    );
  }
}

class TournamentCleanEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const TournamentCleanEmptyState({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 58, height: 58, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.emoji_events_rounded, color: AppColors.teal, size: 29)),
      const SizedBox(height: 14),
      const Text('Todavía no hay competiciones', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -.2)),
      const SizedBox(height: 6),
      const Text('Crea una liga, una eliminatoria o un torneo manual. Grupli te ayudará con los partidos, resultados y clasificación.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.35)),
      const SizedBox(height: 16),
      PrimaryButton(label: 'Crear torneo o liga', icon: Icons.add_rounded, onTap: onCreate),
    ]),
  );
}

class TournamentEmptyTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const TournamentEmptyTip({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.blue, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.2), children: [
        TextSpan(text: '$title: ', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        TextSpan(text: body),
      ]))),
    ]),
  );
}

class TournamentEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const TournamentEmptyState({super.key, required this.onCreate});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 54, height: 54, decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.emoji_events_rounded, color: AppColors.red)),
      const SizedBox(height: 12),
      const Text('Crea tu primer torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 5),
      const Text('Liga, eliminatoria, americano o manual. Con partidos, tabla y estadísticas.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
      const SizedBox(height: 14),
      PrimaryButton(label: 'Crear torneo o liga', icon: Icons.add_rounded, onTap: onCreate),
    ]),
  );
}

class TournamentStepIndicator extends StatelessWidget {
  final int step;
  final int total;
  const TournamentStepIndicator({super.key, required this.step, this.total = 5});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(total, (index) {
    final selected = index == step;
    final done = index < step;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: selected ? 27 : 22,
      height: selected ? 27 : 22,
      decoration: BoxDecoration(color: selected || done ? AppColors.red : AppColors.faint, shape: BoxShape.circle, border: Border.all(color: selected || done ? AppColors.red : AppColors.line)),
      child: Center(child: Text('${index + 1}', style: TextStyle(color: selected || done ? Colors.white : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w900))),
    );
  }));
}


class TournamentCreationHeroCard extends StatelessWidget {
  const TournamentCreationHeroCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.navyDeep,
    padding: const EdgeInsets.all(15),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('🏆', style: TextStyle(fontSize: 25))),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Crea una competición bien configurada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
        SizedBox(height: 5),
        Text('Primero elige el deporte. Después Grupli adapta formato, resultados y tabla.', style: TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.25)),
      ])),
    ]),
  );
}

IconData tournamentTemplateIcon(String value) {
  switch (value) {
    case 'americano_padel':
      return Icons.sync_alt_rounded;
    case 'quick_cup':
      return Icons.account_tree_rounded;
    case 'manual_day':
      return Icons.tune_rounded;
    case 'league':
    default:
      return Icons.table_chart_rounded;
  }
}

class TournamentQuickTemplate {
  final String value;
  final String emoji;
  final String title;
  final String body;
  final String badge;
  const TournamentQuickTemplate(this.value, this.emoji, this.title, this.body, {this.badge = ''});
}

class TournamentQuickTemplateGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final List<String>? allowedValues;
  const TournamentQuickTemplateGrid({super.key, required this.selected, required this.onChanged, this.allowedValues});

  static const templates = [
    TournamentQuickTemplate('league', '', 'Liga', 'Jornadas y clasificación'),
    TournamentQuickTemplate('americano_padel', '', 'Americano', 'Rondas y ranking individual'),
    TournamentQuickTemplate('quick_cup', '', 'Eliminatoria', 'Cuadro, semifinal y final'),
    TournamentQuickTemplate('manual_day', '', 'Manual', 'Tú decides los partidos'),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleTemplates = allowedValues == null
        ? templates
        : templates.where((item) => allowedValues!.contains(item.value)).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visibleTemplates.map((item) {
        final active = selected == item.value;
      return InkWell(
        onTap: () => onChanged(item.value),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 154,
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? AppColors.redSoft : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: active ? AppColors.red : AppColors.line),
            boxShadow: active ? [BoxShadow(color: AppColors.red.withOpacity(.10), blurRadius: 16, offset: const Offset(0, 8))] : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: active ? AppColors.red : AppColors.faint, borderRadius: BorderRadius.circular(12)),
                child: Icon(tournamentTemplateIcon(item.value), color: active ? Colors.white : AppColors.muted, size: 18),
              ),
              const Spacer(),
              if (item.badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(999)),
                  child: Text(item.badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
                ),
            ]),
            const SizedBox(height: 8),
            Text(item.title, style: TextStyle(color: active ? AppColors.red : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13.5)),
            const SizedBox(height: 3),
            Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11, height: 1.2)),
          ]),
        ),
      );
      }).toList(),
    );
  }
}

class TournamentAdvancedToggleCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const TournamentAdvancedToggleCard({super.key, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) => AppCard(
    color: enabled ? AppColors.orangeSoft : AppColors.faint,
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Icon(enabled ? Icons.tune_rounded : Icons.auto_awesome_rounded, color: enabled ? AppColors.orange : AppColors.teal),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(enabled ? 'Modo avanzado activo' : 'Modo rápido recomendado', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(enabled ? 'Puedes tocar formato, rondas, vueltas, cruces y reglas.' : 'Sigues los mismos pasos, pero la app oculta ajustes técnicos y aplica valores seguros.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      Switch(value: enabled, activeThumbColor: AppColors.orange, onChanged: onChanged),
    ]),
  );
}

class TournamentQuickModeInfoCard extends StatelessWidget {
  const TournamentQuickModeInfoCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tealSoft,
    padding: const EdgeInsets.all(11),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
      SizedBox(width: 9),
      Expanded(child: Text(
        'Modo rápido: eliges Liga, Americano, Eliminatoria o Manual y sigues el mismo proceso, pero sin ajustes técnicos innecesarios.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12),
      )),
    ]),
  );
}

class TournamentSimpleFormatSummary extends StatelessWidget {
  final String format;
  final String scoringType;
  final String teamType;
  const TournamentSimpleFormatSummary({super.key, required this.format, required this.scoringType, required this.teamType});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tealSoft,
    padding: const EdgeInsets.all(12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Center(child: Text(scoringEmoji(scoringType), style: const TextStyle(fontSize: 23)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${scoringTypeLabel(scoringType)} · ${tournamentFormatLabel(format)} · ${teamTypeLabel(teamType)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(tournamentFormatSubtitle(format), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25, fontSize: 12)),
        const SizedBox(height: 4),
        Text(tournamentClassificationSummary(format, scoringType), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 11.5)),
      ])),
    ]),
  );
}

class TournamentSimpleFormatConfigCard extends StatelessWidget {
  final String format;
  final int rounds;
  final int courts;
  final ValueChanged<int> onRoundsChanged;
  final ValueChanged<int> onCourtsChanged;
  const TournamentSimpleFormatConfigCard({super.key, required this.format, required this.rounds, required this.courts, required this.onRoundsChanged, required this.onCourtsChanged});

  @override
  Widget build(BuildContext context) {
    if (format == 'manual' || format == 'eliminatoria') {
      return AppCard(color: AppColors.faint, child: Text(format == 'manual'
          ? 'Manual: añade cruces con selectores y fecha individual. Puedes importar texto si prefieres.'
          : 'Eliminatoria: la app crea cuadro, byes, cabezas de serie, siguiente ronda y tercer puesto.',
        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3),
      ));
    }
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(format == 'americano' ? 'Configuración rápida de americano' : 'Configuración rápida de liga', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      if (format == 'americano')
        TournamentCounterRow(label: 'Rondas', value: rounds <= 0 ? 5 : rounds, min: 1, max: 20, onChanged: onRoundsChanged, helper: 'ranking individual')
      else
        TournamentCounterRow(label: 'Jornadas límite', value: rounds, min: 0, max: 30, zeroLabel: 'Todas', onChanged: onRoundsChanged, helper: 'déjalo en Todas para liga completa'),
      TournamentCounterRow(label: 'Pistas / mesas', value: courts, min: 1, max: 12, onChanged: onCourtsChanged, helper: courts <= 1 ? 'una a la vez' : 'en paralelo'),
    ]));
  }
}

class TournamentSportPreset {
  final String value;
  final String emoji;
  final String title;
  final String body;
  const TournamentSportPreset(this.value, this.emoji, this.title, this.body);
}

class TournamentSportEmojiPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const TournamentSportEmojiPicker({super.key, required this.value, required this.onChanged});

  static const presets = [
    TournamentSportPreset('football', '⚽', 'Fútbol', 'Goles'),
    TournamentSportPreset('tennis_padel', '🎾', 'Pádel/Tenis', 'Sets'),
    TournamentSportPreset('basketball', '🏀', 'Baloncesto', 'Puntos'),
    TournamentSportPreset('volleyball', '🏐', 'Voleibol', 'Sets'),
    TournamentSportPreset('ping_pong', '🏓', 'Ping pong', 'A 11'),
    TournamentSportPreset('cards_mus', '🃏', 'Mus/Cartas', 'Tantos'),
    TournamentSportPreset('darts', '🎯', 'Dardos', '301/501'),
    TournamentSportPreset('billiards', '🎱', 'Billar', 'Partidas'),
    TournamentSportPreset('esports', '🎮', 'Esports', 'Mapas'),
    TournamentSportPreset('custom', '✨', 'Libre', 'Avanzado'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: presets.map((item) {
      final selected = item.value == value;
      return InkWell(
        onTap: () => onChanged(item.value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 103,
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.redSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.red : AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(item.emoji, style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 6),
            Text(item.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? AppColors.red : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 11.5)),
            const SizedBox(height: 2),
            Text(item.body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 10)),
          ]),
        ),
      );
    }).toList(),
  );
}

class TournamentValidationCard extends StatelessWidget {
  final String format;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  const TournamentValidationCard({super.key, required this.format, required this.scoringType, required this.scoringConfig});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.blueSoft,
    padding: const EdgeInsets.all(12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.verified_rounded, color: AppColors.blue, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tournamentClassificationTitle(format, scoringType, scoringConfig), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(tournamentClassificationSummary(format, scoringType, scoringConfig: scoringConfig), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 11.5)),
        const SizedBox(height: 4),
        Text(scoringValidationText(scoringType, scoringConfig), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
      ])),
    ]),
  );
}

void showPremiumUpsellDialog(BuildContext context, {String feature = 'Premium de grupo', Map<String, dynamic>? group}) {
  final premiumFeature = GrupliPremium.isPremiumFeature(feature) ? GrupliPremium.feature(feature) : null;
  final title = premiumFeature?.title ?? feature;
  final description = premiumFeature?.description ?? 'Herramientas avanzadas para grupos que organizan torneos con frecuencia.';
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Grupli Premium'),
      content: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 10),
          const Text('Premium será por grupo: todos los miembros disfrutan las funciones avanzadas de ese grupo. Los grupos grandes, los participantes amplios y el tercer puesto seguirán siendo gratis.', style: TextStyle(fontWeight: FontWeight.w700, height: 1.3, color: AppColors.muted)),
          const SizedBox(height: 12),
          ...GrupliPremium.features.take(7).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(item.icon, color: AppColors.teal, size: 18),
              const SizedBox(width: 7),
              Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800))),
            ]),
          )),
          const SizedBox(height: 8),
          const Text('Pagos reales todavía desactivados. Esta fase solo prepara permisos, pantalla y bloqueos suaves.', style: TextStyle(fontWeight: FontWeight.w700, height: 1.25, color: AppColors.muted, fontSize: 12)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
        FilledButton(onPressed: () {
          Navigator.pop(dialogContext);
          if (group != null) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => PremiumGroupScreen(group: group)));
          }
        }, child: Text(group == null ? 'Preparado' : 'Ver Premium')),
      ],
    ),
  );
}


class TournamentPremiumBanner extends StatelessWidget {
  const TournamentPremiumBanner({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.faint,
    padding: const EdgeInsets.all(12),
    onTap: () => showPremiumUpsellDialog(context),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Center(child: Text('👑', style: TextStyle(fontSize: 21)))),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Premium de grupo preparado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        SizedBox(height: 3),
        Text('Más herramientas para grupos que organizan torneos a menudo.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: AppColors.orange),
    ]),
  );
}

class TournamentPremiumMiniCard extends StatelessWidget {
  const TournamentPremiumMiniCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tealSoft,
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      const Text('👑', style: TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      const Expanded(child: Text('Premium preparado por grupo: calendario avanzado, exportar, ranking histórico y estadísticas avanzadas.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25))),
      TextButton(onPressed: () => showPremiumUpsellDialog(context), child: const Text('Ver')),
    ]),
  );
}

class TournamentPremiumSettingsCard extends StatelessWidget {
  const TournamentPremiumSettingsCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.faint,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Premium preparado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('La app queda preparada para activar Premium más adelante sin bloquear grupos grandes ni participantes.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        const TournamentRuleChip(label: 'Participantes gratis'),
        ...GrupliPremium.features.take(6).map((feature) => TournamentRuleChip(label: feature.title)),
      ]),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Ver Premium futuro', icon: Icons.workspace_premium_rounded, onTap: () => showPremiumUpsellDialog(context)),
    ]),
  );
}


class TournamentBigChoice extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final String? badge;
  final VoidCallback onTap;
  const TournamentBigChoice({super.key, required this.selected, required this.icon, required this.title, required this.body, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AppCard(
      onTap: onTap,
      color: selected ? AppColors.redSoft : AppColors.white,
      padding: const EdgeInsets.all(13),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16))),
            if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(999)), child: Text(badge!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9))),
          ]),
          const SizedBox(height: 3),
          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ]),
    ),
  );
}

class TournamentChoice {
  final String value;
  final String title;
  final String body;
  final IconData icon;
  const TournamentChoice(this.value, this.title, this.body, this.icon);
}

class TournamentChoiceGrid extends StatelessWidget {
  final String value;
  final List<TournamentChoice> options;
  final ValueChanged<String> onChanged;
  const TournamentChoiceGrid({super.key, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options.map((option) {
      final selected = option.value == value;
      return InkWell(
        onTap: () => onChanged(option.value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 102,
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.redSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.red : AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(option.icon, color: selected ? AppColors.red : AppColors.muted, size: 24),
            const SizedBox(height: 7),
            Text(option.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? AppColors.red : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 2),
            Text(option.body, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 10)),
          ]),
        ),
      );
    }).toList(),
  );
}

class TournamentRuleChip extends StatelessWidget {
  final String label;
  const TournamentRuleChip({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.75), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.lineSoft)),
    child: Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11)),
  );
}

class TournamentParticipantDraftChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  const TournamentParticipantDraftChip({super.key, required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: onDelete,
    borderRadius: BorderRadius.circular(999),
    pressedScale: .97,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.lineSoft)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.teal),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.close_rounded, size: 14, color: AppColors.muted),
      ]),
    ),
  );
}

class TournamentDraftMatchTile extends StatelessWidget {
  final TournamentDraftMatch match;
  const TournamentDraftMatchTile({super.key, required this.match});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        SizedBox(width: 32, child: Text('${match.round}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900))),
        Expanded(child: Text(match.teamAName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('vs', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11))),
        Expanded(child: Text(match.teamBName, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
      ]),
    ),
  );
}

class TournamentSchedulePreviewTile extends StatelessWidget {
  final TournamentSchedulePreviewRow row;
  const TournamentSchedulePreviewTile({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final date = row.scheduledAt == null ? 'Sin fecha' : DateFormat('EEE d MMM · HH:mm', 'es_ES').format(row.scheduledAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(13)),
            child: Center(child: Text('${row.match.round}', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${row.match.teamAName} vs ${row.match.teamBName}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 4),
            Text([
              date,
              if (row.courtName.trim().isNotEmpty) row.courtName.trim(),
            ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }
}

class TournamentManualDraftRowCard extends StatelessWidget {
  final TournamentManualDraftRow row;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  const TournamentManualDraftRowCard({super.key, required this.row, required this.index, required this.onEdit, required this.onDelete, this.onMoveUp, this.onMoveDown});

  @override
  Widget build(BuildContext context) {
    final date = row.scheduledAt == null ? 'Sin fecha individual' : DateFormat('EEE d MMM · HH:mm', 'es_ES').format(row.scheduledAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)), child: Center(child: Text('${row.round}', style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 10),
            Expanded(child: Text('${row.teamAName} vs ${row.teamBName}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'up') onMoveUp?.call();
                if (value == 'down') onMoveDown?.call();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar partido')),
                if (onMoveUp != null) const PopupMenuItem(value: 'up', child: Text('Subir')),
                if (onMoveDown != null) const PopupMenuItem(value: 'down', child: Text('Bajar')),
                const PopupMenuItem(value: 'delete', child: Text('Retirar / eliminar')),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          Text([
            date,
            if (row.courtName.trim().isNotEmpty) row.courtName.trim(),
            if (row.location.trim().isNotEmpty) row.location.trim(),
          ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
        ]),
      ),
    );
  }
}

class TournamentMatchEditorResult {
  final String teamAId;
  final String teamBId;
  final int round;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String location;
  final String courtName;
  final String notes;
  final bool syncAgenda;
  const TournamentMatchEditorResult({required this.teamAId, required this.teamBId, required this.round, this.scheduledAt, required this.durationMinutes, required this.location, required this.courtName, required this.notes, required this.syncAgenda});
}

Future<TournamentManualDraftRow?> showTournamentManualDraftDialog(
  BuildContext context, {
  required List<String> participants,
  TournamentManualDraftRow? initial,
  int defaultRound = 1,
  int defaultDuration = 60,
  String defaultLocation = '',
  String defaultCourtName = '',
  DateTime? defaultDate,
}) async {
  if (participants.length < 2) return null;
  String? teamA = participants.contains(initial?.teamAName) ? initial!.teamAName : participants.first;
  String? teamB = participants.contains(initial?.teamBName) ? initial!.teamBName : participants.firstWhere((p) => p != teamA, orElse: () => participants.last);
  final roundController = TextEditingController(text: '${initial?.round ?? defaultRound}');
  final durationController = TextEditingController(text: '${initial?.durationMinutes ?? defaultDuration}');
  final locationController = TextEditingController(text: initial?.location ?? defaultLocation);
  final courtController = TextEditingController(text: initial?.courtName ?? defaultCourtName);
  final notesController = TextEditingController(text: initial?.notes ?? '');
  var useDate = initial?.scheduledAt != null || defaultDate != null;
  DateTime selectedDate = initial?.scheduledAt ?? defaultDate ?? DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute);

  final row = await showDialog<TournamentManualDraftRow>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: Text(initial == null ? 'Añadir partido' : 'Editar partido'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: teamA,
            decoration: const InputDecoration(labelText: 'Participante A'),
            items: participants.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setLocal(() => teamA = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: teamB,
            decoration: const InputDecoration(labelText: 'Participante B'),
            items: participants.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setLocal(() => teamB = v),
          ),
          const SizedBox(height: 8),
          TextField(controller: roundController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Jornada')),
          CheckboxListTile(
            value: useDate,
            onChanged: (v) => setLocal(() => useDate = v == true),
            contentPadding: EdgeInsets.zero,
            title: const Text('Poner fecha individual'),
          ),
          if (useDate) Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
              final picked = await showDatePicker(context: dialogContext, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)), locale: const Locale('es', 'ES'));
              if (picked != null) setLocal(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedDate.hour, selectedDate.minute));
            })),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
              final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
              if (picked != null) setLocal(() { selectedTime = picked; selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute); });
            })),
          ]),
          const SizedBox(height: 8),
          TextField(controller: durationController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Duración minutos')),
          const SizedBox(height: 8),
          TextField(controller: courtController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pista / mesa / campo')),
          const SizedBox(height: 8),
          TextField(controller: locationController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación')),
          const SizedBox(height: 8),
          TextField(controller: notesController, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notas')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: teamA == null || teamB == null || teamA == teamB ? null : () => Navigator.pop(dialogContext, TournamentManualDraftRow(
              round: max(1, int.tryParse(roundController.text.trim()) ?? defaultRound),
              teamAName: teamA!,
              teamBName: teamB!,
              scheduledAt: useDate ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute) : null,
              durationMinutes: max(15, int.tryParse(durationController.text.trim()) ?? defaultDuration),
              location: locationController.text.trim(),
              courtName: courtController.text.trim(),
              notes: notesController.text.trim(),
            )),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  roundController.dispose();
  durationController.dispose();
  locationController.dispose();
  courtController.dispose();
  notesController.dispose();
  return row;
}

Future<TournamentMatchEditorResult?> showTournamentMatchEditorDialog(BuildContext context, {required List<Map<String, dynamic>> teams, int defaultRound = 1}) async {
  if (teams.length < 2) return null;
  final ids = teams.map((t) => AppData.text(t['id'])).where((id) => id.isNotEmpty).toList();
  final names = teamNameMap(teams);
  String? teamA = ids.first;
  String? teamB = ids.firstWhere((id) => id != teamA, orElse: () => ids.last);
  final roundController = TextEditingController(text: '$defaultRound');
  final durationController = TextEditingController(text: '60');
  final locationController = TextEditingController();
  final courtController = TextEditingController();
  final notesController = TextEditingController();
  var useDate = false;
  var syncAgenda = true;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 0);

  final result = await showDialog<TournamentMatchEditorResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Añadir partido manual'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: teamA,
            decoration: const InputDecoration(labelText: 'Participante A'),
            items: ids.map((id) => DropdownMenuItem(value: id, child: Text(names[id] ?? 'Participante'))).toList(),
            onChanged: (v) => setLocal(() => teamA = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: teamB,
            decoration: const InputDecoration(labelText: 'Participante B'),
            items: ids.map((id) => DropdownMenuItem(value: id, child: Text(names[id] ?? 'Participante'))).toList(),
            onChanged: (v) => setLocal(() => teamB = v),
          ),
          const SizedBox(height: 8),
          TextField(controller: roundController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Jornada')),
          CheckboxListTile(value: useDate, onChanged: (v) => setLocal(() => useDate = v == true), contentPadding: EdgeInsets.zero, title: const Text('Programar fecha')),
          if (useDate) Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
              final picked = await showDatePicker(context: dialogContext, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)), locale: const Locale('es', 'ES'));
              if (picked != null) setLocal(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedTime.hour, selectedTime.minute));
            })),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
              final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
              if (picked != null) setLocal(() { selectedTime = picked; selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute); });
            })),
          ]),
          const SizedBox(height: 8),
          TextField(controller: durationController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Duración minutos')),
          const SizedBox(height: 8),
          TextField(controller: courtController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pista / mesa / campo')),
          const SizedBox(height: 8),
          TextField(controller: locationController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación')),
          const SizedBox(height: 8),
          TextField(controller: notesController, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notas')),
          if (useDate) CheckboxListTile(value: syncAgenda, onChanged: (v) => setLocal(() => syncAgenda = v == true), contentPadding: EdgeInsets.zero, title: const Text('Añadir a Agenda')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: teamA == null || teamB == null || teamA == teamB ? null : () => Navigator.pop(dialogContext, TournamentMatchEditorResult(
              teamAId: teamA!,
              teamBId: teamB!,
              round: max(1, int.tryParse(roundController.text.trim()) ?? defaultRound),
              scheduledAt: useDate ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute) : null,
              durationMinutes: max(15, int.tryParse(durationController.text.trim()) ?? 60),
              location: locationController.text.trim(),
              courtName: courtController.text.trim(),
              notes: notesController.text.trim(),
              syncAgenda: syncAgenda,
            )),
            child: const Text('Añadir'),
          ),
        ],
      ),
    ),
  );
  roundController.dispose();
  durationController.dispose();
  locationController.dispose();
  courtController.dispose();
  notesController.dispose();
  return result;
}

Future<int?> showTournamentDuplicateRoundDialog(BuildContext context, {required List<Map<String, dynamic>> matches}) async {
  final rounds = matches.map((m) => AppData.intValue(m['round'], 1)).toSet().toList()..sort();
  if (rounds.isEmpty) return null;
  var selected = rounds.last;
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Duplicar jornada'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Se copiarán los mismos cruces en una jornada nueva, sin resultados ni fecha.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Jornada a duplicar'),
            items: rounds.map((round) => DropdownMenuItem(value: round, child: Text('Jornada $round'))).toList(),
            onChanged: (v) => setLocal(() => selected = v ?? selected),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, selected), child: const Text('Duplicar')),
        ],
      ),
    ),
  );
}

class TournamentReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const TournamentReviewRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800))),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
    ]),
  );
}


class TournamentCounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int stepValue;
  final String? zeroLabel;
  final String? helper;
  final ValueChanged<int> onChanged;
  const TournamentCounterRow({super.key, required this.label, required this.value, required this.min, required this.max, this.stepValue = 1, this.zeroLabel, this.helper, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final shown = value == 0 && zeroLabel != null ? zeroLabel! : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          if (helper != null) Text(helper!, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
        ])),
        IconButton(onPressed: value <= min ? null : () => onChanged(value - stepValue < min ? min : value - stepValue), icon: const Icon(Icons.remove_circle_outline_rounded)),
        Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
          child: Text(shown, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        ),
        IconButton(onPressed: value >= max ? null : () => onChanged(value + stepValue > max ? max : value + stepValue), icon: const Icon(Icons.add_circle_outline_rounded)),
      ]),
    );
  }
}

class TournamentDetailHero extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final TeamStanding? leader;
  final int teams;
  final int played;
  final int total;
  final int pending;
  final VoidCallback onAdd;
  final VoidCallback onGenerate;
  const TournamentDetailHero({super.key, required this.tournament, required this.leader, required this.teams, required this.played, required this.total, required this.pending, required this.onAdd, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (played / total).clamp(0.0, 1.0);
    final scoringType = AppData.text(tournament['scoring_type'], 'general');
    final format = AppData.text(tournament['format'], 'liga');
    final classificationTitle = tournamentClassificationTitle(format, scoringType, tournament['scoring_config']);
    return AppCard(
      color: AppColors.navyDeep,
      accentColor: leader == null ? AppColors.teal : AppColors.orange,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TournamentIconBadge(scoringType: scoringType),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(AppData.text(tournament['status'], 'active') == 'finished' ? 'Finalizada' : 'En curso', style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Text(total == 0 ? 'Genera los partidos para empezar.' : '$played de $total resultados registrados', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
            const SizedBox(height: 5),
            Text(classificationTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800, fontSize: 12)),
          ])),
          FilledButton.icon(onPressed: total == 0 ? onGenerate : onAdd, icon: Icon(total == 0 ? Icons.auto_awesome_motion_rounded : Icons.group_add_rounded, size: 18), label: Text(total == 0 ? 'Generar' : 'Añadir'), style: FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white)),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: progress, minHeight: 8, color: AppColors.green, backgroundColor: Colors.white.withOpacity(.18)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TournamentHeroStat(value: '$teams', label: 'Equipos')),
          const SizedBox(width: 8),
          Expanded(child: TournamentHeroStat(value: '$pending', label: 'Pendientes')),
          const SizedBox(width: 8),
          Expanded(child: TournamentHeroStat(value: leader?.points.toString() ?? '0', label: leader == null ? 'Puntos líder' : leader!.name)),
        ]),
      ]),
    );
  }
}

class TournamentHeroStat extends StatelessWidget {
  final String value;
  final String label;
  const TournamentHeroStat({super.key, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(.10))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 2),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCFFFFFFF), fontWeight: FontWeight.w800, fontSize: 10.5)),
    ]),
  );
}

class TournamentTabsBar extends StatelessWidget {
  final int index;
  final String format;
  final ValueChanged<int> onChanged;
  const TournamentTabsBar({super.key, required this.index, this.format = 'liga', required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final items = [
      const ('Resumen', Icons.dashboard_rounded),
      const ('Partidos', Icons.sports_score_rounded),
      (format == 'eliminatoria' ? 'Cuadro' : 'Tabla', format == 'eliminatoria' ? Icons.account_tree_rounded : Icons.table_chart_rounded),
      const ('Estadísticas', Icons.query_stats_rounded),
      const ('Equipos', Icons.groups_rounded),
      const ('Ajustes', Icons.tune_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.navyDeep, borderRadius: BorderRadius.circular(16)),
      child: Row(children: List.generate(items.length, (i) {
        final selected = i == index;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(color: selected ? AppColors.red : Colors.transparent, borderRadius: BorderRadius.circular(13)),
              child: Text(items[i].$1, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: selected ? Colors.white : const Color(0xCFFFFFFF))),
            ),
          ),
        );
      })),
    );
  }
}

class TournamentOverviewPanel extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final List<TeamStanding> standings;
  final VoidCallback onAddParticipants;
  final VoidCallback onGenerate;
  final VoidCallback onManualMatches;
  final VoidCallback onBulkSchedule;
  final VoidCallback? onNextRound;
  final VoidCallback onChanged;
  const TournamentOverviewPanel({super.key, required this.tournament, required this.teams, required this.matches, required this.standings, required this.onAddParticipants, required this.onGenerate, required this.onManualMatches, required this.onBulkSchedule, this.onNextRound, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pendingAll = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).toList();
    final pending = pendingAll.take(4).toList();
    final names = teamNameMap(teams);
    final format = AppData.text(tournament['format'], 'liga');
    final nextTitle = teams.length < 2
        ? 'Añade participantes'
        : matches.isEmpty
            ? 'Genera los partidos'
            : pendingAll.isEmpty
                ? 'Competición lista para cerrar'
                : 'Siguiente partido pendiente';
    final nextBody = teams.length < 2
        ? 'Primero elige quién juega. Puedes añadir equipos, parejas o jugadores.'
        : matches.isEmpty
            ? 'Crea el calendario para ver jornadas, fechas y resultados.'
            : pendingAll.isEmpty
                ? 'Todos los partidos están jugados. Revisa la tabla y finaliza desde Ajustes.'
                : 'Toca un partido para registrar resultado, cambiar fecha o aplazarlo.';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TournamentNextStepCard(title: nextTitle, body: nextBody, icon: teams.length < 2 ? Icons.group_add_rounded : matches.isEmpty ? Icons.auto_awesome_motion_rounded : pendingAll.isEmpty ? Icons.verified_rounded : Icons.sports_score_rounded),
      const SizedBox(height: 12),
      if (teams.length < 2)
        EmptySlim(icon: Icons.group_add_rounded, title: 'Añade participantes', body: 'Necesitas al menos dos equipos, parejas o jugadores.')
      else if (matches.isEmpty)
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Calendario pendiente', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(format == 'manual' ? 'Añade los emparejamientos manuales para empezar.' : 'Genera todos los partidos automáticamente según el formato elegido.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          PrimaryButton(label: format == 'manual' ? 'Añadir partidos' : 'Generar partidos', icon: format == 'manual' ? Icons.add_link_rounded : Icons.auto_awesome_motion_rounded, onTap: format == 'manual' ? onManualMatches : onGenerate),
        ]))
      else ...[
        SectionHeader(title: 'Próximo partido'),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          EmptySlim(icon: Icons.verified_rounded, title: 'Todo jugado', body: onNextRound == null ? 'Puedes marcar la competición como finalizada.' : 'Puedes generar la siguiente ronda.')
        else
          ...pending.map((m) => TournamentSimpleMatchCard(match: m, teams: teams, scoringType: AppData.text(tournament['scoring_type'], 'general'), scoringConfig: tournament['scoring_config'], onChanged: onChanged)),
        if (onNextRound != null) ...[
          const SizedBox(height: 10),
          SecondaryButton(label: 'Generar siguiente ronda', icon: Icons.account_tree_rounded, onTap: onNextRound!),
        ],
        const SizedBox(height: 16),
        SectionHeader(title: 'Último resultado'),
        const SizedBox(height: 8),
        if (matches.where(matchCountsForStandings).isEmpty)
          EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin resultados', body: 'Toca un partido para meter marcador.')
        else
          TournamentLatestResultCard(match: matches.where(matchCountsForStandings).last, names: names, scoringType: AppData.text(tournament['scoring_type'], 'general'), scoringConfig: tournament['scoring_config']),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatCard(icon: Icons.sports_score_rounded, value: '${matches.length}', label: 'Partidos', color: AppColors.red)),
          const SizedBox(width: 8),
          Expanded(child: StatCard(icon: Icons.done_all_rounded, value: '${matches.length - pendingAll.length}', label: 'Jugados', color: AppColors.green)),
          const SizedBox(width: 8),
          Expanded(child: StatCard(icon: Icons.percent_rounded, value: matches.isEmpty ? '0%' : '${(((matches.length - pendingAll.length) / matches.length) * 100).round()}%', label: 'Progreso', color: AppColors.blue)),
        ]),
        const SizedBox(height: 16),
        SectionHeader(title: 'Líder actual'),
        const SizedBox(height: 8),
        if (standings.isEmpty)
          EmptySlim(icon: Icons.table_chart_rounded, title: 'Sin clasificación', body: 'Registra resultados para calcular la tabla.')
        else
          TournamentStandingTile(standing: standings.first, scoringType: AppData.text(tournament['scoring_type'], 'general'), scoringConfig: tournament['scoring_config'], highlighted: true),
      ],
    ]);
  }
}

class TournamentNextStepCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const TournamentNextStepCard({super.key, required this.title, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tealSoft,
    padding: const EdgeInsets.all(13),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.teal, size: 22)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
      ])),
    ]),
  );
}



class TournamentEditFocusCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final List<TeamStanding> standings;
  final VoidCallback onAddParticipants;
  final VoidCallback onBulkSchedule;
  final VoidCallback onManualMatches;
  final VoidCallback onCheckIn;
  const TournamentEditFocusCard({
    super.key,
    required this.tournament,
    required this.teams,
    required this.matches,
    required this.standings,
    required this.onAddParticipants,
    required this.onBulkSchedule,
    required this.onManualMatches,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final names = teamNameMap(teams);
    final pending = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).toList();
    pending.sort((a, b) {
      final date = AppData.text(a['scheduled_at']).compareTo(AppData.text(b['scheduled_at']));
      if (date != 0) return date;
      final round = AppData.intValue(a['round']).compareTo(AppData.intValue(b['round']));
      if (round != 0) return round;
      return AppData.intValue(a['order_index']).compareTo(AppData.intValue(b['order_index']));
    });
    final next = pending.isNotEmpty ? pending.first : null;
    final format = AppData.text(tournament['format'], 'liga');
    final canAddManualMatch = format == 'manual' || format == 'liga';

    return AppCard(
      color: AppColors.navyDeep,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text('✏️', style: TextStyle(fontSize: 23))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Panel de edición', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
            const SizedBox(height: 4),
            Text(
              teams.isEmpty
                  ? 'Empieza añadiendo jugadores, parejas o equipos.'
                  : next == null
                      ? 'Todo está jugado. Puedes revisar tabla, participantes o ajustes.'
                      : 'Edita jugadores, fechas y partidos sin perder el control del torneo.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.25),
            ),
          ])),
        ]),
        if (next != null) ...[
          const SizedBox(height: 10),
          TournamentLiveNowMini(match: next, teams: teams, names: names),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Añadir jugadores', icon: Icons.group_add_rounded, onTap: onAddParticipants)),
          const SizedBox(width: 8),
          Expanded(child: SecondaryButton(label: 'Cambiar fechas', icon: Icons.edit_calendar_rounded, onTap: onBulkSchedule)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (canAddManualMatch) ...[
            Expanded(child: SecondaryButton(label: 'Añadir partido', icon: Icons.add_link_rounded, onTap: onManualMatches)),
            const SizedBox(width: 8),
          ],
          Expanded(child: SecondaryButton(label: 'Check-in', icon: Icons.how_to_reg_rounded, onTap: onCheckIn)),
        ]),
      ]),
    );
  }
}


class TournamentLiveNowMini extends StatelessWidget {
  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> teams;
  final Map<String, String> names;
  const TournamentLiveNowMini({super.key, required this.match, required this.teams, required this.names});

  @override
  Widget build(BuildContext context) {
    final rest = americanoRestText(match, names);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(.10))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text([
          AppData.text(match['round_name'], 'Partido'),
          tournamentMatchDateText(match),
          if (AppData.text(match['court_name']).isNotEmpty) AppData.text(match['court_name']),
        ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCFFFFFFF), fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 5),
        Text('${tournamentMatchSideName(match, names, true)} vs ${tournamentMatchSideName(match, names, false)}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, height: 1.1)),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Descansan: $rest', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ]),
    );
  }
}

Future<void> showTournamentCheckInDialog(BuildContext context, {required List<Map<String, dynamic>> teams}) async {
  final checked = <String>{for (final team in teams) AppData.text(team['id'])};
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Check-in de participantes'),
        content: SizedBox(
          width: double.maxFinite,
          child: teams.isEmpty
              ? const Text('Aún no hay participantes.')
              : SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: teams.map((team) {
                  final id = AppData.text(team['id']);
                  return CheckboxListTile(
                    value: checked.contains(id),
                    onChanged: (value) => setLocal(() {
                      if (value == true) {
                        checked.add(id);
                      } else {
                        checked.remove(id);
                      }
                    }),
                    title: Text(AppData.text(team['name'], 'Participante')),
                    subtitle: Text(checked.contains(id) ? 'Presente' : 'Falta'),
                  );
                }).toList())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            Navigator.pop(dialogContext);
            showToast(context, '${checked.length}/${teams.length} participantes marcados como presentes.');
          }, child: const Text('Guardar')),
        ],
      ),
    ),
  );
}



class TournamentEliminationBracketPanel extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> teams;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  final VoidCallback onNextRound;
  final VoidCallback onThirdPlace;
  final VoidCallback onChanged;
  const TournamentEliminationBracketPanel({
    super.key,
    required this.tournament,
    required this.group,
    required this.matches,
    required this.teams,
    required this.scoringType,
    required this.scoringConfig,
    required this.onNextRound,
    required this.onThirdPlace,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return EmptySlim(icon: Icons.account_tree_rounded, title: 'Cuadro pendiente', body: 'Genera los cruces para ver el cuadro de la eliminatoria.');
    }
    final names = teamNameMap(teams);
    final normalMatches = matches.where((m) => AppData.text(AppData.asMap(m['result_details'])['stage']) != 'third_place').toList();
    final thirdPlace = matches.where((m) => AppData.text(AppData.asMap(m['result_details'])['stage']) == 'third_place' || AppData.text(m['round_name']).toLowerCase().contains('tercer')).toList();
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final match in normalMatches) {
      final round = AppData.intValue(match['round'], 1);
      grouped.putIfAbsent(round, () => []).add(match);
    }
    final rounds = grouped.keys.toList()..sort();
    for (final round in rounds) {
      grouped[round]!.sort((a, b) => AppData.intValue(a['order_index']).compareTo(AppData.intValue(b['order_index'])));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(color: AppColors.tealSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.account_tree_rounded, color: AppColors.teal)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cuadro de eliminatoria', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 3),
            Text('${teams.length} participantes · ${matches.length} partidos · byes visibles', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: const [
          TournamentRuleChip(label: 'Sorteo'),
          TournamentRuleChip(label: 'Pases directos'),
          TournamentRuleChip(label: 'Siguiente ronda'),
          TournamentRuleChip(label: 'Tercer puesto'),
        ]),
      ])),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final round in rounds) ...[
            SizedBox(
              width: 270,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TournamentBracketRoundHeader(roundName: AppData.text(grouped[round]!.first['round_name'], eliminationRoundNameForRemaining(grouped[round]!.length * 2)), count: grouped[round]!.length),
                const SizedBox(height: 8),
                ...grouped[round]!.map((match) => TournamentBracketMatchCard(match: match, teams: teams, names: names, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged, group: group, tournamentName: AppData.text(tournament['name'], 'Torneo'))),
              ]),
            ),
            const SizedBox(width: 12),
          ],
          if (thirdPlace.isNotEmpty)
            SizedBox(
              width: 270,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TournamentBracketRoundHeader(roundName: 'Tercer puesto', count: thirdPlace.length),
                const SizedBox(height: 8),
                ...thirdPlace.map((match) => TournamentBracketMatchCard(match: match, teams: teams, names: names, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged, group: group, tournamentName: AppData.text(tournament['name'], 'Torneo'))),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (canGenerateEliminationNextRound(matches))
        SecondaryButton(label: 'Generar siguiente ronda', icon: Icons.account_tree_rounded, onTap: onNextRound),
      if (canGenerateEliminationNextRound(matches) && canCreateEliminationThirdPlace(matches)) const SizedBox(height: 8),
      if (canCreateEliminationThirdPlace(matches))
        SecondaryButton(label: 'Crear partido por el tercer puesto', icon: Icons.emoji_events_rounded, onTap: onThirdPlace),
      if (!canGenerateEliminationNextRound(matches) && !canCreateEliminationThirdPlace(matches)) ...[
        const SizedBox(height: 4),
        EmptySlim(icon: Icons.info_outline_rounded, title: 'Cuadro al día', body: 'Cierra todos los partidos de la ronda actual para avanzar.')
      ],
    ]);
  }
}

class TournamentBracketRoundHeader extends StatelessWidget {
  final String roundName;
  final int count;
  const TournamentBracketRoundHeader({super.key, required this.roundName, required this.count});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(roundName, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15))),
    TournamentRuleChip(label: '$count'),
  ]);
}

class TournamentBracketMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> teams;
  final Map<String, String> names;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  final VoidCallback onChanged;
  final Map<String, dynamic> group;
  final String tournamentName;
  const TournamentBracketMatchCard({
    super.key,
    required this.match,
    required this.teams,
    required this.names,
    required this.scoringType,
    required this.scoringConfig,
    required this.onChanged,
    required this.group,
    required this.tournamentName,
  });

  @override
  Widget build(BuildContext context) {
    final status = AppData.text(match['status'], 'pending');
    final aId = AppData.text(match['team_a']);
    final bId = AppData.text(match['team_b']);
    final a = names[aId] ?? 'Pendiente';
    final b = bId.isEmpty || bId == 'null' ? 'Pase directo' : names[bId] ?? 'Pendiente';
    final winner = tournamentMatchWinnerId(match);
    final bye = status == 'bye' || b == 'Pase directo';
    final score = matchCountsForStandings(match) || bye ? '${AppData.intValue(match['score_a'])} - ${AppData.intValue(match['score_b'])}' : matchStatusLabel(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        color: bye ? AppColors.violetSoft : AppColors.white,
        padding: const EdgeInsets.all(11),
        onTap: bye ? null : () => showMatchResultDialog(context, match: match, teams: teams, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: matchStatusColor(status).withOpacity(.12), borderRadius: BorderRadius.circular(999)),
              child: Text(bye ? 'BYE' : matchStatusLabel(status), style: TextStyle(color: matchStatusColor(status), fontWeight: FontWeight.w900, fontSize: 10)),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(tournamentMatchDateText(match), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 10))),
          ]),
          const SizedBox(height: 9),
          TournamentBracketTeamLine(name: a, seed: tournamentSeedForTeam(teams, aId), winner: winner == aId),
          const SizedBox(height: 6),
          TournamentBracketTeamLine(name: b, seed: tournamentSeedForTeam(teams, bId), winner: winner == bId),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(score, style: TextStyle(color: bye ? AppColors.violet : matchStatusColor(status), fontWeight: FontWeight.w900, fontSize: 12))),
            if (!bye) TextButton(onPressed: () => showMatchScheduleDialog(context, match: match, group: group, tournamentName: tournamentName, teams: teams, onChanged: onChanged), child: const Text('Fecha')),
          ]),
        ]),
      ),
    );
  }
}

class TournamentBracketTeamLine extends StatelessWidget {
  final String name;
  final int seed;
  final bool winner;
  const TournamentBracketTeamLine({super.key, required this.name, required this.seed, required this.winner});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: winner ? AppColors.green : AppColors.faint, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(seed > 0 ? '$seed' : '-', style: TextStyle(color: winner ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11))),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: winner ? AppColors.green : AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
    if (winner) const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
  ]);
}

int tournamentSeedForTeam(List<Map<String, dynamic>> teams, String teamId) {
  if (teamId.isEmpty || teamId == 'null') return 0;
  for (final team in teams) {
    if (AppData.text(team['id']) == teamId) return AppData.intValue(team['seed']);
  }
  return 0;
}


class TournamentMatchesPanel extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> teams;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  final VoidCallback onBulkSchedule;
  final VoidCallback onChanged;
  const TournamentMatchesPanel({super.key, required this.tournament, required this.group, required this.matches, required this.teams, required this.scoringType, required this.scoringConfig, required this.onBulkSchedule, required this.onChanged});

  @override
  State<TournamentMatchesPanel> createState() => _TournamentMatchesPanelState();
}

class _TournamentMatchesPanelState extends State<TournamentMatchesPanel> {
  String filter = 'all';
  bool syncingAgenda = false;

  List<Map<String, dynamic>> get filteredMatches {
    if (filter == 'played') return widget.matches.where(matchCountsForStandings).toList();
    if (filter == 'postponed') return widget.matches.where((m) => AppData.text(m['status']) == 'postponed').toList();
    if (filter == 'pending') return widget.matches.where((m) {
      final status = AppData.text(m['status'], 'pending');
      return status != 'played' && status != 'postponed' && status != 'cancelled' && status != 'bye';
    }).toList();
    return widget.matches;
  }

  Future<void> addVisualManualMatch() async {
    if (widget.teams.length < 2) {
      await showToast(context, 'Añade al menos 2 participantes.', danger: true);
      return;
    }
    final result = await showTournamentMatchEditorDialog(
      context,
      teams: widget.teams,
      defaultRound: widget.matches.isEmpty ? 1 : widget.matches.fold<int>(1, (value, match) => max(value, AppData.intValue(match['round'], 1))),
    );
    if (result == null) return;
    try {
      final created = await AppData.addTournamentMatch(
        tournamentId: AppData.text(widget.tournament['id']),
        teamAId: result.teamAId,
        teamBId: result.teamBId,
        round: result.round,
        scheduledAt: result.scheduledAt,
        durationMinutes: result.durationMinutes,
        location: result.location,
        courtName: result.courtName,
        notes: result.notes,
      );
      if (result.syncAgenda && result.scheduledAt != null) {
        await AppData.syncMatchAgendaEvent(
          groupId: AppData.text(widget.group['id']),
          tournamentName: AppData.text(widget.tournament['name'], 'Torneo'),
          match: created,
          teamNames: teamNameMap(widget.teams),
        );
      }
      widget.onChanged();
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> duplicateRound() async {
    final round = await showTournamentDuplicateRoundDialog(context, matches: widget.matches);
    if (round == null) return;
    try {
      await AppData.duplicateTournamentRound(AppData.text(widget.tournament['id']), round);
      widget.onChanged();
      if (mounted) await showToast(context, 'Jornada duplicada. Puedes reordenarla o cambiar fechas.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> syncMissingAgendaEvents() async {
    if (syncingAgenda) return;
    setState(() => syncingAgenda = true);
    try {
      final created = await AppData.createAgendaEventsForTournament(
        AppData.text(widget.group['id']),
        AppData.text(widget.tournament['id']),
        AppData.text(widget.tournament['name'], 'Torneo'),
      );
      widget.onChanged();
      if (mounted) {
        await showToast(context, created == 0 ? 'Agenda ya estaba al día.' : '$created partido${created == 1 ? '' : 's'} añadido${created == 1 ? '' : 's'} a Agenda.');
      }
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => syncingAgenda = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManual = AppData.text(widget.tournament['format']) == 'manual';
    if (widget.matches.isEmpty) {
      if (isManual) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EmptySlim(icon: Icons.table_rows_rounded, title: 'Sin partidos todavía', body: 'Añade partidos manuales con selectores y fechas individuales.'),
          const SizedBox(height: 10),
          PrimaryButton(label: 'Añadir partido', icon: Icons.add_rounded, onTap: addVisualManualMatch),
        ]);
      }
      return EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin partidos todavía', body: 'Genera el calendario desde Resumen.');
    }
    final shown = filteredMatches;
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final match in shown) {
      final round = AppData.intValue(match['round'], 1);
      grouped.putIfAbsent(round, () => []).add(match);
    }
    final rounds = grouped.keys.toList()..sort();
    final scheduledForAgenda = widget.matches.where((m) {
      final status = AppData.text(m['status'], 'pending');
      return tournamentMatchHasScheduledDate(m) && status != 'cancelled' && status != 'bye';
    }).toList();
    final linkedAgenda = scheduledForAgenda.where(tournamentMatchHasAgendaEvent).length;
    final missingAgenda = scheduledForAgenda.length - linkedAgenda;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TournamentAgendaSyncSummaryCard(
        totalScheduled: scheduledForAgenda.length,
        linkedAgenda: linkedAgenda,
        missingAgenda: missingAgenda,
        loading: syncingAgenda,
        onSyncMissing: missingAgenda > 0 ? syncMissingAgendaEvents : null,
        onBulkSchedule: widget.onBulkSchedule,
      ),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(child: TournamentSmallFilter(label: 'Todos', selected: filter == 'all', onTap: () => setState(() => filter = 'all'))),
          Expanded(child: TournamentSmallFilter(label: 'Pendientes', selected: filter == 'pending', onTap: () => setState(() => filter = 'pending'))),
          Expanded(child: TournamentSmallFilter(label: 'Jugados', selected: filter == 'played', onTap: () => setState(() => filter = 'played'))),
          Expanded(child: TournamentSmallFilter(label: 'Aplazados', selected: filter == 'postponed', onTap: () => setState(() => filter = 'postponed'))),
        ]),
      ),
      const SizedBox(height: 8),
      if (isManual) ...[
        Row(children: [
          Expanded(child: PrimaryButton(label: 'Añadir partido', icon: Icons.add_rounded, onTap: addVisualManualMatch)),
          const SizedBox(width: 8),
          Expanded(child: SecondaryButton(label: 'Duplicar jornada', icon: Icons.copy_rounded, onTap: duplicateRound)),
        ]),
        const SizedBox(height: 8),
      ],
      if (shown.isEmpty)
        EmptySlim(icon: Icons.filter_alt_rounded, title: 'Sin partidos en este filtro', body: 'Cambia el filtro para ver otros partidos.')
      else ...[
        for (final round in rounds) ...[
          SectionHeader(title: AppData.text(widget.tournament['format']) == 'americano' ? 'Ronda $round' : 'Jornada $round'),
          const SizedBox(height: 8),
          ...grouped[round]!.map((m) => TournamentSimpleMatchCard(match: m, allMatches: widget.matches, group: widget.group, tournamentName: AppData.text(widget.tournament['name'], 'Torneo'), teams: widget.teams, scoringType: widget.scoringType, scoringConfig: widget.scoringConfig, onChanged: widget.onChanged)),
          const SizedBox(height: 12),
        ],
      ],
    ]);
  }
}

class TournamentSmallFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const TournamentSmallFilter({super.key, required this.label, this.selected = false, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: selected ? AppColors.red : Colors.transparent, borderRadius: BorderRadius.circular(999)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 10.5)),
    ),
  );
}

class TournamentAgendaSyncSummaryCard extends StatelessWidget {
  final int totalScheduled;
  final int linkedAgenda;
  final int missingAgenda;
  final bool loading;
  final VoidCallback? onSyncMissing;
  final VoidCallback onBulkSchedule;
  const TournamentAgendaSyncSummaryCard({super.key, required this.totalScheduled, required this.linkedAgenda, required this.missingAgenda, required this.loading, required this.onSyncMissing, required this.onBulkSchedule});

  @override
  Widget build(BuildContext context) {
    final ready = totalScheduled > 0 && missingAgenda == 0;
    final body = totalScheduled == 0
        ? 'Todavía no hay partidos con fecha. Programa una jornada o un lote para verlos también en Agenda.'
        : ready
            ? '$linkedAgenda de $totalScheduled partidos con evento vinculado en Agenda.'
            : '$missingAgenda de $totalScheduled partidos con fecha todavía no aparecen en Agenda.';
    return AppCard(
      color: ready ? AppColors.greenSoft : AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.amber.withOpacity(.16), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.calendar_month_rounded, color: AppColors.amber)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Agenda del torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Reprogramar', icon: Icons.edit_calendar_rounded, onTap: onBulkSchedule)),
          if (onSyncMissing != null) ...[
            const SizedBox(width: 8),
            Expanded(child: PrimaryButton(label: loading ? 'Añadiendo...' : 'Añadir a Agenda', icon: Icons.event_available_rounded, loading: loading, onTap: onSyncMissing!)),
          ],
        ]),
      ]),
    );
  }
}

class TournamentAgendaLinkChip extends StatelessWidget {
  final Map<String, dynamic> match;
  final Color color;
  const TournamentAgendaLinkChip({super.key, required this.match, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(.18))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(tournamentMatchAgendaSyncIcon(match), color: color, size: 12),
        const SizedBox(width: 4),
        Text(tournamentMatchAgendaSyncLabel(match), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9.5)),
      ]),
    );
  }
}

class TournamentSimpleMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> allMatches;
  final Map<String, dynamic>? group;
  final String tournamentName;
  final List<Map<String, dynamic>> teams;
  final String scoringType;
  final Map<String, dynamic>? scoringConfig;
  final VoidCallback onChanged;
  const TournamentSimpleMatchCard({super.key, required this.match, this.allMatches = const [], this.group, this.tournamentName = 'Torneo', required this.teams, this.scoringType = 'general', this.scoringConfig, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final names = teamNameMap(teams);
    final aName = tournamentMatchSideName(match, names, true);
    final bName = tournamentMatchSideName(match, names, false);
    final restText = americanoRestText(match, names);
    final status = AppData.text(match['status'], 'pending');
    final played = matchCountsForStandings(match);
    final specialText = matchSpecialResultText(match, names);
    final specialAllowed = !isAmericanoMatch(match);
    final detailScore = specialText.isNotEmpty ? specialText : matchDetailScoreText(match, scoringType, scoringConfig);
    final score = played ? matchPrimaryScoreText(match, scoringType, scoringConfig) : matchStatusLabel(status);
    final dateText = tournamentMatchDateText(match);
    final statusColor = matchStatusColor(status);
    final agendaColor = tournamentMatchAgendaSyncColor(match);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        accentColor: played ? AppColors.green : statusColor,
        onTap: () => showMatchResultDialog(context, match: match, teams: teams, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
              child: Text(AppData.text(match['round_name'], 'Jornada ${AppData.intValue(match['round'], 1)}'), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10)),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(dateText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11))),
            TournamentAgendaLinkChip(match: match, color: agendaColor),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'result') {
                  await showMatchResultDialog(context, match: match, teams: teams, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged);
                } else if (value == 'schedule') {
                  await showMatchScheduleDialog(context, match: match, group: group, tournamentName: tournamentName, teams: teams, onChanged: onChanged);
                } else if (value == 'special') {
                  await showSpecialMatchResultDialog(context, match: match, teams: teams, onChanged: onChanged);
                } else if (value == 'history') {
                  await showMatchHistoryDialog(context, match: match);
                } else if (value == 'postponed' || value == 'cancelled' || value == 'pending') {
                  try {
                    await AppData.updateMatchStatus(match['id'].toString(), value);
                    onChanged();
                  } catch (e) {
                    if (context.mounted) await showToast(context, humanError(e), danger: true);
                  }
                } else if (value == 'open_event') {
                  final eventId = AppData.text(match['event_id']);
                  if (eventId.isEmpty || group == null) {
                    if (context.mounted) await showToast(context, 'Este partido todavía no tiene evento de Agenda.', danger: true);
                    return;
                  }
                  try {
                    await AppData.openTournamentMatchEvent(context, eventId, group!);
                  } catch (e) {
                    if (context.mounted) await showToast(context, humanError(e), danger: true);
                  }
                } else if (value == 'reopen') {
                  try {
                    await AppData.reopenMatch(match['id'].toString());
                    onChanged();
                  } catch (e) {
                    if (context.mounted) await showToast(context, humanError(e), danger: true);
                  }
                } else if (value == 'move_up' || value == 'move_down') {
                  try {
                    await AppData.shiftTournamentMatchOrder(match['id'].toString(), allMatches, value == 'move_up' ? -1 : 1);
                    onChanged();
                  } catch (e) {
                    if (context.mounted) await showToast(context, humanError(e), danger: true);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'result', child: Text('Registrar resultado')),
                if (specialAllowed) const PopupMenuItem(value: 'special', child: Text('No presentado / victoria admin.')),
                const PopupMenuItem(value: 'schedule', child: Text('Cambiar fecha / pista')),
                const PopupMenuItem(value: 'move_up', child: Text('Subir en la jornada')),
                const PopupMenuItem(value: 'move_down', child: Text('Bajar en la jornada')),
                if (matchResultHistory(match).isNotEmpty) const PopupMenuItem(value: 'history', child: Text('Ver historial')),
                if (AppData.text(match['event_id']).isNotEmpty) const PopupMenuItem(value: 'open_event', child: Text('Abrir en Agenda')),
                const PopupMenuItem(value: 'postponed', child: Text('Marcar aplazado')),
                const PopupMenuItem(value: 'cancelled', child: Text('Cancelar partido')),
                const PopupMenuItem(value: 'pending', child: Text('Volver a pendiente')),
                if (matchCountsForStandings(match)) const PopupMenuItem(value: 'reopen', child: Text('Borrar resultado')),
              ],
            ),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: Text(aName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [
              Text(score, style: TextStyle(color: played ? AppColors.green : statusColor, fontWeight: FontWeight.w900, fontSize: 12)),
              if (detailScore != null) Text(detailScore, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 9)),
            ])),
            Expanded(child: Text(bName, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
          ]),
          if (AppData.text(match['court_name']).isNotEmpty || AppData.text(match['location']).isNotEmpty || restText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text([
              if (AppData.text(match['court_name']).isNotEmpty) AppData.text(match['court_name']),
              if (AppData.text(match['location']).isNotEmpty) AppData.text(match['location']),
              if (restText.isNotEmpty) 'Descansan: $restText',
            ].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
          ],
          if (group != null && status != 'bye') ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: () => showMatchResultDialog(context, match: match, teams: teams, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged),
                icon: Icon(played ? Icons.edit_rounded : Icons.sports_score_rounded, size: 17),
                label: Text(played ? 'Editar resultado' : 'Registrar resultado'),
              )),
              Expanded(child: TextButton.icon(
                onPressed: () => showMatchScheduleDialog(context, match: match, group: group, tournamentName: tournamentName, teams: teams, onChanged: onChanged),
                icon: const Icon(Icons.edit_calendar_rounded, size: 17),
                label: const Text('Fecha'),
              )),
              if (tournamentMatchHasAgendaEvent(match))
                Expanded(child: TextButton.icon(
                  onPressed: () => AppData.openTournamentMatchEvent(context, AppData.text(match['event_id']), group!),
                  icon: const Icon(Icons.calendar_month_rounded, size: 17),
                  label: const Text('Agenda'),
                )),
            ]),
          ],
        ]),
      ),
    );
  }
}

class TournamentLatestResultCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final Map<String, String> names;
  final String scoringType;
  final dynamic scoringConfig;
  const TournamentLatestResultCard({super.key, required this.match, required this.names, required this.scoringType, this.scoringConfig});

  @override
  Widget build(BuildContext context) {
    final aName = tournamentMatchSideName(match, names, true);
    final bName = tournamentMatchSideName(match, names, false);
    final details = matchDetailScoreText(match, scoringType, scoringConfig);
    return AppCard(accentColor: AppColors.green, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text([AppData.text(match['round_name'], 'Resultado'), tournamentMatchDateText(match)].where((item) => item.isNotEmpty).join(' · '), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 10.5)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Text(aName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
        Text(matchPrimaryScoreText(match, scoringType, scoringConfig), style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 16)),
        Expanded(child: Text(bName, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
      ]),
      if (details != null) ...[
        const SizedBox(height: 5),
        Text(details, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    ]));
  }
}

class TournamentStandingsPanel extends StatelessWidget {
  final List<TeamStanding> standings;
  final List<Map<String, dynamic>> matches;
  final List<String> tieBreakers;
  final String format;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  const TournamentStandingsPanel({super.key, required this.standings, required this.matches, required this.tieBreakers, required this.format, required this.scoringType, required this.scoringConfig});

  List<DataColumn> _columns(bool isAmericano, bool setMode) {
    if (isAmericano) {
      final main = scoringUsesGameSetMode(scoringType, scoringConfig)
          ? 'JUEGOS'
          : scoringUsesPointSetMode(scoringType, scoringConfig)
              ? 'PUNTOS'
              : scoringScoreLabel(scoringType, scoringConfig).toUpperCase();
      return [
        const DataColumn(label: Text('#')),
        const DataColumn(label: Text('Jugador')),
        const DataColumn(label: Text('PJ')),
        const DataColumn(label: Text('V')),
        DataColumn(label: Text(main)),
        const DataColumn(label: Text('CONTRA')),
        const DataColumn(label: Text('DIF')),
      ];
    }
    if (setMode) {
      return [
        const DataColumn(label: Text('#')),
        const DataColumn(label: Text('Equipo')),
        const DataColumn(label: Text('PJ')),
        const DataColumn(label: Text('V')),
        const DataColumn(label: Text('P')),
        DataColumn(label: Text(scoringTableForLabel(scoringType, scoringConfig))),
        DataColumn(label: Text(scoringTableAgainstLabel(scoringType, scoringConfig))),
        DataColumn(label: Text(scoringTableDifferenceLabel(scoringType, scoringConfig))),
        DataColumn(label: Text(scoringSecondaryForLabel(scoringType, scoringConfig))),
        DataColumn(label: Text(scoringSecondaryAgainstLabel(scoringType, scoringConfig))),
        DataColumn(label: Text(scoringSecondaryDifferenceLabel(scoringType, scoringConfig))),
        const DataColumn(label: Text('PTS')),
      ];
    }
    final allowDraw = scoringAllowDraw(scoringType, scoringConfig);
    return [
      const DataColumn(label: Text('#')),
      const DataColumn(label: Text('Equipo')),
      const DataColumn(label: Text('PJ')),
      const DataColumn(label: Text('G')),
      if (allowDraw) const DataColumn(label: Text('E')),
      const DataColumn(label: Text('P')),
      DataColumn(label: Text(scoringTableForLabel(scoringType, scoringConfig))),
      DataColumn(label: Text(scoringTableAgainstLabel(scoringType, scoringConfig))),
      DataColumn(label: Text(scoringTableDifferenceLabel(scoringType, scoringConfig))),
      const DataColumn(label: Text('PTS')),
    ];
  }

  List<DataCell> _cells(TeamStanding s, int index, bool isAmericano, bool setMode) {
    final base = [
      DataCell(Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: index == 0 ? AppColors.green : AppColors.ink))),
      DataCell(SizedBox(width: 150, child: Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)))),
      DataCell(Text('${s.played}')),
    ];
    if (isAmericano) {
      return [
        ...base,
        DataCell(Text('${s.wins}')),
        DataCell(Text('${s.goalsFor}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900))),
        DataCell(Text('${s.goalsAgainst}')),
        DataCell(Text('${s.goalDifference}')),
      ];
    }
    if (setMode) {
      return [
        ...base,
        DataCell(Text('${s.wins}')),
        DataCell(Text('${s.losses}')),
        DataCell(Text('${s.goalsFor}')),
        DataCell(Text('${s.goalsAgainst}')),
        DataCell(Text('${s.goalDifference}')),
        DataCell(Text('${s.secondaryFor}')),
        DataCell(Text('${s.secondaryAgainst}')),
        DataCell(Text('${s.secondaryDifference}')),
        DataCell(Text('${s.points}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900))),
      ];
    }
    final allowDraw = scoringAllowDraw(scoringType, scoringConfig);
    return [
      ...base,
      DataCell(Text('${s.wins}')),
      if (allowDraw) DataCell(Text('${s.draws}')),
      DataCell(Text('${s.losses}')),
      DataCell(Text('${s.goalsFor}')),
      DataCell(Text('${s.goalsAgainst}')),
      DataCell(Text('${s.goalDifference}')),
      DataCell(Text('${s.points}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) return EmptySlim(icon: Icons.table_chart_rounded, title: 'Sin clasificacion todavia', body: 'Registra resultados para calcular la clasificacion.');
    final isAmericano = matches.any(isAmericanoMatch);
    final setMode = scoringUsesSetMode(scoringType, scoringConfig);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: tournamentClassificationTitle(format, scoringType, scoringConfig)),
      const SizedBox(height: 8),
      AppCard(
        color: AppColors.faint,
        padding: const EdgeInsets.all(11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(scoringEmoji(scoringType), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            tournamentClassificationSummary(
              format,
              scoringType,
              scoringConfig: scoringConfig,
              tieBreakers: tieBreakers,
            ),
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12, height: 1.25),
          )),
        ]),
      ),
      const SizedBox(height: 8),
      TournamentStandingsSummaryGrid(
        standings: standings,
        matches: matches,
        scoringType: scoringType,
        scoringConfig: scoringConfig,
      ),
      const SizedBox(height: 8),
      AppCard(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 14,
            horizontalMargin: 6,
            headingTextStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11),
            dataTextStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 12),
            columns: _columns(isAmericano, setMode),
            rows: List.generate(standings.length, (index) {
              final s = standings[index];
              return DataRow(cells: _cells(s, index, isAmericano, setMode));
            }),
          ),
        ),
      ),
      const SizedBox(height: 10),
      TournamentTieBreakersCompactCard(tieBreakers: tieBreakers, scoringType: scoringType, scoringConfig: scoringConfig),
      const SizedBox(height: 12),
      SectionHeader(title: 'Detalle de posiciones'),
      const SizedBox(height: 8),
      ...List.generate(standings.length, (index) => TournamentStandingRankCard(
        position: index + 1,
        standing: standings[index],
        scoringType: scoringType,
        scoringConfig: scoringConfig,
        explanation: standingRankReason(index, standings, tieBreakers, scoringType, scoringConfig),
      )),
    ]);
  }
}

class TournamentStandingsSummaryGrid extends StatelessWidget {
  final List<TeamStanding> standings;
  final List<Map<String, dynamic>> matches;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  const TournamentStandingsSummaryGrid({super.key, required this.standings, required this.matches, required this.scoringType, required this.scoringConfig});

  @override
  Widget build(BuildContext context) {
    final played = matches.where(matchCountsForStandings).length;
    final pending = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).length;
    final leader = standings.first;
    final diff = bestGoalDifference(standings);
    final secondary = scoringUsesSetMode(scoringType, scoringConfig) ? bestSecondaryDifference(standings) : bestGoalsFor(standings);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth > 520 ? (constraints.maxWidth - 16) / 3 : (constraints.maxWidth - 8) / 2;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        SizedBox(width: width, child: TournamentMetricCard(title: 'Líder', value: leader.name, detail: '${leader.points} pts', icon: Icons.emoji_events_rounded, color: AppColors.orange)),
        SizedBox(width: width, child: TournamentMetricCard(title: 'Jugados', value: '$played partidos', detail: pending == 0 ? 'Todo cerrado' : '$pending pendientes', icon: Icons.done_all_rounded, color: pending == 0 ? AppColors.green : AppColors.red)),
        SizedBox(width: width, child: TournamentMetricCard(title: 'Mejor ${scoringTableDifferenceLabel(scoringType, scoringConfig)}', value: diff.name, detail: '${diff.goalDifference >= 0 ? '+' : ''}${diff.goalDifference}', icon: Icons.trending_up_rounded, color: AppColors.blue)),
        SizedBox(width: width, child: TournamentMetricCard(title: scoringUsesSetMode(scoringType, scoringConfig) ? 'Mejor ${scoringSecondaryDifferenceLabel(scoringType, scoringConfig)}' : 'Más a favor', value: secondary.name, detail: scoringUsesSetMode(scoringType, scoringConfig) ? '${secondary.secondaryDifference >= 0 ? '+' : ''}${secondary.secondaryDifference}' : '${secondary.goalsFor}', icon: Icons.add_chart_rounded, color: AppColors.violet)),
      ]);
    });
  }
}

class TournamentTieBreakersCompactCard extends StatelessWidget {
  final List<String> tieBreakers;
  final String scoringType;
  final Map<String, dynamic>? scoringConfig;
  const TournamentTieBreakersCompactCard({super.key, required this.tieBreakers, required this.scoringType, this.scoringConfig});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.faint,
    padding: const EdgeInsets.all(11),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.rule_rounded, color: AppColors.teal, size: 18)),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Orden de clasificacion', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 3),
        Text(standingsOrderTextForScoring(tieBreakers, scoringType, scoringConfig), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25, fontSize: 11.5)),
      ])),
    ]),
  );
}

class TournamentTieBreakersInfoCard extends StatelessWidget {
  final List<String> tieBreakers;
  final String scoringType;
  final Map<String, dynamic>? scoringConfig;
  const TournamentTieBreakersInfoCard({super.key, required this.tieBreakers, this.scoringType = 'general', this.scoringConfig});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.blueSoft,
    padding: const EdgeInsets.all(12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.rule_rounded, color: AppColors.blue, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Orden de clasificacion', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(standingsOrderTextForScoring(tieBreakers, scoringType, scoringConfig), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25)),
      ])),
    ]),
  );
}

class TournamentStandingRankCard extends StatelessWidget {
  final int position;
  final TeamStanding standing;
  final String scoringType;
  final dynamic scoringConfig;
  final String explanation;
  const TournamentStandingRankCard({super.key, required this.position, required this.standing, required this.scoringType, this.scoringConfig, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final podium = position <= 3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        color: podium ? AppColors.orangeSoft : AppColors.white,
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: podium ? AppColors.orange : AppColors.faint, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('$position', style: TextStyle(color: podium ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(standing.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 4),
            Text(standingDetailText(standing, scoringType, scoringConfig), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 4),
            Text(explanation, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800, fontSize: 11, height: 1.2)),
          ])),
          const SizedBox(width: 8),
          Text('${standing.points} pts', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
      ),
    );
  }
}

class TournamentStandingTile extends StatelessWidget {
  final TeamStanding standing;
  final String scoringType;
  final dynamic scoringConfig;
  final bool highlighted;
  const TournamentStandingTile({super.key, required this.standing, required this.scoringType, this.scoringConfig, this.highlighted = false});

  @override
  Widget build(BuildContext context) => AppCard(
    color: highlighted ? AppColors.orangeSoft : AppColors.white,
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: highlighted ? AppColors.orange : AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: Icon(highlighted ? Icons.emoji_events_rounded : Icons.groups_rounded, color: highlighted ? Colors.white : AppColors.teal)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(standing.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
        const SizedBox(height: 4),
        Text(standingDetailText(standing, scoringType, scoringConfig), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      Text('${standing.points} pts', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 16)),
    ]),
  );
}

class TournamentStatsPanel extends StatelessWidget {
  final List<TeamStanding> standings;
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> teams;
  final String format;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  const TournamentStatsPanel({super.key, required this.standings, required this.matches, required this.teams, required this.format, required this.scoringType, required this.scoringConfig});

  @override
  Widget build(BuildContext context) {
    final played = matches.where(matchCountsForStandings).length;
    final pending = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).length;
    if (standings.isEmpty || played == 0) {
      return EmptySlim(
        icon: Icons.query_stats_rounded,
        title: 'Sin estadísticas útiles todavía',
        body: 'Registra resultados para ver líder, victorias, diferencia y estadísticas adaptadas al deporte.',
      );
    }

    final leader = standings.first;
    final wins = bestWins(standings);
    final diff = bestGoalDifference(standings);
    final pointsFor = bestGoalsFor(standings);
    final secondaryDiff = scoringUsesSetMode(scoringType, scoringConfig) ? bestSecondaryDifference(standings) : null;
    final secondaryFor = scoringUsesSetMode(scoringType, scoringConfig) ? bestSecondaryFor(standings) : null;
    final rate = bestWinRate(standings);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: tournamentClassificationTitle(format, scoringType, scoringConfig)),
      const SizedBox(height: 8),
      AppCard(
        color: AppColors.faint,
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.insights_rounded, color: AppColors.teal, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(
            tournamentClassificationSummary(format, scoringType, scoringConfig: scoringConfig),
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25),
          )),
        ]),
      ),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth > 520 ? (constraints.maxWidth - 16) / 3 : (constraints.maxWidth - 8) / 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          SizedBox(width: width, child: TournamentMetricCard(title: 'Progreso', value: '$played jugados', detail: pending == 0 ? 'Completo' : '$pending pendientes', icon: Icons.task_alt_rounded, color: pending == 0 ? AppColors.green : AppColors.red)),
          SizedBox(width: width, child: TournamentMetricCard(title: 'Líder', value: leader.name, detail: '${leader.points} pts', icon: Icons.emoji_events_rounded, color: AppColors.orange)),
          SizedBox(width: width, child: TournamentMetricCard(title: 'Mejor % victorias', value: rate.name, detail: standingWinRateText(rate), icon: Icons.percent_rounded, color: AppColors.teal)),
          SizedBox(width: width, child: TournamentMetricCard(title: 'Más victorias', value: wins.name, detail: '${wins.wins} victorias', icon: Icons.done_all_rounded, color: AppColors.green)),
        ]);
      }),
      const SizedBox(height: 12),
      SectionHeader(title: 'Mejores marcas'),
      const SizedBox(height: 8),
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          TournamentStatsRow(icon: Icons.emoji_events_rounded, color: AppColors.orange, label: 'Líder', value: leader.name, detail: '${leader.points} pts'),
          const Divider(height: 1, indent: 58, color: AppColors.line),
          TournamentStatsRow(icon: Icons.done_all_rounded, color: AppColors.green, label: 'Más victorias', value: wins.name, detail: '${wins.wins}'),
          const Divider(height: 1, indent: 58, color: AppColors.line),
          TournamentStatsRow(icon: Icons.trending_up_rounded, color: AppColors.blue, label: 'Mejor ${scoringTableDifferenceLabel(scoringType, scoringConfig)}', value: diff.name, detail: '${diff.goalDifference >= 0 ? '+' : ''}${diff.goalDifference}'),
          const Divider(height: 1, indent: 58, color: AppColors.line),
          TournamentStatsRow(icon: Icons.add_chart_rounded, color: AppColors.violet, label: 'Más ${standingMainStatLabel(scoringType, scoringConfig).toLowerCase()} a favor', value: pointsFor.name, detail: '${pointsFor.goalsFor}'),
          if (secondaryDiff != null) ...[
            const Divider(height: 1, indent: 58, color: AppColors.line),
            TournamentStatsRow(icon: Icons.stacked_line_chart_rounded, color: AppColors.teal, label: 'Mejor ${scoringSecondaryDifferenceLabel(scoringType, scoringConfig)}', value: secondaryDiff.name, detail: '${secondaryDiff.secondaryDifference >= 0 ? '+' : ''}${secondaryDiff.secondaryDifference}'),
          ],
          if (secondaryFor != null) ...[
            const Divider(height: 1, indent: 58, color: AppColors.line),
            TournamentStatsRow(icon: Icons.sports_score_rounded, color: AppColors.blue, label: 'Más ${standingSecondaryStatLabel(scoringType, scoringConfig).toLowerCase()} a favor', value: secondaryFor.name, detail: '${secondaryFor.secondaryFor}'),
          ],
          const Divider(height: 1, indent: 58, color: AppColors.line),
          TournamentStatsRow(icon: Icons.pending_actions_rounded, color: pending == 0 ? AppColors.green : AppColors.red, label: 'Pendientes', value: '$pending partidos', detail: pending == 0 ? 'Todo cerrado' : 'Faltan resultados'),
        ]),
      ),
    ]);
  }
}

class TournamentStatsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String detail;
  const TournamentStatsRow({super.key, required this.icon, required this.color, required this.label, required this.value, required this.detail});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 19)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      ])),
      const SizedBox(width: 8),
      Text(detail, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    ]),
  );
}

class TournamentMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  const TournamentMetricCard({super.key, required this.title, required this.value, required this.detail, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
      const SizedBox(height: 4),
      Text(detail, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    ]),
  );
}



class TournamentSettingsEditPanel extends StatelessWidget {
  final String format;
  final List<Map<String, dynamic>> matches;
  final VoidCallback onAddParticipants;
  final VoidCallback onBulkSchedule;
  final VoidCallback onManualMatches;
  final VoidCallback onCheckIn;
  const TournamentSettingsEditPanel({
    super.key,
    required this.format,
    required this.matches,
    required this.onAddParticipants,
    required this.onBulkSchedule,
    required this.onManualMatches,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final canAddManualMatch = format == 'manual' || format == 'liga';
    return AppCard(
      color: AppColors.navyDeep,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Panel de edición', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
            SizedBox(height: 4),
            Text('Edita jugadores, fechas y partidos desde Ajustes para no saturar el resumen.', style: TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.25)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Añadir jugadores', icon: Icons.group_add_rounded, onTap: onAddParticipants)),
          const SizedBox(width: 8),
          Expanded(child: SecondaryButton(label: 'Cambiar fechas', icon: Icons.edit_calendar_rounded, onTap: matches.isEmpty ? () => showToast(context, 'No hay partidos para mover.', danger: true) : onBulkSchedule)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (canAddManualMatch) ...[
            Expanded(child: SecondaryButton(label: 'Añadir partido', icon: Icons.add_link_rounded, onTap: onManualMatches)),
            const SizedBox(width: 8),
          ],
          Expanded(child: SecondaryButton(label: 'Check-in', icon: Icons.how_to_reg_rounded, onTap: onCheckIn)),
        ]),
      ]),
    );
  }
}


class TournamentSettingsPanel extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> matches;
  final VoidCallback onRegenerate;
  final VoidCallback onManualMatches;
  final VoidCallback onBulkSchedule;
  final VoidCallback onAddParticipants;
  final VoidCallback onCheckIn;
  final VoidCallback onEditTournament;
  final VoidCallback onHistory;
  final ValueChanged<String> onSetStatus;
  final VoidCallback onDelete;
  const TournamentSettingsPanel({super.key, required this.tournament, required this.matches, required this.onRegenerate, required this.onManualMatches, required this.onBulkSchedule, required this.onAddParticipants, required this.onCheckIn, required this.onEditTournament, required this.onHistory, required this.onSetStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final format = AppData.text(tournament['format'], 'liga');
    final scoringType = AppData.text(tournament['scoring_type'], 'general');
    final scoringConfig = resolvedScoringConfig(scoringType, tournament['scoring_config']);
    final formatConfig = tournamentFormatConfig(tournament);
    final scheduleConfig = tournamentScheduleConfig(tournament);
    final tieBreakers = tournamentTieBreakers(tournament, scoringType);
    final status = AppData.text(tournament['status'], 'active');
    final scheduled = matches.where((m) => AppData.text(m['scheduled_at']).isNotEmpty).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Configuración del torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 10),
        TournamentReviewRow(label: 'Estado', value: tournamentStatusLabel(status)),
        TournamentReviewRow(label: 'Formato', value: tournamentFormatLabel(format)),
        TournamentReviewRow(label: 'Participantes', value: teamTypeLabel(AppData.text(tournament['team_type'], 'equipo'))),
        TournamentReviewRow(label: 'Puntuación', value: scoringConfigShortText(scoringType, scoringConfig)),
        TournamentReviewRow(label: 'Clasificación', value: tournamentClassificationTitle(format, scoringType, scoringConfig)),
        TournamentReviewRow(label: 'Orden', value: standingsOrderTextForScoring(tieBreakers, scoringType, scoringConfig)),
        TournamentReviewRow(label: 'Jornadas límite', value: AppData.intValue(formatConfig['max_rounds']) == 0 ? 'Todas' : '${AppData.intValue(formatConfig['max_rounds'])}'),
        TournamentReviewRow(label: 'Vueltas', value: '${AppData.intValue(formatConfig['legs'], 1)}'),
        TournamentReviewRow(label: 'Partidos con fecha', value: '$scheduled/${matches.length}'),
        TournamentReviewRow(label: 'Agenda', value: scheduleConfig['add_to_agenda'] == true ? 'Activada' : 'No'),
      ])),
      const SizedBox(height: 12),
      TournamentSettingsEditPanel(
        format: format,
        matches: matches,
        onAddParticipants: onAddParticipants,
        onBulkSchedule: onBulkSchedule,
        onManualMatches: onManualMatches,
        onCheckIn: onCheckIn,
      ),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Editar torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Cambia nombre, deporte y reglas. Si ya hay resultados, las reglas se bloquean para no romper la clasificación.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: 12),
        SecondaryButton(label: 'Editar nombre / deporte / reglas', icon: Icons.edit_note_rounded, onTap: onEditTournament),
        const SizedBox(height: 8),
        SecondaryButton(label: 'Ver historial de cambios', icon: Icons.history_rounded, onTap: onHistory),
      ])),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(format == 'manual' ? 'Partidos manuales' : 'Calendario y cruces', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Si ya hay resultados, la app bloquea la regeneración para no romper la liga. Rehaz el calendario solo antes de empezar.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: 12),
        SecondaryButton(label: format == 'manual' ? 'Añadir partidos manuales' : 'Regenerar partidos', icon: format == 'manual' ? Icons.add_link_rounded : Icons.refresh_rounded, onTap: format == 'manual' ? onManualMatches : onRegenerate),
        if (matches.isNotEmpty) ...[
          const SizedBox(height: 8),
          SecondaryButton(label: 'Mover jornada / cambiar fechas', icon: Icons.edit_calendar_rounded, onTap: onBulkSchedule),
        ],
      ])),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Estado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(label: const Text('Programado'), onPressed: () => onSetStatus('scheduled')),
          ActionChip(label: const Text('En curso'), onPressed: () => onSetStatus('active')),
          ActionChip(label: const Text('Pausado'), onPressed: () => onSetStatus('paused')),
          ActionChip(label: const Text('Finalizado'), onPressed: () => onSetStatus('finished')),
        ]),
      ])),
      const SizedBox(height: 12),
      TournamentPremiumSettingsCard(),
      const SizedBox(height: 12),
      DangerButton(label: 'Eliminar competición', icon: Icons.delete_outline_rounded, onTap: onDelete),
    ]);
  }
}

class TournamentTeamsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final String format;
  final String teamType;
  final String scoringType;
  final bool showSeeds;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final VoidCallback onAddMembers;
  final VoidCallback onCreatePair;
  const TournamentTeamsPanel({
    super.key,
    required this.teams,
    required this.matches,
    this.format = 'liga',
    this.teamType = 'equipo',
    this.scoringType = 'general',
    this.showSeeds = false,
    required this.onChanged,
    required this.onAdd,
    required this.onAddMembers,
    required this.onCreatePair,
  });

  @override
  Widget build(BuildContext context) {
    final isAmericano = format == 'americano';
    final allowMembers = isAmericano || teamType == 'individual';
    final allowPair = !isAmericano && teamType == 'pareja';
    final title = isAmericano
        ? 'Jugadores del americano'
        : teamType == 'pareja'
            ? 'Parejas participantes'
            : teamType == 'individual'
                ? 'Jugadores participantes'
                : 'Equipos participantes';
    final subtitle = isAmericano
        ? 'Ranking individual: no crees parejas fijas, Grupli las rota.'
        : teamType == 'pareja'
            ? 'Cada fila es una pareja. Mantén el formato Ana / Javi.'
            : teamType == 'individual'
                ? 'Cada fila es un jugador.'
                : 'Cada fila es un equipo. Ideal para fútbol, baloncesto, voleibol o esports.';
    final emptyBody = isAmericano
        ? 'Añade jugadores individuales. Las parejas se crearán automáticamente en cada ronda.'
        : teamType == 'pareja'
            ? 'Crea parejas desde miembros del grupo o escríbelas como Ana / Javi.'
            : teamType == 'individual'
                ? 'Añade jugadores desde miembros o escríbelos manualmente.'
                : 'Escribe los nombres de los equipos que participarán.';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TournamentParticipantsEditorHeader(
        teamsCount: teams.length,
        title: title,
        subtitle: subtitle,
        writeLabel: teamType == 'equipo' ? 'Escribir equipos' : teamType == 'pareja' ? 'Escribir parejas' : 'Escribir jugadores',
        showMembers: allowMembers,
        showPair: allowPair,
        onAddText: onAdd,
        onAddMembers: onAddMembers,
        onCreatePair: onCreatePair,
      ),
      const SizedBox(height: 12),
      if (teams.isEmpty)
        EmptySlim(icon: Icons.groups_rounded, title: 'Sin participantes', body: emptyBody)
      else
        ...teams.map((team) => TournamentTeamCard(team: team, matches: matches, showSeed: showSeeds, onChanged: onChanged)),
    ]);
  }
}

class TournamentTeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final List<Map<String, dynamic>> matches;
  final bool showSeed;
  final VoidCallback onChanged;
  const TournamentTeamCard({super.key, required this.team, required this.matches, this.showSeed = false, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final id = team['id'].toString();
    final played = matches.where((m) => matchCountsForStandings(m) && (AppData.text(m['team_a']) == id || AppData.text(m['team_b']) == id)).length;
    final scheduled = matches.where((m) => AppData.text(m['team_a']) == id || AppData.text(m['team_b']) == id).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ProfileAvatar(name: AppData.text(team['name'], 'Participante'), avatarUrl: AppData.text(team['avatar_url']), radius: 19),
          if (showSeed) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text('#${AppData.intValue(team['seed'])}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 11))),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(team['name'], 'Participante'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 3),
            Text('$played/$scheduled partidos jugados', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') renameTournamentTeamDialog(context, team: team, onChanged: onChanged);
              if (value == 'seed') setTournamentTeamSeedDialog(context, team: team, onChanged: onChanged);
              if (value == 'delete') deleteTournamentTeamDialog(context, team: team, matches: matches, onChanged: onChanged);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rename', child: Text('Renombrar')),
              if (showSeed) const PopupMenuItem(value: 'seed', child: Text('Cambiar cabeza de serie')),
              const PopupMenuItem(value: 'delete', child: Text('Retirar / eliminar')),
            ],
          ),
        ]),
      ),
    );
  }
}



class TournamentParticipantsEditorHeader extends StatelessWidget {
  final int teamsCount;
  final String title;
  final String subtitle;
  final String writeLabel;
  final bool showMembers;
  final bool showPair;
  final VoidCallback onAddText;
  final VoidCallback onAddMembers;
  final VoidCallback onCreatePair;
  const TournamentParticipantsEditorHeader({
    super.key,
    required this.teamsCount,
    this.title = 'Editor de participantes',
    this.subtitle = '',
    this.writeLabel = 'Escribir nombres / equipos',
    this.showMembers = true,
    this.showPair = true,
    required this.onAddText,
    required this.onAddMembers,
    required this.onCreatePair,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.faint,
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.groups_rounded, color: AppColors.red)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(subtitle.isEmpty ? '$teamsCount participante${teamsCount == 1 ? '' : 's'}' : '$teamsCount participante${teamsCount == 1 ? '' : 's'} · $subtitle', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
        ])),
      ]),
      const SizedBox(height: 12),
      if (showMembers || showPair) ...[
        Row(children: [
          if (showMembers) Expanded(child: SecondaryButton(label: 'Miembros', icon: Icons.group_add_rounded, onTap: onAddMembers)),
          if (showMembers && showPair) const SizedBox(width: 8),
          if (showPair) Expanded(child: SecondaryButton(label: 'Crear pareja', icon: Icons.people_rounded, onTap: onCreatePair)),
        ]),
        const SizedBox(height: 8),
      ],
      SecondaryButton(label: writeLabel, icon: Icons.edit_rounded, onTap: onAddText),
    ]),
  );
}

class TournamentPairDraft {
  final Map<String, dynamic> first;
  final Map<String, dynamic> second;
  final String name;
  const TournamentPairDraft({required this.first, required this.second, this.name = ''});
}

class TournamentEditorDraft {
  final String name;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  final Map<String, dynamic> formatConfig;
  final List<String> tieBreakers;
  final bool rulesChanged;
  const TournamentEditorDraft({
    required this.name,
    required this.scoringType,
    required this.scoringConfig,
    required this.formatConfig,
    required this.tieBreakers,
    required this.rulesChanged,
  });
}

Future<String?> showTournamentNamePromptDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String helper,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label, hintText: hint, helperText: helper),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Añadir')),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<List<Map<String, dynamic>>?> showTournamentMemberPickerDialog(BuildContext context, {required List<Map<String, dynamic>> members}) async {
  if (members.isEmpty) {
    await showToast(context, 'Este grupo todavía no tiene miembros para añadir.', danger: true);
    return null;
  }
  final selected = <String>{};
  final byId = <String, Map<String, dynamic>>{
    for (final member in members) AppData.text(member['user_id'], AppData.text(AppData.asMap(member['profiles'])['id'])): member,
  }..removeWhere((key, value) => key.isEmpty);

  return showDialog<List<Map<String, dynamic>>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Añadir miembros del grupo'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: members.map((member) {
            final id = AppData.text(member['user_id'], AppData.text(AppData.asMap(member['profiles'])['id']));
            final checked = selected.contains(id);
            return CheckboxListTile(
              value: checked,
              onChanged: id.isEmpty ? null : (value) => setLocal(() {
                if (value == true) {
                  selected.add(id);
                } else {
                  selected.remove(id);
                }
              }),
              secondary: ProfileAvatar(name: memberDisplayName(member), avatarUrl: memberAvatarUrl(member), radius: 18),
              title: Text(memberDisplayName(member), style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Miembro del grupo'),
              contentPadding: EdgeInsets.zero,
            );
          }).toList())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: selected.isEmpty ? null : () => Navigator.pop(dialogContext, selected.map((id) => byId[id]).whereType<Map<String, dynamic>>().toList()),
            child: Text('Añadir ${selected.length}'),
          ),
        ],
      ),
    ),
  );
}

Future<TournamentPairDraft?> showTournamentPairCreatorDialog(BuildContext context, {required List<Map<String, dynamic>> members}) async {
  if (members.length < 2) {
    await showToast(context, 'Necesitas al menos 2 miembros para crear una pareja.', danger: true);
    return null;
  }

  final ids = members.map((m) => AppData.text(m['user_id'], AppData.text(AppData.asMap(m['profiles'])['id']))).where((id) => id.isNotEmpty).toList();
  final byId = <String, Map<String, dynamic>>{
    for (final member in members) AppData.text(member['user_id'], AppData.text(AppData.asMap(member['profiles'])['id'])): member,
  }..removeWhere((key, value) => key.isEmpty);
  var firstId = ids.first;
  var secondId = ids.length > 1 ? ids[1] : ids.first;
  final nameController = TextEditingController();

  final result = await showDialog<TournamentPairDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) {
        final first = byId[firstId]!;
        final second = byId[secondId]!;
        final suggested = '${memberDisplayName(first)} / ${memberDisplayName(second)}';
        return AlertDialog(
          title: const Text('Crear pareja visual'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButtonFormField<String>(
              value: firstId,
              decoration: const InputDecoration(labelText: 'Jugador 1'),
              items: ids.map((id) => DropdownMenuItem(value: id, child: Text(memberDisplayName(byId[id]!)))).toList(),
              onChanged: (value) => setLocal(() {
                firstId = value ?? firstId;
                if (firstId == secondId) {
                  secondId = ids.firstWhere((id) => id != firstId, orElse: () => secondId);
                }
              }),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: secondId,
              decoration: const InputDecoration(labelText: 'Jugador 2'),
              items: ids.map((id) => DropdownMenuItem(value: id, child: Text(memberDisplayName(byId[id]!)))).toList(),
              onChanged: (value) => setLocal(() {
                secondId = value ?? secondId;
                if (firstId == secondId) {
                  firstId = ids.firstWhere((id) => id != secondId, orElse: () => firstId);
                }
              }),
            ),
            const SizedBox(height: 10),
            Row(children: [
              ProfileAvatar(name: memberDisplayName(first), avatarUrl: memberAvatarUrl(first), radius: 18),
              const SizedBox(width: 6),
              const Icon(Icons.add_rounded, color: AppColors.muted, size: 18),
              const SizedBox(width: 6),
              ProfileAvatar(name: memberDisplayName(second), avatarUrl: memberAvatarUrl(second), radius: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(suggested, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Nombre opcional de la pareja', hintText: suggested),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: firstId == secondId ? null : () => Navigator.pop(dialogContext, TournamentPairDraft(first: byId[firstId]!, second: byId[secondId]!, name: nameController.text.trim())),
              child: const Text('Crear pareja'),
            ),
          ],
        );
      },
    ),
  );
  nameController.dispose();
  return result;
}

Future<TournamentEditorDraft?> showTournamentEditorDialog(BuildContext context, {required Map<String, dynamic> tournament, required bool hasResults}) async {
  final nameController = TextEditingController(text: AppData.text(tournament['name']));
  final originalScoringType = AppData.text(tournament['scoring_type'], 'general');
  var scoringType = originalScoringType;
  var cfg = resolvedScoringConfig(originalScoringType, tournament['scoring_config']);
  final originalCfgJson = jsonEncode(cfg);
  final originalFormatConfig = tournamentFormatConfig(tournament);
  final originalFormatConfigJson = jsonEncode(originalFormatConfig);
  var formatConfig = Map<String, dynamic>.from(originalFormatConfig);
  final win = TextEditingController(text: '${scoringWinPoints(scoringType, cfg)}');
  final draw = TextEditingController(text: '${scoringDrawPoints(scoringType, cfg)}');
  final loss = TextEditingController(text: '${scoringLossPoints(scoringType, cfg)}');
  final target = TextEditingController(text: '${AppData.intValue(cfg['target_score'])}');
  final bestOf = TextEditingController(text: '${scoringBestOf(scoringType, cfg)}');
  final maxRounds = TextEditingController(text: '${AppData.intValue(formatConfig['max_rounds'])}');
  final legs = TextEditingController(text: '${AppData.intValue(formatConfig['legs'], 1)}');

  void applyType(String type) {
    scoringType = type;
    cfg = scoringConfigForType(type);
    win.text = '${scoringWinPoints(type, cfg)}';
    draw.text = '${scoringDrawPoints(type, cfg)}';
    loss.text = '${scoringLossPoints(type, cfg)}';
    target.text = '${AppData.intValue(cfg['target_score'])}';
    bestOf.text = '${scoringBestOf(type, cfg)}';
  }

  final result = await showDialog<TournamentEditorDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Editar torneo'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: nameController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nombre del torneo')),
          const SizedBox(height: 12),
          if (hasResults)
            AppCard(
              color: AppColors.tealSoft,
              padding: const EdgeInsets.all(10),
              child: const Text('Hay resultados registrados. Para proteger la tabla, el deporte y las reglas están bloqueados. Puedes cambiar el nombre.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25)),
            )
          else ...[
            const Text('Deporte', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TournamentSportEmojiPicker(value: scoringType, onChanged: (value) => setLocal(() => applyType(value))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: win, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Victoria'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: draw, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Empate'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: loss, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Derrota'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: target, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Objetivo'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: bestOf, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Mejor de'))),
            ]),
            const SizedBox(height: 12),
            const Text('Formato', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: maxRounds, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Jornadas límite'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: legs, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Vueltas'))),
            ]),
          ],
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final nextCfg = Map<String, dynamic>.from(cfg);
            nextCfg['win'] = int.tryParse(win.text.trim()) ?? scoringWinPoints(scoringType, cfg);
            nextCfg['draw'] = int.tryParse(draw.text.trim()) ?? scoringDrawPoints(scoringType, cfg);
            nextCfg['loss'] = int.tryParse(loss.text.trim()) ?? scoringLossPoints(scoringType, cfg);
            final targetScore = int.tryParse(target.text.trim()) ?? 0;
            if (targetScore > 0) nextCfg['target_score'] = targetScore;
            nextCfg['best_of'] = max(1, int.tryParse(bestOf.text.trim()) ?? scoringBestOf(scoringType, cfg));
            final nextFormat = Map<String, dynamic>.from(formatConfig);
            nextFormat['max_rounds'] = int.tryParse(maxRounds.text.trim()) ?? AppData.intValue(nextFormat['max_rounds']);
            nextFormat['legs'] = max(1, int.tryParse(legs.text.trim()) ?? AppData.intValue(nextFormat['legs'], 1));
            final rulesChanged = hasResults ? false : (scoringType != originalScoringType || jsonEncode(nextCfg) != originalCfgJson || jsonEncode(nextFormat) != originalFormatConfigJson);
            Navigator.pop(dialogContext, TournamentEditorDraft(
              name: nameController.text.trim(),
              scoringType: hasResults ? originalScoringType : scoringType,
              scoringConfig: hasResults ? resolvedScoringConfig(originalScoringType, tournament['scoring_config']) : nextCfg,
              formatConfig: hasResults ? originalFormatConfig : nextFormat,
              tieBreakers: hasResults ? tournamentTieBreakers(tournament, originalScoringType) : defaultTieBreakers(scoringType),
              rulesChanged: rulesChanged,
            ));
          }, child: const Text('Guardar')),
        ],
      ),
    ),
  );

  nameController.dispose();
  win.dispose();
  draw.dispose();
  loss.dispose();
  target.dispose();
  bestOf.dispose();
  maxRounds.dispose();
  legs.dispose();
  return result;
}

Future<void> showTournamentHistoryDialog(BuildContext context, {required Map<String, dynamic> tournament, required List<Map<String, dynamic>> matches, required List<Map<String, dynamic>> teams}) async {
  final names = teamNameMap(teams);
  final items = <Map<String, dynamic>>[];
  for (final match in matches) {
    final title = '${tournamentMatchSideName(match, names, true)} vs ${tournamentMatchSideName(match, names, false)}';
    for (final entry in matchResultHistory(match)) {
      items.add({
        'title': title,
        'text': matchHistoryEntryText(entry),
        'at': AppData.text(entry['at']),
      });
    }
  }
  items.sort((a, b) => AppData.text(b['at']).compareTo(AppData.text(a['at'])));
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Historial del torneo'),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Text('Todavía no hay cambios registrados en resultados o partidos.')
            : SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: items.take(30).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  color: AppColors.faint,
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppData.text(item['title']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(AppData.text(item['text']), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
                  ]),
                ),
              )).toList())),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
      ],
    ),
  );
}


Future<void> showMatchScheduleDialog(BuildContext context, {required Map<String, dynamic> match, Map<String, dynamic>? group, String tournamentName = 'Torneo', required List<Map<String, dynamic>> teams, required VoidCallback onChanged}) async {
  final scheduled = DateTime.tryParse(AppData.text(match['scheduled_at']))?.toLocal();
  DateTime selectedDate = scheduled ?? DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = scheduled == null ? const TimeOfDay(hour: 20, minute: 0) : TimeOfDay(hour: scheduled.hour, minute: scheduled.minute);
  final duration = TextEditingController(text: AppData.text(match['duration_minutes']).isEmpty ? '60' : AppData.text(match['duration_minutes']));
  final location = TextEditingController(text: AppData.text(match['location']));
  final court = TextEditingController(text: AppData.text(match['court_name']));
  final notes = TextEditingController(text: AppData.text(match['notes']));
  var clearDate = false;
  var syncAgenda = group != null && AppData.text(match['status']) != 'cancelled' && AppData.text(match['status']) != 'bye';

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Fecha del partido'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
                locale: const Locale('es', 'ES'),
              );
              if (picked != null) setLocal(() { selectedDate = picked; clearDate = false; });
            })),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
              final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
              if (picked != null) setLocal(() { selectedTime = picked; clearDate = false; });
            })),
          ]),
          CheckboxListTile(
            value: clearDate,
            onChanged: (v) => setLocal(() => clearDate = v == true),
            contentPadding: EdgeInsets.zero,
            title: const Text('Dejar sin fecha'),
          ),
          TextField(controller: duration, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Duración en minutos')),
          const SizedBox(height: 8),
          TextField(controller: location, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación')),
          const SizedBox(height: 8),
          TextField(controller: court, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pista / mesa / campo')),
          const SizedBox(height: 8),
          TextField(controller: notes, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notas')),
          if (group != null) CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: syncAgenda,
            onChanged: clearDate ? null : (v) => setLocal(() => syncAgenda = v == true),
            title: Text(AppData.text(match['event_id']).isEmpty ? 'Añadir también a Agenda' : 'Actualizar evento de Agenda'),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, 'save'), child: const Text('Guardar')),
        ],
      ),
    ),
  );

  try {
    if (result == 'save') {
      final start = clearDate ? null : DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
      await AppData.updateMatchSchedule(match['id'].toString(), start, int.tryParse(duration.text.trim()) ?? 60, location.text, court.text, notes.text);
      if (syncAgenda && start != null && group != null) {
        final updated = Map<String, dynamic>.from(match)
          ..['scheduled_at'] = start.toUtc().toIso8601String()
          ..['duration_minutes'] = int.tryParse(duration.text.trim()) ?? 60
          ..['location'] = location.text
          ..['court_name'] = court.text
          ..['notes'] = notes.text;
        await AppData.syncMatchAgendaEvent(
          groupId: group['id'].toString(),
          tournamentName: tournamentName,
          match: updated,
          teamNames: teamNameMap(teams),
        );
      }
      onChanged();
    }
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  } finally {
    duration.dispose();
    location.dispose();
    court.dispose();
    notes.dispose();
  }
}


Future<void> showTournamentBulkScheduleDialog(
  BuildContext context, {
  required Map<String, dynamic> tournament,
  required Map<String, dynamic> group,
  required List<Map<String, dynamic>> teams,
  required List<Map<String, dynamic>> matches,
  required VoidCallback onChanged,
}) async {
  if (matches.isEmpty) {
    await showToast(context, 'No hay partidos para reprogramar.', danger: true);
    return;
  }

  final movable = matches.where((m) {
    final status = AppData.text(m['status'], 'pending');
    return status != 'played' && status != 'cancelled' && status != 'bye';
  }).toList();

  if (movable.isEmpty) {
    await showToast(context, 'No hay partidos pendientes que se puedan mover.', danger: true);
    return;
  }

  final rounds = movable.map((m) => AppData.intValue(m['round'], 1)).toSet().toList()..sort();
  String scope = 'round_${rounds.first}';
  final firstScheduled = movable
      .map((m) => DateTime.tryParse(AppData.text(m['scheduled_at']))?.toLocal())
      .whereType<DateTime>()
      .toList()
    ..sort();

  DateTime selectedDate = firstScheduled.isNotEmpty ? firstScheduled.first : DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = firstScheduled.isNotEmpty ? TimeOfDay(hour: firstScheduled.first.hour, minute: firstScheduled.first.minute) : const TimeOfDay(hour: 20, minute: 0);
  final duration = TextEditingController(text: AppData.text(movable.first['duration_minutes']).isEmpty ? '60' : AppData.text(movable.first['duration_minutes']));
  final interval = TextEditingController(text: '70');
  final location = TextEditingController(text: AppData.text(movable.first['location']));
  final court = TextEditingController(text: AppData.text(movable.first['court_name']).replaceFirst(RegExp(r'\s+\d+$'), ''));
  int courts = 1;
  bool syncAgenda = true;

  List<Map<String, dynamic>> selectedMatchesForScope(String value) {
    final base = movable.where((m) {
      if (value == 'all') return true;
      if (value == 'pending') return AppData.text(m['status'], 'pending') != 'played';
      if (value.startsWith('round_')) {
        final round = int.tryParse(value.replaceFirst('round_', '')) ?? 1;
        return AppData.intValue(m['round'], 1) == round;
      }
      return true;
    }).toList();
    base.sort((a, b) {
      final round = AppData.intValue(a['round']).compareTo(AppData.intValue(b['round']));
      if (round != 0) return round;
      return AppData.intValue(a['order_index']).compareTo(AppData.intValue(b['order_index']));
    });
    return base;
  }

  List<Widget> previewWidgets(String value) {
    final selected = selectedMatchesForScope(value).take(6).toList();
    final names = teamNameMap(teams);
    final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
    return List.generate(selected.length, (index) {
      final match = selected[index];
      final wave = index ~/ max(1, courts);
      final planned = start.add(Duration(minutes: wave * (int.tryParse(interval.text.trim()) ?? 70)));
      final courtLabel = courts <= 1
          ? court.text.trim()
          : (court.text.trim().isEmpty ? 'Pista ${(index % courts) + 1}' : '${court.text.trim()} ${(index % courts) + 1}');
      final a = tournamentMatchSideName(match, names, true);
      final b = tournamentMatchSideName(match, names, false);
      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 88, child: Text(DateFormat('EEE d · HH:mm', 'es_ES').format(planned), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11))),
          Expanded(child: Text('$a vs $b', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12))),
          if (courtLabel.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(courtLabel, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11)),
          ],
        ]),
      );
    });
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) {
        final selected = selectedMatchesForScope(scope);
        return AlertDialog(
          title: const Text('Reprogramar partidos'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              DropdownButtonFormField<String>(
                value: scope,
                decoration: const InputDecoration(labelText: 'Qué quieres mover'),
                items: [
                  for (final round in rounds) DropdownMenuItem(value: 'round_$round', child: Text('Jornada $round completa')),
                  const DropdownMenuItem(value: 'pending', child: Text('Todos los pendientes')),
                  const DropdownMenuItem(value: 'all', child: Text('Todos los no jugados')),
                ],
                onChanged: (v) => setLocal(() => scope = v ?? scope),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    locale: const Locale('es', 'ES'),
                  );
                  if (picked != null) setLocal(() => selectedDate = picked);
                })),
                const SizedBox(width: 8),
                Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
                  final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
                  if (picked != null) setLocal(() => selectedTime = picked);
                })),
              ]),
              const SizedBox(height: 10),
              TextField(controller: location, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación')),
              const SizedBox(height: 8),
              TextField(controller: court, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombre base pista/mesa', hintText: 'Pista, Mesa, Campo...')),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Text('Pistas/mesas simultáneas', style: TextStyle(fontWeight: FontWeight.w900))),
                IconButton(onPressed: courts <= 1 ? null : () => setLocal(() => courts--), icon: const Icon(Icons.remove_circle_outline_rounded)),
                Text('$courts', style: const TextStyle(fontWeight: FontWeight.w900)),
                IconButton(onPressed: courts >= 12 ? null : () => setLocal(() => courts++), icon: const Icon(Icons.add_circle_outline_rounded)),
              ]),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: syncAgenda,
                onChanged: (v) => setLocal(() => syncAgenda = v == true),
                title: const Text('Sincronizar con Agenda'),
                subtitle: const Text('Crea o actualiza los eventos vinculados.'),
              ),
              const SizedBox(height: 8),
              Text('Vista previa · ${selected.length} partido${selected.length == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...previewWidgets(scope),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: selected.isEmpty ? null : () => Navigator.pop(dialogContext, true), child: const Text('Guardar fechas')),
          ],
        );
      },
    ),
  );

  if (result != true) {
    duration.dispose();
    interval.dispose();
    location.dispose();
    court.dispose();
    return;
  }

  final selected = selectedMatchesForScope(scope);
  final ok = await confirmAction(
    context,
    title: '¿Guardar nueva programación?',
    body: 'Se actualizarán ${selected.length} partido${selected.length == 1 ? '' : 's'} con las fechas de la vista previa. Si están vinculados a Agenda, también se actualizarán los eventos.',
    confirmLabel: 'Guardar fechas',
  );
  if (ok != true) {
    duration.dispose();
    interval.dispose();
    location.dispose();
    court.dispose();
    return;
  }

  try {
    final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
    await AppData.bulkScheduleTournamentMatches(
      groupId: group['id'].toString(),
      tournamentName: AppData.text(tournament['name'], 'Torneo'),
      matches: selected,
      teams: teams,
      firstStart: start,
      durationMinutes: int.tryParse(duration.text.trim()) ?? 60,
      intervalMinutes: int.tryParse(interval.text.trim()) ?? 70,
      courtsCount: courts,
      location: location.text,
      courtName: court.text,
      syncAgenda: syncAgenda,
    );
    onChanged();
    if (context.mounted) await showToast(context, 'Calendario actualizado.');
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  } finally {
    duration.dispose();
    interval.dispose();
    location.dispose();
    court.dispose();
  }
}



bool tournamentUsesSetResultInput(Map<String, dynamic> match, String scoringType, [dynamic scoringConfig]) {
  return !isAmericanoMatch(match) && scoringUsesSetMode(scoringType, scoringConfig);
}

String tournamentResultInputTitleForMatch(Map<String, dynamic> match, String scoringType, [dynamic scoringConfig]) {
  if (isAmericanoMatch(match)) return 'Resultado de la ronda';
  return scoringResultInputTitle(scoringType, scoringConfig);
}

String tournamentResultHelpForMatch(Map<String, dynamic> match, String scoringType, [dynamic scoringConfig]) {
  if (isAmericanoMatch(match)) {
    return 'Americano: pon los puntos o juegos conseguidos por cada pareja en esta ronda. Cada jugador suma el marcador de su pareja al ranking individual.';
  }
  switch (scoringResultModel(scoringType, scoringConfig)) {
    case 'goals':
      return 'Fútbol: marcador por goles. Puede haber empate si la competición lo permite.';
    case 'sets_games':
      return 'Tenis/Pádel: registra cada set completo. La app calcula el marcador del partido, sets y juegos para desempates.';
    case 'sets_points':
      return 'Voleibol/Ping pong: registra cada parcial completo. La app calcula sets y puntos de set.';
    case 'total_points':
      return 'Baloncesto: marcador final por puntos. La app calcula puntos a favor, en contra y diferencia.';
    case 'target_points':
      return 'Dardos: pon los puntos o legs ganados según cómo juguéis. El marcador queda guardado para la tabla.';
    case 'games':
      return 'Juegos/partidas: pon las partidas, mapas o juegos ganados por cada lado.';
    default:
      return 'Marcador flexible: pon el resultado final de cada lado.';
  }
}

String tournamentResultSectionTitleForMatch(Map<String, dynamic> match, String scoringType, [dynamic scoringConfig]) {
  if (isAmericanoMatch(match)) return 'Marcador de la ronda';
  switch (scoringResultModel(scoringType, scoringConfig)) {
    case 'sets_games':
      return 'Sets del partido';
    case 'sets_points':
      return 'Parciales del partido';
    case 'goals':
      return 'Goles';
    case 'total_points':
      return 'Puntos finales';
    case 'target_points':
      return 'Puntuación';
    case 'games':
      return 'Partidas / juegos';
    default:
      return 'Marcador del partido';
  }
}

String tournamentSetRowLabel(String scoringType, int index, [dynamic scoringConfig]) {
  return scoringUsesPointSetMode(scoringType, scoringConfig) ? 'Parcial ${index + 1}' : 'Set ${index + 1}';
}

int tournamentDefaultSetRowsForSport(String scoringType, [dynamic scoringConfig]) {
  switch (scoringResultModel(scoringType, scoringConfig)) {
    case 'sets_games':
      return 3;
    case 'sets_points':
      return 5;
    default:
      return scoringUsesSetMode(scoringType, scoringConfig) ? 3 : 1;
  }
}

int tournamentInitialSetRowsForSport(String scoringType, [dynamic scoringConfig]) {
  final maxRows = max(scoringBestOf(scoringType, scoringConfig), tournamentDefaultSetRowsForSport(scoringType, scoringConfig));
  return max(1, min(maxRows, (maxRows / 2).floor() + 1));
}

Future<void> showMatchResultDialog(BuildContext context, {required Map<String, dynamic> match, required List<Map<String, dynamic>> teams, required String scoringType, Map<String, dynamic>? scoringConfig, required VoidCallback onChanged}) async {
  final names = teamNameMap(teams);
  final aName = tournamentMatchSideName(match, names, true);
  final bName = tournamentMatchSideName(match, names, false);
  final americano = isAmericanoMatch(match);
  final setMode = tournamentUsesSetResultInput(match, scoringType, scoringConfig);
  final aController = TextEditingController(text: AppData.text(match['score_a']));
  final bController = TextEditingController(text: AppData.text(match['score_b']));
  final initialSets = matchDetailSets(match);
  final configuredBestOf = scoringBestOf(scoringType, scoringConfig);
  final maxSetRows = max(configuredBestOf, tournamentDefaultSetRowsForSport(scoringType, scoringConfig));
  final initialSetRows = tournamentInitialSetRowsForSport(scoringType, scoringConfig);
  final targetScore = AppData.intValue(scoringConfig?['target_score'], scoringUsesGameSetMode(scoringType, scoringConfig) ? 6 : 25);
  final setRows = initialSets.isNotEmpty
      ? initialSets.map((set) => {'a': AppData.intValue(set['a']), 'b': AppData.intValue(set['b'])}).toList()
      : List<Map<String, int>>.generate(initialSetRows, (_) => {'a': 0, 'b': 0});
  int simpleA = int.tryParse(aController.text.trim()) ?? 0;
  int simpleB = int.tryParse(bController.text.trim()) ?? 0;
  final played = matchCountsForStandings(match);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('$aName vs $bName'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppCard(
            color: AppColors.faint,
            padding: const EdgeInsets.all(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(scoringEmoji(scoringType), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tournamentResultInputTitleForMatch(match, scoringType, scoringConfig), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(height: 3),
                Text(
                  tournamentResultHelpForMatch(match, scoringType, scoringConfig),
                  style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11.5, height: 1.25),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 10),
          if (!played) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (setMode) ...[
                ActionChip(
                  label: const Text('Local 2-0'),
                  onPressed: () => setDialogState(() {
                    setRows
                      ..clear()
                      ..addAll(List.generate(2, (_) => {'a': scoringUsesGameSetMode(scoringType, scoringConfig) ? 6 : targetScore, 'b': max(0, (scoringUsesGameSetMode(scoringType, scoringConfig) ? 6 : targetScore) - (scoringUsesGameSetMode(scoringType, scoringConfig) ? 2 : 7))}));
                  }),
                ),
                ActionChip(
                  label: const Text('Local 2-1'),
                  onPressed: () => setDialogState(() {
                    final win = scoringUsesGameSetMode(scoringType, scoringConfig) ? 6 : targetScore;
                    final lose = max(0, win - (scoringUsesGameSetMode(scoringType, scoringConfig) ? 2 : 7));
                    setRows
                      ..clear()
                      ..addAll([
                        {'a': win, 'b': lose},
                        {'a': lose, 'b': win},
                        {'a': win, 'b': lose},
                      ]);
                  }),
                ),
              ] else ...[
                ActionChip(label: const Text('1-0'), onPressed: () => setDialogState(() { simpleA = 1; simpleB = 0; })),
                ActionChip(label: const Text('2-1'), onPressed: () => setDialogState(() { simpleA = 2; simpleB = 1; })),
                ActionChip(label: const Text('0-1'), onPressed: () => setDialogState(() { simpleA = 0; simpleB = 1; })),
              ],
            ]),
            const SizedBox(height: 10),
          ],
          if (setMode) ...[
            Row(children: [
              Expanded(child: Text(tournamentResultSectionTitleForMatch(match, scoringType, scoringConfig), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
              Text('${setRows.length}/$maxSetRows', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            ...List.generate(setRows.length, (index) {
              final row = setRows[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TournamentSetScoreEditor(
                  label: tournamentSetRowLabel(scoringType, index, scoringConfig),
                  aName: aName,
                  bName: bName,
                  aScore: row['a'] ?? 0,
                  bScore: row['b'] ?? 0,
                  canRemove: setRows.length > 1,
                  onRemove: () => setDialogState(() => setRows.removeAt(index)),
                  onChangedA: (value) => setDialogState(() => row['a'] = value),
                  onChangedB: (value) => setDialogState(() => row['b'] = value),
                ),
              );
            }),
            if (setRows.length < maxSetRows) ...[
              const SizedBox(height: 2),
              SecondaryButton(
                label: scoringUsesPointSetMode(scoringType, scoringConfig) ? 'Añadir otro parcial' : 'Añadir otro set',
                icon: Icons.add_rounded,
                onTap: () => setDialogState(() => setRows.add({'a': 0, 'b': 0})),
              ),
            ],
          ] else ...[
            Text(tournamentResultSectionTitleForMatch(match, scoringType, scoringConfig), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 6),
            AppCard(
              color: AppColors.white,
              padding: const EdgeInsets.all(10),
              child: Column(children: [
                _TournamentScoreStepper(
                  name: aName,
                  value: simpleA,
                  onChanged: (value) => setDialogState(() => simpleA = value),
                ),
                const SizedBox(height: 8),
                _TournamentScoreStepper(
                  name: bName,
                  value: simpleB,
                  onChanged: (value) => setDialogState(() => simpleB = value),
                ),
              ]),
            ),
          ],
        ])),
        actions: [
          if (played) TextButton(onPressed: () => Navigator.pop(context, 'reopen'), child: const Text('Borrar resultado')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Guardar')),
        ],
      ),
    ),
  );
  final matchId = match['id'].toString();
  try {
    if (result == 'reopen') {
      await AppData.reopenMatch(matchId);
      onChanged();
      return;
    }
    if (result != 'save') return;
    if (setMode) {
      final parsed = setRows.where((set) => (set['a'] ?? 0) > 0 || (set['b'] ?? 0) > 0).map((set) => {'a': set['a'] ?? 0, 'b': set['b'] ?? 0}).toList();
      if (parsed.isEmpty) {
        if (context.mounted) await showToast(context, 'Introduce al menos un set válido.', danger: true);
        return;
      }
      if (parsed.any((set) => set['a'] == set['b'])) {
        if (context.mounted) await showToast(context, 'Un set no puede acabar empatado.', danger: true);
        return;
      }
      final setsA = parsed.where((set) => set['a']! > set['b']!).length;
      final setsB = parsed.where((set) => set['b']! > set['a']!).length;
      if (setsA == setsB) {
        if (context.mounted) await showToast(context, 'En este deporte no puede quedar empate a sets.', danger: true);
        return;
      }
      final bestOf = maxSetRows;
      final neededSets = (bestOf / 2).floor() + 1;
      final winnerSets = max(setsA, setsB);
      if (parsed.length > bestOf) {
        if (context.mounted) await showToast(context, 'Hay demasiados parciales para este partido.', danger: true);
        return;
      }
      if (!americano) {
        if (winnerSets > neededSets) {
          if (context.mounted) await showToast(context, 'Hay demasiados sets para un partido al mejor de $bestOf.', danger: true);
          return;
        }
        if (winnerSets < neededSets) {
          if (context.mounted) await showToast(context, 'El ganador debe llegar a $neededSets set${neededSets == 1 ? '' : 's'}.', danger: true);
          return;
        }
      }
      final gamesA = parsed.fold<int>(0, (sum, set) => sum + AppData.intValue(set['a']));
      final gamesB = parsed.fold<int>(0, (sum, set) => sum + AppData.intValue(set['b']));
      await AppData.setMatchResult(matchId, setsA, setsB, details: {
        'sets': parsed,
        'sets_a': setsA,
        'sets_b': setsB,
        'games_a': gamesA,
        'games_b': gamesB,
        'scoring_type': scoringType,
        'score_model': scoringResultModel(scoringType, scoringConfig),
      });
    } else {
      final a = simpleA;
      final b = simpleB;
      if (a == 0 && b == 0) {
        if (context.mounted) await showToast(context, 'Introduce un marcador antes de guardar.', danger: true);
        return;
      }
      final allowDrawForMatch = americano ? false : scoringAllowDraw(scoringType, scoringConfig);
      if (!allowDrawForMatch && a == b) {
        if (context.mounted) await showToast(context, americano ? 'En Americano la ronda necesita un ganador.' : 'Este sistema no permite empate.', danger: true);
        return;
      }
      await AppData.setMatchResult(matchId, a, b, details: {
        'scoring_type': scoringType,
        'score_model': americano ? 'americano_round' : scoringResultModel(scoringType, scoringConfig),
        if (americano) 'round_score_a': a,
        if (americano) 'round_score_b': b,
      });
    }
    onChanged();
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  } finally {
    aController.dispose();
    bController.dispose();
  }
}


class _TournamentSetScoreEditor extends StatelessWidget {
  final String label;
  final String aName;
  final String bName;
  final int aScore;
  final int bScore;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<int> onChangedA;
  final ValueChanged<int> onChangedB;

  const _TournamentSetScoreEditor({
    required this.label,
    required this.aName,
    required this.bName,
    required this.aScore,
    required this.bScore,
    required this.canRemove,
    required this.onRemove,
    required this.onChangedA,
    required this.onChangedB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
          if (canRemove)
            IconButton(
              tooltip: 'Quitar set',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
        ]),
        const SizedBox(height: 8),
        _TournamentScoreStepper(
          name: aName,
          value: aScore,
          onChanged: onChangedA,
        ),
        const SizedBox(height: 8),
        _TournamentScoreStepper(
          name: bName,
          value: bScore,
          onChanged: onChangedB,
        ),
      ]),
    );
  }
}

class _TournamentScoreStepper extends StatelessWidget {
  final String name;
  final int value;
  final ValueChanged<int> onChanged;

  const _TournamentScoreStepper({required this.name, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
        ),
      ),
      IconButton.filledTonal(
        visualDensity: VisualDensity.compact,
        onPressed: value <= 0 ? null : () => onChanged(value - 1),
        icon: const Icon(Icons.remove_rounded, size: 18),
      ),
      SizedBox(
        width: 46,
        child: Text(
          value.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ),
      IconButton.filled(
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
        onPressed: () => onChanged(value + 1),
        icon: const Icon(Icons.add_rounded, size: 18),
      ),
    ]);
  }
}

Future<void> showSpecialMatchResultDialog(BuildContext context, {required Map<String, dynamic> match, required List<Map<String, dynamic>> teams, required VoidCallback onChanged}) async {
  final names = teamNameMap(teams);
  final aId = AppData.text(match['team_a']);
  final bId = AppData.text(match['team_b']);
  final aName = names[aId] ?? 'Local';
  final bName = names[bId] ?? 'Visitante';
  if (aId.isEmpty || bId.isEmpty || bId == 'null') {
    await showToast(context, 'Este partido no tiene dos participantes.', danger: true);
    return;
  }
  final note = TextEditingController();
  final action = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Resultado especial'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Úsalo para no presentados, abandonos o decisiones del administrador.', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(controller: note, minLines: 2, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nota opcional', hintText: 'Ej: avisó tarde, abandono, decisión del grupo...')),
        const SizedBox(height: 12),
        SecondaryButton(label: '$aName no se presentó', icon: Icons.person_off_rounded, onTap: () => Navigator.pop(dialogContext, 'no_show_a')),
        const SizedBox(height: 8),
        SecondaryButton(label: '$bName no se presentó', icon: Icons.person_off_rounded, onTap: () => Navigator.pop(dialogContext, 'no_show_b')),
        const SizedBox(height: 8),
        SecondaryButton(label: 'Victoria admin. $aName', icon: Icons.gavel_rounded, onTap: () => Navigator.pop(dialogContext, 'walkover_a')),
        const SizedBox(height: 8),
        SecondaryButton(label: 'Victoria admin. $bName', icon: Icons.gavel_rounded, onTap: () => Navigator.pop(dialogContext, 'walkover_b')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
      ],
    ),
  );
  try {
    if (action == 'no_show_a') {
      await AppData.setSpecialMatchResult(match['id'].toString(), winnerTeamId: bId, loserTeamId: aId, specialResult: 'no_show', note: note.text);
    } else if (action == 'no_show_b') {
      await AppData.setSpecialMatchResult(match['id'].toString(), winnerTeamId: aId, loserTeamId: bId, specialResult: 'no_show', note: note.text);
    } else if (action == 'walkover_a') {
      await AppData.setSpecialMatchResult(match['id'].toString(), winnerTeamId: aId, loserTeamId: bId, specialResult: 'walkover', note: note.text);
    } else if (action == 'walkover_b') {
      await AppData.setSpecialMatchResult(match['id'].toString(), winnerTeamId: bId, loserTeamId: aId, specialResult: 'walkover', note: note.text);
    } else {
      return;
    }
    onChanged();
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  } finally {
    note.dispose();
  }
}

Future<void> showMatchHistoryDialog(BuildContext context, {required Map<String, dynamic> match}) async {
  final history = matchResultHistory(match).reversed.toList();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Historial del partido'),
      content: SizedBox(
        width: double.maxFinite,
        child: history.isEmpty
            ? const Text('Todavía no hay cambios registrados.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: history.take(12).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(matchHistoryEntryText(item), style: const TextStyle(fontWeight: FontWeight.w700)),
                )).toList(),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
      ],
    ),
  );
}

Future<void> renameTournamentTeamDialog(BuildContext context, {required Map<String, dynamic> team, required VoidCallback onChanged}) async {
  final controller = TextEditingController(text: AppData.text(team['name']));
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Renombrar'),
      content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
      ],
    ),
  );
  controller.dispose();
  if (name == null) return;
  try {
    await AppData.renameTournamentTeam(team['id'].toString(), name);
    onChanged();
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  }
}

Future<void> setTournamentTeamSeedDialog(BuildContext context, {required Map<String, dynamic> team, required VoidCallback onChanged}) async {
  final controller = TextEditingController(text: AppData.text(team['seed']).isEmpty ? '1' : AppData.text(team['seed']));
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cabeza de serie'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Número de seed', helperText: '1 es el favorito principal. El cuadro se genera por este orden.'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
      ],
    ),
  );
  controller.dispose();
  final seed = int.tryParse((value ?? '').trim());
  if (seed == null) return;
  try {
    await AppData.updateTournamentTeamSeed(team['id'].toString(), seed);
    onChanged();
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  }
}

Future<void> deleteTournamentTeamDialog(BuildContext context, {required Map<String, dynamic> team, required List<Map<String, dynamic>> matches, required VoidCallback onChanged}) async {
  final teamId = team['id'].toString();
  final linked = matches.where((m) => AppData.text(m['team_a']) == teamId || AppData.text(m['team_b']) == teamId || americanoSideIds(m, 'side_a_ids').contains(teamId) || americanoSideIds(m, 'side_b_ids').contains(teamId)).toList();
  final played = linked.where(matchCountsForStandings).length;
  final ok = await confirmAction(
    context,
    title: linked.isEmpty ? '¿Eliminar participante?' : '¿Retirar participante?',
    body: linked.isEmpty
        ? 'Se eliminará definitivamente porque todavía no tiene partidos vinculados.'
        : 'Tiene ${linked.length} partido${linked.length == 1 ? '' : 's'} vinculado${linked.length == 1 ? '' : 's'}${played > 0 ? ' y $played con resultado' : ''}. Para no romper el historial, se marcará como retirado en lugar de borrarlo.',
    danger: true,
    confirmLabel: linked.isEmpty ? 'Eliminar' : 'Retirar',
  );
  if (ok != true) return;
  try {
    final action = await AppData.safeRemoveTournamentTeam(teamId);
    onChanged();
    if (context.mounted) await showToast(context, action == 'deleted' ? 'Participante eliminado.' : 'Participante retirado sin romper partidos.');
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  }
}

String defaultTournamentName(String format) {
  switch (format) {
    case 'eliminatoria': return 'Copa del grupo';
    case 'americano': return 'Americano del grupo';
    case 'manual': return 'Torneo manual';
    default: return 'Liga del grupo';
  }
}

String stepSubtitle(int step) {
  switch (step) {
    case 0: return 'Deporte primero: la app adapta todo lo demás.';
    case 1: return 'Solo se muestran formatos válidos para ese deporte.';
    case 2: return 'Participantes correctos: jugadores, parejas o equipos.';
    case 3: return 'Resultado real: goles, sets, puntos o ranking americano.';
    case 4: return 'Fechas, pistas y eventos de Agenda.';
    default: return 'Revisión completa antes de crear.';
  }
}

bool scoringSupportsAmericano(String type) => TournamentEngineV2.supportsAmericano(type);

List<TournamentDraftMatch> parseTournamentPairings(String raw) {
  final output = <TournamentDraftMatch>[];
  var fallbackRound = 1;
  for (final line in raw.split(RegExp(r'[\n;]+'))) {
    var clean = line.trim();
    if (clean.isEmpty) continue;
    var round = fallbackRound;
    final roundMatch = RegExp(r'(?:jornada|ronda|round)\s*(\d+)', caseSensitive: false).firstMatch(clean);
    if (roundMatch != null) round = int.tryParse(roundMatch.group(1) ?? '') ?? round;
    if (clean.contains(':')) clean = clean.substring(clean.indexOf(':') + 1).trim();
    final parts = clean.split(RegExp(r'\s+(?:vs\.?|contra|v)\s+|\s+-\s+', caseSensitive: false));
    if (parts.length < 2) continue;
    final a = parts.first.trim().replaceAll(RegExp(r'\s+'), ' ');
    final b = parts.sublist(1).join(' vs ').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (a.length < 2 || b.length < 2) continue;
    output.add(TournamentDraftMatch(round: round, teamAName: a, teamBName: b));
    fallbackRound = round;
  }
  return output;
}

List<String> tournamentNamesFromManualPairings(List<TournamentDraftMatch> pairs) {
  return mergeTournamentNames(pairs.expand((p) => [p.teamAName, p.teamBName]).toList());
}

List<String> mergeTournamentNames(List<String> values) {
  final seen = <String>{};
  final output = <String>[];
  for (final value in values) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) continue;
    final key = clean.toLowerCase();
    if (seen.add(key)) output.add(clean);
  }
  return output;
}

List<TournamentDraftMatch> previewPairingsForFormat(
  String format,
  List<String> names, {
  int legs = 1,
  int maxRounds = 0,
  int courts = 1,
}) {
  final clean = mergeTournamentNames(names);
  if (clean.length < 2) return const [];
  final rows = <TournamentDraftMatch>[];
  if (format == 'americano') {
    final generated = generateAmericanoRoundsIds(clean, rounds: maxRounds > 0 ? maxRounds : 5, courts: courts);
    return generated.map((item) => TournamentDraftMatch(
      round: item.round,
      teamAName: item.sideA.join(' / '),
      teamBName: item.sideB.join(' / '),
    )).toList();
  }

  if (format == 'eliminatoria') {
    final targetBracket = nextPowerOfTwoAtLeast(clean.length);
    final byes = max(0, targetBracket - clean.length);
    final byeNames = clean.take(byes).toList();
    final playNames = clean.skip(byes).toList();
    final byeRows = byeNames.map((name) => TournamentDraftMatch(round: 1, teamAName: name, teamBName: 'Pase directo')).toList();
    final playRows = <TournamentDraftMatch>[];
    var left = 0;
    var right = playNames.length - 1;
    while (left < right) {
      playRows.add(TournamentDraftMatch(round: 1, teamAName: playNames[left], teamBName: playNames[right]));
      left++;
      right--;
    }
    final maxRows = max(byeRows.length, playRows.length);
    for (var i = 0; i < maxRows; i++) {
      if (i < byeRows.length) rows.add(byeRows[i]);
      if (i < playRows.length) rows.add(playRows[i]);
    }
    return rows;
  }

  final rotation = <String?>[...clean];
  if (rotation.length.isOdd) rotation.add(null);
  final n = rotation.length;
  final generated = <List<TournamentDraftMatch>>[];
  for (var round = 1; round < n; round++) {
    final roundRows = <TournamentDraftMatch>[];
    for (var i = 0; i < n ~/ 2; i++) {
      final a = rotation[i];
      final b = rotation[n - 1 - i];
      if (a == null || b == null) continue;
      final swap = round.isEven;
      roundRows.add(TournamentDraftMatch(round: round, teamAName: swap ? b : a, teamBName: swap ? a : b));
    }
    generated.add(roundRows);
    final fixed = rotation.first;
    final rest = rotation.sublist(1);
    rest.insert(0, rest.removeLast());
    rotation
      ..clear()
      ..add(fixed)
      ..addAll(rest);
  }
  final limited = maxRounds > 0 ? generated.take(maxRounds).toList() : generated;
  for (var leg = 1; leg <= max(1, legs); leg++) {
    for (var r = 0; r < limited.length; r++) {
      final targetRound = r + 1 + ((leg - 1) * limited.length);
      for (final match in limited[r]) {
        rows.add(leg.isOdd
            ? TournamentDraftMatch(round: targetRound, teamAName: match.teamAName, teamBName: match.teamBName)
            : TournamentDraftMatch(round: targetRound, teamAName: match.teamBName, teamBName: match.teamAName));
      }
    }
  }
  return rows;
}

int currentTournamentRound(List<Map<String, dynamic>> matches) {
  if (matches.isEmpty) return 1;
  final pending = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).toList();
  if (pending.isNotEmpty) return AppData.intValue(pending.first['round'], 1);
  return matches.fold<int>(1, (value, match) => max(value, AppData.intValue(match['round'], 1)));
}

List<Map<String, int>> parseSetScoreInput(String raw) {
  final sets = <Map<String, int>>[];
  for (final line in raw.split(RegExp(r'[\n,;]+'))) {
    final match = RegExp(r'(\d+)\s*[-/]\s*(\d+)').firstMatch(line.trim());
    if (match == null) continue;
    final a = int.tryParse(match.group(1) ?? '');
    final b = int.tryParse(match.group(2) ?? '');
    if (a == null || b == null) continue;
    sets.add({'a': a, 'b': b});
  }
  return sets;
}

TeamStanding bestWins(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final wins = b.wins.compareTo(a.wins);
    if (wins != 0) return wins;
    return b.points.compareTo(a.points);
  });
  return copy.first;
}

TeamStanding bestGoalDifference(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final diff = b.goalDifference.compareTo(a.goalDifference);
    if (diff != 0) return diff;
    return b.points.compareTo(a.points);
  });
  return copy.first;
}

TeamStanding bestGoalsFor(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final goals = b.goalsFor.compareTo(a.goalsFor);
    if (goals != 0) return goals;
    return b.points.compareTo(a.points);
  });
  return copy.first;
}


TeamStanding bestSecondaryDifference(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final diff = b.secondaryDifference.compareTo(a.secondaryDifference);
    if (diff != 0) return diff;
    return b.points.compareTo(a.points);
  });
  return copy.first;
}

TeamStanding bestSecondaryFor(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final value = b.secondaryFor.compareTo(a.secondaryFor);
    if (value != 0) return value;
    return b.points.compareTo(a.points);
  });
  return copy.first;
}

TeamStanding bestWinRate(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final rate = b.winRate.compareTo(a.winRate);
    if (rate != 0) return rate;
    final played = b.played.compareTo(a.played);
    if (played != 0) return played;
    return b.points.compareTo(a.points);
  });
  return copy.first;
}
