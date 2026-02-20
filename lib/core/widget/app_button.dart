import 'package:flutter/material.dart';

import '../theme/font_manager.dart';

/// Reusable primary or secondary button with optional loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.expanded = true,
    this.backgroundColor,
    this.foregroundColor,
    this.loadingColor,
    this.padding,
    this.minHeight = 52,
    this.borderRadius = 28,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final bool expanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? loadingColor;
  final EdgeInsetsGeometry? padding;
  final double minHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg = backgroundColor ??
        (variant == AppButtonVariant.primary
            ? theme.colorScheme.primary
            : theme.colorScheme.surface);
    final effectiveFg = foregroundColor ??
        (variant == AppButtonVariant.primary
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface);
    final effectiveLoadingColor = loadingColor ?? effectiveFg.withValues(alpha: 0.6);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(expanded ? double.infinity : 0, minHeight),
            backgroundColor: effectiveBg,
            foregroundColor: effectiveFg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(context, effectiveLoadingColor, effectiveFg),
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(expanded ? double.infinity : 0, minHeight),
            foregroundColor: effectiveFg,
            side: BorderSide(color: effectiveFg.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(context, effectiveLoadingColor, effectiveFg),
        ),
    };

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildChild(BuildContext context, Color loadingColor, Color labelColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: loadingColor,
        ),
      );
    }
    return Text(
      label,
      style: AppFontManager.buttonStyle.copyWith(color: labelColor),
    );
  }
}

enum AppButtonVariant { primary, secondary }
