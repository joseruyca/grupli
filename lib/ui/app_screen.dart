import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Base screen used by normal pages.
///
/// Important: this widget must never put a scrollable directly inside Center,
/// Align or another loose-height parent. That is what previously caused white
/// pages where only the bottom navigation remained visible.
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
    final effectivePadding = padding ??
        const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xl,
        );

    final nav = bottomNavigationBar == null
        ? null
        : SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Center(
                widthFactor: 1,
                child: SizedBox(
                  width: math.min(MediaQuery.sizeOf(context).width, maxWidth),
                  child: bottomNavigationBar!,
                ),
              ),
            ),
          );

    return Scaffold(
      backgroundColor: background ?? AppColors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: nav,
      body: SafeArea(
        bottom: bottomNavigationBar == null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = math.min(constraints.maxWidth, maxWidth);

            final page = Center(
              child: SizedBox(
                width: pageWidth,
                child: Padding(
                  padding: effectivePadding,
                  child: child,
                ),
              ),
            );

            if (!scrollable) {
              return page;
            }

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: page,
            );
          },
        ),
      ),
    );
  }
}
