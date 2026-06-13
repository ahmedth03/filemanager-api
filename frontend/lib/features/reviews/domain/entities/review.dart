/// Domain entity for a review left on a craftsman or a listing.
class ReviewEntity {
  const ReviewEntity({
    required this.id,
    required this.reviewerId,
    required this.reviewer,
    required this.rating,
    this.comment,
    this.craftsmanId,
    this.listingId,
    required this.createdAt,
  }) : assert(
          craftsmanId != null || listingId != null,
          'A review must reference either a craftsman or a listing',
        );

  final String id;
  final String reviewerId;

  /// Embedded reviewer info: { "id", "name", "avatar" }
  final Map<String, dynamic> reviewer;

  /// Star rating 1–5
  final int rating;

  final String? comment;
  final String? craftsmanId;
  final String? listingId;
  final DateTime createdAt;

  // ── Helpers ─────────────────────────────────────────────────────────────

  String get reviewerName =>
      (reviewer['name'] as String?) ?? 'مستخدم مجهول';

  String? get reviewerAvatar => reviewer['avatar'] as String?;

  bool get hasCraftsmanTarget => craftsmanId != null;
  bool get hasListingTarget => listingId != null;

  // ── Serialisation ────────────────────────────────────────────────────────

  factory ReviewEntity.fromJson(Map<String, dynamic> json) {
    return ReviewEntity(
      id: json['id'] as String,
      reviewerId: json['reviewerId'] as String,
      reviewer: Map<String, dynamic>.from(
          json['reviewer'] as Map? ?? <String, dynamic>{}),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      craftsmanId: json['craftsmanId'] as String?,
      listingId: json['listingId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewer': reviewer,
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (craftsmanId != null) 'craftsmanId': craftsmanId,
      if (listingId != null) 'listingId': listingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReviewEntity copyWith({
    String? id,
    String? reviewerId,
    Map<String, dynamic>? reviewer,
    int? rating,
    String? comment,
    String? craftsmanId,
    String? listingId,
    DateTime? createdAt,
  }) {
    return ReviewEntity(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewer: reviewer ?? this.reviewer,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      craftsmanId: craftsmanId ?? this.craftsmanId,
      listingId: listingId ?? this.listingId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ReviewEntity(id: $id, rating: $rating, reviewerId: $reviewerId)';
}
