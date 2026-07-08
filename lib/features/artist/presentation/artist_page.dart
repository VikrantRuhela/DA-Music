import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/playlist.dart';
import '../../../shared/providers/backend_providers.dart';
import '../../../shared/providers/player_providers.dart';
import '../../../shared/models/music_models.dart' as shared;
import '../../../shared/utils/song_options.dart';
import '../../home/presentation/widgets/album_card.dart';

/// FutureProvider that loads the artist details and all associated shelves.
final artistDetailsProvider = FutureProvider.family<
    ({
      Artist artist,
      List<Song> topSongs,
      List<Album> albums,
      List<Album> singles,
      List<Playlist> playlists,
      List<Artist> relatedArtists
    }),
    String>((ref, artistId) async {
  final artistRepo = ref.watch(artistRepositoryProvider);
  final sourceManager = ref.watch(sourceManagerProvider);

  // 1. Fetch artist details (which populates caches in the adapter)
  final artist = await artistRepo.getArtistById(artistId);

  // 2. Retrieve the cached details mapped from the InnerTube response
  final topSongs = sourceManager.getArtistSongs(artistId);
  final albums = sourceManager.getArtistAlbums(artistId);
  final singles = sourceManager.getArtistSingles(artistId);
  final playlists = sourceManager.getArtistPlaylists(artistId);
  final relatedArtists = sourceManager.getArtistRelated(artistId);

  return (
    artist: artist,
    topSongs: topSongs,
    albums: albums,
    singles: singles,
    playlists: playlists,
    relatedArtists: relatedArtists,
  );
});

class ArtistPage extends ConsumerWidget {
  final String artistId;

