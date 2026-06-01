import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const AppBottomNav({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onChanged,
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.tealSoft,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.groups_rounded), label: 'Grupos'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Ajustes'),
      ],
    );
  }
}
