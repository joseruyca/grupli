import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> tiny = [
    BoxShadow(
      color: Colors.black.withOpacity(0.035),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
