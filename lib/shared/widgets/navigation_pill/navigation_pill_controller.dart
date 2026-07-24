import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'navigation_pill_item.dart';

class NavigationPillController {
  final BuildContext context;
  final List<NavigationPillItem> items = const [
    NavigationPillItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      route: '/',
    ),
    NavigationPillItem(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: 'Search',
      route: '/search',
    ),
    NavigationPillItem(
      icon: Icons.my_library_music_outlined,
      selectedIcon: Icons.my_library_music,
      label: 'Library',
      route: '/library',
    ),
    NavigationPillItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  const NavigationPillController(this.context);

  int get currentIndex {
    final location = GoRouterState.of(context).matchedLocation;
    final index = items.indexWhere((item) => item.route == location);
    return index != -1 ? index : 0;
  }

  void navigateTo(int index) {
    if (index >= 0 && index < items.length) {
      HapticFeedback.lightImpact();
      context.go(items[index].route);
    }
  }
}
