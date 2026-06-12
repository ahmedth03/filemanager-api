import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand colours (inline)
// ---------------------------------------------------------------------------
class _C {
  static const Color primary = Color(0xFF1B4F72);
  static const Color accent = Color(0xFFF39C12);
  static const Color background = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
  static const Color divider = Color(0xFFDEE2E6);
}

// ---------------------------------------------------------------------------
// FilterChipWidget – single chip
// ---------------------------------------------------------------------------
class FilterChipWidget extends StatelessWidget {
  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.borderRadius = 20,
    this.padding,
    this.fontSize = 13,
    this.showCheckmark = false,
    this.enabled = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Icon displayed before the label.
  final IconData? prefixIcon;

  /// Icon displayed after the label.
  final IconData? suffixIcon;

  /// Background colour when selected. Defaults to [primary].
  final Color? selectedColor;

  /// Background colour when not selected. Defaults to white.
  final Color? unselectedColor;

  /// Text colour when selected. Defaults to white.
  final Color? selectedTextColor;

  /// Text colour when not selected. Defaults to [textLight].
  final Color? unselectedTextColor;

  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double fontSize;

  /// Whether to show a leading checkmark when selected.
  final bool showCheckmark;

  final bool enabled;

  Color get _bgColor =>
      isSelected ? (selectedColor ?? _C.primary) : (unselectedColor ?? _C.white);

  Color get _fgColor => isSelected
      ? (selectedTextColor ?? _C.white)
      : (unselectedTextColor ?? _C.textLight);

  Color get _borderColor => isSelected ? _bgColor : _C.divider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? _bgColor : _C.divider,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: enabled ? _borderColor : _C.divider,
            width: 1.5,
          ),
          boxShadow: isSelected && enabled
              ? [
                  BoxShadow(
                    color: _bgColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheckmark && isSelected) ...[
              Icon(
                Icons.check_rounded,
                size: fontSize + 2,
                color: enabled ? _fgColor : _C.textLight,
              ),
              const SizedBox(width: 4),
            ] else if (prefixIcon != null) ...[
              Icon(
                prefixIcon,
                size: fontSize + 2,
                color: enabled ? _fgColor : _C.textLight,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: enabled ? _fgColor : _C.textLight,
                fontFamily: 'Cairo',
              ),
            ),
            if (suffixIcon != null) ...[
              const SizedBox(width: 6),
              Icon(
                suffixIcon,
                size: fontSize + 2,
                color: enabled ? _fgColor : _C.textLight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FilterChipGroup – convenience wrapper for a list of chips
// ---------------------------------------------------------------------------
class FilterChipGroup<T> extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.selectedValues,
    required this.onSelectionChanged,
    this.multiSelect = false,
    this.spacing = 8,
    this.runSpacing = 8,
    this.iconBuilder,
    this.scrollable = false,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final Set<T> selectedValues;
  final void Function(T item, bool selected) onSelectionChanged;
  final bool multiSelect;
  final double spacing;
  final double runSpacing;
  final IconData? Function(T item)? iconBuilder;

  /// When true, chips are placed in a single horizontal scrollable row.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final chips = items.map((item) {
      final bool isSelected = selectedValues.contains(item);
      return FilterChipWidget(
        label: labelBuilder(item),
        isSelected: isSelected,
        prefixIcon: iconBuilder?.call(item),
        onTap: () => onSelectionChanged(item, !isSelected),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              chips[i],
              if (i < chips.length - 1) SizedBox(width: spacing),
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: chips,
    );
  }
}
