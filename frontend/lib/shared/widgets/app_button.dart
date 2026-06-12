import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand palette (inline so this file is self-contained)
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B4F72);
  static const Color accent = Color(0xFFF39C12);
  static const Color background = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);
  static const Color divider = Color(0xFFDEE2E6);
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------
enum AppButtonVariant { primary, secondary, outline, text }

enum AppButtonSize { small, medium, large }

// ---------------------------------------------------------------------------
// AppButton
// ---------------------------------------------------------------------------
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.fullWidth = true,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool fullWidth;
  final double? borderRadius;

  // ------------------------------------------------------------------
  // Dimensions per size
  // ------------------------------------------------------------------
  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  TextStyle get _textStyle {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.buttonSmall;
      case AppButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case AppButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  // ------------------------------------------------------------------
  // Colours per variant
  // ------------------------------------------------------------------
  Color _backgroundColor(bool isDark) {
    if (isDisabled || isLoading) {
      switch (variant) {
        case AppButtonVariant.primary:
        case AppButtonVariant.secondary:
          return AppColors.divider;
        case AppButtonVariant.outline:
        case AppButtonVariant.text:
          return Colors.transparent;
      }
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.accent;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _foregroundColor() {
    if (isDisabled || isLoading) {
      switch (variant) {
        case AppButtonVariant.primary:
        case AppButtonVariant.secondary:
          return AppColors.textLight;
        case AppButtonVariant.outline:
        case AppButtonVariant.text:
          return AppColors.divider;
      }
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.white;
      case AppButtonVariant.secondary:
        return AppColors.white;
      case AppButtonVariant.outline:
        return AppColors.primary;
      case AppButtonVariant.text:
        return AppColors.primary;
    }
  }

  BorderSide _borderSide() {
    if (variant == AppButtonVariant.outline) {
      return BorderSide(
        color: (isDisabled || isLoading) ? AppColors.divider : AppColors.primary,
        width: 1.5,
      );
    }
    return BorderSide.none;
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool effectivelyDisabled = isDisabled || isLoading;
    final VoidCallback? effectiveCallback =
        effectivelyDisabled ? null : onPressed;
    final double radius = borderRadius ?? 12;
    final Color bg = _backgroundColor(false);
    final Color fg = _foregroundColor();

    Widget buttonChild = _buildChild(fg);

    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg,
      disabledForegroundColor: fg,
      elevation: (variant == AppButtonVariant.primary) ? 2 : 0,
      shadowColor: AppColors.primary.withOpacity(0.3),
      padding: _padding,
      minimumSize: Size(fullWidth ? double.infinity : 0, _height),
      maximumSize: Size(fullWidth ? double.infinity : double.infinity, _height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: _borderSide(),
      ),
      textStyle: _textStyle,
    );

    if (variant == AppButtonVariant.text) {
      return TextButton(
        onPressed: effectiveCallback,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          disabledForegroundColor: fg,
          padding: _padding,
          minimumSize: Size(fullWidth ? double.infinity : 0, _height),
          textStyle: _textStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: buttonChild,
      );
    }

    if (variant == AppButtonVariant.outline) {
      return OutlinedButton(
        onPressed: effectiveCallback,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          disabledForegroundColor: fg,
          padding: _padding,
          minimumSize: Size(fullWidth ? double.infinity : 0, _height),
          side: _borderSide(),
          textStyle: _textStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: effectiveCallback,
      style: style,
      child: buttonChild,
    );
  }

  Widget _buildChild(Color fg) {
    if (isLoading) {
      return SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    }

    final List<Widget> rowChildren = [];

    if (prefixIcon != null) {
      rowChildren.add(Icon(prefixIcon, size: _iconSize, color: fg));
      rowChildren.add(const SizedBox(width: 8));
    }

    rowChildren.add(Text(label, style: _textStyle.copyWith(color: fg)));

    if (suffixIcon != null) {
      rowChildren.add(const SizedBox(width: 8));
      rowChildren.add(Icon(suffixIcon, size: _iconSize, color: fg));
    }

    if (rowChildren.length == 1) return rowChildren.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowChildren,
    );
  }
}
