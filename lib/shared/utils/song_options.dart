import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/music_models.dart';
import '../providers/library_providers.dart';
import '../providers/player_providers.dart';
import '../../core/extensions/context_extensions.dart';
import 'artist_navigation.dart';
import '../widgets/more_options/menu_action.dart';
import '../widgets/more_options/more_options_menu.dart';
import '../widgets/more_options/song_info_sheet.dart';

Rect _getWidgetBounds(BuildContext context) {
  try {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(offset.dx, offset.dy, renderBox.size.width, renderBox.size.height);
    }
  } catch (_) {}
  final size = MediaQuery.of(context).size;
  return Rect.fromLTWH(size.width / 2 - 20, size.height / 2 - 20, 40, 40);
}

void showSongOptionsMenu(BuildContext context, WidgetRef ref, Song song, {int? queueIndex}) {
  final libraryManager = ref.read(libraryManagerProvider);
  final isLiked = libraryManager.isSongLiked(song.id);
  final colors = context.daColors;
  final bounds = _getWidgetBounds(context);

  final actions = [
    MenuAction(
      title: isLiked ? 'Remove from Favorites' : 'Add to Favorites',
      icon: isLiked ? Icons.favorite : Icons.favorite_border,
      color: isLiked ? Colors.redAccent : null,
      onTap: () => ref.read(libraryManagerProvider.notifier).toggleLikeSong(song),
    ),
    MenuAction(
      title: 'Add to Playlist',
      icon: Icons.playlist_add,
      onTap: () => _showAddToPlaylistDialog(context, ref, song),
    ),
    MenuAction(
      title: 'Play Next',
      icon: Icons.playlist_play,
      onTap: () async {
        await ref.read(playbackControllerProvider).playNext(song);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.surfaceCard,
              content: Text('"${song.title}" will play next.', style: TextStyle(color: colors.textPrimary)),
            ),
          );
        }
      },
    ),
    MenuAction(
      title: 'Add to Queue',
      icon: Icons.queue_music,
      onTap: () async {
        await ref.read(playbackControllerProvider).addToQueue(song);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.surfaceCard,
              content: Text('Added "${song.title}" to queue.', style: TextStyle(color: colors.textPrimary)),
            ),
          );
        }
      },
    ),
    MenuAction(
      title: 'Start Radio',
      icon: Icons.radio,
      onTap: () async {
        await ref.read(playbackControllerProvider).selectSong(song);
      },
    ),
    if (song.album.isNotEmpty && song.album != 'yt_album_unknown')
      MenuAction(
        title: 'Go to Album',
        icon: Icons.album_outlined,
        onTap: () {
          if (song.album.startsWith('MPREb_') || song.album.startsWith('OLAK5uy_')) {
            context.push('/album/${song.album}');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colors.surfaceCard,
                content: Text('Album details not available for "${song.album}"', style: TextStyle(color: colors.textPrimary)),
              ),
            );
          }
        },
      ),
    MenuAction(
      title: 'Go to Artist',
      icon: Icons.person_outline,
      onTap: () => navigateToArtistByName(context, ref, song.artist),
    ),
    MenuAction(
      title: 'Share Link',
      icon: Icons.share_outlined,
      onTap: () async {
        final shareUrl = 'https://youtube.com/watch?v=${song.id}';
        await Clipboard.setData(ClipboardData(text: shareUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.surfaceCard,
              content: Text('Video link copied to clipboard!', style: TextStyle(color: colors.textPrimary)),
            ),
          );
        }
      },
    ),
    MenuAction(
      title: 'Sleep Timer',
      icon: Icons.snooze,
      onTap: () => showSleepTimerDialog(context, ref),
    ),
    MenuAction(
      title: 'Hide from Recommendations',
      icon: Icons.block,
      onTap: () {
        ref.read(libraryManagerProvider.notifier).trackSkip(song.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.surfaceCard,
            content: Text('Song will be recommended less.', style: TextStyle(color: colors.textPrimary)),
          ),
        );
      },
    ),
    MenuAction(
      title: 'Song Information',
      icon: Icons.info_outline,
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.55),
          builder: (_) => SongInfoSheet(song: song),
        );
      },
    ),
    if (queueIndex != null) ...[
      MenuAction(
        title: 'Move Up',
        icon: Icons.arrow_upward,
        onTap: () {
          final controller = ref.read(playbackControllerProvider);
          final queue = controller.currentQueue;
          final currIdx = controller.currentIndex;
          if (queueIndex > 0) {
            final updatedSongs = List<Song>.from(queue);
            final s = updatedSongs.removeAt(queueIndex);
            updatedSongs.insert(queueIndex - 1, s);
            final newCurrentIndex = (currIdx == queueIndex) ? queueIndex - 1 : (currIdx == queueIndex - 1 ? queueIndex : currIdx);
            controller.reorderQueue(updatedSongs, newCurrentIndex);
          }
        },
      ),
      MenuAction(
        title: 'Move Down',
        icon: Icons.arrow_downward,
        onTap: () {
          final controller = ref.read(playbackControllerProvider);
          final queue = controller.currentQueue;
          final currIdx = controller.currentIndex;
          if (queueIndex < queue.length - 1) {
            final updatedSongs = List<Song>.from(queue);
            final s = updatedSongs.removeAt(queueIndex);
            updatedSongs.insert(queueIndex + 1, s);
            final newCurrentIndex = (currIdx == queueIndex) ? queueIndex + 1 : (currIdx == queueIndex + 1 ? queueIndex : currIdx);
            controller.reorderQueue(updatedSongs, newCurrentIndex);
          }
        },
      ),
      MenuAction(
        title: 'Remove from Queue',
        icon: Icons.delete_outline,
        color: Colors.redAccent,
        onTap: () {
          final controller = ref.read(playbackControllerProvider);
          final queue = controller.currentQueue;
          final currIdx = controller.currentIndex;
          final updatedSongs = List<Song>.from(queue);
          updatedSongs.removeAt(queueIndex);
          int newCurrentIndex = currIdx;
          if (queueIndex == currIdx) {
            newCurrentIndex = updatedSongs.isEmpty ? -1 : (currIdx >= updatedSongs.length ? 0 : currIdx);
          } else if (queueIndex < currIdx) {
            newCurrentIndex--;
          }
          controller.reorderQueue(updatedSongs, newCurrentIndex);
        },
      ),
    ],
  ];

  MoreOptionsMenu.show(
    context: context,
    targetRect: bounds,
    title: song.title,
    subtitle: song.artist,
    artworkUrl: song.artworkUrl,
    actions: actions,
  );
}

