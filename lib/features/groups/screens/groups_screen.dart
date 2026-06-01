import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_client.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/bottom_nav.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/stat_card.dart';
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

  Color _toneFor(String type) {
    switch (type.toLowerCase()) {
      case 'deporte':
        return AppColors.greenSoft;
      case 'cartas':
        return AppColors.lilacSoft;
      default:
        return AppColors.tealSoft;
    }
  }

  String _prettyType(String type) {
    switch (type.toLowerCase()) {
      case 'deporte':
        return 'Deportivo';
      case 'cartas':
        return 'Social';
      default:
        return 'Otro';
    }
  }

  String _prettyPrivacy(String privacy) {
    switch (privacy.toLowerCase()) {
      case 'privado':
        return 'Privado';
      case 'público':
      case 'publico':
        return 'Público';
      default:
        return 'Semiprivado';
    }
  }

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
          Row(
            children: [
              Text('Grupli', style: AppTypography.section.copyWith(color: AppColors.teal, fontSize: 18)),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                child: IconButton(onPressed: _refresh, icon: const Icon(Icons.notifications_none_rounded, size: 20), color: AppColors.navy),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('¡Hola, ${user?.email?.split('@').first ?? 'Jose'}! 👋', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text('Aquí tienes un resumen de tus grupos.', style: AppTypography.muted),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
              if (snapshot.hasError) return EmptyState(icon: Icons.error_outline_rounded, title: 'No se pudo cargar', body: snapshot.error.toString());
              final groups = snapshot.data ?? [];
              final totalBalance = groups.fold<double>(0, (sum, g) => sum + ((g['balance'] ?? 0) as num).toDouble());
              final privateGroups = groups.where((g) => (g['privacy'] ?? '').toString().toLowerCase() == 'privado').length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: StatCard(label: 'Grupos', value: '${groups.length}', icon: Icons.groups_rounded)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: StatCard(label: 'Privados', value: '$privateGroups', icon: Icons.lock_outline_rounded, color: AppColors.lilac)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: StatCard(label: 'Balance neto', value: Fmt.money.format(totalBalance), icon: Icons.account_balance_wallet_outlined, color: AppColors.amber)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Text('Tus grupos', style: AppTypography.section.copyWith(fontSize: 18)),
                      const Spacer(),
                      TextButton(onPressed: () {}, child: const Text('Ver archivados')),
                    ],
                  ),
                  if (user == null)
                    EmptyState(
                      icon: Icons.lock_rounded,
                      title: 'No has iniciado sesión',
                      body: 'Entra o crea una cuenta para ver tus grupos.',
                      action: PrimaryButton(label: 'Ir a login', onPressed: () => context.go('/login')),
                    )
                  else if (groups.isEmpty)
                    EmptyState(
                      icon: Icons.groups_rounded,
                      title: 'Todavía no tienes grupos',
                      body: 'Crea tu primer grupo o entra con un código.',
                    )
                  else
                    Column(
                      children: groups.map((g) {
                        final type = (g['type'] ?? 'otro').toString();
                        final privacy = (g['privacy'] ?? 'privado').toString();
                        final balance = ((g['balance'] ?? 0) as num).toDouble();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AppCard(
                            onTap: () => context.go('/app/groups/${g['id']}'),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(color: _toneFor(type), shape: BoxShape.circle),
                                  child: Icon(_iconFor(type), color: AppColors.navy, size: 28),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [Expanded(child: Text(g['name'] ?? 'Grupo', style: AppTypography.section.copyWith(fontSize: 18))), const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)]),
                                    const SizedBox(height: AppSpacing.xs),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        StatusChip(label: _prettyType(type), color: AppColors.success),
                                        StatusChip(label: _prettyPrivacy(privacy), color: privacy.toLowerCase() == 'privado' ? AppColors.textMuted : AppColors.lilac),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        _MetaItem(icon: Icons.calendar_today_outlined, text: (g['default_days'] ?? 'Sin días').toString()),
                                        _MetaItem(icon: Icons.access_time_rounded, text: (g['default_time'] ?? 'Sin hora').toString()),
                                        _MetaItem(icon: Icons.location_on_outlined, text: (g['default_location'] ?? 'Sin ubicación').toString()),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        Text('${g['members_count'] ?? 0} miembros', style: AppTypography.small),
                                        const Spacer(),
                                        Text(
                                          Fmt.money.format(balance),
                                          style: AppTypography.body.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: balance < 0 ? AppColors.danger : AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: () => context.go('/app/groups/new')),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(label: 'Unirme con código', icon: Icons.qr_code_rounded, onPressed: () => showAppBottomSheet(context, const JoinCodeSheet()).then((_) => _refresh())),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text(text, style: AppTypography.small),
    ]);
  }
}
