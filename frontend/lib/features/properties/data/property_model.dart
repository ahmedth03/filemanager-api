class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String type;
  final String city;
  final String? image;
  final String status;

  const PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.city,
    this.image,
    required this.status,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) => PropertyModel(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        type: json['type'] ?? '',
        city: json['city'] ?? '',
        image: json['image'],
        status: json['status'] ?? 'AVAILABLE',
      );
}
