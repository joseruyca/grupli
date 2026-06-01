import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
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
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  Future<void> _remove(String userId) async {
    try {
      await GroupsRepository().removeMember(widget.groupId, userId);
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(title: 'Miembros', subtitle: 'Gestiona roles y permisos.', showBack: true, trailing: IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));

            final group = Map<String, dynamic>.from(snapshot.data!['group'] as Map);
            final rows = List<Map<String, dynamic>>.from(snapshot.data!['members'] as List);
            final myRole = (group['my_role'] ?? 'member').toString();
            final canManage = myRole == 'owner' || myRole == 'admin';
            final query = _search.text.trim().toLowerCase();
            final filtered = rows.where((m) {
              final profile = Map<String, dynamic>.from((m['profiles'] ?? {}) as Map);
              final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString().toLowerCase();
              final role = (m['role'] ?? 'member').toString();
              final roleOk = _filter == 'Todos' || (_filter == 'Admins' ? (role == 'owner' || role == 'admin') : role == 'member');
              final searchOk = query.isEmpty || name.contains(query);
              return roleOk && searchOk;
            }).toList();

            return Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Buscar miembro', prefixIcon: Icon(Icons.search_rounded)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    initialValue: _filter,
                    onSelected: (v) => setState(() => _filter = v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'Todos', child: Text('Todos')),
                      PopupMenuItem(value: 'Admins', child: Text('Admins')),
                      PopupMenuItem(value: 'Miembros', child: Text('Miembros')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_filter, style: AppTypography.small.copyWith(color: AppColors.navy)), const Icon(Icons.keyboard_arrow_down_rounded)]),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                ...filtered.map((m) {
                  final profile = Map<String, dynamic>.from((m['profiles'] ?? {}) as Map);
                  final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
                  final role = (m['role'] ?? 'member').toString();
                  final isOwner = role == 'owner';
                  final chipColor = isOwner ? AppColors.amber : role == 'admin' ? AppColors.success : AppColors.teal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        Row(
                          children: [
                            MemberAvatar(url: profile['avatar_url'] as String?, fallback: name, size: 44),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(profile['email']?.toString() ?? '', style: AppTypography.small),
                              ]),
                            ),
                            StatusChip(label: role, color: chipColor),
                            if (canManage && !isOwner)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'toggle-admin') {
                                    _setRole(m['user_id'].toString(), role == 'admin' ? 'member' : 'admin');
                                  }
                                  if (value == 'remove') {
                                    _remove(m['user_id'].toString());
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(value: 'toggle-admin', child: Text(role == 'admin' ? 'Quitar admin' : 'Hacer admin')),
                                  const PopupMenuItem(value: 'remove', child: Text('Expulsar')),
                                ],
                              ),
                          ],
                        ),
                      ]),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ]),
    );
  }
}
