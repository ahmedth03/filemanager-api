import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/craftsmen/presentation/craftsmen_screen.dart';
import '../../features/properties/presentation/properties_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const craftsmen = '/craftsmen';
  static const properties = '/properties';
  static const profile = '/profile';
  static const chat = '/chat';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final isLoggedIn = await ref.read(authRepositoryProvider).isLoggedIn();
      final path = state.uri.path;
      if (!isLoggedIn && path != AppRoutes.login && path != AppRoutes.register && path != AppRoutes.splash) {
        return AppRoutes.login;
      }
      if (isLoggedIn && (path == AppRoutes.login || path == AppRoutes.register)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
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
        builder: (context, state) => const MainShell(),
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
    ],
  );
});

// ── Splash ────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4F72),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_work_outlined, size: 90, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'حرفي دار',
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'منصة الحرفيين والعقارات',
                  style: TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Main Shell with Bottom Nav ────────────────────────────────────────────────
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _screens = [
    _HomeTab(),
    CraftsmenScreen(),
    PropertiesScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حرفي دار', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B4F72),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push(AppRoutes.profile),
              tooltip: 'الملف الشخصي',
            ),
          ],
        ),
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1B4F72),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.construction_outlined), activeIcon: Icon(Icons.construction), label: 'الحرفيون'),
            BottomNavigationBarItem(icon: Icon(Icons.apartment_outlined), activeIcon: Icon(Icons.apartment), label: 'العقارات'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'المحادثات'),
          ],
        ),
      ),
    );
  }
}

// ── Home Tab Overview ─────────────────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'مرحباً، ${user?.name ?? 'بك'} 👋',
            style: const TextStyle(fontSize: 22, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'ماذا تريد اليوم؟',
            style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _QuickCard(
            icon: Icons.construction,
            title: 'ابحث عن حرفي',
            subtitle: 'سباكة، كهرباء، نجارة وأكثر',
            color: Colors.orange,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _QuickCard(
            icon: Icons.apartment,
            title: 'تصفح العقارات',
            subtitle: 'شقق، فلل، أراضي للبيع والإيجار',
            color: const Color(0xFF1B4F72),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _QuickCard(
            icon: Icons.chat_bubble,
            title: 'محادثاتي',
            subtitle: 'تواصل مع الحرفيين وأصحاب العقارات',
            color: Colors.teal,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Cairo')),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
