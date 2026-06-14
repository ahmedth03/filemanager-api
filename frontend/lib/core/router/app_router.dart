import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/craftsmen/presentation/craftsmen_screen.dart';
import '../../features/craftsmen/presentation/craftsman_detail_screen.dart';
import '../../features/properties/presentation/properties_screen.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/chat_room_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/reviews/presentation/add_review_screen.dart';
import '../../features/reports/presentation/report_screen.dart';

// ── Route paths ──────────────────────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const craftsmen = '/craftsmen';
  static const craftsmanDetail = '/craftsmen/:id';
  static const properties = '/properties';
  static const propertyDetail = '/properties/:id';
  static const profile = '/profile';
  static const chat = '/chat';
  static const chatRoom = '/chat/:roomId';
  static const notifications = '/notifications';
  static const addReview = '/reviews/add';
  static const report = '/report';
}

// ── Router provider ───────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final isLoggedIn = authAsync.valueOrNull ?? false;
      final location = state.matchedLocation;

      final isOnAuthPage =
          location == AppRoutes.login || location == AppRoutes.register;

      // Don't redirect while loading or on splash
      if (authAsync.isLoading || location == AppRoutes.splash) return null;

      if (!isLoggedIn && !isOnAuthPage) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isOnAuthPage) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.craftsmen,
        builder: (context, state) => const CraftsmenScreen(),
      ),
      GoRoute(
        path: AppRoutes.properties,
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatRoom,
        builder: (context, state) =>
            ChatRoomScreen(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(
        path: AppRoutes.craftsmanDetail,
        builder: (context, state) =>
            CraftsmanDetailScreen(craftsmanId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.propertyDetail,
        builder: (context, state) =>
            PropertyDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addReview,
        builder: (context, state) => AddReviewScreen(
          craftsmanId: state.uri.queryParameters['craftsmanId'],
          listingId: state.uri.queryParameters['listingId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.report,
        builder: (context, state) => ReportScreen(
          targetId: state.uri.queryParameters['targetId'] ?? '',
          type: state.uri.queryParameters['type'] ?? 'USER',
        ),
      ),
    ],
  );
});

// ── Splash Screen ─────────────────────────────────────────────────────────────
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final authAsync = ref.read(authStateProvider);
      final isLoggedIn = authAsync.valueOrNull ?? false;
      context.go(isLoggedIn ? AppRoutes.home : AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'حرفي دار',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ابحث عن حرفيين • استأجر عقارات',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.7),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Home Screen with BottomNavigationBar ──────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    _HomeOverviewTab(),
    CraftsmenScreen(),
    PropertiesScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Cairo', fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handyman_outlined),
              activeIcon: Icon(Icons.handyman_rounded),
              label: 'الحرفيون',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apartment_outlined),
              activeIcon: Icon(Icons.apartment_rounded),
              label: 'العقارات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'المحادثات',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home Overview Tab ─────────────────────────────────────────────────────────
class _HomeOverviewTab extends ConsumerWidget {
  const _HomeOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'حرفي دار',
          style: TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'الإشعارات',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'الملف الشخصي',
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null) ...[
            Text(
              'مرحباً، ${user.name.split(' ').first}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ماذا تريد اليوم؟',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 8),
          _HomeCard(
            icon: Icons.handyman_rounded,
            color: AppColors.primary,
            title: 'ابحث عن حرفي',
            subtitle: 'سباك، كهربائي، نجار وأكثر...',
            onTap: () => context.push(AppRoutes.craftsmen),
          ),
          const SizedBox(height: 16),
          _HomeCard(
            icon: Icons.apartment_rounded,
            color: AppColors.accent,
            title: 'استأجر عقاراً',
            subtitle: 'شقق، منازل، فيلات...',
            onTap: () => context.push(AppRoutes.properties),
          ),
          const SizedBox(height: 16),
          _HomeCard(
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.success,
            title: 'المحادثات',
            subtitle: 'تواصل مع الحرفيين والملاك',
            onTap: () => context.push(AppRoutes.chat),
          ),
          const SizedBox(height: 16),
          _HomeCard(
            icon: Icons.person_rounded,
            color: AppColors.info,
            title: 'الملف الشخصي',
            subtitle: 'إعداداتك ومعلوماتك الشخصية',
            onTap: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
