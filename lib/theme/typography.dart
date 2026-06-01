import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  static TextStyle get hero => const TextStyle(
        fontSize: 34,
        height: 1.02,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: -1.1,
      );

  static TextStyle get title => const TextStyle(
        fontSize: 25,
        height: 1.08,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: -0.6,
      );

  static TextStyle get section => const TextStyle(
        fontSize: 18,
        height: 1.15,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 15,
        height: 1.38,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      );

  static TextStyle get muted => const TextStyle(
        fontSize: 13.5,
        height: 1.34,
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
