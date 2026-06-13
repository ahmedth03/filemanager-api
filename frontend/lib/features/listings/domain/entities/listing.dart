import 'package:freezed_annotation/freezed_annotation.dart';

import 'listing_image.dart';

part 'listing.freezed.dart';
part 'listing.g.dart';

enum ListingType {
  apartment,
  house,
  villa,
  studio,
  shop,
  land;

  String get labelAr {
    switch (this) {
      case ListingType.apartment:
        return 'شقة';
      case ListingType.house:
        return 'منزل';
      case ListingType.villa:
        return 'فيلا';
      case ListingType.studio:
        return 'استوديو';
      case ListingType.shop:
        return 'محل تجاري';
      case ListingType.land:
        return 'أرض';
    }
  }
}

enum TransactionType {
  rent,
  sale;

  String get labelAr {
    switch (this) {
      case TransactionType.rent:
        return 'للإيجار';
      case TransactionType.sale:
        return 'للبيع';
    }
  }
}

enum PriceUnit {
  perMonth,
  perYear,
  total;

  String get labelAr {
    switch (this) {
      case PriceUnit.perMonth:
        return 'شهرياً';
      case PriceUnit.perYear:
        return 'سنوياً';
      case PriceUnit.total:
        return 'إجمالي';
    }
  }
}

@freezed
class Listing with _$Listing {
  const factory Listing({
    required String id,
    required String userId,
    required String title,
    required String description,
    required ListingType type,
    required TransactionType transactionType,
    required double price,
    required PriceUnit priceUnit,
    required String wilaya,
    required String city,
    required String address,
    int? rooms,
    int? bathrooms,
    double? area,
    int? floor,
    int? totalFloors,
    required List<String> amenities,
    required List<ListingImage> images,
    double? latitude,
    double? longitude,
    required bool isActive,
    required bool isFeatured,
    required String contactPhone,
    required String contactName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) =>
      _$ListingFromJson(json);
}
