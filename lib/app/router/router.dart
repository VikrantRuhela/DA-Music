import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import placeholder screens
import '../../features/home/presentation/home_page.dart';
import '../../features/library/presentation/library_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/player/presentation/player_page.dart';
import '../../features/lyrics/presentation/lyrics_page.dart';
import '../../features/queue/presentation/queue_page.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/album/presentation/album_page.dart';
import '../../features/artist/presentation/artist_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/onboarding/presentation/welcome_page.dart';
import '../../features/onboarding/presentation/guest_onboarding_page.dart';
import '../../shared/providers/backend_providers.dart';

// Global navigator key
final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

/// Reactive router configuration provider.
final goRouterProvider = Provider<GoRouter>((ref) {
  final sessionManager = ref.watch(sessionManagerProvider);

  return GoRouter(
    initialLocation: '/',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: sessionManager,
    redirect: (context, state) {
      final isLoggedIn = sessionManager.isLoggedIn;
      final isGuestMode = sessionManager.isGuestMode;
      final isGuestOnboardingCompleted = sessionManager.isGuestOnboardingCompleted;
      final isGoingToWelcome = state.matchedLocation == '/welcome';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isGuestMode) {
        return '/welcome';
      }

      if (isGuestMode && !isGuestOnboardingCompleted) {
        if (!isGoingToOnboarding) {
          return '/onboarding';
        }
        return null;
      }

      if (isGoingToWelcome && (isLoggedIn || isGuestMode)) {
        return '/';
      }

      if (isGoingToOnboarding && (isLoggedIn || (isGuestMode && isGuestOnboardingCompleted))) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const GuestOnboardingPage(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) {
              final query = state.uri.queryParameters['q'] ?? '';
              return SearchPage(initialQuery: query);
            },
          ),
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryPage(),
          ),
          GoRoute(
            path: '/player',
            builder: (context, state) => const PlayerPage(),
          ),
          GoRoute(
            path: '/lyrics',
            builder: (context, state) => const LyricsPage(),
          ),
          GoRoute(
            path: '/queue',
            builder: (context, state) => const QueuePage(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/album/:id',
            builder: (context, state) {
              final albumId = state.pathParameters['id'] ?? '';
              return AlbumPage(albumId: albumId);
            },
          ),
          GoRoute(
            path: '/artist/:id',
            builder: (context, state) {
              final artistId = state.pathParameters['id'] ?? '';
              return ArtistPage(artistId: artistId);
            },
          ),
        ],
      ),
    ],
  );
});
