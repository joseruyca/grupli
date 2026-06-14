part of grupli_app;

class EventsTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const EventsTab({super.key, required this.group, required this.refreshSeed});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant EventsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) load();
  }

  void load() => future = AppData.events(widget.group['id'].toString());
  void reload() => setState(load);

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return SafeArea(
      bottom: false,
      child: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            PageHeader(title: 'Eventos', subtitle: AppData.text(group['name']), leading: true),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando eventos...');
                if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: reload);
                final events = snapshot.data ?? [];
                final upcoming = events.where((e) => DateTime.tryParse(e['starts_at']?.toString() ?? '')?.isAfter(DateTime.now().subtract(const Duration(hours: 2))) ?? false).toList();
                final past = events.length - upcoming.length;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: StatCard(icon: Icons.calendar_month_rounded, value: upcoming.length.toString(), label: 'Próximos', color: AppColors.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(icon: Icons.groups_rounded, value: _attendanceTotal(events, 'yes').toString(), label: 'Confirmados', color: AppColors.green)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(icon: Icons.history_rounded, value: past.toString(), label: 'Pasados', color: AppColors.violet)),
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [Text('Próximos', style: Theme.of(context).textTheme.titleLarge), const Spacer(), TextButton(onPressed: reload, child: const Text('Actualizar'))]),
                  const SizedBox(height: 8),
                  if (upcoming.isEmpty) EmptyBlock(icon: Icons.event_available_rounded, title: 'No hay próximos eventos', body: 'Crea una quedada para que los miembros confirmen asistencia.') else ...upcoming.map((e) => EventCard(event: e, onTap: () async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: e, group: group))); reload(); })),
                ]);
              },
            ),
          ],
        ),
        Positioned(right: 20, bottom: 20, child: FloatingActionButton(backgroundColor: AppColors.teal, foregroundColor: Colors.white, onPressed: () async { final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: group))); if (ok == true) reload(); }, child: const Icon(Icons.add_rounded))),
      ]),
    );
  }

  int _attendanceTotal(List<Map<String, dynamic>> events, String status) {
    var total = 0;
    for (final e in events) {
      final att = e['event_attendance'];
      if (att is List) total += att.where((x) => (x as Map)['status'] == status).length;
    }
    return total;
  }
}




class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Busca una calle, local, pabellón, bar...',
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  Timer? _debounce;
  bool loading = false;
  String error = '';
  List<PlaceSuggestion> suggestions = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged?.call(value);
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        suggestions = const [];
        loading = false;
        error = '';
      });
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    _debounce = Timer(const Duration(milliseconds: 420), () async {
      try {
        final result = await AddressSearchService.autocomplete(query);
        if (!mounted) return;
        if (widget.controller.text.trim() != query) return;
        setState(() {
          suggestions = result.take(6).toList();
          loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          suggestions = const [];
          loading = false;
          error = 'No se pudo buscar. Puedes escribir la dirección manualmente.';
        });
      }
    });
  }

  void _select(PlaceSuggestion suggestion) {
    widget.controller.text = suggestion.description;
    widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
    widget.onChanged?.call(suggestion.description);
    setState(() {
      suggestions = const [];
      loading = false;
      error = '';
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: widget.controller,
        onChanged: _onTextChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.place_outlined),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : widget.controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar dirección',
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged?.call('');
                        setState(() {
                          suggestions = const [];
                          error = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
          hintText: widget.hintText,
          helperText: 'Autocompleta con OpenStreetMap. También puedes escribirlo a mano o pegar un enlace de Maps.',
          helperMaxLines: 2,
        ),
      ),
      if (suggestions.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: const [BoxShadow(color: Color(0x0F102033), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Column(children: [
            for (int i = 0; i < suggestions.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: i == suggestions.length - 1 ? const Radius.circular(18) : Radius.zero,
                ),
                onTap: () => _select(suggestions[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.location_on_rounded, color: AppColors.teal, size: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(suggestions[i].description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(suggestions[i].source, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                    ])),
                  ]),
                ),
              ),
              if (i != suggestions.length - 1) const Divider(height: 1, indent: 56, color: AppColors.line),
            ],
          ]),
        ),
      ],
      if (error.isNotEmpty) ...[
        const SizedBox(height: 7),
        Text(error, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    ]);
  }
}

