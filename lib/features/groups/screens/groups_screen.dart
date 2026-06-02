import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_client.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/bottom_nav.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/mock_ui.dart';
import '../../../shared/utils/safe_values.dart';
import '../groups_repository.dart';
import '../widgets/join_code_sheet.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadGroups();
  }

  Future<List<Map<String, dynamic>>> _loadGroups() async {
    if (SupabaseService.currentUser == null) return <Map<String, dynamic>>[];
    return GroupsRepository().myGroups().timeout(const Duration(seconds: 12));
  }

  void _refresh() => setState(() => _future = _loadGroups());

  String get _displayName {
    final email = SupabaseService.currentUser?.email;
    if (email == null || email.trim().isEmpty) return 'Jose';
    final first = email.split('@').first.trim();
    return first.isEmpty ? 'Jose' : first;
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      bottomNavigationBar: AppBottomNav(
        index: 0,
        onChanged: (i) {
          if (i == 0) context.go('/app');
          if (i == 1) context.go('/app/settings');
          if (i == 2) context.go('/app/profile');
        },
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Mis grupos', style: AppTypography.title.copyWith(fontSize: 24)),
          const Spacer(),
          IconButton.filled(
            onPressed: () => context.go('/app/groups/new'),
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Hola, $_displayName 👋', style: AppTypography.muted),
        const SizedBox(height: 18),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const _SkeletonHome();
            if (snapshot.hasError) return _HomeError(message: snapshot.error.toString(), onRetry: _refresh);
            final groups = snapshot.data ?? <Map<String, dynamic>>[];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: MockStat(value: '${groups.length}', label: 'Grupos', icon: Icons.lock_rounded)),
                const SizedBox(width: 10),
                Expanded(child: MockStat(value: '${_totalMembers(groups)}', label: 'Miembros', icon: Icons.people_alt_rounded, color: AppColors.lilac)),
                const SizedBox(width: 10),
                Expanded(child: MockStat(value: '${_totalEvents(groups)}', label: 'Eventos', icon: Icons.event_rounded, color: AppColors.amber)),
              ]),
              const SizedBox(height: 22),
              MockSectionTitle(title: 'Tus grupos', action: 'Actualizar', onAction: _refresh),
              const SizedBox(height: 8),
              if (groups.isEmpty) _EmptyGroups(onCreate: () => context.go('/app/groups/new'), onJoin: _join) else ...groups.map(_groupCard),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: () => context.go('/app/groups/new')),
              const SizedBox(height: 10),
              SecondaryButton(label: 'Unirme con código', icon: Icons.qr_code_2_rounded, onPressed: _join),
            ]);
          },
        ),
      ]),
    );
  }

  int _totalMembers(List<Map<String, dynamic>> groups) => groups.fold(0, (sum, g) => sum + SafeValue.toInt(g['members_count']));
  int _totalEvents(List<Map<String, dynamic>> groups) => groups.fold(0, (sum, g) => sum + SafeValue.toInt(g['next_events_count']));

  Future<void> _join() async {
    await showAppBottomSheet(context, const JoinCodeSheet());
    _refresh();
  }

  Widget _groupCard(Map<String, dynamic> g) {
    final name = SafeValue.toText(g['name'], 'Grupo');
    final members = SafeValue.toInt(g['members_count']);
    final events = SafeValue.toInt(g['next_events_count']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MockCard(
        onTap: () => context.go('/app/groups/${g['id']}'),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const MockThumbnail(icon: Icons.sports_soccer_rounded, color: AppColors.teal, size: 60),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy))),
              const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 18),
            ]),
            const SizedBox(height: 4),
            Text('$members miembros', style: AppTypography.small),
            const SizedBox(height: 8),
            Row(children: [
              MockAvatarStack(count: members),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(999)),
                child: Text('$events eventos', style: AppTypography.small.copyWith(color: AppColors.tealDark)),
              ),
            ]),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _SkeletonHome extends StatelessWidget {
  const _SkeletonHome();

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(4, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(height: i == 0 ? 92 : 86, decoration: BoxDecoration(color: AppColors.canvasWarm, borderRadius: BorderRadius.circular(18))),
    )));
  }
}

class _HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _HomeError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MockCard(
      color: AppColors.coralSoft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('No se han podido cargar tus grupos', style: AppTypography.section.copyWith(fontSize: 17)),
        const SizedBox(height: 8),
        Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.small.copyWith(color: AppColors.danger)),
        const SizedBox(height: 12),
        SecondaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onPressed: onRetry),
      ]),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyGroups({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return MockCard(
      child: Column(children: [
        const MockThumbnail(icon: Icons.groups_2_rounded, color: AppColors.teal, size: 70),
        const SizedBox(height: 14),
        Text('Empieza creando tu primer grupo', style: AppTypography.section.copyWith(fontSize: 18), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Todos los grupos son privados. Entra con invitación, código o QR cuando lo activemos.', style: AppTypography.muted, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: onCreate),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Unirme con código', icon: Icons.qr_code_rounded, onPressed: onJoin),
      ]),
    );
  }
}
