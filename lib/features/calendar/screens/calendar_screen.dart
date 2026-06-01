import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/avatar.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/status_chip.dart';
import '../../../ui/toast.dart';
import '../../../shared/utils/formatters.dart';
import '../calendar_repository.dart';

class CalendarScreen extends StatefulWidget {
  final String groupId;
  const CalendarScreen({super.key, required this.groupId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = CalendarRepository().events(widget.groupId);
  }

  void _refresh() => setState(() => _future = CalendarRepository().events(widget.groupId));

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Map<String, dynamic>> _eventsFor(List<Map<String, dynamic>> events, DateTime day) {
    return events.where((e) {
      final raw = e['starts_at'];
      if (raw == null) return false;
      return _day(DateTime.parse(raw.toString())).isAtSameMomentAs(_day(day));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Calendario',
          subtitle: 'Quedadas y asistencia del grupo.',
          showBack: true,
          trailing: IconButton.filled(
            onPressed: () => showAppBottomSheet(context, CreateEventSheet(groupId: widget.groupId)).then((_) => _refresh()),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));
            final events = snapshot.data ?? [];
            final selectedEvents = _eventsFor(events, _selected);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TableCalendar<Map<String, dynamic>>(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focused,
                  selectedDayPredicate: (day) => isSameDay(day, _selected),
                  eventLoader: (day) => _eventsFor(events, day),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.navy),
                    rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.navy),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    markersMaxCount: 2,
                    todayDecoration: BoxDecoration(color: AppColors.teal.withOpacity(0.18), shape: BoxShape.circle),
                    selectedDecoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                  ),
                  onDaySelected: (selected, focused) => setState(() {
                    _selected = selected;
                    _focused = focused;
                  }),
                  onPageChanged: (focused) => _focused = focused,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(title: Fmt.date.format(_selected), actionLabel: 'Crear quedada', onAction: () => showAppBottomSheet(context, CreateEventSheet(groupId: widget.groupId, initialDate: _selected)).then((_) => _refresh())),
              const SizedBox(height: AppSpacing.sm),
              if (selectedEvents.isEmpty)
                EmptyState(icon: Icons.event_available_rounded, title: 'No hay quedadas este día', body: 'Crea una quedada o elige otro día del calendario.')
              else
                ...selectedEvents.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _EventCard(
                    event: event,
                    onTap: () => showAppBottomSheet(context, EventDetailSheet(event: event)).then((_) => _refresh()),
                  ),
                )),
            ]);
          },
        ),
      ]),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final starts = DateTime.parse(event['starts_at'].toString());
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          const SoftIconBox(icon: Icons.event_rounded, color: AppColors.teal),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event['title']?.toString() ?? 'Quedada', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Wrap(spacing: 8, runSpacing: 8, children: [
                MetaPill(icon: Icons.access_time_rounded, text: Fmt.hour.format(starts)),
                if ((event['location'] ?? '').toString().isNotEmpty)
                  MetaPill(icon: Icons.location_on_outlined, text: event['location'].toString()),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class EventDetailSheet extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailSheet({super.key, required this.event});

  @override
  State<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<EventDetailSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = CalendarRepository().attendance(widget.event['id'].toString());
  }

  void _refresh() => setState(() => _future = CalendarRepository().attendance(widget.event['id'].toString()));

  int _count(List<Map<String, dynamic>> rows, String status) => rows.where((r) => r['status'] == status).length;

  Future<void> _set(String status) async {
    try {
      await CalendarRepository().setAttendance(widget.event['id'].toString(), status);
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final starts = DateTime.parse(widget.event['starts_at'].toString());
    final minPeople = ((widget.event['min_people'] ?? 2) as num).toInt();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];
        final yes = _count(rows, 'yes');
        final maybe = _count(rows, 'maybe');
        final no = _count(rows, 'no');
        final pending = _count(rows, 'pending');
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const SoftIconBox(icon: Icons.event_rounded, color: AppColors.teal),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(widget.event['title']?.toString() ?? 'Quedada', style: AppTypography.section.copyWith(fontSize: 22))),
          ]),
          const SizedBox(height: AppSpacing.lg),
          DataLine(label: 'Fecha', value: Fmt.date.format(starts)),
          DataLine(label: 'Hora', value: Fmt.hour.format(starts)),
          if ((widget.event['location'] ?? '').toString().isNotEmpty)
            DataLine(label: 'Lugar', value: widget.event['location'].toString()),
          if ((widget.event['notes'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(widget.event['notes'].toString(), style: AppTypography.body),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('Asistencia', style: AppTypography.section.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: _AttendanceBox(label: 'Voy', value: yes, color: AppColors.success, onTap: () => _set('yes'))),
            const SizedBox(width: 8),
            Expanded(child: _AttendanceBox(label: 'Duda', value: maybe, color: AppColors.warning, onTap: () => _set('maybe'))),
            const SizedBox(width: 8),
            Expanded(child: _AttendanceBox(label: 'No voy', value: no, color: AppColors.danger, onTap: () => _set('no'))),
            const SizedBox(width: 8),
            Expanded(child: _AttendanceBox(label: 'Pend.', value: pending, color: AppColors.textMuted, onTap: () => _set('pending'))),
          ]),
          if (yes < minPeople) ...[
            const SizedBox(height: AppSpacing.md),
            InfoPanel(
              icon: Icons.warning_amber_rounded,
              title: 'Aún no se alcanza el mínimo',
              body: 'Faltan ${minPeople - yes} persona(s) para llegar al mínimo de $minPeople.',
              color: AppColors.warning,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Asistentes (${rows.length})', style: AppTypography.section.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          if (snapshot.connectionState == ConnectionState.waiting)
            const LoadingState()
          else if (rows.isEmpty)
            Text('Todavía nadie ha respondido.', style: AppTypography.muted)
          else
            ...rows.map((r) {
              final profile = Map<String, dynamic>.from((r['profiles'] ?? {}) as Map);
              final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
              final status = r['status']?.toString() ?? 'pending';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    MemberAvatar(url: profile['avatar_url'] as String?, fallback: name, size: 36),
                    const SizedBox(width: 10),
                    Expanded(child: Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700))),
                    StatusChip(label: _statusLabel(status), color: _statusColor(status)),
                  ]),
                ),
              );
            }),
        ]);
      },
    );
  }

  String _statusLabel(String status) => switch (status) {
    'yes' => 'Voy',
    'maybe' => 'Duda',
    'no' => 'No voy',
    _ => 'Pendiente',
  };

  Color _statusColor(String status) => switch (status) {
    'yes' => AppColors.success,
    'maybe' => AppColors.warning,
    'no' => AppColors.danger,
    _ => AppColors.textMuted,
  };
}

