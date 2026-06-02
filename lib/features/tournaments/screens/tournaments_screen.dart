import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/confirm_dialog.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/segmented_control.dart';
import '../../../ui/status_chip.dart';
import '../../../ui/toast.dart';
import '../../../ui/group_bottom_nav.dart';
import '../tournament_calculator.dart';
import '../tournaments_repository.dart';

class TournamentsScreen extends StatefulWidget {
  final String groupId;
  const TournamentsScreen({super.key, required this.groupId});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = TournamentsRepository().tournaments(widget.groupId);
  }

  void _refresh() => setState(() => _future = TournamentsRepository().tournaments(widget.groupId));

  Future<void> _createTournament() async {
    await showAppBottomSheet(context, CreateTournamentSheet(groupId: widget.groupId));
    _refresh();
  }

  Future<void> _openTournament(Map<String, dynamic> tournament) async {
    await showAppBottomSheet(context, TournamentDetailSheet(tournamentId: tournament['id'].toString()));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      bottomNavigationBar: GroupBottomNav(groupId: widget.groupId, index: 3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Torneos',
          subtitle: 'Equipos, partidos, resultados y clasificación.',
          showBack: true,
          trailing: IconButton.filled(onPressed: _createTournament, icon: const Icon(Icons.add_rounded)),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));

            final tournaments = snapshot.data ?? [];
            if (tournaments.isEmpty) {
              return Column(children: [
                EmptyState(
                  icon: Icons.emoji_events_rounded,
                  title: 'Sin torneos',
                  body: 'Crea una liga, eliminatoria o formato americano para organizar resultados.',
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(label: 'Crear torneo', icon: Icons.add_rounded, onPressed: _createTournament),
              ]);
            }

            final active = tournaments.where((t) => (t['status'] ?? 'active') == 'active').length;

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _MiniMetric(label: 'Torneos', value: '${tournaments.length}', icon: Icons.emoji_events_rounded)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MiniMetric(label: 'Activos', value: '$active', icon: Icons.play_circle_outline_rounded, color: AppColors.success)),
              ]),
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(title: 'Mis torneos'),
              const SizedBox(height: AppSpacing.sm),
              ...tournaments.map((tournament) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  onTap: () => _openTournament(tournament),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _TournamentBadge(title: tournament['name']?.toString() ?? 'Torneo'),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(tournament['name']?.toString() ?? 'Torneo', style: AppTypography.section.copyWith(fontSize: 18))),
                        StatusChip(
                          label: (tournament['status'] == 'finished') ? 'Finalizado' : 'En curso',
                          color: (tournament['status'] == 'finished') ? AppColors.textMuted : AppColors.success,
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        MetaPill(icon: Icons.sports_score_rounded, text: _prettyFormat(tournament['format']?.toString() ?? 'liga')),
                        MetaPill(icon: Icons.groups_rounded, text: _prettyType(tournament['team_type']?.toString() ?? 'individual')),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Victoria ${tournament['points_win'] ?? 3} pts · Empate ${tournament['points_draw'] ?? 1} pts',
                        style: AppTypography.muted,
                      ),
                    ])),
                  ]),
                ),
              )),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(label: 'Crear torneo', icon: Icons.add_rounded, onPressed: _createTournament),
            ]);
          },
        ),
      ]),
    );
  }

  String _prettyFormat(String format) {
    switch (format) {
      case 'liga':
        return 'Liga';
      case 'eliminatoria':
        return 'Eliminatoria';
      case 'americano':
        return 'Americano';
      default:
        return format;
    }
  }

  String _prettyType(String type) {
    switch (type) {
      case 'individual':
        return 'Individual';
      case 'pareja':
        return 'Parejas';
      case 'equipo':
        return 'Equipos';
      default:
        return type;
    }
  }
}

class TournamentDetailSheet extends StatefulWidget {
  final String tournamentId;
  const TournamentDetailSheet({super.key, required this.tournamentId});

  @override
  State<TournamentDetailSheet> createState() => _TournamentDetailSheetState();
}

