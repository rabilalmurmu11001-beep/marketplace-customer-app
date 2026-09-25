import 'package:flutter/material.dart';

class BrandColors {
  static const Color primary = Color(0xFF1E40AF); // Royal Trust Blue
  static const Color accent = Color(0xFF0D9488);  // Teal Cleanliness Accent
  
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkCard = Color(0xFF121826);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

class BrandTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: BrandColors.primary,
      scaffoldBackgroundColor: BrandColors.lightBg,
      cardColor: BrandColors.lightCard,
      dividerColor: BrandColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: BrandColors.primary,
        secondary: BrandColors.accent,
        surface: BrandColors.lightCard,
        background: BrandColors.lightBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: BrandColors.lightTextPrimary,
        onBackground: BrandColors.lightTextPrimary,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: BrandColors.lightTextPrimary),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: BrandColors.lightTextPrimary),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: BrandColors.lightTextPrimary),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: BrandColors.lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: BrandColors.primary,
      scaffoldBackgroundColor: BrandColors.darkBg,
      cardColor: BrandColors.darkCard,
      dividerColor: BrandColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: BrandColors.primary,
        secondary: BrandColors.accent,
        surface: BrandColors.darkCard,
        background: BrandColors.darkBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: BrandColors.darkTextPrimary,
        onBackground: BrandColors.darkTextPrimary,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: BrandColors.darkTextPrimary),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: BrandColors.darkTextPrimary),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: BrandColors.darkTextPrimary),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: BrandColors.darkTextSecondary),
      ),
    );
  }
}
