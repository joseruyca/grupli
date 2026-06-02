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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 10),
        Container(
          height: 420,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF009B95), Color(0xFF005F72)]),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            const _WelcomePattern(),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.94), borderRadius: BorderRadius.circular(30)),
                  child: const Icon(Icons.groups_2_rounded, color: AppColors.tealDark, size: 48),
                ),
                const SizedBox(height: 20),
                Text('grupli', style: AppTypography.hero.copyWith(color: Colors.white, fontSize: 48, letterSpacing: -2)),
                const SizedBox(height: 18),
                Text('Organiza tu grupo.\nDisfruta más.', textAlign: TextAlign.center, style: AppTypography.section.copyWith(color: Colors.white, fontSize: 20)),
                const SizedBox(height: 28),
                SizedBox(
                  width: 196,
                  child: FilledButton(onPressed: () => context.go('/login'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.tealDark), child: const Text('Comenzar', style: TextStyle(fontWeight: FontWeight.w900))),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: () => context.go('/login'), child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        Text('La app privada para coordinar grupos sin caos.', textAlign: TextAlign.center, style: AppTypography.section.copyWith(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Eventos, calendario, finanzas y torneos en un único espacio cerrado.', textAlign: TextAlign.center, style: AppTypography.muted),
        if (!AppEnv.hasSupabase) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: AppColors.coralSoft,
            border: const BorderSide(color: Color(0xFFF0C6BE)),
            child: Text('Falta configurar Supabase en .env.', style: AppTypography.muted.copyWith(color: AppColors.navy)),
          ),
        ],
      ]),
    );
  }
}

class _WelcomePattern extends StatelessWidget {
  const _WelcomePattern();

  @override
  Widget build(BuildContext context) {
    const icons = [Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_2_rounded];
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Wrap(
        spacing: 28,
        runSpacing: 30,
        children: List.generate(54, (i) => Icon(icons[i % icons.length], size: 18, color: Colors.white.withOpacity(0.12))),
      ),
    );
  }
}