class _TournamentDetailSheetState extends State<TournamentDetailSheet> {
  late Future<_TournamentData> _future;
  String _tab = 'Tabla';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TournamentData> _load() async {
    final repo = TournamentsRepository();
    final tournament = await repo.tournament(widget.tournamentId);
    final teams = await repo.teams(widget.tournamentId);
    final matches = await repo.matches(widget.tournamentId);
    return _TournamentData(tournament: tournament, teams: teams, matches: matches);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _addTeam() async {
    await showAppBottomSheet(context, AddTeamSheet(tournamentId: widget.tournamentId));
    _refresh();
  }

  Future<void> _generateMatches(_TournamentData data) async {
    if (_busy) return;
    if (data.teams.length < 2) {
      AppToast.show(context, 'Añade al menos 2 equipos.', error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      final pairs = TournamentCalculator.roundRobinPairs(
        tournamentId: widget.tournamentId,
        teams: data.teams,
        existingMatches: data.matches,
      );
      if (pairs.isEmpty) {
        if (mounted) AppToast.show(context, 'Ya están generados todos los partidos.');
      } else {
        await TournamentsRepository().createMatches(pairs);
        if (mounted) AppToast.show(context, 'Partidos generados.');
      }
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFinished(_TournamentData data) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = (data.tournament['status'] ?? 'active') == 'finished' ? 'active' : 'finished';
      await TournamentsRepository().setTournamentStatus(widget.tournamentId, status);
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteTournament() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar torneo',
      message: 'Se borrarán equipos, partidos y resultados de este torneo.',
      confirmLabel: 'Eliminar',
    );
    if (!ok) return;

    try {
      await TournamentsRepository().deleteTournament(widget.tournamentId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TournamentData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
        if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));

        final data = snapshot.data!;
        final tournament = data.tournament;
        final standings = TournamentCalculator.standings(
          teams: data.teams,
          matches: data.matches,
          pointsWin: _toInt(tournament['points_win'], 3),
          pointsDraw: _toInt(tournament['points_draw'], 1),
        );
        final played = data.matches.where((m) => (m['status'] ?? 'pending') == 'played').length;

        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _TournamentBadge(title: tournament['name']?.toString() ?? 'Torneo'),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tournament['name']?.toString() ?? 'Torneo', style: AppTypography.section.copyWith(fontSize: 22)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                MetaPill(icon: Icons.sports_score_rounded, text: tournament['format']?.toString() ?? 'liga'),
                MetaPill(icon: Icons.groups_rounded, text: tournament['team_type']?.toString() ?? 'individual'),
                StatusChip(
                  label: (tournament['status'] == 'finished') ? 'Finalizado' : 'En curso',
                  color: (tournament['status'] == 'finished') ? AppColors.textMuted : AppColors.success,
                ),
              ]),
            ])),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(child: _CompactStat(label: 'Equipos', value: '${data.teams.length}')),
            const SizedBox(width: 8),
            Expanded(child: _CompactStat(label: 'Partidos', value: '${data.matches.length}')),
            const SizedBox(width: 8),
            Expanded(child: _CompactStat(label: 'Jugados', value: '$played')),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _Tabs(selected: _tab, values: const ['Tabla', 'Partidos', 'Equipos', 'Ajustes'], onChanged: (value) => setState(() => _tab = value)),
          const SizedBox(height: AppSpacing.lg),
          if (_tab == 'Tabla')
            _StandingsTable(rows: standings)
          else if (_tab == 'Partidos')
            _MatchesPanel(
              data: data,
              onGenerate: () => _generateMatches(data),
              onRefresh: _refresh,
            )
          else if (_tab == 'Equipos')
            _TeamsPanel(
              data: data,
              onAddTeam: _addTeam,
              onRefresh: _refresh,
            )
          else
            _TournamentSettingsPanel(
              data: data,
              busy: _busy,
              onToggleFinished: () => _toggleFinished(data),
              onDelete: _deleteTournament,
            ),
        ]);
      },
    );
  }

  int _toInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class _MatchesPanel extends StatelessWidget {
  final _TournamentData data;
  final VoidCallback onGenerate;
  final VoidCallback onRefresh;

  const _MatchesPanel({required this.data, required this.onGenerate, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (data.teams.length < 2) {
      return Column(children: [
        InfoPanel(
          icon: Icons.groups_rounded,
          title: 'Primero añade equipos',
          body: 'Necesitas al menos 2 equipos para generar partidos.',
          color: AppColors.amber,
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(label: 'Añadir equipo', icon: Icons.add_rounded, onPressed: () => showAppBottomSheet(context, AddTeamSheet(tournamentId: data.tournament['id'].toString())).then((_) => onRefresh())),
      ]);
    }

    if (data.matches.isEmpty) {
      return Column(children: [
        InfoPanel(
          icon: Icons.auto_awesome_rounded,
          title: 'Genera el calendario',
          body: 'Grupli creará una liga todos contra todos con los equipos actuales.',
          color: AppColors.teal,
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(label: 'Generar partidos', icon: Icons.sports_score_rounded, onPressed: onGenerate),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PrimaryButton(label: 'Generar partidos pendientes', icon: Icons.auto_awesome_rounded, onPressed: onGenerate),
      const SizedBox(height: AppSpacing.md),
      ...data.matches.map((match) {
        final played = (match['status'] ?? 'pending') == 'played';
        final teamA = TournamentCalculator.teamName(data.teams, match['team_a']);
        final teamB = TournamentCalculator.teamName(data.teams, match['team_b']);
        final score = played ? '${match['score_a']} - ${match['score_b']}' : 'Pendiente';
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                StatusChip(label: 'Ronda ${match['round'] ?? 1}', color: AppColors.lilac),
                const Spacer(),
                StatusChip(label: played ? 'Jugado' : 'Pendiente', color: played ? AppColors.success : AppColors.textMuted),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: Text(teamA, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800))),
                Text(score, style: AppTypography.section.copyWith(fontSize: 18, color: played ? AppColors.tealDark : AppColors.textMuted)),
                Expanded(child: Text(teamB, textAlign: TextAlign.right, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                  child: SecondaryButton(
                    label: played ? 'Editar resultado' : 'Meter resultado',
                    icon: Icons.edit_rounded,
                    onPressed: () => showAppBottomSheet(context, MatchResultSheet(match: match, teamA: teamA, teamB: teamB)).then((_) => onRefresh()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: () async {
                    try {
                      if (played) {
                        await TournamentsRepository().clearMatchResult(match['id'].toString());
                      } else {
                        await TournamentsRepository().deleteMatch(match['id'].toString());
                      }
                      onRefresh();
                    } catch (e) {
                      if (context.mounted) AppToast.show(context, humanError(e), error: true);
                    }
                  },
                  icon: Icon(played ? Icons.replay_rounded : Icons.delete_outline_rounded, color: played ? AppColors.textMuted : AppColors.danger),
                ),
              ]),
            ]),
          ),
        );
      }),
    ]);
  }
}

