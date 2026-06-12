import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/review.dart';

// ---------------------------------------------------------------------------
// Review state
// ---------------------------------------------------------------------------

class ReviewsState {
  const ReviewsState({
    this.reviews = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submitError,
  });

  final List<ReviewEntity> reviews;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? submitError;

  ReviewsState copyWith({
    List<ReviewEntity>? reviews,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return ReviewsState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      submitError:
          clearSubmitError ? null : submitError ?? this.submitError,
    );
  }
}

// ---------------------------------------------------------------------------
// ReviewsNotifier
// ---------------------------------------------------------------------------

class ReviewsNotifier extends StateNotifier<ReviewsState> {
  ReviewsNotifier(this._dio, this._ref) : super(const ReviewsState());

  final Dio _dio;
  final Ref _ref;

  // ── Load reviews ─────────────────────────────────────────────────────────

  Future<void> loadCraftsmanReviews(String craftsmanId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('/v1/reviews/craftsman/$craftsmanId');
      final List<dynamic> data =
          _extractList(response.data) ?? [];
      final reviews =
          data.map((j) => ReviewEntity.fromJson(j as Map<String, dynamic>)).toList();
      state = state.copyWith(reviews: reviews, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadListingReviews(String listingId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('/v1/reviews/listing/$listingId');
      final List<dynamic> data =
          _extractList(response.data) ?? [];
      final reviews =
          data.map((j) => ReviewEntity.fromJson(j as Map<String, dynamic>)).toList();
      state = state.copyWith(reviews: reviews, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Submit review ─────────────────────────────────────────────────────────

  Future<bool> submitReview({
    required int rating,
    String? comment,
    String? craftsmanId,
    String? listingId,
  }) async {
    assert(
      craftsmanId != null || listingId != null,
      'Must provide craftsmanId or listingId',
    );

    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
    try {
      final response = await _dio.post(
        '/v1/reviews',
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (craftsmanId != null) 'craftsmanId': craftsmanId,
          if (listingId != null) 'listingId': listingId,
        },
      );

      final data = response.data['data'] ?? response.data;
      final newReview =
          ReviewEntity.fromJson(data as Map<String, dynamic>);

      // Prepend the new review
      state = state.copyWith(
        reviews: [newReview, ...state.reviews],
        isSubmitting: false,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: _parseError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
      return false;
    }
  }

  // ── Delete review ─────────────────────────────────────────────────────────

  Future<bool> deleteReview(String reviewId) async {
    try {
      await _dio.delete('/v1/reviews/$reviewId');
      state = state.copyWith(
        reviews: state.reviews.where((r) => r.id != reviewId).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parseError(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() =>
      state = state.copyWith(clearError: true, clearSubmitError: true);

  bool isOwnReview(ReviewEntity review) {
    final user = _ref.read(currentUserProvider);
    return user?.id == review.reviewerId;
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] as String?) ??
          (data['error'] as String?) ??
          e.message ??
          'خطأ غير معروف';
    }
    return e.message ?? 'خطأ في الاتصال بالخادم';
  }

  List<dynamic>? _extractList(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map) {
      final data = responseData['data'];
      if (data is List) return data;
      if (data is Map) {
        final reviews = data['reviews'];
        if (reviews is List) return reviews;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final reviewsProvider =
    StateNotifierProvider.autoDispose<ReviewsNotifier, ReviewsState>((ref) {
  return ReviewsNotifier(ref.watch(dioProvider), ref);
});

/// Family provider: auto-loads craftsman reviews when created.
final craftsmanReviewsProvider = StateNotifierProvider.autoDispose
    .family<ReviewsNotifier, ReviewsState, String>((ref, craftsmanId) {
  final notifier = ReviewsNotifier(ref.watch(dioProvider), ref);
  notifier.loadCraftsmanReviews(craftsmanId);
  return notifier;
});

/// Family provider: auto-loads listing reviews when created.
final listingReviewsProvider = StateNotifierProvider.autoDispose
    .family<ReviewsNotifier, ReviewsState, String>((ref, listingId) {
  final notifier = ReviewsNotifier(ref.watch(dioProvider), ref);
  notifier.loadListingReviews(listingId);
  return notifier;
});

/// Average rating computed from loaded reviews.
final averageRatingProvider = Provider.autoDispose
    .family<double, List<ReviewEntity>>((ref, reviews) {
  if (reviews.isEmpty) return 0.0;
  final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
  return sum / reviews.length;
});
