import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ---------------------------------------------------------------------------
// Brand colours (inline)
// ---------------------------------------------------------------------------
class _C {
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFDEE2E6);
  static const Color textLight = Color(0xFF6C757D);
}

// ---------------------------------------------------------------------------
// NetworkImageWidget
// ---------------------------------------------------------------------------
class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderIcon,
    this.errorIcon,
    this.backgroundColor,
    this.showShimmer = true,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// The URL to load the image from. Can be null or empty.
  final String? imageUrl;

  final double? width;
  final double? height;

  /// How the image is inscribed into the bounding box.
  final BoxFit fit;

  /// Corner radius applied to both the image and placeholders.
  final double borderRadius;

  /// Icon shown while loading (used when [showShimmer] is false).
  final IconData? placeholderIcon;

  /// Icon shown when the image fails to load.
  final IconData? errorIcon;

  /// Background colour of the placeholder/error container.
  final Color? backgroundColor;

  /// Show shimmer effect while loading (default true).
  final bool showShimmer;

  /// Resize hint for the image cache.
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl?.isNotEmpty == true ? imageUrl : null;

    final Widget content = url != null
        ? CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: (_, __) => showShimmer
                ? _ShimmerPlaceholder(
                    width: width,
                    height: height,
                    borderRadius: borderRadius,
                  )
                : _PlaceholderBox(
                    width: width,
                    height: height,
                    icon: placeholderIcon ?? Icons.image_outlined,
                    backgroundColor: backgroundColor,
                    borderRadius: borderRadius,
                  ),
            errorWidget: (_, __, ___) => _PlaceholderBox(
              width: width,
              height: height,
              icon: errorIcon ?? Icons.broken_image_outlined,
              backgroundColor: backgroundColor,
              borderRadius: borderRadius,
            ),
          )
        : _PlaceholderBox(
            width: width,
            height: height,
            icon: placeholderIcon ?? Icons.image_outlined,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
          );

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}

// ---------------------------------------------------------------------------
// Circular avatar variant
// ---------------------------------------------------------------------------
class NetworkAvatarWidget extends StatelessWidget {
  const NetworkAvatarWidget({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholderIcon,
    this.backgroundColor,
  });

  final String? imageUrl;
  final double radius;
  final IconData? placeholderIcon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: NetworkImageWidget(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        borderRadius: 0, // ClipOval handles rounding
        placeholderIcon: placeholderIcon ?? Icons.person_outline_rounded,
        errorIcon: Icons.person_outline_rounded,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShimmerPlaceholder
// ---------------------------------------------------------------------------
class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({
    this.width,
    this.height,
    this.borderRadius = 0,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _C.shimmerBase,
      highlightColor: _C.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _C.shimmerBase,
          borderRadius: borderRadius > 0
              ? BorderRadius.circular(borderRadius)
              : BorderRadius.zero,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PlaceholderBox
// ---------------------------------------------------------------------------
class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({
    this.width,
    this.height,
    required this.icon,
    this.backgroundColor,
    this.borderRadius = 0,
  });

  final double? width;
  final double? height;
  final IconData icon;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? _C.divider,
        borderRadius: borderRadius > 0
            ? BorderRadius.circular(borderRadius)
            : BorderRadius.zero,
      ),
      child: Center(
        child: Icon(
          icon,
          size: (width != null && height != null)
              ? (width! < height! ? width! : height!) * 0.35
              : 32,
          color: _C.textLight,
        ),
      ),
    );
  }
}
