part of grupli_app;

class GroupHeroCard extends StatelessWidget {
  final String name;
  final String coverUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onMore;
  const GroupHeroCard({super.key, required this.name, this.coverUrl = '', this.onEdit, this.onMore});

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl.trim().isNotEmpty;
    return Container(
      height: 126,
      decoration: BoxDecoration(
        color: AppColors.navHome,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Color(0x2A053A59), blurRadius: 30, offset: Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(children: [
          Positioned.fill(
            child: hasCover
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.navHome),
                  )
                : Container(color: AppColors.navHome),
          ),
          if (hasCover)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x12000000), Color(0x55000000)],
                  ),
                ),
              ),
            ),
          Positioned(right: 16, top: 14, child: _HeroActionButton(icon: Icons.edit_rounded, tooltip: 'Editar grupo', onTap: onEdit)),
          Positioned(left: 18, right: 18, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -0.85,
                shadows: [Shadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 3))],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lo importante del grupo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 2))],
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _HeroActionButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionHeader({super.key, required this.title, this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x19008F86))),
              child: Text(action!, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 12.5)),
            ),
          ),
      ]),
    );
  }
}



class GroupDashboardIntro extends StatelessWidget {
  final Map<String, dynamic>? nextEvent;
  final int pendingCount;
  const GroupDashboardIntro({super.key, required this.nextEvent, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final text = nextEvent == null
        ? 'Este grupo todavía no tiene planes próximos.'
        : pendingCount > 0
            ? (pendingCount == 1 ? 'Tienes 1 plan pendiente de confirmar.' : 'Tienes $pendingCount planes pendientes de confirmar.')
            : 'El próximo plan ya está organizado.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.muted, fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.32),
      ),
    );
  }
}

class DashboardQuickActions extends StatelessWidget {
  final VoidCallback? onAgenda;
  final VoidCallback? onFinances;
  final VoidCallback? onTournaments;
  final VoidCallback? onMembers;
  const DashboardQuickActions({super.key, this.onAgenda, this.onFinances, this.onTournaments, this.onMembers});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _DashboardQuickAction(icon: Icons.calendar_month_rounded, label: 'Agenda', color: AppColors.navAgenda, onTap: onAgenda)),
      const SizedBox(width: 8),
      Expanded(child: _DashboardQuickAction(icon: Icons.account_balance_wallet_rounded, label: 'Gastos', color: AppColors.navFinance, onTap: onFinances)),
      const SizedBox(width: 8),
      Expanded(child: _DashboardQuickAction(icon: Icons.emoji_events_rounded, label: 'Torneos', color: AppColors.navTournaments, onTap: onTournaments)),
      const SizedBox(width: 8),
      Expanded(child: _DashboardQuickAction(icon: Icons.group_rounded, label: 'Miembros', color: AppColors.teal, onTap: onMembers)),
    ]);
  }
}

class _DashboardQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _DashboardQuickAction({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lineSoft),
            boxShadow: const [BoxShadow(color: Color(0x070B1B2E), blurRadius: 16, offset: Offset(0, 7))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 7),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 11.5, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}

class CompactInsightStrip extends StatelessWidget {
  final int events;
  final double expenses;
  final int pending;
  final int tournaments;
  const CompactInsightStrip({super.key, required this.events, required this.expenses, required this.pending, required this.tournaments});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Expanded(child: CompactInsight(icon: Icons.calendar_month_rounded, label: 'Agenda', value: '$events')),
        const _TinyDivider(),
        Expanded(child: CompactInsight(icon: Icons.account_balance_wallet_rounded, label: 'Gastos', value: money(expenses))),
        const _TinyDivider(),
        Expanded(child: CompactInsight(icon: Icons.help_outline_rounded, label: 'Dudas', value: '$pending')),
        const _TinyDivider(),
        Expanded(child: CompactInsight(icon: Icons.emoji_events_rounded, label: 'Torneos', value: '$tournaments')),
      ]),
    );
  }
}

class CompactInsight extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const CompactInsight({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 18, color: AppColors.teal),
    const SizedBox(height: 5),
    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink)),
    const SizedBox(height: 1),
    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
  ]);
}

class _TinyDivider extends StatelessWidget {
  const _TinyDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 34, color: AppColors.line);
}


class DashboardUpcomingEventsCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  const DashboardUpcomingEventsCard({super.key, required this.events, required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ordered = [...events]..sort((a, b) {
      final da = DateTime.tryParse(AppData.text(a['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(AppData.text(b['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    final firstDate = DateTime.tryParse(AppData.text(ordered.first['starts_at']))?.toLocal() ?? DateTime.now();
    final hasTournament = ordered.any(eventIsTournamentEvent);
    final accent = hasTournament ? AppColors.teal : eventKindColor(ordered.first);

    Future<void> openEvent(Map<String, dynamic> event) async {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
      onChanged();
    }

    return AppCard(
      color: hasTournament ? const Color(0xFF2F260E) : AppColors.navy,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 58,
            height: 62,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: accent.withOpacity(.28))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(shortWeekday(firstDate).toUpperCase(), style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900)),
              Text(firstDate.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
              Text(DateFormat('MMM', 'es_ES').format(firstDate).replaceAll('.', ''), style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${ordered.length} planes el mismo día', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 5),
            Text(hasTournament ? 'Incluye partidos de liga/torneo' : 'Toca uno para abrir su tarjeta', style: TextStyle(color: hasTournament ? AppColors.amberSoft : const Color(0xDFFFFFFF), fontWeight: FontWeight.w800, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        for (final event in ordered.take(4)) ...[
          DashboardUpcomingEventRow(event: event, onTap: () => openEvent(event)),
          if (event != ordered.take(4).last) const Divider(height: 1, color: Color(0x25FFFFFF)),
        ],
        if (ordered.length > 4) ...[
          const SizedBox(height: 8),
          Text('+ ${ordered.length - 4} más en Agenda', style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800)),
        ],
      ]),
    );
  }
}

class DashboardUpcomingEventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const DashboardUpcomingEventRow({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal() ?? DateTime.now();
    final color = eventKindColor(event);
    final isTournament = eventIsTournamentEvent(event);
    final yes = attendanceCount(event, 'yes');
    final minPeople = AppData.intValue(event['min_people'], 1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: isTournament ? AppColors.amber.withOpacity(.16) : Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(14)),
            child: Icon(eventKindIcon(event), color: isTournament ? AppColors.amber : color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
            const SizedBox(height: 3),
            Text('${DateFormat('HH:mm', 'es_ES').format(date)} · $yes/$minPeople van', style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, fontSize: 11.5)),
          ])),
          if (isTournament) const TournamentAgendaBadge(),
        ]),
      ),
    );
  }
}

class DashboardEventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  const DashboardEventCard({super.key, required this.event, required this.group, required this.onChanged});

  @override
  State<DashboardEventCard> createState() => _DashboardEventCardState();
}

class _DashboardEventCardState extends State<DashboardEventCard> {
  bool saving = false;

  Future<void> setStatus(String status) async {
    setState(() => saving = true);
    try {
      await AppData.setAttendance(widget.event['id'].toString(), status);
      widget.onChanged();
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final minPeople = AppData.intValue(event['min_people'], 1);
    final yes = attendanceCount(event, 'yes');
    final maybe = attendanceCount(event, 'maybe');
    final no = attendanceCount(event, 'no');
    final mine = myAttendanceStatus(event);
    final isTournament = eventIsTournamentEvent(event);
    final missing = max(0, minPeople - yes);
    final progress = minPeople <= 0 ? 0.0 : min(1.0, yes / minPeople);

    return AppCard(
      color: isTournament ? const Color(0xFF2F260E) : AppColors.navy,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: widget.group)));
        widget.onChanged();
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 58,
            height: 62,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.18))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(shortWeekday(date).toUpperCase(), style: const TextStyle(color: AppColors.navAgenda, fontSize: 10, fontWeight: FontWeight.w900)),
              Text(date.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
              Text(DateFormat('MMM', 'es_ES').format(date).replaceAll('.', ''), style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -.25))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: missing == 0 ? AppColors.greenSoft : AppColors.orangeSoft, borderRadius: BorderRadius.circular(99)),
                child: Text(missing == 0 ? 'Listo' : 'Faltan $missing', style: TextStyle(color: missing == 0 ? AppColors.green : AppColors.orange, fontSize: 11.5, fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 7),
            Wrap(spacing: 10, runSpacing: 6, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.schedule_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 4),
                Text(DateFormat('HH:mm', 'es_ES').format(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 210),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.place_outlined, size: 15, color: Colors.white),
                  const SizedBox(width: 4),
                  Flexible(child: Text(AppData.text(event['location'], 'Sin ubicación'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
              ),
            ]),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Color(0x30FFFFFF), color: AppColors.green))),
          const SizedBox(width: 10),
          Text('$yes/$minPeople van', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        ]),
        const SizedBox(height: 7),
        Text(
          yes + maybe + no == 0
              ? 'Nadie ha respondido todavía. Faltan $missing respuestas.'
              : 'Han respondido ${yes + maybe + no} de $minPeople personas. Faltan $missing.',
          style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text('¿Vas a venir?', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: GlassAttendanceButton(label: 'Voy', count: yes, selected: mine == 'yes', color: AppColors.green, onTap: saving ? () {} : () => setStatus('yes'), showCount: false)),
          const SizedBox(width: 8),
          Expanded(child: GlassAttendanceButton(label: 'Quizás', count: maybe, selected: mine == 'maybe', color: AppColors.amber, onTap: saving ? () {} : () => setStatus('maybe'), showCount: false)),
          const SizedBox(width: 8),
          Expanded(child: GlassAttendanceButton(label: 'No', count: no, selected: mine == 'no', color: AppColors.red, onTap: saving ? () {} : () => setStatus('no'), showCount: false)),
        ]),
      ]),
    );
  }
}

class DashboardMiniSummaryRow extends StatelessWidget {
  final int events;
  final int pending;
  final double balance;
  final int tournaments;
  final VoidCallback? onCalendar;
  final VoidCallback? onFinances;
  final VoidCallback? onTournaments;
  const DashboardMiniSummaryRow({super.key, required this.events, required this.pending, required this.balance, required this.tournaments, this.onCalendar, this.onFinances, this.onTournaments});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: MiniSummaryTile(icon: Icons.calendar_month_rounded, label: 'Agenda', value: events.toString(), color: AppColors.navAgenda, onTap: onCalendar)),
    const SizedBox(width: 8),
    Expanded(child: MiniSummaryTile(icon: Icons.account_balance_wallet_rounded, label: 'Balance', value: money(balance), color: balance < -0.01 ? AppColors.red : AppColors.navFinance, onTap: onFinances)),
    const SizedBox(width: 8),
    Expanded(child: MiniSummaryTile(icon: Icons.emoji_events_rounded, label: 'Torneos', value: tournaments.toString(), color: AppColors.navTournaments, onTap: onTournaments)),
  ]);
}

class MiniSummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  const MiniSummaryTile({super.key, required this.icon, required this.label, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 14.5, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w800)),
    ]),
  );
}

class GlassAttendanceButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool showCount;
  const GlassAttendanceButton({super.key, required this.label, required this.count, required this.selected, required this.color, required this.onTap, this.showCount = true});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 44,
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: selected ? color : color.withOpacity(.28), width: 1.2),
        boxShadow: selected ? [BoxShadow(color: color.withOpacity(.20), blurRadius: 14, offset: const Offset(0, 6))] : const [],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? Colors.white : color, size: 15),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: selected ? Colors.white : color, fontSize: 12.5, fontWeight: FontWeight.w900)),
          if (showCount) ...[
            const SizedBox(width: 4),
            Text(count.toString(), style: TextStyle(color: selected ? Colors.white : color, fontSize: 12.5, fontWeight: FontWeight.w900)),
          ],
        ]),
      ),
    ),
  );
}



class DashboardActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> tournaments;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenFinances;
  final VoidCallback? onOpenTournaments;

  const DashboardActivityCard({
    super.key,
    required this.events,
    required this.expenses,
    required this.tournaments,
    this.onOpenCalendar,
    this.onOpenFinances,
    this.onOpenTournaments,
  });

  List<_DashboardActivityItem> _items() {
    final items = <_DashboardActivityItem>[];
    final routineGroups = <String, List<Map<String, dynamic>>>{};
    final singleEvents = <Map<String, dynamic>>[];

    for (final event in events) {
      if (eventIsRoutine(event)) {
        final key = AppData.text(event['title'], 'Rutina');
        routineGroups.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(event);
      } else {
        singleEvents.add(event);
      }
    }

    routineGroups.forEach((title, groupEvents) {
      groupEvents.sort((a, b) {
        final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.now();
        final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.now();
        return da.compareTo(db);
      });
      final first = groupEvents.first;
      final date = DateTime.tryParse(first['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      items.add(_DashboardActivityItem(
        date: date,
        icon: Icons.repeat_rounded,
        color: eventKindColor(first),
        title: title,
        body: '${groupEvents.length} fechas programadas',
        onTapKind: 'calendar',
      ));
    });

    for (final event in singleEvents.take(4)) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      if (date == null) continue;
      final yes = attendanceCount(event, 'yes');
      final minPeople = AppData.intValue(event['min_people'], 1);
      final missing = max(0, minPeople - yes);
      items.add(_DashboardActivityItem(
        date: date,
        icon: Icons.event_available_rounded,
        color: eventKindColor(event),
        title: 'Plan: ${AppData.text(event['title'], 'Quedada')}',
        body: missing == 0 ? '${shortWeekday(date)} ${date.day} · listo' : '${shortWeekday(date)} ${date.day} · faltan $missing respuestas',
        onTapKind: 'calendar',
      ));
    }

    for (final expense in expenses.take(2)) {
      final created = DateTime.tryParse(expense['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final paid = AppData.text(expense['status'], 'pending') == 'paid';
      final status = paid ? 'Liquidado' : 'Pendiente';
      items.add(_DashboardActivityItem(
        date: created,
        icon: Icons.account_balance_wallet_rounded,
        color: paid ? AppColors.green : AppColors.amber,
        title: 'Gasto: ${AppData.text(expense['concept'], 'Gasto')}',
        body: '$status · ${money(AppData.doubleValue(expense['amount']))}',
        onTapKind: 'finances',
      ));
    }

    for (final tournament in tournaments.take(2)) {
      final created = DateTime.tryParse(tournament['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final finished = AppData.text(tournament['status'], 'active') == 'finished';
      items.add(_DashboardActivityItem(
        date: created,
        icon: Icons.emoji_events_rounded,
        color: finished ? AppColors.violet : AppColors.orange,
        title: AppData.text(tournament['name'], 'Competición'),
        body: finished ? 'Finalizado' : 'En curso',
        onTapKind: 'tournaments',
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();

    if (items.isEmpty) {
      return EmptySlim(
        icon: Icons.bolt_rounded,
        title: 'Sin actividad todavía',
        body: 'Los próximos planes aparecerán aquí.',
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _DashboardActivityRow(
              item: items[i],
              onTap: () {
                if (items[i].onTapKind == 'calendar') onOpenCalendar?.call();
                if (items[i].onTapKind == 'finances') onOpenFinances?.call();
                if (items[i].onTapKind == 'tournaments') onOpenTournaments?.call();
              },
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 56, color: AppColors.line),
          ],
        ],
      ),
    );
  }
}

class _DashboardActivityItem {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String onTapKind;

  const _DashboardActivityItem({
    required this.date,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.onTapKind,
  });
}

class _DashboardActivityRow extends StatelessWidget {
  final _DashboardActivityItem item;
  final VoidCallback onTap;

  const _DashboardActivityRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: item.color.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(item.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 22),
          ],
        ),
      ),
    );
  }
}





class CalendarCompactHeader extends StatelessWidget {
  final int todayEvents;
  final int weekEvents;
  final int pendingResponses;
  final VoidCallback onToday;
  const CalendarCompactHeader({super.key, required this.todayEvents, required this.weekEvents, required this.pendingResponses, required this.onToday});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    child: Row(children: [
      Expanded(child: _CalendarMiniStat(label: 'Hoy', value: todayEvents.toString(), color: AppColors.teal)),
      Container(width: 1, height: 28, color: AppColors.line),
      Expanded(child: _CalendarMiniStat(label: '7 días', value: weekEvents.toString(), color: AppColors.blue)),
      Container(width: 1, height: 28, color: AppColors.line),
      Expanded(child: _CalendarMiniStat(label: 'Pendientes', value: pendingResponses.toString(), color: AppColors.amber)),
      const SizedBox(width: 6),
      TextButton(onPressed: onToday, child: const Text('Hoy')),
    ]),
  );
}

class _CalendarMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CalendarMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
    const SizedBox(height: 3),
    Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
  ]);
}

class CalendarSmartHeader extends StatelessWidget {
  final int todayEvents;
  final int weekEvents;
  final int pendingResponses;
  final VoidCallback onToday;

  const CalendarSmartHeader({
    super.key,
    required this.todayEvents,
    required this.weekEvents,
    required this.pendingResponses,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingResponses > 0;
    return AppCard(
      color: AppColors.surface,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: hasPending ? AppColors.amber.withOpacity(.12) : AppColors.tealSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasPending ? Icons.notification_important_rounded : Icons.calendar_month_rounded,
              color: hasPending ? AppColors.amber : AppColors.teal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              hasPending ? 'Tienes respuestas pendientes' : 'Agenda del grupo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              hasPending
                  ? '$pendingResponses ${pendingResponses == 1 ? 'evento necesita' : 'eventos necesitan'} tu respuesta para organizar mejor el grupo.'
                  : 'Mira qué hay hoy, qué viene esta semana y crea eventos desde cualquier día.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ])),
          TextButton(onPressed: onToday, child: const Text('Hoy')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CalendarMiniStat(label: 'Hoy', value: '$todayEvents', color: AppColors.teal)),
          const SizedBox(width: 8),
          Expanded(child: _CalendarMiniStat(label: '7 días', value: '$weekEvents', color: AppColors.violet)),
          const SizedBox(width: 8),
          Expanded(child: _CalendarMiniStat(label: 'Pendientes', value: '$pendingResponses', color: AppColors.amber)),
        ]),
      ]),
    );
  }
}


class WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final Map<String, List<Map<String, dynamic>>> eventsByDay;
  final ValueChanged<DateTime> onSelect;

  const WeekStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.eventsByDay,
    required this.onSelect,
  });

  List<Map<String, dynamic>> eventsFor(DateTime day) {
    return eventsByDay[calendarDayKey(day)] ?? const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final day = days[index];
          final active = sameDay(day, selected);
          final dayEvents = eventsFor(day);
          final hasEvents = dayEvents.isNotEmpty;
          final mainColor = hasEvents ? eventKindColor(dayEvents.first) : AppColors.line;
          final today = sameDay(day, DateTime.now());
          return InkWell(
            onTap: () => onSelect(day),
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 52,
              padding: const EdgeInsets.fromLTRB(5, 7, 5, 7),
              decoration: BoxDecoration(
                color: active ? AppColors.teal : hasEvents ? eventKindSoftColor(dayEvents.first) : AppColors.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: active ? AppColors.teal : today ? AppColors.teal.withOpacity(.45) : hasEvents ? mainColor.withOpacity(.38) : AppColors.line,
                  width: active || today || hasEvents ? 1.3 : 1,
                ),
                boxShadow: active ? const [BoxShadow(color: Color(0x15008F86), blurRadius: 12, offset: Offset(0, 6))] : null,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(shortWeekday(day).toUpperCase(), maxLines: 1, style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 10.5)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(day.day.toString(), maxLines: 1, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 19)),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 8,
                  child: Center(
                    child: hasEvents
                        ? EventDayMarkers(events: dayEvents, active: active, compact: true)
                        : Container(width: today ? 16 : 6, height: 4, decoration: BoxDecoration(color: active ? Colors.white : AppColors.line, borderRadius: BorderRadius.circular(99))),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}


class EventTypeLegend extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  const EventTypeLegend({super.key, required this.events});

  static const List<String> _orderedKinds = ['quedada', 'partido', 'entrenamiento', 'torneo', 'cena', 'reunion'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: [
        const Text('Tipos', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(width: 8),
        for (int i = 0; i < _orderedKinds.length; i++) ...[
          EventLegendMiniChip(event: {'kind': _orderedKinds[i], 'title': _orderedKinds[i]}),
          if (i != _orderedKinds.length - 1) const SizedBox(width: 6),
        ],
      ]),
    );
  }
}

class EventLegendMiniChip extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventLegendMiniChip({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final color = eventKindColor(event);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(eventKindIcon(event), color: color, size: 12),
        const SizedBox(width: 5),
        Text(eventKindLabel(event), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10.5)),
      ]),
    );
  }
}



class EventDayMarkers extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final bool active;
  final bool compact;
  const EventDayMarkers({super.key, required this.events, required this.active, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final visible = events.take(3).toList();
    final barWidth = compact ? 9.0 : 11.0;
    final barHeight = compact ? 4.0 : 4.5;
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
      for (int i = 0; i < visible.length; i++) ...[
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: active ? Colors.white : eventKindColor(visible[i]),
            borderRadius: BorderRadius.circular(99),
            boxShadow: active ? null : [BoxShadow(color: eventKindColor(visible[i]).withOpacity(.22), blurRadius: 4, offset: const Offset(0, 1))],
          ),
        ),
        if (i != visible.length - 1) const SizedBox(width: 2),
      ],
      if (events.length > 3) ...[
        const SizedBox(width: 2),
        Text('+', style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: compact ? 9 : 10, height: .8)),
      ],
    ]);
  }
}

class RoutineBadge extends StatelessWidget {
  final String label;
  final bool compact;
  const RoutineBadge({super.key, required this.label, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 8.0 : 10.0;
    final vertical = compact ? 5.0 : 6.0;
    final iconSize = compact ? 14.0 : 16.0;
    final fontSize = compact ? 11.5 : 12.5;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: AppColors.violet.withOpacity(.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.violet.withOpacity(.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.repeat_rounded, color: AppColors.violet, size: iconSize),
        const SizedBox(width: 5),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.violet, fontSize: fontSize, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}


class TournamentAgendaBadge extends StatelessWidget {
  const TournamentAgendaBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.amber.withOpacity(.42)),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.emoji_events_rounded, color: AppColors.amber, size: 13),
      SizedBox(width: 4),
      Text('Torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 10.5)),
    ]),
  );
}

