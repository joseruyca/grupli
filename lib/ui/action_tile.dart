import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';

class ActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  const ActionTile({super.key, required this.title, this.subtitle, required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: (color ?? AppColors.teal).withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadii.md)),
            child: Icon(icon, color: color ?? AppColors.teal),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
              if (subtitle != null) Text(subtitle!, style: AppTypography.muted),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
