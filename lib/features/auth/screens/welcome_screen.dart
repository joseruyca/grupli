import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/env.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      background: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.groups_2_rounded, color: AppColors.teal, size: 30),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Grupli', style: AppTypography.title),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text('Organiza tu grupo sin caos.', style: AppTypography.hero),
          const SizedBox(height: AppSpacing.md),
          Text('Quedadas, asistencia, gastos compartidos y torneos en una app simple para grupos reales.', style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.xxl),
          if (!AppEnv.hasSupabase) ...[
            AppCard(
              color: AppColors.coralSoft,
              border: const BorderSide(color: Color(0xFFFFCFC7)),
              child: Text('Falta configurar Supabase. Copia .env.example a .env y añade SUPABASE_URL + SUPABASE_ANON_KEY.', style: AppTypography.muted.copyWith(color: AppColors.navy)),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          PrimaryButton(label: 'Iniciar sesión', icon: Icons.login_rounded, onPressed: () => context.go('/login')),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Crear cuenta', icon: Icons.person_add_rounded, onPressed: () => context.go('/register')),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => context.go('/recover'),
              child: const Text('Recuperar contraseña'),
            ),
          ),
        ],
      ),
    );
  }
}
