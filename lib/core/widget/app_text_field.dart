import 'package:flutter/material.dart';

import '../theme/colors_manager.dart';
import '../theme/font_manager.dart';

/// Reusable text field with app styling. Supports dark/light variant and optional password toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.errorText,
    this.obscureText = false,
    this.showPasswordToggle = true,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.variant = AppTextFieldVariant.light,
    this.autofillHints,
    this.autocorrect = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  /// When set, shown as field error (e.g. from API 422 validation).
  final String? errorText;
  final bool obscureText;
  final bool showPasswordToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Widget? prefixIcon;
  final AppTextFieldVariant variant;
  final List<String>? autofillHints;
  final bool autocorrect;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  bool get _isDark => widget.variant == AppTextFieldVariant.dark;

  Color get _labelColor =>
      _isDark ? AppColors.textOnDark : Theme.of(context).colorScheme.onSurface;

  Color get _hintColor => _isDark
      ? AppColors.textOnDark.withValues(alpha: 0.6)
      : Theme.of(context).hintColor;

  Color get _borderColor =>
      _isDark ? AppColors.borderOnDark : Theme.of(context).dividerColor;

  Color get _focusedBorderColor => _isDark
      ? AppColors.textOnDark.withValues(alpha: 0.8)
      : Theme.of(context).colorScheme.primary;

  Color get _fillColor =>
      _isDark
          ? AppColors.inputFillOnDark
          : Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade100;

  Color get _errorColor => AppColors.errorMuted;

  @override
  Widget build(BuildContext context) {
    final showToggle =
        widget.obscureText && widget.showPasswordToggle;

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autocorrect: widget.autocorrect,
      autofillHints: widget.autofillHints,
      style: AppFontManager.bodyMedium(color: _labelColor),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        labelStyle: AppFontManager.bodyMedium(color: _labelColor),
        hintStyle: AppFontManager.bodyMedium(color: _hintColor),
        errorStyle: AppFontManager.bodyMedium(color: _errorColor),
        prefixIcon: widget.prefixIcon,
        suffixIcon: showToggle
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _labelColor,
                ),
                onPressed: () {
                  setState(() => _obscureText = !_obscureText);
                },
              )
            : null,
        filled: true,
        fillColor: _fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: _focusedBorderColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: _errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: _errorColor, width: 1.5),
        ),
      ),
    );
  }
}

enum AppTextFieldVariant { light, dark }
