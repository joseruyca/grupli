import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const AppBottomNav({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onChanged,
      height: 66,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.mintSoft,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.groups_rounded), label: 'Grupos'),
        NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
      ],
    );
  }
}
