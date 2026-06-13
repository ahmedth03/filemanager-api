import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../craftsmen/domain/entities/craftsman.dart';
import '../../../listings/domain/entities/listing.dart';

// ---------------------------------------------------------------------------
// Dio for profile feature
// ---------------------------------------------------------------------------

final _profileDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: AppConfig.instance.apiBaseUrl));
});

// ---------------------------------------------------------------------------
// Profile state
// ---------------------------------------------------------------------------

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
    this.listingsCount = 0,
    this.reviewsGiven = 0,
    this.favoriteCraftsmen = const [],
    this.favoriteListings = const [],
    this.myListings = const [],
    this.craftsmanProfile,
  });

  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final int listingsCount;
  final int reviewsGiven;
  final List<Craftsman> favoriteCraftsmen;
  final List<Listing> favoriteListings;
  final List<Listing> myListings;
  final Craftsman? craftsmanProfile;

  ProfileState copyWith({
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
    int? listingsCount,
    int? reviewsGiven,
    List<Craftsman>? favoriteCraftsmen,
    List<Listing>? favoriteListings,
    List<Listing>? myListings,
    Craftsman? craftsmanProfile,
    bool clearError = false,
    bool clearCraftsmanProfile = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      listingsCount: listingsCount ?? this.listingsCount,
      reviewsGiven: reviewsGiven ?? this.reviewsGiven,
      favoriteCraftsmen:
          favoriteCraftsmen ?? this.favoriteCraftsmen,
      favoriteListings: favoriteListings ?? this.favoriteListings,
      myListings: myListings ?? this.myListings,
      craftsmanProfile: clearCraftsmanProfile
          ? null
          : (craftsmanProfile ?? this.craftsmanProfile),
    );
  }
}

// ---------------------------------------------------------------------------
// ProfileNotifier
// ---------------------------------------------------------------------------

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._dio) : super(const ProfileState()) {
    _init();
  }

  final Dio _dio;

  Future<void> _init() async {
    await Future.wait([
      loadStats(),
      loadFavorites(),
    ]);
  }

  // ------------------------------------------------------------------
  // Load stats (listings count, reviews given)
  // ------------------------------------------------------------------
  Future<void> loadStats() async {
    try {
      final response = await _dio.get('/users/me/stats');
      final data = response.data as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        listingsCount: (data['listingsCount'] as int?) ?? 0,
        reviewsGiven: (data['reviewsGiven'] as int?) ?? 0,
      );
    } catch (_) {
      // Use defaults silently
    }
  }

  // ------------------------------------------------------------------
  // Load favorites
  // ------------------------------------------------------------------
  Future<void> loadFavorites() async {
    try {
      state = state.copyWith(isLoading: true);
      final results = await Future.wait([
        _dio.get('/users/me/favorites/craftsmen'),
        _dio.get('/users/me/favorites/listings'),
      ]);

      final craftsmenData =
          (results[0].data['data'] as List? ?? [])
              .map((json) =>
                  Craftsman.fromJson(json as Map<String, dynamic>))
              .toList();

      final listingsData =
          (results[1].data['data'] as List? ?? [])
              .map((json) =>
                  Listing.fromJson(json as Map<String, dynamic>))
              .toList();

      state = state.copyWith(
        isLoading: false,
        favoriteCraftsmen: craftsmenData,
        favoriteListings: listingsData,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ------------------------------------------------------------------
  // Remove favorite craftsman
  // ------------------------------------------------------------------
  Future<void> removeFavoriteCraftsman(String craftsmanId) async {
    try {
      await _dio.delete('/users/me/favorites/craftsmen/$craftsmanId');
      state = state.copyWith(
        favoriteCraftsmen: state.favoriteCraftsmen
            .where((c) => c.id != craftsmanId)
            .toList(),
      );
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Remove favorite listing
  // ------------------------------------------------------------------
  Future<void> removeFavoriteListing(String listingId) async {
    try {
      await _dio.delete('/users/me/favorites/listings/$listingId');
      state = state.copyWith(
        favoriteListings: state.favoriteListings
            .where((l) => l.id != listingId)
            .toList(),
      );
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Load craftsman profile (for craftsman users)
  // ------------------------------------------------------------------
  Future<void> loadCraftsmanProfile() async {
    try {
      final response = await _dio.get('/craftsmen/me');
      final craftsman =
          Craftsman.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(craftsmanProfile: craftsman);
    } catch (_) {
      // Not a craftsman or profile not created yet
    }
  }

  // ------------------------------------------------------------------
  // Load my listings (for owner users)
  // ------------------------------------------------------------------
  Future<void> loadMyListings() async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await _dio.get('/listings/mine');
      final listings = (response.data['data'] as List? ?? [])
          .map((json) =>
              Listing.fromJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        isLoading: false,
        myListings: listings,
        listingsCount: listings.length,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ------------------------------------------------------------------
  // Update profile
  // ------------------------------------------------------------------
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? email,
    String? avatarPath,
  }) async {
    state = state.copyWith(isUpdating: true);
    try {
      final body = <String, dynamic>{
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      await _dio.patch('/users/me', data: body);
      state = state.copyWith(isUpdating: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: 'حدث خطأ أثناء تحديث الملف الشخصي',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(_profileDioProvider));
});
