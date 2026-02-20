import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography using Google Fonts (Poppins).
/// Use [textTheme] in [ThemeData] or call [AppFontManager] styles directly.
abstract final class AppFontManager {
  AppFontManager._();

  /// Primary font family (used for text theme).
  static String get primaryFamily => GoogleFonts.poppins().fontFamily!;

  /// Secondary font family (same as primary for consistent Poppins across the app).
  static String get secondaryFamily => GoogleFonts.poppins().fontFamily!;

  /// Full [TextTheme] for the app. Pass [ThemeData.light().textTheme] or dark.
  static TextTheme textTheme([TextTheme? base]) {
    final theme = base ?? ThemeData.light().textTheme;
    return GoogleFonts.poppinsTextTheme(theme);
  }

  /// Headline / branding style (e.g. logo, hero text).
  static TextStyle get brandStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  /// Button label style.
  static TextStyle get buttonStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  /// Body medium with optional color.
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Title large with optional color.
  static TextStyle titleLarge({Color? color}) => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
