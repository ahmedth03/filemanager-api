import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Inline brand references (kept local so the file is self-contained)
// ---------------------------------------------------------------------------
class _AppColors {
  static const Color primary = Color(0xFF1B4F72);
  static const Color accent = Color(0xFFF39C12);
  static const Color background = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
  static const Color error = Color(0xFFDC3545);
  static const Color divider = Color(0xFFDEE2E6);
  static const Color surface = Color(0xFFFFFFFF);
}

// ---------------------------------------------------------------------------
// AppTextField
// ---------------------------------------------------------------------------
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.isPassword = false,
    this.isPhoneNumber = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.initialValue,
    this.fillColor,
    this.borderRadius = 12.0,
    this.contentPadding,
    this.onTap,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool isPassword;
  final bool isPhoneNumber;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final String? initialValue;
  final Color? fillColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback? onTap;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  late TextEditingController _effectiveController;
  bool _disposeController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController(text: widget.initialValue);
      _disposeController = true;
    } else {
      _effectiveController = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (_disposeController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  TextInputType get _keyboardType {
    if (widget.keyboardType != null) return widget.keyboardType!;
    if (widget.isPassword) return TextInputType.visiblePassword;
    if (widget.isPhoneNumber) return TextInputType.phone;
    return TextInputType.text;
  }

  List<TextInputFormatter> get _inputFormatters {
    final formatters = <TextInputFormatter>[];
    if (widget.isPhoneNumber) {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')));
      formatters.add(_AlgerianPhoneFormatter());
    }
    if (widget.inputFormatters != null) {
      formatters.addAll(widget.inputFormatters!);
    }
    return formatters;
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final bool isDisabled = !widget.enabled;

    Widget? prefixWidget = widget.prefixIcon != null
        ? Icon(
            widget.prefixIcon,
            color: hasError ? _AppColors.error : _AppColors.textLight,
            size: 20,
          )
        : (widget.isPhoneNumber
            ? _buildPhonePrefix()
            : null);

    Widget? suffixWidget;
    if (widget.isPassword) {
      suffixWidget = GestureDetector(
        onTap: () => setState(() => _obscureText = !_obscureText),
        child: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _AppColors.textLight,
          size: 20,
        ),
      );
    } else if (widget.suffixIcon != null) {
      suffixWidget = GestureDetector(
        onTap: widget.onSuffixIconTap,
        child: Icon(
          widget.suffixIcon,
          color: _AppColors.textLight,
          size: 20,
        ),
      );
    }

    return TextFormField(
      controller: _effectiveController,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: _keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      validator: widget.validator,
      inputFormatters: _inputFormatters,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textDirection: widget.textDirection,
      textAlign: widget.textAlign,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      onTap: widget.onTap,
      style: TextStyle(
        fontSize: 15,
        color: isDisabled ? _AppColors.textLight : _AppColors.textDark,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        helperText: widget.helperText,
        helperMaxLines: 2,
        errorMaxLines: 2,
        prefixIcon: prefixWidget != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: prefixWidget,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: suffixWidget != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: suffixWidget,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        filled: true,
        fillColor: isDisabled
            ? _AppColors.divider
            : (widget.fillColor ?? _AppColors.surface),
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: hasError ? _AppColors.error : _AppColors.textLight,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: _AppColors.textLight,
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          color: _AppColors.error,
          fontSize: 12,
        ),
        helperStyle: const TextStyle(
          color: _AppColors.textLight,
          fontSize: 12,
        ),
        enabledBorder: _border(_AppColors.divider),
        focusedBorder: _border(_AppColors.primary),
        errorBorder: _border(_AppColors.error),
        focusedErrorBorder: _border(_AppColors.error),
        disabledBorder: _border(_AppColors.divider),
        border: _border(_AppColors.divider),
      ),
    );
  }

  Widget _buildPhonePrefix() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🇩🇿',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 4),
        Text(
          '+213',
          style: TextStyle(
            fontSize: 14,
            color: _AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          height: 20,
          width: 1,
          color: _AppColors.divider,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Algerian phone formatter
// Formats: 0X XX XX XX XX  (local) or strips +213 prefix
// ---------------------------------------------------------------------------
class _AlgerianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits, + and spaces
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format as XX XX XX XX (local without country code)
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 9; i++) {
      if (i != 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
