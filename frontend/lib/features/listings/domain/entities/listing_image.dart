import 'package:freezed_annotation/freezed_annotation.dart';

part 'listing_image.freezed.dart';
part 'listing_image.g.dart';

@freezed
class ListingImage with _$ListingImage {
  const factory ListingImage({
    required String id,
    required String listingId,
    required String imageUrl,
    required bool isPrimary,
    required int order,
  }) = _ListingImage;

  factory ListingImage.fromJson(Map<String, dynamic> json) =>
      _$ListingImageFromJson(json);
}
