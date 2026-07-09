import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/music_models.dart';
import '../providers/library_providers.dart';
import '../widgets/da_image.dart';
import '../providers/player_providers.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/download_manager.dart';
import 'artist_navigation.dart';

void showSongOptionsMenu(BuildContext context, WidgetRef ref, Song song) {
  final libraryManager = ref.read(libraryManagerProvider);
  final isLiked = libraryManager.isSongLiked(song.id);
  final colors = context.daColors;
  final typography = context.daTypography;

  showModalBottomSheet(
    context: context,
    backgroundColor: colors.surfaceCard,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header song preview in sheet
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: DAImage(
                      url: song.artworkUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: Icon(Icons.music_note, color: colors.textSecondary),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: typography.title.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist,
                    style: typography.body.copyWith(fontSize: 13.0, color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(height: 1.0, color: Colors.white10),
                
                // Toggle Favorites
                ListTile(
                  leading: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.redAccent : colors.textSecondary,
                  ),
                  title: Text(
                    isLiked ? 'Remove from Favorites' : 'Add to Favorites',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(libraryManagerProvider.notifier).toggleLikeSong(song);
                  },
                ),

                // Add to Playlist
                ListTile(
                  leading: Icon(Icons.playlist_add, color: colors.textSecondary),
                  title: Text('Add to Playlist', style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddToPlaylistDialog(context, ref, song);
                  },
                ),

                // Download options
                Builder(builder: (context) {
                  final downloadManager = ref.watch(downloadManagerProvider);
                  final task = downloadManager.getTask(song.id);
                  final isDownloaded = task?.status == DownloadStatus.completed;
                  final isDownloading = task != null &&
                      (task.status == DownloadStatus.downloading ||
                       task.status == DownloadStatus.queued ||
                       task.status == DownloadStatus.paused);

                  if (isDownloaded) {
                    return ListTile(
                      leading: const Icon(Icons.download_done, color: Colors.green),
                      title: Text('Remove Download', style: TextStyle(color: colors.textPrimary)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(downloadManagerProvider.notifier).removeDownload(song.id);
                      },
                    );
                  } else if (isDownloading) {
                    return ListTile(
                      leading: const Icon(Icons.downloading, color: Colors.orangeAccent),
                      title: Text('Cancel Download', style: TextStyle(color: colors.textPrimary)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(downloadManagerProvider.notifier).cancelDownload(song.id);
                      },
                    );
                  } else {
                    return ListTile(
                      leading: Icon(Icons.download, color: colors.textSecondary),
                      title: Text('Download', style: TextStyle(color: colors.textPrimary)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(downloadManagerProvider.notifier).startDownload(song);
                      },
                    );
                  }
                }),

                // Download Quality Preference Selection
                ListTile(
                  leading: Icon(Icons.high_quality, color: colors.textSecondary),
                  title: Text('Download Quality (${ref.watch(downloadManagerProvider).preferredQuality})', style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDownloadQualityDialog(context, ref);
                  },
                ),

                // Play Next
                ListTile(
                  leading: Icon(Icons.playlist_play, color: colors.textSecondary),
                  title: Text('Play Next', style: TextStyle(color: colors.textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
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

                // Add to Queue
                ListTile(
                  leading: Icon(Icons.queue_music, color: colors.textSecondary),
                  title: Text('Add to Queue', style: TextStyle(color: colors.textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
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

                // Go to Artist
                ListTile(
                  leading: Icon(Icons.person_outline, color: colors.textSecondary),
                  title: Text('Go to Artist', style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    navigateToArtistByName(context, ref, song.artist);
                  },
                ),

                // Go to Album
                if (song.album.isNotEmpty && song.album != 'yt_album_unknown')
                  ListTile(
                    leading: Icon(Icons.album_outlined, color: colors.textSecondary),
                    title: Text('Go to Album', style: TextStyle(color: colors.textPrimary)),
                    onTap: () {
                      Navigator.pop(context);
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

                // Share Link
                ListTile(
                  leading: Icon(Icons.share_outlined, color: colors.textSecondary),
                  title: Text('Share Link', style: TextStyle(color: colors.textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
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

                // Song Information details
                ListTile(
                  leading: Icon(Icons.info_outline, color: colors.textSecondary),
                  title: Text('Song Information', style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _showSongInfoDialog(context, colors, song);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showSongInfoDialog(BuildContext context, dynamic colors, Song song) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text('Song Information', style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Title', song.title, colors),
            _infoRow('Artist', song.artist, colors),
            _infoRow('Album', song.album == 'yt_album_unknown' ? 'Unknown' : song.album, colors),
            _infoRow('Duration', '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}', colors),
            _infoRow('Source ID', song.id, colors),
            _infoRow('Playback Source', song.source, colors),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colors.primary)),
          ),
        ],
      );
    },
  );
}

Widget _infoRow(String label, String value, dynamic colors) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: RichText(
      text: TextSpan(
        style: TextStyle(color: colors.textPrimary, fontSize: 14.0),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    ),
  );
}

void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref, Song song) {
  final libraryManager = ref.read(libraryManagerProvider);
  final playlists = libraryManager.playlists;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add to Playlist'),
        content: playlists.isEmpty
            ? const Text('No playlists found. Create one in your Library.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlists[index];
                    return ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(pl.name),
                      onTap: () {
                        ref.read(libraryManagerProvider.notifier).addSongToPlaylist(pl.id, song);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to playlist "${pl.name}"'),
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
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

void _showDownloadQualityDialog(BuildContext context, WidgetRef ref) {
  final downloadManager = ref.read(downloadManagerProvider);
  final colors = context.daColors;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text('Download Quality', style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Auto', 'High', 'Medium', 'Low'].map((q) {
            return RadioListTile<String>(
              title: Text(q, style: TextStyle(color: colors.textPrimary)),
              value: q,
              groupValue: downloadManager.preferredQuality,
              activeColor: colors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(downloadManagerProvider.notifier).setPreferredQuality(val);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colors.primary)),
          ),
        ],
      );
    },
  );
}
