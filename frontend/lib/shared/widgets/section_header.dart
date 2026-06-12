import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand colours (inline)
// ---------------------------------------------------------------------------
class _C {
  static const Color primary = Color(0xFF1B4F72);
  static const Color accent = Color(0xFFF39C12);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
  static const Color divider = Color(0xFFDEE2E6);
}

// ---------------------------------------------------------------------------
// SectionHeader
// ---------------------------------------------------------------------------
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.seeAllLabel,
    this.onSeeAll,
    this.padding,
    this.showDivider = false,
    this.leadingIcon,
    this.titleStyle,
    this.subtitleStyle,
  });

  /// Main section title.
  final String title;

  /// Optional subtitle displayed below the title.
  final String? subtitle;

  /// Label for the trailing action button. Defaults to 'See all'.
  final String? seeAllLabel;

  /// Callback for the trailing action. Hidden when null.
  final VoidCallback? onSeeAll;

  final EdgeInsetsGeometry? padding;

  /// Show a horizontal divider below the header.
  final bool showDivider;

  /// Optional leading icon next to the title.
  final IconData? leadingIcon;

  /// Override the title text style.
  final TextStyle? titleStyle;

  /// Override the subtitle text style.
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading icon
              if (leadingIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    leadingIcon,
                    size: 18,
                    color: _C.primary,
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Title + optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: titleStyle ??
                          const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark,
                            fontFamily: 'Cairo',
                          ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: subtitleStyle ??
                            const TextStyle(
                              fontSize: 13,
                              color: _C.textLight,
                              fontFamily: 'Cairo',
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // "See all" action
              if (onSeeAll != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          seeAllLabel ?? 'See all',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _C.accent,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _C.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Optional divider
          if (showDivider) ...[
            const SizedBox(height: 10),
            const Divider(
              height: 1,
              thickness: 1,
              color: _C.divider,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SectionDivider – minimal horizontal rule with optional label
// ---------------------------------------------------------------------------
class SectionDivider extends StatelessWidget {
  const SectionDivider({
    super.key,
    this.label,
    this.padding,
  });

  final String? label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Divider(
        height: 1,
        thickness: 1,
        color: _C.divider,
        indent: padding != null ? 0 : 16,
        endIndent: padding != null ? 0 : 16,
      );
    }

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(height: 1, thickness: 1, color: _C.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 12,
                color: _C.textLight,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const Expanded(child: Divider(height: 1, thickness: 1, color: _C.divider)),
        ],
      ),
    );
  }
}
