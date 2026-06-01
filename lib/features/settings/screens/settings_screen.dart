import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/auth_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/action_tile.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
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
        const AppHeader(title: 'Ajustes', subtitle: 'Preferencias básicas de Grupli.'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notificaciones', style: AppTypography.section),
            SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('Quedadas')),
            SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('Gastos')),
            SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('Torneos')),
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
