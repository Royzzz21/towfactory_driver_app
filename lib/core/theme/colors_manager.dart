import 'package:flutter/material.dart';

/// Centralized app colors. Black and white theme.
abstract final class AppColors {
  AppColors._();

  // --- Light theme (black & white) ---
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF212121);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);
  static const Color error = Color(0xFF212121);
  static const Color onError = Color(0xFFFFFFFF);

  // --- Dark / surface backgrounds ---
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF000000);

  /// Text and icons on dark backgrounds (e.g. login).
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Borders on dark backgrounds.
  static const Color borderOnDark = Color(0xFF616161);

  /// Error text and borders (works on light and dark).
  static const Color errorMuted = Color(0xFF616161);

  /// Input fill on dark (white overlay).
  static Color get inputFillOnDark => Colors.white.withValues(alpha: 0.2);

  // --- SnackBar / toasts ---
  static const Color snackBarError = Color(0xFF212121);
  static const Color snackBarSuccess = Color(0xFF424242);
  static const Color snackBarText = Color(0xFFFFFFFF);

  // --- Status bar (for SystemChrome) ---
  static const Color statusBarBackground = Color(0xFFFFFFFF);
}
