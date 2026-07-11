part of grupli_app;

class MembersScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const MembersScreen({super.key, required this.group});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = AppData.members(widget.group['id'].toString());
  }

  void reload() => setState(() { future = AppData.members(widget.group['id'].toString()); });

  Map<String, dynamic>? _me(List<Map<String, dynamic>> members) {
    final uid = AppData.user?.id;
    for (final member in members) {
      if (member['user_id']?.toString() == uid) return member;
    }
    return null;
  }

  String _myRole(List<Map<String, dynamic>> members) => AppData.text(_me(members)?['role'], 'member');

  bool _canManage(List<Map<String, dynamic>> members) {
    final role = _myRole(members);
    return role == 'owner' || role == 'admin';
  }

  Future<void> _changeRole(Map<String, dynamic> member, String role) async {
    final name = memberName(member);
    try {
      await AppData.updateMemberRole(member['id'].toString(), role);
      reload();
      if (mounted) await showToast(context, role == 'admin' ? '$name ahora es admin.' : '$name vuelve a ser miembro.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> _remove(Map<String, dynamic> member) async {
    final name = memberName(member);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Expulsar a $name'),
        content: const Text('Esta persona perderá acceso al grupo. Podrá volver si recibe una nueva invitación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Expulsar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppData.removeMember(member['id'].toString());
      reload();
      if (mounted) await showToast(context, '$name ya no está en el grupo.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> _leaveGroup(String groupName, bool isOwner) async {
    if (isOwner) {
      await showToast(context, 'El owner no puede salir sin transferir o eliminar el grupo.', danger: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: Text('Vas a salir de $groupName. Para volver necesitarás una invitación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppData.leaveGroup(widget.group['id'].toString());
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      await showToast(context, 'Has salido del grupo.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = AppData.text(widget.group['name'], 'Grupo');
    final code = AppData.text(widget.group['invite_code'], '------');
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Miembros', subtitle: 'Personas, roles y permisos del grupo.', leading: true),
        const SizedBox(height: 14),
        InviteAccessCard(groupName: groupName, code: code, compact: false),
        const SizedBox(height: 14),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando miembros...');
            if (snapshot.hasError) return ErrorBlock(message: humanError(snapshot.error), onRetry: reload);
            final members = snapshot.data ?? [];
            final admins = members.where((m) => ['owner', 'admin'].contains(AppData.text(m['role']))).toList();
            final regular = members.where((m) => AppData.text(m['role']) == 'member').toList();
            final canManage = _canManage(members);
            final myRole = _myRole(members);
            final isOwner = myRole == 'owner';
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: StatCard(icon: Icons.groups_rounded, value: members.length.toString(), label: 'Total', color: AppColors.teal)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: Icons.admin_panel_settings_rounded, value: admins.length.toString(), label: 'Admins', color: AppColors.violet)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: Icons.person_outline_rounded, value: regular.length.toString(), label: 'Miembros', color: AppColors.orange)),
              ]),
              const SizedBox(height: 16),
              RoleInfoCard(role: myRole),
              const SizedBox(height: 18),
              SectionHeader(title: 'Owner y administradores'),
              const SizedBox(height: 8),
              ...admins.map((m) => ManageMemberCard(member: m, canManage: canManage, onRole: _changeRole, onRemove: _remove)),
              const SizedBox(height: 16),
              SectionHeader(title: 'Miembros'),
              const SizedBox(height: 8),
              if (regular.isEmpty)
                EmptySlim(icon: Icons.person_add_alt_1_rounded, title: 'Aún no hay miembros normales', body: 'Invita a tu grupo con el código cuando esté listo.')
              else
                ...regular.map((m) => ManageMemberCard(member: m, canManage: canManage, onRole: _changeRole, onRemove: _remove)),
              const SizedBox(height: 16),
              PermissionMatrixCard(),
              const SizedBox(height: 16),
              if (isOwner)
                AppCard(
                  color: AppColors.tealSoft,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Icon(Icons.shield_rounded, color: AppColors.teal),
                    SizedBox(width: 10),
                    Expanded(child: Text('Eres owner del grupo. Puedes gestionar miembros y eliminar el grupo desde Ajustes.', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, height: 1.3))),
                  ]),
                )
              else
                DangerButton(
                  label: 'Salir del grupo',
                  icon: Icons.logout_rounded,
                  onTap: () => _leaveGroup(groupName, isOwner),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}


class GroupSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onChanged;
  const GroupSettingsScreen({super.key, required this.group, this.onChanged});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late Map<String, dynamic> group;
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController timezoneController;
  late final TextEditingController rulesController;
  String type = 'otro';
  String currency = 'EUR';
  String language = 'es';
  bool savingCover = false;
  bool savingInfo = false;
  bool regeneratingCode = false;

  @override
  void initState() {
    super.initState();
    group = Map<String, dynamic>.from(widget.group);
    nameController = TextEditingController(text: AppData.text(group['name'], 'Grupo'));
    descriptionController = TextEditingController(text: AppData.text(group['description'], groupTypeDefaultDescription(AppData.text(group['type'], 'otro'))));
    timezoneController = TextEditingController(text: AppData.text(group['timezone'], 'Europe/Madrid'));
    rulesController = TextEditingController(text: AppData.text(group['rules']));
    type = groupTypeValue(AppData.text(group['type'], 'otro'));
    currency = AppData.text(group['currency'], 'EUR').toUpperCase();
    language = AppData.text(group['language'], 'es').toLowerCase();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    timezoneController.dispose();
    rulesController.dispose();
    super.dispose();
  }

  Future<void> saveInfo() async {
    setState(() => savingInfo = true);
    try {
      await AppData.updateGroupInfo(
        group['id'].toString(),
        name: nameController.text,
        type: type,
        description: descriptionController.text,
        currency: currency,
        timezone: timezoneController.text,
        language: language,
        rules: rulesController.text,
      );
      if (!mounted) return;
      setState(() {
        group['name'] = nameController.text.trim();
        group['type'] = type;
        group['description'] = descriptionController.text.trim();
        group['currency'] = currency;
        group['timezone'] = timezoneController.text.trim();
        group['language'] = language;
        group['rules'] = rulesController.text.trim();
      });
      widget.onChanged?.call();
      await showToast(context, 'Grupo actualizado.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => savingInfo = false);
    }
  }

  Future<void> changeCover() async {
    setState(() => savingCover = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 2400);
      if (picked == null) return;
      final raw = await picked.readAsBytes();
      if (!mounted) return;
      final framed = await Navigator.of(context).push<Uint8List>(MaterialPageRoute(
        builder: (_) => ImageFrameEditorScreen(
          bytes: raw,
          title: 'Ajustar portada',
          helper: 'Arrastra y pellizca la imagen para dejar el banner bien encuadrado.',
          aspectRatio: 16 / 7,
          outputWidth: 1600,
        ),
      ));
      if (framed == null) return;
      final url = await AppData.uploadGroupCoverBytes(group['id'].toString(), framed, 'group-cover.png');
      if (!mounted) return;
      setState(() => group['cover_url'] = url);
      widget.onChanged?.call();
      await showToast(context, 'Foto del grupo actualizada.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => savingCover = false);
    }
  }

  Future<void> removeCover() async {
    setState(() => savingCover = true);
    try {
      await AppData.removeGroupCover(group['id'].toString());
      if (!mounted) return;
      setState(() => group['cover_url'] = null);
      widget.onChanged?.call();
      await showToast(context, 'Foto del grupo eliminada.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => savingCover = false);
    }
  }

  Future<void> regenerateInviteCode() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Regenerar código',
      message: 'El código anterior dejará de servir para nuevas invitaciones. Los miembros actuales seguirán dentro.',
      confirm: 'Regenerar',
      danger: true,
    );
    if (confirm != true) return;
    setState(() => regeneratingCode = true);
    try {
      final code = await AppData.regenerateGroupInviteCode(group['id'].toString());
      if (!mounted) return;
      setState(() => group['invite_code'] = code);
      widget.onChanged?.call();
      await showToast(context, 'Código regenerado.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => regeneratingCode = false);
    }
  }

  Future<void> deleteGroupFlow() async {
    final isOwner = AppData.text(group['owner_id']) == AppData.user?.id;
    if (!isOwner) {
      await showToast(context, 'Solo el owner puede eliminar este grupo.', danger: true);
      return;
    }

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vas a eliminar "${AppData.text(group['name'], 'este grupo')}".'),
          const SizedBox(height: 10),
          const Text('Se eliminarán sus miembros, eventos, asistencias, gastos, liquidaciones, torneos y notificaciones relacionadas.'),
          const SizedBox(height: 14),
          const Text('Escribe ELIMINAR GRUPO para confirmar.', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'ELIMINAR GRUPO')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, controller.text.trim().toUpperCase() == 'ELIMINAR GRUPO'),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    final typed = controller.text;
    controller.dispose();
    if (confirmed != true) {
      if (typed.trim().isNotEmpty && mounted) await showToast(context, 'Escribe ELIMINAR GRUPO exactamente para eliminarlo.', danger: true);
      return;
    }

    try {
      await AppData.deleteGroup(group['id'].toString(), 'ELIMINAR GRUPO');
      widget.onChanged?.call();
      if (!mounted) return;
      await showToast(context, 'Grupo eliminado.');
      if (mounted) Navigator.of(context).pop('deleted');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final code = AppData.text(group['invite_code'], '------');
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Ajustes del grupo', subtitle: 'Identidad, invitaciones y permisos de $name', leading: true),
      const SizedBox(height: 16),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.groups_rounded, color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Información básica', style: Theme.of(context).textTheme.titleMedium),
            Text('Nombre, descripción, portada y reglas del grupo.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 16),
        FieldLabel('Nombre del grupo'),
        TextField(controller: nameController, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'Nombre del grupo')),

        const SizedBox(height: 12),
        FieldLabel('Descripción'),
        TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(hintText: 'Explica para qué se usa este grupo')),
        const SizedBox(height: 12),
        StatusNotice(
          icon: Icons.tune_rounded,
          title: 'Idioma y moneda',
          body: 'Por ahora Grupli trabaja en español y euros. Estos ajustes se activarán cuando estén cerrados en toda la app.',
        ),
        const SizedBox(height: 12),
        FieldLabel('Zona horaria'),
        TextField(controller: timezoneController, decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule_rounded), hintText: 'Europe/Madrid')),
        const SizedBox(height: 12),
        PrimaryButton(label: savingInfo ? 'Guardando...' : 'Guardar cambios', icon: Icons.save_rounded, loading: savingInfo, onTap: saveInfo),
      ])),
      const SizedBox(height: 16),
      GroupCoverSettingsCard(group: group, saving: savingCover, onChange: changeCover, onRemove: removeCover),
      const SizedBox(height: 16),
      InviteAccessCard(groupName: name, code: code, compact: true, onRegenerate: regeneratingCode ? null : regenerateInviteCode),
      const SizedBox(height: 16),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel('Reglas del grupo'),
        TextField(controller: rulesController, minLines: 2, maxLines: 5, decoration: const InputDecoration(hintText: 'Ej. Confirmar asistencia antes del jueves, gastos con ticket...')),
        const SizedBox(height: 12),
        SecondaryButton(label: 'Guardar reglas', icon: Icons.rule_rounded, onTap: saveInfo),
      ])),
      const SizedBox(height: 16),
      SectionHeader(title: 'Premium'),
      const SizedBox(height: 8),
      PremiumGroupPreviewCard(group: group),
      const SizedBox(height: 16),
      SectionHeader(title: 'Administración'),
      const SizedBox(height: 8),
      SettingsRow(icon: Icons.groups_rounded, title: 'Miembros y roles', subtitle: 'Owner, admins y miembros', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group)))),
      SettingsRow(icon: Icons.verified_user_rounded, title: 'Permisos', subtitle: 'Qué puede hacer cada rol', onTap: () => showPermissionSheet(context)),
      SettingsRow(icon: Icons.delete_outline_rounded, title: 'Eliminar grupo', subtitle: 'Solo owner · elimina eventos, gastos y torneos', danger: true, onTap: deleteGroupFlow),
    ]));
  }
}

