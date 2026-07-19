part of grupli_app;
// ignore_for_file: override_on_non_overriding_member

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
      locale: appLocale,
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
            Text('Añade participantes sin escribir de más.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
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
            Text(
              canAutoFillMembers
                  ? 'Toca un botón para añadir gente.'
                  : teamType == 'pareja'
                      ? 'Crea parejas en dos toques.'
                      : 'Pon un nombre claro al equipo.',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12),
            ),
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
            EmptySlim(icon: Icons.groups_rounded, title: 'Sin participantes todavía', body: canAutoFillMembers ? 'Usa Elegir miembros para añadir personas del grupo.' : teamType == 'pareja' ? 'Crea parejas o añade una pareja invitada.' : 'Añade equipos para preparar la competición.')
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
            title: const Text('Pegar nombres', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 13)),
            subtitle: const Text('Opcional', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
            children: [
              TextField(
                controller: participants,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: participantHintText(),
                  helperText: 'Uno por línea. Ejemplo: Ana / Javi.',
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
            const Expanded(child: Text('Partidos', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${manualRows.length} partidos'),
          ]),
          const SizedBox(height: 8),
          const Text('Crea cruces con selectores y añade fecha si quieres.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
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
            const Expanded(child: Text('Pegar cruces', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
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
              helperText: 'Opcional. Se usará si no hay partidos creados a mano.',
            ),
          ),
        ])),
      ] else if (format != 'americano') ...[
        const SizedBox(height: 12),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Cruces opcionales', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${parseTournamentPairings(pairings.text).length} escritos'),
          ]),
          const SizedBox(height: 8),
          const Text('Úsalo si quieres controlar los cruces desde el inicio.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 8),
          TextField(
            controller: pairings,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Jornada 1: Equipo Azul vs Los Invencibles\nJornada 1: Ana / Javi vs Marta / Luis',
              helperText: 'Si lo rellenas, sustituye al sorteo automático.',
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
            Text(
              format == 'americano'
                  ? 'Rondas y ranking.'
                  : format == 'manual'
                      ? 'Cruces manuales y fechas.'
                      : format == 'eliminatoria'
                          ? 'Cuadro y siguiente ronda.'
                          : 'Jornadas y clasificación.',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3),
            ),
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
          TournamentCounterRow(label: 'Rondas', value: americanoRounds, min: 1, max: 40, onChanged: (v) => setState(() => americanoRounds = v), helper: hasParticipants ? 'Recomendado: ${recommendedAmericanoRounds(participantNames.length, courtsCount)}' : 'Se ajusta al añadir jugadores'),
          TournamentCounterRow(label: 'Pistas / mesas', value: courtsCount, min: 1, max: 12, onChanged: (v) => setState(() => courtsCount = v), helper: '1 partido por pista'),
          const SizedBox(height: 8),
          Text(hasParticipants ? 'La app rota parejas y reparte descansos automáticamente.' : 'Añade jugadores para generar las primeras rondas.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          if (hasParticipants && participantNames.length >= 4 && americanoRounds != recommendedAmericanoRounds(participantNames.length, courtsCount)) ...[
            const SizedBox(height: 10),
            SecondaryButton(label: 'Usar ${recommendedAmericanoRounds(participantNames.length, courtsCount)} rondas', icon: Icons.auto_awesome_rounded, onTap: () => setState(() => americanoRounds = recommendedAmericanoRounds(participantNames.length, courtsCount))),
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
          Text(randomizePairings ? 'Recomendado: evita sesgos.' : 'Usa el orden como cabeza de serie.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
        ] else ...[
          Wrap(spacing: 8, runSpacing: 8, children: const [
            TournamentRuleChip(label: 'Todo editable'),
            TournamentRuleChip(label: 'Selector visual'),
            TournamentRuleChip(label: 'Fechas por partido'),
          ]),
          const SizedBox(height: 8),
          const Text('Ideal para cruces raros o eventos de un día.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
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
            Text(format == 'americano' ? 'Siguiente: jugadores' : format == 'manual' ? 'Siguiente: cruces manuales' : 'Siguiente: participantes', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              format == 'americano'
                  ? 'Grupli rota parejas y reparte descansos.'
                  : format == 'manual'
                      ? 'Después añades los cruces uno a uno.'
                      : format == 'eliminatoria'
                          ? 'Añade equipos y la app hace el cuadro.'
                          : 'Añade participantes y la app genera jornadas.',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12),
            ),
          ])),
        ]),
      ),
      if (hasParticipants) ...[
        const SizedBox(height: 14),
        SectionHeader(title: 'Vista previa'),
        const SizedBox(height: 8),
        if (preview.isEmpty)
          EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin cruces todavía', body: 'Revisa participantes o crea el primer cruce.')
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
                ? 'Cada jugador suma sus juegos reales aunque cambie de pareja.'
                : scoringUsesPointSetMode(scoringType, scoringConfig)
                    ? 'Cada jugador suma los puntos reales de sus parciales.'
                    : 'Cada jugador suma su marcador real y rota de pareja.',
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
          Wrap(spacing: 8, runSpacing: 8, children: [
            TournamentRuleChip(label: scoringUsesSetMode(scoringType, scoringConfig) ? 'Con parciales' : scoringScoreLabel(scoringType, scoringConfig)),
            TournamentRuleChip(label: scoringAllowDraw(scoringType, scoringConfig) ? 'Empate permitido' : 'Sin empate'),
            if (scoringUsesSetMode(scoringType, scoringConfig)) TournamentRuleChip(label: 'Mejor de $bestOf'),
          ]),
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
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', appDateLocale).format(firstMatchDate), icon: Icons.calendar_today_rounded, onTap: pickDate)),
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
        TournamentReviewRow(label: 'Partidos', value: '${matches.length}'),
        TournamentReviewRow(label: 'Resultado', value: '${scoringTypeLabel(scoringType)} · ${scoringConfigShortText(scoringType, scoringConfig)}'),
        TournamentReviewRow(label: 'Estadísticas', value: TournamentEngineV2.sportStatsSummary(scoringType)),
        TournamentReviewRow(label: 'Calendario', value: scheduleMatches ? '${DateFormat('d MMM', appDateLocale).format(firstMatchDate)} · ${firstMatchTime.format(context)}' : 'Sin fechas'),
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
