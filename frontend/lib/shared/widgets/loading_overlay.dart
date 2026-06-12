import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand colours (inline)
// ---------------------------------------------------------------------------
class _C {
  static const Color primary = Color(0xFF1B4F72);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF6C757D);
}

// ---------------------------------------------------------------------------
// LoadingOverlay
// Wraps any child and conditionally overlays a loading indicator.
// ---------------------------------------------------------------------------
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.child,
    this.isLoading = false,
    this.message,
    this.overlayColor,
    this.barrierDismissible = false,
  });

  final Widget child;
  final bool isLoading;
  final String? message;

  /// Defaults to black at 50 % opacity.
  final Color? overlayColor;

  /// When true the overlay can be dismissed by tapping it.
  final bool barrierDismissible;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) _buildOverlay(context),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final overlay = GestureDetector(
      behavior: barrierDismissible
          ? HitTestBehavior.translucent
          : HitTestBehavior.opaque,
      onTap: barrierDismissible ? () {} : null,
      child: Container(
        color: overlayColor ?? Colors.black54,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: _LoadingCard(message: message),
        ),
      ),
    );

    return overlay;
  }
}

// ---------------------------------------------------------------------------
// _LoadingCard – the floating card with spinner + optional text
// ---------------------------------------------------------------------------
class _LoadingCard extends StatelessWidget {
  const _LoadingCard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_C.primary),
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: _C.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FullScreenLoader – can be pushed as a route or used directly in a Stack
// ---------------------------------------------------------------------------
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({
    super.key,
    this.message,
    this.backgroundColor,
  });

  final String? message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.black54,
      body: Center(
        child: _LoadingCard(message: message),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// InlineLoader – a simple centred spinner for use inside pages
// ---------------------------------------------------------------------------
class InlineLoader extends StatelessWidget {
  const InlineLoader({
    super.key,
    this.size = 36,
    this.color,
    this.strokeWidth = 3,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? _C.primary,
          ),
        ),
      ),
    );
  }
}
