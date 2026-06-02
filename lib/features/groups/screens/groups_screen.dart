import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_client.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (i) {
            if (i == 1) context.go('/app/profile');
            if (i == 2) context.go('/app/settings');
          },
          height: 70,
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.tealSoft,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.groups_rounded), label: 'Grupos'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Ajustes'),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: AppColors.teal,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _HomeTopBar(onRefresh: _refresh),
              const SizedBox(height: AppSpacing.lg),
              Text('¡Hola, $_displayName! 👋', style: AppTypography.title),
              const SizedBox(height: 5),
              Text('Organiza tus grupos, quedadas, gastos y torneos sin caos.', style: AppTypography.muted),
              const SizedBox(height: AppSpacing.lg),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _HomeLoading();
                  }

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
            ],
          ),
        ),
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
        Text('Grupli', style: AppTypography.section.copyWith(color: AppColors.teal, fontSize: 23, letterSpacing: -0.6)),
        const Spacer(),
        _RoundIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
        const SizedBox(width: 8),
        _RoundIconButton(icon: Icons.refresh_rounded, onTap: onRefresh),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onRefresh;
  final ValueChanged<String> onOpen;

  const _HomeContent({
    required this.groups,
    required this.onCreate,
    required this.onJoin,
    required this.onRefresh,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final totalBalance = groups.fold<double>(0, (sum, g) => sum + SafeValue.toDouble(g['balance']));
    final members = groups.fold<int>(0, (sum, g) => sum + SafeValue.toInt(g['members_count']));
    final privateGroups = groups.where((g) => (g['privacy'] ?? '').toString().toLowerCase() == 'privado').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(icon: Icons.groups_rounded, value: '${groups.length}', label: 'Grupos')),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(icon: Icons.people_outline_rounded, value: '$members', label: 'Miembros', color: AppColors.lilac)),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(icon: Icons.wallet_rounded, value: Fmt.money.format(totalBalance), label: 'Balance', color: AppColors.amber)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onPressed: onCreate)),
          ],
        ),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Unirme con código', icon: Icons.qr_code_rounded, onPressed: onJoin),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Tus grupos', style: AppTypography.section.copyWith(fontSize: 18)),
            const Spacer(),
            TextButton(onPressed: onRefresh, child: const Text('Actualizar')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (groups.isEmpty)
          _EmptyGroupsCard(onCreate: onCreate, onJoin: onJoin)
        else
          ...groups.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _GroupCard(group: g, onTap: () => onOpen(g['id'].toString())),
              )),
        if (groups.isNotEmpty && privateGroups > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('$privateGroups grupo(s) privados protegidos por código.', style: AppTypography.small),
        ],
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = SafeValue.toText(group['type'], 'otro');
    final privacy = SafeValue.toText(group['privacy'], 'privado');
    final balance = SafeValue.toDouble(group['balance']);
    final location = SafeValue.toText(group['default_location'], 'Sin ubicación');
    final time = SafeValue.toText(group['default_time'], 'Sin hora');
    final days = SafeValue.toText(group['default_days'], 'Sin días');
    final members = SafeValue.toInt(group['members_count']);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(color: _toneFor(type), shape: BoxShape.circle),
            child: Icon(_iconFor(type), color: AppColors.navy, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(SafeValue.toText(group['name'], 'Grupo'), style: AppTypography.section.copyWith(fontSize: 18))),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ]),
              const SizedBox(height: 7),
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
                  _Meta(icon: Icons.calendar_today_outlined, text: days),
                  _Meta(icon: Icons.access_time_rounded, text: time),
                  _Meta(icon: Icons.location_on_outlined, text: location),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text('$members miembros', style: AppTypography.small),
                  const Spacer(),
                  Text(
                    Fmt.money.format(balance),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w900,
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
        return Icons.style_rounded;
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

class _EmptyGroupsCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyGroupsCard({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(color: AppColors.mintSoft, shape: BoxShape.circle),
          child: const Icon(Icons.groups_2_rounded, color: AppColors.teal, size: 30),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Crea tu primer grupo', style: AppTypography.section.copyWith(fontSize: 19)),
        const SizedBox(height: 6),
        Text('Empieza con un grupo privado y comparte el código con tus amigos.', style: AppTypography.muted),
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
      Row(
        children: [
          Expanded(child: _GhostBox(height: 104)),
          SizedBox(width: 10),
          Expanded(child: _GhostBox(height: 104)),
          SizedBox(width: 10),
          Expanded(child: _GhostBox(height: 104)),
        ],
      ),
      SizedBox(height: 18),
      _GhostBox(height: 56),
      SizedBox(height: 10),
      _GhostBox(height: 54),
      SizedBox(height: 24),
      _GhostBox(height: 120),
      SizedBox(height: 12),
      _GhostBox(height: 120),
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
          Expanded(child: Text('No se han podido cargar tus grupos. Revisa Supabase o pulsa reintentar.', style: AppTypography.body.copyWith(color: AppColors.navy))),
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
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 10),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.section.copyWith(fontSize: 18, color: AppColors.navy)),
        const SizedBox(height: 3),
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.small),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
