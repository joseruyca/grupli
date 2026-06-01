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
import '../../../ui/empty_state.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/segmented_control.dart';
import '../../../ui/status_chip.dart';
import '../../../ui/toast.dart';
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

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Torneos',
          subtitle: 'Ligas, eliminatorias y resultados claros.',
          showBack: true,
          trailing: IconButton.filled(
            onPressed: () => showAppBottomSheet(context, CreateTournamentSheet(groupId: widget.groupId)).then((_) => _refresh()),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return Column(children: [
                EmptyState(icon: Icons.emoji_events_rounded, title: 'Sin torneos', body: 'Crea una liga, eliminatoria o formato americano.'),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(label: 'Crear torneo', icon: Icons.add_rounded, onPressed: () => showAppBottomSheet(context, CreateTournamentSheet(groupId: widget.groupId)).then((_) => _refresh())),
              ]);
            }
            return Column(children: [
              ...rows.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  onTap: () => showAppBottomSheet(context, TournamentDetailSheet(tournament: t)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _TournamentBadge(title: t['name']?.toString() ?? 'Torneo'),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(t['name'] ?? 'Torneo', style: AppTypography.section.copyWith(fontSize: 18))),
                          StatusChip(label: (t['status'] == 'finished') ? 'Finalizado' : 'En curso', color: (t['status'] == 'finished') ? AppColors.textMuted : AppColors.success),
                        ]),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          MetaPill(icon: Icons.sports_soccer_rounded, text: _prettyFormat(t['format']?.toString() ?? 'liga')),
                          MetaPill(icon: Icons.groups_rounded, text: _prettyType(t['team_type']?.toString() ?? 'individual')),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        Text('Victoria ${t['points_win'] ?? 3} pts · Empate ${t['points_draw'] ?? 1} pts', style: AppTypography.muted),
                      ]),
                    ),
                  ]),
                ),
              )),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(label: 'Crear torneo', icon: Icons.add_rounded, onPressed: () => showAppBottomSheet(context, CreateTournamentSheet(groupId: widget.groupId)).then((_) => _refresh())),
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

class TournamentDetailSheet extends StatefulWidget {
  final Map<String, dynamic> tournament;
  const TournamentDetailSheet({super.key, required this.tournament});

  @override
  State<TournamentDetailSheet> createState() => _TournamentDetailSheetState();
}

class _TournamentDetailSheetState extends State<TournamentDetailSheet> {
  String _tab = 'Tabla';

  final _sampleRows = const [
    ['1', 'Los Pibes', '6', '5', '0', '1', '+11', '15'],
    ['2', 'La Banda', '6', '4', '1', '1', '+8', '13'],
    ['3', 'Los del Barrio', '6', '3', '1', '2', '+4', '10'],
    ['4', 'Siempre Listos', '6', '3', '0', '3', '-1', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _TournamentBadge(title: widget.tournament['name']?.toString() ?? 'Torneo'),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.tournament['name']?.toString() ?? 'Torneo', style: AppTypography.section.copyWith(fontSize: 22)),
            const SizedBox(height: 5),
            Text('${widget.tournament['format']} · ${widget.tournament['team_type']}', style: AppTypography.muted),
          ]),
        ),
      ]),
      const SizedBox(height: AppSpacing.lg),
      Row(children: ['Resumen', 'Tabla', 'Partidos', 'Equipos'].map((tab) {
        final active = tab == _tab;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: active ? AppColors.teal : AppColors.border, width: active ? 2 : 1)),
              ),
              child: Text(tab, textAlign: TextAlign.center, style: TextStyle(color: active ? AppColors.tealDark : AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
        );
      }).toList()),
      const SizedBox(height: AppSpacing.lg),
      if (_tab == 'Tabla') _StandingsPreview(rows: _sampleRows) else InfoPanel(icon: Icons.construction_rounded, title: 'Sección preparada', body: 'Esta parte queda estructurada para la siguiente fase funcional.', color: AppColors.lilac),
      const SizedBox(height: AppSpacing.lg),
      SectionTitle(title: 'Próximos partidos', actionLabel: 'Ver todos'),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _MatchLine(date: 'Mañana · 21:00', a: 'Los Pibes', b: 'La Banda'),
          const Divider(),
          _MatchLine(date: '24 may · 20:00', a: 'Los del Barrio', b: 'Siempre Listos'),
        ]),
      ),
    ]);
  }
}

class _StandingsPreview extends StatelessWidget {
  final List<List<String>> rows;
  const _StandingsPreview({required this.rows});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(32),
            1: FlexColumnWidth(2.2),
            2: FixedColumnWidth(34),
            3: FixedColumnWidth(34),
            4: FixedColumnWidth(34),
            5: FixedColumnWidth(34),
            6: FixedColumnWidth(42),
            7: FixedColumnWidth(42),
          },
          children: [
            _row(['#', 'Equipo', 'PJ', 'PG', 'PE', 'PP', 'DG', 'Pts'], header: true),
            ...rows.map(_row),
          ],
        ),
      ),
    );
  }

  TableRow _row(List<String> cells, {bool header = false}) {
    return TableRow(
      decoration: BoxDecoration(color: header ? AppColors.navy : AppColors.white),
      children: cells.map((cell) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        child: Text(cell, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: header ? Colors.white : AppColors.navy)),
      )).toList(),
    );
  }
}

class _MatchLine extends StatelessWidget {
  final String date;
  final String a;
  final String b;
  const _MatchLine({required this.date, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const SoftIconBox(icon: Icons.sports_score_rounded, color: AppColors.teal, size: 38),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(date, style: AppTypography.small),
          const SizedBox(height: 4),
          Text('$a  vs.  $b', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
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
