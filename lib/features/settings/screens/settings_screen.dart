import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/auth_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/action_tile.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/bottom_nav.dart';
import '../../../ui/buttons.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/toast.dart';
import '../settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<UserSettings> _future;
  UserSettings _settings = const UserSettings();
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UserSettings> _load() async {
    final settings = await SettingsRepository().load();
    _settings = settings;
    _loaded = true;
    return settings;
  }

  Future<void> _save(UserSettings settings) async {
    setState(() {
      _settings = settings;
      _saving = true;
    });

    try {
      await SettingsRepository().save(settings);
      if (mounted) AppToast.show(context, 'Ajustes guardados.');
    } catch (e) {
      if (mounted) AppToast.show(context, 'No se pudieron guardar los ajustes. Ejecuta el SQL de v8 si aún no lo hiciste.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      bottomNavigationBar: AppBottomNav(
        index: 1,
        onChanged: (i) {
          if (i == 0) context.go('/app');
          if (i == 1) context.go('/app/settings');
          if (i == 2) context.go('/app/profile');
        },
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Ajustes', style: AppTypography.title),
          const Spacer(),
          if (_saving)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Text('Preferencias básicas y estado de la app.', style: AppTypography.muted),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<UserSettings>(
          future: _future,
          builder: (context, snapshot) {
            if (!_loaded && snapshot.connectionState == ConnectionState.waiting) return const LoadingState();

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Notificaciones', style: AppTypography.section.copyWith(fontSize: 18)),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingSwitch(
                    icon: Icons.event_available_rounded,
                    title: 'Quedadas',
                    subtitle: 'Recordatorios y actualizaciones',
                    value: _settings.notifyEvents,
                    onChanged: (value) => _save(_settings.copyWith(notifyEvents: value)),
                  ),
                  _SettingSwitch(
                    icon: Icons.receipt_long_rounded,
                    title: 'Gastos',
                    subtitle: 'Nuevos gastos y vencimientos',
                    value: _settings.notifyExpenses,
                    onChanged: (value) => _save(_settings.copyWith(notifyExpenses: value)),
                  ),
                  _SettingSwitch(
                    icon: Icons.emoji_events_rounded,
                    title: 'Torneos',
                    subtitle: 'Resultados y novedades',
                    value: _settings.notifyTournaments,
                    onChanged: (value) => _save(_settings.copyWith(notifyTournaments: value)),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _SettingsRow(icon: Icons.light_mode_outlined, title: 'Tema', trailing: 'Claro', onTap: () => AppToast.show(context, 'El modo claro queda fijado por ahora.')),
                  const Divider(height: 1),
                  _SettingsRow(icon: Icons.description_outlined, title: 'Términos y condiciones', trailing: '', onTap: () => context.go('/app/settings/terms')),
                  const Divider(height: 1),
                  _SettingsRow(icon: Icons.shield_outlined, title: 'Política de privacidad', trailing: '', onTap: () => context.go('/app/settings/privacy')),
                  const Divider(height: 1),
                  _SettingsRow(icon: Icons.help_outline_rounded, title: 'Ayuda y soporte', trailing: '', onTap: () => context.go('/app/settings/help')),
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              ActionTile(title: 'Checklist de prueba', subtitle: 'Validar flujo multiusuario.', icon: Icons.fact_check_rounded, color: AppColors.lilac, onTap: () => context.go('/app/test-checklist')),
              const SizedBox(height: AppSpacing.xl),
              DestructiveButton(label: 'Cerrar sesión', onPressed: () async { await AuthService().signOut(); if (context.mounted) context.go('/'); }),
            ]);
          },
        ),
      ]),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.teal,
      secondary: Icon(icon, color: AppColors.navy),
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: AppTypography.small),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailing.isNotEmpty) Text(trailing, style: AppTypography.small),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ]),
      onTap: onTap,
    );
  }
}
