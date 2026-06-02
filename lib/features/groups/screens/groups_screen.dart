import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_client.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/bottom_nav.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/status_chip.dart';
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
          if (i == 1) context.go('/app/profile');
          if (i == 2) context.go('/app/settings');
        },
      ),
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: AppColors.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _HomeTopBar(onRefresh: _refresh),
          const SizedBox(height: AppSpacing.xl),
          Text('Hola, $_displayName', style: AppTypography.title),
          const SizedBox(height: 6),
          Text('Tus grupos privados, con eventos, gastos y torneos en un solo sitio.', style: AppTypography.muted),
          const SizedBox(height: AppSpacing.xl),
          _CreateJoinPanel(
            onCreate: () => context.go('/app/groups/new'),
            onJoin: () => showAppBottomSheet(context, const JoinCodeSheet()).then((_) => _refresh()),
          ),
          const SizedBox(height: 26),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const _HomeLoading();
              if (snapshot.hasError) {
                return _HomeError(
                  message: snapshot.error.toString(),
                  onRetry: _refresh,
                  onCreate: () => context.go('/app/groups/new'),
                );
              }

              final groups = snapshot.data ?? <Map<String, dynamic>>[];
              return _HomeContent(
                groups: groups,
                onCreate: () => context.go('/app/groups/new'),
                onJoin: () => showAppBottomSheet(context, const JoinCodeSheet()).then((_) => _refresh()),
                onOpen: (id) => context.go('/app/groups/$id'),
                onRefresh: _refresh,
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HomeTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Grupli', style: AppTypography.section.copyWith(color: AppColors.navy, fontSize: 24, letterSpacing: -0.8)),
        const Spacer(),
        _RoundIconButton(icon: Icons.refresh_rounded, onTap: onRefresh),
      ],
    );
  }
}

class _CreateJoinPanel extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _CreateJoinPanel({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.canvasWarm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SoftIconBox(icon: Icons.groups_2_rounded, color: AppColors.teal, size: 46),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Empieza con un grupo privado', style: AppTypography.section.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text('Invita a la gente y organiza todo desde dentro.', style: AppTypography.muted),
          ])),
        ]),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: onCreate),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Entrar con código', icon: Icons.qr_code_rounded, onPressed: onJoin),
      ]),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onRefresh;
  final ValueChanged<String> onOpen;

  const _HomeContent({required this.groups, required this.onCreate, required this.onJoin, required this.onRefresh, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final members = groups.fold<int>(0, (sum, g) => sum + SafeValue.toInt(g['members_count']));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _MetricCard(icon: Icons.lock_outline_rounded, value: '${groups.length}', label: 'Grupos privados')),
        const SizedBox(width: 10),
        Expanded(child: _MetricCard(icon: Icons.people_outline_rounded, value: '$members', label: 'Miembros', color: AppColors.lilac)),
      ]),
      const SizedBox(height: 24),
      Row(children: [
        Text('Tus grupos', style: AppTypography.section.copyWith(fontSize: 20)),
        const Spacer(),
        TextButton(onPressed: onRefresh, child: const Text('Actualizar')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      if (groups.isEmpty)
        _EmptyGroupsCard(onCreate: onCreate, onJoin: onJoin)
      else
        ...groups.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _GroupCard(group: g, onTap: () => onOpen(g['id'].toString())),
            )),
    ]);
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final members = SafeValue.toInt(group['members_count']);
    final code = SafeValue.toText(group['invite_code'], '');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
            child: const Icon(Icons.groups_2_rounded, color: AppColors.tealDark, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(SafeValue.toText(group['name'], 'Grupo'), style: AppTypography.section.copyWith(fontSize: 19))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ]),
            const SizedBox(height: 7),
            Wrap(spacing: 8, runSpacing: 8, children: const [
              StatusChip(label: 'Privado', color: AppColors.teal),
              StatusChip(label: 'Solo invitación', color: AppColors.textMuted),
            ]),
          ])),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          _Meta(icon: Icons.people_outline_rounded, text: '$members miembros'),
          const SizedBox(width: 12),
          _Meta(icon: Icons.qr_code_rounded, text: code.isEmpty ? 'Sin código' : code),
        ]),
        const SizedBox(height: AppSpacing.md),
        const _ModuleStrip(),
      ]),
    );
  }
}

class _ModuleStrip extends StatelessWidget {
  const _ModuleStrip();

  @override
  Widget build(BuildContext context) {
    return Row(children: const [
      Expanded(child: _TinyModule(icon: Icons.event_available_rounded, label: 'Eventos', color: AppColors.teal)),
      SizedBox(width: 8),
      Expanded(child: _TinyModule(icon: Icons.calendar_month_rounded, label: 'Calendario', color: AppColors.lilac)),
      SizedBox(width: 8),
      Expanded(child: _TinyModule(icon: Icons.receipt_long_rounded, label: 'Gastos', color: AppColors.success)),
      SizedBox(width: 8),
      Expanded(child: _TinyModule(icon: Icons.emoji_events_rounded, label: 'Ligas', color: AppColors.amber)),
    ]);
  }
}

class _TinyModule extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TinyModule({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.small.copyWith(fontSize: 10.5, color: AppColors.navy)),
      ]),
    );
  }
}

class _EmptyGroupsCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyGroupsCard({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SoftIconBox(icon: Icons.lock_outline_rounded, color: AppColors.teal, size: 54),
        const SizedBox(height: AppSpacing.md),
        Text('Todavía no tienes grupos', style: AppTypography.section.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Crea uno privado o entra con un código de invitación.', style: AppTypography.muted),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: onCreate),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Tengo un código', icon: Icons.qr_code_rounded, onPressed: onJoin),
      ]),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Row(children: [Expanded(child: _GhostBox(height: 92)), SizedBox(width: 10), Expanded(child: _GhostBox(height: 92))]),
      SizedBox(height: 24),
      _GhostBox(height: 132),
      SizedBox(height: 12),
      _GhostBox(height: 132),
    ]);
  }
}

class _HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCreate;
  const _HomeError({required this.message, required this.onRetry, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(
        color: AppColors.coralSoft,
        border: const BorderSide(color: Color(0xFFF1C2BA)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('No se han podido cargar tus grupos.', style: AppTypography.body.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800))),
        ]),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(message, style: AppTypography.small.copyWith(color: AppColors.textMuted)),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onPressed: onRetry),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: onCreate),
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MetricCard({required this.icon, required this.value, required this.label, this.color = AppColors.teal});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        SoftIconBox(icon: icon, color: color, size: 38),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.section.copyWith(fontSize: 20, color: AppColors.navy)),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.small),
        ])),
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text(text, style: AppTypography.small),
    ]);
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
        child: Icon(icon, color: AppColors.navy, size: 20),
      ),
    );
  }
}

class _GhostBox extends StatelessWidget {
  final double height;
  const _GhostBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.canvasWarm,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
