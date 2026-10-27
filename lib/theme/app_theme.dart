import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medguide/services/app_preferences.dart';

class AppColors {
  static bool get dark => AppPreferences.instance.darkMode;
  static Color get primaryBlue =>
      dark ? const Color(0xFF7BB7F5) : const Color(0xFF0A3D62);
  static Color get teal =>
      dark ? const Color(0xFF58D8D0) : const Color(0xFF087F7A);
  static Color get background =>
      dark ? const Color(0xFF0C1422) : const Color(0xFFF8F9FA);
  static Color get amber =>
      dark ? const Color(0xFFFFBD62) : const Color(0xFFA45C00);
  static Color get danger =>
      dark ? const Color(0xFFFF7972) : const Color(0xFFC4332D);
  static Color get success =>
      dark ? const Color(0xFF65D4A2) : const Color(0xFF187443);
  static Color get cardWhite =>
      dark ? const Color(0xFF172436) : const Color(0xFFFFFFFF);
  static Color get textPrimary =>
      dark ? const Color(0xFFF2F6FC) : const Color(0xFF1A2332);
  static Color get textSecondary =>
      dark ? const Color(0xFFB4C3D5) : const Color(0xFF627287);
  static Color get textLight =>
      dark ? const Color(0xFF91A5BA) : const Color(0xFF64748B);
  static Color get border =>
      dark ? const Color(0xFF34465C) : const Color(0xFFE4E9F0);
  static Color get surfaceBlue =>
      dark ? const Color(0xFF1C3550) : const Color(0xFFEBF3FA);
  static Color get surfaceTeal =>
      dark ? const Color(0xFF153B41) : const Color(0xFFE6F9F8);
  static Color get riskLow => success;
  static Color get riskMedium => amber;
  static Color get riskHigh => danger;
  static Color get brandSolid => dark ? const Color(0xFF245D91) : primaryBlue;
  static Color get heroStart =>
      dark ? const Color(0xFF183B64) : const Color(0xFF0A3D62);
  static Color get heroEnd =>
      dark ? const Color(0xFF126B70) : const Color(0xFF0FB9B1);
  static List<Color> get femaleGradient => dark
      ? const [Color(0xFF322053), Color(0xFF7845A8)]
      : const [Color(0xFF6B42B8), Color(0xFFAA70D6)];
  static List<Color> get clinicianFemaleGradient => dark
      ? const [Color(0xFF211238), Color(0xFF5A348D), Color(0xFF7C4CA7)]
      : const [Color(0xFF28154F), Color(0xFF6840AE), Color(0xFFA66AD7)];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: AppColors.dark ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: AppColors.dark ? Brightness.dark : Brightness.light,
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.teal,
        surface: AppColors.cardWhite,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.dmSansTextTheme()
          .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary)
          .copyWith(
        displayLarge: GoogleFonts.dmSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.dmSans(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textLight,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlue,
          letterSpacing: 0.1,
        ),
      ),

      // ✅ FIXED HERE
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandSolid,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.danger,
            width: 1.5,
          ),
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textLight,
        ),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: GoogleFonts.dmSans(color: AppColors.primaryBlue),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        errorStyle: GoogleFonts.dmSans(color: AppColors.danger),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: AppColors.primaryBlue,
        ),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
