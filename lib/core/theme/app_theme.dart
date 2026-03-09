import 'package:flutter/material.dart';

import 'colors_manager.dart';
import 'font_manager.dart';

/// App theme configuration (reference-style).
class AppTheme {
  AppTheme();

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        // Roboto fallback ensures ₱ (U+20B1) renders correctly when Poppins lacks the glyph
        fontFamilyFallback: const ['Roboto'],
        textTheme: AppFontManager.textTheme(ThemeData.light().textTheme),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          error: AppColors.error,
          onError: AppColors.onError,
          inverseSurface: AppColors.primary,
          onInverseSurface: AppColors.onPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 8,
          shadowColor: Color(0x40000000),
          surfaceTintColor: Colors.transparent,
        ),
      );
}
