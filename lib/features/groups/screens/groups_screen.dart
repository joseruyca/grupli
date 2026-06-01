import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_client.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/action_tile.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/bottom_nav.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/status_chip.dart';
import '../../../shared/utils/formatters.dart';
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
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (SupabaseService.currentUser == null) return [];
    return GroupsRepository().myGroups();
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    return AppScreen(
      bottomNavigationBar: AppBottomNav(
        index: 0,
        onChanged: (i) {
          if (i == 1) context.go('/app/profile');
          if (i == 2) context.go('/app/settings');
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Mis grupos',
            subtitle: user == null ? 'Inicia sesión para empezar.' : 'Hola, ${user.email ?? 'Jose'}',
            trailing: IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: () => context.go('/app/groups/new'))),
          ]),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Unirse con código', icon: Icons.vpn_key_rounded, onPressed: () => showAppBottomSheet(context, const JoinCodeSheet()).then((_) => _refresh())),
          const SizedBox(height: AppSpacing.xl),
          if (user == null)
            EmptyState(
              icon: Icons.lock_rounded,
              title: 'No has iniciado sesión',
              body: 'Entra o crea una cuenta para ver tus grupos.',
              action: PrimaryButton(label: 'Ir a login', onPressed: () => context.go('/login')),
            )
          else
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
                if (snapshot.hasError) return EmptyState(icon: Icons.error_outline_rounded, title: 'No se pudo cargar', body: snapshot.error.toString());
                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.groups_rounded,
                    title: 'Todavía no tienes grupos',
                    body: 'Crea tu primer grupo o entra con un código.',
                  );
                }
                return Column(
                  children: groups.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      onTap: () => context.go('/app/groups/${g['id']}'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(g['name'] ?? 'Grupo', style: AppTypography.section)),
                          StatusChip(label: (g['role'] ?? 'member').toString()),
                        ]),
                        const SizedBox(height: AppSpacing.sm),
                        Text('${g['type'] ?? 'otro'} · ${g['privacy'] ?? 'privado'} · ${g['members_count'] ?? 0} miembros', style: AppTypography.muted),
                        const SizedBox(height: AppSpacing.md),
                        Row(children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(child: Text(g['default_location'] ?? 'Sin ubicación habitual', style: AppTypography.small)),
                          Text(Fmt.money.format(((g['balance'] ?? 0) as num).toDouble()), style: AppTypography.small.copyWith(color: AppColors.teal)),
                        ]),
                      ]),
                    ),
                  )).toList(),
                );
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          ActionTile(
            title: 'Checklist multiusuario',
            subtitle: 'Pruebas clave de permisos y flujo real.',
            icon: Icons.fact_check_rounded,
            color: AppColors.lilac,
            onTap: () => context.go('/app/test-checklist'),
          ),
        ],
      ),
    );
  }
}
