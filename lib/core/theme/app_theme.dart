import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Palette ─────────────────────────────────────────────────────────
  static const Color purplePrimary  = Color(0xFF534AB7);
  static const Color purpleLight    = Color(0xFF7F77DD);
  static const Color purpleDim      = Color(0xFF3A3490);
  static const Color blueAccent     = Color(0xFF185FA5);
  static const Color cyanAccent     = Color(0xFF00C8E8);
  static const Color greenAccent    = Color(0xFF00D97E);
  static const Color backgroundDark = Color(0xFF080720);
  static const Color surfaceGlass   = Color(0x14FFFFFF);   // 8 % white
  static const Color borderGlass    = Color(0x33FFFFFF);   // 20 % white
  static const Color borderGlowPurple = Color(0x66534AB7);

  // ── Card Decorations ─────────────────────────────────────────────────────

  /// Standard frosted-glass card
  static BoxDecoration glassCard() => BoxDecoration(
        color: surfaceGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass, width: 0.8),
      );

  /// Elevated glass card with a purple-glow shadow
  static BoxDecoration glassCardGlow() => BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderGlowPurple, width: 1),
        boxShadow: [
          BoxShadow(
            color: purpleLight.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      );

  /// Strong glass card (used for the wallet / hero cards)
  static BoxDecoration glassCardStrong() => BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x55FFFFFF), width: 1),
        boxShadow: [
          BoxShadow(
            color: purpleLight.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
      );

  // ── Backgrounds ──────────────────────────────────────────────────────────

  static BoxDecoration gradientBackground() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0A2E),   // deep navy
            Color(0xFF1E1068),   // rich indigo
            Color(0xFF2A1B6E),   // mid purple
            Color(0xFF101E4A),   // dark blue
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      );

  static BoxDecoration cardGradient({
    Color from = const Color(0xFF6C63FF),
    Color to   = const Color(0xFF3A3490),
  }) => BoxDecoration(
        gradient: LinearGradient(
          colors: [from, to],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: from.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ── Widget Builder (with BackdropFilter) ─────────────────────────────────

  /// Wraps [child] in a BackdropFilter blur — real frosted-glass look.
  static Widget buildGlassCard({
    required Widget child,
    double radius = 20,
    EdgeInsets padding = const EdgeInsets.all(20),
    double sigmaX = 12,
    double sigmaY = 12,
    Color color = const Color(0x14FFFFFF),
    Color border = borderGlass,
    List<BoxShadow>? shadows,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: 0.8),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Buttons ──────────────────────────────────────────────────────────────

  static ButtonStyle primaryButton() => ElevatedButton.styleFrom(
        backgroundColor: purplePrimary,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: purpleLight.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 52),
      );

  static ButtonStyle glowButton({Color color = purplePrimary}) =>
      ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 12,
        shadowColor: color.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(double.infinity, 54),
      );

  // ── Input Fields ─────────────────────────────────────────────────────────

  static InputDecoration glassInput({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0x12FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: purpleLight, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  // ── AppBar ───────────────────────────────────────────────────────────────

  static AppBar glassAppBar({
    required String title,
    List<Widget>? actions,
    bool hasBack = true,
    BuildContext? context,
  }) =>
      AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0x22000000),
        elevation: 0,
        automaticallyImplyLeading: hasBack,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      );

  // ── Badge helpers ────────────────────────────────────────────────────────

  static Widget statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      );

  // ── Theme ────────────────────────────────────────────────────────────────

  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: purplePrimary,
      colorScheme: const ColorScheme.dark(
        primary: purplePrimary,
        secondary: blueAccent,
        surface: surfaceGlass,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton()),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E1068),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white,          fontWeight: FontWeight.w700, fontSize: 24),
        titleMedium:   TextStyle(color: Color(0xB3FFFFFF),    fontWeight: FontWeight.w400, fontSize: 14),
        bodyLarge:     TextStyle(color: Color(0xE6FFFFFF),    fontSize: 16),
        displayLarge:  TextStyle(color: Colors.white,         fontWeight: FontWeight.w900, fontSize: 72),
      ),
    );
  }
}