class _TeamsPanel extends StatelessWidget {
  final _TournamentData data;
  final VoidCallback onAddTeam;
  final VoidCallback onRefresh;

  const _TeamsPanel({required this.data, required this.onAddTeam, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PrimaryButton(label: 'Añadir equipo', icon: Icons.add_rounded, onPressed: onAddTeam),
      const SizedBox(height: AppSpacing.md),
      if (data.teams.isEmpty)
        EmptyState(icon: Icons.groups_rounded, title: 'Sin equipos', body: 'Añade equipos, parejas o jugadores para crear partidos.')
      else
        ...data.teams.map((team) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              _TeamAvatar(name: team['name']?.toString() ?? 'Equipo'),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(team['name']?.toString() ?? 'Equipo', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800))),
              IconButton(
                onPressed: () async {
                  try {
                    await TournamentsRepository().deleteTeam(team['id'].toString());
                    onRefresh();
                  } catch (e) {
                    if (context.mounted) AppToast.show(context, 'No se puede borrar si tiene partidos. Borra antes sus partidos.', error: true);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              ),
            ]),
          ),
        )),
    ]);
  }
}

class _TournamentSettingsPanel extends StatelessWidget {
  final _TournamentData data;
  final bool busy;
  final VoidCallback onToggleFinished;
  final VoidCallback onDelete;

