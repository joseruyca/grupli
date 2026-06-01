import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  static TextStyle get hero => const TextStyle(
        fontSize: 34,
        height: 1.05,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: -1.15,
      );

  static TextStyle get title => const TextStyle(
        fontSize: 28,
        height: 1.08,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: -0.85,
      );

  static TextStyle get section => const TextStyle(
        fontSize: 20,
        height: 1.12,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: -0.45,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 15,
        height: 1.42,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      );

  static TextStyle get muted => const TextStyle(
        fontSize: 13.5,
        height: 1.38,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get small => const TextStyle(
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      );
}
