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
import '../../../ui/confirm_dialog.dart';
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
    return events.where((event) {
      final raw = event['starts_at'];
      if (raw == null) return false;
      return _day(DateTime.parse(raw.toString())).isAtSameMomentAs(_day(day));
    }).toList();
  }

  Future<void> _createEvent([DateTime? initialDate]) async {
    await showAppBottomSheet(context, CreateEventSheet(groupId: widget.groupId, initialDate: initialDate ?? _selected));
    _refresh();
  }

  Future<void> _openEvent(Map<String, dynamic> event) async {
    await showAppBottomSheet(context, EventDetailSheet(eventId: event['id'].toString()));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Calendario',
          subtitle: 'Quedadas y asistencia del grupo.',
          showBack: true,
          trailing: IconButton.filled(onPressed: () => _createEvent(), icon: const Icon(Icons.add_rounded)),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));
            final events = snapshot.data ?? [];
            final selectedEvents = _eventsFor(events, _selected);
            final upcoming = events.where((e) {
              final status = (e['status'] ?? 'active').toString();
              final raw = e['starts_at'];
              if (raw == null || status == 'cancelled') return false;
              return DateTime.parse(raw.toString()).isAfter(DateTime.now().subtract(const Duration(hours: 2)));
            }).length;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _MiniMetric(label: 'Este mes', value: '${events.length}', icon: Icons.event_available_rounded)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MiniMetric(label: 'Próximas', value: '$upcoming', icon: Icons.upcoming_rounded, color: AppColors.success)),
              ]),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TableCalendar<Map<String, dynamic>>(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focused,
                  selectedDayPredicate: (day) => isSameDay(day, _selected),
                  eventLoader: (day) => _eventsFor(events, day),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.navy),
                    rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.navy),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 11),
                    weekendStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    markerSize: 5,
                    markersMaxCount: 3,
                    todayDecoration: BoxDecoration(color: AppColors.teal.withOpacity(0.16), shape: BoxShape.circle),
                    todayTextStyle: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w900),
                    selectedDecoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    markerDecoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                    defaultTextStyle: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
                    weekendTextStyle: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
                  ),
                  onDaySelected: (selected, focused) => setState(() {
                    _selected = selected;
                    _focused = focused;
                  }),
                  onPageChanged: (focused) => _focused = focused,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(title: Fmt.day.format(_selected), actionLabel: 'Crear quedada', onAction: () => _createEvent(_selected)),
              const SizedBox(height: AppSpacing.sm),
              if (selectedEvents.isEmpty)
                EmptyState(icon: Icons.event_available_rounded, title: 'No hay quedadas este día', body: 'Crea una quedada o toca otro día del calendario.')
              else
                ...selectedEvents.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _EventCard(event: event, onTap: () => _openEvent(event)),
                )),
            ]);
          },
        ),
      ]),
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

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final starts = DateTime.parse(event['starts_at'].toString());
    final status = (event['status'] ?? 'active').toString();
    final cancelled = status == 'cancelled';
    return AppCard(
      onTap: onTap,
      color: cancelled ? AppColors.canvasWarm : AppColors.white,
      child: Row(children: [
        SoftIconBox(icon: cancelled ? Icons.event_busy_rounded : Icons.event_rounded, color: cancelled ? AppColors.textMuted : AppColors.teal),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(event['title']?.toString() ?? 'Quedada', style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: cancelled ? AppColors.textMuted : AppColors.navy))),
            if (cancelled) const StatusChip(label: 'Cancelada', color: AppColors.textMuted),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            MetaPill(icon: Icons.access_time_rounded, text: Fmt.hour.format(starts)),
            if ((event['location'] ?? '').toString().isNotEmpty) MetaPill(icon: Icons.location_on_outlined, text: event['location'].toString()),
            MetaPill(icon: Icons.people_outline_rounded, text: 'Mín. ${event['min_people'] ?? 2}'),
          ]),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ]),
    );
  }
}

class EventDetailSheet extends StatefulWidget {
  final String eventId;
  const EventDetailSheet({super.key, required this.eventId});