void showAlbumOptionsMenu(BuildContext context, WidgetRef ref, Album album) {
  final libraryManager = ref.read(libraryManagerProvider);
  final isLiked = libraryManager.likedAlbums.any((a) => a.id == album.id);
  final colors = context.daColors;
  final bounds = _getWidgetBounds(context);

  final actions = [
    MenuAction(
      title: 'Play Album',
      icon: Icons.play_arrow,
      onTap: () {
        if (album.songs.isNotEmpty) {
          ref.read(playbackControllerProvider).setQueue(album.songs, startIndex: 0);
        }
      },
    ),
    MenuAction(
      title: 'Shuffle Album',
      icon: Icons.shuffle,
      onTap: () {
        if (album.songs.isNotEmpty) {
          final shuffled = List<Song>.from(album.songs)..shuffle();
          ref.read(playbackControllerProvider).setQueue(shuffled, startIndex: 0);
        }
      },
    ),
    MenuAction(
      title: isLiked ? 'Remove from Library' : 'Add to Library',
      icon: isLiked ? Icons.favorite : Icons.favorite_border,
      color: isLiked ? Colors.redAccent : null,
      onTap: () => ref.read(libraryManagerProvider.notifier).toggleLikeAlbum(album),
    ),
    MenuAction(
      title: 'Share Album',
      icon: Icons.share_outlined,
      onTap: () async {
        final shareUrl = 'https://music.youtube.com/browse/${album.id}';
        await Clipboard.setData(ClipboardData(text: shareUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.surfaceCard,
              content: Text('Album link copied to clipboard!', style: TextStyle(color: colors.textPrimary)),
            ),
          );
        }
      },
    ),
    MenuAction(
      title: 'Go to Artist',
      icon: Icons.person_outline,
      onTap: () => navigateToArtistByName(context, ref, album.artist),
    ),
  ];

  MoreOptionsMenu.show(
    context: context,
    targetRect: bounds,
    title: album.name,
    subtitle: album.artist,
    artworkUrl: album.artworkUrl,
    actions: actions,
  );
}

