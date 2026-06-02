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
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/buttons.dart';
import '../../../ui/confirm_dialog.dart';
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
    await Share.share('Únete a mi grupo privado en Grupli con el código: $code');
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

  String _prettyRole(String role) {
    switch (role) {
      case 'owner':
        return 'Eres owner';
      case 'admin':
        return 'Eres admin';
      default:
        return 'Miembro';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return AppColors.amber;
      case 'admin':
        return AppColors.success;
      default:
        return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState(label: 'Cargando grupo...');
          if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));

          final g = snapshot.data!;
          final code = SafeValue.toText(g['invite_code'], '');
          final role = SafeValue.toText(g['my_role'], 'member');
          final isAdmin = role == 'owner' || role == 'admin';
          final isOwner = role == 'owner';
          final membersCount = SafeValue.toInt(g['members_count']);
          final name = SafeValue.toText(g['name'], 'Grupo');

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppHeader(
              title: 'Grupo privado',
              subtitle: 'Todo dentro de este grupo es cerrado y solo accesible para miembros.',
              showBack: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'refresh') _refresh();
                  if (v == 'regenerate') _regenerate();
                  if (v == 'edit') context.go('/app/groups/${widget.groupId}/edit');
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'refresh', child: Text('Actualizar')),
                  if (isAdmin) const PopupMenuItem(value: 'edit', child: Text('Editar nombre')),
                  if (isAdmin) const PopupMenuItem(value: 'regenerate', child: Text('Regenerar código')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _HeroGroupCard(
              name: name,
              roleLabel: _prettyRole(role),
              roleColor: _roleColor(role),
            ),

            const SizedBox(height: AppSpacing.md),
            _InviteCodeCard(
              code: code,
              onCopy: () => _copyCode(code),
              onShare: () => _shareCode(code),
            ),

            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(child: _SummaryTile(label: 'Miembros', value: '$membersCount', helper: 'personas dentro', icon: Icons.groups_rounded, color: AppColors.teal)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _SummaryTile(label: 'Acceso', value: 'Privado', helper: 'solo con invitación', icon: Icons.lock_outline_rounded, color: AppColors.lilac)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _SummaryTile(label: 'Código', value: code.isEmpty ? '—' : code, helper: 'para entrar al grupo', icon: Icons.qr_code_2_rounded, color: AppColors.amber)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _SummaryTile(label: 'Tu rol', value: role == 'owner' ? 'Owner' : role == 'admin' ? 'Admin' : 'Miembro', helper: 'permisos actuales', icon: Icons.verified_user_outlined, color: AppColors.success)),
            ]),

            const SizedBox(height: AppSpacing.lg),
            SectionTitle(title: 'Accesos rápidos'),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
              children: [
                _QuickCard(title: 'Calendario', subtitle: 'Quedadas y asistencia', icon: Icons.calendar_month_rounded, color: AppColors.teal, onTap: () => context.go('/app/groups/${widget.groupId}/calendar')),
                _QuickCard(title: 'Finanzas', subtitle: 'Gastos y balances', icon: Icons.account_balance_wallet_rounded, color: AppColors.success, onTap: () => context.go('/app/groups/${widget.groupId}/finances')),
                _QuickCard(title: 'Torneos', subtitle: 'Competiciones', icon: Icons.emoji_events_rounded, color: AppColors.lilac, onTap: () => context.go('/app/groups/${widget.groupId}/tournaments')),
                _QuickCard(title: 'Miembros', subtitle: '$membersCount miembros', icon: Icons.group_rounded, color: AppColors.amber, onTap: () => context.go('/app/groups/${widget.groupId}/members')),
              ],
            ),

            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.md),
              ActionTile(
                title: 'Editar nombre',
                subtitle: 'El grupo seguirá siendo privado y cerrado.',
                icon: Icons.edit_rounded,
                onTap: () => context.go('/app/groups/${widget.groupId}/edit'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActionTile(
                title: 'Regenerar código',
                subtitle: 'Crea un nuevo código si el actual se ha compartido demasiado.',
                icon: Icons.refresh_rounded,
                onTap: _regenerate,
                color: AppColors.amber,
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

class _HeroGroupCard extends StatelessWidget {
  final String name;
  final String roleLabel;
  final Color roleColor;

  const _HeroGroupCard({
    required this.name,
    required this.roleLabel,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(color: AppColors.mintSoft, shape: BoxShape.circle),
          child: const Icon(Icons.groups_2_rounded, color: AppColors.navy, size: 32),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTypography.section.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 8, runSpacing: 8, children: [
              StatusChip(label: roleLabel, color: roleColor),
              const StatusChip(label: 'Privado', color: AppColors.teal),
              const StatusChip(label: 'Cerrado', color: AppColors.textMuted),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _InviteCodeCard({required this.code, required this.onCopy, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.canvasWarm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SoftIconBox(icon: Icons.qr_code_2_rounded, color: AppColors.teal, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Código de invitación', style: AppTypography.small.copyWith(color: AppColors.navy)),
              const SizedBox(height: 4),
              SelectableText(
                code.isEmpty ? 'Sin código' : code,
                style: AppTypography.section.copyWith(fontSize: 20),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text('Ahora mismo se entra con código. Después añadiremos enlace de invitación y QR.', style: AppTypography.muted),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: _SmallOutlineButton(label: 'Copiar', icon: Icons.copy_rounded, onTap: onCopy)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _SmallOutlineButton(label: 'Compartir', icon: Icons.ios_share_rounded, onTap: onShare)),
        ]),
      ]),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.helper, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SoftIconBox(icon: icon, color: color, size: 38),
        const SizedBox(height: AppSpacing.md),
        Text(label, style: AppTypography.small.copyWith(color: AppColors.navy)),
        const SizedBox(height: 5),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.section.copyWith(fontSize: 18, color: color == AppColors.lilac ? AppColors.navy : color)),
        const SizedBox(height: 4),
        Text(helper, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.small),
      ]),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SoftIconBox(icon: icon, color: color, size: 42),
        const Spacer(),
        Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.small),
      ]),
    );
  }
}

class _SmallOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallOutlineButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.tealDark,
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
