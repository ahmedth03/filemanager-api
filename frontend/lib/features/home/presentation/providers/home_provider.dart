import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../craftsmen/domain/entities/craftsman.dart';
import '../../../listings/domain/entities/listing.dart';

// ---------------------------------------------------------------------------
// Dio instance (simple, local — production code should use the shared client)
// ---------------------------------------------------------------------------

final _dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: AppConfig.instance.apiBaseUrl));
});

// ---------------------------------------------------------------------------
// Selected wilaya filter
// ---------------------------------------------------------------------------

final selectedWilayaProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Featured craftsmen
// ---------------------------------------------------------------------------

class FeaturedCraftsmenNotifier extends AsyncNotifier<List<Craftsman>> {
  @override
  Future<List<Craftsman>> build() async {
    return _fetchFeaturedCraftsmen();
  }

  Future<List<Craftsman>> _fetchFeaturedCraftsmen() async {
    final dio = ref.read(_dioProvider);
    final wilaya = ref.watch(selectedWilayaProvider);

    final queryParams = <String, dynamic>{
      'limit': 10,
      if (wilaya != null) 'wilaya': wilaya,
    };

    try {
      final response = await dio.get(
        '/craftsmen/featured',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Craftsman.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      // Return mock data for development
      return _mockCraftsmen();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFeaturedCraftsmen);
  }
}

final featuredCraftsmenProvider =
    AsyncNotifierProvider<FeaturedCraftsmenNotifier, List<Craftsman>>(
  FeaturedCraftsmenNotifier.new,
);

// ---------------------------------------------------------------------------
// Featured listings
// ---------------------------------------------------------------------------

class FeaturedListingsNotifier extends AsyncNotifier<List<Listing>> {
  @override
  Future<List<Listing>> build() async {
    return _fetchFeaturedListings();
  }

  Future<List<Listing>> _fetchFeaturedListings() async {
    final dio = ref.read(_dioProvider);
    final wilaya = ref.watch(selectedWilayaProvider);

    final queryParams = <String, dynamic>{
      'limit': 10,
      if (wilaya != null) 'wilaya': wilaya,
    };

    try {
      final response = await dio.get(
        '/listings/featured',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Listing.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return _mockListings();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFeaturedListings);
  }
}

final featuredListingsProvider =
    AsyncNotifierProvider<FeaturedListingsNotifier, List<Listing>>(
  FeaturedListingsNotifier.new,
);

// ---------------------------------------------------------------------------
// Mock data helpers
// ---------------------------------------------------------------------------

List<Craftsman> _mockCraftsmen() {
  return List.generate(5, (i) {
    return Craftsman(
      id: 'craftsman_$i',
      userId: 'user_$i',
      name: ['أحمد بن علي', 'محمد كريم', 'يوسف بلقاسم', 'عمر حمادي', 'خالد زيدان'][i],
      phone: '0550${100000 + i}',
      avatar: null,
      specialty: CraftsmanSpecialty.values[i % CraftsmanSpecialty.values.length],
      bio: 'حرفي محترف مع خبرة ${i + 2} سنوات في المجال',
      wilaya: ['الجزائر', 'وهران', 'قسنطينة', 'عنابة', 'بجاية'][i],
      city: ['الجزائر العاصمة', 'وهران', 'قسنطينة', 'عنابة', 'بجاية'][i],
      rating: 4.0 + (i % 10) / 10,
      reviewCount: 10 + i * 5,
      isAvailable: i % 2 == 0,
      isVerified: i % 3 != 0,
      hourlyRate: 1000.0 + i * 200,
      experience: 2 + i,
      portfolio: [],
      createdAt: DateTime.now().subtract(Duration(days: i * 30)),
    );
  });
}

List<Listing> _mockListings() {
  return List.generate(5, (i) {
    return Listing(
      id: 'listing_$i',
      userId: 'user_$i',
      title: ['شقة فاخرة في الجزائر العاصمة', 'منزل واسع بوهران', 'فيلا بقسنطينة', 'استوديو بعنابة', 'محل تجاري ببجاية'][i],
      description: 'عقار رائع في موقع ممتاز مع كل التسهيلات',
      type: ListingType.values[i % ListingType.values.length],
      transactionType: i % 2 == 0 ? TransactionType.rent : TransactionType.sale,
      price: 50000.0 + i * 10000,
      priceUnit: i % 2 == 0 ? PriceUnit.perMonth : PriceUnit.total,
      wilaya: ['الجزائر', 'وهران', 'قسنطينة', 'عنابة', 'بجاية'][i],
      city: ['الجزائر العاصمة', 'وهران', 'قسنطينة', 'عنابة', 'بجاية'][i],
      address: 'شارع الاستقلال',
      rooms: 2 + i,
      bathrooms: 1 + (i ~/ 2),
      area: 60.0 + i * 15,
      amenities: ['موقف سيارة', 'مصعد', 'حراسة'],
      images: [],
      isActive: true,
      isFeatured: i < 2,
      contactPhone: '0550${200000 + i}',
      contactName: 'مالك العقار',
      createdAt: DateTime.now().subtract(Duration(days: i * 7)),
      updatedAt: DateTime.now().subtract(Duration(days: i)),
    );
  });
}
