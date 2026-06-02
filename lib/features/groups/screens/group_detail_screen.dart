import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/action_tile.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/buttons.dart';
import '../../../ui/confirm_dialog.dart';
import '../../../ui/group_bottom_nav.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/status_chip.dart';
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
    final ok = await showConfirmDialog(
      context,
      title: 'Salir del grupo',
      message: 'Dejarás de ver este grupo y su información.',
      confirmLabel: 'Salir',
    );
    if (!ok) return;
    try {
      await GroupsRepository().leaveGroup(widget.groupId);
      if (mounted) context.go('/app');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar grupo',
      message: 'Esta acción borra eventos, asistencias, gastos, torneos y miembros de este grupo.',
      confirmLabel: 'Eliminar',
    );
    if (!ok) return;
    try {
      await GroupsRepository().deleteGroup(widget.groupId);
      if (mounted) context.go('/app');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  String _roleLabel(String role) {
    if (role == 'owner') return 'Creador';
    if (role == 'admin') return 'Admin';
    return 'Miembro';
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      bottomNavigationBar: GroupBottomNav(groupId: widget.groupId, index: 4),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState(label: 'Cargando grupo...');
          if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));

          final g = snapshot.data!;
          final name = SafeValue.toText(g['name'], 'Grupo');
          final code = SafeValue.toText(g['invite_code'], '');
          final role = SafeValue.toText(g['my_role'], 'member');
          final isAdmin = role == 'owner' || role == 'admin';
          final isOwner = role == 'owner';
          final membersCount = SafeValue.toInt(g['members_count']);
          final nextEvents = SafeValue.toInt(g['next_events_count']);
          final expenses = SafeValue.toInt(g['expenses_count']);
          final activeTournaments = SafeValue.toInt(g['active_tournaments_count']);

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _GroupHero(
              name: name,
              role: _roleLabel(role),
              members: membersCount,
              onBack: () => context.go('/app'),
              onMenu: () {},
            ),
            const SizedBox(height: 14),
            _QuickActions(
              groupId: widget.groupId,
              onCopy: () => _copyCode(code),
              onShare: () => _shareCode(code),
            ),
            const SizedBox(height: 16),
            _InviteCard(code: code, onCopy: () => _copyCode(code), onShare: () => _shareCode(code)),
            const SizedBox(height: 16),
            SectionTitle(title: 'Organización del grupo'),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
              children: [
                _FeatureCard(
                  title: 'Eventos',
                  subtitle: 'Quedadas y asistencia',
                  footer: nextEvents == 0 ? 'Sin próximas' : '$nextEvents próximas',
                  icon: Icons.event_available_rounded,
                  color: AppColors.teal,
                  onTap: () => context.go('/app/groups/${widget.groupId}/events'),
                ),
                _FeatureCard(
                  title: 'Calendario',
                  subtitle: 'Agenda mensual',
                  footer: 'Ver agenda',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.lilac,
                  onTap: () => context.go('/app/groups/${widget.groupId}/calendar'),
                ),
                _FeatureCard(
                  title: 'Finanzas',
                  subtitle: 'Gastos y balances',
                  footer: expenses == 0 ? 'Sin gastos' : '$expenses gastos',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.success,
                  onTap: () => context.go('/app/groups/${widget.groupId}/finances'),
                ),
                _FeatureCard(
                  title: 'Torneos',
                  subtitle: 'Ligas y resultados',
                  footer: activeTournaments == 0 ? 'Sin torneos' : '$activeTournaments activos',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.amber,
                  onTap: () => context.go('/app/groups/${widget.groupId}/tournaments'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionTitle(title: 'Administración'),
            const SizedBox(height: AppSpacing.sm),
            ActionTile(
              title: 'Miembros',
              subtitle: '$membersCount personas · admins y permisos',
              icon: Icons.group_rounded,
              color: AppColors.teal,
              onTap: () => context.go('/app/groups/${widget.groupId}/members'),
            ),
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.sm),
              ActionTile(
                title: 'Editar grupo',
                subtitle: 'Cambiar nombre y preparar invitaciones',
                icon: Icons.tune_rounded,
                color: AppColors.lilac,
                onTap: () => context.go('/app/groups/${widget.groupId}/edit'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActionTile(
                title: 'Regenerar código',
                subtitle: 'Cerrar el código antiguo y crear uno nuevo',
                icon: Icons.sync_lock_rounded,
                color: AppColors.amber,
                onTap: _regenerate,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (isOwner)
              DestructiveButton(label: 'Eliminar grupo', onPressed: _delete)
            else
              DestructiveButton(label: 'Salir del grupo', onPressed: _leave),
          ]);
        },
      ),
    );
  }
}

class _GroupHero extends StatelessWidget {
  final String name;
  final String role;
  final int members;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  const _GroupHero({required this.name, required this.role, required this.members, required this.onBack, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 186,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7F7B), Color(0xFF0A4F63)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(right: -26, top: -26, child: Icon(Icons.groups_rounded, size: 156, color: Colors.white.withOpacity(0.08))),
        Positioned(left: 16, top: 14, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), color: Colors.white, style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.18)))),
        Positioned(right: 16, top: 14, child: IconButton(onPressed: onMenu, icon: const Icon(Icons.more_horiz_rounded), color: Colors.white, style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.18)))),
        Positioned(
          left: 20,
          right: 20,
          bottom: 22,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.title.copyWith(fontSize: 30, color: Colors.white))),
              const SizedBox(width: 8),
              const Icon(Icons.lock_rounded, color: Colors.white70, size: 18),
            ]),
            const SizedBox(height: 8),
            Text('$members miembros · Grupo privado · $role', style: AppTypography.body.copyWith(color: Colors.white.withOpacity(0.86), fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
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
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Icon(icon, color: AppColors.tealDark, size: 22),
            const SizedBox(height: 5),
            Text(label, style: AppTypography.small.copyWith(color: AppColors.navy)),
          ]),
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  const _InviteCard({required this.code, required this.onCopy, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        const SoftIconBox(icon: Icons.lock_rounded, color: AppColors.teal, size: 42),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Código de invitación', style: AppTypography.small),
          const SizedBox(height: 3),
          SelectableText(code.isEmpty ? 'Sin código' : code, style: AppTypography.section.copyWith(fontSize: 18, letterSpacing: 1)),
        ])),
        IconButton(onPressed: onCopy, icon: const Icon(Icons.copy_rounded), color: AppColors.tealDark),
        IconButton(onPressed: onShare, icon: const Icon(Icons.ios_share_rounded), color: AppColors.tealDark),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String footer;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({required this.title, required this.subtitle, required this.footer, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SoftIconBox(icon: icon, color: color, size: 38),
        const SizedBox(height: 10),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.small),
        const Spacer(),
        Text(footer, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.small.copyWith(color: color)),
      ]),
    );
  }
}