class EventKindPill extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool compact;
  const EventKindPill({super.key, required this.event, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = eventKindColor(event);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 5 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(eventKindIcon(event), color: color, size: compact ? 14 : 16),
        const SizedBox(width: 5),
        Text(eventKindLabel(event), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: compact ? 11 : 12)),
      ]),
    );
  }
}


class EventScopeCard extends StatelessWidget {
  final String title;
  final String value;
  final ValueChanged<String> onChanged;
  const EventScopeCard({super.key, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.violetSoft,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 42, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.repeat_rounded, color: AppColors.violet)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          const Text('Elige qué fechas quieres modificar.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        RoutineChoice(label: 'Solo esta fecha', selected: value == 'single', onTap: () => onChanged('single')),
        RoutineChoice(label: 'Esta y futuras', selected: value == 'future', onTap: () => onChanged('future')),
        RoutineChoice(label: 'Toda la rutina', selected: value == 'all', onTap: () => onChanged('all')),
      ]),
    ]),
  );
}

Future<String?> showRoutineScopeDialog(BuildContext context, {required String title, required String actionLabel}) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.event_rounded),
          title: const Text('Solo esta fecha'),
          subtitle: const Text('No cambia el resto de la rutina.'),
          onTap: () => Navigator.pop(context, 'single'),
        ),
        ListTile(
          leading: const Icon(Icons.update_rounded),
          title: const Text('Esta y futuras'),
          subtitle: const Text('Mantiene las fechas pasadas intactas.'),
          onTap: () => Navigator.pop(context, 'future'),
        ),
        ListTile(
          leading: const Icon(Icons.repeat_rounded),
          title: const Text('Toda la rutina'),
          subtitle: const Text('Aplica a todas las fechas conectadas.'),
          onTap: () => Navigator.pop(context, 'all'),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))],
    ),
  );
}

class RoutineChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const RoutineChoice({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.teal : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: selected ? AppColors.teal : AppColors.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.repeat_rounded, color: selected ? Colors.white : AppColors.teal, size: 17),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900)),
      ]),
    ),
  );
}

class RoutineInfoBox extends StatelessWidget {
  final String text;
  const RoutineInfoBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.72),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.35))),
    ]),
  );
}

class EventTemplateChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const EventTemplateChoice({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.teal : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.teal : AppColors.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? Colors.white : AppColors.teal, size: 18),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900)),
      ]),
    ),
  );
}

class EventFormPreviewCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String location;
  final int minPeople;
  final String template;
  final String? repeatLabel;

  const EventFormPreviewCard({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.minPeople,
    required this.template,
    this.repeatLabel,
  });

  IconData get icon {
    final lower = template.toLowerCase();
    if (lower.contains('partido')) return Icons.sports_soccer_rounded;
    if (lower.contains('entrenamiento')) return Icons.fitness_center_rounded;
    if (lower.contains('cena')) return Icons.restaurant_rounded;
    if (lower.contains('reun')) return Icons.forum_rounded;
    return Icons.event_available_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isRoutine = repeatLabel != null && repeatLabel!.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF006B69), Color(0xFF00998E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const [BoxShadow(color: Color(0x16008F86), blurRadius: 18, offset: Offset(0, 9))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 54,
            height: 56,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(18)),
            child: Icon(isRoutine ? Icons.repeat_rounded : icon, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 8),
            Text(longDateTime(date), style: const TextStyle(color: Color(0xEFFFFFFF), fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(location.trim().isEmpty ? 'Lugar por definir' : location.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(99)),
                child: Text('Mínimo $minPeople asistentes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              if (isRoutine)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.22), borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.repeat_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(repeatLabel!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ]),
                ),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class PremiumEventDetailHero extends StatelessWidget {
  final Map<String, dynamic> event;
  final DateTime date;
  final int yes;
  final int minPeople;

  const PremiumEventDetailHero({
    super.key,
    required this.event,
    required this.date,
    required this.yes,
    required this.minPeople,
  });

  @override
  Widget build(BuildContext context) {
    final ok = yes >= minPeople;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: ok ? const [Color(0xFF0D8F72), Color(0xFF15B38C)] : const [Color(0xFF006B69), Color(0xFF00998E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x16008F86), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 58,
              height: 62,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(18)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(shortWeekday(date).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                Text(date.day.toString(), style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Text(longDateTime(date), style: const TextStyle(color: Color(0xEFFFFFFF), fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(AppData.text(event['location'], 'Sin ubicación'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700)),
            ])),
          ]),
          if (AppData.text(event['notes']).isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(16)),
              child: Text(AppData.text(event['notes']), style: const TextStyle(color: Colors.white, height: 1.35, fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(99)),
            child: Text(ok ? 'Mínimo alcanzado · $yes/$minPeople' : 'Faltan ${max(0, minPeople - yes)} · $yes/$minPeople confirmados', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }
}

class AttendanceOverviewCard extends StatelessWidget {
  final int yes;
  final int maybe;
  final int no;
  final int pending;
  final int minPeople;

  const AttendanceOverviewCard({
    super.key,
    required this.yes,
    required this.maybe,
    required this.no,
    required this.pending,
    required this.minPeople,
  });

  @override
  Widget build(BuildContext context) {
    final ok = yes >= minPeople;
    final total = max(1, yes + maybe + no + pending);
    final answered = yes + maybe + no;
    final missingForMinimum = max(0, minPeople - yes);
    final progress = (yes / max(1, minPeople)).clamp(0.0, 1.0).toDouble();
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded, color: ok ? AppColors.green : AppColors.amber),
        const SizedBox(width: 9),
        Expanded(child: Text(ok ? 'Todo listo' : 'Falta $missingForMinimum ${missingForMinimum == 1 ? 'persona' : 'personas'}', style: Theme.of(context).textTheme.titleMedium)),
        Text('$yes/$minPeople', style: TextStyle(color: ok ? AppColors.green : AppColors.amber, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 9,
          backgroundColor: AppColors.faint,
          color: ok ? AppColors.green : AppColors.amber,
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _AttendanceMiniStat(label: 'Van', value: yes, color: AppColors.green)),
        Expanded(child: _AttendanceMiniStat(label: 'Duda', value: maybe, color: AppColors.amber)),
        Expanded(child: _AttendanceMiniStat(label: 'No van', value: no, color: AppColors.red)),
        Expanded(child: _AttendanceMiniStat(label: 'Faltan', value: pending, color: AppColors.muted)),
      ]),
      const SizedBox(height: 8),
      Text('Han respondido $answered de $total personas.', style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w800)),
    ]));
  }
}

class _AttendanceMiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AttendanceMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
  ]);
}



class EventMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const EventMetaChip({super.key, required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.72), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withOpacity(.14))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w800))),
      ]),
    );
  }
}

// ---------- UI components ----------

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)));
}

class PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool loading;
  const PrimaryButton({super.key, required this.label, required this.onTap, this.icon, this.loading = false});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final radius = AppColors.humanRadius;
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        offset: hovering ? const Offset(0, -.025) : Offset.zero,
        child: PressableScale(
          onTap: widget.loading ? null : widget.onTap,
          borderRadius: radius,
          pressedScale: .975,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: radius,
                color: AppColors.tealDark,
                border: Border.all(color: hovering ? AppColors.humanAccent : AppColors.teal, width: hovering ? 2.4 : 1.2),
                boxShadow: const [BoxShadow(color: AppColors.mediumShadow, blurRadius: 22, offset: Offset(0, 10))],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: widget.loading
                      ? const SizedBox(key: ValueKey('loading'), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : Row(
                          key: const ValueKey('content'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon ?? Icons.check_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 9),
                            Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -.15)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const SecondaryButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final radius = AppColors.humanRadius;
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        offset: hovering ? const Offset(0, -.018) : Offset.zero,
        child: PressableScale(
          onTap: widget.onTap,
          borderRadius: radius,
          pressedScale: .975,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: radius,
              border: Border.all(color: hovering ? AppColors.teal : const Color(0x330E6B73), width: hovering ? 2 : 1),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, size: 20, color: AppColors.teal),
              const SizedBox(width: 9),
              Text(widget.label, style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const DangerButton({super.key, required this.label, required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 54, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: Color(0xFFFFC7C7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: onTap, icon: Icon(icon), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))));
}

class WhiteButton extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const WhiteButton({super.key, required this.label, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(height: 48, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: onTap, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))));
}

class SocialButton extends StatelessWidget {
  final String label; final String icon; final VoidCallback onTap;
  const SocialButton({super.key, required this.label, required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 46, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: onTap, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 12), Text(label, style: const TextStyle(fontWeight: FontWeight.w800))])));
}

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final Color? accentColor;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.onTap,
    this.color = AppColors.white,
    this.accentColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final radius = AppColors.softRadius;
    final accent = widget.accentColor;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, hovering && widget.onTap != null ? -2 : 0, 0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: radius,
        border: Border.all(color: hovering && widget.onTap != null ? AppColors.teal.withOpacity(.42) : AppColors.lineSoft, width: hovering && widget.onTap != null ? 1.6 : 1),
        boxShadow: const [BoxShadow(color: AppColors.softShadow, blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: accent == null
          ? widget.child
          : Stack(children: [
              Positioned(left: 0, top: 1, bottom: 1, child: Container(width: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(99)))),
              Padding(padding: const EdgeInsets.only(left: 15), child: widget.child),
            ]),
    );
    if (widget.onTap == null) return card;
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: PressableScale(
        onTap: widget.onTap,
        borderRadius: radius,
        child: card,
      ),
    );
  }
}

class RoundBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const RoundBackButton({super.key, this.onTap});
  @override Widget build(BuildContext context) => Container(
    width: 42,
    height: 44,
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line), boxShadow: const [BoxShadow(color: Color(0x08111B34), blurRadius: 12, offset: Offset(0, 4))]),
    child: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 20), onPressed: onTap ?? () => Navigator.of(context).maybePop()),
  );
}


class OwnProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  const OwnProfileButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AppData.profile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const <String, dynamic>{};
        final name = AppData.text(profile['full_name'], AppData.user?.email?.split('@').first ?? 'Perfil');
        final avatar = AppData.text(profile['avatar_url']);
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 44,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
              boxShadow: const [BoxShadow(color: Color(0x07111B34), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: ProfileAvatar(name: name, avatarUrl: avatar, radius: 18),
          ),
        );
      },
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool filled;
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.filled = false});
  @override Widget build(BuildContext context) => Container(
    width: 42,
    height: 44,
    decoration: BoxDecoration(
      color: filled ? AppColors.navHome : AppColors.white,
      shape: BoxShape.circle,
      border: filled ? null : Border.all(color: AppColors.line),
      boxShadow: filled ? const [BoxShadow(color: Color(0x33053A59), blurRadius: 18, offset: Offset(0, 8))] : const [BoxShadow(color: Color(0x07111B34), blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: IconButton(onPressed: onTap, icon: Icon(icon, size: 20, color: filled ? Colors.white : AppColors.ink)),
  );
}

class OrDivider extends StatelessWidget { const OrDivider({super.key}); @override Widget build(BuildContext context) => Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))), Expanded(child: Divider())]); }


void appLightHaptic() {
  if (kIsWeb) return;
  try {
    HapticFeedback.selectionClick();
  } catch (_) {
    // Haptic feedback is optional and must never block the UI.
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double pressedScale;
  final bool haptic;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.pressedScale = .985,
    this.haptic = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _setPressed(false);
              if (widget.haptic) appLightHaptic();
              widget.onTap?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 95),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const StatCard({super.key, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    color: AppColors.surface,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(color: color.withOpacity(.10), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(height: 6),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
      const SizedBox(height: 1),
      Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
    ]),
  );
}

