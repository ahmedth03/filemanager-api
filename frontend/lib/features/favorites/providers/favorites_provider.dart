import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/favorites_repository.dart';

final favoritesRepositoryProvider =
    Provider<FavoritesRepository>((ref) => FavoritesRepository());

final isCraftsmanFavoritedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, craftsmanId) async {
  return ref.read(favoritesRepositoryProvider).isCraftsmanFavorited(craftsmanId);
});

final isListingFavoritedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, listingId) async {
  return ref.read(favoritesRepositoryProvider).isListingFavorited(listingId);
});

final favoritesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(favoritesRepositoryProvider).getFavorites();
});