class EventLocationMapCard extends StatelessWidget {
  final String address;
  const EventLocationMapCard({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    final clean = address.trim();
    if (clean.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.map_rounded, color: AppColors.teal)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dirección', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(clean, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
        ])),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: () { openAddressInGoogleMaps(context, clean); },
          icon: const Icon(Icons.navigation_rounded, size: 17),
          label: const Text('Maps', style: TextStyle(fontWeight: FontWeight.w900)),
          style: TextButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ]),
    );
  }
}

class CreateEventScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final DateTime? initialDate;
  final Map<String, dynamic>? event;
  const CreateEventScreen({super.key, required this.group, this.initialDate, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final title = TextEditingController();
  final location = TextEditingController();
  final notes = TextEditingController();
  late DateTime date;
  TimeOfDay time = const TimeOfDay(hour: 20, minute: 0);
  int minPeople = 2;
  bool loading = false;
  String template = 'Quedada';
  bool repeatEnabled = false;
  String repeatFrequency = 'weekly';
  int repeatOccurrences = 8;
  String editScope = 'single';

  bool get editing => widget.event != null;
  bool get editingRoutine => editing && eventIsRoutine(widget.event!);

  String get frequencyLabel {
    switch (repeatFrequency) {
      case 'biweekly':
        return 'cada 2 semanas';
      case 'monthly':
        return 'cada mes';
      default:
        return 'cada semana';
    }
  }

  String get routinePreview {
    if (!repeatEnabled) return 'Evento único';
    final first = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return '${_cap(frequencyLabel)} · $repeatOccurrences eventos · empieza ${longDateTime(first)}';
  }

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final eventDate = DateTime.tryParse(event?['starts_at']?.toString() ?? '')?.toLocal();
    date = widget.initialDate ?? eventDate ?? DateTime.now().add(const Duration(days: 1));
    if (eventDate != null) time = TimeOfDay.fromDateTime(eventDate);
    title.text = AppData.text(event?['title']);
    location.text = AppData.text(event?['location']);
    notes.text = AppData.text(event?['notes']);
    minPeople = AppData.intValue(event?['min_people'], 2);
    if (title.text.toLowerCase().contains('partido')) template = 'Partido';
    if (title.text.toLowerCase().contains('entrenamiento')) template = 'Entrenamiento';
    if (title.text.toLowerCase().contains('cena')) template = 'Cena';
    if (title.text.toLowerCase().contains('reunión') || title.text.toLowerCase().contains('reunion')) template = 'Reunión';
  }

  @override
  void dispose() {
    title.dispose();
    location.dispose();
    notes.dispose();
    super.dispose();
  }

  void applyTemplate(String value) {
    setState(() {
      template = value;
      if (title.text.trim().isEmpty || ['Quedada', 'Partido', 'Entrenamiento', 'Cena del grupo', 'Reunión'].contains(title.text.trim())) {
        title.text = value == 'Cena' ? 'Cena del grupo' : value;
      }
      if (value == 'Partido' && minPeople < 4) minPeople = 4;
      if (value == 'Entrenamiento' && minPeople < 2) minPeople = 2;
      if (value == 'Cena' && minPeople < 2) minPeople = 2;
      if (value == 'Reunión' && minPeople < 2) minPeople = 2;
    });
  }

  Future<void> save() async {
    final cleanTitle = title.text.trim();
    if (cleanTitle.length < 2) {
      await showToast(context, 'Pon un título claro para el evento.', danger: true);
      return;
    }
    if (!editing && repeatEnabled && repeatOccurrences < 2) {
      await showToast(context, 'Una rutina necesita al menos 2 eventos.', danger: true);
      return;
    }

    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => loading = true);
    try {
      if (editing) {
        await AppData.updateEventWithScope(widget.event!['id'].toString(), editScope, cleanTitle, start, location.text, notes.text, minPeople);
      } else if (repeatEnabled) {
        final created = await AppData.createEventSeries(
          widget.group['id'].toString(),
          cleanTitle,
          start,
          location.text,
          notes.text,
          minPeople,
          repeatFrequency,
          repeatOccurrences,
        );
        if (mounted) await showToast(context, 'Rutina creada: $created eventos generados.');
      } else {
        await AppData.createEvent(widget.group['id'].toString(), cleanTitle, start, location.text, notes.text, minPeople);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = AppData.text(widget.group['name'], 'Grupo');
    final previewDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: editing ? 'Editar evento' : 'Nuevo evento', subtitle: groupName, leading: true),
      const SizedBox(height: 14),
      EventFormPreviewCard(
        title: title.text.trim().isEmpty ? (editing ? 'Evento del grupo' : 'Nueva quedada') : title.text.trim(),
        date: previewDate,
        location: location.text.trim(),
        minPeople: minPeople,
        template: template,
        repeatLabel: repeatEnabled ? routinePreview : (editingRoutine ? eventRoutineBadge(widget.event!) : null),
      ),
      if (editingRoutine) ...[
        const SizedBox(height: 14),
        EventScopeCard(
          title: 'Editar rutina',
          value: editScope,
          onChanged: (value) => setState(() => editScope = value),
        ),
      ],
      const SizedBox(height: 16),
      SectionHeader(title: 'Tipo de plan'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        EventTemplateChoice(label: 'Quedada', icon: Icons.groups_rounded, selected: template == 'Quedada', onTap: () => applyTemplate('Quedada')),
        EventTemplateChoice(label: 'Partido', icon: Icons.sports_soccer_rounded, selected: template == 'Partido', onTap: () => applyTemplate('Partido')),
        EventTemplateChoice(label: 'Entrenamiento', icon: Icons.fitness_center_rounded, selected: template == 'Entrenamiento', onTap: () => applyTemplate('Entrenamiento')),
        EventTemplateChoice(label: 'Cena', icon: Icons.restaurant_rounded, selected: template == 'Cena', onTap: () => applyTemplate('Cena')),
        EventTemplateChoice(label: 'Reunión', icon: Icons.forum_rounded, selected: template == 'Reunión', onTap: () => applyTemplate('Reunión')),
      ]),
      const SizedBox(height: 16),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel('Título'),
        TextField(controller: title, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Ej. Partido semanal')),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: SmallPick(label: 'Fecha', value: DateFormat('dd/MM/yyyy', 'es_ES').format(date), icon: Icons.calendar_month_rounded, onTap: () async {
            final d = await showDatePicker(
              context: context,
              locale: const Locale('es'),
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (d != null) setState(() => date = d);
          })),
          const SizedBox(width: 10),
          Expanded(child: SmallPick(label: 'Hora', value: time.format(context), icon: Icons.schedule_rounded, onTap: () async {
            final t = await showTimePicker(context: context, initialTime: time);
            if (t != null) setState(() => time = t);
          })),
        ]),
        const SizedBox(height: 14),
        FieldLabel('Dirección o lugar'),
        AddressAutocompleteField(
          controller: location,
          onChanged: (_) => setState(() {}),
          hintText: 'Busca una calle, local, pabellón, bar...',
        ),
      ])),
      if (!editing) ...[
        const SizedBox(height: 14),
        AppCard(
          color: repeatEnabled ? AppColors.tealSoft : AppColors.white,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: repeatEnabled ? AppColors.teal : AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)),
                child: Icon(Icons.repeat_rounded, color: repeatEnabled ? Colors.white : AppColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Convertir en rutina', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text('Ideal para partido todos los jueves, entreno semanal o quedadas fijas.', style: Theme.of(context).textTheme.bodyMedium),
              ])),
              Switch.adaptive(value: repeatEnabled, activeColor: AppColors.teal, onChanged: (v) => setState(() => repeatEnabled = v)),
            ]),
            if (repeatEnabled) ...[
              const SizedBox(height: 14),
              FieldLabel('Frecuencia'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                RoutineChoice(label: 'Cada semana', selected: repeatFrequency == 'weekly', onTap: () => setState(() => repeatFrequency = 'weekly')),
                RoutineChoice(label: 'Cada 2 semanas', selected: repeatFrequency == 'biweekly', onTap: () => setState(() => repeatFrequency = 'biweekly')),
                RoutineChoice(label: 'Cada mes', selected: repeatFrequency == 'monthly', onTap: () => setState(() => repeatFrequency = 'monthly')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Eventos a generar', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(routinePreview, style: Theme.of(context).textTheme.bodyMedium),
                ])),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => setState(() => repeatOccurrences = max(2, repeatOccurrences - 1)), icon: const Icon(Icons.remove_rounded)),
                    Text(repeatOccurrences.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    IconButton(onPressed: () => setState(() => repeatOccurrences = min(52, repeatOccurrences + 1)), icon: const Icon(Icons.add_rounded)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              RoutineInfoBox(text: 'Se crearán $repeatOccurrences fechas conectadas en una misma rutina. Después podrás editar solo una fecha, esta y futuras, o toda la rutina.'),
            ],
          ]),
        ),
      ],
      const SizedBox(height: 14),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_rounded, color: AppColors.teal, size: 20)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mínimo para que el plan salga adelante', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('Grupli avisará cuando haya suficientes personas confirmadas.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 12),
        StepperRow(value: minPeople, onMinus: () => setState(() => minPeople = max(1, minPeople - 1)), onPlus: () => setState(() => minPeople++)),
      ])),
      const SizedBox(height: 14),
      FieldLabel('Notas opcionales'),
      TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(hintText: 'Material, normas, instrucciones, coste aproximado...')),
      const SizedBox(height: 22),
      PrimaryButton(
        label: editing ? 'Guardar cambios' : (repeatEnabled ? 'Crear rutina' : 'Crear evento'),
        icon: editing ? Icons.save_rounded : (repeatEnabled ? Icons.repeat_rounded : Icons.add_rounded),
        loading: loading,
        onTap: save,
      ),
    ]));
  }
}


