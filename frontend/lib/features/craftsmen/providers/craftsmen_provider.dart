import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/craftsman_repository.dart';
import '../data/craftsman_model.dart';
import '../../../core/models/paginated_result.dart';

final craftsmenRepositoryProvider =
    Provider<CraftsmanRepository>((ref) => CraftsmanRepository());

class CraftsmanFilter {
  final String? wilaya;
  final String? specialtyId;
  final String? search;
  final bool? isAvailable;
  final int page;

  const CraftsmanFilter({
    this.wilaya,
    this.specialtyId,
    this.search,
    this.isAvailable,
    this.page = 1,
  });

  CraftsmanFilter copyWith({
    String? wilaya,
    String? specialtyId,
    String? search,
    bool? isAvailable,
    int? page,
    bool clearWilaya = false,
    bool clearSpecialtyId = false,
    bool clearSearch = false,
    bool clearIsAvailable = false,
  }) {
    return CraftsmanFilter(
      wilaya: clearWilaya ? null : (wilaya ?? this.wilaya),
      specialtyId:
          clearSpecialtyId ? null : (specialtyId ?? this.specialtyId),
      search: clearSearch ? null : (search ?? this.search),
      isAvailable:
          clearIsAvailable ? null : (isAvailable ?? this.isAvailable),
      page: page ?? this.page,
    );
  }
}

final craftsmanFilterProvider =
    StateProvider<CraftsmanFilter>((ref) => const CraftsmanFilter(page: 1));

final craftsmenProvider =
    FutureProvider.autoDispose<PaginatedResult<CraftsmanModel>>((ref) async {
  final filter = ref.watch(craftsmanFilterProvider);
  return ref.read(craftsmenRepositoryProvider).getCraftsmen(
        page: filter.page,
        wilaya: filter.wilaya,
        specialtyId: filter.specialtyId,
        isAvailable: filter.isAvailable,
        search: filter.search,
      );
});

final specialtiesProvider =
    FutureProvider<List<SpecialtyModel>>((ref) async {
  return ref.read(craftsmenRepositoryProvider).getSpecialties();
});

final craftsmanDetailProvider =
    FutureProvider.autoDispose.family<CraftsmanModel, String>((ref, id) async {
  return ref.read(craftsmenRepositoryProvider).getCraftsman(id);
});