class MoneyStat extends StatelessWidget {
  final String label; final double value; final bool positiveMeansGood;
  const MoneyStat({super.key, required this.label, required this.value, required this.positiveMeansGood});
  @override Widget build(BuildContext context) {
    final color = value >= 0 ? AppColors.green : AppColors.red;
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 8), Text(money(value), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 19))]));
  }
}


class GroupHomeCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  const GroupHomeCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final members = AppData.intValue(group['members_count'], 1);
    final events = AppData.intValue(group['events_count'], 0);
    final cover = AppData.text(group['cover_url']);
    final hasCover = cover.trim().isNotEmpty;
    final memberLabel = members == 1 ? 'miembro' : 'miembros';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: 'Abrir grupo $name',
        child: PressableScale(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          pressedScale: .985,
          child: Container(
            height: 116,
            decoration: BoxDecoration(
              color: AppColors.navHome,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [BoxShadow(color: Color(0x26053A59), blurRadius: 28, offset: Offset(0, 14))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(children: [
                Positioned.fill(
                  child: hasCover
                      ? Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.navHome),
                        )
                      : Container(color: AppColors.navHome),
                ),
                if (hasCover)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0x99000000), Color(0x44000000), Color(0x22000000)],
                        ),
                      ),
                    ),
                  ),
                if (!hasCover)
                  Positioned(
                    left: 18,
                    top: 24,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: const Color(0x22000000), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x33FFFFFF))),
                      child: Icon(groupTypeIcon(AppData.text(group['type'], 'otro')), color: Colors.white, size: 34),
                    ),
                  ),
                Positioned(
                  left: hasCover ? 24 : 108,
                  right: 58,
                  top: 21,
                  bottom: 18,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.35,
                            shadows: [Shadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 3))],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.lock_rounded, size: 13, color: Color(0xF2FFFFFF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Privado · $members $memberLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900, shadows: [Shadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 2))]),
                        ),
                      ),
                    ]),
                    const Spacer(),
                    Text(
                      events == 0 ? 'Sin planes próximos' : '$events ${events == 1 ? 'plan próximo' : 'planes próximos'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xEFFFFFFF), fontSize: 12.5, fontWeight: FontWeight.w800, shadows: [Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2))]),
                    ),
                  ]),
                ),
                Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: Color(0x30FFFFFF), shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class RootBottomNav extends StatelessWidget {
  final int index; final ValueChanged<int> onTap;
  const RootBottomNav({super.key, required this.index, required this.onTap});
  @override Widget build(BuildContext context) => BottomBar(items: const [NavSpec(Icons.home_rounded, 'Inicio'), NavSpec(Icons.notifications_none_rounded, 'Avisos'), NavSpec(Icons.person_outline_rounded, 'Perfil')], index: index, onTap: onTap);
}

class GroupBottomNav extends StatelessWidget {
  final String groupName; final int index; final ValueChanged<int> onTap;
  const GroupBottomNav({super.key, required this.groupName, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: BottomBar(
        items: const [
          NavSpec(Icons.home_rounded, 'Inicio'),
          NavSpec(Icons.calendar_month_rounded, 'Agenda'),
          NavSpec(Icons.account_balance_wallet_rounded, 'Finanzas'),
          NavSpec(Icons.emoji_events_rounded, 'Torneos'),
          NavSpec(Icons.more_horiz_rounded, 'Más'),
        ],
        index: index,
        onTap: onTap,
      ),
    );
  }
}

class NavSpec { final IconData icon; final String label; const NavSpec(this.icon, this.label); }

Color navColorFor(int index, int count) {
  if (count <= 3) {
    switch (index) {
      case 0: return AppColors.navHome;
      case 1: return AppColors.amber;
      default: return AppColors.violet;
    }
  }
  switch (index) {
    case 0: return AppColors.navHome;
    case 1: return AppColors.navAgenda;
    case 2: return AppColors.navFinance;
    case 3: return AppColors.navTournaments;
    default: return AppColors.navMore;
  }
}

class BottomBar extends StatelessWidget {
  final List<NavSpec> items;
  final int index;
  final ValueChanged<int> onTap;
  const BottomBar({super.key, required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.lineSoft),
      boxShadow: const [BoxShadow(color: Color(0x14111B34), blurRadius: 28, offset: Offset(0, -4))],
    ),
    child: Row(children: List.generate(items.length, (i) {
      final active = i == index;
      final spec = items[i];
      final color = navColorFor(i, items.length);
      return Expanded(
        child: PressableScale(
          onTap: active ? null : () => onTap(i),
          borderRadius: BorderRadius.circular(20),
          pressedScale: .94,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            height: 58,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: active ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: active ? [BoxShadow(color: color.withOpacity(.24), blurRadius: 16, offset: const Offset(0, 7))] : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              style: TextStyle(fontSize: items.length >= 5 ? 9.4 : 10.2, fontWeight: FontWeight.w900, color: active ? Colors.white : AppColors.muted),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedScale(
                  scale: active ? 1.06 : 1,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: Icon(spec.icon, size: 22, color: active ? Colors.white : color),
                ),
                const SizedBox(height: 3),
                Text(spec.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
      );
    })),
  );
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool leading;
  final Widget? action;
  const PageHeader({super.key, required this.title, this.subtitle = '', this.leading = false, this.action});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
    if (leading) ...[RoundBackButton(onTap: () => Navigator.of(context).maybePop()), const SizedBox(width: 12)],
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineMedium),
      if (subtitle.trim().isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.32, fontSize: 14)),
      ],
    ])),
    if (action != null) ...[
      const SizedBox(width: 10),
      action!,
    ],
  ]);
}

class HeaderCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const HeaderCreateButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.teal,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
      ),
    ),
  );
}

class CenterLoader extends StatelessWidget {
  final String label;
  const CenterLoader({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 42),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 58, height: 58, child: CustomPaint(painter: GrupliLoadingMarkPainter())),
          const SizedBox(height: 14),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.35)),
        ]),
      );
}

class GrupliLoadingMarkPainter extends CustomPainter {
  const GrupliLoadingMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.tealSoft;
    final line = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)), bg);
    final path = Path()
      ..moveTo(size.width * .24, size.height * .56)
      ..quadraticBezierTo(size.width * .38, size.height * .32, size.width * .52, size.height * .52)
      ..quadraticBezierTo(size.width * .64, size.height * .70, size.width * .78, size.height * .42);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorBlock({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final sessionProblem = looksLikeSessionProblem(message);
    final title = sessionProblem ? 'Sesión pausada' : 'La conexión titubeó';
    final body = sessionProblem ? 'Vuelve a entrar y dejamos todo en su sitio.' : humanizeError(message);
    return AppCard(
      color: AppColors.surfaceWarm,
      accentColor: sessionProblem ? AppColors.amber : AppColors.humanAccent,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(children: [
        const SizedBox(width: 76, height: 58, child: CustomPaint(painter: GrupliErrorMarkPainter())),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.38)),
        const SizedBox(height: 16),
        if (sessionProblem) ...[
          PrimaryButton(
            label: 'Salir y volver a entrar',
            icon: Icons.logout_rounded,
            onTap: () async {
              await AppData.clearLocalSession();
              onRetry();
            },
          ),
          const SizedBox(height: 10),
        ],
        SecondaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onTap: onRetry),
      ]),
    );
  }
}

class GrupliErrorMarkPainter extends CustomPainter {
  const GrupliErrorMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = AppColors.humanAccentSoft;
    final stroke = Paint()
      ..color = AppColors.humanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final blob = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .05, size.height * .12, size.width * .9, size.height * .72), const Radius.circular(22));
    canvas.drawRRect(blob, fill);
    final path = Path()
      ..moveTo(size.width * .22, size.height * .54)
      ..cubicTo(size.width * .34, size.height * .30, size.width * .46, size.height * .76, size.width * .58, size.height * .52)
      ..cubicTo(size.width * .64, size.height * .38, size.width * .70, size.height * .37, size.width * .78, size.height * .48);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(Offset(size.width * .80, size.height * .30), 2.4, Paint()..color = AppColors.humanAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmptyBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const EmptyBlock({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.surfaceWarm,
        accentColor: AppColors.teal,
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        child: Column(children: [
          Container(
            width: 72,
            height: 66,
            decoration: BoxDecoration(color: AppColors.tealMist, borderRadius: AppColors.humanRadius, border: Border.all(color: const Color(0x220E6B73))),
            child: Icon(icon, color: AppColors.teal, size: 31),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 7),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.38)),
        ]),
      );
}

class EmptySlim extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const EmptySlim({super.key, required this.icon, required this.title, this.body = ''});

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.surfaceWarm,
        padding: const EdgeInsets.all(14),
        accentColor: AppColors.teal,
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealMist, borderRadius: AppColors.humanRadius, border: Border.all(color: const Color(0x1A0E6B73))), child: Icon(icon, color: AppColors.teal, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            if (body.trim().isNotEmpty) ...[const SizedBox(height: 4), Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.28))],
          ])),
        ]),
      );
}

bool looksLikeNetworkError(String raw) {
  final text = raw.toLowerCase();
  return text.contains('network') ||
      text.contains('socket') ||
      text.contains('connection') ||
      text.contains('failed host lookup') ||
      text.contains('xmlhttprequest') ||
      text.contains('internet');
}

bool looksLikeSessionProblem(String raw) {
  final text = raw.toLowerCase();
  if (text.contains('invalid login credentials') || text.contains('email not confirmed') || text.contains('invalid email')) return false;
  return text.contains('not_authenticated') ||
      text.contains('usuario no autenticado') ||
      text.contains('jwt') ||
      text.contains('refresh token') ||
      text.contains('invalid refresh') ||
      text.contains('invalid_grant') ||
      text.contains('session_id') ||
      text.contains('session not found') ||
      text.contains('session from') ||
      text.contains('auth session missing') ||
      text.contains('no current user') ||
      text.contains('session expired') ||
      text.contains('expired token');
}

String humanizeError(String raw) {
  final original = raw.replaceAll('Exception: ', '').trim();
  final text = original.toLowerCase();
  if (text.isEmpty) return 'No se pudo completar la acción. Inténtalo de nuevo.';
  if (text.contains('invalid login credentials')) return 'Email o contraseña incorrectos.';
  if (text.contains('email not confirmed')) return 'Confirma tu email antes de iniciar sesión.';
  if (text.contains('invalid email')) return 'El email no tiene un formato válido.';
  if (text.contains('weak password')) return 'La contraseña es demasiado débil.';
  if (text.contains('user already registered') || text.contains('already registered')) return 'Esta cuenta ya existe. Inicia sesión en lugar de registrarte.';
  if (text.contains('confirmation_required')) return 'Para eliminar la cuenta debes escribir ELIMINAR exactamente.';
  if (looksLikeSessionProblem(original)) return 'Tu sesión ha caducado. Cierra sesión e inicia sesión de nuevo.';
  if (text.contains('owner_protected') || text.contains('owner') || text.contains('creador del grupo')) return 'El creador del grupo está protegido. Transfiere o elimina el grupo antes de hacer esa acción.';
  if (text.contains('member_not_found') || text.contains('not_member')) return 'Ese miembro ya no está disponible en el grupo.';
  if (text.contains('invalid_role')) return 'Ese rol no es válido.';
  if (text.contains('settlement_payments') || text.contains('create_settlement_payment_atomic')) return 'Finanzas necesita una actualización interna. Vuelve a intentarlo más tarde.';
  if (text.contains('tournaments_scoring_type_check')) return 'Torneos necesita una actualización interna. Vuelve a intentarlo más tarde.';
  if (text.contains('permission') || text.contains('policy') || text.contains('rls') || text.contains('not allowed') || text.contains('denied') || text.contains('violates row-level')) return 'No tienes permiso para hacer esa acción.';
  if (looksLikeNetworkError(original)) return 'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.';
  if (text.contains('duplicate') || text.contains('already') || text.contains('unique constraint')) return 'Parece que esto ya existe o ya se había guardado.';
  if (text.contains('foreign key') || text.contains('violates') || text.contains('constraint')) return 'No se pudo guardar porque hay datos relacionados. Revisa la acción e inténtalo de nuevo.';
  if (text.contains('postgrestexception') || text.contains('pgrst') || text.contains('supabase') || text.contains('postgres')) return 'No se pudo completar la acción en la base de datos. Inténtalo otra vez.';
  if (original.length > 120) return 'No se pudo completar la acción. Inténtalo de nuevo.';
  return original;
}

