import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../app/theme/tokens.dart';

class NavigationRailWidget extends StatelessWidget {
  const NavigationRailWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 72.0,
      margin: const EdgeInsets.all(DATokens.spacingSmall),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(DATokens.radiusXXLarge),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DATokens.spacingLarge),
            child: Icon(
              Icons.music_note,
              color: colors.primary,
              size: DATokens.iconLarge,
            ),
          ),

          // Vertically Centered Navigation Items
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavRailItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  route: '/',
                  currentLocation: location,
                  tooltip: 'Home',
                ),
                const SizedBox(height: DATokens.spacingMedium),
                _NavRailItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search,
                  route: '/search',
                  currentLocation: location,
                  tooltip: 'Search',
                ),
                const SizedBox(height: DATokens.spacingMedium),
                _NavRailItem(
                  icon: Icons.my_library_music_outlined,
                  selectedIcon: Icons.my_library_music,
                  route: '/library',
                  currentLocation: location,
                  tooltip: 'Library',
                ),
                const SizedBox(height: DATokens.spacingMedium),
                _NavRailItem(
                  icon: Icons.favorite_border_outlined,
                  selectedIcon: Icons.favorite,
                  route: '/favorites',
                  currentLocation: location,
                  tooltip: 'Favorites',
                ),
              ],
            ),
          ),

          // Settings Pinned to Bottom
          Padding(
            padding: const EdgeInsets.only(bottom: DATokens.spacingLarge),
            child: _NavRailItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              route: '/settings',
              currentLocation: location,
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRailItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final String currentLocation;
  final String tooltip;

  const _NavRailItem({
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.currentLocation,
    required this.tooltip,
  });

  @override
  State<_NavRailItem> createState() => _NavRailItemState();
}

class _NavRailItemState extends State<_NavRailItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final isSelected = widget.currentLocation == widget.route;

    final color = isSelected
        ? colors.primary
        : (_isHovered ? colors.textPrimary : colors.textSecondary);

    final scale = _isHovered ? 1.1 : 1.0;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.route),
          child: AnimatedScale(
            scale: scale,
            duration: DATokens.durationFast,
            curve: DATokens.curveHover,
            child: AnimatedContainer(
              duration: DATokens.durationFast,
              curve: DATokens.curveHover,
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.1)
                    : (_isHovered ? colors.surfaceHover : Colors.transparent),
                borderRadius: BorderRadius.circular(DATokens.radiusLarge),
              ),
              child: Icon(
                isSelected ? widget.selectedIcon : widget.icon,
                color: color,
                size: DATokens.iconMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