void showPlaylistOptionsMenu(BuildContext context, WidgetRef ref, Playlist playlist) {
  final colors = context.daColors;
  final bounds = _getWidgetBounds(context);

  final actions = [
    MenuAction(
      title: 'Play Playlist',
      icon: Icons.play_arrow,
      onTap: () {
        if (playlist.songs.isNotEmpty) {
          ref.read(playbackControllerProvider).setQueue(playlist.songs, startIndex: 0);
        }
      },
    ),
    MenuAction(
      title: 'Shuffle Playlist',
      icon: Icons.shuffle,
      onTap: () {
        if (playlist.songs.isNotEmpty) {
          final shuffled = List<Song>.from(playlist.songs)..shuffle();
          ref.read(playbackControllerProvider).setQueue(shuffled, startIndex: 0);
        }
      },
    ),
    MenuAction(
      title: 'Download (Future Ready)',
      icon: Icons.download,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.surfaceCard,
            content: Text('Download features will be integrated soon.', style: TextStyle(color: colors.textPrimary)),
          ),
        );
      },
    ),
    MenuAction(
      title: 'Share Playlist',
      icon: Icons.share_outlined,
      onTap: () async {
        final shareUrl = 'https://music.youtube.com/playlist?list=${playlist.id}';
        await Clipboard.setData(ClipboardData(text: shareUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.surfaceCard,
              content: Text('Playlist link copied to clipboard!', style: TextStyle(color: colors.textPrimary)),
            ),
          );
        }
      },
    ),
  ];

  MoreOptionsMenu.show(
    context: context,
    targetRect: bounds,
    title: playlist.name,
    subtitle: '${playlist.songs.length} songs',
    actions: actions,
  );
}

void showArtistOptionsMenu(BuildContext context, WidgetRef ref, Artist artist) {
  final libraryManager = ref.read(libraryManagerProvider);
  final isLiked = libraryManager.likedArtists.any((a) => a.id == artist.id);
  final colors = context.daColors;
  final bounds = _getWidgetBounds(context);

  final actions = [
    MenuAction(
      title: isLiked ? 'Unfollow' : 'Follow',
      icon: isLiked ? Icons.person_remove : Icons.person_add,
      onTap: () => ref.read(libraryManagerProvider.notifier).toggleLikeArtist(artist),
    ),
    MenuAction(
      title: 'Share Artist',
      icon: Icons.share_outlined,
      onTap: () async {
        final shareUrl = 'https://music.youtube.com/channel/${artist.id}';
        await Clipboard.setData(ClipboardData(text: shareUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.surfaceCard,
              content: Text('Artist link copied to clipboard!', style: TextStyle(color: colors.textPrimary)),
            ),
          );
        }
      },
    ),
    MenuAction(
      title: 'View Albums',
      icon: Icons.album_outlined,
      onTap: () => context.push('/artist/${artist.id}'),
    ),
  ];

  MoreOptionsMenu.show(
    context: context,
    targetRect: bounds,
    title: artist.name,
    artworkUrl: artist.artworkUrl,
    actions: actions,
  );
}

void showSleepTimerDialog(BuildContext context, WidgetRef ref) {
  final colors = context.daColors;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text('Sleep Timer', style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 15, 30, 45, 60].map((mins) {
            return ListTile(
              title: Text('$mins minutes', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                final duration = Duration(minutes: mins);
                ref.read(sleepTimerDurationProvider.notifier).state = duration;
                ref.read(sleepTimerProvider)?.cancel();
                final timer = Timer(duration, () {
                  ref.read(playbackControllerProvider).pause();
                  ref.read(sleepTimerProvider.notifier).state = null;
                  ref.read(sleepTimerDurationProvider.notifier).state = null;
                });
                ref.read(sleepTimerProvider.notifier).state = timer;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: colors.surfaceCard,
                    content: Text('Playback will pause in $mins minutes.', style: TextStyle(color: colors.textPrimary)),
                  ),
                );
              },
            );
          }).toList(),
        ),
      );
    },
  );
}

void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref, Song song) {
  final libraryManager = ref.read(libraryManagerProvider);
  final playlists = libraryManager.playlists;
  final colors = context.daColors;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text('Add to Playlist', style: TextStyle(color: colors.textPrimary)),
        content: playlists.isEmpty
            ? Text('No playlists found. Create one in Library.', style: TextStyle(color: colors.textPrimary))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlists[index];
                    return ListTile(
                      leading: Icon(Icons.playlist_play, color: colors.textSecondary),
                      title: Text(pl.name, style: TextStyle(color: colors.textPrimary)),
                      onTap: () {
                        ref.read(libraryManagerProvider.notifier).addSongToPlaylist(pl.id, song);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: colors.surfaceCard,
                            content: Text('Added to playlist "${pl.name}"', style: TextStyle(color: colors.textPrimary)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.primary)),
          ),
        ],
      );
    },
  );
}
