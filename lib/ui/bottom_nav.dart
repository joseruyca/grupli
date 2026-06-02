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
      height: 60,
      elevation: 0,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.tealSoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: 'Avisos'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
      ],
    );
  }
}
