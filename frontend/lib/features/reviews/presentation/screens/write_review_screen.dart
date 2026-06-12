import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/reviews_provider.dart';

// ---------------------------------------------------------------------------
// WriteReviewScreen
// ---------------------------------------------------------------------------

/// Can be used for both craftsman and listing reviews.
/// Supply exactly one of [craftsmanId] or [listingId].
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({
    super.key,
    this.craftsmanId,
    this.listingId,
    required this.targetName,
    this.targetSubtitle,
    this.targetImageUrl,
  }) : assert(
          craftsmanId != null || listingId != null,
          'Must supply either craftsmanId or listingId',
        );

  final String? craftsmanId;
  final String? listingId;

  /// Display name of the craftsman / listing shown at the top.
  final String targetName;

  /// Optional subtitle, e.g. profession or listing type.
  final String? targetSubtitle;

  /// Optional image to show alongside the name.
  final String? targetImageUrl;

  @override
  ConsumerState<WriteReviewScreen> createState() =>
      _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _selectedRating = 0;
  String? _ratingError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_selectedRating == 0) {
      setState(() => _ratingError = 'يرجى اختيار تقييم بالنجوم');
      return false;
    }
    setState(() => _ratingError = null);
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final success = await ref.read(reviewsProvider.notifier).submitReview(
          rating: _selectedRating,
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          craftsmanId: widget.craftsmanId,
          listingId: widget.listingId,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال تقييمك بنجاح!',
            style: TextStyle(fontFamily: 'Cairo'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true); // true = review was submitted
    } else {
      final error = ref.read(reviewsProvider).submitError;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error,
              style: const TextStyle(fontFamily: 'Cairo'),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewsProvider);
    final isSubmitting = reviewState.isSubmitting;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'كتابة تقييم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Target info card ────────────────────────────────────────
              _buildTargetCard(),

              const SizedBox(height: 24),

              // ── Star rating section ─────────────────────────────────────
              _buildRatingSection(),

              if (_ratingError != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _ratingError!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Comment field ───────────────────────────────────────────
              _buildCommentField(),

              const SizedBox(height: 32),

              // ── Submit button ───────────────────────────────────────────
              AppButton(
                label: 'إرسال التقييم',
                onPressed: isSubmitting ? null : _submit,
                isLoading: isSubmitting,
                size: AppButtonSize.large,
              ),

              const SizedBox(height: 16),

              const Text(
                'تقييماتك تساعد الآخرين في اتخاذ قراراتهم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCard() {
    return Container(
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
      child: Row(
        children: [
          // Image / initials avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: widget.targetImageUrl != null
                ? NetworkImage(widget.targetImageUrl!)
                : null,
            child: widget.targetImageUrl == null
                ? Text(
                    _initial(widget.targetName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.targetSubtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.targetSubtitle!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.craftsmanId != null ? 'حرفي' : 'عقار',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    const labels = ['', 'سيء جداً', 'سيء', 'مقبول', 'جيد', 'ممتاز'];

    return Column(
      children: [
        const Text(
          'كيف تقيّم تجربتك؟',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: RatingBar.builder(
            initialRating: _selectedRating.toDouble(),
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 44,
            glow: false,
            unratedColor: AppColors.starEmpty,
            itemBuilder: (context, _) => const Icon(
              Icons.star_rounded,
              color: AppColors.starFilled,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _selectedRating = rating.toInt();
                _ratingError = null;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selectedRating > 0
              ? Text(
                  labels[_selectedRating],
                  key: ValueKey(_selectedRating),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                )
              : const Text(
                  'اضغط على نجمة لتقييم',
                  key: ValueKey(0),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تعليق (اختياري)',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _commentController,
            textDirection: TextDirection.rtl,
            maxLines: 5,
            minLines: 3,
            maxLength: 500,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
            decoration: const InputDecoration(
              hintText:
                  'شارك تجربتك بالتفصيل لمساعدة الآخرين...',
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textHint,
              ),
              contentPadding: EdgeInsets.all(14),
              border: InputBorder.none,
              counterStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}
