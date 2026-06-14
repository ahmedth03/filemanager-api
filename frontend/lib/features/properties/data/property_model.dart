class PropertyOwnerModel {
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  const PropertyOwnerModel({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory PropertyOwnerModel.fromJson(Map<String, dynamic> json) =>
      PropertyOwnerModel(
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        avatarUrl: json['avatarUrl'],
      );
}

class PropertyImageModel {
  final String id;
  final String url;
  final bool isCover;
  final int order;

  const PropertyImageModel({
    required this.id,
    required this.url,
    required this.isCover,
    required this.order,
  });

  factory PropertyImageModel.fromJson(Map<String, dynamic> json) =>
      PropertyImageModel(
        id: json['id']?.toString() ?? '',
        url: json['url'] ?? '',
        isCover: json['isCover'] ?? false,
        order: json['order'] ?? 0,
      );
}

class PropertyModel {
  final String id;
  final String ownerId;
  final PropertyOwnerModel? owner;
  final String title;
  final String description;
  final String type;
  final String status;
  final double price;
  final String pricePeriod;
  final String wilaya;
  final String city;
  final String? address;
  final int rooms;
  final int bathrooms;
  final double? area;
  final bool hasParking;
  final bool hasElevator;
  final bool hasBalcony;
  final bool isFurnished;
  final bool isAvailable;
  final int viewCount;
  final double avgRating;
  final List<PropertyImageModel> images;

  const PropertyModel({
    required this.id,
    required this.ownerId,
    this.owner,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.price,
    required this.pricePeriod,
    required this.wilaya,
    required this.city,
    this.address,
    required this.rooms,
    required this.bathrooms,
    this.area,
    required this.hasParking,
    required this.hasElevator,
    required this.hasBalcony,
    required this.isFurnished,
    required this.isAvailable,
    required this.viewCount,
    required this.avgRating,
    required this.images,
  });

  String? get coverImageUrl {
    if (images.isEmpty) return null;
    final cover =
        images.where((i) => i.isCover).toList();
    if (cover.isNotEmpty) return cover.first.url;
    final sorted = List<PropertyImageModel>.from(images)
      ..sort((a, b) => a.order.compareTo(b.order));
    return sorted.first.url;
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) => PropertyModel(
        id: json['id']?.toString() ?? '',
        ownerId: json['ownerId']?.toString() ?? '',
        owner: json['owner'] != null
            ? PropertyOwnerModel.fromJson(
                json['owner'] as Map<String, dynamic>)
            : null,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        type: json['type'] ?? 'APARTMENT',
        status: json['status'] ?? 'ACTIVE',
        price: (json['price'] ?? 0).toDouble(),
        pricePeriod: json['pricePeriod'] ?? 'monthly',
        wilaya: json['wilaya'] ?? '',
        city: json['city'] ?? '',
        address: json['address'],
        rooms: json['rooms'] ?? 0,
        bathrooms: json['bathrooms'] ?? 0,
        area: json['area'] != null ? (json['area'] as num).toDouble() : null,
        hasParking: json['hasParking'] ?? false,
        hasElevator: json['hasElevator'] ?? false,
        hasBalcony: json['hasBalcony'] ?? false,
        isFurnished: json['isFurnished'] ?? false,
        isAvailable: json['isAvailable'] ?? true,
        viewCount: json['viewCount'] ?? 0,
        avgRating: (json['avgRating'] ?? 0).toDouble(),
        images: (json['images'] as List<dynamic>? ?? [])
            .map((e) =>
                PropertyImageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
