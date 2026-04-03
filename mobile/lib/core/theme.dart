import 'package:flutter/material.dart';

class KawachColors {
  static const background = Color(0xFF0A0A0A);
  static const surfaceOne = Color(0xFF141414);
  static const surfaceTwo = Color(0xFF1E1E1E);
  static const indigo = Color(0xFF6366F1);
  static const indigoLight = Color(0xFF818CF8);
  static const gold = Color(0xFFD4A853);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const borderSubtle = Color(0xFF2A2A2A);
  static const borderActive = Color(0x406366F1);
}

ThemeData buildKawachTheme() {
  const baseText = TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: KawachColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: KawachColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 15,
      color: KawachColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      color: KawachColors.textSecondary,
    ),
  );

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KawachColors.background,
    colorScheme: const ColorScheme.dark(
      primary: KawachColors.indigo,
      secondary: KawachColors.gold,
      surface: KawachColors.surfaceOne,
    ),
    textTheme: baseText,
    appBarTheme: const AppBarTheme(
      backgroundColor: KawachColors.background,
      foregroundColor: KawachColors.textPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: KawachColors.surfaceOne,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: KawachColors.borderSubtle),
      ),
    ),
  );
}
