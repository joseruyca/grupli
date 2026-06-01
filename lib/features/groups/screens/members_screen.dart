import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/avatar.dart';
import '../../../ui/list_row.dart';
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

            return Column(
              children: rows.map((m) {
                final profile = Map<String, dynamic>.from((m['profiles'] ?? {}) as Map);
                final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
                final role = (m['role'] ?? 'member').toString();
                final isOwner = role == 'owner';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Column(children: [
                      ListRow(
                        leading: MemberAvatar(url: profile['avatar_url'] as String?, fallback: name),
                        title: name,
                        subtitle: profile['email']?.toString(),
                        trailing: StatusChip(label: role, color: isOwner ? AppColors.coral : AppColors.teal),
                      ),
                      if (canManage && !isOwner) ...[
                        const Divider(),
                        Row(children: [
                          Expanded(child: TextButton(onPressed: () => _setRole(m['user_id'].toString(), role == 'admin' ? 'member' : 'admin'), child: Text(role == 'admin' ? 'Quitar admin' : 'Hacer admin'))),
                          Expanded(child: TextButton(onPressed: () => _remove(m['user_id'].toString()), child: Text('Expulsar', style: AppTypography.body.copyWith(color: AppColors.danger))))
                        ]),
                      ],
                    ]),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ]),
    );
  }
}