  @override
  State<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<EventDetailSheet> {
  late Future<_EventDetailData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_EventDetailData> _load() async {
    final repo = CalendarRepository();
    final event = await repo.event(widget.eventId);
    final attendance = await repo.attendance(widget.eventId);
    return _EventDetailData(event: event, attendance: attendance);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _set(String status) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await CalendarRepository().setAttendance(widget.eventId, status);
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> event) async {
    await showAppBottomSheet(context, EditEventSheet(event: event));
    _refresh();
  }

  Future<void> _toggleCancel(Map<String, dynamic> event) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = (event['status'] ?? 'active').toString();
      if (status == 'cancelled') {
        await CalendarRepository().reactivateEvent(widget.eventId);
      } else {
        await CalendarRepository().cancelEvent(widget.eventId);
      }
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(context, title: 'Eliminar quedada', message: 'Esta acción borrará la quedada y sus respuestas.', confirmLabel: 'Eliminar');
    if (!ok) return;
    try {
      await CalendarRepository().deleteEvent(widget.eventId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  int _count(List<Map<String, dynamic>> rows, String status) => rows.where((r) => r['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EventDetailData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
        if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));
        final data = snapshot.data!;
        final event = data.event;
        final rows = data.attendance;
        final starts = DateTime.parse(event['starts_at'].toString());
        final minPeople = ((event['min_people'] ?? 2) as num).toInt();
        final yes = _count(rows, 'yes');
        final maybe = _count(rows, 'maybe');
        final no = _count(rows, 'no');
        final pending = _count(rows, 'pending');
        final cancelled = (event['status'] ?? 'active') == 'cancelled';
        final myRows = rows.where((r) => r['is_me'] == true).toList();
        final myStatus = myRows.isEmpty ? 'pending' : myRows.first['status'].toString();

        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SoftIconBox(icon: cancelled ? Icons.event_busy_rounded : Icons.event_rounded, color: cancelled ? AppColors.textMuted : AppColors.teal),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event['title']?.toString() ?? 'Quedada', style: AppTypography.section.copyWith(fontSize: 22)),
              const SizedBox(height: 6),
              if (cancelled) const StatusChip(label: 'Cancelada', color: AppColors.textMuted),
            ])),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _edit(event);
                if (value == 'cancel') _toggleCancel(event);
                if (value == 'delete') _delete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'cancel', child: Text(cancelled ? 'Reactivar' : 'Cancelar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              DataLine(label: 'Fecha', value: Fmt.date.format(starts)),
              DataLine(label: 'Hora', value: Fmt.hour.format(starts)),
              if ((event['location'] ?? '').toString().isNotEmpty) DataLine(label: 'Lugar', value: event['location'].toString()),
              DataLine(label: 'Mínimo de personas', value: '$minPeople'),
              if ((event['notes'] ?? '').toString().isNotEmpty) ...[
                const Divider(),
                Align(alignment: Alignment.centerLeft, child: Text(event['notes'].toString(), style: AppTypography.body)),
              ],
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Tu respuesta', style: AppTypography.section.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: _ResponseButton(label: 'Voy', active: myStatus == 'yes', color: AppColors.success, onTap: cancelled ? null : () => _set('yes'))),
            const SizedBox(width: 8),
            Expanded(child: _ResponseButton(label: 'Duda', active: myStatus == 'maybe', color: AppColors.warning, onTap: cancelled ? null : () => _set('maybe'))),
            const SizedBox(width: 8),
            Expanded(child: _ResponseButton(label: 'No voy', active: myStatus == 'no', color: AppColors.danger, onTap: cancelled ? null : () => _set('no'))),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Text('Asistencia', style: AppTypography.section.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: _AttendanceBox(label: 'Voy', value: yes, color: AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _AttendanceBox(label: 'Duda', value: maybe, color: AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(child: _AttendanceBox(label: 'No', value: no, color: AppColors.danger)),
            const SizedBox(width: 8),
            Expanded(child: _AttendanceBox(label: 'Pend.', value: pending, color: AppColors.textMuted)),
          ]),
          if (!cancelled && yes < minPeople) ...[
            const SizedBox(height: AppSpacing.md),
            InfoPanel(icon: Icons.warning_amber_rounded, title: 'Aún no se alcanza el mínimo', body: 'Faltan ${minPeople - yes} persona(s) para llegar al mínimo de $minPeople.', color: AppColors.warning),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Miembros (${rows.length})', style: AppTypography.section.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            Text('Todavía no hay miembros en el grupo.', style: AppTypography.muted)
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
                    Expanded(child: Text(r['is_me'] == true ? 'Tú' : name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700))),
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

class _EventDetailData {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> attendance;
  const _EventDetailData({required this.event, required this.attendance});
}

class _ResponseButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback? onTap;
  const _ResponseButton({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 12.5)),
      ),
    );
  }
}

