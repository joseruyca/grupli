import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/errors.dart';
import '../../../features/auth/auth_service.dart';
import '../../../shared/utils/formatters.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/bottom_nav.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/mock_ui.dart';
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
      if (mounted) AppToast.show(context, 'Foto actualizada.');
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
    return AppScreen(
      bottomNavigationBar: AppBottomNav(
        index: 2,
        onChanged: (i) {
          if (i == 0) context.go('/app');
          if (i == 1) context.go('/app/settings');
          if (i == 2) context.go('/app/profile');
        },
      ),
      child: FutureBuilder<ProfileSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
          if (snapshot.hasError) return MockCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));
          final summary = snapshot.data!;
          final profile = summary.profile;
          final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
          final email = (profile['email'] ?? '').toString();
          final avatar = profile['avatar_url']?.toString();
          _name.text = name;

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Spacer(), IconButton(onPressed: _refresh, icon: const Icon(Icons.more_horiz_rounded), color: AppColors.navy)]),
            Center(child: _Avatar(url: avatar, busy: _avatarBusy, onTap: _pickAvatar)),
            const SizedBox(height: 12),
            Center(child: Text(name, style: AppTypography.title.copyWith(fontSize: 24), textAlign: TextAlign.center)),
            const SizedBox(height: 3),
            Center(child: Text(email, style: AppTypography.small, textAlign: TextAlign.center)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: MockStat(value: '${summary.groupsCount}', label: 'Grupos', icon: Icons.groups_rounded)),
              const SizedBox(width: 8),
              Expanded(child: MockStat(value: Fmt.money.format(summary.balanceTotal), label: 'Saldo', icon: Icons.euro_rounded, color: AppColors.success)),
              const SizedBox(width: 8),
              Expanded(child: MockStat(value: '${(summary.attendanceRate * 100).round()}%', label: 'Asistencia', icon: Icons.event_available_rounded, color: AppColors.lilac)),
            ]),
            const SizedBox(height: 18),
            MockCard(padding: EdgeInsets.zero, child: Column(children: [
              _ProfileAction(icon: Icons.edit_rounded, label: 'Editar perfil', onTap: () => _showEditName(context)),
              const Divider(height: 1),
              _ProfileAction(icon: Icons.camera_alt_outlined, label: 'Cambiar foto', onTap: _pickAvatar),
              const Divider(height: 1),
              _ProfileAction(icon: Icons.no_photography_outlined, label: 'Quitar foto', onTap: _removeAvatar),
              const Divider(height: 1),
              _ProfileAction(icon: Icons.settings_outlined, label: 'Ajustes', onTap: () => context.go('/app/settings')),
            ])),
            const SizedBox(height: 22),
            DestructiveButton(label: 'Cerrar sesión', onPressed: _logout),
          ]);
        },
      ),
    );
  }

  void _showEditName(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
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
}

class _Avatar extends StatelessWidget {
  final String? url;
  final bool busy;
  final VoidCallback onTap;
  const _Avatar({required this.url, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.tealSoft,
          backgroundImage: hasImage ? NetworkImage(url!) : null,
          child: hasImage ? null : const Icon(Icons.person_rounded, color: AppColors.teal, size: 46),
        ),
        Positioned(
          right: -2,
          bottom: 2,
          child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle), child: busy ? const Padding(padding: EdgeInsets.all(7), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16)),
        ),
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
      title: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
