import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';

class TestChecklistScreen extends StatelessWidget {
  const TestChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Usuario A crea grupo',
      'Usuario B entra por código',
      'B no puede eliminar grupo',
      'A hace admin a B',
      'B admin puede editar grupo',
      'B no puede degradar owner',
      'A regenera código y el anterior deja de servir',
      'B crea gasto solo si participa',
      'B no ve grupos ajenos',
    ];
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppHeader(title: 'Checklist multiusuario', subtitle: 'Pruebas obligatorias antes de considerar Grupli estable.', showBack: true),
        const SizedBox(height: AppSpacing.lg),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(99)), child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 18)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(item, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800))),
            ]),
          ),
        )),
      ]),
    );
  }
}