  const ArtistPage({
    super.key,
    required this.artistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;
    final artistDetailsAsync = ref.watch(artistDetailsProvider(artistId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: artistDetailsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(DATokens.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_outlined,
                  color: Colors.redAccent,
                  size: DATokens.iconXLarge,
                ),
                const SizedBox(height: DATokens.spacingMedium),
                Text(
                  'Failed to load artist details',
                  style: typography.title.copyWith(fontSize: 18.0),
                ),
                const SizedBox(height: DATokens.spacingTiny),
                Text(
                  err.toString(),
                  style: typography.body.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final artist = data.artist;
          final topSongs = data.topSongs;
          final albums = data.albums;
          final singles = data.singles;
          final playlists = data.playlists;
          final related = data.relatedArtists;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Immersive Header with Artist image and details
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                stretch: true,
                backgroundColor: colors.surfaceCard,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  title: Text(
                    artist.name,
                    style: typography.headline.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          color: Colors.black54,
                          offset: Offset(0.0, 2.0),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (artist.image.url.isNotEmpty)
                        Image.network(
                          artist.image.url,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            color: colors.surfaceHover,
                            child: Icon(
                              Icons.person_outline,
                              size: 80,
                              color: colors.textSecondary,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: colors.surfaceHover,
                          child: Icon(
                            Icons.person_outline,
                            size: 80,
                            color: colors.textSecondary,
                          ),
                        ),
                      // Overlay dark gradient for readability
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black38,
                              Colors.black12,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DATokens.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Followers / Subscribers & Actions
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (artist.subscriberCount > 0)
                                  Text(
                                    '${_formatSubscribers(artist.subscriberCount)} Subscribers',
                                    style: typography.body.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (topSongs.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                final modelSongs = topSongs.map((s) => shared.Song(
                                  id: s.id,
                                  title: s.title,
                                  artist: s.artistId == 'Unknown Artist' ? artist.name : s.artistId,
                                  album: s.albumId,
                                  duration: s.duration.value,
                                  artworkUrl: s.artwork.url,
                                  source: s.sourceId,
                                  lyrics: null,
                                )).toList();
                                ref.read(playbackControllerProvider).setQueue(
                                  modelSongs,
                                  autoPlay: true,
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play Top Songs'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.textPrimary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: DATokens.spacingLarge),

                      // Biography Section (if description is available)
                      if (artist.description.isNotEmpty &&
                          artist.description != 'Official YouTube Channel catalog') ...[
                        _buildSectionHeader('About', colors, typography),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(DATokens.spacingMedium),
                          decoration: BoxDecoration(
                            color: colors.surfaceHover.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(DATokens.radiusLarge),
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            artist.description,
                            style: typography.body.copyWith(
                              color: colors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: DATokens.spacingLarge),
                      ],

                      // Top Songs Section
                      if (topSongs.isNotEmpty) ...[
                        _buildSectionHeader('Top Songs', colors, typography),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: topSongs.length,
                          itemBuilder: (context, index) {
                            final song = topSongs[index];
                            return Card(
                              color: colors.surfaceCard.withValues(alpha: 0.1),
                              margin: const EdgeInsets.only(bottom: DATokens.spacingSmall),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                              ),
                              child: ListTile(
                                onTap: () {
                                  final modelSongs = topSongs.map((s) => shared.Song(
                                    id: s.id,
                                    title: s.title,
                                    artist: s.artistId == 'Unknown Artist' ? artist.name : s.artistId,
                                    album: s.albumId,
                                    duration: s.duration.value,
                                    artworkUrl: s.artwork.url,
                                    source: s.sourceId,
                                    lyrics: null,
                                  )).toList();
                                  ref.read(playbackControllerProvider).setQueue(
                                    modelSongs,
                                    startIndex: index,
                                    autoPlay: true,
                                  );
                                },
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                                  child: song.artwork.url.isNotEmpty
                                      ? Image.network(
                                          song.artwork.url,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 48,
                                          height: 48,
                                          color: colors.surfaceHover,
                                          child: Icon(
                                            Icons.music_note,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  song.title,
                                  style: typography.title.copyWith(fontSize: 15.0),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  song.artistId == 'Unknown Artist' ? artist.name : song.artistId,
                                  style: typography.caption.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatDuration(song.duration.value),
                                      style: typography.caption.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: DATokens.spacingSmall),
                                    IconButton(
                                      icon: Icon(Icons.more_vert, color: colors.textSecondary),
                                      onPressed: () {
                                         final modelSong = shared.Song(
                                           id: song.id,
                                           title: song.title,
                                           artist: song.artistId == 'Unknown Artist' ? artist.name : song.artistId,
                                           album: song.albumId,
                                           duration: song.duration.value,
                                           artworkUrl: song.artwork.url,
                                           source: song.sourceId,
                                           lyrics: null,
                                         );
                                        showSongOptionsMenu(context, ref, modelSong);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: DATokens.spacingLarge),
                      ],

                      // Albums Section
                      if (albums.isNotEmpty) ...[
                        _buildSectionHeader('Albums', colors, typography),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: albums.length,
                            itemBuilder: (context, index) {
                              final album = albums[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: DATokens.spacingMedium),
                                child: SizedBox(
                                  width: 150,
                                  child: AlbumCard(
                                    title: album.title,
                                    subtitle: '${album.year}',
                                    artworkUrl: album.cover.url,
                                    onTap: () => context.push('/album/${album.id}'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: DATokens.spacingLarge),
                      ],

                      // Singles Section
                      if (singles.isNotEmpty) ...[
                        _buildSectionHeader('Singles & EPs', colors, typography),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: singles.length,
                            itemBuilder: (context, index) {
                              final single = singles[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: DATokens.spacingMedium),
                                child: SizedBox(
                                  width: 150,
                                  child: AlbumCard(
                                    title: single.title,
                                    subtitle: '${single.year}',
                                    artworkUrl: single.cover.url,
                                    onTap: () => context.push('/album/${single.id}'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: DATokens.spacingLarge),
                      ],

                      // Playlists Section
                      if (playlists.isNotEmpty) ...[
                        _buildSectionHeader('Playlists', colors, typography),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: playlists.length,
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: DATokens.spacingMedium),
                                child: SizedBox(
                                  width: 150,
                                  child: AlbumCard(
                                    title: playlist.title,
                                    subtitle: playlist.owner,
                                    artworkUrl: playlist.cover.url,
                                    onTap: () => context.push('/album/${playlist.id}'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: DATokens.spacingLarge),
                      ],

                      // Related Artists Section
                      if (related.isNotEmpty) ...[
                        _buildSectionHeader('Fans Might Also Like', colors, typography),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: related.length,
                            itemBuilder: (context, index) {
                              final rArtist = related[index];
                              return GestureDetector(
                                onTap: () => context.push('/artist/${rArtist.id}'),
                                child: Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: DATokens.spacingMedium),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: colors.surfaceHover,
                                        backgroundImage: rArtist.image.url.isNotEmpty
                                            ? NetworkImage(rArtist.image.url)
                                            : null,
                                        child: rArtist.image.url.isEmpty
                                            ? Icon(Icons.person, color: colors.textSecondary)
                                            : null,
                                      ),
                                      const SizedBox(height: DATokens.spacingSmall),
                                      Text(
                                        rArtist.name,
                                        style: typography.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic colors, dynamic typography) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DATokens.spacingMedium),
      child: Text(
        title,
        style: typography.headline.copyWith(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  String _formatSubscribers(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
