import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.025),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> tiny = [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
