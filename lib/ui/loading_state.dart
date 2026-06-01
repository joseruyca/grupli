import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class LoadingState extends StatelessWidget {
  final String label;
  const LoadingState({super.key, this.label = 'Cargando...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.teal),
            const SizedBox(height: AppSpacing.md),
            Text(label, style: AppTypography.muted),
          ],
        ),
      ),
    );
  }
}
