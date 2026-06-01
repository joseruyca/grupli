import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
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
    return events.where((e) => _day(DateTime.parse(e['starts_at'].toString())).isAtSameMomentAs(_day(day))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Calendario',
          subtitle: 'Quedadas, asistencia y días habituales.',
          showBack: true,
          trailing: IconButton.filled(onPressed: () => showAppBottomSheet(context, CreateEventSheet(groupId: widget.groupId)).then((_) => _refresh()), icon: const Icon(Icons.add_rounded)),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(snapshot.error.toString()));
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
                  onDaySelected: (selectedDay, focusedDay) => setState(() { _selected = selectedDay; _focused = focusedDay; }),
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: AppColors.teal.withOpacity(0.25), shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Eventos del día', style: AppTypography.section),
              const SizedBox(height: AppSpacing.md),
              if (selectedEvents.isEmpty)
                EmptyState(icon: Icons.event_busy_rounded, title: 'No hay quedadas', body: 'Crea una quedada para este día.')
              else
                ...selectedEvents.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: EventCard(event: e, onChanged: _refresh),
                )),
            ]);
          },
        ),
      ]),
    );
  }
}

class EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onChanged;
  const EventCard({super.key, required this.event, required this.onChanged});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _loading = false;

  Future<void> _attend(String status) async {
    setState(() => _loading = true);
    try {
      await CalendarRepository().setAttendance(widget.event['id'].toString(), status);
      if (mounted) AppToast.show(context, 'Asistencia actualizada: $status');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final starts = DateTime.parse(widget.event['starts_at'].toString()).toLocal();
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.event['title'] ?? 'Quedada', style: AppTypography.section)),
          StatusChip(label: Fmt.hour.format(starts)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text('${Fmt.date.format(starts)} · ${widget.event['location'] ?? 'Sin lugar'}', style: AppTypography.muted),
        if ((widget.event['notes'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(widget.event['notes'].toString(), style: AppTypography.body),
        ],
        const SizedBox(height: AppSpacing.md),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Row(children: [
          Expanded(child: TextButton(onPressed: _loading ? null : () => _attend('yes'), child: const Text('Voy'))),
          Expanded(child: TextButton(onPressed: _loading ? null : () => _attend('maybe'), child: const Text('Duda'))),
          Expanded(child: TextButton(onPressed: _loading ? null : () => _attend('no'), child: const Text('No voy'))),
        ]),
      ]),
    );
  }
}

class CreateEventSheet extends StatefulWidget {
  final String groupId;
  const CreateEventSheet({super.key, required this.groupId});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _title = TextEditingController();
  final _date = TextEditingController(text: Fmt.date.format(DateTime.now()));
  final _time = TextEditingController(text: '20:00');
  final _location = TextEditingController();
  final _notes = TextEditingController();
  final _min = TextEditingController(text: '2');
  bool _loading = false;

  Future<void> _create() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final parts = _time.text.split(':');
      final starts = DateTime(now.year, now.month, now.day, int.tryParse(parts.first) ?? 20, parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
      await CalendarRepository().createEvent(
        groupId: widget.groupId,
        title: _title.text,
        startsAt: starts,
        location: _location.text,
        notes: _notes.text,
        minPeople: int.tryParse(_min.text) ?? 2,
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
      Text('Crear quedada', style: AppTypography.section),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(controller: _title, label: 'Título'),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _time, label: 'Hora'),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _location, label: 'Lugar / pista / mesa'),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _notes, label: 'Notas', maxLines: 2),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _min, label: 'Mínimo personas', keyboardType: TextInputType.number),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Crear quedada', loading: _loading, onPressed: _create),
    ]);
  }
}
