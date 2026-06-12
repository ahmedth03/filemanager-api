import '../entities/craftsman.dart';
import '../repositories/craftsmen_repository.dart';

class SearchCraftsmenUseCase {
  const SearchCraftsmenUseCase(this._repository);

  final CraftsmenRepository _repository;

  Future<List<Craftsman>> call(
    String query, {
    String? wilaya,
    CraftsmanSpecialty? specialty,
    int page = 1,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }
    final filters = CraftsmenFilters(
      wilaya: wilaya,
      specialty: specialty,
      query: query.trim(),
      page: page,
      limit: limit,
    );
    return _repository.searchCraftsmen(query.trim(), filters: filters);
  }
}
