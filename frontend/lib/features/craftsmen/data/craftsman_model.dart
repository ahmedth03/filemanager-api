class CraftsmanModel {
  final String id;
  final String name;
  final String specialty;
  final String? avatar;
  final double rating;
  final String phone;
  final String city;
  final bool isAvailable;

  const CraftsmanModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.avatar,
    required this.rating,
    required this.phone,
    required this.city,
    required this.isAvailable,
  });

  factory CraftsmanModel.fromJson(Map<String, dynamic> json) => CraftsmanModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        specialty: json['specialty'] ?? '',
        avatar: json['avatar'],
        rating: (json['rating'] ?? 0).toDouble(),
        phone: json['phone'] ?? '',
        city: json['city'] ?? '',
        isAvailable: json['isAvailable'] ?? true,
      );
}
