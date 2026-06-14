import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/property_repository.dart';
import '../data/property_model.dart';
import '../../../core/models/paginated_result.dart';

final propertyRepositoryProvider =
    Provider<PropertyRepository>((ref) => PropertyRepository());

class PropertyFilter {
  final String? wilaya;
  final String? type;
  final String? search;
  final double? minPrice;
  final double? maxPrice;
  final int? rooms;
  final bool? isFurnished;
  final String? sortBy;
  final int page;

  const PropertyFilter({
    this.wilaya,
    this.type,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.rooms,
    this.isFurnished,
    this.sortBy,
    this.page = 1,
  });

  PropertyFilter copyWith({
    String? wilaya,
    String? type,
    String? search,
    double? minPrice,
    double? maxPrice,
    int? rooms,
    bool? isFurnished,
    String? sortBy,
    int? page,
    bool clearWilaya = false,
    bool clearType = false,
    bool clearSearch = false,
    bool clearRooms = false,
    bool clearIsFurnished = false,
  }) {
    return PropertyFilter(
      wilaya: clearWilaya ? null : (wilaya ?? this.wilaya),
      type: clearType ? null : (type ?? this.type),
      search: clearSearch ? null : (search ?? this.search),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      rooms: clearRooms ? null : (rooms ?? this.rooms),
      isFurnished: clearIsFurnished ? null : (isFurnished ?? this.isFurnished),
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
    );
  }
}

final propertyFilterProvider =
    StateProvider<PropertyFilter>((ref) => const PropertyFilter(page: 1));

final propertiesProvider =
    FutureProvider.autoDispose<PaginatedResult<PropertyModel>>((ref) async {
  final filter = ref.watch(propertyFilterProvider);
  return ref.read(propertyRepositoryProvider).getListings(
        page: filter.page,
        wilaya: filter.wilaya,
        type: filter.type,
        search: filter.search,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        rooms: filter.rooms,
        isFurnished: filter.isFurnished,
        sortBy: filter.sortBy,
      );
});

final propertyDetailProvider =
    FutureProvider.autoDispose.family<PropertyModel, String>((ref, id) async {
  return ref.read(propertyRepositoryProvider).getListing(id);
});

final myListingsProvider =
    FutureProvider.autoDispose<List<PropertyModel>>((ref) async {
  return ref.read(propertyRepositoryProvider).getMyListings();
});
