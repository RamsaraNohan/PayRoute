import 'package:flutter/material.dart';

class AppTheme {
  static const Color purplePrimary = Color(0xFF534AB7);
  static const Color purpleLight = Color(0xFF7F77DD);
  static const Color blueAccent = Color(0xFF185FA5);
  static const Color backgroundDark = Color(0xFF0D0B2B);
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color borderGlass = Color(0x33FFFFFF);

  static BoxDecoration glassCard() => BoxDecoration(
        color: surfaceGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass, width: 0.5),
      );

  static BoxDecoration gradientBackground() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1560), Color(0xFF3D2B8A), Color(0xFF1A3A6B)],
        ),
      );

  static ButtonStyle primaryButton() => ElevatedButton.styleFrom(
        backgroundColor: purplePrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 52),
      );

  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: purplePrimary,
      colorScheme: const ColorScheme.dark(
        primary: purplePrimary,
        secondary: blueAccent,
        surface: surfaceGlass,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton()),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24),
        titleMedium: TextStyle(color: Color(0xB3FFFFFF), fontWeight: FontWeight.w400, fontSize: 14),
        bodyLarge: TextStyle(color: Color(0xE6FFFFFF), fontSize: 16),
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 72),
      ),
    );
  }
}
