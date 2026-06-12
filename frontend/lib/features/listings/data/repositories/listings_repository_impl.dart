import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/repositories/listings_repository.dart';
import '../../domain/entities/listing.dart';
import '../datasources/listings_remote_datasource.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepositoryImpl(
    datasource: ref.watch(listingsRemoteDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class ListingsRepositoryImpl implements ListingsRepository {
  const ListingsRepositoryImpl({required this.datasource});

  final ListingsRemoteDatasource datasource;

  @override
  Future<List<Listing>> getListings(ListingsFilters filters) async {
    final data = await datasource.getListings(
        params: filters.toQueryParams());
    final list = (data['listings'] as List<dynamic>?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Listing.fromJson)
        .toList();
  }

  @override
  Future<List<Listing>> searchListings(
    String query, {
    ListingsFilters? filters,
  }) async {
    final data = await datasource.searchListings(
      query: query,
      params: filters?.toQueryParams(),
    );
    final list = (data['listings'] as List<dynamic>?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Listing.fromJson)
        .toList();
  }

  @override
  Future<Listing> getListingById(String id) async {
    final data = await datasource.getListingById(id);
    return Listing.fromJson(data);
  }

  @override
  Future<Listing> createListing(Map<String, dynamic> body) async {
    final data = await datasource.createListing(body);
    return Listing.fromJson(data);
  }

  @override
  Future<Listing> updateListing(String id, Map<String, dynamic> body) async {
    final data = await datasource.updateListing(id, body);
    return Listing.fromJson(data);
  }

  @override
  Future<void> deleteListing(String id) async {
    await datasource.deleteListing(id);
  }

  @override
  Future<List<Listing>> getMyListings() async {
    final list = await datasource.getMyListings();
    return list.map(Listing.fromJson).toList();
  }

  @override
  Future<void> toggleFavorite(String listingId) async {
    await datasource.toggleFavorite(listingId);
  }

  @override
  Future<List<String>> getFavoriteIds() async {
    return datasource.getFavoriteIds();
  }
}
