import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../storage/secure_storage.dart';
import 'route_names.dart';

// ── Auth screens ─────────────────────────────────────────────────────────────
import 'package:harfidar/features/auth/presentation/screens/splash_screen.dart';
import 'package:harfidar/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:harfidar/features/auth/presentation/screens/login_screen.dart';
import 'package:harfidar/features/auth/presentation/screens/register_screen.dart';
import 'package:harfidar/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:harfidar/features/auth/presentation/screens/reset_password_screen.dart';

// ── Home ─────────────────────────────────────────────────────────────────────
import 'package:harfidar/features/home/presentation/screens/home_screen.dart';

// ── Craftsmen ────────────────────────────────────────────────────────────────
import 'package:harfidar/features/craftsmen/presentation/screens/craftsmen_list_screen.dart';
import 'package:harfidar/features/craftsmen/presentation/screens/craftsman_detail_screen.dart';
import 'package:harfidar/features/craftsmen/presentation/screens/craftsman_profile_setup_screen.dart';

// ── Listings ─────────────────────────────────────────────────────────────────
import 'package:harfidar/features/listings/presentation/screens/listings_list_screen.dart';
import 'package:harfidar/features/listings/presentation/screens/listing_detail_screen.dart';
import 'package:harfidar/features/listings/presentation/screens/create_listing_screen.dart';
import 'package:harfidar/features/listings/presentation/screens/my_listings_screen.dart';

// ── Chat ─────────────────────────────────────────────────────────────────────
import 'package:harfidar/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:harfidar/features/chat/presentation/screens/chat_room_screen.dart';

// ── Profile ──────────────────────────────────────────────────────────────────
import 'package:harfidar/features/profile/presentation/screens/profile_screen.dart';
import 'package:harfidar/features/profile/presentation/screens/settings_screen.dart';
import 'package:harfidar/features/profile/presentation/screens/my_favorites_screen.dart';
import 'package:harfidar/features/profile/presentation/screens/edit_profile_screen.dart';

// ── Notifications ─────────────────────────────────────────────────────────────
import 'package:harfidar/features/notifications/presentation/screens/notifications_screen.dart';

// ── Reviews ──────────────────────────────────────────────────────────────────
import 'package:harfidar/features/reviews/presentation/screens/write_review_screen.dart';

// ── Navigation shell ─────────────────────────────────────────────────────────
import 'package:harfidar/features/navigation/presentation/screens/main_navigation_screen.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Exposes the configured [GoRouter] as a Riverpod provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return _buildRouter(secureStorage);
});

// ---------------------------------------------------------------------------
// Router builder
// ---------------------------------------------------------------------------

GoRouter _buildRouter(SecureStorage secureStorage) {
  return GoRouter(
    initialLocation: RouteNames.pathSplash,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) async {
      final token = await secureStorage.getAccessToken();
      final isLoggedIn = token != null && token.isNotEmpty;

      final isAuthRoute = _authRoutes.contains(state.matchedLocation) ||
          state.matchedLocation.startsWith(RouteNames.pathOnboarding);

      final isSplash =
          state.matchedLocation == RouteNames.pathSplash;

      // Always allow splash through — it handles its own redirect
      if (isSplash) return null;

      // Not logged in and trying to access a protected route
      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.pathLogin;
      }

      // Already logged in and trying to access auth routes
      if (isLoggedIn && isAuthRoute) {
        return RouteNames.pathHome;
      }

      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.pathSplash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ───────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.pathOnboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.pathLogin,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'forgot-password',
            name: RouteNames.forgotPassword,
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'reset-password',
            name: RouteNames.resetPassword,
            builder: (context, state) {
              final token = state.uri.queryParameters['token'] ?? '';
              return ResetPasswordScreen(token: token);
            },
          ),
          GoRoute(
            path: 'otp',
            name: RouteNames.otpVerification,
            builder: (context, state) {
              final phone = state.uri.queryParameters['phone'] ?? '';
              // OTP screen placeholder — no dedicated screen file provided
              return Scaffold(
                appBar: AppBar(title: const Text('التحقق من الرمز')),
                body: Center(
                  child: Text(
                    'رمز التحقق للرقم: $phone',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.pathRegister,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Craftsman profile setup (post-register) ───────────────────────────
      GoRoute(
        path: RouteNames.pathCraftsmanProfileSetup,
        name: RouteNames.craftsmanProfileSetup,
        builder: (context, state) => const CraftsmanProfileSetupScreen(),
      ),

      // ── Main Shell (bottom navigation) ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            MainNavigationScreen(child: child),
        routes: [
          // Home tab
          GoRoute(
            path: RouteNames.pathHome,
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),

          // Craftsmen tab
          GoRoute(
            path: RouteNames.pathCraftsmenList,
            name: RouteNames.craftsmenList,
            builder: (context, state) => const CraftsmenListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.craftsmanDetail,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CraftsmanDetailScreen(craftsmanId: id);
                },
                routes: [
                  GoRoute(
                    path: 'portfolio',
                    name: RouteNames.portfolio,
                    builder: (context, state) {
                      // Portfolio is part of CraftsmanDetailScreen — navigate back
                      final id = state.pathParameters['id']!;
                      return CraftsmanDetailScreen(craftsmanId: id);
                    },
                  ),
                  GoRoute(
                    path: 'review',
                    name: RouteNames.writeReview,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return WriteReviewScreen(
                        craftsmanId: id,
                        targetName: '',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Listings tab
          GoRoute(
            path: RouteNames.pathListingsList,
            name: RouteNames.listingsList,
            builder: (context, state) => const ListingsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.listingDetail,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ListingDetailScreen(listingId: id);
                },
              ),
            ],
          ),

          // Chat tab
          GoRoute(
            path: RouteNames.pathChatList,
            name: RouteNames.chatList,
            builder: (context, state) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: ':conversationId',
                name: RouteNames.chatRoom,
                builder: (context, state) {
                  final id = state.pathParameters['conversationId']!;
                  return ChatRoomScreen(roomId: id);
                },
              ),
            ],
          ),

          // Profile tab
          GoRoute(
            path: RouteNames.pathProfile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Standalone protected routes (outside shell) ───────────────────────
      GoRoute(
        path: RouteNames.pathFavorites,
        name: RouteNames.favorites,
        builder: (context, state) => const MyFavoritesScreen(),
      ),
      GoRoute(
        path: RouteNames.pathNotifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.pathSettings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.pathMyListings,
        name: RouteNames.myListings,
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/create-listing',
        name: RouteNames.createListing,
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],

    // ── Error page ───────────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.pathHome),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Auth routes that do not require a valid token
// ---------------------------------------------------------------------------

const _authRoutes = {
  RouteNames.pathLogin,
  RouteNames.pathRegister,
  RouteNames.pathOnboarding,
  RouteNames.pathSplash,
  '/login/forgot-password',
  '/login/reset-password',
  '/login/otp',
};
