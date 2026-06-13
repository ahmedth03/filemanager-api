import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/api_client.dart';

class CraftsmenState {
  final List<dynamic> craftsmen;
  final int total;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  const CraftsmenState({
    this.craftsmen = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
  });

  CraftsmenState copyWith({
    List<dynamic>? craftsmen,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
  }) =>
      CraftsmenState(
        craftsmen: craftsmen ?? this.craftsmen,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        hasMore: hasMore ?? this.hasMore,
      );
}

class CraftsmenNotifier extends StateNotifier<CraftsmenState> {
  final Ref _ref;
  Map<String, dynamic> _currentFilters = {};

  CraftsmenNotifier(this._ref) : super(const CraftsmenState()) {
    loadCraftsmen();
  }

  Future<void> loadCraftsmen({Map<String, dynamic>? filters}) async {
    if (filters != null) _currentFilters = filters;
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/v1/craftsmen', queryParameters: {
        'page': 1,
        'limit': 20,
        ..._currentFilters,
      });
      final data = response.data['data'];
      final list = (data['craftsmen'] as List<dynamic>?) ?? [];
      final total = (data['total'] as int?) ?? 0;
      state = state.copyWith(
        craftsmen: list,
        total: total,
        page: 1,
        isLoading: false,
        hasMore: list.length < total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final dio = _ref.read(dioProvider);
      final nextPage = state.page + 1;
      final response = await dio.get('/v1/craftsmen', queryParameters: {
        'page': nextPage,
        'limit': 20,
        ..._currentFilters,
      });
      final data = response.data['data'];
      final newItems = (data['craftsmen'] as List<dynamic>?) ?? [];
      final combined = [...state.craftsmen, ...newItems];
      final total = (data['total'] as int?) ?? state.total;
      state = state.copyWith(
        craftsmen: combined,
        page: nextPage,
        isLoadingMore: false,
        hasMore: combined.length < total,
        total: total,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void applyFilters(Map<String, dynamic> filters) =>
      loadCraftsmen(filters: filters);

  void clearFilters() => loadCraftsmen(filters: {});
}

final craftsmenProvider =
    StateNotifierProvider<CraftsmenNotifier, CraftsmenState>((ref) {
  return CraftsmenNotifier(ref);
});

final craftsmanDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/v1/craftsmen/$id');
  return Map<String, dynamic>.from(response.data['data'] as Map);
});

final craftsmanReviewsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/v1/craftsmen/$id/reviews');
  return (response.data['data']['reviews'] as List<dynamic>?) ?? [];
});
