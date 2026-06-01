import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.section.copyWith(fontSize: 18))),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const MetaPill({super.key, required this.icon, required this.text, this.color = AppColors.textMuted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withOpacity(0.13)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(text, style: AppTypography.small.copyWith(color: color)),
      ]),
    );
  }
}

class SoftIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const SoftIconBox({super.key, required this.icon, this.color = AppColors.teal, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadii.md)),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const InfoPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.color = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color.withOpacity(0.08),
      border: BorderSide(color: color.withOpacity(0.15)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIconBox(icon: icon, color: color, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(body, style: AppTypography.muted),
            ]),
          ),
        ],
      ),
    );
  }
}

class DataLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DataLine({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(child: Text(label, style: AppTypography.muted)),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, color: valueColor ?? AppColors.navy)),
      ]),
    );
  }
}