class _AttendanceBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final VoidCallback onTap;

  const _AttendanceBox({required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.16))),
        child: Column(children: [
          Text('$value', style: AppTypography.section.copyWith(color: color, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.small.copyWith(color: color)),
        ]),
      ),
    );
  }
}

class CreateEventSheet extends StatefulWidget {
  final String groupId;
  final DateTime? initialDate;
  const CreateEventSheet({super.key, required this.groupId, this.initialDate});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  final _min = TextEditingController(text: '2');
  final _date = TextEditingController();
  final _time = TextEditingController(text: '20:00');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _date.text = '${initial.year}-${initial.month.toString().padLeft(2, '0')}-${initial.day.toString().padLeft(2, '0')}';
  }

  Future<void> _create() async {
    if (_saving || _title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final dateParts = _date.text.split('-').map(int.parse).toList();
      final timeParts = _time.text.split(':').map(int.parse).toList();
      final starts = DateTime(dateParts[0], dateParts[1], dateParts[2], timeParts[0], timeParts.length > 1 ? timeParts[1] : 0);
      await CalendarRepository().createEvent(
        groupId: widget.groupId,
        title: _title.text,
        startsAt: starts,
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        minPeople: int.tryParse(_min.text) ?? 2,
      );
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
      Text('Crear quedada', style: AppTypography.section),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(controller: _title, label: 'Título', hint: 'Cena, partido, partida...'),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: AppTextField(controller: _date, label: 'Fecha', hint: '2026-06-01')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: AppTextField(controller: _time, label: 'Hora', hint: '20:00')),
      ]),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _location, label: 'Lugar', hint: 'Casa, pista, bar...'),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _min, label: 'Mínimo de personas', keyboardType: TextInputType.number),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _notes, label: 'Notas', maxLines: 2),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Guardar quedada', loading: _saving, onPressed: _create),
    ]);
  }
}
