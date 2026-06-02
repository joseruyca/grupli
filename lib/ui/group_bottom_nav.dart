import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class GroupBottomNav extends StatelessWidget {
  final String groupId;
  final int index;

  const GroupBottomNav({super.key, required this.groupId, required this.index});

  void _go(BuildContext context, int selected) {
    if (selected == index) return;
    final encoded = Uri.encodeComponent(groupId);
    switch (selected) {
      case 0:
        context.go('/app/groups/$encoded/events');
        break;
      case 1:
        context.go('/app/groups/$encoded/calendar');
        break;
      case 2:
        context.go('/app/groups/$encoded/finances');
        break;
      case 3:
        context.go('/app/groups/$encoded/tournaments');
        break;
      default:
        context.go('/app/groups/$encoded');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _go(context, i),
        height: 66,
        elevation: 0,
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.tealSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available_rounded), label: 'Eventos'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Calendario'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Finanzas'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events_rounded), label: 'Torneos'),
          NavigationDestination(icon: Icon(Icons.more_horiz_rounded), selectedIcon: Icon(Icons.more_horiz_rounded), label: 'Más'),
        ],
      ),
    );
  }
}

class GroupContextHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool showBack;

  const GroupContextHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      if (showBack) ...[
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.navy,
          style: IconButton.styleFrom(backgroundColor: AppColors.canvasWarm),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.title.copyWith(fontSize: 24)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.small),
        ]),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}
