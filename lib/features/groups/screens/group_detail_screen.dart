import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/action_tile.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';
import '../../../ui/confirm_dialog.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/stat_card.dart';
import '../../../ui/status_chip.dart';
import '../../../ui/toast.dart';
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
      message: 'Solo el propietario puede eliminar el grupo. Esta acción borra eventos, gastos y torneos del grupo.',
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

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
          if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));
          final g = snapshot.data!;
          final code = (g['invite_code'] ?? '').toString();
          final role = (g['my_role'] ?? 'member').toString();
          final isAdmin = role == 'owner' || role == 'admin';
          final isOwner = role == 'owner';
          final membersCount = g['members_count'] ?? 0;

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppHeader(
              title: g['name'] ?? 'Grupo',
              subtitle: '${g['type'] ?? 'otro'} · ${g['privacy'] ?? 'privado'}',
              showBack: true,
              trailing: IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const StatusChip(label: 'Código'),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(code.isEmpty ? 'Sin código' : code, style: AppTypography.title)),
                  IconButton(onPressed: () => _copyCode(code), icon: const Icon(Icons.copy_rounded)),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Text('Comparte este código para que otros miembros entren al grupo.', style: AppTypography.muted),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Compartir invitación',
                      icon: Icons.ios_share_rounded,
                      onPressed: code.isEmpty ? null : () => Share.share('Únete a mi grupo en Grupli con el código: $code'),
                    ),
                  ),
                ]),
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: _busy ? null : _regenerate,
                    icon: const Icon(Icons.autorenew_rounded),
                    label: const Text('Regenerar código'),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(child: StatCard(label: 'Rol', value: role, icon: Icons.verified_user_rounded)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: StatCard(label: 'Miembros', value: '$membersCount', icon: Icons.people_alt_rounded)),
            ]),
            const SizedBox(height: AppSpacing.lg),
            ActionTile(title: 'Calendario', subtitle: 'Quedadas, asistencia y habituales.', icon: Icons.calendar_month_rounded, onTap: () => context.go('/app/groups/${widget.groupId}/calendar')),
            const SizedBox(height: AppSpacing.md),
            ActionTile(title: 'Finanzas', subtitle: 'Gastos, balances y saldos.', icon: Icons.account_balance_wallet_rounded, color: AppColors.coral, onTap: () => context.go('/app/groups/${widget.groupId}/finances')),
            const SizedBox(height: AppSpacing.md),
            ActionTile(title: 'Torneos', subtitle: 'Equipos, partidos y clasificación.', icon: Icons.emoji_events_rounded, color: AppColors.lilac, onTap: () => context.go('/app/groups/${widget.groupId}/tournaments')),
            const SizedBox(height: AppSpacing.md),
            ActionTile(title: 'Miembros', subtitle: 'Roles, admins y expulsiones.', icon: Icons.group_rounded, onTap: () => context.go('/app/groups/${widget.groupId}/members')),
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.md),
              ActionTile(title: 'Editar grupo', subtitle: 'Nombre, tipo, días, hora y ubicación.', icon: Icons.edit_rounded, onTap: () => context.go('/app/groups/${widget.groupId}/edit')),
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
