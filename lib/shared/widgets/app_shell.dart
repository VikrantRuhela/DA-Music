import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../app/theme/tokens.dart';
import '../../features/home/presentation/widgets/navigation_rail.dart';
import '../../features/player/presentation/widgets/player_panel.dart';
import '../providers/player_providers.dart';
import '../animations/motion_system.dart';
import 'custom_title_bar.dart';
import '../../features/player/presentation/widgets/mini_player.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final isImmersive = ref.watch(immersiveModeProvider);

    final duration = ref.scaledDuration(isImmersive ? DAMotion.large : const Duration(milliseconds: 380));
    final curve = ref.scaledCurve(DAMotion.fastOutSlowIn);



    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const CustomTitleBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            // Responsive breakpoints
            final bool showPlayerPanel = screenWidth >= 1200;
            final bool showNavRail = screenWidth >= 700;

            final double railWidth = isImmersive ? 0.0 : (showNavRail ? 72.0 : 0.0);
            final double playerPanelWidth = isImmersive ? screenWidth : (showPlayerPanel ? 360.0 : 0.0);

            return Row(
              children: [
                // Navigation Rail
                AnimatedContainer(
                  duration: duration,
                  curve: curve,
                  width: railWidth,
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 72.0,
                      maxWidth: 72.0,
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        opacity: isImmersive ? 0.0 : 1.0,
                        duration: duration,
                        curve: curve,
                        child: const NavigationRailWidget(),
                      ),
                    ),
                  ),
                ),

                // Main Content Panel
                Expanded(
                  child: AnimatedOpacity(
                    opacity: isImmersive ? 0.0 : 1.0,
                    duration: duration,
                    curve: curve,
                    child: ClipRect(
                      child: Container(
                        margin: isImmersive ? EdgeInsets.zero : const EdgeInsets.all(DATokens.spacingSmall),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(isImmersive ? 0.0 : DATokens.radiusXXLarge),
                          border: Border.all(
                            color: isImmersive ? Colors.transparent : colors.border,
                            width: 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IgnorePointer(
                          ignoring: isImmersive,
                          child: Stack(
                            children: [
                              child,
                              if (!showPlayerPanel && !isImmersive)
                                const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: MiniPlayer(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Persistent / Fullscreen Player Panel
                AnimatedContainer(
                  duration: duration,
                  curve: curve,
                  width: playerPanelWidth,
                  child: const PersistentPlayerPanel(),
                ),
              ],
            );
          },
        ),
      ),
    ],
  ),
),
      bottomNavigationBar: MediaQuery.of(context).size.width < 700 && !isImmersive
          ? const _MobileBottomNavBar()
          : null,
    );
  }
}

class _MobileBottomNavBar extends StatelessWidget {
  const _MobileBottomNavBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      height: 64.0,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MobileNavTab(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            route: '/',
            currentLocation: location,
          ),
          _MobileNavTab(
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            route: '/search',
            currentLocation: location,
          ),
          _MobileNavTab(
            icon: Icons.my_library_music_outlined,
            selectedIcon: Icons.my_library_music,
            route: '/library',
            currentLocation: location,
          ),
          _MobileNavTab(
            icon: Icons.favorite_border_outlined,
            selectedIcon: Icons.favorite,
            route: '/favorites',
            currentLocation: location,
          ),
          _MobileNavTab(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            route: '/settings',
            currentLocation: location,
          ),
        ],
      ),
    );
  }
}

class _MobileNavTab extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final String currentLocation;

  const _MobileNavTab({
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final isSelected = currentLocation == route;

    return GestureDetector(
      onTap: () => context.go(route),
      child: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? colors.primary : colors.textSecondary,
        size: DATokens.iconMedium,
      ),
    );
  }
}
