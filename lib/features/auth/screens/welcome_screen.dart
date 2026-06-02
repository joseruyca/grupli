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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 26),
        Container(
          height: 430,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF12A39E), Color(0xFF075C62)],
            ),
          ),
          child: Stack(children: [
            Positioned.fill(child: _Pattern()),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.94), borderRadius: BorderRadius.circular(30)),
                  child: const Icon(Icons.groups_2_rounded, color: AppColors.tealDark, size: 48),
                ),
                const SizedBox(height: 20),
                Text('grupli', style: AppTypography.hero.copyWith(color: Colors.white, fontSize: 46, letterSpacing: -1.6)),
                const SizedBox(height: 18),
                Text('Organiza tu grupo.\nDisfruta más.', textAlign: TextAlign.center, style: AppTypography.section.copyWith(color: Colors.white, fontSize: 20)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),
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
        PrimaryButton(label: 'Comenzar', icon: Icons.arrow_forward_rounded, onPressed: () => context.go('/login')),
        const SizedBox(height: 12),
        Center(child: TextButton(onPressed: () => context.go('/login'), child: const Text('Iniciar sesión'))),
      ]),
    );
  }
}

class _Pattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const icons = [Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_2_rounded];
    return Wrap(
      spacing: 28,
      runSpacing: 28,
      children: List.generate(40, (i) => Icon(icons[i % icons.length], size: 18, color: Colors.white.withOpacity(0.12))),
    );
  }
}
