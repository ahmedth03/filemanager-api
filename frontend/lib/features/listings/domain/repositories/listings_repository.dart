import '../entities/listing.dart';

class ListingsFilters {
  const ListingsFilters({
    this.wilaya,
    this.type,
    this.transactionType,
    this.minPrice,
    this.maxPrice,
    this.minRooms,
    this.minArea,
    this.query,
    this.isFeatured,
    this.page = 1,
    this.limit = 20,
  });

  final String? wilaya;
  final ListingType? type;
  final TransactionType? transactionType;
  final double? minPrice;
  final double? maxPrice;
  final int? minRooms;
  final double? minArea;
  final String? query;
  final bool? isFeatured;
  final int page;
  final int limit;

  ListingsFilters copyWith({
    String? wilaya,
    ListingType? type,
    TransactionType? transactionType,
    double? minPrice,
    double? maxPrice,
    int? minRooms,
    double? minArea,
    String? query,
    bool? isFeatured,
    int? page,
    int? limit,
    bool clearWilaya = false,
    bool clearType = false,
    bool clearTransactionType = false,
    bool clearPrice = false,
    bool clearRooms = false,
    bool clearArea = false,
  }) {
    return ListingsFilters(
      wilaya: clearWilaya ? null : wilaya ?? this.wilaya,
      type: clearType ? null : type ?? this.type,
      transactionType: clearTransactionType
          ? null
          : transactionType ?? this.transactionType,
      minPrice: clearPrice ? null : minPrice ?? this.minPrice,
      maxPrice: clearPrice ? null : maxPrice ?? this.maxPrice,
      minRooms: clearRooms ? null : minRooms ?? this.minRooms,
      minArea: clearArea ? null : minArea ?? this.minArea,
      query: query ?? this.query,
      isFeatured: isFeatured ?? this.isFeatured,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (wilaya != null) 'wilaya': wilaya,
      if (type != null) 'type': type!.name,
      if (transactionType != null) 'transactionType': transactionType!.name,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minRooms != null) 'minRooms': minRooms,
      if (minArea != null) 'minArea': minArea,
      if (query != null && query!.isNotEmpty) 'q': query,
      if (isFeatured != null) 'isFeatured': isFeatured,
      'page': page,
      'limit': limit,
    };
  }
}

abstract class ListingsRepository {
  Future<List<Listing>> getListings(ListingsFilters filters);
  Future<List<Listing>> searchListings(String query, {ListingsFilters? filters});
  Future<Listing> getListingById(String id);
  Future<Listing> createListing(Map<String, dynamic> data);
  Future<Listing> updateListing(String id, Map<String, dynamic> data);
  Future<void> deleteListing(String id);
  Future<List<Listing>> getMyListings();
  Future<void> toggleFavorite(String listingId);
  Future<List<String>> getFavoriteIds();
}
