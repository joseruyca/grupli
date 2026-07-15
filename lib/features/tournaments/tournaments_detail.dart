part of grupli_app;
// ignore_for_file: override_on_non_overriding_member

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
    if (currentFormat == 'americano') return appIsEnglish ? 'Add players' : 'Añadir jugadores';
    if (currentTeamType == 'pareja') return appIsEnglish ? 'Add pairs' : 'Añadir parejas';
    if (currentTeamType == 'individual') return appIsEnglish ? 'Add players' : 'Añadir jugadores';
    return appIsEnglish ? 'Add teams' : 'Añadir equipos';
  }

  String get currentParticipantAddHint {
    if (currentFormat == 'americano') return 'Ana\nJavi\nMarta\nLuis';
    if (currentTeamType == 'pareja') return 'Ana / Javi\nMarta / Luis\nCris / Pablo';
    if (currentTeamType == 'individual') return 'Ana\nJavi\nMarta\nLuis';
    if (currentScoringType == 'football') return appIsEnglish ? 'The Penguins FC\nBlue Team\nSunday Crew' : 'Los Pingüinos FC\nEquipo Azul\nLa Banda del Domingo';
    return appIsEnglish ? 'Blue Team\nThe Underdogs\nFriday Crew' : 'Equipo Azul\nLos Invencibles\nGrupo del Viernes';
  }

  String get currentParticipantAddHelp {
    if (currentFormat == 'americano') return appIsEnglish ? 'One player per line. In Americano, Grupli creates rotating pairs automatically.' : 'Un jugador por línea. En Americano Grupli crea parejas rotativas automáticamente.';
    if (currentTeamType == 'pareja') return appIsEnglish ? 'One pair per line. Use the Ana / Javi format so it is clear.' : 'Una pareja por línea. Usa el formato Ana / Javi para que se entienda bien.';
    if (currentTeamType == 'individual') return appIsEnglish ? 'One player per line.' : 'Un jugador por línea.';
    return appIsEnglish ? 'One team per line. Do not add loose players if this competition is for teams.' : 'Un equipo por línea. No añadas jugadores sueltos si esta competición es por equipos.';
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(appIsEnglish ? 'Cancel' : 'Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(appIsEnglish ? 'Add' : 'Añadir')),
        ],
      ),
    );
    controller.dispose();
    final names = parseTournamentParticipantNames(value ?? '');
    if (names.isEmpty) return;
    try {
      await AppData.addTournamentTeams(widget.tournamentId, names);
      await load(soft: true);
      if (mounted) await showToast(context, appIsEnglish ? 'Participants added. Regenerate or add matches if needed.' : 'Participantes añadidos. Regenera o añade partidos si lo necesitas.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> addGroupMembersVisual() async {
    if (!currentCanAddMembers) {
      await showToast(context, currentTeamType == 'pareja'
          ? (appIsEnglish ? 'This competition uses pairs. Create pairs from the Pair button or write them as Ana / Javi.' : 'Esta competición usa parejas. Crea las parejas desde el botón Pareja o escríbelas como Ana / Javi.')
          : (appIsEnglish ? 'This competition uses teams. Add team names instead of loading individual members.' : 'Esta competición usa equipos. Añade nombres de equipos en vez de cargar miembros sueltos.'),
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
          added == 0 ? (appIsEnglish ? 'No new members were added: they were already in the tournament.' : 'No se añadieron miembros nuevos: ya estaban en el torneo.') : (appIsEnglish ? '$added participant${added == 1 ? '' : 's'} added.' : '$added participante${added == 1 ? '' : 's'} añadidos.'),
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
          ? (appIsEnglish ? 'Americano does not create fixed pairs: Grupli rotates them round by round.' : 'En Americano no se crean parejas fijas: Grupli las rota ronda a ronda.')
          : (appIsEnglish ? 'This competition is not configured as pairs.' : 'Esta competición no está configurada como parejas.'),
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
      if (mounted) await showToast(context, appIsEnglish ? 'Pair created.' : 'Pareja creada.');
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
      await showToast(context, appIsEnglish ? 'There are recorded results. To protect the table, only the name can be changed.' : 'Hay resultados registrados. Para proteger la tabla solo se permite cambiar el nombre.', danger: true);
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
      if (mounted) await showToast(context, appIsEnglish ? 'Tournament updated.' : 'Torneo actualizado.');
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
        title: Text(appIsEnglish ? 'Add manual matches' : 'Añadir partidos manuales'),
        content: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 10,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: appIsEnglish ? 'Round 2: Blue Team vs Red Team\nRound 2: Ana / Javi vs Marta / Luis' : 'Jornada 2: Equipo Azul vs Equipo Rojo\nJornada 2: Ana / Javi vs Marta / Luis'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(appIsEnglish ? 'Cancel' : 'Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(appIsEnglish ? 'Add' : 'Añadir')),
        ],
      ),
    );
    controller.dispose();
    final pairs = parseTournamentPairings(value ?? '');
    if (pairs.isEmpty) return;
    try {
      await AppData.addManualMatches(widget.tournamentId, tournamentTeams(t), pairs, scheduleConfig: tournamentScheduleConfig(t));
      await load(soft: true);
      if (mounted) await showToast(context, appIsEnglish ? 'Matches added.' : 'Partidos añadidos.');
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
      await showToast(context, appIsEnglish ? 'Add at least 2 participants.' : 'Añade al menos 2 participantes.', danger: true);
      return;
    }
    final matches = tournamentMatches(t);
    final results = matches.where(matchCountsForStandings).length;
    if (results > 0) {
      await showToast(context, appIsEnglish ? 'You cannot regenerate a league with results. Delete the results first or create another competition.' : 'No se puede regenerar una liga con resultados. Borra primero los resultados o crea otra competición.', danger: true);
      return;
    }
    if (matches.isNotEmpty) {
      final ok = await confirmAction(
        context,
        title: appIsEnglish ? 'Regenerate schedule?' : '¿Regenerar calendario?',
        body: appIsEnglish ? 'Current pending matches will be deleted to create a new schedule. Recorded results block this action.' : 'Se borrarán los partidos pendientes actuales para crear un calendario nuevo. Los resultados ya registrados bloquean esta acción.',
        danger: true,
        confirmLabel: appIsEnglish ? 'Regenerate' : 'Regenerar',
      );
      if (ok != true) return;
    }
    try {
      await AppData.generateMatches(widget.tournamentId, format, teams, formatConfig: tournamentFormatConfig(t), scheduleConfig: tournamentScheduleConfig(t));
      await load(soft: true);
      if (mounted) await showToast(context, appIsEnglish ? 'Schedule generated.' : 'Calendario generado.');
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
      if (mounted) await showToast(context, appIsEnglish ? 'Next round generated.' : 'Siguiente ronda generada.');
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
      if (mounted) await showToast(context, appIsEnglish ? 'Third-place match created.' : 'Partido por el tercer puesto creado.');
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
      title: appIsEnglish ? 'Delete competition?' : '¿Eliminar competición?',
      body: appIsEnglish ? 'Participants, matches and results will be deleted. This action cannot be undone.' : 'Se borrarán participantes, partidos y resultados. Esta acción no se puede deshacer.',
      danger: true,
      confirmLabel: appIsEnglish ? 'Delete' : 'Eliminar',
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
      PageHeader(title: t == null ? (appIsEnglish ? 'Competition' : 'Competición') : AppData.text(t['name'], appIsEnglish ? 'Competition' : 'Competición'), subtitle: t == null ? (appIsEnglish ? 'Loading...' : 'Cargando...') : '${tournamentFormatLabel(format)} · ${teamTypeLabel(AppData.text(t['team_type'], appIsEnglish ? 'team' : 'equipo'))} · ${appIsEnglish ? 'Round' : 'Jornada'} ${currentTournamentRound(matches)}', leading: true),
      const SizedBox(height: 14),
      if (loading && t == null)
        CenterLoader(label: appIsEnglish ? 'Loading competition...' : 'Cargando competición...')
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