class PremiumGroupPreviewCard extends StatelessWidget {
  final Map<String, dynamic> group;
  const PremiumGroupPreviewCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final entitlement = GrupliPremium.entitlementForGroup(group);
    return AppCard(
      color: entitlement.active ? AppColors.tealSoft : AppColors.faint,
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PremiumGroupScreen(group: group))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Icon(entitlement.active ? Icons.workspace_premium_rounded : Icons.workspace_premium_rounded, color: entitlement.active ? AppColors.teal : AppColors.orange)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entitlement.active ? 'Grupli Premium activo' : 'Grupli Premium preparado', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(entitlement.active ? 'Este grupo tiene activadas las funciones Premium.' : 'Pagos aún desactivados. Dejamos lista la estructura para activar Premium por grupo más adelante.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25, fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ]),
    );
  }
}

class PremiumGroupScreen extends StatelessWidget {
  final Map<String, dynamic> group;
  const PremiumGroupScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final entitlement = GrupliPremium.entitlementForGroup(group);
    return DirectPage(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: 'Grupli Premium', subtitle: 'Premium será por grupo: si se activa aquí, todos los miembros de $name lo disfrutan y la app va sin anuncios.', leading: true),
        const SizedBox(height: 16),
        AppCard(
          color: entitlement.active ? AppColors.tealSoft : AppColors.orangeSoft,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)), child: Icon(entitlement.active ? Icons.verified_rounded : Icons.lock_clock_rounded, color: entitlement.active ? AppColors.teal : AppColors.orange)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entitlement.label, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(GrupliPremium.billingEnabled ? 'Los pagos estarán conectados al backend y a las stores.' : 'Los pagos todavía no están activos. Esta versión solo prepara permisos y experiencia, con acceso sin anuncios cuando Premium llegue.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25)),
              ])),
            ]),
            const SizedBox(height: 14),
            StatusNotice(
              icon: Icons.shield_outlined,
              title: 'Sin trampas locales',
              body: 'Cuando se activen pagos, la app consultará al backend si el grupo tiene Premium. El frontend no decidirá solo.',
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'Gratis debe seguir siendo útil'),
        const SizedBox(height: 8),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Incluido gratis', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...GrupliPremium.freeTournamentPrinciples.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(item, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.25))),
            ]),
          )),
        ])),
        const SizedBox(height: 16),
        SectionHeader(title: 'Premium futuro'),
        const SizedBox(height: 8),
        ...GrupliPremium.features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(13),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(14)), child: Icon(feature.icon, color: AppColors.orange, size: 21)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(feature.title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(feature.description, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25, fontSize: 12)),
              ])),
            ]),
          ),
        )),
        const SizedBox(height: 8),
        PrimaryButton(
          label: GrupliPremium.billingEnabled ? 'Activar Premium' : 'Pagos todavía desactivados',
          icon: Icons.workspace_premium_rounded,
          onTap: () => showToast(context, GrupliPremium.billingEnabled ? 'El pago se conectará con la store.' : 'Premium está preparado, pero los pagos reales se activarán en una fase posterior.'),
        ),
      ],
    ));
  }
}

class GroupCoverSettingsCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool saving;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  const GroupCoverSettingsCard({super.key, required this.group, required this.saving, required this.onChange, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cover = AppData.text(group['cover_url']);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 128,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF073A57), Color(0xFF0B6B8F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: cover.isNotEmpty
                ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_rounded, color: Colors.white, size: 34)))
                : const Center(child: Icon(Icons.image_rounded, color: Colors.white, size: 34)),
          ),
        ),
        const SizedBox(height: 12),
        Text('Foto del grupo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Dale identidad al grupo en Inicio y Mis grupos.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SecondaryButton(label: saving ? 'Guardando...' : 'Cambiar foto', icon: Icons.photo_camera_rounded, onTap: saving ? () {} : onChange)),
          if (cover.isNotEmpty) ...[
            const SizedBox(width: 10),
            Expanded(child: DangerButton(label: 'Quitar', icon: Icons.delete_outline_rounded, onTap: saving ? () {} : onRemove)),
          ],
        ]),
      ]),
    );
  }
}