class HomeLoading extends StatelessWidget { const HomeLoading({super.key}); @override Widget build(BuildContext context) => Column(children: [Row(children: const [Expanded(child: GhostBox(height: 90)), SizedBox(width: 10), Expanded(child: GhostBox(height: 90)), SizedBox(width: 10), Expanded(child: GhostBox(height: 90))]), const SizedBox(height: 24), const GhostBox(height: 100), const SizedBox(height: 10), const GhostBox(height: 100)]); }
class GhostBox extends StatelessWidget {
  final double height;
  const GhostBox({super.key, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: AppColors.softRadius,
          border: Border.all(color: AppColors.hairline),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceWarm, AppColors.faint, AppColors.tealMist],
            stops: [0, .58, 1],
          ),
        ),
        child: ClipRRect(
          borderRadius: AppColors.softRadius,
          child: CustomPaint(painter: GrupliSkeletonPainter()),
        ),
      );
}

class GrupliSkeletonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.46)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * .12, size.height * .36), Offset(size.width * .68, size.height * .36), paint);
    paint.strokeWidth = 8;
    paint.color = Colors.white.withOpacity(.36);
    canvas.drawLine(Offset(size.width * .12, size.height * .58), Offset(size.width * .48, size.height * .58), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChoiceBigCard extends StatelessWidget { final IconData icon; final String title; final String body; final VoidCallback onTap; const ChoiceBigCard({super.key, required this.icon, required this.title, required this.body, required this.onTap}); @override Widget build(BuildContext context) => AppCard(onTap: onTap, child: Row(children: [Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealSoft), child: Icon(icon, color: AppColors.teal)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text(body, style: Theme.of(context).textTheme.bodyMedium)])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)])); }

class MiniAction extends StatelessWidget { final IconData icon; final String label; final VoidCallback onTap; const MiniAction({super.key, required this.icon, required this.label, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)), child: Column(children: [Icon(icon, color: AppColors.ink), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))]))); }

class Grid2 extends StatelessWidget { final List<Widget> children; const Grid2({super.key, required this.children}); @override Widget build(BuildContext context) => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55, children: children); }

class FeatureTile extends StatelessWidget { final IconData icon; final String title; final String body; final Color color; final VoidCallback onTap; const FeatureTile({super.key, required this.icon, required this.title, required this.body, required this.color, required this.onTap}); @override Widget build(BuildContext context) => AppCard(onTap: onTap, child: Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12))]))])); }

class ActivityRow extends StatelessWidget { final IconData icon; final String title; final String meta; const ActivityRow({super.key, required this.icon, required this.title, required this.meta}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [CircleAvatar(radius: 16, backgroundColor: AppColors.tealSoft, child: Icon(icon, color: AppColors.teal, size: 17)), const SizedBox(width: 11), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), Text(meta, style: const TextStyle(color: AppColors.muted, fontSize: 12))])); }


class QuickTemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const QuickTemplateChip({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    avatar: const Icon(Icons.add_rounded, size: 17),
    backgroundColor: AppColors.faint,
    side: const BorderSide(color: AppColors.line),
    onPressed: onTap,
  );
}

class DateBadge extends StatelessWidget {
  final DateTime date;
  const DateBadge({super.key, required this.date});
  @override
  Widget build(BuildContext context) => Container(
    width: 62,
    height: 66,
    decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(shortWeekday(date).toUpperCase(), style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w900)),
      Text(date.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w900)),
    ]),
  );
}





class AgendaPremiumHero extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> upcomingEvents;
  final Map<String, dynamic> group;
  final VoidCallback onCreate;
  final VoidCallback onChanged;

  const AgendaPremiumHero({
    super.key,
    required this.events,
    required this.upcomingEvents,
    required this.group,
    required this.onCreate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final next = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;
    final nextDayEvents = eventsOnSameDay(upcomingEvents, next);
    final totalYes = upcomingEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'yes'));
    final totalMaybe = upcomingEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'maybe'));

    if (next != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (nextDayEvents.length > 1)
          AgendaSameDayCompactCard(events: nextDayEvents, group: group, onChanged: onChanged, title: 'Próximos de ese día')
        else
          EventAgendaCard(event: next, group: group, onChanged: onChanged),
        const SizedBox(height: 10),
        AgendaMatteStatsRow(
          events: events.length,
          upcoming: upcomingEvents.length,
          attendance: '$totalYes / $totalMaybe',
        ),
      ]);
    }

    return AppCard(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 58,
            height: 62,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.18))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('SIN', style: TextStyle(color: AppColors.navAgenda, fontSize: 10, fontWeight: FontWeight.w900)),
              const Text('+', style: TextStyle(color: AppColors.ink, fontSize: 25, fontWeight: FontWeight.w900, height: 1)),
              Text(DateFormat('MMM', 'es_ES').format(DateTime.now()).replaceAll('.', ''), style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Próximo plan', style: TextStyle(color: Color(0xDFFFFFFF), fontSize: 12, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text(
              'Crea el primer plan del grupo',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21, height: 1.05, letterSpacing: -.25),
            ),
          ])),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: TextButton.icon(
              onPressed: onCreate,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Elige un día, crea un evento y el grupo podrá confirmar asistencia desde la Agenda.',
          style: TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.32),
        ),
        const SizedBox(height: 12),
        AgendaMatteStatsRow(events: events.length, upcoming: upcomingEvents.length, attendance: '$totalYes / $totalMaybe'),
      ]),
    );
  }
}

class AgendaMatteStatsRow extends StatelessWidget {
  final int events;
  final int upcoming;
  final String attendance;
  const AgendaMatteStatsRow({super.key, required this.events, required this.upcoming, required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: MatteStatTile(label: 'Eventos', value: '$events', icon: Icons.calendar_month_rounded, color: AppColors.navAgenda)),
      const SizedBox(width: 8),
      Expanded(child: MatteStatTile(label: 'Próximos', value: '$upcoming', icon: Icons.event_available_rounded, color: AppColors.teal)),
      const SizedBox(width: 8),
      Expanded(child: MatteStatTile(label: 'Van / duda', value: attendance, icon: Icons.groups_rounded, color: AppColors.green)),
    ]);
  }
}

class MatteStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const MatteStatTile({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 1),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 10.5)),
        ])),
      ]),
    );
  }
}

class AgendaViewSwitch extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const AgendaViewSwitch({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(5),
      color: AppColors.tealSoft,
      child: Row(children: [
        Expanded(child: _AgendaSwitchItem(label: 'Semana', icon: Icons.view_week_rounded, selected: index == 0, onTap: () => onChanged(0))),
        const SizedBox(width: 5),
        Expanded(child: _AgendaSwitchItem(label: 'Mes', icon: Icons.calendar_month_rounded, selected: index == 1, onTap: () => onChanged(1))),
      ]),
    );
  }
}

class _AgendaSwitchItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _AgendaSwitchItem({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected ? [BoxShadow(color: AppColors.teal.withOpacity(.10), blurRadius: 12, offset: const Offset(0, 6))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? AppColors.teal : AppColors.muted, size: 18),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(color: selected ? AppColors.ink : AppColors.muted, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class AgendaWeekHeader extends StatelessWidget {
  final DateTime selected;
  final int weekEvents;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  const AgendaWeekHeader({super.key, required this.selected, required this.weekEvents, required this.onPrevious, required this.onNext, required this.onToday});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 6));
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${DateFormat('d MMM', 'es_ES').format(start)} — ${DateFormat('d MMM', 'es_ES').format(end)}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text('$weekEvents planes en los próximos 7 días', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      TextButton.icon(onPressed: onToday, icon: const Icon(Icons.today_rounded, size: 17), label: const Text('Hoy')),
    ]);
  }
}

class AgendaMonthHeader extends StatelessWidget {
  final DateTime month;
  final int eventsCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  const AgendaMonthHeader({super.key, required this.month, required this.eventsCount, required this.onPrevious, required this.onNext, required this.onToday});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _RoundIconButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(monthTitle(month), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text('$eventsCount eventos este mes', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      TextButton(onPressed: onToday, child: const Text('Hoy')),
      _RoundIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
    ]);
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)),
      child: Icon(icon, color: AppColors.ink),
    ),
  );
}

class PremiumWeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final Map<String, List<Map<String, dynamic>>> eventsByDay;
  final ValueChanged<DateTime> onSelect;

  const PremiumWeekStrip({super.key, required this.days, required this.selected, required this.eventsByDay, required this.onSelect});

  List<Map<String, dynamic>> eventsFor(DateTime day) => eventsByDay[calendarDayKey(day)] ?? const <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) {
    return Row(children: days.map((day) {
      final active = sameDay(day, selected);
      final today = sameDay(day, DateTime.now());
      final dayEvents = eventsFor(day);
      final hasEvents = dayEvents.isNotEmpty;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.teal : hasEvents ? eventKindSoftColor(dayEvents.first) : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active ? AppColors.teal : today ? AppColors.teal.withOpacity(.45) : hasEvents ? eventKindColor(dayEvents.first).withOpacity(.34) : AppColors.line),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(shortWeekday(day).toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? Colors.white : AppColors.muted, fontSize: 10, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(day.day.toString(), style: TextStyle(color: active ? Colors.white : AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 11,
                  child: hasEvents
                      ? EventDayMarkers(events: dayEvents, active: active)
                      : Container(width: today ? 18 : 7, height: 4, decoration: BoxDecoration(color: active ? Colors.white : AppColors.line, borderRadius: BorderRadius.circular(99))),
                ),
              ]),
            ),
          ),
        ),
      );
    }).toList());
  }
}

class PremiumMonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final Map<String, List<Map<String, dynamic>>> eventsByDay;
  final ValueChanged<DateTime> onSelect;
  const PremiumMonthCalendar({super.key, required this.month, required this.selected, required this.eventsByDay, required this.onSelect});

  List<Map<String, dynamic>> eventsFor(DateTime day) => eventsByDay[calendarDayKey(day)] ?? const <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final startOffset = (first.weekday + 6) % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) { cells.add(null); }
    for (int d = 1; d <= days; d++) { cells.add(DateTime(month.year, month.month, d)); }
    while (cells.length % 7 != 0) { cells.add(null); }

    final rows = <List<DateTime?>>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(cells.sublist(i, min(i + 7, cells.length)));
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      color: AppColors.surface,
      child: Column(children: [
        Row(children: ['L','M','X','J','V','S','D'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.muted, fontSize: 12))))).toList()),
        const SizedBox(height: 10),
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: row.map((day) {
            if (day == null) return const Expanded(child: SizedBox(height: 46));
            final active = sameDay(day, selected);
            final today = sameDay(day, DateTime.now());
            final dayEvents = eventsFor(day);
            final hasEvents = dayEvents.isNotEmpty;
            return Expanded(
              child: SizedBox(
                height: 46,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(day),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? AppColors.teal : hasEvents ? eventKindSoftColor(dayEvents.first) : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: active ? AppColors.teal : today ? AppColors.teal.withOpacity(.45) : hasEvents ? eventKindColor(dayEvents.first).withOpacity(.38) : Colors.transparent),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(day.day.toString(), maxLines: 1, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: active || hasEvents || today ? FontWeight.w900 : FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 7,
                        child: hasEvents
                            ? EventDayMarkers(events: dayEvents, active: active, compact: true)
                            : today
                                ? Container(width: 14, height: 4, decoration: BoxDecoration(color: active ? Colors.white : AppColors.teal, borderRadius: BorderRadius.circular(99)))
                                : const SizedBox.shrink(),
                      ),
                    ]),
                  ),
                ),
              ),
            );
          }).toList()),
        )),
      ]),
    );
  }
}

class AgendaSelectedDayCard extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> events;
  final int confirmed;
  final int maybe;
  final VoidCallback onCreate;
  const AgendaSelectedDayCard({super.key, required this.day, required this.events, required this.confirmed, required this.maybe, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    final color = agendaDayAccentColor(events);
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: agendaDaySoftColor(events),
      child: Row(children: [
        Container(
          width: 58,
          height: 64,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.16))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(shortWeekday(day).toUpperCase(), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
            Text(day.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 23, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(longDay(day), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            hasEvents ? '${events.length} plan${events.length == 1 ? '' : 'es'} · $confirmed van · $maybe duda' : 'Día libre para crear un nuevo plan',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.25),
          ),
        ])),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: TextButton.icon(
            onPressed: onCreate,
            style: TextButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class PremiumAgendaEmptyState extends StatelessWidget {
  final bool hasAnyEvents;
  final DateTime selected;
  final VoidCallback onCreate;
  const PremiumAgendaEmptyState({super.key, required this.hasAnyEvents, required this.selected, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      color: AppColors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.event_available_rounded, color: AppColors.navAgenda)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hasAnyEvents ? 'No hay planes este día' : 'Empieza la agenda del grupo', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              hasAnyEvents
                  ? 'El ${DateFormat('d MMM', 'es_ES').format(selected)} está libre. Puedes crear un plan o revisar los próximos eventos.'
                  : 'Crea el primer evento y los miembros podrán confirmar asistencia desde aquí.',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.32),
            ),
          ])),
        ]),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: PrimaryButton(label: 'Crear plan para este día', icon: Icons.add_rounded, onTap: onCreate)),
      ]),
    );
  }
}

class AgendaRecoveryCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onRetry;
  const AgendaRecoveryCard({super.key, required this.onCreate, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.tealSoft,
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.event_available_rounded, color: AppColors.teal)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('La agenda no puede quedar en blanco', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          SizedBox(height: 3),
          Text('Aunque falle la carga, siempre verás este panel para reintentar o crear un plan.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
        ])),
        const SizedBox(width: 8),
        Column(children: [
          SizedBox(width: 96, child: PrimaryButton(label: 'Crear', icon: Icons.add_rounded, onTap: onCreate)),
          const SizedBox(height: 7),
          SizedBox(width: 96, child: SecondaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onTap: onRetry)),
        ]),
      ]),
    );
  }
}

class CalendarOverviewCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> upcomingEvents;
  final VoidCallback onCreate;
  const CalendarOverviewCard({super.key, required this.events, required this.upcomingEvents, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final next = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;
    final activeEvents = events.length;
    final nextDate = next == null ? null : DateTime.tryParse(next['starts_at']?.toString() ?? '')?.toLocal();
    final nextColor = next == null ? AppColors.teal : eventKindColor(next);
    final totalYes = upcomingEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'yes'));
    final totalMaybe = upcomingEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'maybe'));

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(children: [
            Positioned(
              right: -32,
              top: -38,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: nextColor.withOpacity(.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -26,
              bottom: -34,
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(16)),
                    child: Icon(next == null ? Icons.calendar_month_rounded : eventKindIcon(next), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      next == null ? 'Aún no hay planes' : 'Próximo plan',
                      style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      next == null ? 'Crea el primer evento del grupo' : AppData.text(next['title'], 'Evento'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, height: 1.05),
                    ),
                  ])),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: TextButton.icon(
                      onPressed: onCreate,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
                if (next != null) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _WhiteMetaPill(icon: Icons.schedule_rounded, text: nextDate == null ? 'Fecha pendiente' : longDateTime(nextDate)),
                    _WhiteMetaPill(icon: Icons.place_outlined, text: AppData.text(next['location'], 'Sin ubicación')),
                    _WhiteMetaPill(icon: Icons.people_alt_rounded, text: "${attendanceCount(next, 'yes')} van · mínimo ${AppData.intValue(next['min_people'], 2)}"),
                  ]),
                ],
                const SizedBox(height: 13),
                Row(children: [
                  Expanded(child: _DarkAgendaMetric(label: 'Eventos', value: '$activeEvents')),
                  const SizedBox(width: 8),
                  Expanded(child: _DarkAgendaMetric(label: 'Próximos', value: '${upcomingEvents.length}')),
                  const SizedBox(width: 8),
                  Expanded(child: _DarkAgendaMetric(label: 'Van / duda', value: '$totalYes / $totalMaybe')),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WhiteMetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _WhiteMetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withOpacity(.12))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 6),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
      ]),
    );
  }
}

