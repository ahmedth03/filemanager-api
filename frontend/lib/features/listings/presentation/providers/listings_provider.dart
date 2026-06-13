import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class ListingsState {
  final List<dynamic> listings;
  final int total;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  const ListingsState({
    this.listings = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
  });

  ListingsState copyWith({
    List<dynamic>? listings,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
  }) =>
      ListingsState(
        listings: listings ?? this.listings,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        hasMore: hasMore ?? this.hasMore,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class ListingsNotifier extends StateNotifier<ListingsState> {
  final Ref _ref;
  Map<String, dynamic> _currentFilters = {};

  ListingsNotifier(this._ref) : super(const ListingsState()) {
    loadListings();
  }

  Future<void> loadListings({Map<String, dynamic>? filters}) async {
    if (filters != null) _currentFilters = filters;
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/v1/listings', queryParameters: {
        'page': 1,
        'limit': 20,
        ..._currentFilters,
      });
      final data = response.data['data'];
      final list = (data['listings'] as List<dynamic>?) ?? [];
      final total = (data['total'] as int?) ?? 0;
      state = state.copyWith(
        listings: list,
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
      final response = await dio.get('/v1/listings', queryParameters: {
        'page': nextPage,
        'limit': 20,
        ..._currentFilters,
      });
      final data = response.data['data'];
      final newItems = (data['listings'] as List<dynamic>?) ?? [];
      final combined = [...state.listings, ...newItems];
      final total = (data['total'] as int?) ?? state.total;
      state = state.copyWith(
        listings: combined,
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
      loadListings(filters: filters);

  void clearFilters() => loadListings(filters: {});
}

// ---------------------------------------------------------------------------
// My Listings state
// ---------------------------------------------------------------------------
class MyListingsState {
  final List<dynamic> listings;
  final bool isLoading;
  final String? error;

  const MyListingsState({
    this.listings = const [],
    this.isLoading = false,
    this.error,
  });

  MyListingsState copyWith({
    List<dynamic>? listings,
    bool? isLoading,
    String? error,
  }) =>
      MyListingsState(
        listings: listings ?? this.listings,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class MyListingsNotifier extends StateNotifier<MyListingsState> {
  final Ref _ref;

  MyListingsNotifier(this._ref) : super(const MyListingsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/v1/listings/my');
      final list =
          (response.data['data']['listings'] as List<dynamic>?) ?? [];
      state = state.copyWith(listings: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> delete(String id) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete('/v1/listings/$id');
      state = state.copyWith(
        listings: state.listings
            .where((l) {
              final lId =
                  ((l as Map<String, dynamic>)['_id'] ?? l['id'] ?? '')
                      .toString();
              return lId != id;
            })
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateListing(String listingId, Map<String, dynamic> data) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.put('/v1/listings/$listingId', data: data);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final listingsProvider =
    StateNotifierProvider<ListingsNotifier, ListingsState>((ref) {
  return ListingsNotifier(ref);
});

final myListingsProvider =
    StateNotifierProvider<MyListingsNotifier, MyListingsState>((ref) {
  return MyListingsNotifier(ref);
});

final listingDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/v1/listings/$id');
  return Map<String, dynamic>.from(response.data['data'] as Map);
});

final listingFavoritesProvider =
    FutureProvider<List<String>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/v1/listings/favorites');
    return ((response.data['data']['ids'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .toList();
  } catch (_) {
    return [];
  }
});
