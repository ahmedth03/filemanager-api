class ReviewModel {
  final String id;
  final ReviewerModel reviewer;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.reviewer,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id']?.toString() ?? '',
        reviewer: ReviewerModel.fromJson(json['reviewer'] ?? {}),
        rating: (json['rating'] ?? 0) as int,
        comment: json['comment'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}

class ReviewerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  const ReviewerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ReviewerModel.fromJson(Map<String, dynamic> json) => ReviewerModel(
        id: json['id']?.toString() ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        avatarUrl: json['avatarUrl'],
      );
}
