part of grupli_app;
// ignore_for_file: override_on_non_overriding_member

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
        Text(appIsEnglish ? 'Tournaments' : 'Torneos', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -.6)),
        const SizedBox(height: 4),
        Text(
          appIsEnglish ? 'Competitions for $subtitle' : 'Competiciones de $subtitle',
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
    final title = hasActivity ? (appIsEnglish ? "What's next" : 'Qué toca ahora') : (appIsEnglish ? 'Start a competition' : 'Empieza la competición');
    final body = nextCount > 0
        ? '$nextCount ${nextCount == 1 ? 'partido pendiente' : 'partidos pendientes'} para revisar.'
        : activeCount > 0
            ? '$activeCount ${activeCount == 1 ? 'competición activa' : 'competiciones activas'} en marcha.'
            : 'Crea una liga, eliminatoria, americano o manual.';
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
            Expanded(child: TournamentMiniMetric(label: appIsEnglish ? 'Pending' : 'Pendientes', value: '$nextCount', color: AppColors.amber)),
            const SizedBox(width: 8),
            Expanded(child: TournamentMiniMetric(label: appIsEnglish ? 'Finished' : 'Finalizadas', value: '$finishedCount', color: AppColors.blue)),
          ]),
          const SizedBox(height: 14),
          PrimaryButton(label: appIsEnglish ? 'Create tournament or league' : 'Crear torneo o liga', icon: Icons.add_rounded, onTap: onCreate),
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
            ? 'Falta el calendario'
            : unscheduled > 0
                ? 'Faltan fechas'
                : pending > 0
                    ? 'Resultados pendientes'
                    : 'Todo listo';
    final body = needsTeams
        ? 'Añade al menos dos participantes para poder generar partidos sin confusión.'
        : matches.isEmpty
            ? 'Crea el calendario para ver los cruces.'
            : unscheduled > 0
                ? '$unscheduled ${unscheduled == 1 ? 'partido sin fecha' : 'partidos sin fecha'}.'
                : pending > 0
                    ? '$pending ${pending == 1 ? 'partido pendiente' : 'partidos pendientes'}.'
                    : standings.isEmpty ? 'Sin tabla todavía.' : 'Líder: ${standings.first.name}.';
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
        ? (appIsEnglish ? 'Add participants' : 'Añadir participantes')
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
        ? (appIsEnglish ? 'No matches created yet' : 'Sin partidos creados todavía')
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
      Text(appIsEnglish ? 'No competitions yet' : 'Todavía no hay competiciones', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -.2)),
      const SizedBox(height: 6),
      Text(appIsEnglish ? 'Create a league, knockout or manual tournament. Grupli helps with matches, results and standings.' : 'Crea una liga, una eliminatoria o un torneo manual. Grupli te ayudará con los partidos, resultados y clasificación.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.35)),
      const SizedBox(height: 16),
      PrimaryButton(label: appIsEnglish ? 'Create tournament or league' : 'Crear torneo o liga', icon: Icons.add_rounded, onTap: onCreate),
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
      Text(appIsEnglish ? 'Create your first tournament' : 'Crea tu primer torneo', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 5),
      Text(appIsEnglish ? 'League, knockout, Americano or manual. With matches, table and stats.' : 'Liga, eliminatoria, americano o manual. Con partidos, tabla y estadísticas.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
      const SizedBox(height: 14),
      PrimaryButton(label: appIsEnglish ? 'Create tournament or league' : 'Crear torneo o liga', icon: Icons.add_rounded, onTap: onCreate),
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
        child: const Center(child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26)),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Prepara tu torneo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
        SizedBox(height: 5),
        Text('Deporte, formato y participantes en un solo flujo.', style: TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.25)),
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

  static final templates = [
    TournamentQuickTemplate('league', '', 'Liga', appIsEnglish ? 'Rounds and table' : 'Jornadas y tabla'),
    TournamentQuickTemplate('americano_padel', '', 'Americano', appIsEnglish ? 'Rotations and ranking' : 'Rotación y ranking'),
    TournamentQuickTemplate('quick_cup', '', 'Eliminatoria', appIsEnglish ? 'Bracket and final' : 'Cuadro y final'),
    TournamentQuickTemplate('manual_day', '', 'Manual', appIsEnglish ? 'Cruces manuales' : 'Cruces manuales'),
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
        Text(enabled ? (appIsEnglish ? 'Advanced mode on' : 'Modo avanzado') : (appIsEnglish ? 'Quick setup recommended' : 'Configuración rápida recomendada'), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(enabled ? (appIsEnglish ? 'You can tweak format, rounds, brackets and rules.' : 'Puedes ajustar formato, rondas, cruces y reglas.') : (appIsEnglish ? 'Same flow, fewer technical settings.' : 'Mismo flujo, menos ajustes técnicos.'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
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
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
      SizedBox(width: 9),
      Expanded(child: Text(
        appIsEnglish ? 'Quick mode: pick League, Americano, Knockout or Manual and follow the same flow.' : 'Modo rápido: eliges Liga, Americano, Eliminatoria o Manual y sigues el mismo flujo.',
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
        Text('${scoringTypeLabel(scoringType)} · ${tournamentFormatLabel(format)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Wrap(spacing: 6, runSpacing: 6, children: [
          TournamentRuleChip(label: teamTypeLabel(teamType)),
          TournamentRuleChip(label: tournamentFormatSubtitle(format)),
        ]),
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
      return AppCard(
        color: AppColors.faint,
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          TournamentRuleChip(label: format == 'manual' ? 'Selector visual' : 'Cuadro autom?tico'),
          TournamentRuleChip(label: format == 'manual' ? 'Importar texto' : 'Byes y siguiente ronda'),
        ]),
      );
    }
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(format == 'americano' ? 'Americano' : 'Liga', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      if (format == 'americano')
        TournamentCounterRow(label: 'Rondas', value: rounds <= 0 ? 5 : rounds, min: 1, max: 20, onChanged: onRoundsChanged, helper: 'Ranking')
      else
        TournamentCounterRow(label: 'Jornadas', value: rounds, min: 0, max: 30, zeroLabel: 'Todas', onChanged: onRoundsChanged, helper: 'Completa'),
      TournamentCounterRow(label: 'Pistas / mesas', value: courts, min: 1, max: 12, onChanged: onCourtsChanged, helper: courts <= 1 ? 'Una' : 'Varias'),
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
    final date = row.scheduledAt == null ? 'Sin fecha' : DateFormat('EEE d MMM · HH:mm', appDateLocale).format(row.scheduledAt!);
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
    final date = row.scheduledAt == null ? 'Sin fecha individual' : DateFormat('EEE d MMM · HH:mm', appDateLocale).format(row.scheduledAt!);
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
        title: Text(initial == null ? (appIsEnglish ? 'Add match' : 'Añadir partido') : (appIsEnglish ? 'Edit match' : 'Editar partido')),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: teamA,
            decoration: InputDecoration(labelText: appIsEnglish ? 'Participant A' : 'Participante A'),
            items: participants.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setLocal(() => teamA = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: teamB,
            decoration: InputDecoration(labelText: appIsEnglish ? 'Participant B' : 'Participante B'),
            items: participants.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setLocal(() => teamB = v),
          ),
          const SizedBox(height: 8),
          TextField(controller: roundController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: appIsEnglish ? 'Round' : 'Jornada')),
          CheckboxListTile(
            value: useDate,
            onChanged: (v) => setLocal(() => useDate = v == true),
            contentPadding: EdgeInsets.zero,
            title: Text(appIsEnglish ? 'Set individual date' : 'Poner fecha individual'),
          ),
          if (useDate) Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', appDateLocale).format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
              final picked = await showDatePicker(context: dialogContext, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)), locale: appLocale);
              if (picked != null) setLocal(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedDate.hour, selectedDate.minute));
            })),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
              final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
              if (picked != null) setLocal(() { selectedTime = picked; selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute); });
            })),
          ]),
          const SizedBox(height: 8),
          TextField(controller: durationController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: appIsEnglish ? 'Duration minutes' : 'Duración minutos')),
          const SizedBox(height: 8),
          TextField(controller: courtController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pista / mesa / campo')),
          const SizedBox(height: 8),
          TextField(controller: locationController, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: appIsEnglish ? 'Location' : 'Ubicación')),
          const SizedBox(height: 8),
          TextField(controller: notesController, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: appIsEnglish ? 'Notes' : 'Notas')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(appIsEnglish ? 'Cancel' : 'Cancelar')),
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
            child: Text(appIsEnglish ? 'Save' : 'Guardar'),
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
        title: Text(appIsEnglish ? 'Add manual match' : 'Añadir partido manual'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: teamA,
            decoration: InputDecoration(labelText: appIsEnglish ? 'Participant A' : 'Participante A'),
            items: ids.map((id) => DropdownMenuItem(value: id, child: Text(names[id] ?? 'Participante'))).toList(),
            onChanged: (v) => setLocal(() => teamA = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: teamB,
            decoration: InputDecoration(labelText: appIsEnglish ? 'Participant B' : 'Participante B'),
            items: ids.map((id) => DropdownMenuItem(value: id, child: Text(names[id] ?? 'Participante'))).toList(),
            onChanged: (v) => setLocal(() => teamB = v),
          ),
          const SizedBox(height: 8),
          TextField(controller: roundController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: appIsEnglish ? 'Round' : 'Jornada')),
          CheckboxListTile(value: useDate, onChanged: (v) => setLocal(() => useDate = v == true), contentPadding: EdgeInsets.zero, title: Text(appIsEnglish ? 'Schedule date' : 'Programar fecha')),
          if (useDate) Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', appDateLocale).format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
              final picked = await showDatePicker(context: dialogContext, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)), locale: appLocale);
              if (picked != null) setLocal(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedTime.hour, selectedTime.minute));
            })),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
              final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
              if (picked != null) setLocal(() { selectedTime = picked; selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute); });
            })),
          ]),
          const SizedBox(height: 8),
          TextField(controller: durationController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: appIsEnglish ? 'Duration minutes' : 'Duración minutos')),
          const SizedBox(height: 8),
          TextField(controller: courtController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pista / mesa / campo')),
          const SizedBox(height: 8),
          TextField(controller: locationController, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: appIsEnglish ? 'Location' : 'Ubicación')),
          const SizedBox(height: 8),
          TextField(controller: notesController, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: appIsEnglish ? 'Notes' : 'Notas')),
          if (useDate) CheckboxListTile(value: syncAgenda, onChanged: (v) => setLocal(() => syncAgenda = v == true), contentPadding: EdgeInsets.zero, title: Text(appIsEnglish ? 'Add to Agenda' : 'Añadir a Agenda')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(appIsEnglish ? 'Cancel' : 'Cancelar')),
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
            child: Text(appIsEnglish ? 'Add' : 'Añadir'),
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
          Text(appIsEnglish ? 'The same pairings will be copied to a new round, without results or date.' : 'Se copiarán los mismos cruces en una jornada nueva, sin resultados ni fecha.', style: const TextStyle(fontWeight: FontWeight.w700)),
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
