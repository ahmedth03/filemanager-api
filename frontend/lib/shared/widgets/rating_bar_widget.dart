import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// ---------------------------------------------------------------------------
// Brand colours (inline)
// ---------------------------------------------------------------------------
class _C {
  static const Color starFilled = Color(0xFFF39C12);
  static const Color starEmpty = Color(0xFFDEE2E6);
  static const Color textLight = Color(0xFF6C757D);
  static const Color textDark = Color(0xFF212529);
}

// ---------------------------------------------------------------------------
// RatingBarWidget
// ---------------------------------------------------------------------------
/// A widget that renders a star rating bar.
///
/// Set [interactive] to `true` to allow the user to tap stars.
/// Set [allowHalfRating] to `true` to support 0.5 increments.
/// Optionally pass [ratingCount] to display the review count alongside.
class RatingBarWidget extends StatefulWidget {
  const RatingBarWidget({
    super.key,
    required this.rating,
    this.ratingCount,
    this.itemSize = 20,
    this.interactive = false,
    this.allowHalfRating = true,
    this.onRatingUpdate,
    this.direction = Axis.horizontal,
    this.showLabel = false,
    this.labelPosition = RatingLabelPosition.right,
  });

  /// Current rating value (0..5).
  final double rating;

  /// Total number of ratings/reviews to display next to the stars.
  final int? ratingCount;

  /// Size of each star icon.
  final double itemSize;

  /// When true the user can tap to change the rating.
  final bool interactive;

  /// Whether to allow half-star values.
  final bool allowHalfRating;

  /// Called when the user selects a new rating (only in interactive mode).
  final ValueChanged<double>? onRatingUpdate;

  /// Orientation of the star row.
  final Axis direction;

  /// Whether to show a numeric label alongside the stars.
  final bool showLabel;

  /// Position of the numeric label relative to the stars.
  final RatingLabelPosition labelPosition;

  @override
  State<RatingBarWidget> createState() => _RatingBarWidgetState();
}

class _RatingBarWidgetState extends State<RatingBarWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating.clamp(0.0, 5.0);
  }

  @override
  void didUpdateWidget(covariant RatingBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating.clamp(0.0, 5.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingBar = RatingBar.builder(
      initialRating: _currentRating,
      minRating: 1,
      direction: widget.direction,
      allowHalfRating: widget.allowHalfRating,
      itemCount: 5,
      itemSize: widget.itemSize,
      ignoreGestures: !widget.interactive,
      itemPadding: const EdgeInsets.symmetric(horizontal: 1.5),
      itemBuilder: (_, __) => const Icon(
        Icons.star_rounded,
        color: _C.starFilled,
      ),
      unratedColor: _C.starEmpty,
      updateOnDrag: widget.interactive,
      onRatingUpdate: (rating) {
        if (widget.interactive) {
          setState(() => _currentRating = rating);
          widget.onRatingUpdate?.call(rating);
        }
      },
    );

    if (!widget.showLabel && widget.ratingCount == null) {
      return ratingBar;
    }

    final labelWidget = _buildLabel();

    if (widget.labelPosition == RatingLabelPosition.right) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ratingBar,
          const SizedBox(width: 6),
          if (labelWidget != null) labelWidget,
        ],
      );
    }

    if (widget.labelPosition == RatingLabelPosition.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (labelWidget != null) labelWidget,
          const SizedBox(width: 6),
          ratingBar,
        ],
      );
    }

    // bottom
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ratingBar,
        const SizedBox(height: 4),
        if (labelWidget != null) labelWidget,
      ],
    );
  }

  Widget? _buildLabel() {
    final parts = <String>[];
    if (widget.showLabel) parts.add(_currentRating.toStringAsFixed(1));
    if (widget.ratingCount != null) {
      parts.add('(${_formatCount(widget.ratingCount!)})');
    }
    if (parts.isEmpty) return null;

    return Text(
      parts.join(' '),
      style: TextStyle(
        fontSize: widget.itemSize * 0.7,
        color: _C.textLight,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

// ---------------------------------------------------------------------------
// Label position enum
// ---------------------------------------------------------------------------
enum RatingLabelPosition { left, right, bottom }

// ---------------------------------------------------------------------------
// ReadOnlyRating – lightweight non-interactive shortcut
// ---------------------------------------------------------------------------
class ReadOnlyRating extends StatelessWidget {
  const ReadOnlyRating({
    super.key,
    required this.rating,
    this.ratingCount,
    this.itemSize = 16,
  });

  final double rating;
  final int? ratingCount;
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    return RatingBarWidget(
      rating: rating,
      ratingCount: ratingCount,
      itemSize: itemSize,
      interactive: false,
      allowHalfRating: true,
      showLabel: true,
    );
  }
}

// ---------------------------------------------------------------------------
// InteractiveRating – star picker with callback
// ---------------------------------------------------------------------------
class InteractiveRating extends StatelessWidget {
  const InteractiveRating({
    super.key,
    required this.rating,
    required this.onRatingUpdate,
    this.itemSize = 32,
    this.allowHalfRating = true,
  });

  final double rating;
  final ValueChanged<double> onRatingUpdate;
  final double itemSize;
  final bool allowHalfRating;

  @override
  Widget build(BuildContext context) {
    return RatingBarWidget(
      rating: rating,
      itemSize: itemSize,
      interactive: true,
      allowHalfRating: allowHalfRating,
      onRatingUpdate: onRatingUpdate,
    );
  }
}
