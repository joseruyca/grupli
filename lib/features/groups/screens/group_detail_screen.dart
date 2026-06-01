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

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'deporte':
        return Icons.sports_soccer_rounded;
      case 'cartas':
        return Icons.celebration_rounded;
      default:
        return Icons.groups_2_rounded;
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
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'refresh') _refresh();
                  if (v == 'regenerate') _regenerate();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'refresh', child: Text('Actualizar')),
                  if (isAdmin) const PopupMenuItem(value: 'regenerate', child: Text('Regenerar código')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(color: AppColors.mintSoft, shape: BoxShape.circle),
                    child: Icon(_iconFor((g['type'] ?? 'otro').toString()), color: AppColors.navy, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g['name'] ?? 'Grupo', style: AppTypography.section.copyWith(fontSize: 24)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (role == 'owner') const _TinyTag(label: 'Eres owner', color: AppColors.amber),
                        if (role == 'admin') const _TinyTag(label: 'Eres admin', color: AppColors.success),
                        _TinyTag(label: (g['privacy'] ?? 'privado').toString(), color: AppColors.textMuted),
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.canvasWarm, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Código de invitación', style: AppTypography.small.copyWith(color: AppColors.navy)),
                        const SizedBox(height: 4),
                        Text(code.isEmpty ? 'Sin código' : code, style: AppTypography.section.copyWith(fontSize: 19)),
                      ]),
                    ),
                    SecondaryButtonSmall(label: 'Copiar', icon: Icons.copy_rounded, onPressed: () => _copyCode(code)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.28,
              children: [
                _QuickCard(title: 'Calendario', subtitle: 'Próximas quedadas', icon: Icons.calendar_month_rounded, color: AppColors.teal, onTap: () => context.go('/app/groups/${widget.groupId}/calendar')),
                _QuickCard(title: 'Finanzas', subtitle: 'Balance y pagos', icon: Icons.account_balance_wallet_rounded, color: AppColors.success, onTap: () => context.go('/app/groups/${widget.groupId}/finances')),
                _QuickCard(title: 'Torneos', subtitle: 'Competiciones', icon: Icons.emoji_events_rounded, color: AppColors.lilac, onTap: () => context.go('/app/groups/${widget.groupId}/tournaments')),
                _QuickCard(title: 'Miembros', subtitle: '$membersCount miembros', icon: Icons.group_rounded, color: AppColors.amber, onTap: () => context.go('/app/groups/${widget.groupId}/members')),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.md),
              ActionTile(title: 'Editar grupo', subtitle: 'Información, días, hora y ubicación.', icon: Icons.edit_rounded, onTap: () => context.go('/app/groups/${widget.groupId}/edit')),
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

class _TinyTag extends StatelessWidget {
  final String label;
  final Color color;
  const _TinyTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color),
        ),
        const Spacer(),
        Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTypography.muted),
      ]),
    );
  }
}

class SecondaryButtonSmall extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const SecondaryButtonSmall({super.key, required this.label, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.tealDark,
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