class GroupAlertBell extends StatelessWidget {
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> pendingEvents;
  final Future<void> Function(Map<String, dynamic> event) onEventOpen;
  final VoidCallback onChanged;

  const GroupAlertBell({
    super.key,
    required this.group,
    required this.pendingEvents,
    required this.onEventOpen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AppData.notifications(),
      builder: (context, snapshot) {
        final groupId = group['id']?.toString();
        final notifications = (snapshot.data ?? const <Map<String, dynamic>>[])
            .where((n) => groupId == null || n['group_id']?.toString() == groupId)
            .take(12)
            .toList();
        final unread = notifications.where((n) => n['read_at'] == null).length;
        final count = pendingEvents.length + unread;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
              icon: count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              onTap: () => showGroupAlertsSheet(
                context,
                group: group,
                pendingEvents: pendingEvents,
                notifications: notifications,
                onEventOpen: onEventOpen,
                onChanged: onChanged,
              ),
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(count > 9 ? '9+' : count.toString(), style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        );
      },
    );
  }
}

void showGroupAlertsSheet(
  BuildContext context, {
  required Map<String, dynamic> group,
  required List<Map<String, dynamic>> pendingEvents,
  required List<Map<String, dynamic>> notifications,
  required Future<void> Function(Map<String, dynamic> event) onEventOpen,
  required VoidCallback onChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => GroupAlertsSheet(
      rootContext: context,
      group: group,
      pendingEvents: pendingEvents,
      notifications: notifications,
      onEventOpen: onEventOpen,
      onChanged: onChanged,
    ),
  );
}

class GroupAlertsSheet extends StatelessWidget {
  final BuildContext rootContext;
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> pendingEvents;
  final List<Map<String, dynamic>> notifications;
  final Future<void> Function(Map<String, dynamic> event) onEventOpen;
  final VoidCallback onChanged;

  const GroupAlertsSheet({
    super.key,
    required this.rootContext,
    required this.group,
    required this.pendingEvents,
    required this.notifications,
    required this.onEventOpen,
    required this.onChanged,
  });

  Future<void> _openNotification(BuildContext context, Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id != null && id.isNotEmpty) await AppData.markNotificationRead(id);
    if (context.mounted) Navigator.of(context).pop();
    onChanged();
    final groupId = notification['group_id']?.toString();
    if (groupId != null && groupId.isNotEmpty && rootContext.mounted) {
      await Navigator.of(rootContext).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId)));
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = pendingEvents.isNotEmpty || notifications.isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .72),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.lineSoft),
          boxShadow: const [BoxShadow(color: Color(0x24102033), blurRadius: 34, offset: Offset(0, 16))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Avisos del grupo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(AppData.text(group['name'], 'Grupo'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              ])),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              shrinkWrap: true,
              children: [
                if (!hasContent)
                  EmptySlim(icon: Icons.notifications_none_rounded, title: 'Sin avisos pendientes', body: 'Cuando haya respuestas, gastos o cambios importantes aparecerán aquí.'),
                if (pendingEvents.isNotEmpty) ...[
                  const _SheetLabel('Respuestas pendientes'),
                  ...pendingEvents.take(6).map((event) => PendingDecisionRow(
                    event: event,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await onEventOpen(event);
                    },
                  )),
                  const SizedBox(height: 8),
                ],
                if (notifications.isNotEmpty) ...[
                  const _SheetLabel('Notificaciones'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(children: [
                      for (int i = 0; i < notifications.length; i++) ...[
                        NotificationListRow(notification: notifications[i], onTap: () => _openNotification(context, notifications[i])),
                        if (i != notifications.length - 1) const Divider(height: 1, indent: 64, color: AppColors.line),
                      ],
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
    child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: .2)),
  );
}

class PendingDecisionRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const PendingDecisionRow({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final color = eventKindColor(event);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(children: [
        Container(
          width: 40,
          height: 42,
          decoration: BoxDecoration(color: eventKindSoftColor(event), borderRadius: BorderRadius.circular(14)),
          child: Icon(notificationIcon('event'), color: color, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text('${longDateTime(date)} · responde asistencia', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ]),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const NotificationsScreen({super.key, required this.onChanged});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => future = AppData.notifications();
  void reload() => setState(load);

  Future<void> markAll() async {
    await AppData.markAllNotificationsRead();
    reload();
  }

  Future<void> openNotification(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id != null && id.isNotEmpty) await AppData.markNotificationRead(id);
    final groupId = notification['group_id']?.toString();
    reload();
    widget.onChanged();
    if (!mounted) return;
    if (groupId != null && groupId.isNotEmpty) {
      final tab = notificationGroupTab(notification);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId, initialTab: tab)));
      widget.onChanged();
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async => reload(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? [];
            final unread = notifications.where((n) => n['read_at'] == null).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: PageHeader(title: 'Avisos', subtitle: unread == 0 ? 'Todo leído en tus grupos.' : '$unread aviso${unread == 1 ? '' : 's'} sin leer', leading: false)),
                  if (unread > 0)
                    TextButton(onPressed: markAll, child: const Text('Leer todo')),
                ]),
                const SizedBox(height: 12),
                PushStatusCard(onEnable: () async {
                  final token = await PushNotificationService.enableForCurrentDevice();
                  if (!mounted) return;
                  if (token == null) {
                    await showToast(context, 'No se pudieron activar las notificaciones en este dispositivo.', danger: true);
                  } else {
                    await showToast(context, 'Notificaciones push activadas en este dispositivo.');
                  }
                }),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CenterLoader(label: 'Cargando avisos...')
                else if (snapshot.hasError)
                  ErrorBlock(message: 'No se pudieron cargar los avisos. Inténtalo de nuevo.', onRetry: reload)
                else if (notifications.isEmpty)
                  EmptyBlock(
                    icon: Icons.notifications_none_rounded,
                    title: 'Sin avisos todavía',
                    body: 'Cuando alguien cree una quedada, añada un gasto, registre un resultado o entre al grupo, aparecerá aquí.',
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(children: [
                      for (int i = 0; i < notifications.length; i++) ...[
                        NotificationListRow(notification: notifications[i], onTap: () => openNotification(notifications[i])),
                        if (i != notifications.length - 1) const Divider(height: 1, indent: 64, color: AppColors.line),
                      ],
                    ]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PushStatusCard extends StatelessWidget {
  final Future<void> Function() onEnable;
  const PushStatusCard({super.key, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final configured = AppConfig.firebaseConfigured || !kIsWeb;
    return AppCard(
      color: configured ? AppColors.tealSoft : AppColors.surface,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: configured ? AppColors.white : AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
          child: Icon(configured ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: AppColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notificaciones del dispositivo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Activa este dispositivo para recibir avisos importantes de tus grupos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: onEnable, icon: const Icon(Icons.power_settings_new_rounded), label: const Text('Activar en este dispositivo')),
          ),
        ])),
      ]),
    );
  }
}

class NotificationListRow extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  const NotificationListRow({super.key, required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = notification['read_at'] == null;
    final type = AppData.text(notification['type'], 'general');
    final color = notificationColor(type);
    final created = DateTime.tryParse(notification['created_at']?.toString() ?? '')?.toLocal();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(notificationIcon(type), color: color, size: 21),
            ),
            if (unread)
              Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(AppData.text(notification['title'], 'Aviso'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: unread ? FontWeight.w900 : FontWeight.w800, color: AppColors.ink))),
              if (created != null) Text(notificationTime(created), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text(AppData.text(notification['body'], 'Hay una novedad en tu grupo.'), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
          ])),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}


int notificationGroupTabFromValues(String routeType, String type) {
  final value = AppData.text(routeType, AppData.text(type)).toLowerCase();
  if (value.contains('event') || value.contains('agenda') || value.contains('attendance') || value.contains('calendar')) return 1;
  if (value.contains('finance') || value.contains('expense') || value.contains('settlement') || value.contains('payment') || value.contains('gasto')) return 2;
  if (value.contains('tournament') || value.contains('match') || value.contains('torneo') || value.contains('resultado')) return 3;
  if (value.contains('member') || value.contains('grupo') || value.contains('group') || value.contains('invite')) return 4;
  return 0;
}

int notificationGroupTab(Map<String, dynamic> notification) {
  return notificationGroupTabFromValues(
    AppData.text(notification['route_type']),
    AppData.text(notification['type']),
  );
}