class _AttendanceBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AttendanceBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.16))),
      child: Column(children: [
        Text('$value', style: AppTypography.section.copyWith(color: color, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.small.copyWith(color: color)),
      ]),
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
  int _minPeople = 2;
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  Future<void> _create() async {
    if (_saving || _title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final starts = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      await CalendarRepository().createEvent(
        groupId: widget.groupId,
        title: _title.text,
        startsAt: starts,
        location: _location.text,
        notes: _notes.text,
        minPeople: _minPeople,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return _EventFormScaffold(
      title: 'Crear quedada',
      nameController: _title,
      locationController: _location,
      notesController: _notes,
      date: _date,
      time: _time,
      minPeople: _minPeople,
      loading: _saving,
      submitLabel: 'Guardar quedada',
      onPickDate: _pickDate,
      onPickTime: _pickTime,
      onMinPeopleChanged: (v) => setState(() => _minPeople = v),
      onSubmit: _create,
    );
  }
}

class EditEventSheet extends StatefulWidget {
  final Map<String, dynamic> event;
  const EditEventSheet({super.key, required this.event});

  @override
  State<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<EditEventSheet> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late DateTime _date;
  late TimeOfDay _time;
  late int _minPeople;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final starts = DateTime.parse(widget.event['starts_at'].toString());
    _title = TextEditingController(text: widget.event['title']?.toString() ?? '');
    _location = TextEditingController(text: widget.event['location']?.toString() ?? '');
    _notes = TextEditingController(text: widget.event['notes']?.toString() ?? '');
    _date = DateTime(starts.year, starts.month, starts.day);
    _time = TimeOfDay(hour: starts.hour, minute: starts.minute);
    _minPeople = ((widget.event['min_people'] ?? 2) as num).toInt();
  }

  Future<void> _save() async {
    if (_saving || _title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final starts = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      await CalendarRepository().updateEvent(
        eventId: widget.event['id'].toString(),
        title: _title.text,
        startsAt: starts,
        location: _location.text,
        notes: _notes.text,
        minPeople: _minPeople,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return _EventFormScaffold(
      title: 'Editar quedada',
      nameController: _title,
      locationController: _location,
      notesController: _notes,
      date: _date,
      time: _time,
      minPeople: _minPeople,
      loading: _saving,
      submitLabel: 'Guardar cambios',
      onPickDate: _pickDate,
      onPickTime: _pickTime,
      onMinPeopleChanged: (v) => setState(() => _minPeople = v),
      onSubmit: _save,
    );
  }
}

class _EventFormScaffold extends StatelessWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController locationController;
  final TextEditingController notesController;
  final DateTime date;
  final TimeOfDay time;
  final int minPeople;
  final bool loading;
  final String submitLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<int> onMinPeopleChanged;
  final VoidCallback onSubmit;

  const _EventFormScaffold({
    required this.title,
    required this.nameController,
    required this.locationController,
    required this.notesController,
    required this.date,
    required this.time,
    required this.minPeople,
    required this.loading,
    required this.submitLabel,
    required this.onPickDate,
    required this.onPickTime,
    required this.onMinPeopleChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTypography.section),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(controller: nameController, label: 'Título', hint: 'Cena, partido, partida...'),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: _PickerCard(label: 'Fecha', value: Fmt.date.format(date), icon: Icons.calendar_month_rounded, onTap: onPickDate)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _PickerCard(label: 'Hora', value: time.format(context), icon: Icons.access_time_rounded, onTap: onPickTime)),
      ]),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: locationController, label: 'Lugar', hint: 'Casa, pista, bar...', prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted)),
      const SizedBox(height: AppSpacing.md),
      Text('Mínimo de personas', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
      const SizedBox(height: AppSpacing.sm),
      Container(
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          const Icon(Icons.people_outline_rounded, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text('$minPeople', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(onPressed: minPeople > 1 ? () => onMinPeopleChanged(minPeople - 1) : null, icon: const Icon(Icons.remove_rounded)),
          IconButton(onPressed: () => onMinPeopleChanged(minPeople + 1), icon: const Icon(Icons.add_rounded)),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: notesController, label: 'Notas', hint: 'Traed algo para compartir...', maxLines: 2),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: submitLabel, loading: loading, onPressed: onSubmit),
    ]);
  }
}

class _PickerCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _PickerCard({required this.label, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTypography.small),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}
