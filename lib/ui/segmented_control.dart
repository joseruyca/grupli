import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/spacing.dart';

class SegmentedControl extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  const SegmentedControl({super.key, required this.values, required this.selected, required this.onChanged});

  String _label(String value) {
    final lower = value.toLowerCase();
    switch (lower) {
      case 'deporte':
        return 'Deportivo';
      case 'cartas':
        return 'Social';
      case 'otro':
        return 'Otro';
      case 'privado':
        return 'Privado';
      case 'público':
      case 'publico':
        return 'Público';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: values.map((value) {
        final active = value == selected;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: active ? AppColors.tealSoft : AppColors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: active ? AppColors.teal : AppColors.border),
            ),
            child: Text(
              _label(value),
              style: TextStyle(
                color: active ? AppColors.tealDark : AppColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12.8,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
