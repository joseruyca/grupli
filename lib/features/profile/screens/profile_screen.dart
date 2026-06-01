import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/errors.dart';
import '../../../core/supabase_client.dart';
import '../../../features/auth/auth_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
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
        AppHeader(title: 'Perfil', subtitle: user?.email ?? 'Sin sesión', trailing: IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))),
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
              _name.text = _name.text.isEmpty ? name : _name.text;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppCard(
                  child: Column(children: [
                    AvatarPicker(url: profile['avatar_url'] as String?, fallback: name, onTap: _pickAvatar),
                    const SizedBox(height: AppSpacing.md),
                    Text(name, style: AppTypography.section),
                    Text(user.email ?? '', style: AppTypography.muted),
                  ]),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(child: StatCard(label: 'Grupos', value: '-', icon: Icons.groups_rounded)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _name, label: 'Nombre'),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(label: 'Guardar perfil', loading: _saving, onPressed: _saveName),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(label: 'Quitar avatar', icon: Icons.delete_outline_rounded, onPressed: () async { await ProfileRepository().removeAvatar(); _refresh(); }),
                const SizedBox(height: AppSpacing.xl),
                DestructiveButton(label: 'Cerrar sesión', onPressed: _logout),
              ]);
            },
          ),
      ]),
    );
  }
}
