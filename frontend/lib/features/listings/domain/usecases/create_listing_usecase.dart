import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../entities/listing.dart';

// ---------------------------------------------------------------------------
// CreateListingParams
// ---------------------------------------------------------------------------

class CreateListingParams {
  const CreateListingParams({
    required this.title,
    required this.description,
    required this.type,
    required this.transactionType,
    required this.price,
    required this.priceUnit,
    required this.wilaya,
    required this.city,
    required this.address,
    required this.contactPhone,
    required this.contactName,
    this.rooms,
    this.bathrooms,
    this.area,
    this.floor,
    this.totalFloors,
    this.amenities = const [],
    this.images = const [],
    this.latitude,
    this.longitude,
  });

  final String title;
  final String description;
  final ListingType type;
  final TransactionType transactionType;
  final double price;
  final PriceUnit priceUnit;
  final String wilaya;
  final String city;
  final String address;
  final String contactPhone;
  final String contactName;
  final int? rooms;
  final int? bathrooms;
  final double? area;
  final int? floor;
  final int? totalFloors;
  final List<String> amenities;

  /// List of local file paths to upload together with the listing.
  final List<String> images;

  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'transactionType': transactionType.name,
      'price': price,
      'priceUnit': priceUnit.name,
      'wilaya': wilaya,
      'city': city,
      'address': address,
      'contactPhone': contactPhone,
      'contactName': contactName,
      if (rooms != null) 'rooms': rooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (area != null) 'area': area,
      if (floor != null) 'floor': floor,
      if (totalFloors != null) 'totalFloors': totalFloors,
      if (amenities.isNotEmpty) 'amenities': amenities,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

// ---------------------------------------------------------------------------
// CreateListingUseCase
// ---------------------------------------------------------------------------

/// Creates a new property listing.
///
/// If [params.images] is non-empty the request is sent as `multipart/form-data`
/// so the files are uploaded alongside the JSON fields.
/// Otherwise a plain JSON POST is used.
class CreateListingUseCase {
  const CreateListingUseCase(this._ref);

  final Ref _ref;

  Future<Map<String, dynamic>> call(CreateListingParams params) async {
    final dio = _ref.read(dioProvider);

    late Response<dynamic> response;

    if (params.images.isNotEmpty) {
      // ── Multipart upload ──────────────────────────────────────────────
      final formFields = params.toJson();
      final formData = FormData();

      formFields.forEach((key, value) {
        if (value is List) {
          for (final item in value) {
            formData.fields.add(MapEntry(key, item.toString()));
          }
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      for (final path in params.images) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(path),
          ),
        );
      }

      response = await dio.post(
        '/v1/listings',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } else {
      // ── JSON POST ─────────────────────────────────────────────────────
      response = await dio.post(
        '/v1/listings',
        data: params.toJson(),
      );
    }

    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) return data;
    }

    return {};
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final createListingUseCaseProvider =
    Provider<CreateListingUseCase>((ref) {
  return CreateListingUseCase(ref);
});