class _DarkAgendaMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DarkAgendaMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(.10))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 10.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class CalendarDaySummary extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> events;
  final int confirmed;
  final int maybe;
  final VoidCallback onCreate;
  const CalendarDaySummary({super.key, required this.day, required this.events, required this.confirmed, required this.maybe, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    final color = agendaDayAccentColor(events);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(children: [
        DateBadge(date: day),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(longDay(day), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            hasEvents ? '${events.length} plan${events.length == 1 ? '' : 'es'} · $confirmed van · $maybe duda' : 'Día libre',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ])),
        const SizedBox(width: 8),
        SizedBox(
          height: 38,
          child: TextButton.icon(
            onPressed: onCreate,
            style: TextButton.styleFrom(backgroundColor: color.withOpacity(.10), foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}



String agendaSelectedDayTitle(DateTime day) {
  final today = DateTime.now();
  if (sameDay(day, today)) return 'Hoy';
  return DateFormat('EEEE d MMM', 'es_ES').format(day).replaceAll('.', '');
}

class AgendaGroupedUpcomingList extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  final DateTime? excludeDay;
  final VoidCallback onCreate;
  const AgendaGroupedUpcomingList({
    super.key,
    required this.events,
    required this.group,
    required this.onChanged,
    this.excludeDay,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = events.where((event) {
      if (excludeDay == null) return true;
      final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal();
      return date == null || !sameDay(date, excludeDay!);
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(AppData.text(a['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(AppData.text(b['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });

    if (filtered.isEmpty) {
      return AgendaNoMorePlansCard(onCreate: onCreate);
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final event in filtered) {
      final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal();
      if (date == null) continue;
      grouped.putIfAbsent(calendarDayKey(date), () => <Map<String, dynamic>>[]).add(event);
    }

    final keys = grouped.keys.toList()..sort();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final key in keys.take(5)) ...[
        AgendaSameDayCompactCard(
          events: grouped[key]!,
          group: group,
          onChanged: onChanged,
          title: agendaSelectedDayTitle(DateTime.parse(key)),
          compactHeader: true,
        ),
        const SizedBox(height: 10),
      ],
      if (keys.length > 5)
        AppCard(
          color: AppColors.surface,
          padding: const EdgeInsets.all(12),
          child: Text('+ ${keys.length - 5} días más con planes', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
        ),
    ]);
  }
}

class AgendaNoMorePlansCard extends StatelessWidget {
  final VoidCallback onCreate;
  const AgendaNoMorePlansCard({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.surface,
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(
        width: 42,
        height: 44,
        decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.event_available_rounded, color: AppColors.orange, size: 20),
      ),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('No hay más planes', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        SizedBox(height: 3),
        Text('Crea un nuevo evento para el grupo.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: onCreate,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    ]),
  );
}

class AgendaSameDayCompactCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  final String title;
  final bool compactHeader;
  const AgendaSameDayCompactCard({super.key, required this.events, required this.group, required this.onChanged, this.title = 'Planes del día', this.compactHeader = false});

  @override
  Widget build(BuildContext context) {
    final ordered = [...events]..sort((a, b) {
      final da = DateTime.tryParse(AppData.text(a['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(AppData.text(b['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    final firstDate = DateTime.tryParse(AppData.text(ordered.first['starts_at']))?.toLocal() ?? DateTime.now();
    final hasTournament = ordered.any(eventIsTournamentEvent);
    final accent = hasTournament ? AppColors.teal : eventKindColor(ordered.first);

    Future<void> openEvent(Map<String, dynamic> event) async {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
      onChanged();
    }

    return AppCard(
      color: AppColors.white,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 45,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: accent.withOpacity(.20))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(shortWeekday(firstDate).toUpperCase(), style: TextStyle(color: accent, fontSize: 9.5, fontWeight: FontWeight.w900)),
              Text(firstDate.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 19, fontWeight: FontWeight.w900, height: 1)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 3),
            Text('${ordered.length} evento${ordered.length == 1 ? '' : 's'} · ${DateFormat('d MMM', 'es_ES').format(firstDate).replaceAll('.', '')}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          ])),
          if (hasTournament) const TournamentAgendaBadge(),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.lineSoft)),
          child: Column(children: [
            for (int i = 0; i < ordered.take(6).length; i++) ...[
              AgendaCompactEventRow(event: ordered[i], onTap: () => openEvent(ordered[i])),
              if (i != ordered.take(6).length - 1) const Divider(height: 1, indent: 58, color: AppColors.lineSoft),
            ],
          ]),
        ),
        if (ordered.length > 6) ...[
          const SizedBox(height: 8),
          Text('+ ${ordered.length - 6} más', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ]),
    );
  }
}

class AgendaCompactEventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const AgendaCompactEventRow({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal() ?? DateTime.now();
    final color = eventKindColor(event);
    final isTournament = eventIsTournamentEvent(event);
    final yes = attendanceCount(event, 'yes');
    final minPeople = AppData.intValue(event['min_people'], 1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: isTournament ? Colors.white : eventKindSoftColor(event), borderRadius: BorderRadius.circular(14), border: Border.all(color: isTournament ? AppColors.lineSoft : Colors.transparent)),
            child: Icon(eventKindIcon(event), color: isTournament ? AppColors.amber : color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 3),
            Text('${DateFormat('HH:mm', 'es_ES').format(date)} · $yes/$minPeople van', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11.5)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class EventAgendaCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  const EventAgendaCard({super.key, required this.event, required this.group, required this.onChanged});
  @override
  State<EventAgendaCard> createState() => _EventAgendaCardState();
}

class _EventAgendaCardState extends State<EventAgendaCard> {
  bool saving = false;

  Future<void> setStatus(String status) async {
    if (saving) return;
    if (mounted) setState(() => saving = true);
    try {
      await AppData.setAttendance(widget.event['id'].toString(), status);
      widget.onChanged();
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> open() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: widget.event, group: widget.group)));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final yes = attendanceCount(event, 'yes');
    final maybe = attendanceCount(event, 'maybe');
    final no = attendanceCount(event, 'no');
    final minPeople = AppData.intValue(event['min_people'], 2);
    final mine = myAttendanceStatus(event);
    final viable = yes >= minPeople;
    final color = eventKindColor(event);
    final isTournament = eventIsTournamentEvent(event);
    final progress = min(1.0, yes / max(1, minPeople));

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: AppCard(
        color: AppColors.white,
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 48,
                  height: 52,
                  decoration: BoxDecoration(color: eventKindSoftColor(event), borderRadius: BorderRadius.circular(17)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(eventKindIcon(event), color: color, size: 20),
                    const SizedBox(height: 3),
                    Text(DateFormat('HH:mm', 'es_ES').format(date), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    EventKindPill(event: event, compact: true),
                    if (isTournament) const TournamentAgendaBadge(),
                    if (eventIsRoutine(event)) RoutineBadge(label: eventRoutineBadge(event)),
                  ]),
                  const SizedBox(height: 7),
                  Text(AppData.text(event['title'], 'Evento'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 16.5, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 6),
                  MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: AppColors.line,
                          valueColor: AlwaysStoppedAnimation<Color>(viable ? AppColors.green : color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$yes/$minPeople', style: TextStyle(color: viable ? AppColors.green : color, fontWeight: FontWeight.w900, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    viable ? 'Plan viable · mínimo alcanzado' : 'Faltan ${max(0, minPeople - yes)} para alcanzar el mínimo',
                    style: TextStyle(color: viable ? AppColors.green : AppColors.amber, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ])),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ]),
            ),
          ),
          Container(height: 1, color: AppColors.lineSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
            child: Row(children: [
              Expanded(child: CompactAttendanceButton(label: 'Voy', count: yes, selected: mine == 'yes', color: AppColors.green, onTap: saving ? () {} : () => setStatus('yes'))),
              const SizedBox(width: 7),
              Expanded(child: CompactAttendanceButton(label: 'Duda', count: maybe, selected: mine == 'maybe', color: AppColors.amber, onTap: saving ? () {} : () => setStatus('maybe'))),
              const SizedBox(width: 7),
              Expanded(child: CompactAttendanceButton(label: 'No', count: no, selected: mine == 'no', color: AppColors.red, onTap: saving ? () {} : () => setStatus('no'))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class CompactAttendanceButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const CompactAttendanceButton({super.key, required this.label, required this.count, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 38,
      decoration: BoxDecoration(color: selected ? color.withOpacity(.12) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? color : AppColors.lineSoft)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(width: 4),
        Text(count.toString(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
      ]),
    ),
  );
}

class EventMemberRoster extends StatelessWidget {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> members;
  const EventMemberRoster({super.key, required this.event, required this.members});
  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return EmptySlim(icon: Icons.groups_rounded, title: 'Sin miembros cargados', body: 'Cuando haya miembros, aquí verás quién va y quién falta por responder.');
    return Column(children: members.map((m) {
      final userId = AppData.text(m['user_id']);
      final status = eventStatusForUser(event, userId);
      final name = memberDisplayName(m);
      final color = attendanceColor(status);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), child: Row(children: [
          ProfileAvatar(name: name, avatarUrl: memberAvatarUrl(m), radius: 18),
          const SizedBox(width: 11),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)), child: Text(attendanceLabel(status), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12))),
        ])),
      );
    }).toList());
  }
}

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const EventCard({super.key, required this.event, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final yes = attendanceCount(event, 'yes');
    final maybe = attendanceCount(event, 'maybe');
    final minPeople = AppData.intValue(event['min_people'], 2);
    final viable = yes >= minPeople;
    final color = eventKindColor(event);
    final soft = eventKindSoftColor(event);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(.16)),
          boxShadow: [BoxShadow(color: color.withOpacity(.045), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: AppColors.white,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(children: [
                  Container(width: 6, color: color),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(
                        width: 54,
                        height: 58,
                        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(17)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(shortWeekday(d).toUpperCase(), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
                          Text(d.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(eventKindIcon(event), color: color, size: 16),
                          const SizedBox(width: 5),
                          Text(eventKindLabel(event), style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w900)),
                          if (eventIsRoutine(event)) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.repeat_rounded, color: color, size: 14),
                            const SizedBox(width: 4),
                            Flexible(child: Text(eventRoutineBadge(event), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w900))),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 5),
                        MetaLine(icon: Icons.schedule_rounded, text: DateFormat('dd/MM · HH:mm', 'es_ES').format(d)),
                        MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
                      ])),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: viable ? AppColors.greenSoft : AppColors.orangeSoft, borderRadius: BorderRadius.circular(99)), child: Text(viable ? '$yes/$minPeople OK' : '$yes/$minPeople', style: TextStyle(color: viable ? AppColors.green : AppColors.orange, fontWeight: FontWeight.w900, fontSize: 12))),
                        const SizedBox(height: 6),
                        Text('$maybe duda', style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                  )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventMiniCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventMiniCard({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    return AppCard(child: Row(children: [
      DateBadge(date: d),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppData.text(event['title'], 'Evento'), style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(dateLabel(d), style: const TextStyle(color: AppColors.muted)),
      ])),
    ]));
  }
}

class ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final List<Map<String, dynamic>> members;
  final VoidCallback? onTap;
  const ExpenseCard({super.key, required this.expense, required this.members, this.onTap});

  @override
  Widget build(BuildContext context) {
    final paidBy = expense['paid_by']?.toString() ?? '';
    final amount = AppData.doubleValue(expense['amount']);
    final unpaid = unpaidAmount(expense);
    final settled = unpaid <= 0.01 || AppData.text(expense['status']) == 'paid';
    final participants = expenseParticipants(expense).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        onTap: onTap,
        child: Row(children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ProfileAvatar(name: financeMemberName(paidBy, members), avatarUrl: financeMemberAvatarUrl(paidBy, members), radius: 21),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(color: settled ? AppColors.green : AppColors.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: Icon(settled ? Icons.check_rounded : Icons.receipt_long_rounded, size: 10, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(expense['concept'], 'Gasto'), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('Pagó ${financeMemberName(paidBy, members)} · $participants participantes', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            _MiniChip(text: settled ? 'Liquidado' : 'Pendiente ${money(unpaid)}', color: settled ? AppColors.green : AppColors.orange),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(money(amount), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ]),
        ]),
      ),
    );
  }
}

class TournamentCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback? onTap;
  const TournamentCard({super.key, required this.tournament, this.onTap});

  @override
  Widget build(BuildContext context) {
    final teams = tournament['tournament_teams'] is List ? (tournament['tournament_teams'] as List).length : 0;
    final matches = tournament['matches'] is List ? (tournament['matches'] as List).length : 0;
    final played = tournament['matches'] is List ? (tournament['matches'] as List).where((m) => m is Map && m['status'] == 'played').length : 0;
    final format = AppData.text(tournament['format'], 'liga');
    final status = AppData.text(tournament['status'], 'active');
    final scoringType = AppData.text(tournament['scoring_type'], 'general');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(format == 'eliminatoria' ? Icons.account_tree_rounded : format == 'americano' ? Icons.sync_alt_rounded : Icons.emoji_events_rounded, color: AppColors.teal, size: 34),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(tournament['name'], 'Torneo'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('${tournamentFormatLabel(format)} · ${teamTypeLabel(AppData.text(tournament['team_type'], 'equipo'))} · ${scoringTypeLabel(scoringType)}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 5),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _MiniChip(text: '$teams participantes', color: AppColors.teal),
              _MiniChip(text: '$played/$matches jugados', color: AppColors.violet),
              _MiniChip(text: status == 'finished' ? 'Finalizado' : 'En curso', color: status == 'finished' ? AppColors.muted : AppColors.green),
            ]),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
  );
}

class MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  const MemberCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final profile = AppData.asMap(member['profiles']);
    final role = AppData.text(member['role'], 'member');
    final name = memberName(member);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(children: [
          ProfileAvatar(name: name, avatarUrl: AppData.text(profile['avatar_url']), radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(AppData.text(profile['email'], 'sin email'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: role == 'member' ? AppColors.faint : AppColors.tealSoft, borderRadius: BorderRadius.circular(99)),
            child: Text(
              role == 'owner' ? 'OWNER' : role == 'admin' ? 'ADMIN' : 'MIEMBRO',
              style: TextStyle(color: role == 'member' ? AppColors.muted : AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ]),
      ),
    );
  }
}

String memberName(Map<String, dynamic> member) {
  final profile = AppData.asMap(member['profiles']);
  final fullName = AppData.text(profile['full_name']);
  if (fullName.isNotEmpty && fullName != 'Usuario') return fullName;
  final email = AppData.text(profile['email']);
  if (email.contains('@')) return email.split('@').first;
  return 'Miembro';
}



class InviteAccessCard extends StatelessWidget {
  final String groupName;
  final String code;
  final bool compact;
  final VoidCallback? onRegenerate;
  const InviteAccessCard({super.key, required this.groupName, required this.code, this.compact = false, this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(compact ? 14 : 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lock_person_rounded, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Acceso privado', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('Nadie entra al grupo sin recibir este código.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 14),
        InviteCodeBox(code: code),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Copiar link', icon: Icons.link_rounded, onTap: () => copyInviteLink(context, code))),
          const SizedBox(width: 10),
          Expanded(child: PrimaryButton(label: 'Compartir', icon: Icons.share_rounded, onTap: () => Share.share(inviteText(groupName, code)))),
        ]),
        const SizedBox(height: 10),
        InviteLinkBox(code: code),
        if (onRegenerate != null) ...[
          const SizedBox(height: 10),
          DangerButton(label: 'Regenerar código', icon: Icons.refresh_rounded, onTap: onRegenerate!),
        ],
      ]),
    );
  }
}

class InviteCodeBox extends StatelessWidget {
  final String code;
  const InviteCodeBox({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33008F86)),
      ),
      child: Row(children: [
        const Icon(Icons.qr_code_2_rounded, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(child: Text(code, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.teal))),
        const SizedBox(width: 12),
        const Icon(Icons.ios_share_rounded, color: AppColors.teal),
      ]),
    );
  }
}


class InviteLinkBox extends StatelessWidget {
  final String code;
  const InviteLinkBox({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final link = InviteLinks.joinUrl(code);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        const Icon(Icons.link_rounded, color: AppColors.teal, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12))),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => copyInviteLink(context, code),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text('Copiar', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class RoleInfoCard extends StatelessWidget {
  final String role;
  const RoleInfoCard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner';
    final isAdmin = role == 'admin';
    final color = isOwner ? AppColors.orange : isAdmin ? AppColors.teal : AppColors.violet;
    final title = isOwner ? 'Eres owner del grupo' : isAdmin ? 'Eres admin' : 'Eres miembro';
    final body = isOwner
        ? 'Puedes nombrar admins, quitar admins y gestionar el grupo. Tu rol está protegido.'
        : isAdmin
            ? 'Puedes ayudar a gestionar miembros y mantener el grupo ordenado.'
            : 'Puedes participar en quedadas, gastos y torneos. Los admins gestionan permisos.';
    return AppCard(
      color: AppColors.surface,
      child: Row(children: [
        Container(width: 42, height: 44, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(15)), child: Icon(isOwner ? Icons.workspace_premium_rounded : isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ])),
      ]),
    );
  }
}

