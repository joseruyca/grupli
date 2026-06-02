import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/buttons.dart';
import '../../../ui/confirm_dialog.dart';
import '../../../ui/group_page_scaffold.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/mock_ui.dart';
import '../../../ui/toast.dart';
import '../../../shared/utils/safe_values.dart';
import '../groups_repository.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = GroupsRepository().getGroup(widget.groupId);
  }

  void _refresh() => setState(() => _future = GroupsRepository().getGroup(widget.groupId));

  Future<void> _copyCode(String code) async {
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) AppToast.show(context, 'Código copiado.');
  }

  Future<void> _shareCode(String code) async {
    if (code.isEmpty) return;
    await Share.share('Únete a mi grupo privado en Grupli con este código: $code');
  }

  Future<void> _regenerate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final code = await GroupsRepository().regenerateCode(widget.groupId);
      if (mounted) AppToast.show(context, 'Nuevo código: $code');
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final ok = await showConfirmDialog(context, title: 'Salir del grupo', message: 'Dejarás de ver este grupo y su información.', confirmLabel: 'Salir');
    if (!ok) return;
    try {
      await GroupsRepository().leaveGroup(widget.groupId);
      if (mounted) context.go('/app');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(context, title: 'Eliminar grupo', message: 'Esta acción borra eventos, asistencias, gastos, torneos y miembros de este grupo.', confirmLabel: 'Eliminar');
    if (!ok) return;
    try {
      await GroupsRepository().deleteGroup(widget.groupId);
      if (mounted) context.go('/app');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GroupPageScaffold(
      groupId: widget.groupId,
      navIndex: 4,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState(label: 'Cargando grupo...');
          if (snapshot.hasError) return MockCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));
          if (!snapshot.hasData || snapshot.data == null) {
            return MockCard(child: Text('No se pudo cargar este grupo. Vuelve atrás y entra de nuevo.', style: AppTypography.body));
          }

          final g = snapshot.data!;
          final name = SafeValue.toText(g['name'], 'Grupo');
          final code = SafeValue.toText(g['invite_code'], '');
          final role = SafeValue.toText(g['my_role'], 'member');
          final isOwner = role == 'owner';
          final isAdmin = role == 'owner' || role == 'admin';
          final members = SafeValue.toInt(g['members_count']);
          final nextEvents = SafeValue.toInt(g['next_events_count']);
          final expenses = SafeValue.toInt(g['expenses_count']);
          final tournaments = SafeValue.toInt(g['active_tournaments_count']);

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Hero(name: name, members: members, onBack: () => context.go('/app'), onMenu: () => context.go('/app/groups/${widget.groupId}/edit')),
            const SizedBox(height: 12),
            _QuickActions(groupId: widget.groupId, onCopy: () => _copyCode(code), onShare: () => _shareCode(code)),
            const SizedBox(height: 18),
            _ActivityCard(code: code, nextEvents: nextEvents, expenses: expenses, onCopy: () => _copyCode(code), onShare: () => _shareCode(code)),
            const SizedBox(height: 18),
            MockSectionTitle(title: 'Funciones principales'),
            const SizedBox(height: 8),
            _FunctionList(groupId: widget.groupId, nextEvents: nextEvents, expenses: expenses, tournaments: tournaments),
            const SizedBox(height: 18),
            MockSectionTitle(title: 'Más del grupo'),
            const SizedBox(height: 8),
            MockRowTile(icon: Icons.group_rounded, title: 'Miembros', subtitle: '$members personas · admins y permisos', onTap: () => context.go('/app/groups/${widget.groupId}/members')),
            const SizedBox(height: 10),
            if (isAdmin) ...[
              MockRowTile(icon: Icons.tune_rounded, color: AppColors.lilac, title: 'Ajustes del grupo', subtitle: 'Nombre, permisos e invitaciones', onTap: () => context.go('/app/groups/${widget.groupId}/edit')),
              const SizedBox(height: 10),
              MockRowTile(icon: Icons.sync_lock_rounded, color: AppColors.amber, title: 'Regenerar código', subtitle: 'Invalida el código anterior', onTap: _regenerate),
              const SizedBox(height: 14),
            ],
            if (isOwner) DestructiveButton(label: 'Eliminar grupo', onPressed: _delete) else DestructiveButton(label: 'Salir del grupo', onPressed: _leave),
          ]);
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String name;
  final int members;
  final VoidCallback onBack;
  final VoidCallback onMenu;
  const _Hero({required this.name, required this.members, required this.onBack, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D8F89), Color(0xFF0F4061)])),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _HeroPatternPainter())),
        Positioned(left: 12, top: 12, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), color: Colors.white, style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.20)))),
        Positioned(right: 12, top: 12, child: IconButton(onPressed: onMenu, icon: const Icon(Icons.more_horiz_rounded), color: Colors.white, style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.20)))),
        Positioned(left: 18, right: 18, bottom: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.title.copyWith(fontSize: 28, color: Colors.white)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.lock_rounded, color: Colors.white70, size: 15),
            const SizedBox(width: 5),
            Text('$members miembros · Grupo privado', style: AppTypography.small.copyWith(color: Colors.white.withOpacity(0.86))),
          ]),
        ])),
      ]),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.10)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(Offset(size.width * (0.15 + i * 0.14), size.height * (0.20 + (i % 3) * 0.16)), 18 + i.toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickActions extends StatelessWidget {
  final String groupId;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  const _QuickActions({required this.groupId, required this.onCopy, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _QuickAction(icon: Icons.person_add_alt_1_rounded, label: 'Invitar', onTap: onShare)),
      const SizedBox(width: 8),
      Expanded(child: _QuickAction(icon: Icons.qr_code_2_rounded, label: 'Código', onTap: onCopy)),
      const SizedBox(width: 8),
      Expanded(child: _QuickAction(icon: Icons.group_rounded, label: 'Miembros', onTap: () => context.go('/app/groups/$groupId/members'))),
      const SizedBox(width: 8),
      Expanded(child: _QuickAction(icon: Icons.settings_rounded, label: 'Ajustes', onTap: () => context.go('/app/groups/$groupId/edit'))),
    ]);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MockCard(
      padding: const EdgeInsets.symmetric(vertical: 11),
      onTap: onTap,
      child: Column(children: [Icon(icon, color: AppColors.tealDark, size: 21), const SizedBox(height: 5), Text(label, style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 11))]),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String code;
  final int nextEvents;
  final int expenses;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  const _ActivityCard({required this.code, required this.nextEvents, required this.expenses, required this.onCopy, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return MockCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Actividad reciente', style: AppTypography.section.copyWith(fontSize: 17)),
        const SizedBox(height: 10),
        _TinyActivity(icon: Icons.event_available_rounded, text: nextEvents == 0 ? 'Aún no hay próximas quedadas' : '$nextEvents próximas quedadas'),
        const SizedBox(height: 8),
        _TinyActivity(icon: Icons.receipt_long_rounded, text: expenses == 0 ? 'Sin gastos registrados' : '$expenses gastos registrados'),
        const Divider(height: 22),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Código', style: AppTypography.small), SelectableText(code.isEmpty ? 'SIN CÓDIGO' : code, style: AppTypography.section.copyWith(fontSize: 18, letterSpacing: 1))])),
          IconButton(onPressed: onCopy, icon: const Icon(Icons.copy_rounded), color: AppColors.tealDark),
          IconButton(onPressed: onShare, icon: const Icon(Icons.ios_share_rounded), color: AppColors.tealDark),
        ]),
      ]),
    );
  }
}

