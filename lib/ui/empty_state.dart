import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.white,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppRadii.lg)),
            child: Icon(icon, color: AppColors.teal, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.section, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTypography.muted, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ]
        ],
      ),
    );
  }
}