class PermissionMatrixCard extends StatelessWidget {
  final bool compact;
  const PermissionMatrixCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_user_rounded, color: AppColors.teal, size: 21)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Permisos claros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text('Cada rol tiene límites para evitar errores humanos.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 12),
        PermissionLine(role: 'Owner', body: 'Control total, admins, miembros y acciones críticas.', color: AppColors.orange),
        PermissionLine(role: 'Admin', body: 'Gestiona miembros y ayuda a mantener el grupo.', color: AppColors.teal),
        PermissionLine(role: 'Miembro', body: 'Participa en eventos, gastos y torneos del grupo.', color: AppColors.violet),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text('El owner queda protegido: no puede ser expulsado ni degradado desde la app.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ]),
    );
  }
}

class PermissionLine extends StatelessWidget {
  final String role;
  final String body;
  final Color color;
  const PermissionLine({super.key, required this.role, required this.body, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
          child: Text(role, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.35))),
      ]),
    );
  }
}


Future<void> showMemberProfileSheet(
  BuildContext context,
  Map<String, dynamic> member,
  bool canEditThis,
  Future<void> Function(Map<String, dynamic> member, String role) onRole,
  Future<void> Function(Map<String, dynamic> member) onRemove,
) async {
  final profile = AppData.asMap(member['profiles']);
  final name = memberName(member);
  final role = AppData.text(member['role'], 'member');
  final email = AppData.text(profile['email'], 'sin email');
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: ProfileAvatar(name: name, avatarUrl: AppData.text(profile['avatar_url']), radius: 42)),
          const SizedBox(height: 12),
          Center(child: Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 4),
          Center(child: Text(email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: 12),
          Center(child: RoleBadge(role: role)),
          const SizedBox(height: 18),
          RoleInfoCard(role: role),
          if (canEditThis) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: SecondaryButton(
                label: role == 'admin' ? 'Quitar admin' : 'Hacer admin',
                icon: role == 'admin' ? Icons.person_outline_rounded : Icons.admin_panel_settings_rounded,
                onTap: () {
                  Navigator.pop(context);
                  onRole(member, role == 'admin' ? 'member' : 'admin');
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: DangerButton(
                label: 'Expulsar',
                icon: Icons.person_remove_rounded,
                onTap: () {
                  Navigator.pop(context);
                  onRemove(member);
                },
              )),
            ]),
          ] else ...[
            const SizedBox(height: 14),
            EmptySlim(
              icon: Icons.lock_outline_rounded,
              title: 'Sin acciones disponibles',
              body: role == 'owner' ? 'El owner está protegido.' : 'Solo owner/admins pueden gestionar otros miembros.',
            ),
          ],
        ]),
      ),
    ),
  );
}


class ManageMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool canManage;
  final Future<void> Function(Map<String, dynamic> member, String role) onRole;
  final Future<void> Function(Map<String, dynamic> member) onRemove;
  const ManageMemberCard({super.key, required this.member, required this.canManage, required this.onRole, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final profile = AppData.asMap(member['profiles']);
    final role = AppData.text(member['role'], 'member');
    final name = memberName(member);
    final isMe = member['user_id']?.toString() == AppData.user?.id;
    final canEditThis = canManage && role != 'owner' && !isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => showMemberProfileSheet(context, member, canEditThis, onRole, onRemove),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(children: [
          ProfileAvatar(name: name, avatarUrl: AppData.text(profile['avatar_url']), radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(isMe ? '$name (Tú)' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))),
              RoleBadge(role: role),
            ]),
            const SizedBox(height: 3),
            Text(AppData.text(profile['email'], 'sin email'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
          if (canEditThis)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
              onSelected: (value) {
                if (value == 'admin') onRole(member, 'admin');
                if (value == 'member') onRole(member, 'member');
                if (value == 'remove') onRemove(member);
              },
              itemBuilder: (context) => [
                if (role != 'admin') const PopupMenuItem(value: 'admin', child: Text('Hacer admin')),
                if (role == 'admin') const PopupMenuItem(value: 'member', child: Text('Quitar admin')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'remove', child: Text('Expulsar del grupo')),
              ],
            ),
        ]),
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final color = role == 'owner' ? AppColors.orange : role == 'admin' ? AppColors.teal : AppColors.muted;
    final text = role == 'owner' ? 'OWNER' : role == 'admin' ? 'ADMIN' : 'MIEMBRO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10.5)),
    );
  }
}

class SettingsRow extends StatelessWidget { final IconData icon; final String title; final String subtitle; final VoidCallback onTap; final bool danger; const SettingsRow({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: AppCard(onTap: onTap, child: Row(children: [Icon(icon, color: danger ? AppColors.red : AppColors.ink), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: danger ? AppColors.red : AppColors.ink)), Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)]))); }

class MetaLine extends StatelessWidget { final IconData icon; final String text; const MetaLine({super.key, required this.icon, required this.text}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(children: [Icon(icon, size: 15, color: AppColors.muted), const SizedBox(width: 5), Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)))])); }

class AttendancePick extends StatelessWidget { final String label; final int count; final bool selected; final Color color; final VoidCallback onTap; const AttendancePick({super.key, required this.label, required this.count, required this.selected, required this.color, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: selected ? color.withOpacity(.10) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: selected ? color : AppColors.line)), child: Column(children: [Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)), Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18))]))); }

class StatusNotice extends StatelessWidget {
  final bool ok;
  final String text;
  final IconData? icon;
  final String? title;
  final String? body;

  const StatusNotice({
    super.key,
    bool? ok,
    String? text,
    this.icon,
    this.title,
    this.body,
  })  : ok = ok ?? true,
        text = text ?? '';

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon ?? (ok ? Icons.check_circle_rounded : Icons.info_rounded);
    final effectiveTitle = title;
    final effectiveBody = body ?? text;
    final accent = ok ? AppColors.green : AppColors.amber;
    final bg = ok ? const Color(0xFFEAF8F0) : const Color(0xFFFFF6DF);
    final border = ok ? const Color(0xFFBFEBD2) : const Color(0xFFFFE3A6);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: effectiveTitle == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(effectiveIcon, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: effectiveTitle == null
                ? Text(
                    effectiveBody,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveTitle,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
                      ),
                      if (effectiveBody.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          effectiveBody,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted, height: 1.25),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class SmallPick extends StatelessWidget { final String label; final String value; final IconData icon; final VoidCallback onTap; const SmallPick({super.key, required this.label, required this.value, required this.icon, required this.onTap}); @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FieldLabel(label), InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(15)), child: Row(children: [Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))), Icon(icon, color: AppColors.muted, size: 20)])))]); }

class StepperRow extends StatelessWidget { final int value; final VoidCallback onMinus; final VoidCallback onPlus; const StepperRow({super.key, required this.value, required this.onMinus, required this.onPlus}); @override Widget build(BuildContext context) => AppCard(child: Row(children: [const Icon(Icons.groups_rounded, color: AppColors.muted), const SizedBox(width: 12), Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_rounded)), IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded))])); }


class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final Map<String, List<Map<String, dynamic>>> eventsByDay;
  final ValueChanged<DateTime> onSelect;
  const MonthGrid({super.key, required this.month, required this.selected, required this.eventsByDay, required this.onSelect});

  List<Map<String, dynamic>> eventsFor(DateTime day) {
    return eventsByDay[calendarDayKey(day)] ?? const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final startOffset = (first.weekday + 6) % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) { cells.add(null); }
    for (int d = 1; d <= days; d++) { cells.add(DateTime(month.year, month.month, d)); }
    while (cells.length % 7 != 0) { cells.add(null); }

    final rows = <List<DateTime?>>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(cells.sublist(i, min(i + 7, cells.length)));
    }

    return Column(children: [
      Row(children: ['L','M','X','J','V','S','D'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.muted, fontSize: 12))))).toList()),
      const SizedBox(height: 8),
      ...rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: row.map((day) {
          if (day == null) return const Expanded(child: SizedBox(height: 42));
          final active = sameDay(day, selected);
          final today = sameDay(day, DateTime.now());
          final dayEvents = eventsFor(day);
          final hasEvents = dayEvents.isNotEmpty;
          final mainColor = hasEvents ? eventKindColor(dayEvents.first) : AppColors.line;
          return Expanded(
            child: SizedBox(
              height: 44,
              child: InkWell(
                onTap: () => onSelect(day),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? AppColors.teal : hasEvents ? eventKindSoftColor(dayEvents.first) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? AppColors.teal : today ? AppColors.teal.withOpacity(.55) : hasEvents ? mainColor.withOpacity(.32) : Colors.transparent,
                      width: active || today || hasEvents ? 1.2 : 1,
                    ),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        day.day.toString(),
                        maxLines: 1,
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.ink,
                          fontWeight: active || hasEvents || today ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 7,
                      child: Center(
                        child: hasEvents
                            ? EventDayMarkers(events: dayEvents, active: active, compact: true)
                            : const SizedBox(height: 5),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          );
        }).toList()),
      )),
    ]);
  }
}


class PatternIcons extends StatelessWidget { const PatternIcons({super.key}); @override Widget build(BuildContext context) => Wrap(spacing: 24, runSpacing: 20, children: List.generate(70, (i) => Icon([Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_rounded][i % 6], size: 17, color: Colors.white))); }

void showPermissionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
      child: Column(mainAxisSize: MainAxisSize.min, children: const [
        PermissionMatrixCard(),
      ]),
    ),
  );
}


Future<bool?> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  bool danger = false,
  String confirmLabel = 'Confirmar',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? AppColors.red : AppColors.teal),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

String humanError(Object? error) {
  return humanizeError(error?.toString() ?? '');
}


void copyInviteCode(BuildContext context, String code) {
  Clipboard.setData(ClipboardData(text: InviteLinks.normalizeCode(code)));
  showToast(context, 'Código copiado.');
}

void copyInviteLink(BuildContext context, String code) {
  Clipboard.setData(ClipboardData(text: InviteLinks.joinUrl(code)));
  showToast(context, 'Link de invitación copiado.');
}

String inviteText(String groupName, String code) {
  final clean = InviteLinks.normalizeCode(code);
  return 'Únete a $groupName en Grupli. Toca este enlace y entrarás directamente al grupo:\n\n${InviteLinks.joinUrl(clean)}\n\nSi tienes la app instalada, se abrirá automáticamente. Código: $clean';
}

void showCodeSheet(BuildContext context, String code, String groupName) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Invitación privada', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Comparte este link solo con quien quieras dentro del grupo.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        InviteCodeBox(code: code),
        const SizedBox(height: 10),
        InviteLinkBox(code: code),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Copiar link', icon: Icons.link_rounded, onTap: () => copyInviteLink(context, code))),
          const SizedBox(width: 10),
          Expanded(child: PrimaryButton(label: 'Compartir', icon: Icons.share_rounded, onTap: () => Share.share(inviteText(groupName, code)))),
        ]),
      ]),
    ),
  );
}
