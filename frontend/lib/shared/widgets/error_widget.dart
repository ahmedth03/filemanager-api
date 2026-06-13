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
  static const Color error = Color(0xFFDC3545);
}

// ---------------------------------------------------------------------------
// AppErrorWidget
// Named AppErrorWidget to avoid collision with Flutter's built-in ErrorWidget.
// ---------------------------------------------------------------------------
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.retryLabel,
    this.icon,
    this.compact = false,
  });

  /// Human-readable error description.
  final String message;

  /// Optional short title above the message.
  final String? title;

  /// When provided a "Retry" button is displayed.
  final VoidCallback? onRetry;

  /// Label for the retry button. Defaults to 'Retry'.
  final String? retryLabel;

  /// Override the default error icon.
  final IconData? icon;

  /// Use compact layout (no padding, smaller sizes).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact ? 40 : 64;
    final double titleSize = compact ? 14 : 17;
    final double bodySize = compact ? 12 : 14;
    final EdgeInsets padding = compact
        ? const EdgeInsets.all(16)
        : const EdgeInsets.symmetric(horizontal: 32, vertical: 24);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: iconSize + 24,
              height: iconSize + 24,
              decoration: BoxDecoration(
                color: _C.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: iconSize,
                color: _C.error,
              ),
            ),

            SizedBox(height: compact ? 12 : 20),

            // Title
            if (title != null && title!.isNotEmpty) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: compact ? 4 : 8),
            ],

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: bodySize,
                color: _C.textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),

            // Retry button
            if (onRetry != null) ...[
              SizedBox(height: compact ? 12 : 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 20 : 28,
                    vertical: compact ? 10 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NetworkErrorWidget – convenience subtype for network errors
// ---------------------------------------------------------------------------
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'No internet connection.\nPlease check your network and try again.',
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      icon: Icons.wifi_off_rounded,
      title: 'Connection Error',
      message: message,
      onRetry: onRetry,
      retryLabel: 'Try Again',
    );
  }
}
