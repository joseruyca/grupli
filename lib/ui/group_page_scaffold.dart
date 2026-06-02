import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'group_bottom_nav.dart';

/// Stable scaffold for pages that live inside a group.
///
/// This intentionally avoids AppScreen. The group detail page and the 4 main
/// group tabs always need a visible body plus a fixed group bottom navigation.
/// Keep this shell simple: Scaffold -> SafeArea -> SingleChildScrollView.
class GroupPageScaffold extends StatelessWidget {
  final String groupId;
  final int navIndex;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const GroupPageScaffold({
    super.key,
    required this.groupId,
    required this.navIndex,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.xl),
    this.maxWidth = 430,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SafeArea(
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
              child: GroupBottomNav(groupId: groupId, index: navIndex),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = math.min(constraints.maxWidth, maxWidth);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: SizedBox(
                  width: pageWidth,
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
