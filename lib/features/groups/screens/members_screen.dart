import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/avatar.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/status_chip.dart';
import '../../../ui/toast.dart';
import '../groups_repository.dart';

class MembersScreen extends StatefulWidget {
  final String groupId;
  const MembersScreen({super.key, required this.groupId});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Future<Map<String, dynamic>> _future;
  final _search = TextEditingController();
  String _filter = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final repo = GroupsRepository();
    final group = await repo.getGroup(widget.groupId);
    final members = await repo.members(widget.groupId);
    return {'group': group, 'members': members};
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _setRole(String userId, String role) async {
    try {
      await GroupsRepository().setMemberRole(widget.groupId, userId, role);
      _refresh();
      if (mounted) AppToast.show(context, role == 'admin' ? 'Miembro convertido en admin.' : 'Admin convertido en miembro.');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  Future<void> _remove(String userId) async {
    try {
      await GroupsRepository().removeMember(widget.groupId, userId);
      _refresh();
      if (mounted) AppToast.show(context, 'Miembro expulsado.');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  String _nameOf(Map<String, dynamic> member) {
    final profile = Map<String, dynamic>.from((member['profiles'] ?? {}) as Map);
    return (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
  }

  String _emailOf(Map<String, dynamic> member) {
    final profile = Map<String, dynamic>.from((member['profiles'] ?? {}) as Map);
    return (profile['email'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Miembros',
          subtitle: 'Roles, asistencia y acciones del grupo.',
          showBack: true,
          trailing: IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState(label: 'Cargando miembros...');
            if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));

            final group = Map<String, dynamic>.from(snapshot.data!['group'] as Map);
            final rows = List<Map<String, dynamic>>.from(snapshot.data!['members'] as List);
            final myRole = (group['my_role'] ?? 'member').toString();
            final canManage = myRole == 'owner' || myRole == 'admin';
            final admins = rows.where((m) {
              final r = (m['role'] ?? 'member').toString();
              return r == 'owner' || r == 'admin';
            }).length;

            final query = _search.text.trim().toLowerCase();
            final filtered = rows.where((m) {
              final name = _nameOf(m).toLowerCase();
              final email = _emailOf(m).toLowerCase();
              final role = (m['role'] ?? 'member').toString();
              final roleOk = _filter == 'Todos' || (_filter == 'Admins' ? (role == 'owner' || role == 'admin') : role == 'member');
              final searchOk = query.isEmpty || name.contains(query) || email.contains(query);
              return roleOk && searchOk;
            }).toList();

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _MemberStat(label: 'Total', value: '${rows.length}', icon: Icons.groups_rounded, color: AppColors.teal)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MemberStat(label: 'Admins', value: '$admins', icon: Icons.admin_panel_settings_rounded, color: AppColors.amber)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MemberStat(label: 'Miembros', value: '${rows.length - admins}', icon: Icons.person_outline_rounded, color: AppColors.lilac)),
              ]),
              const SizedBox(height: AppSpacing.lg),

              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: 'Buscar miembro', prefixIcon: Icon(Icons.search_rounded)),
                  ),
                ),
                const SizedBox(width: 8),
                _FilterButton(value: _filter, onChanged: (v) => setState(() => _filter = v)),
              ]),
              const SizedBox(height: AppSpacing.lg),

              Row(children: [
                Expanded(child: Text('Miembro', style: AppTypography.small.copyWith(color: AppColors.navy))),
                SizedBox(width: 78, child: Text('Rol', textAlign: TextAlign.center, style: AppTypography.small.copyWith(color: AppColors.navy))),
                SizedBox(width: 50, child: Text('Acción', textAlign: TextAlign.right, style: AppTypography.small.copyWith(color: AppColors.navy))),
              ]),
              const SizedBox(height: AppSpacing.sm),

              if (filtered.isEmpty)
                InfoPanel(
                  icon: Icons.search_off_rounded,
                  title: 'No hay resultados',
                  body: 'Cambia el filtro o busca por otro nombre/correo.',
                  color: AppColors.lilac,
                )
              else
                ...filtered.map((m) {
                  final profile = Map<String, dynamic>.from((m['profiles'] ?? {}) as Map);
                  final name = _nameOf(m);
                  final email = _emailOf(m);
                  final role = (m['role'] ?? 'member').toString();
                  final isOwner = role == 'owner';
                  final isAdmin = role == 'admin';
                  final chipColor = isOwner ? AppColors.amber : isAdmin ? AppColors.success : AppColors.teal;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _MemberCard(
                      name: name,
                      email: email,
                      avatarUrl: profile['avatar_url'] as String?,
                      role: role,
                      chipColor: chipColor,
                      canManage: canManage && !isOwner,
                      onMakeAdmin: () => _setRole(m['user_id'].toString(), isAdmin ? 'member' : 'admin'),
                      onRemove: () => _remove(m['user_id'].toString()),
                    ),
                  );
                }),

              const SizedBox(height: AppSpacing.md),
              AppCard(
                color: AppColors.canvasWarm,
                child: Row(children: const [
                  _LegendDot(color: AppColors.success, label: 'Admin'),
                  SizedBox(width: AppSpacing.md),
                  _LegendDot(color: AppColors.teal, label: 'Miembro'),
                  SizedBox(width: AppSpacing.md),
                  _LegendDot(color: AppColors.amber, label: 'Owner'),
                ]),
              ),
            ]);
          },
        ),
      ]),
    );
  }
}

class _MemberStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MemberStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SoftIconBox(icon: icon, color: color, size: 36),
        const SizedBox(height: 10),
        Text(value, style: AppTypography.section.copyWith(fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.small),
      ]),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterButton({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'Todos', child: Text('Todos')),
        PopupMenuItem(value: 'Admins', child: Text('Admins')),
        PopupMenuItem(value: 'Miembros', child: Text('Miembros')),
      ],
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: AppTypography.small.copyWith(color: AppColors.navy)),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final Color chipColor;
  final bool canManage;
  final VoidCallback onMakeAdmin;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.chipColor,
    required this.canManage,
    required this.onMakeAdmin,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          MemberAvatar(url: avatarUrl, fallback: name, size: 46),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(email.isEmpty ? 'Sin correo visible' : email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.small),
            ]),
          ),
          StatusChip(label: _roleLabel(role), color: chipColor),
          if (canManage) ...[
            const SizedBox(width: 2),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle-admin') onMakeAdmin();
                if (value == 'remove') onRemove();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle-admin', child: Text(role == 'admin' ? 'Quitar admin' : 'Hacer admin')),
                const PopupMenuItem(value: 'remove', child: Text('Expulsar')),
              ],
            ),
          ],
        ]),
      ]),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      default:
        return 'Miembro';
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: AppTypography.small),
    ]);
  }
}
