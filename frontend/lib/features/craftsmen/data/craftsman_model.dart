class CraftsmanUserModel {
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? phone;

  const CraftsmanUserModel({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.phone,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory CraftsmanUserModel.fromJson(Map<String, dynamic> json) =>
      CraftsmanUserModel(
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        avatarUrl: json['avatarUrl'],
        phone: json['phone'],
      );
}

class SpecialtyModel {
  final String id;
  final String nameAr;
  final String nameFr;
  final String? nameEn;
  final String? icon;

  const SpecialtyModel({
    required this.id,
    required this.nameAr,
    required this.nameFr,
    this.nameEn,
    this.icon,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) => SpecialtyModel(
        id: json['id']?.toString() ?? '',
        nameAr: json['nameAr'] ?? '',
        nameFr: json['nameFr'] ?? '',
        nameEn: json['nameEn'],
        icon: json['icon'],
      );
}

class PortfolioItemModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? description;

  const PortfolioItemModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
  });

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) =>
      PortfolioItemModel(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        description: json['description'],
      );
}

class CraftsmanModel {
  final String id;
  final String userId;
  final CraftsmanUserModel user;
  final SpecialtyModel? specialty;
  final String? bio;
  final int yearsExperience;
  final String wilaya;
  final String city;
  final String? businessName;
  final String? whatsappNumber;
  final bool isAvailable;
  final double avgRating;
  final int totalReviews;
  final String status;
  final List<PortfolioItemModel> portfolio;

  const CraftsmanModel({
    required this.id,
    required this.userId,
    required this.user,
    this.specialty,
    this.bio,
    required this.yearsExperience,
    required this.wilaya,
    required this.city,
    this.businessName,
    this.whatsappNumber,
    required this.isAvailable,
    required this.avgRating,
    required this.totalReviews,
    required this.status,
    required this.portfolio,
  });

  String get fullName => user.fullName;

  factory CraftsmanModel.fromJson(Map<String, dynamic> json) => CraftsmanModel(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        user: CraftsmanUserModel.fromJson(
            json['user'] as Map<String, dynamic>? ?? {}),
        specialty: json['specialty'] != null
            ? SpecialtyModel.fromJson(
                json['specialty'] as Map<String, dynamic>)
            : null,
        bio: json['bio'],
        yearsExperience: json['yearsExperience'] ?? 0,
        wilaya: json['wilaya'] ?? '',
        city: json['city'] ?? '',
        businessName: json['businessName'],
        whatsappNumber: json['whatsappNumber'],
        isAvailable: json['isAvailable'] ?? true,
        avgRating: (json['avgRating'] ?? 0).toDouble(),
        totalReviews: json['totalReviews'] ?? 0,
        status: json['status'] ?? 'VERIFIED',
        portfolio: (json['portfolio'] as List<dynamic>? ?? [])
            .map((e) => PortfolioItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
