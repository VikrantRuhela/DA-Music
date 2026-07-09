import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/animations/motion_system.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../domain/entities/home_feed.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/playlist.dart';
import 'widgets/greeting_widget.dart';
import 'widgets/search_widget.dart';
import 'widgets/recently_played_widget.dart';
import 'widgets/favorites_grid.dart';
import 'widgets/recommended_section.dart';
import '../../taste_engine/presentation/providers/taste_engine_providers.dart';
import '../../../domain/entities/value_objects.dart';

final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final sourceManager = ref.watch(sourceManagerProvider);
  ref.watch(tasteEngineNotifierProvider);

  final genericFeed = await sourceManager.getHome();
  final accountService = ref.watch(ytAccountServiceProvider);

  if (accountService.isLoggedIn) {
    try {
      final ytmSongs = await accountService.fetchPersonalizedRecommendations();
      if (ytmSongs.isNotEmpty) {
        final domainSongs = ytmSongs.map((s) => Song(
          id: s.id,
          title: s.title,
          artistId: s.artist,
          albumId: s.album,
          duration: DurationValue(s.duration),
          thumbnail: Artwork(s.artworkUrl),
          artwork: Artwork(s.artworkUrl),
          sourceId: s.source,
        )).toList();

        // Replace only the recommended songs section
        final sections = genericFeed.sections.map((section) {
          if (section.type == 'recommended') {
            return HomeFeedSection(
              title: 'Recommended for You',
              type: 'recommended',
              items: domainSongs,
            );
          }
          return section;
        }).toList();

        return HomeFeed(sections: sections);
      }
    } catch (_) {}
  }

  return genericFeed;
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleMode = ref.watch(motionScaleModeProvider);
    final homeFeedAsync = ref.watch(homeFeedProvider);
    final recommendationsAsync = ref.watch(personalizedRecommendationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: homeFeedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_outlined, color: Colors.redAccent, size: DATokens.iconXLarge),
              const SizedBox(height: DATokens.spacingMedium),
              const Text(
                'Failed to load Home Feed',
                style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: DATokens.spacingTiny),
              Text(
                err.toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (feed) {
          final recommendedSection = feed.sections.firstWhere((s) => s.type == 'recommended');
          final albumsSection = feed.sections.firstWhere((s) => s.type == 'albums');
          final playlistsSection = feed.sections.firstWhere((s) => s.type == 'playlists');

          final List<Song> recommendedSongs = recommendationsAsync.maybeWhen(
            data: (songs) => songs.isNotEmpty
                ? songs.map((s) => Song(
                    id: s.id,
                    title: s.title,
                    artistId: s.artist,
                    albumId: s.album,
                    duration: DurationValue(s.duration),
                    thumbnail: Artwork(s.artworkUrl),
                    artwork: Artwork(s.artworkUrl),
                    sourceId: s.source,
                  )).toList()
                : recommendedSection.items.cast<Song>(),
            orElse: () => recommendedSection.items.cast<Song>(),
          );

          final children = [
            const GreetingWidget(),
            const SearchWidget(),
            RecommendedSection(albums: albumsSection.items.cast<Album>()),
            RecentlyPlayedWidget(songs: recommendedSongs),
            FavoritesGrid(playlists: playlistsSection.items.cast<Playlist>()),
          ];

          Widget listWidget;
          if (scaleMode == MotionScaleMode.disabled) {
            listWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          } else {
            final interval = scaleMode == MotionScaleMode.reduced ? 25.ms : 50.ms;
            final duration = scaleMode == MotionScaleMode.reduced ? 120.ms : 250.ms;

            listWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children
                  .animate(interval: interval)
                  .fadeIn(duration: duration, curve: Curves.easeOut)
                  .slideY(begin: 0.03, end: 0, duration: duration, curve: Curves.easeOut),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: DATokens.spacingLarge,
              vertical: DATokens.spacingMedium,
            ),
            child: listWidget,
          );
        },
      ),
    );
  }
}