class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> group;
  const EventDetailScreen({super.key, required this.event, required this.group});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<_EventDetailData> future;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = _EventDetailData.load(widget.event['id'].toString(), widget.group['id'].toString());
  }

  void reload() => setState(load);

  Future<void> setStatus(String eventId, String status) async {
    setState(() => saving = true);
    try {
      await AppData.setAttendance(eventId, status);
      reload();
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveContribution(Map<String, dynamic> event, [Map<String, dynamic>? current]) async {
    final initial = AppData.text(current?['items_text']);
    final value = await showEventContributionDialog(context, initial: initial, event: event);
    if (value == null) return;
    if (value == _eventContributionDeleteToken) {
      await deleteContribution(event);
      return;
    }
    setState(() => saving = true);
    try {
      await AppData.saveEventContribution(
        groupId: widget.group['id'].toString(),
        eventId: event['id'].toString(),
        itemsText: value,
      );
      reload();
      if (mounted) await showToast(context, 'Guardado. El grupo ya puede ver qué llevas.');
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deleteContribution(Map<String, dynamic> event) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar lo que llevo'),
        content: const Text('Se borrará solo tu aportación de este evento.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => saving = true);
    try {
      await AppData.deleteMyEventContribution(event['id'].toString());
      reload();
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> editEvent(Map<String, dynamic> event) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: widget.group, event: event)));
    if (ok == true) reload();
  }

  Future<void> cancelEvent(Map<String, dynamic> event) async {
    String scope = 'single';
    final isRoutine = eventIsRoutine(event);
    if (isRoutine) {
      final selectedScope = await showRoutineScopeDialog(context, title: 'Cancelar rutina', actionLabel: 'Cancelar');
      if (selectedScope == null) return;
      scope = selectedScope;
    } else {
      final yes = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cancelar evento'),
          content: const Text('El evento dejará de aparecer en el calendario del grupo. Esta acción no borra el grupo.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancelar evento')),
          ],
        ),
      );
      if (yes != true) return;
    }
    try {
      await AppData.cancelEventWithScope(event['id'].toString(), scope);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EventDetailData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DirectPage(child: CenterLoader(label: 'Cargando evento...'));
        }
        if (snapshot.hasError) {
          return DirectPage(child: ErrorBlock(message: snapshot.error.toString(), onRetry: reload));
        }
        final data = snapshot.data!;
        final event = data.event;
        final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
        final yes = attendanceCount(event, 'yes');
        final maybe = attendanceCount(event, 'maybe');
        final no = attendanceCount(event, 'no');
        final minPeople = AppData.intValue(event['min_people'], 2);
        final mine = myAttendanceStatus(event);
        final pending = max(0, data.members.length - yes - maybe - no);
        final canManageEvent = AppData.text(event['created_by']).isNotEmpty && AppData.text(event['created_by']) == (AppData.user?.id ?? '');

        return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageHeader(title: AppData.text(event['title'], 'Evento'), subtitle: AppData.text(widget.group['name'], 'Grupo'), leading: true),
          const SizedBox(height: 12),
          PremiumEventDetailHero(event: event, date: date, yes: yes, minPeople: minPeople),
          if (AppData.text(event['location']).isNotEmpty) ...[
            const SizedBox(height: 12),
            EventLocationMapCard(address: AppData.text(event['location'])),
          ],
          if (eventIsRoutine(event)) ...[
            const SizedBox(height: 12),
            RoutineInfoBox(text: '${eventRoutineBadge(event)} · al editar o cancelar podrás aplicar el cambio a una fecha, a futuras fechas o a toda la rutina.'),
          ],
          const SizedBox(height: 16),
          SectionHeader(title: 'Tu respuesta'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AttendancePick(label: 'Voy', count: yes, selected: mine == 'yes', color: AppColors.green, onTap: saving ? () {} : () => setStatus(event['id'].toString(), 'yes'))),
            const SizedBox(width: 8),
            Expanded(child: AttendancePick(label: 'Duda', count: maybe, selected: mine == 'maybe', color: AppColors.amber, onTap: saving ? () {} : () => setStatus(event['id'].toString(), 'maybe'))),
            const SizedBox(width: 8),
            Expanded(child: AttendancePick(label: 'No voy', count: no, selected: mine == 'no', color: AppColors.red, onTap: saving ? () {} : () => setStatus(event['id'].toString(), 'no'))),
          ]),
          if (saving) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
          const SizedBox(height: 12),
          AttendanceOverviewCard(yes: yes, maybe: maybe, no: no, pending: pending, minPeople: minPeople),
          const SizedBox(height: 18),
          EventContributionsCard(
            contributions: data.contributions,
            onAdd: () => saveContribution(event),
            onEdit: (contribution) => saveContribution(event, contribution),
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Asistencia del grupo', action: 'Actualizar', onTap: reload),
          const SizedBox(height: 10),
          EventMemberRoster(event: event, members: data.members),
          if (AppData.text(event['location']).isNotEmpty) ...[
            const SizedBox(height: 18),
            PrimaryButton(label: 'Ir a Google Maps', icon: Icons.navigation_rounded, onTap: () { openAddressInGoogleMaps(context, AppData.text(event['location'])); }),
          ],
          if (canManageEvent) ...[
            const SizedBox(height: 18),
            SecondaryButton(label: 'Editar evento', icon: Icons.edit_rounded, onTap: () => editEvent(event)),
            const SizedBox(height: 10),
            DangerButton(label: 'Cancelar evento', icon: Icons.event_busy_rounded, onTap: () => cancelEvent(event)),
          ],
        ]));
      },
    );
  }
}

