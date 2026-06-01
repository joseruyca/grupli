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
import '../../../ui/stat_card.dart';
import '../../../ui/status_chip.dart';
import '../../../shared/utils/formatters.dart';
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
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];
    try {
      return await GroupsRepository().myGroups().timeout(const Duration(seconds: 12));
    } catch (_) {
      rethrow;
    }
  }

  void _refresh() => setState(() => _future = _load());

  String _displayName() {
    final email = SupabaseService.currentUser?.email;
    if (email == null || email.trim().isEmpty) return 'Jose';
    return email.split('@').first;
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
          _TopBar(onRefresh: _refresh),
          const SizedBox(height: AppSpacing.lg),
          Text('¡Hola, ${_displayName()}! 👋', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text('Aquí tienes un resumen de tus grupos.', style: AppTypography.muted),
          const SizedBox(height: AppSpacing.lg),
          if (user == null)
            _LoggedOutState()
          else
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                final loading = snapshot.connectionState == ConnectionState.waiting;
                final groups = snapshot.data ?? [];
                final hasError = snapshot.hasError;

                if (loading) {
                  return const _GroupsLoadingState();
                }

                if (hasError) {
                  return _GroupsErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }

                return _GroupsLoadedState(
                  groups: groups,
                  onRefresh: _refresh,
                  onCreateGroup: () => context.go('/app/groups/new'),
                  onJoinCode: () => showAppBottomSheet(context, const JoinCodeSheet()).then((_) => _refresh()),
                  onOpenGroup: (id) => context.go('/app/groups/$id'),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _TopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Grupli', style: AppTypography.section.copyWith(color: AppColors.teal, fontSize: 21)),
        const Spacer(),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
          child: IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.notifications_none_rounded, size: 20),
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _LoggedOutState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.lock_rounded,
      title: 'No has iniciado sesión',
      body: 'Entra o crea una cuenta para ver tus grupos.',
      action: PrimaryButton(label: 'Ir a login', onPressed: () => context.go('/login')),
    );
  }
}

class _GroupsLoadingState extends StatelessWidget {
  const _GroupsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(
        children: [
          Expanded(child: _GhostStat()),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: _GhostStat()),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: _GhostStat()),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('Tus grupos', style: AppTypography.section.copyWith(fontSize: 18)),
      const SizedBox(height: AppSpacing.md),
      const _GhostCard(),
      const SizedBox(height: AppSpacing.md),
      const _GhostCard(),
    ]);
  }
}

class _GroupsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GroupsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InfoErrorCard(message: 'No se han podido cargar tus grupos. Pulsa reintentar.'),
      const SizedBox(height: AppSpacing.md),
      PrimaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onPressed: onRetry),
      const SizedBox(height: AppSpacing.md),
      SecondaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: () => context.go('/app/groups/new')),
    ]);
  }
}

class _GroupsLoadedState extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final VoidCallback onRefresh;
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinCode;
  final ValueChanged<String> onOpenGroup;

  const _GroupsLoadedState({
    required this.groups,
    required this.onRefresh,
    required this.onCreateGroup,
    required this.onJoinCode,
    required this.onOpenGroup,
  });

  @override
  Widget build(BuildContext context) {
    final totalBalance = groups.fold<double>(0, (sum, g) => sum + SafeValue.toDouble(g['balance']));
    final privateGroups = groups.where((g) => (g['privacy'] ?? '').toString().toLowerCase() == 'privado').length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          TextButton(onPressed: onRefresh, child: const Text('Actualizar')),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      if (groups.isEmpty)
        EmptyState(
          icon: Icons.groups_rounded,
          title: 'Todavía no tienes grupos',
          body: 'Crea tu primer grupo o entra con un código.',
        )
      else
        ...groups.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _GroupCard(group: g, onTap: () => onOpenGroup(g['id'].toString())),
        )),
      const SizedBox(height: AppSpacing.md),
      PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: onCreateGroup),
      const SizedBox(height: AppSpacing.md),
      SecondaryButton(label: 'Unirme con código', icon: Icons.qr_code_rounded, onPressed: onJoinCode),
    ]);
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = (group['type'] ?? 'otro').toString();
    final privacy = (group['privacy'] ?? 'privado').toString();
    final balance = SafeValue.toDouble(group['balance']);

    return AppCard(
      onTap: onTap,
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
              Row(children: [
                Expanded(child: Text(group['name']?.toString() ?? 'Grupo', style: AppTypography.section.copyWith(fontSize: 18))),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ]),
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
                  _MetaItem(icon: Icons.calendar_today_outlined, text: (group['default_days'] ?? 'Sin días').toString()),
                  _MetaItem(icon: Icons.access_time_rounded, text: (group['default_time'] ?? 'Sin hora').toString()),
                  _MetaItem(icon: Icons.location_on_outlined, text: (group['default_location'] ?? 'Sin ubicación').toString()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text('${group['members_count'] ?? 0} miembros', style: AppTypography.small),
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
    );
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

class _GhostStat extends StatelessWidget {
  const _GhostStat();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class InfoErrorCard extends StatelessWidget {
  final String message;
  const InfoErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.coralSoft,
      border: const BorderSide(color: Color(0xFFF1C2BA)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(message, style: AppTypography.body.copyWith(color: AppColors.navy))),
      ]),
    );
  }
}
