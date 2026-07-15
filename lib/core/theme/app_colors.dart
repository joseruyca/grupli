part of grupli_app;

class AppColors {
  // Grupli v16.34 design tokens: warm, calm and readable.
  static const bgShell = Color(0xFFF4F7F6);
  static const white = Color(0xFFFFFFFF);
  static const paper = Color(0xFFFFFEFB);
  static const cream = Color(0xFFFBF7F0);
  static const ink = Color(0xFF102133);
  static const inkSoft = Color(0xFF28384A);
  static const muted = Color(0xFF687589);
  static const faint = Color(0xFFF7FAF9);
  static const surface = Color(0xFFFEFFFE);
  static const surfaceWarm = Color(0xFFFFFCF6);
  static const line = Color(0xFFE1E9EF);
  static const lineSoft = Color(0xFFF0F4F6);
  static const hairline = Color(0xFFEAF0F3);
  static const teal = Color(0xFF0E6B73);
  static const tealDark = Color(0xFF073A4A);
  static const tealSoft = Color(0xFFE7F3F1);
  static const tealMist = Color(0xFFF1F8F7);
  static const navy = Color(0xFF062C3B);
  static const navyDeep = Color(0xFF041A25);
  static const blue = Color(0xFF315F8C);
  static const blueSoft = Color(0xFFEAF2F8);
  static const violet = Color(0xFF6D5A86);
  static const violetSoft = Color(0xFFF2EFF7);
  static const orange = Color(0xFFD69027);
  static const orangeSoft = Color(0xFFFFF3DF);
  static const green = Color(0xFF2F8B57);
  static const greenDark = Color(0xFF276E48);
  static const greenSoft = Color(0xFFEAF5EE);
  static const red = Color(0xFFC75B4C);
  static const redSoft = Color(0xFFFBEDEA);
  static const amber = Color(0xFFD69A28);
  static const amberSoft = Color(0xFFFFF4DC);
  static const humanAccent = Color(0xFFD65B46);
  static const humanAccentSoft = Color(0xFFFFEFEA);
  static const navHome = Color(0xFF073A4A);
  static const navAgenda = Color(0xFFDFA22E);
  static const navFinance = Color(0xFF2F8B57);
  static const navTournaments = Color(0xFFC75B4C);
  static const navMore = Color(0xFF6D5578);

  static const softShadow = Color(0x0D102133);
  static const mediumShadow = Color(0x18102133);

  static BorderRadius get humanRadius => const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(12),
      );

  static BorderRadius get softRadius => const BorderRadius.only(
        topLeft: Radius.circular(14),
        topRight: Radius.circular(26),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(16),
      );
}
