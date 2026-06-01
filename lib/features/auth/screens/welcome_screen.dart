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
      background: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.groups_2_rounded, color: AppColors.teal, size: 42),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Grupli', style: AppTypography.title.copyWith(fontSize: 36)),
                const SizedBox(height: AppSpacing.md),
                Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(999))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text('Organiza tu grupo\nsin caos.', style: AppTypography.hero, textAlign: TextAlign.left),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Planes, tareas y comunicación en un solo lugar. Menos idas y vueltas, más tiempo para disfrutar.',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (!AppEnv.hasSupabase) ...[
            AppCard(
              color: AppColors.coralSoft,
              border: const BorderSide(color: Color(0xFFF0C6BE)),
              child: Text(
                'Falta configurar Supabase. Copia .env.example a .env y añade SUPABASE_URL + SUPABASE_ANON_KEY.',
                style: AppTypography.muted.copyWith(color: AppColors.navy),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          PrimaryButton(label: 'Iniciar sesión', icon: Icons.login_rounded, onPressed: () => context.go('/login')),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Crear cuenta', icon: Icons.person_add_alt_1_rounded, onPressed: () => context.go('/register')),
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
