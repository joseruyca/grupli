import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class MemberAvatar extends StatelessWidget {
  final String? url;
  final String fallback;
  final double size;
  const MemberAvatar({super.key, this.url, required this.fallback, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final initial = fallback.trim().isEmpty ? '?' : fallback.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.mintSoft,
      backgroundImage: url == null || url!.isEmpty ? null : NetworkImage(url!),
      child: url == null || url!.isEmpty
          ? Text(initial, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900))
          : null,
    );
  }
}

class AvatarPicker extends StatelessWidget {
  final String? url;
  final String fallback;
  final VoidCallback? onTap;
  const AvatarPicker({super.key, this.url, required this.fallback, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          MemberAvatar(url: url, fallback: fallback, size: 86),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(AppRadii.pill)),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
          )
        ],
      ),
    );
  }
}
