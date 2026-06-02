import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class AppScreen extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final Color? background;
  final double maxWidth;

  const AppScreen({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.scrollable = true,
    this.padding,
    this.background,
    this.maxWidth = 430,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xl);

    final page = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: scrollable
            ? SingleChildScrollView(
                padding: effectivePadding,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: child,
              )
            : Padding(padding: effectivePadding, child: child),
      ),
    );

    return Scaffold(
      backgroundColor: background ?? AppColors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: bottomNavigationBar!,
                  ),
                ),
              ),
            ),
      body: SafeArea(bottom: bottomNavigationBar == null, child: page),
    );
  }
}
