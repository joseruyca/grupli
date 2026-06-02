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
    final effectivePadding = padding ??
        const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xl,
        );

    return Scaffold(
      backgroundColor: background ?? AppColors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
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
      body: SafeArea(
        bottom: bottomNavigationBar == null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : maxWidth;
            final availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
            final pageWidth = availableWidth < maxWidth ? availableWidth : maxWidth;

            final page = SizedBox(
              width: pageWidth,
              height: availableHeight,
              child: scrollable
                  ? ListView(
                      padding: effectivePadding,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [child],
                    )
                  : Padding(
                      padding: effectivePadding,
                      child: child,
                    ),
            );

            return Align(
              alignment: Alignment.topCenter,
              child: page,
            );
          },
        ),
      ),
    );
  }
}
