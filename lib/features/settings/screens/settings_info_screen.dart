import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';

class SettingsInfoScreen extends StatelessWidget {
  final String type;
  const SettingsInfoScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final data = _InfoData.fromType(type);

    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(title: data.title, subtitle: data.subtitle, showBack: true),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(data.icon, color: AppColors.teal, size: 30),
            const SizedBox(height: AppSpacing.md),
            Text(data.title, style: AppTypography.section),
            const SizedBox(height: AppSpacing.md),
            Text(data.body, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }
}

class _InfoData {
  final String title;
  final String subtitle;
  final String body;
  final IconData icon;

  const _InfoData({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
  });

  factory _InfoData.fromType(String type) {
    switch (type) {
      case 'terms':
        return const _InfoData(
          title: 'Términos y condiciones',
          subtitle: 'Documento base para pruebas.',
          icon: Icons.description_outlined,
          body: 'Grupli está en fase de desarrollo. Estas condiciones son una base provisional para explicar el uso de la app: organización de grupos, quedadas, gastos compartidos y torneos. Antes de publicar la app de forma real, habrá que revisar este texto legal completo.',
        );
      case 'privacy':
        return const _InfoData(
          title: 'Política de privacidad',
          subtitle: 'Privacidad básica del proyecto.',
          icon: Icons.shield_outlined,
          body: 'Grupli usa Supabase para autenticar usuarios y guardar datos de grupos, perfiles, asistencia, gastos y torneos. No se debe guardar información sensible innecesaria. Antes de producción habrá que redactar una política completa y adaptada al uso real.',
        );
      case 'help':
      default:
        return const _InfoData(
          title: 'Ayuda y soporte',
          subtitle: 'Guía rápida de uso.',
          icon: Icons.help_outline_rounded,
          body: 'Crea un grupo, comparte el código de invitación y usa cada módulo según necesites: Calendario para quedadas, Finanzas para gastos compartidos y Torneos para competiciones. Si algo falla, prueba a actualizar la pantalla o revisar que el usuario pertenece al grupo.',
        );
    }
  }
}
