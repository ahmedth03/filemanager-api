import '../entities/craftsman.dart';
import '../repositories/craftsmen_repository.dart';

class GetCraftsmenUseCase {
  const GetCraftsmenUseCase(this._repository);

  final CraftsmenRepository _repository;

  Future<List<Craftsman>> call({
    String? wilaya,
    CraftsmanSpecialty? specialty,
    double? minRating,
    bool? isAvailable,
    int page = 1,
    int limit = 20,
  }) async {
    final filters = CraftsmenFilters(
      wilaya: wilaya,
      specialty: specialty,
      minRating: minRating,
      isAvailable: isAvailable,
      page: page,
      limit: limit,
    );
    return _repository.getCraftsmen(filters);
  }
}
