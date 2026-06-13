import 'app_config.dart';

/// Centralised API endpoint constants.
///
/// All paths are relative to [AppConfig.instance.apiBaseUrl].
/// Full URLs are built by the [ApiClient] using [AppConfig.instance.apiBaseUrl]
/// as the base.
class ApiConfig {
  ApiConfig._();

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyPhone = '/auth/verify-phone';
  static const String resendOtp = '/auth/resend-otp';

  // ── Users ──────────────────────────────────────────────────────────────────
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String uploadAvatar = '/users/avatar';
  static const String deleteAccount = '/users/account';
  static const String userById = '/users/{id}';

  // ── Craftsmen ──────────────────────────────────────────────────────────────
  static const String craftsmen = '/craftsmen';
  static const String craftsmanById = '/craftsmen/{id}';
  static const String craftsmanProfile = '/craftsmen/profile';
  static const String craftsmanPortfolio = '/craftsmen/{id}/portfolio';
  static const String craftsmanAvailability = '/craftsmen/{id}/availability';
  static const String craftsmanReviews = '/craftsmen/{id}/reviews';
  static const String craftsmanCategories = '/craftsmen/categories';
  static const String nearbyCraftsmen = '/craftsmen/nearby';
  static const String searchCraftsmen = '/craftsmen/search';
  static const String featuredCraftsmen = '/craftsmen/featured';

  // ── Listings (Real Estate) ──────────────────────────────────────────────────
  static const String listings = '/listings';
  static const String listingById = '/listings/{id}';
  static const String createListing = '/listings';
  static const String updateListing = '/listings/{id}';
  static const String deleteListing = '/listings/{id}';
  static const String myListings = '/listings/mine';
  static const String searchListings = '/listings/search';
  static const String featuredListings = '/listings/featured';
  static const String listingImages = '/listings/{id}/images';
  static const String nearbyListings = '/listings/nearby';

  // ── Reviews ────────────────────────────────────────────────────────────────
  static const String reviews = '/reviews';
  static const String reviewById = '/reviews/{id}';
  static const String createReview = '/reviews';
  static const String updateReview = '/reviews/{id}';
  static const String deleteReview = '/reviews/{id}';

  // ── Favorites ─────────────────────────────────────────────────────────────
  static const String favorites = '/favorites';
  static const String addFavorite = '/favorites';
  static const String removeFavorite = '/favorites/{id}';
  static const String favoriteCraftsmen = '/favorites/craftsmen';
  static const String favoriteListings = '/favorites/listings';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String conversations = '/chat/conversations';
  static const String conversationById = '/chat/conversations/{id}';
  static const String createConversation = '/chat/conversations';
  static const String messages = '/chat/conversations/{id}/messages';
  static const String sendMessage = '/chat/conversations/{id}/messages';
  static const String markMessagesRead = '/chat/conversations/{id}/read';

  // ── Notifications ──────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/{id}/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String notificationSettings = '/notifications/settings';
  static const String registerDeviceToken = '/notifications/device-token';

  // ── Search & Discovery ─────────────────────────────────────────────────────
  static const String globalSearch = '/search';
  static const String searchSuggestions = '/search/suggestions';

  // ── Locations ─────────────────────────────────────────────────────────────
  static const String wilayas = '/locations/wilayas';
  static const String communes = '/locations/communes';
  static const String communesByWilaya = '/locations/wilayas/{id}/communes';

  // ── Media Upload ──────────────────────────────────────────────────────────
  static const String uploadImage = '/media/upload';
  static const String uploadMultipleImages = '/media/upload/multiple';
  static const String deleteMedia = '/media/{id}';

  // ── Reports ───────────────────────────────────────────────────────────────
  static const String reportUser = '/reports/user';
  static const String reportListing = '/reports/listing';
  static const String reportReview = '/reports/review';

  // ── App Metadata ──────────────────────────────────────────────────────────
  static const String appVersion = '/app/version';
  static const String appConfig = '/app/config';
  static const String termsOfService = '/app/terms';
  static const String privacyPolicy = '/app/privacy';

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Replaces `{id}` placeholder in an endpoint template.
  /// Example: [ApiConfig.craftsmanById.withId('abc123')]
  static String withId(String endpoint, String id) =>
      endpoint.replaceFirst('{id}', id);

  /// Full URL helper (prepends [AppConfig.instance.apiBaseUrl]).
  static String fullUrl(String endpoint) =>
      '${AppConfig.instance.apiBaseUrl}$endpoint';
}

/// Extension for convenient path building.
extension ApiEndpointX on String {
  /// Replaces the first `{id}` placeholder with [id].
  String withId(String id) => replaceFirst('{id}', id);

  /// Returns the fully-qualified URL by prepending the current base URL.
  String get fullUrl => '${AppConfig.instance.apiBaseUrl}$this';
}
