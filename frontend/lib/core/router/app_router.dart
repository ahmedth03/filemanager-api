import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../storage/secure_storage.dart';
import 'route_names.dart';

// ---------------------------------------------------------------------------
// Placeholder screens — replace with real screen imports once features exist
// ---------------------------------------------------------------------------

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 20))),
    );
  }
}

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
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Splash'),
      ),

      // ── Onboarding ───────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.pathOnboarding,
        name: RouteNames.onboarding,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Onboarding'),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.pathLogin,
        name: RouteNames.login,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Login'),
        routes: [
          GoRoute(
            path: 'forgot-password',
            name: RouteNames.forgotPassword,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Forgot Password'),
          ),
          GoRoute(
            path: 'reset-password',
            name: RouteNames.resetPassword,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Reset Password'),
          ),
          GoRoute(
            path: 'otp',
            name: RouteNames.otpVerification,
            builder: (context, state) {
              final phone = state.uri.queryParameters['phone'] ?? '';
              return _PlaceholderScreen(
                  title: 'OTP Verification – $phone');
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.pathRegister,
        name: RouteNames.register,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Register'),
      ),

      // ── Craftsman profile setup (post-register) ───────────────────────────
      GoRoute(
        path: RouteNames.pathCraftsmanProfileSetup,
        name: RouteNames.craftsmanProfileSetup,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Craftsman Profile Setup'),
      ),

      // ── Main Shell (bottom navigation) ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            _MainNavigationShell(child: child),
        routes: [
          // Home tab
          GoRoute(
            path: RouteNames.pathHome,
            name: RouteNames.home,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Home'),
          ),

          // Craftsmen tab
          GoRoute(
            path: RouteNames.pathCraftsmenList,
            name: RouteNames.craftsmenList,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Craftsmen'),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.craftsmanDetail,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen(
                      title: 'Craftsman Detail – $id');
                },
                routes: [
                  GoRoute(
                    path: 'portfolio',
                    name: RouteNames.portfolio,
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Portfolio'),
                  ),
                  GoRoute(
                    path: 'review',
                    name: RouteNames.writeReview,
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Write Review'),
                  ),
                ],
              ),
            ],
          ),

          // Listings tab
          GoRoute(
            path: RouteNames.pathListingsList,
            name: RouteNames.listingsList,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Listings'),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.listingDetail,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen(
                      title: 'Listing Detail – $id');
                },
              ),
            ],
          ),

          // Chat tab
          GoRoute(
            path: RouteNames.pathChatList,
            name: RouteNames.chatList,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Chats'),
            routes: [
              GoRoute(
                path: ':conversationId',
                name: RouteNames.chatRoom,
                builder: (context, state) {
                  final id = state.pathParameters['conversationId']!;
                  return _PlaceholderScreen(
                      title: 'Chat Room – $id');
                },
              ),
            ],
          ),

          // Profile tab
          GoRoute(
            path: RouteNames.pathProfile,
            name: RouteNames.profile,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Profile'),
          ),
        ],
      ),

      // ── Standalone protected routes (outside shell) ───────────────────────
      GoRoute(
        path: RouteNames.pathFavorites,
        name: RouteNames.favorites,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Favorites'),
      ),
      GoRoute(
        path: RouteNames.pathNotifications,
        name: RouteNames.notifications,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Notifications'),
      ),
      GoRoute(
        path: RouteNames.pathSettings,
        name: RouteNames.settings,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Settings'),
      ),
      GoRoute(
        path: RouteNames.pathMyListings,
        name: RouteNames.myListings,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'My Listings'),
      ),
      GoRoute(
        path: '/create-listing',
        name: RouteNames.createListing,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Create Listing'),
      ),
      GoRoute(
        path: '/edit-profile',
        name: RouteNames.editProfile,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Edit Profile'),
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

// ---------------------------------------------------------------------------
// Main navigation shell — bottom navigation bar
// ---------------------------------------------------------------------------

class _MainNavigationShell extends StatelessWidget {
  const _MainNavigationShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith(RouteNames.pathCraftsmenList)) currentIndex = 1;
    if (location.startsWith(RouteNames.pathListingsList)) currentIndex = 2;
    if (location.startsWith(RouteNames.pathChatList)) currentIndex = 3;
    if (location.startsWith(RouteNames.pathProfile)) currentIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.pathHome);
            case 1:
              context.go(RouteNames.pathCraftsmenList);
            case 2:
              context.go(RouteNames.pathListingsList);
            case 3:
              context.go(RouteNames.pathChatList);
            case 4:
              context.go(RouteNames.pathProfile);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman_outlined),
            activeIcon: Icon(Icons.handyman),
            label: 'الحرفيون',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            activeIcon: Icon(Icons.apartment),
            label: 'العقارات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'المحادثات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
