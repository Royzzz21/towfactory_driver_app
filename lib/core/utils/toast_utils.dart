import 'package:flutter/material.dart';

import '../theme/colors_manager.dart';
import '../theme/font_manager.dart';

/// SnackBar / toast helpers with success and error variants.
abstract final class ToastUtils {
  ToastUtils._();

  /// Shows a success snackbar (green background).
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.snackBarSuccess,
    );
  }

  /// Shows an error snackbar (red background).
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.snackBarError,
    );
  }

  /// Shows a neutral/info snackbar (dark background).
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.surfaceDark,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFontManager.bodyMedium(color: AppColors.snackBarText),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
