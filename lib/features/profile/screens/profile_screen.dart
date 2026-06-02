import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/errors.dart';
import '../../../core/supabase_client.dart';
import '../../../features/auth/auth_service.dart';
import '../../../shared/utils/formatters.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/avatar.dart';
import '../../../ui/bottom_nav.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/toast.dart';
import '../profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileSummary> _future;
  final _name = TextEditingController();
  bool _saving = false;
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    _future = ProfileRepository().summary();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _future = ProfileRepository().summary());

  Future<void> _pickAvatar() async {
    if (_avatarBusy) return;
    setState(() => _avatarBusy = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 900);
      if (file == null) return;
      await ProfileRepository().uploadAvatar(file);
      _refresh();
      if (mounted) AppToast.show(context, 'Foto de perfil actualizada.');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_avatarBusy) return;
    setState(() => _avatarBusy = true);
    try {
      await ProfileRepository().removeAvatar();
      _refresh();
      if (mounted) AppToast.show(context, 'Foto eliminada.');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _saveName() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ProfileRepository().updateName(_name.text);
      _refresh();
      if (mounted) {
        Navigator.of(context).maybePop();
        AppToast.show(context, 'Perfil actualizado.');
      }
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    return AppScreen(
      bottomNavigationBar: AppBottomNav(
        index: 1,
        onChanged: (i) {
          if (i == 0) context.go('/app');
          if (i == 2) context.go('/app/settings');
        },
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Perfil', style: AppTypography.title),
          const Spacer(),
          IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Text('Tu identidad dentro de los grupos.', style: AppTypography.muted),
        const SizedBox(height: AppSpacing.lg),
        if (user == null)
          AppCard(child: Text('Inicia sesión para ver tu perfil.', style: AppTypography.body))
        else
          FutureBuilder<ProfileSummary>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
              if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));

              final summary = snapshot.data!;
              final profile = summary.profile;
              final name = (profile['full_name'] ?? user.email ?? 'Usuario').toString();
              final email = (profile['email'] ?? user.email ?? '').toString();
              final avatar = profile['avatar_url'] as String?;

              if (_name.text.isEmpty) _name.text = name;

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ProfileHero(
                  name: name,
                  email: email,
                  avatarUrl: avatar,
                  avatarBusy: _avatarBusy,
                  onAvatarTap: _pickAvatar,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(child: _ProfileStat(label: 'Grupos', value: '${summary.groupsCount}', icon: Icons.groups_rounded)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _ProfileStat(label: 'Saldo total', value: Fmt.money.format(summary.balanceTotal), icon: Icons.wallet_rounded, color: AppColors.teal)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _ProfileStat(label: 'Asistencia', value: '${(summary.attendanceRate * 100).round()}%', icon: Icons.trending_up_rounded, color: AppColors.success)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                Text('Acciones', style: AppTypography.section.copyWith(fontSize: 18)),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _ProfileAction(icon: Icons.edit_rounded, label: 'Editar perfil', onTap: () => _showEditName(context)),
                    const Divider(height: 1),
                    _ProfileAction(icon: Icons.camera_alt_outlined, label: 'Cambiar foto de perfil', onTap: _pickAvatar),
                    const Divider(height: 1),
                    _ProfileAction(icon: Icons.delete_outline_rounded, label: 'Quitar foto de perfil', onTap: _removeAvatar),
                    const Divider(height: 1),
                    _ProfileAction(icon: Icons.bar_chart_rounded, label: 'Mis estadísticas', onTap: () => _showStats(context, summary)),
                  ]),
                ),
                const SizedBox(height: AppSpacing.xl),
                DestructiveButton(label: 'Cerrar sesión', onPressed: _logout),
              ]);
            },
          ),
      ]),
    );
  }

  void _showEditName(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Editar perfil', style: AppTypography.section),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _name, label: 'Nombre visible', hint: 'Ej. Jose'),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Guardar perfil', loading: _saving, onPressed: _saveName),
        ]),
      ),
    );
  }

  void _showStats(BuildContext context, ProfileSummary summary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mis estadísticas', style: AppTypography.section),
          const SizedBox(height: AppSpacing.md),
          AppCard(child: Column(children: [
            _DataLine(label: 'Grupos activos', value: '${summary.groupsCount}'),
            _DataLine(label: 'Saldo total', value: Fmt.money.format(summary.balanceTotal)),
            _DataLine(label: 'Confirmaciones de asistencia', value: '${summary.attendanceYes}/${summary.attendanceTotal}'),
            _DataLine(label: 'Asistencia media', value: '${(summary.attendanceRate * 100).round()}%'),
          ])),
        ]),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final bool avatarBusy;
  final VoidCallback onAvatarTap;

  const _ProfileHero({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.avatarBusy,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          AvatarPicker(url: avatarUrl, fallback: name, onTap: onAvatarTap),
          if (avatarBusy)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(color: Color(0x66FFFFFF), shape: BoxShape.circle),
                child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
            ),
        ]),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTypography.section.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(email, style: AppTypography.muted),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppRadii.pill)),
              child: Text('Perfil activo', style: AppTypography.small.copyWith(color: AppColors.tealDark)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: color.withOpacity(0.11), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.section.copyWith(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.small),
      ]),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}

class _DataLine extends StatelessWidget {
  final String label;
  final String value;

  const _DataLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(child: Text(label, style: AppTypography.muted)),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
