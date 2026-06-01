import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
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
          subtitle: 'Ligas, eliminatorias y resultados.',
          showBack: true,
          trailing: IconButton.filled(onPressed: () => showAppBottomSheet(context, CreateTournamentSheet(groupId: widget.groupId)).then((_) => _refresh()), icon: const Icon(Icons.add_rounded)),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(snapshot.error.toString()));
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) return EmptyState(icon: Icons.emoji_events_rounded, title: 'Sin torneos', body: 'Crea una liga, eliminatoria o formato americano.');
            return Column(children: rows.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(t['name'] ?? 'Torneo', style: AppTypography.section)),
                    StatusChip(label: t['status'] ?? 'activo', color: (t['status'] == 'finished') ? AppColors.textMuted : AppColors.teal),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${t['format']} · ${t['team_type']} · victoria ${t['points_win']} pts', style: AppTypography.muted),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    Expanded(child: SecondaryButton(label: 'Equipos', icon: Icons.groups_rounded, onPressed: () {})),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: SecondaryButton(label: 'Partidos', icon: Icons.sports_score_rounded, onPressed: () {})),
                  ]),
                ]),
              ),
            )).toList());
          },
        ),
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
    if (_name.text.trim().isEmpty) return;
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
      AppTextField(controller: _name, label: 'Nombre'),
      const SizedBox(height: AppSpacing.md),
      SegmentedControl(values: const ['liga', 'eliminatoria', 'americano'], selected: _format, onChanged: (v) => setState(() => _format = v)),
      const SizedBox(height: AppSpacing.md),
      SegmentedControl(values: const ['individual', 'pareja', 'equipo'], selected: _type, onChanged: (v) => setState(() => _type = v)),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: AppTextField(controller: _win, label: 'Puntos victoria', keyboardType: TextInputType.number)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: AppTextField(controller: _draw, label: 'Puntos empate', keyboardType: TextInputType.number)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Crear torneo', loading: _loading, onPressed: _create),
    ]);
  }
}