class _EventDetailData {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> contributions;
  const _EventDetailData({required this.event, required this.members, required this.contributions});

  static Future<_EventDetailData> load(String eventId, String groupId) async {
    final results = await Future.wait([
      AppData.eventById(eventId),
      AppData.members(groupId),
      AppData.eventContributions(eventId),
    ]);
    return _EventDetailData(
      event: results[0] as Map<String, dynamic>,
      members: List<Map<String, dynamic>>.from(results[1] as List),
      contributions: List<Map<String, dynamic>>.from(results[2] as List),
    );
  }
}

const String _eventContributionDeleteToken = '__DELETE_EVENT_CONTRIBUTION__';

List<String> eventContributionSuggestions(Map<String, dynamic> event) {
  final kind = eventKind(event);
  final title = AppData.text(event['title']).toLowerCase();
  final notes = AppData.text(event['notes']).toLowerCase();
  final joined = '$title $notes';

  if (joined.contains('fiesta') || joined.contains('cumple') || joined.contains('karaoke')) {
    return const ['Bebida', 'Hielo', 'Vasos', 'Comida', 'Altavoz', 'Micrófono', 'Decoración', 'Postre'];
  }
  if (kind == 'partido' || kind == 'torneo' || kind == 'entrenamiento') {
    return const ['Pelotas', 'Agua', 'Petos', 'Bomba', 'Botiquín', 'Altavoz', 'Toallas', 'Hielo'];
  }
  if (kind == 'cena') {
    return const ['Bebida', 'Postre', 'Pan', 'Tortilla', 'Hielo', 'Vasos', 'Servilletas', 'Cubiertos'];
  }
  if (kind == 'reunion') {
    return const ['Documentos', 'Ordenador', 'Cargador', 'Agua', 'Café', 'Algo para picar'];
  }
  return const ['Bebida', 'Comida', 'Hielo', 'Vasos', 'Pelotas', 'Altavoz', 'Postre', 'Agua'];
}

