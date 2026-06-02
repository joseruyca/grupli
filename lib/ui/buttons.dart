import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.teal,
          disabledBackgroundColor: AppColors.teal.withOpacity(0.45),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
        icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.tealDark,
          side: const BorderSide(color: AppColors.teal),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          backgroundColor: AppColors.white,
        ),
        icon: Icon(icon ?? Icons.add_rounded, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }
}

class DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const DestructiveButton({super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: Color(0xFFF2B9B6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          backgroundColor: AppColors.white,
        ),
        icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger)) : const Icon(Icons.logout_rounded, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }
}
