import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/review.dart';
import '../providers/reviews_provider.dart';

// ---------------------------------------------------------------------------
// ReviewCard
// ---------------------------------------------------------------------------

class ReviewCard extends ConsumerWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onDeleted,
  });

  final ReviewEntity review;

  /// Called after a successful deletion so the parent can react.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reviewsProvider.notifier);
    final isOwn = notifier.isOwnReview(review);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.reviewerName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwn)
                          _DeleteButton(
                            reviewId: review.id,
                            onDeleted: onDeleted,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: review.rating.toDouble(),
                      itemBuilder: (_, __) => const Icon(
                        Icons.star_rounded,
                        color: AppColors.starFilled,
                      ),
                      unratedColor: AppColors.starEmpty,
                      itemCount: 5,
                      itemSize: 18,
                      direction: Axis.horizontal,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Comment ────────────────────────────────────────────────────
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ],

          // ── Date ───────────────────────────────────────────────────────
          const SizedBox(height: 8),
          Text(
            _formatDate(review.createdAt),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: review.reviewerAvatar != null
          ? NetworkImage(review.reviewerAvatar!)
          : null,
      child: review.reviewerAvatar == null
          ? Text(
              _initial(review.reviewerName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          : null,
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  String _formatDate(DateTime dt) {
    return DateFormat('d MMMM y', 'ar').format(dt);
  }
}

// ---------------------------------------------------------------------------
// Delete button with confirmation dialog
// ---------------------------------------------------------------------------

class _DeleteButton extends ConsumerStatefulWidget {
  const _DeleteButton({required this.reviewId, this.onDeleted});

  final String reviewId;
  final VoidCallback? onDeleted;

  @override
  ConsumerState<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends ConsumerState<_DeleteButton> {
  bool _deleting = false;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'حذف التقييم',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'هل أنت متأكد أنك تريد حذف هذا التقييم؟',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final success = await ref
        .read(reviewsProvider.notifier)
        .deleteReview(widget.reviewId);

    if (mounted) setState(() => _deleting = false);

    if (success && mounted) {
      widget.onDeleted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حذف التقييم',
            style: TextStyle(fontFamily: 'Cairo'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deleting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.error,
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
      tooltip: 'حذف التقييم',
      onPressed: () => _confirmDelete(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
