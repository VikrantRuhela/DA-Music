import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/providers/player_providers.dart';
import '../../../shared/providers/library_providers.dart';
import '../../../shared/widgets/da_empty_state.dart';
import '../../../shared/utils/song_options.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String? _selectedPlaylistId;

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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Playlist',
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: playlists.isEmpty
          ? Center(
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
            )
          : ListView.builder(
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
            ),
    );
  }
}