IconData notificationIcon(String type) {
  return switch (type) {
    'event' => Icons.event_available_rounded,
    'finance' => Icons.account_balance_wallet_rounded,
    'tournament' => Icons.emoji_events_rounded,
    'member' => Icons.groups_rounded,
    _ => Icons.notifications_rounded,
  };
}

Color notificationColor(String type) {
  return switch (type) {
    'event' => AppColors.teal,
    'finance' => AppColors.green,
    'tournament' => AppColors.orange,
    'member' => AppColors.violet,
    _ => AppColors.blue,
  };
}

String notificationTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('dd/MM', 'es_ES').format(date);
}


class SupportTicketScreen extends StatefulWidget {
  final Map<String, dynamic>? group;
  final String screen;
  const SupportTicketScreen({super.key, this.group, this.screen = 'perfil'});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  String type = 'bug';
  String priority = 'normal';
  bool loading = false;
  late Future<List<Map<String, dynamic>>> myTicketsFuture;

  @override
  void initState() {
    super.initState();
    myTicketsFuture = AppData.mySupportTickets();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await AppData.createSupportTicket(
        groupId: widget.group?['id']?.toString(),
        type: type,
        priority: priority,
        title: title.text,
        description: description.text,
        screen: widget.screen,
      );
      title.clear();
      description.clear();
      setState(() { myTicketsFuture = AppData.mySupportTickets(); });
      if (mounted) await showToast(context, 'Reporte enviado. Gracias, lo revisarás desde el panel admin.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = AppData.text(widget.group?['name'], 'Cuenta general');
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Ayuda y soporte', subtitle: 'Reporta errores, dudas o sugerencias sin salir de Grupli.', leading: true),
      const SizedBox(height: 14),
      AppCard(
        padding: const EdgeInsets.all(16),
        color: AppColors.tealSoft,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.support_agent_rounded, color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Enviar reporte', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Zona: $groupName · ${AppConfig.appVersion}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
          ])),
        ]),
      ),
      const SizedBox(height: 14),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel('Tipo de reporte'),
        DropdownButtonFormField<String>(
          value: type,
          items: const [
            DropdownMenuItem(value: 'bug', child: Text('Bug o fallo')),
            DropdownMenuItem(value: 'cuenta', child: Text('Cuenta / acceso')),
            DropdownMenuItem(value: 'grupo', child: Text('Grupo / invitación')),
            DropdownMenuItem(value: 'evento', child: Text('Evento / asistencia')),
            DropdownMenuItem(value: 'finanzas', child: Text('Finanzas / pagos')),
            DropdownMenuItem(value: 'torneo', child: Text('Torneos / resultados')),
            DropdownMenuItem(value: 'sugerencia', child: Text('Sugerencia')),
            DropdownMenuItem(value: 'otro', child: Text('Otro')),
          ],
          onChanged: (v) => setState(() => type = v ?? 'bug'),
        ),
        const SizedBox(height: 12),
        FieldLabel('Prioridad'),
        DropdownButtonFormField<String>(
          value: priority,
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Baja')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'high', child: Text('Alta')),
            DropdownMenuItem(value: 'critical', child: Text('Crítica')),
          ],
          onChanged: (v) => setState(() => priority = v ?? 'normal'),
        ),
        const SizedBox(height: 12),
        FieldLabel('Título'),
        TextField(controller: title, decoration: const InputDecoration(hintText: 'Ej. No me deja marcar un pago')),
        const SizedBox(height: 12),
        FieldLabel('Descripción'),
        TextField(controller: description, minLines: 4, maxLines: 7, decoration: const InputDecoration(hintText: 'Cuenta qué ha pasado, en qué pantalla y qué esperabas que ocurriera.')),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Enviar reporte', icon: Icons.send_rounded, loading: loading, onTap: submit),
      ])),
      const SizedBox(height: 18),
      SectionHeader(title: 'Tus reportes recientes'),
      const SizedBox(height: 8),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: myTicketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando reportes...');
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) return EmptySlim(icon: Icons.inbox_rounded, title: 'Sin reportes todavía', body: 'Cuando envíes algo aparecerá aquí.');
          return Column(children: tickets.take(5).map((ticket) => SupportTicketCard(ticket: ticket)).toList());
        },
      ),
    ]));
  }
}


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String filter = 'open';
  int section = 0;
  late Future<_AdminDashboardData> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = _AdminDashboardData.load(status: filter);
  }

  void reload() => setState(load);

  Future<void> changeStatus(Map<String, dynamic> ticket, String status, {String? note}) async {
    final role = await AppData.currentAppAdminRole();
    if (role == 'viewer' || role.isEmpty) {
      if (mounted) await showToast(context, 'Tu rol puede ver métricas, pero no modificar reportes.', danger: true);
      return;
    }
    try {
      await AppData.updateSupportTicketStatus(ticket['id'].toString(), status, note: note);
      reload();
      if (mounted) await showToast(context, 'Reporte actualizado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> replyToTicket(Map<String, dynamic> ticket) async {
    final controller = TextEditingController(text: AppData.text(ticket['admin_note']));
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder reporte'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'Escribe una respuesta visible para el usuario...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar respuesta')),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;
    await changeStatus(ticket, 'reviewing', note: note);
  }

  Future<void> setUserStatus(Map<String, dynamic> user, String status) async {
    final email = AppData.text(user['email']);
    if (email.isEmpty) return;
    final label = status == 'blocked' ? 'bloquear' : 'activar';
    final ok = await confirmAction(
      context,
      title: '¿${label[0].toUpperCase()}${label.substring(1)} usuario?',
      body: status == 'blocked'
          ? 'El usuario podrá seguir existiendo en base de datos, pero quedará marcado como bloqueado para soporte/admin.'
          : 'El usuario volverá a aparecer como activo.',
      danger: status == 'blocked',
      confirmLabel: status == 'blocked' ? 'Bloquear' : 'Activar',
    );
    if (ok != true) return;
    try {
      await AppData.adminSetUserStatus(email, status);
      reload();
      if (mounted) await showToast(context, status == 'blocked' ? 'Usuario bloqueado.' : 'Usuario activado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: FutureBuilder<_AdminDashboardData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando panel admin...');
        if (snapshot.hasError) return ErrorBlock(message: humanError(snapshot.error), onRetry: reload);
        final data = snapshot.data ?? _AdminDashboardData.empty();
        final overview = data.overview;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageHeader(title: 'Panel admin', subtitle: 'Soporte, usuarios, grupos y calidad de Grupli.', leading: true),
          const SizedBox(height: 10),
          AdminRoleInfoCard(role: data.role),
          const SizedBox(height: 12),
          AdminOverviewHero(overview: overview),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AdminMetricCard(label: 'Usuarios', value: '${AppData.intValue(overview['users'])}', icon: Icons.people_alt_rounded, color: AppColors.teal)),
            const SizedBox(width: 9),
            Expanded(child: AdminMetricCard(label: 'Grupos', value: '${AppData.intValue(overview['groups'])}', icon: Icons.groups_rounded, color: AppColors.violet)),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: AdminMetricCard(label: 'Reportes', value: '${AppData.intValue(overview['open_tickets'])}', icon: Icons.support_agent_rounded, color: AppColors.orange)),
            const SizedBox(width: 9),
            Expanded(child: AdminMetricCard(label: 'Críticos', value: '${AppData.intValue(overview['critical_tickets'])}', icon: Icons.warning_amber_rounded, color: AppColors.red)),
          ]),
          const SizedBox(height: 14),
          AdminSectionTabs(index: section, role: data.role, onChanged: (i) => setState(() => section = i)),
          const SizedBox(height: 14),
          if (section == 0) ...[
            SectionHeader(
              title: 'Reportes de usuarios',
              action: data.isViewer ? 'Solo lectura' : filter == 'open' ? 'Ver todos' : 'Abiertos',
              onTap: data.isViewer ? null : () { setState(() { filter = filter == 'open' ? 'all' : 'open'; load(); }); },
            ),
            const SizedBox(height: 8),
            if (data.isViewer)
              EmptySlim(icon: Icons.visibility_rounded, title: 'Modo viewer', body: 'Puedes ver métricas y estado general, pero no detalles sensibles ni acciones de soporte.')
            else if (data.tickets.isEmpty)
              EmptySlim(icon: Icons.verified_rounded, title: filter == 'open' ? 'No hay reportes abiertos' : 'No hay reportes', body: 'Cuando un usuario reporte algo aparecerá aquí.')
            else
              ...data.tickets.map((ticket) => AdminTicketCard(
                ticket: ticket,
                canHandle: data.canHandleSupport,
                onStatus: (status) => changeStatus(ticket, status),
                onReply: data.canHandleSupport ? () => replyToTicket(ticket) : null,
              )),
          ] else if (section == 1) ...[
            SectionHeader(title: 'Usuarios', action: data.isOwner ? '${data.users.length}' : 'Owner'),
            const SizedBox(height: 8),
            if (!data.isOwner)
              EmptySlim(icon: Icons.lock_rounded, title: 'Solo owner', body: 'Los usuarios son información sensible. Support y viewer no pueden gestionarlos.')
            else if (data.users.isEmpty)
              EmptySlim(icon: Icons.people_alt_rounded, title: 'Sin usuarios visibles', body: 'Todavía no hay usuarios para mostrar.')
            else
              ...data.users.map((u) => AdminUserCard(user: u, onBlock: () => setUserStatus(u, 'blocked'), onActivate: () => setUserStatus(u, 'active'))),
          ] else if (section == 2) ...[
            SectionHeader(title: 'Grupos', action: data.isOwner ? '${data.groups.length}' : 'Owner'),
            const SizedBox(height: 8),
            if (!data.isOwner)
              EmptySlim(icon: Icons.lock_rounded, title: 'Solo owner', body: 'La vista completa de grupos queda reservada al owner.')
            else if (data.groups.isEmpty)
              EmptySlim(icon: Icons.groups_rounded, title: 'Sin grupos visibles', body: 'Cuando se creen grupos aparecerán aquí.')
            else
              ...data.groups.map((g) => AdminGroupCard(group: g)),
          ] else if (section == 3) ...[
            SectionHeader(title: 'Dispositivos push', action: data.isOwner ? '${data.devices.length}' : 'Owner'),
            const SizedBox(height: 8),
            if (!data.isOwner)
              EmptySlim(icon: Icons.lock_rounded, title: 'Solo owner', body: 'Los tokens/dispositivos son datos técnicos sensibles.')
            else if (data.devices.isEmpty)
              EmptySlim(icon: Icons.phone_android_rounded, title: 'Sin dispositivos', body: 'Aparecerán cuando los usuarios activen notificaciones en su móvil.')
            else
              ...data.devices.map((d) => AdminDeviceCard(device: d)),
          ] else ...[
            SectionHeader(title: 'Actividad y calidad', action: '${data.qualityEvents.length}'),
            const SizedBox(height: 8),
            if (data.qualityEvents.isEmpty)
              EmptySlim(icon: Icons.insights_rounded, title: 'Sin eventos todavía', body: 'Se guardarán reportes y señales internas útiles.')
            else
              ...data.qualityEvents.take(20).map((event) => QualityEventCard(event: event)),
          ],
        ]);
      },
    ));
  }
}

