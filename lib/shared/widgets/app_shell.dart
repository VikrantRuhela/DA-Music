import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/device_memory_manager.dart';
import '../../app/theme/tokens.dart';
import '../../shared/providers/player_providers.dart';
import '../../shared/providers/library_providers.dart';
import '../../shared/animations/motion_system.dart';
import 'custom_title_bar.dart';
import '../../features/player/presentation/widgets/mini_player.dart';
import '../../features/player/presentation/widgets/player_panel.dart';
import '../../features/home/presentation/widgets/navigation_rail.dart';
import '../../features/player/presentation/widgets/immersive/android_sliding_player.dart';
import 'ambient_background.dart';
import '../../features/taste_engine/presentation/taste_playback_observer.dart';
import '../../app/router/router.dart';
import 'navigation_pill/navigation_pill.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const MethodChannel _appLaunchChannel = MethodChannel('com.vikrantruhela.datunes/app_launch');

  @override
  void initState() {
    super.initState();
    _checkLaunchIntent();
  }

  void _checkLaunchIntent() async {
    try {
      final action = await _appLaunchChannel.invokeMethod<String>('getInitialAction');
      if (action == 'open_player') {
        ref.read(immersiveModeProvider.notifier).state = true;
      }
    } catch (_) {}

    _appLaunchChannel.setMethodCallHandler((call) async {
      if (call.method == 'onLaunchIntent' && call.arguments == 'open_player') {
        ref.read(immersiveModeProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final currentSong = ref.watch(currentSongProvider);
    final isImmersive = ref.watch(immersiveModeProvider);
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final showAlbumArt = ref.watch(showAlbumArtBackgroundProvider);
    final isLowRam = DeviceMemoryManager.instance.isLowRamDevice;
    debugPrint(' [AppShell] build - isImmersive: $isImmersive, currentSong: ${currentSong?.title}, showAlbumArt: $showAlbumArt');

    if (isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool showPlayerPanel = screenWidth >= 1200;
    final bool showNavRail = screenWidth >= 700;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    final duration = ref.scaledDuration(isImmersive ? DAMotion.large : const Duration(milliseconds: 380));
    final curve = ref.scaledCurve(DAMotion.fastOutSlowIn);

    final containerBorderRadius = isImmersive
        ? BorderRadius.zero
        : (isAndroid
            ? const BorderRadius.vertical(
                top: Radius.circular(DATokens.radiusXXLarge),
              )
            : BorderRadius.circular(DATokens.radiusXXLarge));

    final containerMargin = isImmersive
        ? EdgeInsets.zero
        : (isAndroid
            ? const EdgeInsets.only(
                top: DATokens.spacingSmall,
                left: DATokens.spacingSmall,
                right: DATokens.spacingSmall,
                bottom: 0.0,
              )
            : const EdgeInsets.all(DATokens.spacingSmall));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If full-screen immersive player is open, close immersive mode first
        if (ref.read(immersiveModeProvider)) {
          ref.read(immersiveModeProvider.notifier).state = false;
          return;
        }

        // 2. Check if shellNavigatorKey can pop nested screens (e.g. /album/:id -> /library)
        if (shellNavigatorKey.currentState != null && shellNavigatorKey.currentState!.canPop()) {
          shellNavigatorKey.currentState!.pop();
          return;
        }

        // 3. Check current location
        final location = GoRouterState.of(context).matchedLocation;

        // 4. If on any tab/page other than Home ('/'), navigate back to Home
        if (location != '/') {
          context.go('/');
          return;
        }

        // 5. If already on Home ('/'), exit app naturally
        SystemNavigator.pop();
      },
      child: TastePlaybackObserver(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AmbientBackground(
          child: Stack(
            children: [
              SafeArea(
                bottom: !isAndroid,
                child: Column(
                  children: [
                    const CustomTitleBar(),
                    Expanded(
                      child: Row(
                        children: [
                          if (showNavRail && !isImmersive)
                            const _DesktopNavRail(),
                          Expanded(
                            child: AnimatedOpacity(
                              opacity: isImmersive ? 0.0 : 1.0,
                              duration: duration,
                              curve: curve,
                              child: Container(
                                margin: containerMargin,
                                child: ClipRRect(
                                  borderRadius: containerBorderRadius,
                                  child: Stack(
                                    children: [
                                      // Layer 2: Main Dark Wine Container Surface (with frosted glass blur when showAlbumArt is enabled)
                                      Positioned.fill(
                                        child: showAlbumArt
                                            ? ClipRect(
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: isLowRam ? 16.0 : 25.0,
                                                    sigmaY: isLowRam ? 16.0 : 25.0,
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: isImmersive ? Colors.transparent : colors.background.withValues(alpha: 0.50),
                                                      borderRadius: containerBorderRadius,
                                                      border: Border.all(
                                                        color: isImmersive ? Colors.transparent : colors.border.withValues(alpha: 0.4),
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  color: isImmersive ? Colors.transparent : colors.background,
                                                  borderRadius: containerBorderRadius,
                                                  border: Border.all(
                                                    color: isImmersive ? Colors.transparent : colors.border.withValues(alpha: 0.4),
                                                    width: 1.0,
                                                  ),
                                                ),
                                              ),
                                      ),

                                      // Layer 3: 100% Sharp & Unblurred Foreground Page UI
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          ignoring: isImmersive,
                                          child: Stack(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: isAndroid && !isImmersive
                                                      ? (ref.watch(currentSongProvider) != null ? 144.0 + bottomPadding : 80.0 + bottomPadding)
                                                      : 0.0,
                                                ),
                                                child: widget.child,
                                              ),
                                              if (!isAndroid && !showPlayerPanel && !isImmersive)
                                                const Align(
                                                  alignment: Alignment.bottomCenter,
                                                  child: MiniPlayer(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!isAndroid)
                            AnimatedContainer(
                              duration: duration,
                              curve: curve,
                              width: isImmersive ? screenWidth : (showPlayerPanel ? 360.0 : 0.0),
                              child: PersistentPlayerPanel(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isAndroid)
                const AndroidSlidingPlayer(),
              if (isAndroid && !isImmersive)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _AndroidBottomDock(showPlayerPanel: showPlayerPanel),
                ),
            ],
          ),
        ),
        bottomNavigationBar: (!isAndroid && screenWidth < 700 && !isImmersive)
            ? const _MobileBottomNavBar()
            : null,
      ),
    ),
    );
  }
}

class _DesktopNavRail extends ConsumerWidget {
  const _DesktopNavRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isImmersive = ref.watch(immersiveModeProvider);
    final duration = ref.scaledDuration(isImmersive ? DAMotion.large : const Duration(milliseconds: 380));
    final curve = ref.scaledCurve(DAMotion.fastOutSlowIn);

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: isImmersive ? 0.0 : 72.0,
      child: ClipRect(
        child: OverflowBox(
          minWidth: 72.0,
          maxWidth: 72.0,
          alignment: Alignment.centerLeft,
          child: AnimatedOpacity(
            opacity: isImmersive ? 0.0 : 1.0,
            duration: duration,
            curve: curve,
            child: NavigationRailWidget(),
          ),
        ),
      ),
    );
  }
}

class _AndroidBottomDock extends ConsumerWidget {
  final bool showPlayerPanel;

  const _AndroidBottomDock({required this.showPlayerPanel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NavigationPill(),
          ],
        ),
      ),
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
        color: colors.surface.withValues(alpha: 0.65),
        border: Border(
          top: BorderSide(
            color: colors.border.withValues(alpha: 0.4),
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