Future<String?> showEventContributionDialog(BuildContext context, {required String initial, required Map<String, dynamic> event}) async {
  final controller = TextEditingController(text: initial);
  final suggestions = eventContributionSuggestions(event);
  final hasInitial = initial.trim().isNotEmpty;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        title: const Text('¿Qué vas a llevar?'),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Escribe algo sencillo. Por ejemplo: bebida, tortilla, pelotas o altavoz.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.35)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              maxLength: 240,
              decoration: const InputDecoration(
                labelText: 'Yo llevo...',
                hintText: 'Ej: bebida y hielo',
                prefixIcon: Icon(Icons.card_giftcard_rounded),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Ideas rápidas', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((suggestion) => ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  final current = controller.text.trim();
                  final alreadyAdded = current.toLowerCase().split(',').map((value) => value.trim()).contains(suggestion.toLowerCase());
                  final next = current.isEmpty
                      ? suggestion
                      : alreadyAdded
                          ? current
                          : '$current, ${suggestion.toLowerCase()}';
                  controller.text = next;
                  controller.selection = TextSelection.collapsed(offset: controller.text.length);
                  setLocalState(() {});
                },
              )).toList(),
            ),
            if (hasInitial) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.pop(dialogContext, _eventContributionDeleteToken),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Quitar lo que llevo'),
              ),
            ],
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Volver')),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');
              if (value.length < 2) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}

class EventContributionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> contributions;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit;
  const EventContributionsCard({super.key, required this.contributions, required this.onAdd, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppData.user?.id ?? '';
    Map<String, dynamic>? mine;
    for (final contribution in contributions) {
      if (AppData.text(contribution['user_id']) == currentUserId) {
        mine = contribution;
        break;
      }
    }
    final count = contributions.length;
    return AppCard(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x22D69027))),
            child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Qué llevamos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(
              count == 0 ? 'Nadie ha dicho todavía qué lleva.' : '$count ${count == 1 ? 'persona ya ha dicho qué lleva' : 'personas ya han dicho qué llevan'}.',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ])),
        ]),
        const SizedBox(height: 14),
        if (contributions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.lineSoft)),
            child: const Text(
              'Nadie ha añadido nada todavía. Pulsa el botón y escribe qué vas a llevar.',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.35),
            ),
          )
        else
          ...contributions.map((contribution) {
            final isMine = AppData.text(contribution['user_id']) == currentUserId;
            final profile = AppData.asMap(contribution['profiles']);
            var name = AppData.text(profile['full_name']);
            if (name.isEmpty || name == 'Usuario') {
              final email = AppData.text(profile['email']);
              name = email.contains('@') ? email.split('@').first : 'Miembro';
            }
            final avatar = AppData.text(profile['avatar_url']);
            final text = AppData.text(contribution['items_text'], 'Algo para el evento');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isMine ? const Color(0x330E6B73) : AppColors.lineSoft)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ProfileAvatar(name: name, avatarUrl: avatar, radius: 20),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isMine ? 'Tú' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text(text, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, height: 1.3, fontSize: 15)),
                  ])),
                ]),
              ),
            );
          }),
        const SizedBox(height: 4),
        SecondaryButton(
          label: mine == null ? 'Añadir lo que llevo' : 'Editar lo que llevo',
          icon: mine == null ? Icons.add_rounded : Icons.edit_rounded,
          onTap: mine == null ? onAdd : () => onEdit(mine!),
        ),
      ]),
    );
  }
}