class _AdminDashboardData {
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> tickets;
  final List<Map<String, dynamic>> qualityEvents;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> devices;
  final String role;
  const _AdminDashboardData({
    required this.overview,
    required this.tickets,
    required this.qualityEvents,
    required this.users,
    required this.groups,
    required this.devices,
    this.role = '',
  });
  static _AdminDashboardData empty() => const _AdminDashboardData(overview: {}, tickets: [], qualityEvents: [], users: [], groups: [], devices: [], role: '');
  bool get isOwner => role == 'owner';
  bool get canHandleSupport => role == 'owner' || role == 'support';
  bool get isViewer => role == 'viewer';
  static Future<_AdminDashboardData> load({String status = 'open'}) async {
    final role = await AppData.currentAppAdminRole();
    final isOwner = role == 'owner';
    final results = await Future.wait([
      AppData.adminOverview(),
      role == 'viewer' ? Future.value(<Map<String, dynamic>>[]) : AppData.adminSupportTickets(status: status),
      AppData.adminQualityEvents(),
      isOwner ? AppData.adminUsersOverview() : Future.value(<Map<String, dynamic>>[]),
      isOwner ? AppData.adminGroupsOverview() : Future.value(<Map<String, dynamic>>[]),
      isOwner ? AppData.adminDevicesOverview() : Future.value(<Map<String, dynamic>>[]),
    ]);
    return _AdminDashboardData(
      overview: AppData.asMap(results[0]),
      tickets: AppData.asList(results[1]),
      qualityEvents: AppData.asList(results[2]),
      users: AppData.asList(results[3]),
      groups: AppData.asList(results[4]),
      devices: AppData.asList(results[5]),
      role: role,
    );
  }
}

class SupportTicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const SupportTicketCard({super.key, required this.ticket});
  @override
  Widget build(BuildContext context) {
    final status = AppData.text(ticket['status'], 'open');
    final color = ticketStatusColor(status);
    final group = AppData.asMap(ticket['groups']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(14)), child: Icon(ticketTypeIcon(AppData.text(ticket['type'])), color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(ticket['title'], 'Reporte'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 3),
            Text('${ticketStatusLabel(status)} · ${AppData.text(group['name'], 'Cuenta general')}', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          ])),
          _MiniChip(text: ticketPriorityLabel(AppData.text(ticket['priority'], 'normal')), color: ticketPriorityColor(AppData.text(ticket['priority'], 'normal'))),
        ]),
        if (AppData.text(ticket['admin_note']).isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.teal.withOpacity(.14))),
            child: Text('Respuesta de soporte: ${AppData.text(ticket['admin_note'])}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, height: 1.3)),
          ),
        ],
      ])),
    );
  }
}


class AdminRoleInfoCard extends StatelessWidget {
  final String role;
  const AdminRoleInfoCard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final normalized = role.isEmpty ? 'viewer' : role;
    final color = normalized == 'owner' ? AppColors.orange : normalized == 'support' ? AppColors.teal : AppColors.violet;
    final title = normalized == 'owner' ? 'Owner de la app' : normalized == 'support' ? 'Soporte' : 'Viewer';
    final body = normalized == 'owner'
        ? 'Control total: usuarios, grupos, reportes, métricas y acciones críticas.'
        : normalized == 'support'
            ? 'Puede ver y responder reportes, sin tocar acciones críticas de usuarios.'
            : 'Solo métricas y estado general. No puede modificar información sensible.';
    return AppCard(
      padding: const EdgeInsets.all(13),
      color: color.withOpacity(.08),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(14)), child: Icon(normalized == 'owner' ? Icons.workspace_premium_rounded : normalized == 'support' ? Icons.support_agent_rounded : Icons.visibility_rounded, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.25)),
        ])),
        _MiniChip(text: normalized.toUpperCase(), color: color),
      ]),
    );
  }
}

class AdminOverviewHero extends StatelessWidget {
  final Map<String, dynamic> overview;
  const AdminOverviewHero({super.key, required this.overview});
  @override
  Widget build(BuildContext context) {
    final open = AppData.intValue(overview['open_tickets']);
    final critical = AppData.intValue(overview['critical_tickets']);
    final good = open == 0 && critical == 0;
    return AppCard(
      color: good ? AppColors.greenSoft : AppColors.tealDark,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: good ? AppColors.white : Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(16)), child: Icon(good ? Icons.verified_rounded : Icons.admin_panel_settings_rounded, color: good ? AppColors.green : Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(good ? 'Todo controlado' : '$open reportes abiertos', style: TextStyle(color: good ? AppColors.ink : Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 4),
          Text(critical > 0 ? '$critical críticos necesitan revisión prioritaria.' : 'Revisa soporte, usuarios y señales de calidad desde aquí.', style: TextStyle(color: good ? AppColors.muted : const Color(0xDFFFFFFF), fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const AdminMetricCard({super.key, required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 19)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
      ])),
    ]),
  );
}

class AdminTicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool canHandle;
  final ValueChanged<String> onStatus;
  final VoidCallback? onReply;
  const AdminTicketCard({super.key, required this.ticket, this.canHandle = true, required this.onStatus, this.onReply});
  @override
  Widget build(BuildContext context) {
    final profile = AppData.asMap(ticket['profiles']);
    final group = AppData.asMap(ticket['groups']);
    final status = AppData.text(ticket['status'], 'open');
    final priority = AppData.text(ticket['priority'], 'normal');
    final name = AppData.text(profile['full_name'], AppData.text(profile['email'], 'Usuario'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProfileAvatar(name: name, avatarUrl: AppData.text(profile['avatar_url']), radius: 21),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(AppData.text(ticket['title'], 'Reporte'), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
              _MiniChip(text: ticketPriorityLabel(priority), color: ticketPriorityColor(priority)),
            ]),
            const SizedBox(height: 3),
            Text('${ticketTypeLabel(AppData.text(ticket['type']))} · ${AppData.text(group['name'], 'Cuenta general')} · ${ticketStatusLabel(status)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 10),
        Text(AppData.text(ticket['description'], 'Sin descripción'), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.35)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _MiniChip(text: AppData.text(ticket['app_version'], AppConfig.appVersion), color: AppColors.teal),
          _MiniChip(text: AppData.text(ticket['device_info'], 'dispositivo'), color: AppColors.violet),
          _MiniChip(text: AppData.text(ticket['screen'], 'app'), color: AppColors.muted),
        ]),
        if (AppData.text(ticket['admin_note']).isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.green.withOpacity(.15))),
            child: Text('Respuesta admin: ${AppData.text(ticket['admin_note'])}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, height: 1.3)),
          ),
        ],
        const SizedBox(height: 12),
        if (canHandle)
          Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(width: 130, child: SecondaryButton(label: 'Revisando', icon: Icons.search_rounded, onTap: () => onStatus('reviewing'))),
            SizedBox(width: 130, child: PrimaryButton(label: 'Resolver', icon: Icons.check_rounded, onTap: () => onStatus('resolved'))),
            SizedBox(width: 120, child: SecondaryButton(label: 'Cerrar', icon: Icons.archive_rounded, onTap: () => onStatus('closed'))),
            if (onReply != null) SizedBox(width: 130, child: SecondaryButton(label: 'Responder', icon: Icons.reply_rounded, onTap: () => onReply!.call())),
          ])
        else
          EmptySlim(icon: Icons.visibility_rounded, title: 'Solo lectura', body: 'Tu rol no permite modificar reportes.'),
      ])),
    );
  }
}

class QualityEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const QualityEventCard({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    final profile = AppData.asMap(event['profiles']);
    final group = AppData.asMap(event['groups']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.insights_rounded, color: AppColors.blue, size: 19)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(event['event_type'], 'evento'), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text('${AppData.text(profile['email'], 'usuario')} · ${AppData.text(group['name'], 'sin grupo')} · ${AppData.text(event['screen'], 'app')}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}


class AdminSectionTabs extends StatelessWidget {
  final int index;
  final String role;
  final ValueChanged<int> onChanged;
  const AdminSectionTabs({super.key, required this.index, required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.support_agent_rounded, 'Reportes', AppColors.orange),
      (Icons.people_alt_rounded, 'Usuarios', AppColors.teal),
      (Icons.groups_rounded, 'Grupos', AppColors.violet),
      (Icons.phone_android_rounded, 'Dispositivos', AppColors.blue),
      (Icons.insights_rounded, 'Actividad', AppColors.green),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final selected = index == i;
          final item = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? item.$3 : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? item.$3 : AppColors.line),
                boxShadow: selected ? [BoxShadow(color: item.$3.withOpacity(.22), blurRadius: 14, offset: const Offset(0, 7))] : null,
              ),
              child: Row(children: [
                Icon(item.$1, size: 17, color: selected ? Colors.white : item.$3),
                const SizedBox(width: 7),
                Text(item.$2, style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
              ]),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class AdminUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onBlock;
  final VoidCallback onActivate;
  const AdminUserCard({super.key, required this.user, required this.onBlock, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(user['full_name'], AppData.text(user['email'], 'Usuario'));
    final email = AppData.text(user['email'], 'sin email');
    final status = AppData.text(user['status'], 'active');
    final role = AppData.text(user['admin_role'], '');
    final isBlocked = status == 'blocked';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ProfileAvatar(name: name, avatarUrl: AppData.text(user['avatar_url']), radius: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
            _MiniChip(text: isBlocked ? 'BLOQUEADO' : 'ACTIVO', color: isBlocked ? AppColors.red : AppColors.green),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            if (role.isNotEmpty) _MiniChip(text: role.toUpperCase(), color: role == 'owner' ? AppColors.orange : role == 'support' ? AppColors.teal : AppColors.violet),
            _MiniChip(text: '${AppData.intValue(user['groups_count'])} grupos', color: AppColors.violet),
            _MiniChip(text: '${AppData.intValue(user['devices_count'])} dispositivos', color: AppColors.blue),
            _MiniChip(text: AppData.text(user['last_seen_at']).isEmpty ? 'sin actividad push' : 'push visto', color: AppColors.muted),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SecondaryButton(label: isBlocked ? 'Activar' : 'Bloquear', icon: isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, onTap: isBlocked ? onActivate : onBlock)),
          ]),
        ]),
      ),
    );
  }
}

class AdminGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  const AdminGroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final ownerEmail = AppData.text(group['owner_email'], 'owner no disponible');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.violetSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.groups_rounded, color: AppColors.violet)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('Owner: $ownerEmail', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(spacing: 7, runSpacing: 7, children: [
              _MiniChip(text: '${AppData.intValue(group['members_count'])} miembros', color: AppColors.teal),
              _MiniChip(text: '${AppData.intValue(group['events_count'])} eventos', color: AppColors.orange),
              _MiniChip(text: '${AppData.intValue(group['expenses_count'])} gastos', color: AppColors.green),
              _MiniChip(text: '${AppData.intValue(group['tournaments_count'])} torneos', color: AppColors.red),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class AdminDeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  const AdminDeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final enabled = device['enabled'] != false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: enabled ? AppColors.blueSoft : AppColors.faint, borderRadius: BorderRadius.circular(14)), child: Icon(enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: enabled ? AppColors.blue : AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(device['email'], 'Usuario'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('${AppData.text(device['platform'], 'plataforma')} · ${AppData.text(device['app_version'], AppConfig.appVersion)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 7),
            Wrap(spacing: 7, runSpacing: 7, children: [
              _MiniChip(text: enabled ? 'activo' : 'apagado', color: enabled ? AppColors.green : AppColors.muted),
              _MiniChip(text: AppData.text(device['last_seen_at']).isEmpty ? 'sin last seen' : 'last seen', color: AppColors.blue),
            ]),
          ])),
        ]),
      ),
    );
  }
}

IconData ticketTypeIcon(String type) {
  switch (type) {
    case 'cuenta': return Icons.person_outline_rounded;
    case 'grupo': return Icons.groups_rounded;
    case 'evento': return Icons.event_rounded;
    case 'finanzas': return Icons.account_balance_wallet_rounded;
    case 'torneo': return Icons.emoji_events_rounded;
    case 'sugerencia': return Icons.lightbulb_outline_rounded;
    default: return Icons.bug_report_rounded;
  }
}

String ticketTypeLabel(String type) {
  switch (type) {
    case 'cuenta': return 'Cuenta';
    case 'grupo': return 'Grupo';
    case 'evento': return 'Evento';
    case 'finanzas': return 'Finanzas';
    case 'torneo': return 'Torneo';
    case 'sugerencia': return 'Sugerencia';
    case 'otro': return 'Otro';
    default: return 'Bug';
  }
}

String ticketStatusLabel(String status) {
  switch (status) {
    case 'reviewing': return 'En revisión';
    case 'resolved': return 'Resuelto';
    case 'closed': return 'Cerrado';
    default: return 'Abierto';
  }
}

Color ticketStatusColor(String status) {
  switch (status) {
    case 'reviewing': return AppColors.blue;
    case 'resolved': return AppColors.green;
    case 'closed': return AppColors.muted;
    default: return AppColors.orange;
  }
}

