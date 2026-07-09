import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/providers/player_providers.dart';
import '../../../shared/providers/library_providers.dart';
import '../../../shared/widgets/da_empty_state.dart';
import '../../../shared/utils/song_options.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/services/library_manager.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String? _selectedPlaylistId;
  int _selectedTab = 0; // 0 = Playlists, 1 = Downloads

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Playlist Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref.read(libraryManagerProvider.notifier).createPlaylist(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final libraryManager = ref.watch(libraryManagerProvider);
    final playlists = libraryManager.playlists;

    if (_selectedPlaylistId != null) {
      final playlistIndex = playlists.indexWhere((p) => p.id == _selectedPlaylistId);
      if (playlistIndex < 0) {
        // Selected playlist was deleted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedPlaylistId = null;
          });
        });
        return const SizedBox.shrink();
      }

      final playlist = playlists[playlistIndex];

      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: colors.textPrimary,
            onPressed: () {
              setState(() {
                _selectedPlaylistId = null;
              });
            },
          ),
          title: Text(
            playlist.name,
            style: typography.title.copyWith(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete Playlist',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Playlist'),
                    content: Text('Are you sure you want to delete "${playlist.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          ref.read(libraryManagerProvider.notifier).deletePlaylist(playlist.id);
                          Navigator.pop(context);
                          setState(() {
                            _selectedPlaylistId = null;
                          });
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: playlist.songs.isEmpty
            ? const Center(
                child: DAEmptyState(
                  icon: Icons.playlist_play,
                  title: 'Playlist is Empty',
                  description: 'Add songs to this playlist using song overflow menus.',
                ),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: DATokens.spacingMedium,
                  vertical: DATokens.spacingSmall,
                ),
                itemCount: playlist.songs.length,
                itemBuilder: (context, index) {
                  final song = playlist.songs[index];

                  return Card(
                    color: colors.surfaceCard.withValues(alpha: 0.1),
                    margin: const EdgeInsets.only(bottom: DATokens.spacingSmall),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                      side: BorderSide(color: colors.border.withValues(alpha: 0.1)),
                    ),
                    child: ListTile(
                      onTap: () {
                        ref.read(playbackControllerProvider).setQueue(
                              playlist.songs,
                              startIndex: index,
                              autoPlay: true,
                            );
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                        child: song.artworkUrl != null && song.artworkUrl!.isNotEmpty
                            ? Image.network(
                                song.artworkUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white24),
                              )
                            : const Icon(Icons.music_note, color: Colors.white24),
                      ),
                      title: Text(
                        song.title,
                        style: typography.title.copyWith(fontSize: 14.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist,
                        style: typography.caption.copyWith(color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () {
                              ref.read(libraryManagerProvider.notifier).removeSongFromPlaylist(playlist.id, song.id);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert, color: colors.textSecondary),
                            onPressed: () {
                              showSongOptionsMenu(context, ref, song);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Library',
          style: typography.title.copyWith(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create Playlist',
              onPressed: () => _showCreatePlaylistDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DATokens.spacingMedium, vertical: DATokens.spacingSmall),
            child: Row(
              children: [
                _buildTabButton('Playlists', 0, colors, typography),
                const SizedBox(width: DATokens.spacingMedium * 1.5),
                _buildTabButton('Downloads', 1, colors, typography),
              ],
            ),
          ),
          const SizedBox(height: DATokens.spacingSmall),
          Expanded(
            child: _selectedTab == 0
                ? _buildPlaylistsTab(playlists, colors, typography)
                : _buildDownloadsTab(colors, typography),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index, dynamic colors, dynamic typography) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: typography.title.copyWith(
              fontSize: 16.0,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.textPrimary : colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4.0),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.0,
            width: isSelected ? 40.0 : 0.0,
            color: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsTab(List<LibraryPlaylist> playlists, dynamic colors, dynamic typography) {
    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DAEmptyState(
              icon: Icons.my_library_music_outlined,
              title: 'Your Library is Empty',
              description: 'Create custom playlists to organize your music.',
            ),
            const SizedBox(height: DATokens.spacingMedium),
            ElevatedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: DATokens.spacingMedium,
        vertical: DATokens.spacingSmall,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final pl = playlists[index];

        return Card(
          color: colors.surfaceCard.withValues(alpha: 0.1),
          margin: const EdgeInsets.only(bottom: DATokens.spacingSmall),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DATokens.radiusMedium),
            side: BorderSide(color: colors.border.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            onTap: () {
              setState(() {
                _selectedPlaylistId = pl.id;
              });
            },
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: BorderRadius.circular(DATokens.radiusSmall),
              ),
              child: Icon(Icons.playlist_play, color: colors.primary),
            ),
            title: Text(
              pl.name,
              style: typography.title.copyWith(fontSize: 14.0, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${pl.songs.length} songs',
              style: typography.caption.copyWith(color: colors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildDownloadsTab(dynamic colors, dynamic typography) {
    final downloadManager = ref.watch(downloadManagerProvider);
    final allTasks = downloadManager.allTasks;
    final activeTasks = allTasks.where((t) => 
      t.status == DownloadStatus.downloading || 
      t.status == DownloadStatus.queued || 
      t.status == DownloadStatus.paused ||
      t.status == DownloadStatus.failed
    ).toList();

    final downloadedSongsAsync = ref.watch(downloadedSongsProvider);

    return downloadedSongsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.primary)),
      error: (err, stack) => Center(
        child: Text('Error loading downloads: $err', style: TextStyle(color: colors.textPrimary)),
      ),
      data: (downloadedSongs) {
        if (activeTasks.isEmpty && downloadedSongs.isEmpty) {
          return const Center(
            child: DAEmptyState(
              icon: Icons.download_for_offline_outlined,
              title: 'No Offline Music',
              description: 'Download tracks using the options menu to listen offline.',
            ),
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: DATokens.spacingMedium),
          children: [
            if (activeTasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DATokens.spacingSmall),
                child: Text(
                  'Downloading (${activeTasks.length})',
                  style: typography.title.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ),
              ...activeTasks.map((t) => _buildActiveTaskCard(t, colors, typography)),
              const Divider(color: Colors.white10, height: 24.0),
            ],
            if (downloadedSongs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DATokens.spacingSmall),
                child: Text(
                  'Downloaded Tracks',
                  style: typography.title.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ),
              ...List.generate(downloadedSongs.length, (index) {
                final song = downloadedSongs[index];
                return Card(
                  color: colors.surfaceCard.withValues(alpha: 0.1),
                  margin: const EdgeInsets.only(bottom: DATokens.spacingSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                    side: BorderSide(color: colors.border.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    onTap: () {
                      ref.read(playbackControllerProvider).setQueue(
                            downloadedSongs,
                            startIndex: index,
                            autoPlay: true,
                          );
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                      child: song.artworkUrl != null && song.artworkUrl!.isNotEmpty
                          ? Image.network(
                              song.artworkUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white24),
                            )
                          : const Icon(Icons.music_note, color: Colors.white24),
                    ),
                    title: Text(
                      song.title,
                      style: typography.title.copyWith(fontSize: 14.0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist,
                      style: typography.caption.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert, color: colors.textSecondary),
                      onPressed: () {
                        showSongOptionsMenu(context, ref, song);
                      },
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActiveTaskCard(DownloadTask t, dynamic colors, dynamic typography) {
    String statusText = 'Queued';
    if (t.status == DownloadStatus.downloading) {
      final double speedBytesPerSec = t.speedMb * 1024 * 1024;
      String speedText;
      if (speedBytesPerSec <= 0) {
        speedText = '0 KB/s';
      } else if (speedBytesPerSec >= 1024 * 1024) {
        speedText = '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
      } else if (speedBytesPerSec >= 1024) {
        speedText = '${(speedBytesPerSec / 1024).toStringAsFixed(0)} KB/s';
      } else {
        speedText = '1 KB/s';
      }
      final sizeText = '${(t.remainingBytes / (1024 * 1024)).toStringAsFixed(1)} MB left';
      final etaText = t.etaSeconds > 0 ? '${t.etaSeconds}s left' : 'calculating...';
      statusText = '$speedText  •  $sizeText  •  $etaText';
    } else if (t.status == DownloadStatus.paused) {
      statusText = 'Paused';
    } else if (t.status == DownloadStatus.failed) {
      statusText = 'Failed: ${t.error ?? "Unknown error"}';
    }

    return Card(
      color: colors.surfaceCard.withValues(alpha: 0.15),
      margin: const EdgeInsets.only(bottom: DATokens.spacingSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DATokens.radiusMedium),
        side: BorderSide(color: colors.border.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DATokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: typography.title.copyWith(fontSize: 14.0, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        t.artist,
                        style: typography.caption.copyWith(color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t.status == DownloadStatus.downloading)
                      IconButton(
                        icon: const Icon(Icons.pause, color: Colors.white70),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref.read(downloadManagerProvider.notifier).pauseDownload(t.songId);
                        },
                      )
                    else if (t.status == DownloadStatus.paused)
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white70),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref.read(downloadManagerProvider.notifier).resumeDownload(t.songId);
                        },
                      ),
                    const SizedBox(width: DATokens.spacingMedium),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ref.read(downloadManagerProvider.notifier).cancelDownload(t.songId);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: DATokens.spacingSmall),
            LinearProgressIndicator(
              value: t.progress,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
            const SizedBox(height: 4.0),
            Text(
              statusText,
              style: typography.caption.copyWith(color: t.status == DownloadStatus.failed ? Colors.redAccent : colors.textSecondary, fontSize: 11.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