  const _TournamentSettingsPanel({
    required this.data,
    required this.busy,
    required this.onToggleFinished,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final finished = (data.tournament['status'] ?? 'active') == 'finished';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InfoPanel(
        icon: finished ? Icons.lock_open_rounded : Icons.flag_rounded,
        title: finished ? 'Torneo finalizado' : 'Torneo activo',
        body: finished ? 'Puedes reabrirlo para editar resultados.' : 'Cuando acabéis, finalízalo para dejar la clasificación cerrada.',
        color: finished ? AppColors.textMuted : AppColors.success,
      ),
      const SizedBox(height: AppSpacing.md),
      SecondaryButton(
        label: finished ? 'Reabrir torneo' : 'Finalizar torneo',
        icon: finished ? Icons.lock_open_rounded : Icons.flag_rounded,
        onPressed: busy ? null : onToggleFinished,
      ),
      const SizedBox(height: AppSpacing.md),
      DestructiveButton(label: 'Eliminar torneo', onPressed: busy ? null : onDelete),
    ]);
  }
}

class _StandingsTable extends StatelessWidget {
  final List<TournamentStanding> rows;
  const _StandingsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return EmptyState(icon: Icons.table_chart_rounded, title: 'Sin clasificación', body: 'Añade equipos y resultados para calcular la tabla.');
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(2.5),
            2: FixedColumnWidth(30),
            3: FixedColumnWidth(30),
            4: FixedColumnWidth(30),
            5: FixedColumnWidth(30),
            6: FixedColumnWidth(38),
            7: FixedColumnWidth(38),
          },
          children: [
            _row(['#', 'Equipo', 'PJ', 'PG', 'PE', 'PP', 'DG', 'Pts'], header: true),
            ...rows.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final row = entry.value;
              return _row([
                '$index',
                row.teamName,
                '${row.played}',
                '${row.won}',
                '${row.draw}',
                '${row.lost}',
                row.goalDifference >= 0 ? '+${row.goalDifference}' : '${row.goalDifference}',
                '${row.points}',
              ]);
            }),
          ],
        ),
      ),
    );
  }

  TableRow _row(List<String> cells, {bool header = false}) {
    return TableRow(
      decoration: BoxDecoration(color: header ? AppColors.navy : AppColors.white),
      children: cells.map((cell) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
        child: Text(
          cell,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.2, fontWeight: FontWeight.w800, color: header ? Colors.white : AppColors.navy),
        ),
      )).toList(),
    );
  }
}

class AddTeamSheet extends StatefulWidget {
  final String tournamentId;
  const AddTeamSheet({super.key, required this.tournamentId});

  @override
  State<AddTeamSheet> createState() => _AddTeamSheetState();
}

class _AddTeamSheetState extends State<AddTeamSheet> {
  final _name = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_saving || _name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await TournamentsRepository().createTeam(widget.tournamentId, _name.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Añadir equipo', style: AppTypography.section),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(controller: _name, label: 'Nombre', hint: 'Los Pibes'),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Guardar equipo', icon: Icons.add_rounded, loading: _saving, onPressed: _save),
    ]);
  }
}

class MatchResultSheet extends StatefulWidget {
  final Map<String, dynamic> match;
  final String teamA;
  final String teamB;

  const MatchResultSheet({super.key, required this.match, required this.teamA, required this.teamB});

  @override
  State<MatchResultSheet> createState() => _MatchResultSheetState();
}

