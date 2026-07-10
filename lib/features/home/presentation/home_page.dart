import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/animations/motion_system.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/providers/library_providers.dart';
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
  final storage = ref.watch(storageServiceProvider);
  final sourceManager = ref.watch(sourceManagerProvider);
  ref.watch(tasteEngineNotifierProvider);
  final accountService = ref.watch(ytAccountServiceProvider);

  try {
    final genericFeed = await sourceManager.getHome();
    HomeFeed finalFeed = genericFeed;

    if (accountService.isLoggedIn) {
      try {
        final ytmSections = await accountService.fetchPersonalizedHomeSections();
        final List<HomeFeedSection> newSections = [];

        final ytmSongs = ytmSections['songs'] ?? [];
        if (ytmSongs.isNotEmpty) {
          final domainSongs = ytmSongs.map((s) => Song(
            id: s.id,
            title: s.title,
            artistId: s.artist,
            albumId: s.album,
            duration: DurationValue(s.duration),
            thumbnail: Artwork(s.artworkUrl ?? ''),
            artwork: Artwork(s.artworkUrl ?? ''),
            sourceId: s.source,
          )).toList();
          newSections.add(HomeFeedSection(
            title: 'Recommended for You',
            type: 'recommended',
            items: domainSongs,
          ));
        } else {
          newSections.add(genericFeed.sections.firstWhere((s) => s.type == 'recommended'));
        }

        final ytmAlbums = ytmSections['albums'] ?? [];
        if (ytmAlbums.isNotEmpty) {
          final domainAlbums = ytmAlbums.map((a) => Album(
            id: a.id,
            title: a.name,
            artistId: a.artist,
            cover: Artwork(a.artworkUrl ?? ''),
            year: 2026,
            trackCount: 10,
            duration: DurationValue(const Duration(minutes: 40)),
          )).toList();
          newSections.add(HomeFeedSection(
            title: 'Recommended Albums',
            type: 'albums',
            items: domainAlbums,
          ));
        } else {
          newSections.add(genericFeed.sections.firstWhere((s) => s.type == 'albums'));
        }

        final ytmPlaylists = ytmSections['playlists'] ?? [];
        if (ytmPlaylists.isNotEmpty) {
          final domainPlaylists = ytmPlaylists.map((p) => Playlist(
            id: p.id,
            title: p.name,
            description: 'YouTube Music Mix',
            cover: Artwork(p.artworkUrl ?? ''),
            owner: 'YouTube Music',
            songIds: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )).toList();
          newSections.add(HomeFeedSection(
            title: 'Daily Mixes & Playlists',
            type: 'playlists',
            items: domainPlaylists,
          ));
        } else {
          newSections.add(genericFeed.sections.firstWhere((s) => s.type == 'playlists'));
        }

        finalFeed = HomeFeed(sections: newSections);
      } catch (_) {}
    }

    // Save final feed to offline cache
    final jsonStr = HomeFeedCacheSerializer.serialize(finalFeed);
    await storage.setString('ytm_cache_home_feed', jsonStr);

    return finalFeed;
  } catch (e) {
    // Retrieve from offline cache on error/offline
    final cached = await storage.getString('ytm_cache_home_feed');
    if (cached != null && cached.isNotEmpty) {
      return HomeFeedCacheSerializer.deserialize(cached);
    }
    // Return empty fallback feed
    return HomeFeed(sections: [
      HomeFeedSection(title: 'Recommended for You', type: 'recommended', items: const []),
      HomeFeedSection(title: 'Trending Albums', type: 'albums', items: const []),
      HomeFeedSection(title: 'Featured Playlists', type: 'playlists', items: const []),
    ]);
  }
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

class HomeFeedCacheSerializer {
  static String serialize(HomeFeed feed) {
    final List<Map<String, dynamic>> sectionsList = [];
    for (final section in feed.sections) {
      final List<Map<String, dynamic>> itemsList = [];
      for (final item in section.items) {
        if (item is Song) {
          itemsList.add({
            '__type': 'song',
            'id': item.id,
            'title': item.title,
            'artistId': item.artistId,
            'albumId': item.albumId,
            'durationMs': item.duration.value.inMilliseconds,
            'thumbnailUrl': item.thumbnail.url,
            'artworkUrl': item.artwork.url,
            'sourceId': item.sourceId,
          });
        } else if (item is Album) {
          itemsList.add({
            '__type': 'album',
            'id': item.id,
            'title': item.title,
            'artistId': item.artistId,
            'coverUrl': item.cover.url,
            'year': item.year,
            'trackCount': item.trackCount,
            'durationMs': item.duration.value.inMilliseconds,
          });
        } else if (item is Playlist) {
          itemsList.add({
            '__type': 'playlist',
            'id': item.id,
            'title': item.title,
            'description': item.description,
            'coverUrl': item.cover.url,
            'owner': item.owner,
            'songIds': item.songIds,
            'createdAt': item.createdAt.toIso8601String(),
            'updatedAt': item.updatedAt.toIso8601String(),
          });
        }
      }
      sectionsList.add({
        'title': section.title,
        'type': section.type,
        'items': itemsList,
      });
    }
    return jsonEncode(sectionsList);
  }

  static HomeFeed deserialize(String jsonStr) {
    try {
      final List<dynamic> sectionsList = jsonDecode(jsonStr);
      final List<HomeFeedSection> sections = [];
      for (final secMap in sectionsList) {
        if (secMap is Map) {
          final String title = secMap['title'] as String? ?? 'Untitled Section';
          final String type = secMap['type'] as String? ?? 'generic';
          final List<dynamic> itemsList = secMap['items'] as List? ?? [];
          final List<dynamic> items = [];

          for (final itemMap in itemsList) {
            if (itemMap is Map) {
              final typeKey = itemMap['__type'] as String?;
              if (typeKey == 'song') {
                items.add(Song(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  artistId: itemMap['artistId'] as String? ?? '',
                  albumId: itemMap['albumId'] as String? ?? '',
                  duration: DurationValue(Duration(milliseconds: itemMap['durationMs'] as int? ?? 0)),
                  thumbnail: Artwork(itemMap['thumbnailUrl'] as String?),
                  artwork: Artwork(itemMap['artworkUrl'] as String?),
                  sourceId: itemMap['sourceId'] as String? ?? '',
                ));
              } else if (typeKey == 'album') {
                items.add(Album(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  artistId: itemMap['artistId'] as String? ?? '',
                  cover: Artwork(itemMap['coverUrl'] as String?),
                  year: itemMap['year'] as int? ?? 2026,
                  trackCount: itemMap['trackCount'] as int? ?? 0,
                  duration: DurationValue(Duration(milliseconds: itemMap['durationMs'] as int? ?? 0)),
                ));
              } else if (typeKey == 'playlist') {
                items.add(Playlist(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  description: itemMap['description'] as String? ?? '',
                  cover: Artwork(itemMap['coverUrl'] as String?),
                  owner: itemMap['owner'] as String? ?? '',
                  songIds: List<String>.from(itemMap['songIds'] ?? []),
                  createdAt: DateTime.tryParse(itemMap['createdAt'] as String? ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.tryParse(itemMap['updatedAt'] as String? ?? '') ?? DateTime.now(),
                ));
              }
            }
          }
          sections.add(HomeFeedSection(
            title: title,
            type: type,
            items: items,
          ));
        }
      }
      return HomeFeed(sections: sections);
    } catch (_) {
      return HomeFeed(sections: []);
    }
  }
}
