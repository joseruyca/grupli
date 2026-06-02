import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class MockHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final VoidCallback? onBack;

  const MockHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      if (showBack) ...[
        _IconBubble(icon: Icons.arrow_back_rounded, onTap: onBack ?? () => context.pop()),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.title.copyWith(fontSize: 24, letterSpacing: -0.65)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvasWarm,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(width: 42, height: 42, child: Icon(icon, color: AppColors.navy, size: 22)),
      ),
    );
  }
}

class MockCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final double radius;

  const MockCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color = AppColors.white,
    this.borderColor = AppColors.border,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.tiny,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: content),
    );
  }
}

class MockPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;

  const MockPill({super.key, required this.label, this.icon, this.color = AppColors.teal, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: selected ? color : color.withOpacity(0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: selected ? Colors.white : color),
          const SizedBox(width: 5),
        ],
        Text(label, style: AppTypography.small.copyWith(color: selected ? Colors.white : color, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class MockThumbnail extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final String? label;

  const MockThumbnail({super.key, required this.icon, this.color = AppColors.teal, this.size = 58, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.95), color.withOpacity(0.45)]),
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: size * 0.44)),
    );
  }
}

class MockAvatarStack extends StatelessWidget {
  final int count;
  final double size;
  const MockAvatarStack({super.key, required this.count, this.size = 25});

  @override
  Widget build(BuildContext context) {
    final shown = count <= 0 ? 3 : (count > 4 ? 4 : count);
    return SizedBox(
      width: shown * (size * 0.62) + size,
      height: size,
      child: Stack(
        children: List.generate(shown, (i) {
          final colors = [AppColors.teal, AppColors.lilac, AppColors.amber, AppColors.success];
          return Positioned(
            left: i * (size * 0.62),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i % colors.length], border: Border.all(color: AppColors.white, width: 2)),
              child: Icon(Icons.person_rounded, size: size * 0.55, color: Colors.white),
            ),
          );
        }),
      ),
    );
  }
}

class MockStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;
  const MockStat({super.key, required this.value, required this.label, this.color = AppColors.teal, this.icon});

  @override
  Widget build(BuildContext context) {
    return MockCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(children: [
        if (icon != null) ...[Icon(icon, color: color, size: 20), const SizedBox(height: 6)],
        Text(value, style: AppTypography.section.copyWith(fontSize: 20, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: AppTypography.small.copyWith(fontSize: 11)),
      ]),
    );
  }
}

class MockSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const MockSectionTitle({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: AppTypography.section.copyWith(fontSize: 17))),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ]);
  }
}

class MockRowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  const MockRowTile({super.key, required this.icon, required this.title, required this.subtitle, this.color = AppColors.teal, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return MockCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(children: [
        MockThumbnail(icon: icon, color: color, size: 48),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
          const SizedBox(height: 3),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.small),
        ])),
        trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ]),
    );
  }
}
