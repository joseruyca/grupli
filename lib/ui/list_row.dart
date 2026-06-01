import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class ListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  const ListRow({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: AppTypography.muted),
      trailing: trailing,
    );
  }
}
