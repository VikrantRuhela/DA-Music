import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'section_header.dart';
import 'song_tile.dart';
import '../../../../domain/entities/song.dart';
import '../../../../shared/providers/player_providers.dart';
import '../../../../shared/models/music_models.dart' as shared;
import '../../../../shared/utils/song_options.dart';
import '../../../../app/theme/tokens.dart';

import '../../../../core/extensions/context_extensions.dart';

class RecentlyPlayedWidget extends ConsumerWidget {
  final List<Song> songs;

  const RecentlyPlayedWidget({
    super.key,
    required this.songs,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;

    if (songs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Recommended Songs'),
          Container(
            height: 150.0,
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(DATokens.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, color: colors.textSecondary.withValues(alpha: 0.4), size: 48.0),
                const SizedBox(height: DATokens.spacingSmall),
                Text(
                  'No song recommendations yet.',
                  style: typography.body.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recommended Songs'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: SongTile(
                title: song.title,
                artist: song.artistId,
                duration: _formatDuration(song.duration.value),
                coverUrl: song.thumbnail.url,
                onTap: () {
                  debugPrint('Tapped Song ID: ${song.id}, Title: ${song.title}');
                  final modelSongs = songs.map((s) => shared.Song(
                    id: s.id,
                    title: s.title,
                    artist: s.artistId,
                    album: s.albumId,
                    duration: s.duration.value,
                    artworkUrl: s.artwork.url,
                    source: s.sourceId,
                    lyrics: null,
                  )).toList();
                  ref.read(playbackControllerProvider).setQueue(modelSongs, startIndex: index, autoPlay: true);
                },
                onMorePressed: () {
                  final modelSong = shared.Song(
                    id: song.id,
                    title: song.title,
                    artist: song.artistId,
                    album: song.albumId,
                    duration: song.duration.value,
                    artworkUrl: song.artwork.url,
                    source: song.sourceId,
                    lyrics: null,
                  );
                  showSongOptionsMenu(context, ref, modelSong);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