String ticketPriorityLabel(String priority) {
  switch (priority) {
    case 'critical': return 'Crítica';
    case 'high': return 'Alta';
    case 'low': return 'Baja';
    default: return 'Normal';
  }
}

Color ticketPriorityColor(String priority) {
  switch (priority) {
    case 'critical': return AppColors.red;
    case 'high': return AppColors.orange;
    case 'low': return AppColors.muted;
    default: return AppColors.teal;
  }
}


class ProfileScreen extends StatefulWidget {
  final VoidCallback onChanged;
  final ValueChanged<int>? onNavigateRoot;
  const ProfileScreen({super.key, required this.onChanged, this.onNavigateRoot});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> future;
  bool photoLoading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = _ProfileData.load();
  }

  void reload() {
    setState(load);
    widget.onChanged();
  }

  Future<void> editName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre visible',
            hintText: 'Ej. José García',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    if (newName == null) return;
    try {
      await AppData.updateProfileName(newName);
      reload();
      if (mounted) await showToast(context, 'Nombre actualizado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> changePhoto() async {
    if (photoLoading) return;
    setState(() => photoLoading = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (picked == null) return;
      final raw = await picked.readAsBytes();
      if (!mounted) return;
      final framed = await Navigator.of(context).push<Uint8List>(MaterialPageRoute(
        builder: (_) => ImageFrameEditorScreen(
          bytes: raw,
          title: 'Ajustar foto',
          helper: 'Arrastra y pellizca para centrar tu foto dentro del círculo.',
          aspectRatio: 1,
          outputWidth: 900,
          circularPreview: true,
        ),
      ));
      if (framed == null) return;
      await AppData.uploadAvatarBytes(framed, 'avatar.png');
      reload();
      if (mounted) await showToast(context, 'Foto actualizada.');
    } catch (e) {
      if (mounted) {
        await showToast(context, 'No se ha podido subir la foto. Inténtalo de nuevo.', danger: true);
      }
    } finally {
      if (mounted) setState(() => photoLoading = false);
    }
  }

  Future<void> removePhoto() async {
    final ok = await confirmAction(
      context,
      title: '¿Quitar foto?',
      body: 'Volverás al avatar con iniciales. Puedes subir otra foto cuando quieras.',
      danger: true,
    );
    if (ok != true) return;
    try {
      await AppData.removeAvatar();
      reload();
      if (mounted) await showToast(context, 'Foto eliminada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> confirmSignOut() async {
    final ok = await confirmAction(
      context,
      title: '¿Cerrar sesión?',
      body: 'Podrás volver a entrar con tu correo cuando quieras.',
      danger: true,
      confirmLabel: 'Cerrar sesión',
    );
    if (ok != true) return;
    await AppData.sb.auth.signOut();
  }

  Future<void> deleteAccountFlow() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta acción elimina tu cuenta de Grupli, tu perfil, tu foto, tus dispositivos, tus avisos y tu acceso a los grupos.'),
            const SizedBox(height: 10),
            const Text('Si eres owner de algún grupo, esos grupos también se eliminarán con sus eventos, gastos y torneos.'),
            const SizedBox(height: 14),
            const Text('Escribe ELIMINAR para confirmar.', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'ELIMINAR'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, controller.text.trim().toUpperCase() == 'ELIMINAR'),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    final typed = controller.text;
    controller.dispose();
    if (confirmed != true) {
      if (typed.trim().isNotEmpty && mounted) {
        await showToast(context, 'Para eliminar la cuenta debes escribir ELIMINAR exactamente.', danger: true);
      }
      return;
    }

    try {
      await AppData.deleteMyAccount('ELIMINAR');
      if (mounted) await showToast(context, 'Cuenta eliminada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  void showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
            child: FutureBuilder<Map<String, dynamic>>(
              future: AppData.notificationSettings(),
              builder: (context, snapshot) {
                final settings = snapshot.data ?? {};
                bool enabled(String key) => settings[key] != false;
                Future<void> toggle(String key, bool value) async {
                  await AppData.updateNotificationSettings({key: value});
                  setSheetState(() {});
                }
                return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SheetTitle(icon: Icons.notifications_active_outlined, title: 'Notificaciones', body: 'Elige qué avisos quieres recibir de tus grupos.'),
                  const SizedBox(height: 12),
                  NotificationPreferenceSwitch(icon: Icons.event_available_rounded, title: 'Eventos', body: 'Nuevas quedadas, cambios y cancelaciones', value: enabled('notify_events'), onChanged: (v) => toggle('notify_events', v)),
                  NotificationPreferenceSwitch(icon: Icons.account_balance_wallet_rounded, title: 'Finanzas', body: 'Gastos nuevos y pagos importantes', value: enabled('notify_expenses'), onChanged: (v) => toggle('notify_expenses', v)),
                  NotificationPreferenceSwitch(icon: Icons.emoji_events_rounded, title: 'Torneos', body: 'Torneos, partidos y resultados', value: enabled('notify_tournaments'), onChanged: (v) => toggle('notify_tournaments', v)),
                  NotificationPreferenceSwitch(icon: Icons.groups_rounded, title: 'Miembros', body: 'Entradas al grupo y cambios de rol', value: enabled('notify_members'), onChanged: (v) => toggle('notify_members', v)),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Activar push en este dispositivo', icon: Icons.notifications_active_rounded, onTap: () async {
                    final token = await PushNotificationService.enableForCurrentDevice();
                    if (!mounted) return;
                    if (token == null) {
                      await showToast(context, 'No se pudieron activar las notificaciones en este dispositivo.', danger: true);
                    } else {
                      await showToast(context, 'Notificaciones activadas en este dispositivo.');
                    }
                  }),
                ]);
              },
            ),
          );
        },
      ),
    );
  }

  void showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
          SheetTitle(icon: Icons.lock_outline_rounded, title: 'Privacidad y seguridad', body: 'Grupli está pensada para grupos cerrados. Nadie entra sin invitación o código.'),
          SizedBox(height: 12),
          PreferencePreviewRow(icon: Icons.verified_user_rounded, title: 'Cuenta protegida', body: 'Acceso seguro y sesión privada'),
          PreferencePreviewRow(icon: Icons.groups_rounded, title: 'Grupos privados', body: 'El contenido del grupo queda limitado a sus miembros'),
          PreferencePreviewRow(icon: Icons.admin_panel_settings_rounded, title: 'Roles claros', body: 'Owner, admins y miembros tienen permisos separados'),
          PreferencePreviewRow(icon: Icons.delete_outline_rounded, title: 'Eliminación de cuenta', body: 'Puedes iniciar el borrado de cuenta desde Perfil con confirmación explícita'),
        ]),
      ),
    );
  }

  Future<void> openSupport() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportTicketScreen(screen: 'perfil')));
    reload();
  }

  Future<void> openAdminPanel() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    reload();
  }

  Future<void> openProfileGroup(Map<String, dynamic> group) async {
    final groupId = group['id']?.toString() ?? '';
    if (groupId.isEmpty) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId)));
    reload();
  }

  Future<void> openAllGroups(List<Map<String, dynamic>> groups) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfileAllGroupsScreen(groups: groups, onOpenGroup: openProfileGroup),
    ));
    reload();
  }

  void goBackFromProfile() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    widget.onNavigateRoot?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      child: FutureBuilder<_ProfileData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CenterLoader(label: 'Cargando perfil...');
          }
          if (snapshot.hasError) {
            return ErrorBlock(message: humanError(snapshot.error), onRetry: reload);
          }

          final data = snapshot.data ?? _ProfileData.empty();
          final name = data.name;
          final email = data.email;
          final avatarUrl = data.avatarUrl;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              RoundBackButton(onTap: goBackFromProfile),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Perfil', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Tu cuenta, foto, grupos y ajustes básicos.', style: Theme.of(context).textTheme.bodyMedium),
              ])),
              CircleIconButton(icon: Icons.refresh_rounded, onTap: reload),
            ]),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(children: [
                Stack(alignment: Alignment.bottomRight, children: [
                  ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 54),
                  Material(
                    color: AppColors.teal,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: changePhoto,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: photoLoading
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
              ]),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: 'Cuenta'),
            const SizedBox(height: 8),
            SettingsRow(icon: Icons.edit_rounded, title: 'Nombre visible', subtitle: name, onTap: () => editName(name)),
            SettingsRow(icon: Icons.photo_camera_rounded, title: 'Cambiar foto', subtitle: photoLoading ? 'Subiendo imagen...' : 'Elige una imagen de tu dispositivo', onTap: changePhoto),
            if (avatarUrl.isNotEmpty)
              SettingsRow(icon: Icons.delete_outline_rounded, title: 'Quitar foto', subtitle: 'Volver al avatar con iniciales', danger: true, onTap: removePhoto),
            const SizedBox(height: 8),
            SectionHeader(title: 'Tus grupos', action: 'Ver todos', onTap: () => openAllGroups(data.groups)),
            const SizedBox(height: 8),
            if (data.groups.isEmpty)
              EmptySlim(icon: Icons.groups_rounded, title: 'Aún no tienes grupos', body: 'Crea o únete a un grupo desde Inicio.')
            else
              ...data.groups.take(3).map((group) => ProfileGroupMiniCard(group: group, onTap: () => openProfileGroup(group))),
            if (data.groups.length > 3)
              SettingsRow(icon: Icons.more_horiz_rounded, title: 'Ver todos los grupos', subtitle: '${data.groups.length} grupos en total', onTap: () => openAllGroups(data.groups)),
            const SizedBox(height: 8),
            SectionHeader(title: 'Ajustes'),
            const SizedBox(height: 8),
            SettingsRow(icon: Icons.notifications_none_rounded, title: 'Notificaciones', subtitle: 'Eventos, gastos y torneos', onTap: showNotificationsSheet),
            SettingsRow(icon: Icons.language_rounded, title: 'Idioma', subtitle: 'Español', onTap: () => showToast(context, 'El selector de idioma llegará en una próxima versión.')),
            SettingsRow(icon: Icons.lock_outline_rounded, title: 'Privacidad y seguridad', subtitle: 'Grupos cerrados, roles y acceso privado', onTap: showPrivacySheet),
            SettingsRow(icon: Icons.help_outline_rounded, title: 'Ayuda y soporte', subtitle: 'Reportar bugs, dudas o sugerencias', onTap: openSupport),
            if (data.isAdmin)
              SettingsRow(icon: Icons.admin_panel_settings_rounded, title: 'Panel admin', subtitle: 'Roles, reportes, métricas y calidad de Grupli', onTap: openAdminPanel),
            SettingsRow(icon: Icons.delete_forever_rounded, title: 'Eliminar cuenta', subtitle: 'Borra tu cuenta y datos personales de Grupli', danger: true, onTap: deleteAccountFlow),
            const SizedBox(height: 10),
            DangerButton(label: 'Cerrar sesión', icon: Icons.logout_rounded, onTap: confirmSignOut),
          ]);
        },
      ),
    );
  }
}

class ProfileAllGroupsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final Future<void> Function(Map<String, dynamic> group) onOpenGroup;
  const ProfileAllGroupsScreen({super.key, required this.groups, required this.onOpenGroup});

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader(title: 'Tus grupos', subtitle: '${groups.length} grupos en total. Toca uno para abrirlo.', leading: true),
        const SizedBox(height: 14),
        if (groups.isEmpty)
          EmptyBlock(icon: Icons.groups_rounded, title: 'Aún no tienes grupos', body: 'Crea o únete a un grupo desde Inicio.')
        else
          ...groups.map((group) => ProfileGroupMiniCard(group: group, onTap: () => onOpenGroup(group))),
      ]),
    );
  }
}

class _ProfileData {
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> groups;
  final bool isAdmin;

  const _ProfileData({required this.profile, required this.groups, this.isAdmin = false});

  static _ProfileData empty() => const _ProfileData(profile: {}, groups: [], isAdmin: false);

  static Future<_ProfileData> load() async {
    final results = await Future.wait([
      AppData.profile(),
      AppData.myGroups(),
      AppData.isSuperAdmin(),
    ]);
    return _ProfileData(
      profile: AppData.asMap(results[0]),
      groups: AppData.asList(results[1]),
      isAdmin: results[2] == true,
    );
  }

  String get email => AppData.text(profile['email'], AppData.user?.email ?? '');
  String get name {
    final fromProfile = AppData.text(profile['full_name']);
    if (fromProfile.isNotEmpty && fromProfile != 'Usuario') return fromProfile;
    final e = email;
    if (e.contains('@')) return e.split('@').first;
    return 'Usuario';
  }

  String get avatarUrl => AppData.text(profile['avatar_url']);

  int get adminGroups => groups.where((g) => ['owner', 'admin'].contains(AppData.text(g['role']))).length;
  int get totalEvents => groups.fold<int>(0, (sum, g) => sum + AppData.intValue(g['events_count']));
}



class ProfileAvatar extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double radius;
  const ProfileAvatar({super.key, required this.name, required this.avatarUrl, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final initials = initialsFor(name);
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.tealSoft,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
        child: const SizedBox.shrink(),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.tealSoft,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.teal,
          fontWeight: FontWeight.w900,
          fontSize: radius * .58,
        ),
      ),
    );
  }
}

class TinyStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const TinyStat({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.faint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.teal, size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class AccountStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const AccountStatusPill({super.key, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withOpacity(.18))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    ]),
  );
}

class ProfileGroupMiniCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  const ProfileGroupMiniCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final role = AppData.text(group['role'], 'member');
    final members = AppData.intValue(group['members_count'], 1);
    final events = AppData.intValue(group['events_count'], 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.groups_rounded, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
              RoleBadge(role: role),
            ]),
            const SizedBox(height: 4),
            Text('$members miembros · $events eventos', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const SheetTitle({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: AppColors.teal),
    ),
    const SizedBox(height: 12),
    Text(title, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 6),
    Text(body, style: Theme.of(context).textTheme.bodyMedium),
  ]);
}

class PreferencePreviewRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const PreferencePreviewRow({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(children: [
        Icon(icon, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ])),
      ]),
    ),
  );
}



class NotificationPreferenceSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;
  const NotificationPreferenceSwitch({super.key, required this.icon, required this.title, required this.body, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.teal, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ])),
        Switch(value: value, activeColor: AppColors.teal, onChanged: onChanged),
      ]),
    ),
  );
}


class SmartPromptCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;
  const SmartPromptCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surface,
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 9),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(actionLabel, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 18, color: color),
              ]),
            ),
          ),
        ])),
      ]),
    );
  }
}

void showGroupQuickActionsSheet(
  BuildContext context, {
  required Map<String, dynamic> group,
  required VoidCallback onSettings,
  required VoidCallback onMembers,
  required VoidCallback onMore,
  required VoidCallback onReport,
}) {
  final name = AppData.text(group['name'], 'Grupo');
  final code = AppData.text(group['invite_code'], '------');
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x1C061A2A), blurRadius: 32, offset: Offset(0, 14))]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.tune_rounded, color: AppColors.teal)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              const Text('Acciones rápidas del grupo', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 12),
          SettingsRow(icon: Icons.edit_rounded, title: 'Editar grupo', subtitle: 'Nombre, portada y ajustes', onTap: () { Navigator.pop(sheetContext); onSettings(); }),
          SettingsRow(icon: Icons.groups_rounded, title: 'Miembros', subtitle: 'Roles, admins y expulsiones', onTap: () { Navigator.pop(sheetContext); onMembers(); }),
          SettingsRow(icon: Icons.link_rounded, title: 'Copiar enlace', subtitle: InviteLinks.joinUrl(code), onTap: () { Navigator.pop(sheetContext); copyInviteLink(context, code); }),
          SettingsRow(icon: Icons.share_rounded, title: 'Compartir invitación', subtitle: 'Enviar por WhatsApp u otra app', onTap: () { Navigator.pop(sheetContext); Share.share(inviteText(name, code)); }),
          SettingsRow(icon: Icons.more_horiz_rounded, title: 'Ver todo', subtitle: 'Invitaciones, permisos y privacidad', onTap: () { Navigator.pop(sheetContext); onMore(); }),
          SettingsRow(icon: Icons.support_agent_rounded, title: 'Reportar problema', subtitle: 'Enviar incidencia sobre este grupo', onTap: () { Navigator.pop(sheetContext); onReport(); }),
        ]),
      ),
    ),
  );
}
