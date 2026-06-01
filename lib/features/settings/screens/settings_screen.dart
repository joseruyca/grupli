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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      bottomNavigationBar: AppBottomNav(
        index: 2,
        onChanged: (i) {
          if (i == 0) context.go('/app');
          if (i == 1) context.go('/app/profile');
        },
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ajustes', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text('Preferencias básicas y estado de la app.', style: AppTypography.muted),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notificaciones', style: AppTypography.section.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.sm),
            _SettingSwitch(icon: Icons.event_available_rounded, title: 'Quedadas', subtitle: 'Recordatorios y actualizaciones'),
            _SettingSwitch(icon: Icons.receipt_long_rounded, title: 'Gastos', subtitle: 'Nuevos gastos y vencimientos'),
            _SettingSwitch(icon: Icons.emoji_events_rounded, title: 'Torneos', subtitle: 'Resultados y novedades'),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: const [
            _SettingsRow(icon: Icons.light_mode_outlined, title: 'Tema', trailing: 'Claro'),
            Divider(height: 1),
            _SettingsRow(icon: Icons.description_outlined, title: 'Términos y condiciones', trailing: 'Próximamente'),
            Divider(height: 1),
            _SettingsRow(icon: Icons.shield_outlined, title: 'Política de privacidad', trailing: 'Próximamente'),
            Divider(height: 1),
            _SettingsRow(icon: Icons.help_outline_rounded, title: 'Ayuda y soporte', trailing: ''),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        ActionTile(title: 'Checklist de prueba', subtitle: 'Validar flujo multiusuario.', icon: Icons.fact_check_rounded, color: AppColors.lilac, onTap: () => context.go('/app/test-checklist')),
        const SizedBox(height: AppSpacing.xl),
        DestructiveButton(label: 'Cerrar sesión', onPressed: () async { await AuthService().signOut(); if (context.mounted) context.go('/'); }),
      ]),
    );
  }
}

class _SettingSwitch extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SettingSwitch({required this.icon, required this.title, required this.subtitle});

  @override
  State<_SettingSwitch> createState() => _SettingSwitchState();
}

class _SettingSwitchState extends State<_SettingSwitch> {
  bool value = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (v) => setState(() => value = v),
      activeColor: AppColors.teal,
      secondary: Icon(widget.icon, color: AppColors.navy),
      title: Text(widget.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
      subtitle: Text(widget.subtitle, style: AppTypography.small),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;
  const _SettingsRow({required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailing.isNotEmpty) Text(trailing, style: AppTypography.small),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ]),
    );
  }
}
