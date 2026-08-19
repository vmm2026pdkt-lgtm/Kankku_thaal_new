import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0D0F18);
  static const surface = Color(0xFF161926);
  static const surface2 = Color(0xFF1F2235);
  static const surface3 = Color(0xFF262B42);
  static const border = Color(0xFF2A2F4A);
  static const income = Color(0xFF3ECF8E);
  static const expense = Color(0xFFF05C5C);
  static const gold = Color(0xFFF0A500);
  static const text = Color(0xFFE8EAF6);
  static const text2 = Color(0xFFA8ADC8);
  static const muted = Color(0xFF6B7394);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'NotoSansTamil',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.income,
      error: AppColors.expense,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      foregroundColor: AppColors.gold,
      titleTextStyle: TextStyle(
        color: AppColors.gold,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