class _TinyActivity extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TinyActivity({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: AppColors.tealDark, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: AppTypography.small.copyWith(color: AppColors.navy)))]);
  }
}

class _FunctionList extends StatelessWidget {
  final String groupId;
  final int nextEvents;
  final int expenses;
  final int tournaments;
  const _FunctionList({required this.groupId, required this.nextEvents, required this.expenses, required this.tournaments});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _FunctionCard(icon: Icons.event_available_rounded, title: 'Eventos', subtitle: 'Quedadas y asistencia', badge: nextEvents == 0 ? 'Crear' : '$nextEvents próximas', color: AppColors.teal, onTap: () => context.go('/app/groups/$groupId/events'))),
        const SizedBox(width: 10),
        Expanded(child: _FunctionCard(icon: Icons.calendar_month_rounded, title: 'Calendario', subtitle: 'Vista mensual', badge: 'Abrir', color: AppColors.lilac, onTap: () => context.go('/app/groups/$groupId/calendar'))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _FunctionCard(icon: Icons.account_balance_wallet_rounded, title: 'Finanzas', subtitle: 'Gastos y saldos', badge: expenses == 0 ? 'Sin gastos' : '$expenses gastos', color: AppColors.success, onTap: () => context.go('/app/groups/$groupId/finances'))),
        const SizedBox(width: 10),
        Expanded(child: _FunctionCard(icon: Icons.emoji_events_rounded, title: 'Torneos', subtitle: 'Ligas y resultados', badge: tournaments == 0 ? 'Crear' : '$tournaments activos', color: AppColors.amber, onTap: () => context.go('/app/groups/$groupId/tournaments'))),
      ]),
    ]);
  }
}

class _FunctionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;
  const _FunctionCard({required this.icon, required this.title, required this.subtitle, required this.badge, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MockCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.small),
        const SizedBox(height: 10),
        MockPill(label: badge, color: color),
      ]),
    );
  }
}
