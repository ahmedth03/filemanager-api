/// All named route constants for the application.
///
/// Use these constants instead of hard-coded strings everywhere
/// so that route renames are caught at compile time.
class RouteNames {
  RouteNames._();

  // ── Root / Shell ──────────────────────────────────────────────────────────
  static const String root = '/';
  static const String splash = 'splash';
  static const String mainNavigation = 'main';

  // ── Onboarding & Auth ─────────────────────────────────────────────────────
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String resetPassword = 'reset-password';
  static const String otpVerification = 'otp-verification';

  // ── Home ──────────────────────────────────────────────────────────────────
  static const String home = 'home';

  // ── Craftsmen ─────────────────────────────────────────────────────────────
  static const String craftsmenList = 'craftsmen-list';
  static const String craftsmanDetail = 'craftsman-detail';
  static const String craftsmanProfileSetup = 'craftsman-profile-setup';
  static const String portfolio = 'portfolio';

  // ── Listings / Real-Estate ────────────────────────────────────────────────
  static const String listingsList = 'listings-list';
  static const String listingDetail = 'listing-detail';
  static const String createListing = 'create-listing';
  static const String editListing = 'edit-listing';
  static const String myListings = 'my-listings';

  // ── Chat ─────────────────────────────────────────────────────────────────
  static const String chatList = 'chat-list';
  static const String chatRoom = 'chat-room';

  // ── Profile ──────────────────────────────────────────────────────────────
  static const String profile = 'profile';
  static const String editProfile = 'edit-profile';
  static const String settings = 'settings';

  // ── Misc ─────────────────────────────────────────────────────────────────
  static const String favorites = 'favorites';
  static const String notifications = 'notifications';
  static const String writeReview = 'write-review';
  static const String map = 'map';
  static const String webView = 'web-view';
  static const String report = 'report';

  // ── Paths (full path strings for use in GoRouter.go / context.push) ───────
  static const String pathSplash = '/splash';
  static const String pathOnboarding = '/onboarding';
  static const String pathLogin = '/login';
  static const String pathRegister = '/register';
  static const String pathForgotPassword = '/forgot-password';
  static const String pathResetPassword = '/reset-password';
  static const String pathOtpVerification = '/otp-verification';
  static const String pathMain = '/main';
  static const String pathHome = '/main/home';
  static const String pathCraftsmenList = '/main/craftsmen';
  static const String pathListingsList = '/main/listings';
  static const String pathChatList = '/main/chats';
  static const String pathProfile = '/main/profile';
  static const String pathFavorites = '/favorites';
  static const String pathNotifications = '/notifications';
  static const String pathSettings = '/settings';
  static const String pathWriteReview = '/write-review';
  static const String pathCraftsmanProfileSetup = '/craftsman-profile-setup';
  static const String pathMyListings = '/my-listings';
  static const String pathEditProfile = '/edit-profile';
  static const String pathReport = '/report';
}
