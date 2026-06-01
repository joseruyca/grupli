import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppToast {
  static void show(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