class CalendarTab extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> group;
  final int refreshSeed;
  const CalendarTab({super.key, required this.groupId, required this.group, required this.refreshSeed});
  @override State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = DateTime.now();
  int viewMode = 0; // 0 semana, 1 mes
  bool loading = true;
  bool refreshing = false;
  String? errorMessage;
  List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
  int _loadToken = 0;
  Timer? _reloadDebounce;

  String get groupId => widget.groupId.trim().isNotEmpty ? widget.groupId.trim() : AppData.text(widget.group['id']);

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalendarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed || oldWidget.groupId != widget.groupId) {
      _scheduleSoftReload();
    }
  }

  void _scheduleSoftReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) load(silent: true);
    });
  }

  Map<String, List<Map<String, dynamic>>> _eventsByDay(List<Map<String, dynamic>> source) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final event in source) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      if (date == null) continue;
      final key = calendarDayKey(date);
      (map[key] ??= <Map<String, dynamic>>[]).add(event);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
    }
    return map;
  }

  List<Map<String, dynamic>> _eventsForDay(Map<String, List<Map<String, dynamic>>> index, DateTime day) {
    return List<Map<String, dynamic>>.from(index[calendarDayKey(day)] ?? const <Map<String, dynamic>>[]);
  }

  int _eventsInMonthFromIndex(Map<String, List<Map<String, dynamic>>> index, DateTime targetMonth) {
    var count = 0;
    for (final entry in index.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date != null && date.year == targetMonth.year && date.month == targetMonth.month) {
        count += entry.value.length;
      }
    }
    return count;
  }

  Future<void> load({bool silent = false}) async {
    final id = groupId;
    final token = ++_loadToken;
    if (id.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
        refreshing = false;
        errorMessage = 'No se ha podido identificar este grupo. Vuelve a Mis grupos y entra otra vez.';
        events = <Map<String, dynamic>>[];
      });
      return;
    }

    if (mounted) {
      setState(() {
        if (!silent && events.isEmpty) {
          loading = true;
        } else {
          refreshing = true;
        }
        errorMessage = null;
      });
    }

    try {
      final rows = await AppData.events(id).timeout(const Duration(seconds: 12));
      if (!mounted || token != _loadToken) return;
      setState(() {
        events = rows;
        loading = false;
        refreshing = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        loading = false;
        refreshing = false;
        errorMessage = humanError(e);
      });
    }
  }

  Future<void> reload() async => load(silent: events.isNotEmpty);

  Future<void> createFor(DateTime day) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateEventScreen(group: widget.group, initialDate: day)),
    );
    if (ok == true) await load(silent: true);
  }

  Future<void> openEvent(Map<String, dynamic> event) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: widget.group)));
    await load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = events
        .where((e) => AppData.text(e['status'], 'active') != 'cancelled')
        .toList();
    visibleEvents.sort((a, b) {
      final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.now();
      final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.now();
      return da.compareTo(db);
    });

    final byDay = _eventsByDay(visibleEvents);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final upcomingEvents = visibleEvents.where((event) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      if (date == null) return false;
      final eventDay = DateTime(date.year, date.month, date.day);
      return !eventDay.isBefore(today);
    }).toList();

    final selectedEvents = _eventsForDay(byDay, selected);
    final weekStart = today;
    final weekDays = List<DateTime>.generate(7, (i) => DateTime(weekStart.year, weekStart.month, weekStart.day).add(Duration(days: i)));
    final weekEventsCount = weekDays.fold<int>(0, (sum, day) => sum + _eventsForDay(byDay, day).length);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.navAgenda,
        onRefresh: reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 112),
          children: [
            PageHeader(
              title: 'Agenda',
              subtitle: 'Elige un día y crea planes.',
              leading: false,
              action: HeaderCreateButton(
                label: 'Crear',
                icon: Icons.add_rounded,
                onTap: () => createFor(selected),
              ),
            ),
            const SizedBox(height: 12),
            if (loading && events.isEmpty) ...[
              const CenterLoader(label: 'Cargando agenda...'),
              const SizedBox(height: 12),
            ],
            if (errorMessage != null) ...[
              ErrorBlock(message: errorMessage!, onRetry: () { reload(); }),
              const SizedBox(height: 12),
            ],
            if (refreshing) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(minHeight: 3, color: AppColors.navAgenda, backgroundColor: AppColors.line),
              ),
              const SizedBox(height: 10),
            ],
            AgendaViewSwitch(
              index: viewMode,
              onChanged: (i) => setState(() => viewMode = i),
            ),
            const SizedBox(height: 12),
            if (viewMode == 0) ...[
              AgendaWeekHeader(
                selected: selected,
                weekEvents: weekEventsCount,
                onPrevious: () {
                  final next = selected.subtract(const Duration(days: 7));
                  setState(() {
                    selected = next;
                    month = DateTime(next.year, next.month);
                  });
                },
                onNext: () {
                  final next = selected.add(const Duration(days: 7));
                  setState(() {
                    selected = next;
                    month = DateTime(next.year, next.month);
                  });
                },
                onToday: () {
                  final now = DateTime.now();
                  setState(() {
                    selected = DateTime(now.year, now.month, now.day);
                    month = DateTime(now.year, now.month);
                  });
                },
              ),
              const SizedBox(height: 10),
              PremiumWeekStrip(
                days: weekDays,
                selected: selected,
                eventsByDay: byDay,
                onSelect: (day) => setState(() {
                  selected = day;
                  month = DateTime(day.year, day.month);
                }),
              ),
            ] else ...[
              AgendaMonthHeader(
                month: month,
                eventsCount: _eventsInMonthFromIndex(byDay, month),
                onPrevious: () => setState(() => month = DateTime(month.year, month.month - 1)),
                onNext: () => setState(() => month = DateTime(month.year, month.month + 1)),
                onToday: () {
                  final now = DateTime.now();
                  setState(() {
                    selected = DateTime(now.year, now.month, now.day);
                    month = DateTime(now.year, now.month);
                  });
                },
              ),
              const SizedBox(height: 10),
              RepaintBoundary(
                child: PremiumMonthCalendar(
                  month: month,
                  selected: selected,
                  eventsByDay: byDay,
                  onSelect: (d) => setState(() {
                    selected = d;
                    month = DateTime(d.year, d.month);
                  }),
                ),
              ),
            ],
            const SizedBox(height: 10),
            EventTypeLegend(events: visibleEvents),
            const SizedBox(height: 14),
            if (selectedEvents.isNotEmpty) ...[
              SectionHeader(title: 'Planes del día', action: '${selectedEvents.length}'),
              const SizedBox(height: 10),
              AgendaSameDayCompactCard(events: selectedEvents, group: widget.group, onChanged: reload, title: agendaSelectedDayTitle(selected)),
              const SizedBox(height: 18),
            ],
            SectionHeader(title: selectedEvents.isEmpty ? 'Próximos planes' : 'Siguientes planes', action: '${upcomingEvents.length}'),
            const SizedBox(height: 10),
            if (upcomingEvents.isEmpty)
              PremiumAgendaEmptyState(
                hasAnyEvents: visibleEvents.isNotEmpty,
                selected: selected,
                onCreate: () => createFor(selected),
              )
            else
              AgendaGroupedUpcomingList(
                events: upcomingEvents,
                group: widget.group,
                onChanged: reload,
                excludeDay: selectedEvents.isNotEmpty ? selected : null,
                onCreate: () => createFor(selected),
              ),
          ],
        ),
      ),
    );
  }
}
