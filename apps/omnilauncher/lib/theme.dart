import 'package:flutter/material.dart';

/// FORGE luxury palette — mirrors the website (docs/styles.css).
class ForgeColors {
  ForgeColors._();
  static const bg = Color(0xFF0A0E17);
  static const bg2 = Color(0xFF0F1524);
  static const card = Color(0xFF131B30);
  static const cardSoft = Color(0xFF0E1528);
  static const line = Color(0xFF1E2A47);
  static const txt = Color(0xFFE8EDF7);
  static const mut = Color(0xFF9AA7C4);
  static const cy = Color(0xFF22D3EE);
  static const mg = Color(0xFFF472B6);
  static const vi = Color(0xFFA78BFA);
  static const gr = Color(0xFF34D399);
  static const gold = Color(0xFFE8C15A);
  static const gold2 = Color(0xFFB98A2E);
  static const onCy = Color(0xFF04121A);

  static Color tint(Color c, double alpha) => c.withValues(alpha: alpha);

  static const heroGradient = LinearGradient(colors: [cy, Color(0xFF0EA5E9)]);
  static const goldGradient = LinearGradient(colors: [gold, gold2]);
  static const cardGradient =
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [card, cardSoft]);
}

/// Material 3 dark theme using the FORGE palette.
ThemeData forgeDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ForgeColors.cy,
    brightness: Brightness.dark,
  ).copyWith(
    primary: ForgeColors.cy,
    onPrimary: ForgeColors.onCy,
    secondary: ForgeColors.gold,
    onSecondary: const Color(0xFF1A1206),
    surface: ForgeColors.card,
    onSurface: ForgeColors.txt,
    error: const Color(0xFFF87171),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ForgeColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: ForgeColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: ForgeColors.txt,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: ForgeColors.txt),
    ),
    cardTheme: CardThemeData(
      color: ForgeColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ForgeColors.line),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ForgeColors.bg2,
      selectedColor: ForgeColors.cy,
      labelStyle: const TextStyle(color: ForgeColors.mut, fontSize: 12),
      secondaryLabelStyle: const TextStyle(color: ForgeColors.onCy),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: const BorderSide(color: ForgeColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ForgeColors.bg2,
      labelStyle: const TextStyle(color: ForgeColors.mut),
      hintStyle: const TextStyle(color: ForgeColors.mut),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ForgeColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ForgeColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ForgeColors.cy),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: ForgeColors.cy,
      inactiveTrackColor: ForgeColors.line,
      thumbColor: ForgeColors.gold,
      valueIndicatorColor: ForgeColors.gold,
      valueIndicatorTextStyle: TextStyle(color: ForgeColors.onCy, fontWeight: FontWeight.bold),
    ),
    dividerTheme: const DividerThemeData(color: ForgeColors.line),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ForgeColors.cy,
      foregroundColor: ForgeColors.onCy,
      elevation: 6,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ForgeColors.card,
      contentTextStyle: TextStyle(color: ForgeColors.txt),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: ForgeColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ForgeColors.line),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: ForgeColors.cy,
      unselectedLabelColor: ForgeColors.mut,
      indicatorColor: ForgeColors.cy,
      dividerColor: ForgeColors.line,
    ),
  );
}