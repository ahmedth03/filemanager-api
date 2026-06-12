import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand colours (inline)
// ---------------------------------------------------------------------------
class _C {
  static const Color primary = Color(0xFF1B4F72);
  static const Color accent = Color(0xFFF39C12);
  static const Color background = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
  static const Color divider = Color(0xFFDEE2E6);
}

// ---------------------------------------------------------------------------
// EmptyStateWidget
// ---------------------------------------------------------------------------
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  /// Primary empty-state title.
  final String title;

  /// Optional descriptive subtitle.
  final String? subtitle;

  /// Icon to display when no [imagePath] is provided.
  final IconData? icon;

  /// Optional asset image path (e.g., 'assets/images/empty.png').
  final String? imagePath;

  /// Label for the optional action button.
  final String? actionLabel;

  /// Callback for the optional action button.
  final VoidCallback? onAction;

  /// Use compact sizing.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double imageSize = compact ? 80 : 140;
    final EdgeInsets padding = compact
        ? const EdgeInsets.all(16)
        : const EdgeInsets.symmetric(horizontal: 32, vertical: 40);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Illustration / icon
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildIconFallback(imageSize),
              )
            else
              _buildIconFallback(imageSize),

            SizedBox(height: compact ? 16 : 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 15 : 18,
                fontWeight: FontWeight.w700,
                color: _C.textDark,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: compact ? 6 : 10),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  color: _C.textLight,
                  height: 1.5,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action button
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: compact ? 16 : 28),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 24 : 36,
                    vertical: compact ? 10 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _C.divider.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.inbox_outlined,
        size: size * 0.5,
        color: _C.textLight,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience variants
// ---------------------------------------------------------------------------

class EmptySearchWidget extends StatelessWidget {
  const EmptySearchWidget({
    super.key,
    this.message = 'No results found.\nTry a different search term.',
    this.onClear,
  });

  final String message;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No Results',
      subtitle: message,
      actionLabel: onClear != null ? 'Clear Search' : null,
      onAction: onClear,
    );
  }
}

class EmptyListWidget extends StatelessWidget {
  const EmptyListWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: icon ?? Icons.list_alt_rounded,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