class _MatchResultSheetState extends State<MatchResultSheet> {
  late final TextEditingController _scoreA;
  late final TextEditingController _scoreB;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _scoreA = TextEditingController(text: widget.match['score_a']?.toString() ?? '');
    _scoreB = TextEditingController(text: widget.match['score_b']?.toString() ?? '');
  }

  Future<void> _save() async {
    if (_saving) return;
    final a = int.tryParse(_scoreA.text.trim());
    final b = int.tryParse(_scoreB.text.trim());
    if (a == null || b == null || a < 0 || b < 0) {
      AppToast.show(context, 'Introduce resultados válidos.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await TournamentsRepository().updateMatchResult(matchId: widget.match['id'].toString(), scoreA: a, scoreB: b);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Resultado', style: AppTypography.section),
      const SizedBox(height: AppSpacing.md),
      Text('${widget.teamA} vs. ${widget.teamB}', style: AppTypography.muted),
      const SizedBox(height: AppSpacing.lg),
      Row(children: [
        Expanded(child: AppTextField(controller: _scoreA, label: widget.teamA, keyboardType: TextInputType.number)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: AppTextField(controller: _scoreB, label: widget.teamB, keyboardType: TextInputType.number)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Guardar resultado', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
    ]);
  }
}

class CreateTournamentSheet extends StatefulWidget {
  final String groupId;
  const CreateTournamentSheet({super.key, required this.groupId});

  @override
  State<CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<CreateTournamentSheet> {
  final _name = TextEditingController();
  final _win = TextEditingController(text: '3');
  final _draw = TextEditingController(text: '1');
  String _format = 'liga';
  String _type = 'individual';
  bool _loading = false;

  Future<void> _create() async {
    if (_name.text.trim().isEmpty || _loading) return;
    setState(() => _loading = true);
    try {
      await TournamentsRepository().createTournament(
        groupId: widget.groupId,
        name: _name.text,
        format: _format,
        teamType: _type,
        pointsWin: int.tryParse(_win.text) ?? 3,
        pointsDraw: int.tryParse(_draw.text) ?? 1,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Crear torneo', style: AppTypography.section),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(controller: _name, label: 'Nombre', hint: 'Copa de verano'),
      const SizedBox(height: AppSpacing.md),
      Text('Formato', style: AppTypography.small.copyWith(color: AppColors.navy)),
      const SizedBox(height: AppSpacing.sm),
      SegmentedControl(values: const ['liga', 'eliminatoria', 'americano'], selected: _format, onChanged: (v) => setState(() => _format = v)),
      const SizedBox(height: AppSpacing.md),
      Text('Tipo', style: AppTypography.small.copyWith(color: AppColors.navy)),
      const SizedBox(height: AppSpacing.sm),
      SegmentedControl(values: const ['individual', 'pareja', 'equipo'], selected: _type, onChanged: (v) => setState(() => _type = v)),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: AppTextField(controller: _win, label: 'Victoria', keyboardType: TextInputType.number)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: AppTextField(controller: _draw, label: 'Empate', keyboardType: TextInputType.number)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Crear torneo', loading: _loading, onPressed: _create),
    ]);
  }
}

class _TournamentData {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;

  _TournamentData({required this.tournament, required this.teams, required this.matches});
}

class _TournamentBadge extends StatelessWidget {
  final String title;
  const _TournamentBadge({required this.title});

  @override
  Widget build(BuildContext context) {
    final short = title.trim().isEmpty ? 'T' : title.trim().split(' ').take(2).map((e) => e[0]).join().toUpperCase();
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(18)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(short, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
      ]),
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  final String name;
  const _TeamAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'T' : name.trim()[0].toUpperCase();
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(color: AppColors.mintSoft, shape: BoxShape.circle),
      child: Center(child: Text(initial, style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w900))),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniMetric({required this.label, required this.value, required this.icon, this.color = AppColors.teal});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        SoftIconBox(icon: icon, color: color, size: 38),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppTypography.section.copyWith(fontSize: 21)),
          Text(label, style: AppTypography.small),
        ])),
      ]),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  const _CompactStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AppTypography.section.copyWith(fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.small),
      ]),
    );
  }
}

class _Tabs extends StatelessWidget {
  final String selected;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _Tabs({required this.selected, required this.values, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: values.map((value) {
      final active = value == selected;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: active ? AppColors.teal : AppColors.border, width: active ? 2 : 1)),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(color: active ? AppColors.tealDark : AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
      );
    }).toList());
  }
}
