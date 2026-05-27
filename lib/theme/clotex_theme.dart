import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClotexColors {
  static const Color primary = Colors.black;
  static const Color background = Colors.white;
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF757575);
  static const Color accent = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color error = Color(0xFFB00020);
}

class ClotexTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ClotexColors.primary,
      scaffoldBackgroundColor: ClotexColors.background,
      colorScheme: const ColorScheme.light(
        primary: ClotexColors.primary,
        onPrimary: Colors.white,
        surface: ClotexColors.background,
        onSurface: ClotexColors.textPrimary,
        error: ClotexColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ClotexColors.textPrimary,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ClotexColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ClotexColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 16,
          color: ClotexColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14,
          color: ClotexColors.textSecondary,
        ),
        labelLarge: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: ClotexColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ClotexColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ClotexColors.textPrimary,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: ClotexColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: ClotexColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
