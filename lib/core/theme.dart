import 'package:flutter/material.dart';

/// Design tokens — CRED/Google Pay inspired: deep violet-plum base,
/// warm gold signature accent (ties into "கணக்கு தாள்" coin motif),
/// vivid mint income / coral expense for instant scannability.
class AppColors {
  // Base
  static const bgTop = Color(0xFF1A0B2E);
  static const bgBottom = Color(0xFF0D0620);
  static const bg = Color(0xFF120A22);

  // Surfaces (glass-card feel)
  static const surface = Color(0xFF221636);
  static const surface2 = Color(0xFF2C1E48);
  static const surface3 = Color(0xFF382A56);
  static const border = Color(0xFF3D2E5C);
  static const borderBright = Color(0xFF5B4384);

  // Signature accent
  static const gold = Color(0xFFFFC857);
  static const goldDeep = Color(0xFFE8A93B);
  static const violet = Color(0xFF8B5CF6);
  static const violetDeep = Color(0xFF6B3FA0);

  // Semantic
  static const income = Color(0xFF00D9A3);
  static const incomeDeep = Color(0xFF00A87D);
  static const expense = Color(0xFFFF5C7A);
  static const expenseDeep = Color(0xFFE23A5A);

  // Text
  static const text = Color(0xFFF5F0FF);
  static const text2 = Color(0xFFB8ADD6);
  static const muted = Color(0xFF7A6E9E);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B3FA0), Color(0xFF2D1B4E), Color(0xFF1A0B2E)],
    stops: [0.0, 0.55, 1.0],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD97D), Color(0xFFE8A93B)],
  );

  static const incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E6B8), Color(0xFF00A87D)],
  );

  static const expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A93), Color(0xFFE23A5A)],
  );
}

/// Type scale — bold, tight letter-spacing for numbers/headings (fintech
/// confidence), relaxed spacing for body/captions (readability at small size).
class AppText {
  static const hero = TextStyle(
    fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.text,
    letterSpacing: -0.5, height: 1.0,
  );
  static const h1 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.3,
  );
  static const h2 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.1,
  );
  static const label = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2,
    letterSpacing: 0.6,
  );
  static const body = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.text);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted);
  static const amount = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.3,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkRipple.splashFactory,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.income,
      error: AppColors.expense,
      surface: AppColors.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.gold,
      titleTextStyle: AppText.h1.copyWith(color: AppColors.gold),
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface2,
      selectedColor: AppColors.gold,
      labelStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      labelStyle: const TextStyle(color: AppColors.text2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.borderBright),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.text2,
    ),
  );
}

/// Reusable glass-card decoration used across screens for a consistent
/// premium surface treatment.
BoxDecoration glassCard({Color? color, double radius = 20, Color? borderColor}) => BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppColors.border),
    );
