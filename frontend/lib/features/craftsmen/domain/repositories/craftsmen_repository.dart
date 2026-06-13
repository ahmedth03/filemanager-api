import '../entities/craftsman.dart';

class CraftsmenFilters {
  const CraftsmenFilters({
    this.wilaya,
    this.specialty,
    this.minRating,
    this.isAvailable,
    this.query,
    this.page = 1,
    this.limit = 20,
  });

  final String? wilaya;
  final CraftsmanSpecialty? specialty;
  final double? minRating;
  final bool? isAvailable;
  final String? query;
  final int page;
  final int limit;

  CraftsmenFilters copyWith({
    String? wilaya,
    CraftsmanSpecialty? specialty,
    double? minRating,
    bool? isAvailable,
    String? query,
    int? page,
    int? limit,
    bool clearWilaya = false,
    bool clearSpecialty = false,
    bool clearMinRating = false,
    bool clearAvailable = false,
  }) {
    return CraftsmenFilters(
      wilaya: clearWilaya ? null : wilaya ?? this.wilaya,
      specialty: clearSpecialty ? null : specialty ?? this.specialty,
      minRating: clearMinRating ? null : minRating ?? this.minRating,
      isAvailable: clearAvailable ? null : isAvailable ?? this.isAvailable,
      query: query ?? this.query,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (wilaya != null) 'wilaya': wilaya,
      if (specialty != null) 'specialty': specialty!.key,
      if (minRating != null) 'minRating': minRating,
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (query != null && query!.isNotEmpty) 'q': query,
      'page': page,
      'limit': limit,
    };
  }
}

abstract class CraftsmenRepository {
  Future<List<Craftsman>> getCraftsmen(CraftsmenFilters filters);
  Future<List<Craftsman>> searchCraftsmen(String query, {CraftsmenFilters? filters});
  Future<Craftsman> getCraftsmanById(String id);
  Future<Craftsman> createCraftsmanProfile(Map<String, dynamic> data);
  Future<Craftsman> updateCraftsmanProfile(String id, Map<String, dynamic> data);
  Future<void> deleteCraftsmanProfile(String id);
  Future<int> getCraftsmenCount(CraftsmenFilters filters);
}
