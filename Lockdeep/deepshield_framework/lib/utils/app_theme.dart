import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF050A14);
  static const Color surface = Color(0xFF0D1B2A);
  static const Color surfaceVariant = Color(0xFF112236);
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonBlueGlow = Color(0x4400D4FF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonRed = Color(0xFFFF3B5C);
  static const Color neonOrange = Color(0xFFFF8C00);
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF7A9BB5);
  static const Color divider = Color(0xFF1A2F45);
  static const Color cardBorder = Color(0xFF1E3A5F);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: neonGreen,
        surface: surface,
        error: neonRed,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
        displayMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1),
        titleMedium: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.8),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        labelLarge: TextStyle(color: neonBlue, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: neonBlue, width: 1.5)),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: Color(0xFF3D5A75)),
        prefixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
        iconTheme: IconThemeData(color: neonBlue),
      ),
      cardTheme: CardThemeData(
  color: surface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: cardBorder, width: 1),
    ),
    ),
    );
  }
}
