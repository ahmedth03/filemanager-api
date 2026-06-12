import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

class MainNavigationScreen extends ConsumerWidget {
  final Widget child;
  const MainNavigationScreen({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RouteNames.pathCraftsmenList)) return 1;
    if (location.startsWith(RouteNames.pathListingsList)) return 2;
    if (location.startsWith(RouteNames.pathChatList)) return 3;
    if (location.startsWith(RouteNames.pathProfile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.pathHome);
        break;
      case 1:
        context.go(RouteNames.pathCraftsmenList);
        break;
      case 2:
        context.go(RouteNames.pathListingsList);
        break;
      case 3:
        context.go(RouteNames.pathChatList);
        break;
      case 4:
        context.go(RouteNames.pathProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndex(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.1),
          surfaceTintColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.handyman_outlined),
              selectedIcon: Icon(Icons.handyman, color: AppColors.primary),
              label: 'حرفيون',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment, color: AppColors.primary),
              label: 'عقارات',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon:
                  Icon(Icons.chat_bubble, color: AppColors.primary),
              label: 'رسائل',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
