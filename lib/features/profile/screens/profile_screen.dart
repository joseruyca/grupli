import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/errors.dart';
import '../../../core/supabase_client.dart';
import '../../../features/auth/auth_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/action_tile.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/avatar.dart';
import '../../../ui/bottom_nav.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/stat_card.dart';
import '../../../ui/toast.dart';
import '../profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _future;
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = ProfileRepository().profile();
  }

  void _refresh() => setState(() => _future = ProfileRepository().profile());

  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 900);
      if (file == null) return;
      await ProfileRepository().uploadAvatar(file);
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  Future<void> _saveName() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ProfileRepository().updateName(_name.text);
      _refresh();
      if (mounted) AppToast.show(context, 'Perfil actualizado.');
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
        const SizedBox(height: AppSpacing.lg),
        if (user == null)
          AppCard(child: Text('Inicia sesión para ver tu perfil.', style: AppTypography.body))
        else
          FutureBuilder<Map<String, dynamic>?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
              final profile = snapshot.data ?? {};
              final name = (profile['full_name'] ?? user.email ?? 'Usuario').toString();
              if (_name.text.isEmpty) _name.text = name;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppCard(
                  child: Row(children: [
                    AvatarPicker(url: profile['avatar_url'] as String?, fallback: name, onTap: _pickAvatar),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: AppTypography.section.copyWith(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(user.email ?? '', style: AppTypography.muted),
                    ])),
                  ]),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(child: StatCard(label: 'Grupos', value: '-', icon: Icons.groups_rounded)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: StatCard(label: 'Balance total', value: '—', icon: Icons.wallet_rounded, color: AppColors.teal)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: StatCard(label: 'Asistencia', value: '—', icon: Icons.trending_up_rounded, color: AppColors.success)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                SectionTitle(title: 'Acciones'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _ProfileAction(icon: Icons.edit_rounded, label: 'Editar nombre', onTap: () => _showEditName(context)),
                    const Divider(height: 1),
                    _ProfileAction(icon: Icons.camera_alt_outlined, label: 'Cambiar foto de perfil', onTap: _pickAvatar),
                    const Divider(height: 1),
                    _ProfileAction(icon: Icons.delete_outline_rounded, label: 'Quitar avatar', onTap: () async { await ProfileRepository().removeAvatar(); _refresh(); }),
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
          AppTextField(controller: _name, label: 'Nombre'),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Guardar perfil', loading: _saving, onPressed: _saveName),
        ]),
      ),
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
